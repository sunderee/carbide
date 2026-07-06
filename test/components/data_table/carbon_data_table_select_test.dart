// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 520, child: child)),
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

/// A controlled multi/single-select table for interaction tests.
class _Selectable extends StatefulWidget {
  const _Selectable({this.multi = true, this.batchActions});
  final bool multi;
  final List<CarbonTableBatchAction>? batchActions;
  @override
  State<_Selectable> createState() => _SelectableState();
}

class _SelectableState extends State<_Selectable> {
  Set<int> _selected = <int>{};
  @override
  Widget build(BuildContext context) => CarbonDataTable(
    columns: _columns,
    rows: _rows(),
    selection: widget.multi
        ? CarbonTableSelection.multi
        : CarbonTableSelection.single,
    selectedRows: _selected,
    batchActions: widget.batchActions,
    onSelectionChanged: (Set<int> s) => setState(() => _selected = s),
  );
}

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('motion', () {
    testWidgets('batch bar slide tokens match _data-table-action.scss', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const _Selectable(
            batchActions: <CarbonTableBatchAction>[
              CarbonTableBatchAction(label: 'Delete'),
            ],
          ),
        ),
      );
      // `--batch-actions`: transform $duration-fast-02
      // motion(standard, productive).
      final AnimatedSlide bar = tester.widget(find.byType(AnimatedSlide));
      expect(bar.duration, CarbonDuration.fast02);
      expect(bar.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion slides the batch bar instantly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: _Selectable(
              batchActions: <CarbonTableBatchAction>[
                CarbonTableBatchAction(label: 'Delete'),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).duration,
        Duration.zero,
      );
      // Selecting a row lands the bar fully on the next frame.
      await tester.tap(find.bySemanticsLabel('Select row 1'));
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
        Offset.zero,
      );
      expect(find.text('1 item selected'), findsOneWidget);
    });
  });

  group('multi-select', () {
    testWidgets('row checkbox selects + fills with layer-selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const _Selectable()));
      expect(find.byType(CarbonCheckbox), findsNWidgets(4)); // select-all + 3
      await tester.tap(find.bySemanticsLabel('Select row 2'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Store'), theme.layerSelected01);
      expect(_rowColor(tester, 'Load'), theme.layer01);
    });

    testWidgets('row checkbox is vertically centered in its row', (
      WidgetTester tester,
    ) async {
      // Regression: an empty-label checkbox used to reserve a body text line,
      // pinning the box to the top so it rode above the row centre.
      await tester.pumpWidget(_host(const _Selectable()));
      final Rect box = tester.getRect(
        find
            .descendant(
              of: find.bySemanticsLabel('Select row 1'),
              matching: find.byType(CarbonCheckbox),
            )
            .first,
      );
      // The selector is the 16px box only (no stray text line), and its centre
      // lines up with the centred data-cell text in the same row.
      expect(box.height, CarbonCheckbox.boxSize);
      expect(
        box.center.dy,
        moreOrLessEquals(
          tester.getRect(find.text('Load')).center.dy,
          epsilon: 0.5,
        ),
      );
    });

    testWidgets('select-all toggles every row, then clears', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const _Selectable()));
      await tester.tap(find.bySemanticsLabel('Select all rows'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Load'), theme.layerSelected01);
      expect(_rowColor(tester, 'Cache'), theme.layerSelected01);
      // The batch bar now covers the header (incl. select-all); Cancel clears.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Load'), theme.layer01);
    });
  });

  group('single-select', () {
    testWidgets('radios are exclusive', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const _Selectable(multi: false)));
      expect(find.byType(CarbonRadioButton), findsNWidgets(3));
      await tester.tap(find.bySemanticsLabel('Select row 1'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Load'), theme.layerSelected01);
      await tester.tap(find.bySemanticsLabel('Select row 3'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Cache'), theme.layerSelected01);
      expect(_rowColor(tester, 'Load'), theme.layer01); // exclusive
    });
  });

  group('batch actions', () {
    testWidgets('bar appears with a count and a working action', (
      WidgetTester tester,
    ) async {
      int deleted = 0;
      await tester.pumpWidget(
        _host(
          _Selectable(
            batchActions: <CarbonTableBatchAction>[
              CarbonTableBatchAction(
                label: 'Delete',
                onPressed: () => deleted++,
              ),
            ],
          ),
        ),
      );
      // Nothing selected → no count yet.
      expect(find.text('1 item selected'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Select row 1'));
      await tester.pumpAndSettle();
      expect(find.text('1 item selected'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Select row 2'));
      await tester.pumpAndSettle();
      expect(find.text('2 items selected'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      expect(deleted, 1);
      // Cancel clears the selection.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Load'), theme.layer01);
    });
  });

  group('goldens', () {
    testWidgets('multi-select with a batch bar across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'data_table_batch',
        containsText: true,
        size: const Size(560, 240),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 520,
            child: CarbonDataTable(
              columns: _columns,
              rows: _rows(),
              selection: CarbonTableSelection.multi,
              selectedRows: const <int>{0, 1},
              onSelectionChanged: (_) {},
              batchActions: <CarbonTableBatchAction>[
                CarbonTableBatchAction(label: 'Delete', onPressed: () {}),
              ],
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
