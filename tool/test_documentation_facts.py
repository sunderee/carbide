#!/usr/bin/env python3
import unittest
from documentation_facts import artwork_count, check_claims

class DocumentationFactsTests(unittest.TestCase):
    def test_dart_dollar_names_and_wrapped_declarations_count(self):
        self.assertEqual(artwork_count('static const CarbonIconData $4K = a;\nstatic const CarbonIconData\n longName = b;'), 2)
    def test_comments_and_strings_are_not_artwork(self):
        self.assertEqual(artwork_count('// static const CarbonIconData fake = a;\nconst s = "static const CarbonIconData fake = a;";'), 0)
    def test_duplicate_names_fail(self):
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            artwork_count('static const CarbonIconData a = a;\nstatic const CarbonIconData a = b;')
    def test_stale_counts_and_theme_names_fail(self):
        for text in ['2,673 Carbon icons', '1,564 Carbon pictograms', 'CarbideThemeData']:
            with self.subTest(text=text), self.assertRaises(ValueError):
                check_claims(text, {'icons': 2775, 'pictograms': 1576})
    def test_widgets_only_claim_fails_but_sdk_import_example_is_valid(self):
        with self.assertRaises(ValueError):
            check_claims('Built only on package:flutter/widgets.dart', {})
        check_claims("import 'package:flutter/widgets.dart';", {})
    def test_correct_counts_pass(self):
        check_claims('2,775 Carbon icons and 1,576 Carbon pictograms', {'icons': 2775, 'pictograms': 1576})
if __name__ == '__main__': unittest.main()
