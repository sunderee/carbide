#!/usr/bin/env python3
"""Render README coverage/categorization from the catalog and export policy."""
import argparse
import json
from pathlib import Path
import re
from generate_gallery_examples import balanced_end
from public_surface import inventory, mask_source

ROOT = Path(__file__).resolve().parents[1]


def literal_field(source, name):
    match = re.search(rf'\b{re.escape(name)}\s*:', mask_source(source))
    if not match:
        raise ValueError(f'Missing {name} field')
    literal = re.match(r"\s*'([^']+)'", source[match.end():])
    if not literal:
        raise ValueError(f'{name} must use reviewed literal metadata')
    return literal[1]


def categories(root=ROOT):
    pages = root / 'example/lib/src/pages'
    available = {}
    for path in pages.glob('*_pages.dart'):
        source=path.read_text(); masked=mask_source(source)
        match=re.search(r'final GalleryCategory (\w+) = GalleryCategory\(', masked)
        if not match: raise ValueError(f'Unsupported gallery category declaration: {path}')
        end=balanced_end(masked, match.end()-1)
        body=source[match.end():end]
        title=literal_field(body, 'title')
        body_mask=mask_source(body)
        entries=[]
        for entry in re.finditer(r'\bGalleryEntry\(', body_mask):
            finish=balanced_end(body_mask, entry.end()-1)
            text=body[entry.end():finish]
            entries.append((literal_field(text,'slug'),literal_field(text,'title')))
        if not entries: raise ValueError('Missing literal category/entry metadata')
        available[match[1]]={'title':title,'entries':entries}
    source=(root/'example/lib/src/catalog.dart').read_text()
    order=re.search(r'kCatalog\s*=\s*<GalleryCategory>\[([^\]]+)\]', mask_source(source))
    if not order: raise ValueError('Unsupported catalog composition')
    names=re.findall(r'\b\w+Category\b', order[1])
    if set(names)!=set(available): raise ValueError('Catalog imports/category inventory differ')
    return [available[name] for name in names]


def block(title, content):
    return f'<!-- carbide-readme:{title}:start -->\n{content}\n<!-- carbide-readme:{title}:end -->'


def render(groups, exports, policy, stories, families):
    routes=[slug for group in groups for slug,_ in group['entries']]
    if len(routes)!=len(set(routes)): raise ValueError('Duplicate catalog slug')
    summary=(f"The checked catalog contains **{len(routes)} routes**. The public barrel exposes "
        f"**{len(exports)} declarations**, including **{sum(e['visual'] for e in exports.values())} widget classes** "
        f"across **{families} source families**. These counts include composition and inherited-scope "
        "types, not separate independent controls. The [API-to-gallery policy](docs/testing/gallery-coverage.md) "
        "records live references and reasoned composition/nonvisual exemptions.")
    lines=['| Gallery category | Pages | Public widget declarations mapped |','| --- | --- | --- |']
    for group in groups:
        slugs={slug for slug,_ in group['entries']}
        widget_count=sum(e['visual'] and bool(slugs.intersection(policy[name]['routes'])) for name,e in exports.items())
        links=', '.join(f'[{title}](https://sunderee.github.io/carbide/#/components/{slug})' for slug,title in group['entries'])
        lines.append(f"| {group['title']} | {links} | {widget_count} |")
    lines+=['','A widget can map to several categories; these per-category counts are not additive. '
        'Mappings include composed variants rather than implying a dedicated page for each declaration. '
        'Component pages provide clipboard copy/expand controls and source-derived functional examples; '
        'CI compiles their actual displayed code and reviewed Button configurations.']
    fidelity=(f"**{len(stories)} curated default stories** compare selected families with committed upstream Carbon "
        "Storybook images. Their 24×24 luminance-grid scores, control dimensions, token colors and state "
        "contracts detect reviewed drift; they do not establish pixel identity or all-variant coverage. "
        "Other family specimens use Linux golden regression baselines and behavior/accessibility tests. "
        "The [parity matrix](docs/carbon-parity.md) records these distinct tiers and implementation boundaries.")
    return {'coverage':summary,'catalog':'\n'.join(lines),'fidelity':fidelity}


def update(source, sections):
    for name,value in sections.items():
        pattern=rf'<!-- carbide-readme:{name}:start -->[\s\S]*?<!-- carbide-readme:{name}:end -->'
        if len(re.findall(pattern,source))!=1: raise ValueError(f'Expected one README {name} block')
        source=re.sub(pattern,lambda _:block(name,value),source)
    return source


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args=parser.parse_args()
    exports=inventory()
    policy=json.loads((ROOT/'tool/gallery_coverage.json').read_text())['exports']
    stories=json.loads((ROOT/'tool/fidelity/stories.json').read_text())['stories']
    families=len(json.loads((ROOT/'tool/public_surface.json').read_text())['families'])
    source=(ROOT/'README.md').read_text()
    generated=update(source,render(categories(),exports,policy,stories,families))
    if args.check:
        if source!=generated: raise SystemExit('Stale README catalog/coverage: run python3 tool/readme_catalog.py')
    else:(ROOT/'README.md').write_text(generated)
    print('README catalog, export counts and fidelity coverage match source.')

if __name__=='__main__': main()
