// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 480, child: child)),
  ),
);

const List<CarbonTableColumn> _columns = <CarbonTableColumn>[
  CarbonTableColumn(title: 'Name', sortable: true),
  CarbonTableColumn(title: 'Status'),
];

List<CarbonTableRow> _rows() => const <CarbonTableRow>[
  CarbonTableRow(cells: <Widget>[Text('Load'), Text('Running')]),
  CarbonTableRow(cells: <Widget>[Text('Store'), Text('Stopped')]),
];

bool _hasIcon(WidgetTester tester, CarbonIconData icon) => tester
    .widgetList<CarbonIcon>(find.byType(CarbonIcon))
    .any((CarbonIcon i) => i.icon == icon);

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('sort affordance', () {
    testWidgets('a sortable header reports its index when tapped', (
      WidgetTester tester,
    ) async {
      int? sorted;
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            onSort: (int i) => sorted = i,
          ),
        ),
      );
      await tester.tap(find.text('Name'));
      expect(sorted, 0);
    });

    testWidgets('non-sortable header does not report sorts', (
      WidgetTester tester,
    ) async {
      int? sorted;
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            onSort: (int i) => sorted = i,
          ),
        ),
      );
      await tester.tap(find.text('Status'));
      expect(sorted, isNull);
    });

    testWidgets('Enter activates a focused sort header', (
      WidgetTester tester,
    ) async {
      int sorts = 0;
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            onSort: (_) => sorts++,
          ),
        ),
      );
      Focus.of(tester.element(find.text('Name'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sorts, 1);
    });
  });

  group('sort glyph', () {
    testWidgets('ascending shows ArrowUp; descending shows ArrowDown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            sortColumnIndex: 0,
            sortDirection: CarbonSortDirection.ascending,
            onSort: (_) {},
          ),
        ),
      );
      expect(_hasIcon(tester, CarbonIcons.arrowUp), isTrue);
      expect(_hasIcon(tester, CarbonIcons.arrowDown), isFalse);

      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            sortColumnIndex: 0,
            sortDirection: CarbonSortDirection.descending,
            onSort: (_) {},
          ),
        ),
      );
      expect(_hasIcon(tester, CarbonIcons.arrowDown), isTrue);
    });

    testWidgets('an unsorted sortable header uses the inactive arrows glyph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(columns: _columns, rows: _rows(), onSort: (_) {}),
        ),
      );
      expect(_hasIcon(tester, CarbonIcons.arrowsVertical), isTrue);
    });
  });

  group('semantics (#226)', () {
    testWidgets('the sorted column header is a labelled, focusable '
        'tap target', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            sortColumnIndex: 0,
            sortDirection: CarbonSortDirection.ascending,
            onSort: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Name')),
        isSemantics(hasTapAction: true, isFocusable: true),
      );
      // TODO(#226): upstream TableHeader exposes the direction via
      // `aria-sort`, but the sorted column carries no sort-state
      // semantics here (no hint/value/flag) — only the activation
      // surface can be asserted until that lands.
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('sorted table across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'data_table_sorted',
        containsText: true,
        size: const Size(520, 200),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 480,
            child: CarbonDataTable(
              columns: const <CarbonTableColumn>[
                CarbonTableColumn(title: 'Name', sortable: true),
                CarbonTableColumn(title: 'Status', sortable: true),
              ],
              sortColumnIndex: 0,
              sortDirection: CarbonSortDirection.ascending,
              onSort: (_) {},
              rows: const <CarbonTableRow>[
                CarbonTableRow(cells: <Widget>[Text('Cache'), Text('Running')]),
                CarbonTableRow(cells: <Widget>[Text('Load'), Text('Stopped')]),
                CarbonTableRow(cells: <Widget>[Text('Store'), Text('Running')]),
              ],
            ),
          ),
        ),
      );
    });
  });
}
