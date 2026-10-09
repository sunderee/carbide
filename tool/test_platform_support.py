#!/usr/bin/env python3
from pathlib import Path
import unittest
from platform_support import ROOT, classify, run_commands

class PlatformSupportTests(unittest.TestCase):
    def setUp(self):
        workflow = ROOT / '.github/workflows'
        self.sources = [(workflow / p).read_text() for p in ['ci.yaml','verify.yaml','gallery-web.yaml','os-matrix.yaml']]
    def test_current_configuration_is_classified(self):
        result = classify(*self.sources)
        self.assertEqual(result['hosts'], ['macos-latest','windows-latest'])
        self.assertIn('integration_test/font_resolution_test.dart', result['nativeTargets'])
    def test_run_blocks_do_not_include_adjacent_steps(self):
        source = '    - run: |\n        flutter test\n    - uses: other/action\n    - run: dart analyze\n'
        self.assertEqual(run_commands(source), ['flutter test','dart analyze'])
    def test_comment_is_not_a_test_command(self):
        self.sources[1] = self.sources[1].replace('run: flutter test --coverage','run: echo skipped # flutter test --coverage')
        with self.assertRaisesRegex(ValueError, 'Linux'): classify(*self.sources)
    def test_missing_minimum_gallery_test_fails(self):
        self.sources[1] = self.sources[1].replace('          flutter test\n', '          echo skipped\n', 1)
        with self.assertRaisesRegex(ValueError, 'independent'): classify(*self.sources)
    def test_native_font_contract_removal_fails(self):
        self.sources[2] = self.sources[2].replace('integration_test/font_resolution_test.dart','integration_test/unrelated.dart')
        with self.assertRaisesRegex(ValueError, 'font'): classify(*self.sources)
    def test_wasm_build_removal_fails(self):
        self.sources[2] = self.sources[2].replace('--wasm','')
        with self.assertRaisesRegex(ValueError, 'WASM'): classify(*self.sources)
    def test_changed_host_matrix_requires_review(self):
        self.sources[3] = self.sources[3].replace('os: [macos-latest, windows-latest]', 'os: [ubuntu-latest]')
        with self.assertRaisesRegex(ValueError, 'platform set'): classify(*self.sources)
if __name__ == '__main__': unittest.main()
