#!/usr/bin/env python3
"""Coverage policy fails closed when APIs, routes or evidence change."""
import unittest
from gallery_coverage import validate

class CoverageTests(unittest.TestCase):
    def setUp(self):
        self.exports = {'CarbonButton': {'visual': True}}
        self.policy = {'CarbonButton': {'mode': 'demonstrated', 'routes': ['button']}}
        self.routes = {'button': 'CarbonButton(label: label)'}

    def check(self):
        validate(self.exports, self.policy, self.routes, '')

    def test_direct_reference_passes(self):
        self.check()

    def test_new_export_requires_explicit_classification(self):
        self.exports['NewWidget'] = {'visual': True}
        with self.assertRaisesRegex(ValueError, 'unclassified'):
            self.check()

    def test_removed_route_fails(self):
        self.routes.clear()
        with self.assertRaisesRegex(ValueError, 'route'):
            self.check()

    def test_removed_live_reference_fails(self):
        self.routes['button'] = 'OtherWidget()'
        with self.assertRaisesRegex(ValueError, 'live reference'):
            self.check()

    def test_exemption_needs_reason(self):
        self.policy['CarbonButton']['mode'] = 'composition'
        with self.assertRaisesRegex(ValueError, 'reason'):
            self.check()
        self.policy['CarbonButton']['reason'] = 'Composed by an interactive family control.'
        self.check()

    def test_claimed_shell_usage_needs_evidence(self):
        self.policy['CarbonButton']['shell_reference'] = True
        with self.assertRaisesRegex(ValueError, 'shell'):
            self.check()

if __name__ == '__main__':
    unittest.main()
