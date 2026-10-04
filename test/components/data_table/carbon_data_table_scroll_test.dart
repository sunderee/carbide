// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Scroll behavior of the sticky-header table (#232): the header stays pinned
// while the height-capped body viewport scrolls, rows scrolled out of the
// viewport are clipped from hit testing, and the batch-actions bar still
// overlays the pinned header after scrolling.

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Web unit tests use wide placeholder glyphs; native browser tests load Plex.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(
      child: SizedBox(width: kIsWeb ? 720 : 480, child: child),
    ),
  ),
);

const List<CarbonTableColumn> _columns = <CarbonTableColumn>[
  CarbonTableColumn(title: 'Name'),
  CarbonTableColumn(title: 'Status'),
];

/// Rows named `Row 1` … `Row [count]`; at the default lg size each is 48px,
/// so 12 rows (576px) overflow the 320px sticky viewport.
List<CarbonTableRow> _manyRows(int count) => <CarbonTableRow>[
  for (int i = 1; i <= count; i++)
    CarbonTableRow(cells: <Widget>[Text('Row $i'), Text('Status $i')]),
];

void main() {
  group('sticky header scrolling', () {
    testWidgets('body is capped at stickyHeaderHeight and scrolls while the '
        'header stays pinned', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _manyRows(12),
            stickyHeader: true,
          ),
        ),
      );
      // The body viewport is capped at the default 320px sticky height even
      // though the 12 lg rows want 576px.
      expect(tester.getSize(find.byType(Scrollable)).height, 320);

      final Offset headerBefore = tester.getTopLeft(find.text('Name'));
      final Offset row1Before = tester.getTopLeft(find.text('Row 1'));

      await tester.drag(find.byType(Scrollable), const Offset(0, -150));
      await tester.pumpAndSettle();

      // The header did not move; the rows scrolled up underneath it.
      expect(tester.getTopLeft(find.text('Name')), headerBefore);
      expect(tester.getTopLeft(find.text('Row 1')).dy, lessThan(row1Before.dy));
    });

    testWidgets('scrollUntilVisible reaches the last row without moving the '
        'header', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _manyRows(12),
            stickyHeader: true,
          ),
        ),
      );
      final Offset headerBefore = tester.getTopLeft(find.text('Name'));
      expect(find.text('Row 12').hitTestable(), findsNothing);

      await tester.scrollUntilVisible(find.text('Row 12'), 48);
      await tester.pumpAndSettle();

      expect(find.text('Row 12').hitTestable(), findsOneWidget);
      expect(tester.getTopLeft(find.text('Name')), headerBefore);
    });

    testWidgets('rows scrolled above the viewport are clipped out of hit '
        'testing', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _manyRows(12),
            stickyHeader: true,
          ),
        ),
      );
      // Over-drag; clamping physics settle at the 256px max extent.
      await tester.drag(find.byType(Scrollable), const Offset(0, -600));
      await tester.pumpAndSettle();

      // The first row is still laid out (the body viewport keeps its
      // child mounted) but sits above the clipped viewport, so it can no
      // longer be hit — matching content hidden under the sticky header.
      expect(find.text('Row 1'), findsOneWidget);
      expect(find.text('Row 1').hitTestable(), findsNothing);
      expect(find.text('Row 12').hitTestable(), findsOneWidget);
    });
  });

  group('batch actions under scroll', () {
    testWidgets('selecting a row after scrolling overlays the bar on the '
        'pinned header', (WidgetTester tester) async {
      Set<int> selected = <int>{};
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                CarbonDataTable(
                  columns: _columns,
                  rows: _manyRows(12),
                  stickyHeader: true,
                  selection: CarbonTableSelection.multi,
                  selectedRows: selected,
                  onSelectionChanged: (Set<int> next) =>
                      setState(() => selected = next),
                  batchActions: const <CarbonTableBatchAction>[
                    CarbonTableBatchAction(label: 'Delete'),
                  ],
                ),
          ),
        ),
      );
      final Offset headerBefore = tester.getTopLeft(find.text('Name'));

      // Scroll the body, then select a row that is visible after the scroll.
      await tester.drag(find.byType(Scrollable), const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Select row 6'));
      await tester.pumpAndSettle();

      // The batch bar slid in over the header band — which never moved —
      // rather than over the scrolled rows.
      expect(find.text('1 item selected'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Name')), headerBefore);
      final Rect bar = tester.getRect(find.text('1 item selected'));
      final Rect name = tester.getRect(find.text('Name'));
      expect(bar.top, lessThan(name.bottom));
      expect(bar.bottom, greaterThan(name.top));

      // The body still scrolls with the bar shown.
      final Offset row6 = tester.getTopLeft(find.text('Row 6'));
      await tester.drag(find.byType(Scrollable), const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Row 6')).dy, lessThan(row6.dy));
      expect(find.text('1 item selected'), findsOneWidget);
    });
  });
}
