#!/usr/bin/env python3
"""Read and cross-check both independent packages' declared SDK floors."""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read_floor(source):
    environment = re.search(r"^environment:\n((?:[ \t].*\n|\n)+)", source, re.M)
    if not environment:
        raise ValueError("missing environment SDK constraints")
    result = {}
    for name in ["sdk", "flutter"]:
        match = re.search(rf"^  {name}:\s*[\"']?>=(\d+\.\d+\.\d+)(?:\s|[\"']|$)",
                          environment[1], re.M)
        if not match:
            raise ValueError(f"missing explicit minimum {name} version")
        result[name] = match[1]
    return result


def main():
    root = read_floor((ROOT / "pubspec.yaml").read_text())
    gallery = read_floor((ROOT / "example/pubspec.yaml").read_text())
    if root != gallery:
        raise ValueError(f"package SDK floors differ: {root} vs {gallery}")
    print(f"flutter={root['flutter']}")
    print(f"dart={root['sdk']}")


if __name__ == "__main__":
    main()
