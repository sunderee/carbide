#!/usr/bin/env python3
# Copyright 2026 Bizjak Tech OÜ
# Licensed under the Apache License, Version 2.0. See LICENSE.
"""Prove that the motion source guard rejects policy regressions."""

import unittest

from check_motion_policy import ESSENTIAL_MOTION, violations


class MotionPolicyTest(unittest.TestCase):
    def test_new_animation_without_a_duration_token_is_guarded(self):
        self.assertTrue(violations("components/new.dart", "AnimatedScale(duration: Duration(milliseconds: 70))"))

    def test_unresolved_token_in_an_otherwise_guarded_file_fails(self):
        source = "carbonDuration(context, CarbonDuration.fast01); AnimatedRotation(duration: CarbonDuration.fast02);"
        self.assertEqual(violations("components/new.dart", source), ["every CarbonDuration token must pass through carbonDuration"])

    def test_multiline_resolver_and_local_duration_are_supported(self):
        source = "final d = carbonDuration(\n context,\n CarbonDuration.fast01,\n); AnimatedScale(duration: d);"
        self.assertEqual(violations("components/new.dart", source), [])

    def test_comments_and_examples_do_not_satisfy_the_guard(self):
        for example in ("// carbonDuration(context, CarbonDuration.fast01)\n", "/* carbonDuration(context, d) */", "'carbonDuration(context, d)'", '"""carbonDuration(context, d)"""'):
            self.assertTrue(violations("components/new.dart", example + " AnimatedScale(duration: d);"))

    def test_documented_tokens_do_not_count_as_unresolved_uses(self):
        self.assertEqual(violations("components/new.dart", "/// CarbonDuration.fast01\nfinal label = 'CarbonDuration.fast02';"), [])

    def test_essential_motion_does_not_exempt_duration_tokens(self):
        for name in ESSENTIAL_MOTION:
            self.assertEqual(violations(name, "AnimationController(duration: cycle);"), [])
            self.assertTrue(violations(name, "AnimatedContainer(duration: CarbonDuration.fast01);"))

    def test_exception_is_exact_and_has_a_reason(self):
        self.assertTrue(all(ESSENTIAL_MOTION.values()))
        self.assertTrue(violations("components/new_loading.dart", "AnimationController(duration: cycle);"))

    def test_scroll_animation_is_guarded_without_implicit_widgets(self):
        self.assertTrue(violations("components/new.dart", "controller.animateTo(target, duration: d);"))


if __name__ == "__main__":
    unittest.main()
