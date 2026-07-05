// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

Widget _themed(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets('paints only while visible', (WidgetTester tester) async {
    Widget ring({required bool visible}) => _themed(
      CarbonFocusRing(
        visible: visible,
        child: const SizedBox(width: 80, height: 32),
      ),
    );

    await tester.pumpWidget(ring(visible: false));
    CustomPaint paint = tester.widget<CustomPaint>(
      find.byType(CustomPaint).first,
    );
    expect(paint.foregroundPainter, isNull);

    await tester.pumpWidget(ring(visible: true));
    paint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
    expect(paint.foregroundPainter, isNotNull);
  });

  testWidgets('paints rounded outer and inner rings for a non-zero '
      'borderRadius', (WidgetTester tester) async {
    Widget ring(BorderRadius radius) => _themed(
      CarbonFocusRing(
        visible: true,
        inset: true,
        borderRadius: radius,
        child: const SizedBox(width: 80, height: 32),
      ),
    );

    await tester.pumpWidget(ring(BorderRadius.circular(8)));
    RenderObject renderRing() =>
        tester.renderObject(find.byType(CustomPaint).first);
    // Outer ring plus the 1px inset ring, both rounded.
    expect(
      renderRing(),
      paints
        ..rrect()
        ..rrect(),
    );

    // Radii smaller than the stroke inset clamp to zero rather than going
    // negative.
    await tester.pumpWidget(ring(BorderRadius.circular(1)));
    expect(
      renderRing(),
      paints
        ..rrect()
        ..rrect(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not affect child layout', (WidgetTester tester) async {
    await tester.pumpWidget(
      _themed(
        const CarbonFocusRing(
          visible: true,
          child: SizedBox(width: 80, height: 32),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CarbonFocusRing)), const Size(80, 32));
  });

  testWidgets('default focus ring across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'focus_ring_default',
      size: const Size(140, 72),
      builder: (BuildContext context) => const Center(
        child: CarbonFocusRing(
          visible: true,
          child: SizedBox(width: 100, height: 40),
        ),
      ),
    );
  });

  testWidgets('inset focus ring across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'focus_ring_inset',
      size: const Size(140, 72),
      builder: (BuildContext context) => Center(
        child: CarbonFocusRing(
          visible: true,
          inset: true,
          child: ColoredBox(
            color: CarbonTheme.of(context).backgroundInverse,
            child: const SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    );
  });
}
