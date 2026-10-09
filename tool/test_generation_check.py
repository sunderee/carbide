#!/usr/bin/env python3
"""Generated drift checks must detect changes without repairing them."""

import tempfile
import unittest
from pathlib import Path
from generation_check import GenerationPlan


class GenerationCheckTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        (self.root / 'lib').mkdir()

    def test_drift_fails_without_changing_existing_or_creating_new_files(self):
        existing = self.root / 'lib/token.dart'
        existing.write_text('incorrect')
        plan = GenerationPlan(self.root)
        plan.add(existing, 'correct')
        missing = self.root / 'test/missing.dart'
        plan.add(missing, 'new')
        with self.assertRaisesRegex(ValueError, 'Generated output drift'):
            plan.finish(True, format_dart=False)
        self.assertEqual(existing.read_text(), 'incorrect')
        self.assertFalse(missing.exists())
        self.assertFalse(missing.parent.exists())

    def test_obsolete_file_fails_check_and_is_removed_only_in_write_mode(self):
        old = self.root / 'lib/obsolete.dart'
        old.write_text('obsolete')
        plan = GenerationPlan(self.root)
        plan.removals.add(old)
        with self.assertRaisesRegex(ValueError, 'obsolete.dart'):
            plan.finish(True, format_dart=False)
        self.assertTrue(old.exists())
        plan.finish(False, format_dart=False)
        self.assertFalse(old.exists())

    def test_recreated_bucket_is_compared_instead_of_deleted(self):
        bucket = self.root / 'lib/bucket.dart'
        bucket.write_text('same')
        plan = GenerationPlan(self.root)
        plan.removals.add(bucket)
        plan.add(bucket, 'same')
        plan.finish(True, format_dart=False)
        self.assertEqual(bucket.read_text(), 'same')

    def test_output_outside_repository_is_rejected(self):
        with self.assertRaises(ValueError):
            GenerationPlan(self.root).add(self.root.parent / 'outside.dart', '')


if __name__ == '__main__':
    unittest.main()
