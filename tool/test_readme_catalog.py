#!/usr/bin/env python3
from pathlib import Path
import tempfile
import unittest
from readme_catalog import categories, render, update

class ReadmeTests(unittest.TestCase):
    def test_catalog_order_and_live_metadata_exclude_comments(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);folder=root/'example/lib/src/pages';folder.mkdir(parents=True)
            (folder/'demo_pages.dart').write_text("final GalleryCategory demoCategory = GalleryCategory(\n title: 'Demo',\n entries: <GalleryEntry>[\n // GalleryEntry(slug: 'fake', title: 'Fake'),\n GalleryEntry(slug: 'real', title: 'Real', builder: () => const Demo()),\n ],\n);\n")
            (folder.parent/'catalog.dart').write_text('final kCatalog = <GalleryCategory>[demoCategory];')
            self.assertEqual(categories(root), [{'title':'Demo','entries':[('real','Real')]}])
    def test_coverage_comes_from_exports_and_story_inventory(self):
        groups=[{'title':'Demo','entries':[('real','Real')]}]
        exports={'Widget':{'visual':True},'Value':{'visual':False}}
        policy={name:{'routes':['real']} for name in exports}
        data=render(groups,exports,policy,[{}],1)
        self.assertIn('**2 declarations**', data['coverage'])
        self.assertIn('**1 widget classes**', data['coverage'])
        self.assertIn('**1 curated default stories**', data['fidelity'])
        self.assertIn('/components/real', data['catalog'])
    def test_duplicate_routes_fail(self):
        with self.assertRaisesRegex(ValueError,'Duplicate'):
            render([{'title':'Demo','entries':[('a','A'),('a','A')]}],{}, {},[],0)
    def test_missing_or_repeated_markers_fail(self):
        for source in ['', '<!-- carbide-readme:coverage:start --><!-- carbide-readme:coverage:end -->'*2]:
            with self.assertRaisesRegex(ValueError,'one README'): update(source,{'coverage':'new'})
    def test_generated_block_replacement_preserves_other_prose(self):
        source='Before\n<!-- carbide-readme:coverage:start -->old<!-- carbide-readme:coverage:end -->\nAfter'
        result=update(source, {'coverage':'new'})
        self.assertTrue(result.startswith('Before'))
        self.assertTrue(result.endswith('After'))
        self.assertIn('new',result)
        self.assertNotIn('old',result)
if __name__=='__main__': unittest.main()
