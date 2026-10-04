#!/usr/bin/env python3
# Copyright 2026 Bizjak Tech OÜ
# Licensed under the Apache License, Version 2.0. See LICENSE.
"""Guard Carbon duration resolution and explicit essential-motion exceptions."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# These controllers report ongoing activity, rather than decorating a change.
# The progress-bar exception covers ONLY its indeterminate sweep: its
# determinate value transition must still resolve every Carbon duration token.
ESSENTIAL_MOTION = {
    "components/loading/carbon_loading.dart":
        "The spinner (also used by inline loading) signals an active operation.",
    "components/progress_bar/carbon_progress_bar.dart":
        "The indeterminate sweep signals activity when progress is unknown.",
}

_NON_CODE = re.compile(
    r"//[^\n]*|/\*[\s\S]*?\*/|'''[\s\S]*?'''|\"\"\"[\s\S]*?\"\"\""
    r"|'(?:\\.|[^'\\])*'|\"(?:\\.|[^\"\\])*\""
)
_ANIMATION = re.compile(
    r"\b(?:Animated\w+|TweenAnimationBuilder|AnimationController|"
    r"ImplicitlyAnimatedWidget)\b|\.animateTo\s*\("
)
_RESOLVED_TOKEN = re.compile(
    r"\bcarbonDuration\s*\(\s*\w+\s*,\s*CarbonDuration\.\w+\s*,?\s*\)"
)


def violations(name: str, source: str) -> list[str]:
    """Check code, ignoring examples, comments and string literals."""
    code = _NON_CODE.sub(lambda match: " " * len(match.group()), source)
    errors = []
    if _ANIMATION.search(code) and not re.search(r"\bcarbonDuration\s*\(", code):
        if name not in ESSENTIAL_MOTION:
            errors.append("animated source must call carbonDuration")
    unresolved = _RESOLVED_TOKEN.sub("", code)
    if re.search(r"\bCarbonDuration\.\w+", unresolved):
        errors.append("every CarbonDuration token must pass through carbonDuration")
    return errors


def main() -> int:
    failures = []
    for folder in ("components", "theme"):
        for path in sorted((ROOT / "lib/src" / folder).rglob("*.dart")):
            name = path.relative_to(ROOT / "lib/src").as_posix()
            failures.extend(f"{name}: {error}" for error in violations(name, path.read_text()))
    for name, rationale in ESSENTIAL_MOTION.items():
        source = ROOT / "lib/src" / name
        if not rationale or not source.exists() or not _ANIMATION.search(source.read_text()):
            failures.append(f"{name}: stale or undocumented essential-motion exception")
    if failures:
        print("\n".join(failures))
        return 1
    print("Motion policy source guard passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
