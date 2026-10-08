#!/usr/bin/env python3
import unittest
from public_api_policy import validate

class PolicyTests(unittest.TestCase):
    def setUp(self):
        self.exports = {'Public': {}}
        self.policy = {'exports': {'Public': {'stability': 'stable'}}, 'internal': ['Internal']}
    def check(self, doc=''):
        validate(self.exports, self.policy, lambda _: doc)
    def test_stable_passes(self): self.check()
    def test_new_export_requires_review(self):
        self.exports['New'] = {}
        with self.assertRaisesRegex(ValueError, 'classification'): self.check()
    def test_removed_export_requires_review(self):
        self.exports.clear()
        with self.assertRaisesRegex(ValueError, 'classification'): self.check()
    def test_advanced_marker_is_required(self):
        self.policy['exports']['Public']['stability'] = 'advanced'
        with self.assertRaisesRegex(ValueError, 'marker'): self.check()
        self.check('/// **Advanced API.** Supported custom composition.')
    def test_unknown_policy_fails(self):
        self.policy['exports']['Public']['stability'] = 'unprotected'
        with self.assertRaisesRegex(ValueError, 'unknown'): self.check()
    def test_internal_export_fails_even_when_classified(self):
        self.exports['Internal'] = {}
        self.policy['exports']['Internal'] = {'stability': 'stable'}
        with self.assertRaisesRegex(ValueError, 'leaked'): self.check()
if __name__ == '__main__': unittest.main()
