#!/usr/bin/env python3
"""Check gallery identity, published screenshot copies and release metadata."""
import argparse
import json
from pathlib import Path
import re
import shutil
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ['overview', 'button_dark', 'data_table']


def check(root=ROOT):
    web=root/'example/web'
    manifest=json.loads((web/'manifest.json').read_text())
    html=(web/'index.html').read_text()
    if manifest['name']!='Carbide Gallery' or manifest['orientation']!='any':
        raise ValueError('Gallery identity/orientation drift')
    if 'A new Flutter project.' in html or '#0175C2' in json.dumps(manifest) or 'carbide_gallery' in html:
        raise ValueError('Flutter starter metadata remains')
    if manifest['theme_color']!='#161616' or '<title>Carbide Gallery</title>' not in html:
        raise ValueError('Gallery browser identity drift')
    for icon in manifest['icons']:
        path=web/icon['src']
        svg=ET.fromstring(path.read_text())
        if svg.tag!='{http://www.w3.org/2000/svg}svg' or icon['type']!='image/svg+xml':
            raise ValueError('Unexpected gallery icon asset')
    pubspec=(root/'pubspec.yaml').read_text()
    section=re.search(r'^screenshots:\n([\s\S]*?)(?=^\w|\Z)',pubspec,re.M)
    paths=re.findall(r'^\s+path:\s*(\S+)',section[1] if section else '',re.M)
    expected=[f'screenshots/{name}.png' for name in SCREENSHOTS]
    if paths!=expected:
        raise ValueError('Published screenshots differ from reviewed listing set')
    for name,path in zip(SCREENSHOTS,paths):
        image=(root/path).read_bytes()
        if image!=(root/f'docs/images/{name}.png').read_bytes():
            raise ValueError(f'Stale published screenshot: {path}')
        if image[:8]!=b'\x89PNG\r\n\x1a\n' or len(image)>4*1024*1024:
            raise ValueError(f'Invalid/oversized listing PNG: {path}')
        width,height=struct.unpack('>II',image[16:24])
        if width<384 or height<384:
            raise ValueError(f'Listing PNG too small: {path}')
    ignore=(root/'.pubignore').read_text()
    if re.search(r'^screenshots/?$',ignore,re.M):
        raise ValueError('Listing screenshots are excluded from publication')
    security=(root/'SECURITY.md').read_text()
    if 'https://github.com/sunderee/carbide/security/advisories/new' not in security:
        raise ValueError('Missing private vulnerability reporting path')
    if '* @sunderee' not in (root/'.github/CODEOWNERS').read_text():
        raise ValueError('Missing repository-owner review policy')
    dependabot=(root/'.github/dependabot.yml').read_text()
    if 'package-ecosystem: github-actions' not in dependabot or 'interval: weekly' not in dependabot:
        raise ValueError('Dependency automation differs from recorded Actions-only decision')
    deploy=(root/'.github/workflows/deploy-gallery.yml').read_text()
    if any(f'"{p}"' not in deploy for p in ['pubspec.yaml','pubspec.lock']):
        raise ValueError('Root dependency changes do not trigger gallery deployment')
    print('Gallery identity, listing images and release metadata match reviewed inputs.')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sync-screenshots',action='store_true')
    args=parser.parse_args()
    if args.sync_screenshots:
        for name in SCREENSHOTS:
            shutil.copyfile(ROOT/f'docs/images/{name}.png',ROOT/f'screenshots/{name}.png')
    check()

if __name__=='__main__': main()
