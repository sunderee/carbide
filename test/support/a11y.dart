// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// Shared accessibility assertions (#226), mirroring how
/// `expectThemeGoldens` made goldens a one-liner.
///
/// Two layers:
///
/// * [expectA11y] — runs Flutter's accessibility guideline matchers
///   (tap-target size, labelled tap targets) against the currently pumped
///   tree. Call it from a component's state-matrix test with the tree in
///   its default size; where Carbon deliberately ships a sub-guideline
///   size (`sm` = 32px), keep the call off that variant and cite the SCSS
///   in a comment instead of skipping silently.
/// * [wcagContrastRatio] — the WCAG 2.1 relative-luminance contrast ratio,
///   used by the token-pair sweep in `test/theme/contrast_test.dart`.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts the pumped tree meets the platform accessibility guidelines.
///
/// [tapTargets] runs [androidTapTargetGuideline] (48×48dp minimum — the
/// stricter of the two platform guidelines, so passing it implies the iOS
/// 44×44 one). [labeled] runs [labeledTapTargetGuideline] (every tappable
/// node carries a label). Both default on; disable an axis only with a
/// comment citing the upstream size that makes it inapplicable.
Future<void> expectA11y(
  WidgetTester tester, {
  bool tapTargets = true,
  bool labeled = true,
}) async {
  if (tapTargets) {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  }
  if (labeled) {
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  }
}

/// The WCAG 2.1 contrast ratio between [foreground] and [background],
/// in `[1, 21]`.
///
/// If [foreground] is translucent it is composited over [background]
/// first, matching how the pixel actually renders.
double wcagContrastRatio(Color foreground, Color background) {
  final Color fg = foreground.a == 1.0
      ? foreground
      : Color.alphaBlend(foreground, background);
  final double lighter = math.max(_luminance(fg), _luminance(background));
  final double darker = math.min(_luminance(fg), _luminance(background));
  return (lighter + 0.05) / (darker + 0.05);
}

/// WCAG relative luminance (sRGB linearization).
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}
