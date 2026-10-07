// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

// Pinned Carbon packages/grid/scss/_config.scss: $grid-gutter = 32px,
// $grid-gutter-condensed = 1px. _css-grid.scss gives each wide column 16px
// start/end margins; narrow sets start to 0 and retains end at 16px.
// Therefore visible interior gaps are 32/16/1px. The issue's symmetric
// outer-edge hang and 32px narrow interior gap do not match current Carbon.
const double _halfGutter = 32 / 2;

(double, double) _gutters(CarbonGridMode mode) => switch (mode) {
  CarbonGridMode.wide => (_halfGutter, _halfGutter),
  CarbonGridMode.narrow => (0, _halfGutter),
  CarbonGridMode.condensed => (0.5, 0.5),
};

Widget _column(String id, {int span = 1, int offset = 0, Widget? child}) =>
    CarbonColumn(
      key: ValueKey<String>('slot-$id'),
      span: span,
      offset: offset,
      child:
          child ??
          SizedBox(
            key: ValueKey<String>('content-$id'),
            height: 20,
            child: const ColoredBox(color: Color(0xFF0F62FE)),
          ),
    );

Rect _rect(WidgetTester tester, String id) =>
    tester.getRect(find.byKey(ValueKey<String>(id)));

double _start(Rect rect, TextDirection direction, double width) =>
    direction == TextDirection.ltr ? rect.left : width - rect.right;

double _end(Rect rect, TextDirection direction, double width) =>
    direction == TextDirection.ltr ? width - rect.right : rect.left;

Future<void> _pump(
  WidgetTester tester,
  double width,
  Widget grid,
  TextDirection direction,
) async {
  await tester.binding.setSurfaceSize(Size(width + 40, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: grid),
      ),
    ),
  );
}

void main() {
  for (final CarbonGridMode mode in CarbonGridMode.values) {
    test(
      'visible ${mode.name} gutter matches the pinned CSS column margins',
      () {
        final (double start, double end) = _gutters(mode);
        expect(mode.gutter, start + end);
        expect(CarbonSpacing.spacing07 / 2, _halfGutter);
      },
    );
    for (final double width in <double>[320, 672, 1056, 1584]) {
      for (final bool fullWidth in <bool>[false, true]) {
        for (final TextDirection direction in TextDirection.values) {
          testWidgets('$mode width=$width full=$fullWidth $direction gutters', (
            WidgetTester tester,
          ) async {
            final CarbonBreakpoint breakpoint = CarbonBreakpoint.of(width);
            final double margin = fullWidth ? 0 : breakpoint.margin;
            final (double start, double end) = _gutters(mode);
            await _pump(
              tester,
              width,
              CarbonGrid(
                mode: mode,
                fullWidth: fullWidth,
                children: <Widget>[
                  for (int i = 0; i < breakpoint.columns; i++) _column('$i'),
                ],
              ),
              direction,
            );
            final Rect first = _rect(tester, 'content-0');
            final Rect last = _rect(
              tester,
              'content-${breakpoint.columns - 1}',
            );
            expect(
              _start(first, direction, width),
              closeTo(margin + start, 0.01),
            );
            // One pixel of shared track slack prevents premature Wrap rows.
            expect(
              _end(last, direction, width),
              closeTo(margin + end + 1, 0.01),
            );
            for (int i = 0; i < breakpoint.columns - 1; i++) {
              final Rect a = _rect(tester, 'content-$i');
              final Rect b = _rect(tester, 'content-${i + 1}');
              final double gap = direction == TextDirection.ltr
                  ? b.left - a.right
                  : a.left - b.right;
              expect(gap, closeTo(start + end, 0.01));
              expect(a.top, first.top);
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }

    for (final TextDirection direction in TextDirection.values) {
      testWidgets('$mode multi-row gutters stay aligned $direction', (
        WidgetTester tester,
      ) async {
        await _pump(
          tester,
          672,
          CarbonGrid(
            mode: mode,
            rowSpacing: 7,
            children: <Widget>[
              for (int i = 0; i < 6; i++) _column('$i', span: 4),
            ],
          ),
          direction,
        );
        for (int row = 1; row < 3; row++) {
          final Rect first = _rect(tester, 'content-${row * 2}');
          final Rect second = _rect(tester, 'content-${row * 2 + 1}');
          expect(first.left, _rect(tester, 'content-0').left);
          expect(first.right, _rect(tester, 'content-0').right);
          expect(second.left, _rect(tester, 'content-1').left);
          expect(first.top, row * 27);
          expect(second.top, first.top);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '$mode offsets consume logical tracks before content $direction',
        (WidgetTester tester) async {
          await _pump(
            tester,
            672,
            CarbonGrid(
              mode: mode,
              children: <Widget>[_column('offset', span: 4, offset: 2)],
            ),
            direction,
          );
          final (double start, double end) = _gutters(mode);
          const double track = (672 - 2 * 16 - 1) / 8;
          final Rect content = _rect(tester, 'content-offset');
          expect(
            _start(content, direction, 672),
            closeTo(16 + track * 2 + start, 0.01),
          );
          expect(content.width, closeTo(track * 4 - start - end, 0.01));
          expect(_rect(tester, 'slot-offset').width, closeTo(track * 6, 0.01));
        },
      );
    }
  }

  for (final TextDirection direction in TextDirection.values) {
    testWidgets('nested narrow grids do not compound start hangs $direction', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        1056,
        CarbonGrid(
          mode: CarbonGridMode.narrow,
          children: <Widget>[
            _column(
              'outer',
              span: 16,
              child: CarbonGrid(
                mode: CarbonGridMode.narrow,
                fullWidth: true,
                children: <Widget>[
                  _column(
                    'inner',
                    span: 8,
                    child: CarbonGrid(
                      mode: CarbonGridMode.narrow,
                      fullWidth: true,
                      children: <Widget>[_column('leaf', span: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        direction,
      );
      final double start = _start(_rect(tester, 'slot-outer'), direction, 1056);
      expect(start, closeTo(16, 0.01));
      expect(
        _start(_rect(tester, 'slot-inner'), direction, 1056),
        closeTo(start, 0.01),
      );
      expect(
        _start(_rect(tester, 'content-leaf'), direction, 1056),
        closeTo(start, 0.01),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'mode and breakpoint changes update gutters without stale rows $direction',
      (WidgetTester tester) async {
        final List<Widget> columns = <Widget>[
          _column('a', span: 2),
          _column('b', span: 2),
        ];
        for (final double width in <double>[672, 320, 1056, 672]) {
          for (final CarbonGridMode mode in CarbonGridMode.values) {
            await _pump(
              tester,
              width,
              CarbonGrid(mode: mode, children: columns),
              direction,
            );
            final double margin = CarbonBreakpoint.of(width).margin;
            expect(
              _start(_rect(tester, 'content-a'), direction, width),
              closeTo(margin + _gutters(mode).$1, 0.01),
            );
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  }

  testWidgets('narrow grid across themes and RTL', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'grid_narrow',
      size: const Size(800, 140),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: CarbonGrid(
          mode: CarbonGridMode.narrow,
          rowSpacing: 8,
          children: <Widget>[
            for (int i = 0; i < 4; i++)
              CarbonColumn(
                sm: 2,
                md: 4,
                lg: 4,
                child: SizedBox(
                  height: 48,
                  child: ColoredBox(
                    color: CarbonTheme.of(context).layerAccent01,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  });
}
