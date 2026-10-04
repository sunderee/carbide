// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/legibility.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 480, child: child)),
  ),
);

const List<CarbonTableColumn> _columns = <CarbonTableColumn>[
  CarbonTableColumn(title: 'Name'),
  CarbonTableColumn(title: 'Status'),
];

List<CarbonTableRow> _rows() => const <CarbonTableRow>[
  CarbonTableRow(cells: <Widget>[Text('Load'), Text('Running')]),
  CarbonTableRow(cells: <Widget>[Text('Store'), Text('Stopped')]),
  CarbonTableRow(cells: <Widget>[Text('Cache'), Text('Running')]),
];

Color _rowColor(WidgetTester tester, String cell) =>
    (tester
                .widget<AnimatedContainer>(
                  find
                      .ancestor(
                        of: find.text(cell),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration)
        .color!;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('motion', () {
    testWidgets('row fill tokens match _data-table.scss', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonDataTable(columns: _columns, rows: _rows())),
      );
      // `tbody tr`: background-color $duration-fast-01
      // motion(entrance, productive).
      final AnimatedContainer row = tester.widget(
        find
            .ancestor(
              of: find.text('Load'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(row.duration, CarbonDuration.fast01);
      expect(row.curve, CarbonEasing.entranceProductive);
    });

    testWidgets('reduced motion fills rows instantly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: CarbonDataTable(columns: _columns, rows: _rows()),
          ),
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(
              find
                  .ancestor(
                    of: find.text('Load'),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .duration,
        Duration.zero,
      );
    });
  });

  group('structure', () {
    testWidgets('renders header + cells; title and description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            title: 'Routines',
            description: 'Background jobs',
            columns: _columns,
            rows: _rows(),
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Load'), findsOneWidget);
      expect(find.text('Routines'), findsOneWidget);
      expect(find.text('Background jobs'), findsOneWidget);
      // The title uses heading-03 / text-primary.
      expect(
        tester.widget<Text>(find.text('Routines')).style!.fontSize,
        CarbonTypeStyles.heading03.fontSize,
      );
    });

    testWidgets('header is layer-accent; default rows are the layer token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonDataTable(columns: _columns, rows: _rows())),
      );
      final ColoredBox headerBox = tester.widget<ColoredBox>(
        find
            .ancestor(of: find.text('Name'), matching: find.byType(ColoredBox))
            .first,
      );
      expect(headerBox.color, theme.layerAccent01);
      // A default (non-zebra) body row is on the layer token.
      expect(_rowColor(tester, 'Load'), theme.layer01);
    });
  });

  group('sizes', () {
    testWidgets('row height follows the size token', (
      WidgetTester tester,
    ) async {
      for (final (CarbonTableSize size, double height)
          in <(CarbonTableSize, double)>[
            (CarbonTableSize.xs, 24),
            (CarbonTableSize.sm, 32),
            (CarbonTableSize.md, 40),
            (CarbonTableSize.lg, 48),
            (CarbonTableSize.xl, 64),
          ]) {
        await tester.pumpWidget(
          _host(
            CarbonDataTable(
              key: ValueKey<CarbonTableSize>(size),
              size: size,
              columns: _columns,
              rows: const <CarbonTableRow>[
                CarbonTableRow(cells: <Widget>[Text('A'), Text('B')]),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        // The row height token is a minimum (docs/text-scaling.md); at
        // 1.0x scale the rendered row sits exactly on the token.
        final double rowHeight = tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('A'),
                    matching: find.byType(ConstrainedBox),
                  )
                  .first,
            )
            .height;
        expect(rowHeight, height, reason: '$size');
        // The cell text must not be clipped by the fixed row height (xs is
        // 24px against an 18px body-compact-01 line box).
        expectTextNotClipped(tester, find.text('A'));
      }
    });
  });

  group('zebra + hover', () {
    testWidgets('zebra tints the even child rows', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(CarbonDataTable(columns: _columns, rows: _rows(), zebra: true)),
      );
      // Row 1 (index 0) is the odd child → untinted; row 2 (index 1) is the
      // even child → layer-accent.
      expect(_rowColor(tester, 'Load'), theme.layer01);
      expect(_rowColor(tester, 'Store'), theme.layerAccent01);
    });

    testWidgets('hovering a row fills it with layer-hover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonDataTable(columns: _columns, rows: _rows())),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Store')));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Store'), theme.layerHover01);
    });
  });

  group('sticky header', () {
    testWidgets('constrains the body to a scrollable region', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            stickyHeader: true,
            stickyHeaderHeight: 80,
          ),
        ),
      );
      expect(find.byType(Scrollable), findsOneWidget);
    });
  });

  group('semantics (#226)', () {
    testWidgets('column headers and body cells are exposed to '
        'assistive technology', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonDataTable(columns: _columns, rows: _rows())),
      );
      // Header labels.
      expect(find.bySemanticsLabel('Name'), findsOneWidget);
      expect(find.bySemanticsLabel('Status'), findsOneWidget);
      // Every cell of every row is reachable as a semantics node.
      expect(find.bySemanticsLabel('Load'), findsOneWidget);
      expect(find.bySemanticsLabel('Store'), findsOneWidget);
      expect(find.bySemanticsLabel('Cache'), findsOneWidget);
      expect(find.bySemanticsLabel('Stopped'), findsOneWidget);
      expect(find.bySemanticsLabel('Running'), findsNWidgets(2));
      handle.dispose();
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: const <CarbonTableColumn>[
              CarbonTableColumn(title: 'Name', sortable: true),
              CarbonTableColumn(title: 'Status'),
            ],
            rows: _rows(),
            selection: CarbonTableSelection.multi,
            onSelectionChanged: (_) {},
            onSort: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Sorting and selection expose named, full-band 48dp targets.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('table variants across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'data_table',
        // Direction-sensitive geometry (#227): mirrored fill / side
        // accent / overlay side re-snapshots under RTL.
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        containsText: true,
        size: const Size(520, 320),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 480,
            child: CarbonDataTable(
              title: 'Routines',
              description: 'Background jobs',
              columns: <CarbonTableColumn>[
                CarbonTableColumn(title: 'Name'),
                CarbonTableColumn(title: 'Status'),
                CarbonTableColumn(title: 'Owner'),
              ],
              zebra: true,
              rows: <CarbonTableRow>[
                CarbonTableRow(
                  cells: <Widget>[Text('Load'), Text('Running'), Text('Ada')],
                ),
                CarbonTableRow(
                  cells: <Widget>[Text('Store'), Text('Stopped'), Text('Lin')],
                ),
                CarbonTableRow(
                  cells: <Widget>[Text('Cache'), Text('Running'), Text('Sam')],
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}
