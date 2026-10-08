#!/usr/bin/env python3
"""Enforce family-level guideline coverage and cited axis exceptions."""

import json
from pathlib import Path
import re

from public_surface import ROOT


def check_exceptions(source, name):
    for match in re.finditer(r'\bexpectA11y\s*\([^;]*?\);', source, re.S):
        call = match.group()
        if not re.search(r'\b(?:tapTargets|labeled)\s*:\s*(?!true\b)', call):
            continue
        comments = source[:match.start()].splitlines()[-10:]
        citation = next((line.split('a11y-exception:', 1)[1].strip()
                         for line in comments if 'a11y-exception:' in line), '')
        upstream = re.fullmatch(r'https://github.com/carbon-design-system/carbon/blob/[0-9a-f]{40}/packages/styles/scss/[^ ]+\.scss', citation)
        issue = re.fullmatch(r'https://github.com/sunderee/carbide/issues/\d+', citation)
        if not (upstream or issue):
            line = source[:match.start()].count('\n') + 1
            raise ValueError(f'{name}:{line}: axis override needs a pinned a11y-exception citation')
        reasons = [line for line in comments if line.lstrip().startswith('//')
                   and 'a11y-exception:' not in line]
        if not reasons:
            raise ValueError(f'{name}: exception needs an adjacent reason')


def check_inventory(families, policies, root=ROOT):
    if set(families) != set(policies):
        raise ValueError(f'Unclassified accessibility families: {sorted(set(families) ^ set(policies))}')
    for family, policy in policies.items():
        if policy.get('exemption'):
            continue
        suites = policy.get('suites', [])
        if not suites:
            raise ValueError(f'{family}: missing guideline suite or reasoned exemption')
        for suite in suites:
            source = (root / suite).read_text()
            if 'expectA11y(' not in source:
                raise ValueError(f'{family}: {suite} does not run the guideline helper')
            if policy.get('matrix') and f"'{family}':" not in source:
                raise ValueError(f'{family}: missing state-matrix entry')
    for path in (root / 'test').rglob('*.dart'):
        check_exceptions(path.read_text(), path.relative_to(root))


def main():
    surface = json.loads((ROOT / 'tool/public_surface.json').read_text())
    policies = json.loads((ROOT / 'tool/accessibility_inventory.json').read_text())
    check_inventory(surface['families'], policies)
    tested = sum(not p.get('exemption') for p in policies.values())
    print(f'Accessibility inventory: {tested} guideline families, {len(policies)-tested} reasoned exemptions; every axis override cited.')


if __name__ == '__main__':
    main()
