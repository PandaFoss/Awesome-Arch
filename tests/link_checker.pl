#!/usr/bin/perl
################################################################################
# Author: Max Ferrer (PandaFoss) <maxi.fg13@gmail.com>                         #
#                                                                              #
# Execute this script to check the links and verify in case one is down.       #
#                                                                              #
################################################################################

use warnings;
use strict;
use feature 'say';
use HTTP::Status qw(:constants :is status_message);
use HTTP::Tiny;
use Term::ANSIColor;

my $Client = HTTP::Tiny->new();

open(my $readme_file, '<', '../readme.md')
    or die "Failed to open readme for reading: $!";

while(my $line =<$readme_file>) {
    if ($line =~ m/^- \[.*\]\((http.*?)\).*$/i) {
        my $response = $Client->get($1);
        print colored(" * ", 'bold blue'), $1, ": ", $response->{status};
        if (is_error($response->{status})) {
            say colored(" ERROR!", 'bold red');
        } else {
            say colored(" OK!", 'bold green');
        }
    }
}

close($readme_file);
