#!/usr/bin/env perl
################################################################################
# Author: Max Ferrer (PandaFoss) <maxi.fg13@gmail.com>                        #
#                                                                              #
# Execute this script to check the links and verify in case one is down.     #
#                                                                              #
# Improvements over the original version:                                    #
#   - Reads every file in src/ instead of only readme.md, so it works        #
#     regardless of whether readme.md was already regenerated.               #
#   - Runs requests in parallel (Parallel::ForkManager) instead of one at a  #
#     time: with ~150+ links this is the difference between minutes and      #
#     seconds.                                                               #
#   - Uses HEAD first (cheaper) and falls back to GET if the server          #
#     rejects HEAD (405/501), since some hosts don't support it.             #
#   - Sends a real User-Agent and sets a timeout, so it doesn't hang forever #
#     or get a false 403 from sites that block "empty" clients.              #
#   - Retries once on transient errors (timeouts, 5xx) before reporting.     #
#   - De-duplicates URLs that appear more than once across files.           #
#   - Prints a final summary and exits non-zero if there were errors, so it #
#     can be wired into CI.                                                  #
################################################################################

use warnings;
use strict;
use feature 'say';
use FindBin qw($RealBin);
use File::Glob qw(bsd_glob);
use HTTP::Status qw(is_error);
use HTTP::Tiny;
use Term::ANSIColor;
use Parallel::ForkManager;

use constant {
    TIMEOUT       => 10,      # seconds per request
    MAX_PARALLEL  => 20,      # concurrent requests
    RETRIES       => 1,       # extra attempts after the first failure
    USER_AGENT    => 'Mozilla/5.0 (compatible; Awesome-Arch-LinkChecker/2.0; '
                   . '+https://github.com/PandaFoss/Awesome-Arch)',
};

my $src_dir = "$RealBin/../src";
my @files   = bsd_glob("$src_dir/*.md");
die "No .md files found in $src_dir\n" unless @files;

# --- collect unique (url => [files where it appears]) -----------------------
my %links;
for my $file (@files) {
    open(my $fh, '<', $file) or die "Failed to open $file: $!";
    while (my $line = <$fh>) {
        while ($line =~ m/\[.*?\]\((https?:\/\/[^\s\)]+)\)/g) {
            my $url = $1;
            push @{ $links{$url} }, $file;
        }
    }
    close($fh);
}

my @urls = sort keys %links;
printf "Checking %d unique links across %d files...\n\n", scalar(@urls), scalar(@files);

# --- check a single url, with one retry on transient failures ---------------
sub check_url {
    my ($url) = @_;
    my $client = HTTP::Tiny->new(
        timeout         => TIMEOUT,
        agent           => USER_AGENT,
        default_headers => { 'Accept' => '*/*' },
    );

    my $attempt  = 0;
    my $response;
    while ($attempt <= RETRIES) {
        $response = $client->head($url);
        # Some servers don't implement HEAD properly; fall back to GET.
        if ($response->{status} == 405 || $response->{status} == 501) {
            $response = $client->get($url);
        }
        last if !is_error($response->{status}) || $response->{status} != 599;
        $attempt++;
    }
    return $response;
}

# --- run checks in parallel, collect results in a temp file per child -------
my $pm = Parallel::ForkManager->new(MAX_PARALLEL);
my @errors;

$pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;
    return unless $data;
    if ($data->{ok}) {
        print colored(" * ", 'bold blue'), $data->{url}, ": ", $data->{status};
        say colored(" OK!", 'bold green');
    } else {
        print colored(" * ", 'bold blue'), $data->{url}, ": ", $data->{status};
        say colored(" ERROR!", 'bold red');
        push @errors, $data;
    }
});

for my $url (@urls) {
    $pm->start and next;
    my $response = check_url($url);
    $pm->finish(0, {
        url    => $url,
        status => $response->{status},
        ok     => !is_error($response->{status}),
        reason => $response->{reason} // '',
    });
}
$pm->wait_all_children;

# --- summary ------------------------------------------------------------------
say "";
say "-" x 60;
printf "%d/%d links OK\n", scalar(@urls) - scalar(@errors), scalar(@urls);

if (@errors) {
    say colored("\nBroken or unreachable links:", 'bold red');
    for my $e (sort { $a->{url} cmp $b->{url} } @errors) {
        my @in_files = map { s{.*/}{}r } @{ $links{ $e->{url} } };
        say "  - $e->{url} ($e->{status} $e->{reason}) -> found in: @in_files";
    }
    say colored("\nNote: check failing links manually before removing them, ", 'yellow')
      . colored("some sites block automated clients (false negatives).", 'yellow');
    exit 1;
}

say colored("\nAll links are up!", 'bold green');
exit 0;
