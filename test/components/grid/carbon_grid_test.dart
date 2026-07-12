// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(double width, Widget grid) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    // topLeft so absolute positions are not offset by horizontal centering.
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: grid),
  ),
);

// One column track at a given grid width / total columns (wide mode, margin).
double _unit(double width, int totalColumns, double margin) =>
    ((width - 2 * margin) - (totalColumns - 1) * 32 - 1) / totalColumns;

// Pumps [grid] in a surface wide enough that a [width]px grid is not clamped
// to the 800px default surface (which would resolve to a smaller breakpoint).
Future<void> _pump(WidgetTester tester, double width, Widget grid) async {
  await tester.binding.setSurfaceSize(Size(width + 40, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_host(width, grid));
}

void main() {
  // Layout-only: no semantics surface (#226).
  group('spec-lock', () {
    testWidgets('a column spans a fraction of the grid at lg (16 cols)', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        1056,
        CarbonGrid(
          children: <Widget>[
            CarbonColumn(
              lg: 8,
              key: const ValueKey<String>('a'),
              child: const SizedBox(height: 10),
            ),
            CarbonColumn(
              lg: 8,
              key: const ValueKey<String>('b'),
              child: const SizedBox(height: 10),
            ),
          ],
        ),
      );
      final double unit = _unit(1056, 16, 16);
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(8 * unit + 7 * 32, 0.6),
      );
      // Two half-width columns share one row.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('b'))).dy,
        tester.getTopLeft(find.byKey(const ValueKey<String>('a'))).dy,
      );
    });

    testWidgets('fewer columns at the sm breakpoint', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        400,
        CarbonGrid(
          children: <Widget>[
            CarbonColumn(
              sm: 2,
              key: const ValueKey<String>('a'),
              child: const SizedBox(height: 10),
            ),
          ],
        ),
      );
      final double unit = _unit(400, 4, 0); // sm: 4 columns, margin 0.
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(2 * unit + 32, 0.6),
      );
    });

    testWidgets('an unset breakpoint cascades up from a smaller one', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        1056,
        CarbonGrid(
          children: <Widget>[
            // Only sm is set → used at lg too.
            CarbonColumn(
              sm: 4,
              key: const ValueKey<String>('a'),
              child: const SizedBox(height: 10),
            ),
          ],
        ),
      );
      final double unit = _unit(1056, 16, 16);
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(4 * unit + 3 * 32, 0.6),
      );
    });

    testWidgets('without breakpoint spans, span applies and defaults to the '
        'full grid', (WidgetTester tester) async {
      await _pump(
        tester,
        1056,
        CarbonGrid(
          children: <Widget>[
            CarbonColumn(
              span: 4,
              key: const ValueKey<String>('a'),
              child: const SizedBox(height: 10),
            ),
            const CarbonColumn(
              key: ValueKey<String>('b'),
              child: SizedBox(height: 10),
            ),
          ],
        ),
      );
      final double unit = _unit(1056, 16, 16);
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(4 * unit + 3 * 32, 0.6),
      );
      // No span at all → the full 16-column width.
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('b'))).width,
        closeTo(16 * unit + 15 * 32, 0.6),
      );
    });

    testWidgets('columns relayout when the grid crosses a breakpoint', (
      WidgetTester tester,
    ) async {
      final Widget grid = CarbonGrid(
        children: <Widget>[
          CarbonColumn(
            sm: 2,
            lg: 8,
            key: const ValueKey<String>('a'),
            child: const SizedBox(height: 10),
          ),
        ],
      );

      await _pump(tester, 1056, grid);
      final double lgUnit = _unit(1056, 16, 16);
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(8 * lgUnit + 7 * 32, 0.6),
      );

      // Shrinking to sm re-resolves the scope; dependents must be notified.
      await _pump(tester, 400, grid);
      final double smUnit = _unit(400, 4, 0);
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(2 * smUnit + 32, 0.6),
      );
    });

    testWidgets('a width change within one breakpoint re-derives the unit', (
      WidgetTester tester,
    ) async {
      final Widget column = CarbonColumn(
        lg: 8,
        key: const ValueKey<String>('a'),
        child: const SizedBox(height: 10),
      );

      // 1056 and 1200 both resolve to lg (16 columns, 16px margin).
      await _pump(tester, 1056, CarbonGrid(children: <Widget>[column]));
      await _pump(tester, 1200, CarbonGrid(children: <Widget>[column]));
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(8 * _unit(1200, 16, 16) + 7 * 32, 0.6),
      );

      // An unrelated grid property change keeps the column layout stable.
      await _pump(
        tester,
        1200,
        CarbonGrid(rowSpacing: 8, children: <Widget>[column]),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('a'))).width,
        closeTo(8 * _unit(1200, 16, 16) + 7 * 32, 0.6),
      );
    });
  });

  group('layout', () {
    testWidgets('rows wrap when spans exceed the grid', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        1056,
        CarbonGrid(
          children: <Widget>[
            for (int i = 0; i < 3; i++)
              CarbonColumn(
                lg: 8,
                key: ValueKey<String>('c$i'),
                child: const SizedBox(height: 20),
              ),
          ],
        ),
      );
      // 3 × 8 = 24 tracks > 16 → the third wraps below the first.
      expect(
        tester.getTopLeft(find.byKey(const ValueKey<String>('c2'))).dy,
        greaterThan(
          tester.getTopLeft(find.byKey(const ValueKey<String>('c0'))).dy,
        ),
      );
    });

    testWidgets('offset shifts the content right by empty tracks', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        1056,
        CarbonGrid(
          children: const <Widget>[
            CarbonColumn(
              lg: 4,
              offset: 2,
              child: SizedBox(
                height: 10,
                child: ColoredBox(
                  color: Color(0xFF000000),
                  key: ValueKey<String>('content'),
                ),
              ),
            ),
          ],
        ),
      );
      final double unit = _unit(1056, 16, 16);
      // Content begins after the 16px margin + 2 empty tracks.
      final double contentLeft = tester
          .getTopLeft(find.byKey(const ValueKey<String>('content')))
          .dx;
      expect(contentLeft, closeTo(16 + 2 * unit + 2 * 32, 1.0));
    });

    testWidgets('a column outside a grid asserts', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: CarbonColumn(span: 4, child: SizedBox.shrink()),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });

  group('goldens', () {
    testWidgets('responsive layout', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'grid',
        size: const Size(800, 140),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topCenter,
          child: CarbonGrid(
            rowSpacing: 8,
            children: <Widget>[
              for (int i = 0; i < 4; i++)
                CarbonColumn(
                  sm: 2,
                  md: 4,
                  lg: 4,
                  child: SizedBox(
                    height: 48,
                    child: ColoredBox(color: CarbonThemeData.white.layer01),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  });
}
