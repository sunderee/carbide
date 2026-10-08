#!/usr/bin/env python3
"""Build small, test-only locale glyph fixtures from pinned IBM Plex sources.

Requires fonttools==4.66.1. Run from the repository root. Font assets remain
under test/ and are excluded by .pubignore; production fonts are unchanged.
"""
from pathlib import Path
from urllib.request import urlopen
import hashlib
import io
import json

from fontTools import subset, ttLib
import fontTools

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'test/support/fonts'
COMMIT = '763c36ef9117782905ae010056dfbe8fd2653a25'
BASE = f'https://raw.githubusercontent.com/IBM/plex/{COMMIT}/'
SPECS = [
    ('Carbide Test Arabic', 'CarbideTestArabic.ttf',
     'packages/plex-sans-arabic/fonts/complete/ttf/IBMPlexSansArabic-Regular.ttf',
     set(range(0x600, 0x700)) | set(range(0x750, 0x780)) | set(range(0x8A0, 0x900))),
    ('Carbide Test Japanese', 'CarbideTestJapanese.ttf',
     'packages/plex-sans-jp/fonts/complete/ttf/hinted/IBMPlexSansJP-Regular.ttf',
     set(range(0x3000, 0x3100)) | {ord(c) for c in '年月日火水木金土令和開始終了付前次'}),
]

def main():
    if fontTools.__version__ != '4.66.1':
        raise RuntimeError('Use fonttools==4.66.1 for deterministic regeneration.')
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {'sourceRepository': 'https://github.com/IBM/plex',
                'sourceCommit': COMMIT, 'fontToolsVersion': fontTools.__version__, 'fonts': []}
    for family, filename, source, points in SPECS:
        data = urlopen(BASE + source).read()
        font = ttLib.TTFont(io.BytesIO(data), recalcTimestamp=False)
        available = set(font.getBestCmap())
        wanted = points & available
        options = subset.Options()
        options.recalc_timestamp = False
        options.name_IDs = ['*']
        options.name_legacy = True
        options.name_languages = ['*']
        cutter = subset.Subsetter(options=options)
        cutter.populate(unicodes=wanted)
        cutter.subset(font)
        # Rename the derived fonts; retain copyright and SIL OFL notices.
        names = {1: family, 2: 'Regular', 3: family + '-test-subset',
                 4: family + ' Regular', 6: family.replace(' ', '') + '-Regular',
                 16: family, 17: 'Regular'}
        for record in font['name'].names:
            if record.nameID in names:
                record.string = names[record.nameID].encode(record.getEncoding())
        font.save(OUT / filename, reorderTables=True)
        result = (OUT / filename).read_bytes()
        manifest['fonts'].append({'family': family, 'file': filename, 'sourcePath': source,
            'sourceSha256': hashlib.sha256(data).hexdigest(),
            'sha256': hashlib.sha256(result).hexdigest(), 'bytes': len(result),
            'codePoints': sorted(wanted)})
        print(filename, len(result), 'bytes,', len(wanted), 'code points')
    license_path = 'packages/plex-sans-arabic/fonts/complete/ttf/license.txt'
    (OUT / 'OFL.txt').write_bytes(urlopen(BASE + license_path).read())
    (OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')

if __name__ == '__main__':
    main()
