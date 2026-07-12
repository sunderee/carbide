// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/aspect-ratio/_aspect-ratio.scss
//   react/src/components/AspectRatio/AspectRatio.tsx
//
// A thin wrapper over Flutter's AspectRatio exposing Carbon's named ratio set.

import 'package:flutter/widgets.dart';

/// Carbon's fixed aspect ratios.
enum CarbonAspectRatioValue {
  /// 16:9.
  r16x9(16 / 9, '16x9'),

  /// 9:16.
  r9x16(9 / 16, '9x16'),

  /// 2:1.
  r2x1(2 / 1, '2x1'),

  /// 1:2.
  r1x2(1 / 2, '1x2'),

  /// 4:3.
  r4x3(4 / 3, '4x3'),

  /// 3:4.
  r3x4(3 / 4, '3x4'),

  /// 3:2.
  r3x2(3 / 2, '3x2'),

  /// 2:3.
  r2x3(2 / 3, '2x3'),

  /// 1:1.
  r1x1(1 / 1, '1x1');

  const CarbonAspectRatioValue(this.ratio, this.label);

  /// The width-to-height ratio.
  final double ratio;

  /// The Carbon name (e.g. `16x9`).
  final String label;
}

/// Constrains [child] to one of Carbon's fixed aspect [ratio]s.
///
/// ```dart
/// CarbonAspectRatio(
///   ratio: CarbonAspectRatioValue.r16x9,
///   child: Image.asset('hero.png', fit: BoxFit.cover),
/// )
/// ```
class CarbonAspectRatio extends StatelessWidget {
  /// Creates an aspect-ratio box.
  const CarbonAspectRatio({
    required this.ratio,
    required this.child,
    super.key,
  });

  /// The aspect ratio to enforce.
  final CarbonAspectRatioValue ratio;

  /// The widget constrained to [ratio].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: ratio.ratio, child: child);
  }
}
