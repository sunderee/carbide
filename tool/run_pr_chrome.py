#!/usr/bin/env python3
"""Run the explicitly reviewed browser component subset; pixels stay Linux-only."""

import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    suites = json.loads((ROOT / "tool/pr_chrome_suites.json").read_text())["suites"]
    if not suites or len(set(suites)) != len(suites):
        raise ValueError("Chrome subset must be nonempty and contain unique paths")
    for suite in suites:
        if not suite.startswith("test/") or not suite.endswith("_test.dart"):
            raise ValueError(f"unexpected suite path: {suite}")
        if not (ROOT / suite).is_file():
            raise ValueError(f"missing Chrome suite: {suite}")
    return subprocess.call([
        "flutter", "test", "--platform", "chrome",
        "--dart-define=CARBIDE_SKIP_GOLDENS=true", *suites,
    ], cwd=ROOT)


if __name__ == "__main__":
    sys.exit(main())
