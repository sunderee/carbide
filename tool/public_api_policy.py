#!/usr/bin/env python3
"""Check deliberate compatibility classifications for every barrel export."""
import json
from pathlib import Path
import re
from public_surface import inventory

ROOT = Path(__file__).resolve().parents[1]


def validate(exports, policy, source):
    if set(exports) != set(policy['exports']):
        raise ValueError('Every public declaration needs an explicit stability classification')
    for name, entry in policy['exports'].items():
        if entry.get('stability') not in {'stable', 'advanced'}:
            raise ValueError(f'{name}: unknown stability classification')
        if entry['stability'] == 'advanced':
            if not source(name).startswith('/// **Advanced API.**'):
                raise ValueError(f'{name}: missing adjacent advanced API dartdoc marker')
    for name in policy['internal']:
        if name in exports:
            raise ValueError(f'{name}: internal declaration leaked through the barrel')


def adjacent_doc(name, entry):
    text = (ROOT / entry['source']).read_text()
    # Inventory establishes the declaration's identity/source. Read the
    # immediately preceding doc block; a marker elsewhere cannot satisfy it.
    match = re.search(rf'^(?:abstract\s+final\s+)?(?:class|typedef|\w+)\s+{re.escape(name)}\b', text, re.M)
    if not match:
        raise ValueError(f'{name}: missing source declaration')
    lines = text[:match.start()].splitlines()
    docs = []
    for line in reversed(lines):
        if not line.startswith('///'):
            break
        docs.append(line)
    doc = '\n'.join(reversed(docs))
    marker = doc.find('/// **Advanced API.**')
    return doc[marker:] if marker >= 0 else doc


def main():
    exports = inventory()
    policy = json.loads((ROOT / 'tool/public_api_policy.json').read_text())
    validate(exports, policy, lambda name: adjacent_doc(name, exports[name]))
    advanced = sum(e['stability'] == 'advanced' for e in policy['exports'].values())
    print(f'Public API policy: {len(exports) - advanced} stable, {advanced} advanced; internals hidden.')


if __name__ == '__main__':
    main()
