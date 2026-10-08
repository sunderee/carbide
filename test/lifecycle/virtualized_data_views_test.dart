// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  Widget child, {
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 760, child: child),
      ),
    ),
  ),
);
const _columns = [
  CarbonTableColumn(title: 'Name'),
  CarbonTableColumn(title: 'Status'),
];
List<CarbonTableRow> _rows(int count) => [
  for (int i = 0; i < count; i++)
    CarbonTableRow(
      id: i,
      label: 'Record $i',
      cells: [
        _Cell(id: i),
        const Text('Available'),
      ],
      expandedContent: Text('Details $i'),
    ),
];
List<CarbonTreeNode> _nodes(int count) => [
  for (int i = 0; i < count; i++)
    CarbonTreeNode(id: i, label: 'Record $i', disabled: i == 998),
];
void check(String name, WidgetTesterCallback body) =>
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });
void main() {
  for (final sticky in [false, true]) {
    check('1,000 virtual table rows stay bounded with sticky=$sticky', (
      tester,
    ) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(1000),
            virtualized: true,
            viewportHeight: 240,
            scrollController: scroll,
            stickyHeader: sticky,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(_Cell).evaluate().length, lessThanOrEqualTo(12));
      final header = tester.getTopLeft(find.text('Name'));
      for (int i = 0; i < 12; i++) {
        await tester.drag(find.byType(Scrollable), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(find.byType(_Cell).evaluate().length, lessThanOrEqualTo(12));
      }
      expect(scroll.offset, greaterThan(1000));
      if (sticky)
        expect(tester.getTopLeft(find.text('Name')), header);
      else
        expect(find.text('Name'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  check(
    'virtual table selection, expansion, cell state and focus follow stable IDs',
    (tester) async {
      final rows = ValueNotifier(_rows(1000)), scroll = ScrollController();
      addTearDown(rows.dispose);
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder(
            valueListenable: rows,
            builder: (_, value, _) => CarbonDataTable(
              columns: _columns,
              rows: value,
              virtualized: true,
              viewportHeight: 240,
              scrollController: scroll,
              stickyHeader: true,
              selection: CarbonTableSelection.multi,
              selectedRowIds: const {0},
              onSelectedRowIdsChanged: (_) {},
              expandable: true,
              expandedRowIds: const {0},
              onExpansionChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cell = tester.state<_CellState>(find.byType(_Cell).first);
      cell.increment();
      cell.focus.requestFocus();
      await tester.pumpAndSettle();
      for (int i = 0; i < 8; i++) {
        await tester.drag(find.byType(Scrollable), const Offset(0, -180));
        await tester.pumpAndSettle();
      }
      expect(cell.focus.hasPrimaryFocus, isTrue);
      expect(find.byType(_Cell).evaluate().length, lessThanOrEqualTo(13));
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.state(find.byKey(const ValueKey('cell-0'))), same(cell));
      expect(cell.count, 1);
      expect(cell.focus.hasPrimaryFocus, isTrue);
      rows.value = rows.value.reversed.toList();
      await tester.pumpAndSettle();
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(tester.state(find.byKey(const ValueKey('cell-0'))), same(cell));
      expect(cell.focus.hasPrimaryFocus, isTrue);
      expect(find.text('Details 0').hitTestable(), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(find.bySemanticsLabel('Select row Record 0'))
            .properties
            .checked,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );
  check('virtualized tables require stable unique record IDs', (tester) async {
    expect(
      () => tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: const [
              CarbonTableRow(cells: [Text('A')]),
            ],
            virtualized: true,
          ),
        ),
      ),
      throwsAssertionError,
    );
  });
  for (final direction in TextDirection.values) {
    for (final scale in [1.3, 2.0]) {
      check(
        'virtual tree reveals never-mounted End and preserves focus in $direction at $scale',
        (tester) async {
          final scroll = ScrollController();
          addTearDown(scroll.dispose);
          await tester.pumpWidget(
            _host(
              CarbonTreeView(
                nodes: _nodes(1000),
                label: 'Files',
                virtualized: true,
                viewportHeight: 240,
                scrollController: scroll,
              ),
              scale: scale,
              direction: direction,
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Record 999'), findsNothing);
          expect(find.byType(Text).evaluate().length, lessThanOrEqualTo(12));
          await tester.tap(find.text('Record 0'));
          await tester.pumpAndSettle();
          final first = FocusManager.instance.primaryFocus!;
          await tester.sendKeyEvent(LogicalKeyboardKey.end);
          await tester.pumpAndSettle();
          expect(find.text('Record 999').hitTestable(), findsOneWidget);
          expect(FocusManager.instance.primaryFocus!.debugLabel, 'tree-999');
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus!.debugLabel, 'tree-997');
          scroll.jumpTo(0);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus!.debugLabel, 'tree-997');
          scroll.jumpTo(scroll.position.maxScrollExtent);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus!.debugLabel, 'tree-997');
          expect(find.byType(Text).evaluate().length, lessThanOrEqualTo(13));
          await tester.sendKeyEvent(LogicalKeyboardKey.home);
          await tester.pumpAndSettle();
          expect(FocusManager.instance.primaryFocus, same(first));
          expect(find.text('Record 0').hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  check('eager table and tree rendering remain available', (tester) async {
    await tester.pumpWidget(
      _host(
        CarbonDataTable(
          columns: _columns,
          rows: _rows(1000),
          stickyHeader: true,
        ),
      ),
    );
    expect(find.byType(_Cell), findsNWidgets(1000));
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 240,
          child: SingleChildScrollView(
            child: CarbonTreeView(nodes: _nodes(1000), label: 'Files'),
          ),
        ),
      ),
    );
    expect(find.text('Record 999'), findsOneWidget);
  });
}

class _Cell extends StatefulWidget {
  _Cell({required this.id}) : super(key: ValueKey('cell-$id'));
  final int id;
  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> {
  final focus = FocusNode();
  int count = 0;
  void increment() => setState(() => count++);
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarbonButton(
    label: 'Record ${widget.id} · $count',
    focusNode: focus,
    onPressed: increment,
  );
}
