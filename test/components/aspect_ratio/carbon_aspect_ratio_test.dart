// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

void main() {
  // Layout-only: no semantics surface (#226).
  group('spec-lock', () {
    test('named ratios match their numeric value', () {
      expect(CarbonAspectRatioValue.r16x9.ratio, closeTo(16 / 9, 1e-9));
      expect(CarbonAspectRatioValue.r1x1.ratio, 1);
      expect(CarbonAspectRatioValue.r2x1.ratio, 2);
      expect(CarbonAspectRatioValue.r1x2.ratio, 0.5);
      expect(CarbonAspectRatioValue.r4x3.ratio, closeTo(4 / 3, 1e-9));
      expect(CarbonAspectRatioValue.r9x16.label, '9x16');
    });

    test('covers all nine Carbon ratios', () {
      expect(CarbonAspectRatioValue.values, hasLength(9));
    });
  });

  group('layout', () {
    testWidgets('lays the child out at the requested ratio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 320,
              child: CarbonAspectRatio(
                ratio: CarbonAspectRatioValue.r16x9,
                child: SizedBox.expand(key: ValueKey<String>('content')),
              ),
            ),
          ),
        ),
      );
      final Size size = tester.getSize(
        find.byKey(const ValueKey<String>('content')),
      );
      expect(size.width, 320);
      expect(size.height, closeTo(320 * 9 / 16, 0.01));
    });

    testWidgets('a tall ratio fits within the available width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              height: 200,
              child: CarbonAspectRatio(
                ratio: CarbonAspectRatioValue.r1x2,
                child: SizedBox.expand(key: ValueKey<String>('content')),
              ),
            ),
          ),
        ),
      );
      final Size size = tester.getSize(
        find.byKey(const ValueKey<String>('content')),
      );
      // height bounded to 200 → width = height * (1/2) = 100.
      expect(size.height, 200);
      expect(size.width, closeTo(100, 0.01));
    });
  });

  group('goldens', () {
    testWidgets('common ratios', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'aspect_ratio',
        size: const Size(360, 200),
        builder: (BuildContext context) => Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final CarbonAspectRatioValue r in <CarbonAspectRatioValue>[
                CarbonAspectRatioValue.r16x9,
                CarbonAspectRatioValue.r1x1,
                CarbonAspectRatioValue.r3x4,
              ])
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 96,
                    child: CarbonAspectRatio(
                      ratio: r,
                      child: ColoredBox(color: CarbonThemeData.white.layer01),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  });
}
