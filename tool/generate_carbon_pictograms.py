#!/usr/bin/env python3
"""Generate Carbide's pictogram data from the pinned Carbon sources.

The pictogram analogue of tool/generate_carbon_icons.py: reads all 1,564
SVGs in documentation/carbon/packages/pictograms/src/svg (flat, single
32x32-grid fill-based artwork per pictogram), validates two-way against
pictograms.yml, and emits:

  - lib/src/pictograms/generated/pictograms_<bucket>.dart
  - lib/src/pictograms/carbon_pictograms.dart   (the CarbonPictograms index)
  - test/pictograms/all_pictograms.dart         (test-only full list)
  - tool/carbon_pictograms.lock.json            (update detection)

Pictograms reuse the icon data model: each becomes a CarbonIconData with a
single size-32 artwork (the 32-grid master), painted by CarbonIconPainter and
rendered by the CarbonPictogram widget at 48px+ per Carbon guidance.

Run from the repository root:  python3 tool/generate_carbon_pictograms.py
Re-run when bumping the Carbon submodule; review the diff.
"""

from __future__ import annotations

import re
from pathlib import Path

from generation_check import run_generation, write_generated, remove_generated

import icons_lock
from carbon_svg import extract
from generate_carbon_icons import (
    HEADER,
    artwork_dart,
    bucket_of,
    identifier,
    parse_deprecated_yml,
)

ROOT = Path(__file__).resolve().parent.parent
PKG = ROOT / "documentation/carbon/packages/pictograms"
SVG = PKG / "src/svg"
GEN_DIR = ROOT / "lib/src/pictograms/generated"
INDEX = ROOT / "lib/src/pictograms/carbon_pictograms.dart"
ALL_LIST = ROOT / "test/pictograms/all_pictograms.dart"
LOCKFILE = ROOT / "tool/carbon_pictograms.lock.json"


def parse_pictograms_yml() -> set[str]:
    names: set[str] = set()
    for line in (PKG / "pictograms.yml").read_text().splitlines():
        m = re.match(r"^- name: (.+)$", line)
        if m:
            names.add(m.group(1).strip().strip("'\""))
    return names


def collect_assets() -> dict[str, dict]:
    """Same shape as the icon registry: name -> {'assets': {32: Path}}."""
    return {
        path.stem: {"namespace": "", "assets": {32: path}}
        for path in sorted(SVG.glob("*.svg"))
    }


def validate(pictograms: dict[str, dict], registry: set[str]) -> None:
    missing = sorted(set(pictograms) - registry)
    orphaned = sorted(registry - set(pictograms))
    problems = [f"asset `{n}` missing from pictograms.yml" for n in missing]
    problems += [f"pictograms.yml entry `{n}` has no asset" for n in orphaned]
    if problems:
        raise SystemExit(
            "registry validation failed:\n  " + "\n  ".join(problems[:20])
        )


def main() -> None:
    registry = parse_pictograms_yml()
    deprecated = parse_deprecated_yml(PKG / "deprecated.yml")
    pictograms = collect_assets()
    validate(pictograms, registry)

    entries = []
    seen: dict[str, str] = {}
    for name in sorted(pictograms, key=str.lower):
        ident = identifier(name, "")
        assert ident not in seen, f"identifier clash: {ident} ({name})"
        seen[ident] = name
        vbw, vbh, shapes = extract(pictograms[name]["assets"][32])
        assert vbw == vbh == 32, f"unexpected pictogram viewBox: {name}"
        entries.append((ident, name, [(32, vbw, vbh, shapes)]))
    entries.sort(key=lambda e: e[0].lower().lstrip("$"))

    buckets: dict[str, list] = {}
    for entry in entries:
        buckets.setdefault(bucket_of(entry[0]), []).append(entry)

    # Output directories are created only after generation is verified.
    for old in GEN_DIR.glob("pictograms_*.dart"):
        remove_generated(old)
    for bucket, items in sorted(buckets.items()):
        lines = [
            HEADER.replace("generate_carbon_icons", "generate_carbon_pictograms")
            .replace("@carbon/icons", "@carbon/pictograms")
            .replace("Icon artwork", "Pictogram artwork"),
            "import '../../icons/carbon_icon_data.dart';",
            "",
        ]
        for ident, name, artwork in items:
            lines.append(f"/// The Carbon `{name}` pictogram data.")
            lines.append(f"const CarbonIconData {ident} = CarbonIconData(")
            lines.append(f"  name: '{name}',")
            lines.append("  artwork: <CarbonIconArtwork>[")
            for size, vbw, vbh, shapes in artwork:
                lines += artwork_dart(size, vbw, vbh, shapes, "    ")
            lines.append("  ],")
            lines.append(");")
            lines.append("")
        write_generated(GEN_DIR / f"pictograms_{bucket}.dart", "\n".join(lines))

    lines = [
        HEADER.replace("generate_carbon_icons", "generate_carbon_pictograms")
        .replace("@carbon/icons", "@carbon/pictograms")
        .replace("Icon artwork", "Pictogram artwork"),
        "import '../icons/carbon_icon_data.dart';",
    ]
    for bucket in sorted(buckets):
        lines.append(
            f"import 'generated/pictograms_{bucket}.dart' as {bucket}_;"
        )
    lines += [
        "",
        "/// Every Carbon pictogram, as generated [CarbonIconData] constants.",
        "///",
        "/// Each entry is an independent constant, so unused pictograms are",
        "/// tree-shaken from release builds. Render one with the",
        "/// `CarbonPictogram` widget at 48 logical pixels or larger.",
        "abstract final class CarbonPictograms {",
    ]
    for ident, name, _ in entries:
        bucket = bucket_of(ident)
        lines.append(f"  /// The Carbon `{name}` pictogram.")
        if name in deprecated:
            reason = deprecated[name].replace(r"$", r"\$").replace("'", r"\'")
            lines.append(f"  @Deprecated('{reason}')")
        lines.append(
            f"  static const CarbonIconData {ident} = {bucket}_.{ident};"
        )
        lines.append("")
    lines.append("}")
    write_generated(INDEX, "\n".join(lines))

    lines = [
        HEADER.replace("lib/", "test/")
        .replace("generate_carbon_icons", "generate_carbon_pictograms")
        .replace("@carbon/icons", "@carbon/pictograms")
        .replace("Icon artwork", "Pictogram artwork"),
        "// Test-only: referencing every pictogram here would defeat",
        "// tree-shaking in an app, which is why this list is not in lib/.",
        "",
        "import 'package:carbide/carbide.dart';",
    ]
    for bucket in sorted(buckets):
        lines.append(
            "import 'package:carbide/src/pictograms/generated/"
            f"pictograms_{bucket}.dart' as {bucket}_;"
        )
    lines += [
        "",
        "/// Every generated Carbon pictogram.",
        "const List<CarbonIconData> allCarbonPictograms = <CarbonIconData>[",
    ]
    for ident, _, _ in entries:
        lines.append(f"  {bucket_of(ident)}_.{ident},")
    lines += ["];", ""]
    # Output directories are created by the deferred writer.
    write_generated(ALL_LIST, "\n".join(lines))

    previous = icons_lock.read_lock(LOCKFILE)
    lock = icons_lock.compute_lock(pictograms, deprecated)
    icons_lock.write_lock(lock, LOCKFILE, writer=write_generated)
    if previous is not None:
        print(icons_lock.format_report(icons_lock.diff_locks(previous, lock)))

    print(
        f"pictograms: {len(entries)} (registry {len(registry)}), "
        f"deprecated: {sum(1 for e in entries if e[1] in deprecated)}, "
        f"buckets: {len(buckets)}"
    )


if __name__ == "__main__":
    run_generation(main)
