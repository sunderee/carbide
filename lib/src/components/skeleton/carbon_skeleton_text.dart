// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   react/src/components/SkeletonText/SkeletonText.tsx
//   styles/scss/components/skeleton-styles/_skeleton-styles.scss

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import 'carbon_skeleton.dart';

/// Placeholder lines for loading text.
///
/// One 16px line by default (24px with [heading]); [paragraph] renders
/// [lineCount] lines whose widths vary with the **upstream's fixed seed
/// sequence** — Carbon's "random" widths come from three hard-coded seeds,
/// so the output is deterministic and matches the React renderer exactly.
class CarbonSkeletonText extends StatelessWidget {
  /// Creates skeleton text.
  const CarbonSkeletonText({
    super.key,
    this.heading = false,
    this.paragraph = false,
    this.lineCount = 3,
    this.width,
  });

  /// Renders the taller 24px heading line instead of the 16px body line.
  final bool heading;

  /// Renders [lineCount] lines instead of one.
  final bool paragraph;

  /// Number of lines when [paragraph] is set; defaults to 3 like upstream.
  final int lineCount;

  /// Line width in logical pixels; null fills the available width.
  final double? width;

  /// Upstream's fixed pseudo-random seeds (`SkeletonText.tsx`).
  static const List<double> seeds = <double>[
    0.973051493507435,
    0.15334737213558558,
    0.5671034553053769,
  ];

  /// Upstream's `getRandomInt(min, max, n)` — deterministic by seed index.
  static int randomInt(int min, int max, int n) =>
      (seeds[n % 3] * (max - min + 1)).floor() + min;

  /// The width of paragraph line [index] given the resolved full [width],
  /// with [fixed] selecting the px-mode formula (explicit width) over the
  /// percent-mode one (fill width).
  static double lineWidth(double width, int index, {required bool fixed}) {
    if (fixed) {
      final int min = (width - 75) < 0 ? 0 : (width - 75).toInt();
      return randomInt(min, width.toInt(), index).toDouble();
    }
    return width - randomInt(0, 75, index);
  }

  @override
  Widget build(BuildContext context) {
    final double lineHeight = heading ? 24 : 16;
    final int lines = paragraph ? lineCount : 1;
    final double? fixedWidth = width;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < lines; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing03),
            child: !paragraph
                ? CarbonSkeleton(width: fixedWidth, height: lineHeight)
                : fixedWidth != null
                ? CarbonSkeleton(
                    width: lineWidth(fixedWidth, i, fixed: true),
                    height: lineHeight,
                  )
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints c) {
                      return CarbonSkeleton(
                        width: lineWidth(c.maxWidth, i, fixed: false),
                        height: lineHeight,
                      );
                    },
                  ),
          ),
      ],
    );
  }
}
