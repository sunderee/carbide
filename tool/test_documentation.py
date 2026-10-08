#!/usr/bin/env python3
from pathlib import Path
import tempfile
import unittest
from check_documentation import check_links, examples, headings, links

class DocumentationTests(unittest.TestCase):
    def test_heading_ids_handle_code_punctuation_and_duplicates(self):
        self.assertEqual(headings('# API `names` & scope\n## Again\n## Again'), {'api-names--scope','again','again-1'})
    def test_code_example_links_are_not_document_navigation(self):
        source='[Guide](guide.md#intro)\n```dart\nText("[bad](missing.md)");\n```\n[reference]: other.md'
        self.assertEqual(links(source), ['guide.md#intro','other.md'])
    def test_missing_files_and_anchors_fail(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp);page=root/'index.md';target=root/'guide.md';target.write_text('# Intro\n')
            for url in ['missing.md','guide.md#missing']:
                page.write_text(f'[Link]({url})')
                with self.assertRaises(ValueError): check_links([page], root)
            page.write_text('[Link](guide.md#intro)');self.assertEqual(check_links([page],root),1)
    def test_complete_sources_and_expression_wrapping(self):
        source="```dart\nimport 'package:flutter/widgets.dart';\nclass Demo {}\n```\n```dart\nconst SizedBox(width: 20)\n```"
        result=examples(source)
        self.assertIn('class Demo {}',result[0]);self.assertIn('final Object example1',result[1])
    def test_guide_must_have_examples(self):
        with self.assertRaisesRegex(ValueError,'no checked'): examples('# Guide')
if __name__=='__main__': unittest.main()
