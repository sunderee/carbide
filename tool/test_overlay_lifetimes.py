#!/usr/bin/env python3
"""New portal owners and missing scenarios must fail the lifetime gate."""

import tempfile
import unittest
from pathlib import Path
from check_overlay_lifetimes import owners, validate, scenario_names


class OverlayInventoryTest(unittest.TestCase):
    def test_scan_ignores_comments_and_borrowed_controller(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / 'lib/src'
            source.mkdir(parents=True)
            (source / 'owner.dart').write_text('final portal = OverlayPortalController();')
            (source / 'borrowed.dart').write_text('// OverlayPortalController()\nOverlayPortalController? borrowed;')
            self.assertEqual(owners(root), {'lib/src/owner.dart'})

    def test_new_owner_and_missing_scenario_fail(self):
        with self.assertRaisesRegex(ValueError, 'inventory changed'):
            validate({'new.dart'}, {}, set())
        with self.assertRaisesRegex(ValueError, 'missing harness case'):
            validate({'owner.dart'}, {'owner.dart': ['open-close-dispose']}, set())
        validate({'owner.dart'}, {'owner.dart': ['scenario']}, {'scenario'})

    def test_conditional_and_picker_cases_are_inventoried(self):
        source = "for (final name in <String>['select', 'combo box']) _picker(name);\nname: modal ? 'modal' : 'nonmodal',\nname: 'popover',"
        self.assertEqual(scenario_names(source), {'select', 'combo box', 'modal', 'nonmodal', 'popover'})


if __name__ == '__main__':
    unittest.main()
