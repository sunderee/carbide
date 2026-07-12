// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

void main() {
  // Layout-only: no semantics surface (#226).
  group('gap resolution (Stack.tsx SPACING_STEPS)', () {
    test('steps 1–12 map onto the Carbon spacing scale', () {
      for (int step = 1; step <= 12; step++) {
        expect(
          CarbonStack(gapStep: step, children: const <Widget>[]).resolvedGap,
          CarbonSpacing.steps[step - 1],
          reason: 'step $step',
        );
      }
      // Spot values: step 5 = 16px, step 12 = 96px.
      expect(
        const CarbonStack(gapStep: 5, children: <Widget>[]).resolvedGap,
        16,
      );
      expect(
        const CarbonStack(gapStep: 12, children: <Widget>[]).resolvedGap,
        96,
      );
    });

    test('step 13 is rejected (upstream excludes it) and gap/gapStep are '
        'mutually exclusive', () {
      expect(
        () => CarbonStack(gapStep: 13, children: const <Widget>[]),
        throwsAssertionError,
      );
      expect(
        () => CarbonStack(gapStep: 5, gap: 10, children: const <Widget>[]),
        throwsAssertionError,
      );
    });

    test('custom gap and the zero default', () {
      expect(const CarbonStack(gap: 10, children: <Widget>[]).resolvedGap, 10);
      expect(const CarbonStack(children: <Widget>[]).resolvedGap, 0);
    });
  });

  group('layout', () {
    testWidgets('vertical (default) spaces children by the gap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonStack(
            gapStep: 5,
            children: <Widget>[
              SizedBox(key: Key('a'), width: 40, height: 20),
              SizedBox(key: Key('b'), width: 40, height: 20),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('b'))).dy -
            tester.getBottomLeft(find.byKey(const Key('a'))).dy,
        16,
      );
      expect(tester.getSize(find.byType(CarbonStack)), const Size(40, 56));
    });

    testWidgets('horizontal orientation', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonStack(
            orientation: Axis.horizontal,
            gapStep: 3,
            children: <Widget>[
              SizedBox(key: Key('a'), width: 20, height: 40),
              SizedBox(key: Key('b'), width: 20, height: 40),
            ],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('b'))).dx -
            tester.getTopRight(find.byKey(const Key('a'))).dx,
        8,
      );
    });
  });

  testWidgets('stack gaps across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'stack',
      size: const Size(120, 120),
      builder: (BuildContext context) {
        final Color swatch = CarbonTheme.of(context).borderStrong01;
        return Center(
          child: CarbonStack(
            gapStep: 4,
            children: <Widget>[
              for (int i = 0; i < 3; i++)
                SizedBox(
                  width: 64,
                  height: 16,
                  child: ColoredBox(color: swatch),
                ),
            ],
          ),
        );
      },
    );
  });
}
