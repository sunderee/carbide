#!/usr/bin/env python3
"""Verify image bytes match committed capture provenance without Carbon checkout."""

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def verify_images(manifest, directory):
    expected = {f"{story['component']}/{theme}.png" for story in manifest['stories'] for theme in manifest['themes']}
    hashes = manifest['imageSha256']
    if set(hashes) != expected:
        raise ValueError('Every reference image needs capture provenance')
    for relative in sorted(expected):
        actual = hashlib.sha256((directory / relative).read_bytes()).hexdigest()
        if actual != hashes[relative]:
            raise ValueError(f'Reference bytes differ from capture provenance: {relative}')
    return len(expected)


def main():
    directory = ROOT / 'test/fidelity/references'
    count = verify_images(json.loads((directory / 'manifest.json').read_text()), directory)
    print(f'Reference image provenance passes: {count} SHA-256 hashes.')


if __name__ == '__main__':
    main()
