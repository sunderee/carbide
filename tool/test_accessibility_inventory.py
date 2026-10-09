#!/usr/bin/env python3
"""Regression checks for uncited exceptions and missing family coverage."""

import unittest
import tempfile
from pathlib import Path
from check_accessibility_inventory import check_exceptions, check_inventory


class AccessibilityInventoryTest(unittest.TestCase):
    def test_uncited_and_conditional_axis_overrides_fail(self):
        for option in ['tapTargets: false', 'labeled: false', 'tapTargets: size.height >= 48']:
            with self.assertRaisesRegex(ValueError, 'citation'):
                check_exceptions(f'await expectA11y(tester, {option});', 'fixture.dart')

    def test_pinned_reason_and_issue_are_accepted(self):
        for url in ['https://github.com/carbon-design-system/carbon/blob/'+'a'*40+'/packages/styles/scss/components/menu/_menu.scss', 'https://github.com/sunderee/carbide/issues/342']:
            check_exceptions('// Upstream menu rows are 32px.\n// a11y-exception: '+url+'\nawait expectA11y(tester, tapTargets: false);', 'fixture.dart')
        check_exceptions('await expectA11y(tester);', 'fixture.dart')

    def test_new_family_requires_review(self):
        with self.assertRaisesRegex(ValueError, 'new_widget'):
            check_inventory({'new_widget': {}}, {})
        with self.assertRaisesRegex(ValueError, 'missing guideline'):
            check_inventory({'button': {}}, {'button': {}})

    def test_missing_helper_and_missing_matrix_entry_fail(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            suite = root / 'suite.dart'
            policy = {'button': {'suites': ['suite.dart'], 'matrix': True}}
            suite.write_text('void main() {}')
            with self.assertRaisesRegex(ValueError, 'guideline helper'):
                check_inventory({'button': {}}, policy, root)
            suite.write_text('await expectA11y(tester);')
            with self.assertRaisesRegex(ValueError, 'state-matrix entry'):
                check_inventory({'button': {}}, policy, root)


if __name__ == '__main__':
    unittest.main()
