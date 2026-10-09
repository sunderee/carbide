#!/usr/bin/env python3
"""Independently compare Dart colors to Carbon's committed JS API snapshot.

No generator, DTCG parser, theme resolver or generated Dart test is imported.
The snapshot comes from Carbon's own JavaScript public-API test/build pipeline.
"""

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SNAPSHOT = ROOT / 'documentation/carbon/packages/colors/__tests__/__snapshots__/public-api-test.js.snap'
COLORS = ROOT / 'lib/src/foundations/colors.dart'


def parse_snapshot(source):
    section = re.search(r'exports\[`@carbon/colors public API JavaScript exports 1`\] = `\n\[(.*?)\n\]\n`;', source, re.S)
    if section is None:
        raise ValueError('Carbon JS snapshot format changed')
    values = {}
    for line in section[1].splitlines():
        if not line.strip():
            continue
        if re.fullmatch(r'  "[\w.]+: \[Same as [\w.]+\]",?', line):
            continue  # Jest identity notation for aggregate namespace aliases.
        if line.strip() == '"rgba: [Function]",':
            continue  # JavaScript formatting helper, not a palette constant.
        match = re.fullmatch(r'  "([\w.]+): "(#[0-9a-fA-F]{6})"",?', line)
        if match is None:
            raise ValueError(f'Unsupported JS snapshot entry: {line}')
        name, color = match.groups()
        if '.' in name:  # Aggregate ramp aliases; only flat exports map to constants.
            continue
        if name in values:
            raise ValueError(f'Duplicate JS export: {name}')
        values[name] = int(color[1:], 16) | 0xFF000000
    if not values:
        raise ValueError('No flat JS color exports')
    return values


def compare(snapshot, dart_source):
    upstream = parse_snapshot(snapshot)
    dart = {name: int(value, 16) for name, value in re.findall(r'static const Color (\w+) = Color\((0x[0-9A-Fa-f]{8})\);', dart_source)}
    if set(dart) != set(upstream):
        raise ValueError(f'Color API differs: {sorted(set(dart) ^ set(upstream))}')
    differences = [name for name in upstream if upstream[name] != dart[name]]
    if differences:
        raise ValueError(f'Color values differ from Carbon JS exports: {differences}')
    return len(upstream)


def main():
    count = compare(SNAPSHOT.read_text(), COLORS.read_text())
    print(f'Independent color check passes: {count} JS exports match Dart constants.')


if __name__ == '__main__':
    main()
