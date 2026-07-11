#!/usr/bin/env python3
"""
Automatically regenerates the listing section of readme.md from the files
inside src/, following the order and hierarchy declared in src/SUMMARY.md.

With this in place, adding/editing a list item only requires touching the
corresponding file inside src/. This script (normally run from CI, see
.github/workflows/readme-sync.yml) takes care of propagating the change to
readme.md.

Usage:
    python3 scripts/generate_readme.py            # regenerate readme.md
    python3 scripts/generate_readme.py --check     # validate only (exit 1 if
                                                      readme.md is out of date)

Single requirement: readme.md must contain the markers
    <!-- content:start -->
    <!-- content:end -->
wrapping the block that goes from "## Arch-based projects" to the end of
"## Inactive projects" (everything that today gets edited "by hand" twice).
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
SUMMARY = SRC / "SUMMARY.md"
README = ROOT / "readme.md"

START_MARKER = "<!-- content:start -->"
END_MARKER = "<!-- content:end -->"

# "  - [Title](./file.md)" -> nested entries (indented)
SUMMARY_LINE_RE = re.compile(r"^(?P<indent>\s*)-\s*\[.*?\]\(\./(?P<file>[\w.-]+\.md)\)")
# "[Title](./file.md)" -> top-level entry (only Introduction today)
INTRO_LINE_RE = re.compile(r"^\[.*?\]\(\./(?P<file>[\w.-]+\.md)\)")


def parse_summary():
    """Returns [(depth, file), ...] in the order they should be rendered.
    Stops as soon as it hits a non-matching line after entries have started
    (the blank line + the trailing link to Contribute are left out, since
    that section isn't generated from here)."""
    entries = []
    for line in SUMMARY.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            if entries:
                break
            continue
        m = INTRO_LINE_RE.match(line)
        if m:
            entries.append((0, m.group("file")))
            continue
        m = SUMMARY_LINE_RE.match(line)
        if m:
            depth = len(m.group("indent")) // 2 + 1
            entries.append((depth, m.group("file")))
            continue
        # Line that matches nothing (e.g. the "# Summary" header): ignore it
        # if we haven't started collecting entries yet; if we already have,
        # it's time to stop.
        if entries:
            break
    return entries


def demote_heading(text, depth):
    """The first heading of every file in src/ comes as '# Title'; we bump
    it to match its actual depth within SUMMARY.md."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        if line.startswith("# "):
            lines[i] = "#" * (depth + 1) + line[1:]
            break
    return "\n".join(lines).strip()


def build_body():
    parts = []
    for depth, filename in parse_summary():
        # Introduction isn't part of the listing that's duplicated in readme.md
        if filename == "introduction.md":
            continue
        path = SRC / filename
        if not path.exists():
            sys.exit(f"SUMMARY.md references {filename}, but it doesn't exist in src/")
        parts.append(demote_heading(path.read_text(encoding="utf-8"), depth))
    return "\n\n".join(parts) + "\n"


def main():
    if not README.exists():
        sys.exit(f"Couldn't find {README}")
    readme = README.read_text(encoding="utf-8")

    if START_MARKER not in readme or END_MARKER not in readme:
        sys.exit(
            f"Couldn't find the {START_MARKER} / {END_MARKER} markers in readme.md.\n"
            "Add them once, wrapping the block that goes from "
            "'## Arch-based projects' to the end of '## Inactive projects'."
        )

    before, rest = readme.split(START_MARKER, 1)
    _, after = rest.split(END_MARKER, 1)
    new_readme = before + START_MARKER + "\n\n" + build_body() + "\n" + END_MARKER + after

    check_only = "--check" in sys.argv
    if new_readme == readme:
        print("readme.md is already in sync with src/.")
        return

    if check_only:
        print(
            "readme.md is out of date with respect to src/.\n"
            "Run `python3 scripts/generate_readme.py` and commit the result."
        )
        sys.exit(1)

    README.write_text(new_readme, encoding="utf-8")
    print("readme.md updated from src/.")


if __name__ == "__main__":
    main()
