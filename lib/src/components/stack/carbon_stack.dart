// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   react/src/components/Stack/Stack.tsx
//   styles/scss/components/stack/_stack.scss

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';

/// Carbon's spacing layout helper: children laid out along one axis with a
/// uniform gap from the spacing scale.
///
/// ```dart
/// CarbonStack(
///   gapStep: 5, // spacing-05 = 16px
///   children: [...],
/// );
/// ```
///
/// [gapStep] selects a step of the Carbon spacing scale (1–12 — upstream
/// deliberately excludes step 13); [gap] sets a custom logical-pixel gap
/// instead. Named `CarbonStack` because Flutter's `Stack` is a z-axis
/// widget; this is the upstream `Stack` layout component.
class CarbonStack extends StatelessWidget {
  /// Creates a stack.
  const CarbonStack({
    super.key,
    required this.children,
    this.orientation = Axis.vertical,
    this.gapStep,
    this.gap,
  }) : assert(
         gapStep == null || gap == null,
         'provide gapStep or gap, not both',
       ),
       assert(
         gapStep == null || (gapStep >= 1 && gapStep <= 12),
         'gapStep is a Carbon spacing step between 1 and 12',
       );

  /// The children, laid out along [orientation].
  final List<Widget> children;

  /// The main axis; vertical by default like upstream.
  final Axis orientation;

  /// A Carbon spacing-scale step (1–12) for the gap between children.
  final int? gapStep;

  /// A custom gap in logical pixels (the upstream CSS-length escape hatch).
  final double? gap;

  /// The resolved gap in logical pixels.
  double get resolvedGap {
    final int? step = gapStep;
    if (step != null) {
      return CarbonSpacing.steps[step - 1];
    }
    return gap ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final double space = resolvedGap;
    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0 && space > 0) {
        spaced.add(
          SizedBox(
            width: orientation == Axis.horizontal ? space : null,
            height: orientation == Axis.vertical ? space : null,
          ),
        );
      }
      spaced.add(children[i]);
    }
    return Flex(
      direction: orientation,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spaced,
    );
  }
}
