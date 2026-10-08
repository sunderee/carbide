#!/usr/bin/env python3
"""Require lifetime scenarios for every source that constructs a portal."""

import json
import re
from public_surface import ROOT, mask_source


def owners(root=ROOT):
    result = set()
    for path in (root / 'lib/src').rglob('*.dart'):
        source = mask_source(path.read_text())
        if re.search(r'\bOverlayPortal(?:Controller)?(?:\.\w+)?\s*\(', source):
            result.add(path.relative_to(root).as_posix())
    return result


def validate(actual, manifest, cases):
    if actual != set(manifest):
        raise ValueError(f'Portal owner inventory changed: {sorted(actual ^ set(manifest))}')
    for owner, scenarios in manifest.items():
        if not scenarios:
            raise ValueError(f'{owner}: missing lifetime scenario')
        for name in scenarios:
            if name not in cases:
                raise ValueError(f'{owner}: missing harness case {name}')


def scenario_names(source):
    names = set()
    for expression in re.findall(r'\bname:\s*([^,\n]+)', source):
        names.update(re.findall(r"'([^']+)'", expression))
    picker_loop = re.search(r'for\s*\(final name in <String>\[(.*?)\]\)\s*_picker\(name\)', source, re.S)
    if picker_loop:
        names.update(re.findall(r"'([^']+)'", picker_loop.group(1)))
    return names


def main():
    manifest = json.loads((ROOT / 'tool/overlay_lifetimes.json').read_text())
    source = (ROOT / 'test/leaks/overlay_lifetime_test.dart').read_text()
    cases = scenario_names(source)
    validate(owners(), manifest, cases)
    print(f'Overlay lifetime inventory: {len(manifest)} portal owners, {len(cases)} lifecycle scenarios.')


if __name__ == '__main__':
    main()
