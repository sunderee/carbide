#!/usr/bin/env python3
"""Check repository documentation links and compile the final adoption examples."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile
import urllib.parse
from sdk_floor import read_floor

ROOT = Path(__file__).resolve().parents[1]
GUIDE = ROOT / 'docs/releases/0.5.0-adoption.md'


def headings(source):
    used = {}
    result = set(re.findall(r'<(?:a|[^>]+)\s[^>]*id=["\']([^"\']+)', source))
    for label in re.findall(r'^#{1,6}\s+(.+?)(?:\s+#+)?$', source, re.M):
        label = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', label)
        slug = re.sub(r'[^\w\s-]', '', label.lower()).replace(' ', '-')
        count = used.get(slug, 0)
        used[slug] = count + 1
        result.add(slug + (f'-{count}' if count else ''))
    return result


def links(source):
    source = re.sub(r'```[\s\S]*?```', '', source)
    direct = re.findall(r'\]\(([^)]+)\)', source)
    references = re.findall(r'^\s*\[[^\]]+\]:\s*(\S+)', source, re.M)
    return [value.split()[0].strip('<>') for value in direct + references]


def check_links(files, root=ROOT):
    count = 0
    for path in files:
        for url in links(path.read_text()):
            parts = urllib.parse.urlsplit(url)
            if parts.scheme or parts.netloc:
                continue  # Remote primary links are reviewed separately.
            target = path.parent / urllib.parse.unquote(parts.path) if parts.path else path
            if not target.exists():
                raise ValueError(f'{path.relative_to(root)}: missing target {url}')
            if parts.fragment and target.suffix == '.md':
                if urllib.parse.unquote(parts.fragment) not in headings(target.read_text()):
                    raise ValueError(f'{path.relative_to(root)}: missing heading {url}')
            count += 1
    return count


def examples(source):
    blocks = re.findall(r'```dart\n([\s\S]*?)```', source)
    if not blocks:
        raise ValueError('Adoption guide has no checked API examples')
    sources = []
    for index, code in enumerate(blocks):
        code = code.strip()
        if not code.startswith('import '):
            code = ("import 'package:carbide/carbide.dart';\n"
                    "import 'package:flutter/widgets.dart';\n"
                    f'final Object example{index} = {code.removesuffix(";")};\n')
        sources.append('// ignore_for_file: unused_import\n' + code)
    return sources


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--links-only', action='store_true')
    args = parser.parse_args()
    files = [ROOT / name for name in ['README.md','CONTRIBUTING.md','CHANGELOG.md','SECURITY.md','example/README.md']]
    files += sorted((ROOT / 'docs').rglob('*.md'))
    count = check_links(files)
    print(f'Documentation: {count} local file/heading links resolve.')
    if args.links_only:
        return
    floor = read_floor((ROOT / 'pubspec.yaml').read_text())
    guide = GUIDE.read_text()
    if f"Flutter {floor['flutter']} / Dart {floor['sdk']}" not in guide:
        raise ValueError('Adoption guide SDK floor differs from the package')
    sources = examples(guide)
    with tempfile.TemporaryDirectory(prefix='.compiled-doc-examples-', dir=ROOT / 'example') as directory:
        scratch = Path(directory)
        for index, source in enumerate(sources):
            (scratch / f'example_{index}.dart').write_text(source)
        (scratch / 'analysis_options.yaml').write_text('analyzer:\n  language:\n    strict-casts: true\n    strict-inference: true\n    strict-raw-types: true\n')
        subprocess.run(['dart','analyze',str(scratch)], cwd=ROOT / 'example', check=True)
    print(f'Compiled {len(sources)} complete adoption API examples.')

if __name__ == '__main__': main()
