// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Renders the Carbon spacing scale (spacing-01 … spacing-13) as bars whose
// width is the step's logical-pixel value. layout_test.dart locks the numeric
// values; this golden pins the scale *to scale*, so a regression in any step
// (or the geometric progression between them) is caught visually.
//
// Solid rectangles only (no text), so the baseline is pixel-stable everywhere.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

void main() {
  testWidgets('the spacing scale renders to scale on each theme', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'spacing_scale',
      size: const Size(200, 232),
      builder: (BuildContext context) => const _SpacingScale(),
    );
  });
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale();

  @override
  Widget build(BuildContext context) {
    final Color bar = CarbonTheme.of(context).borderStrong01;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final double step in CarbonSpacing.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SizedBox(
                width: step,
                height: 10,
                child: ColoredBox(color: bar),
              ),
            ),
        ],
      ),
    );
  }
}
