#!/usr/bin/env python3
"""Update/check the authoritative Carbon commit and React version lock."""

import argparse
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / 'tool/carbon_reference.lock.json'
CARBON = ROOT / 'documentation/carbon'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--tag', help='Reviewed Carbon release tag when changing the pin')
    args = parser.parse_args()
    commit = subprocess.check_output(['git', '-C', str(CARBON), 'rev-parse', 'HEAD'], text=True).strip()
    indexed = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', ':documentation/carbon'], text=True).strip()
    if commit != indexed:
        raise ValueError('Stage the intended Carbon gitlink before updating its lock')
    version = json.loads((CARBON / 'packages/react/package.json').read_text())['version']
    current = json.loads(LOCK.read_text())
    if args.check:
        if current['carbonCommit'] != commit or current['carbonReactVersion'] != version:
            raise ValueError('Authoritative Carbon lock differs from the pinned checkout')
        print(f'Carbon pin lock matches {commit} / {version}')
        return
    tag = args.tag or (current.get('carbonTag') if current['carbonCommit'] == commit else None)
    if not tag:
        parser.error('--tag is required when changing the Carbon release pin')
    current.update(carbonCommit=commit, carbonReactVersion=version, carbonTag=tag)
    LOCK.write_text(json.dumps(current, indent=2) + '\n')
    print('Updated Carbon pin; refresh/review reference captures before committing')


if __name__ == '__main__':
    main()
