#!/usr/bin/env python3
"""Fail closed on release tags and pub's narrowly allowed gitlink warning."""

import argparse
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
NUMBER = r"(?:0|[1-9]\d*)"
PRERELEASE_ID = rf"(?:{NUMBER}|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)"
SEMVER = rf"{NUMBER}\.{NUMBER}\.{NUMBER}(?:-{PRERELEASE_ID}(?:\.{PRERELEASE_ID})*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
KNOWN_GITLINKS = frozenset({
    "documentation/carbon", "documentation/carbon-design-kit",
    "documentation/carbon-icons", "documentation/carbon-website",
    "documentation/plex",
})


def assert_tag(tag, pubspec):
    """Require an exact, valid v-prefixed package version, including suffixes."""
    matches = re.findall(r"^version:\s*([^\s#]+)\s*(?:#.*)?$", pubspec, re.M)
    if len(matches) != 1 or not re.fullmatch(SEMVER, matches[0]):
        raise ValueError("pubspec must contain one valid package version")
    if tag != "v" + matches[0]:
        raise ValueError(f"tag {tag!r} does not match package v{matches[0]}")


def assert_dry_run(code, output):
    """Allow only Pub's complete ignored-gitlinks diagnostic, never a substring."""
    if code == 0:
        summary = "Package has 0 warnings."
        if not output.rstrip().endswith(summary) or output.count(summary) != 1:
            raise ValueError("missing clean validation summary")
        before_summary = output[:output.rfind(summary)]
        if re.search(r"(?im)^(?:warning|error|fatal)|potential issue", before_summary):
            raise ValueError("successful dry-run contains a diagnostic")
        return "Dry-run clean."
    # Pub uses EX_DATAERR (65) for validation warnings. Network/tool crashes must
    # not be mistaken for a tolerated warning, even if the log contains one.
    if code != 65:
        raise ValueError(f"unexpected dry-run exit code {code}")
    marker = "Package validation found the following potential issue:\n"
    if output.count(marker) != 1:
        raise ValueError("expected exactly one package-validation diagnostic")
    diagnostic = output.split(marker, 1)[1]
    pattern = (
        r"\* ([1-5]) checked-in files are ignored by a `\.gitignore`\.\n"
        r"  Previous versions of Pub would include those in the published package\.\n"
        r"  \n"
        r"  Consider adjusting your `\.gitignore` files to not ignore those files, and if you do not wish to\n"
        r"  publish these files use `\.pubignore`\. See also dart\.dev/go/pubignore\n"
        r"  \n"
        r"  Files that are checked in while gitignored:\n"
        r"  \n"
        r"((?:  documentation/[a-z-]+\n){1,5})"
        r"  \n  \n"
        r"The server may enforce additional checks\.\n\n"
        r"Package has 1 warning\.\n?"
    )
    match = re.fullmatch(pattern, diagnostic)
    if not match:
        raise ValueError("unexpected or changed package-validation warning")
    paths = [line.strip() for line in match[2].splitlines()]
    if len(paths) != int(match[1]) or len(set(paths)) != len(paths):
        raise ValueError("ignored-file count is inconsistent")
    if not set(paths) <= KNOWN_GITLINKS:
        raise ValueError("ignored paths include a non-reference file")
    prefix = output.split(marker, 1)[0]
    if re.search(r"(?im)^(?:warning|error|fatal|pub finished with).*", prefix):
        raise ValueError("additional diagnostic before package validation")
    return "Only the exact documentation gitlink warning is tolerated."


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    tag = commands.add_parser("tag")
    tag.add_argument("name")
    commands.add_parser("dry-run")
    args = parser.parse_args()
    try:
        if args.command == "tag":
            assert_tag(args.name, (ROOT / "pubspec.yaml").read_text())
            print("Tag matches package version.")
        else:
            result = subprocess.run(["dart", "pub", "publish", "--dry-run"],
                                    cwd=ROOT, text=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT)
            print(result.stdout, end="", flush=True)
            print(assert_dry_run(result.returncode, result.stdout))
    except ValueError as error:
        print(f"Release verification failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
