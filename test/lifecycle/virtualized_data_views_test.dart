// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'dart:ui' show SemanticsRole;

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';
import '../support/legibility.dart';

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
      if (sticky) {
        expect(tester.getTopLeft(find.text('Name')), header);
      } else {
        expect(find.text('Name'), findsNothing);
      }
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
      // Variable detail height refines the sliver's initial end estimate.
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
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
  test('virtualized tables require stable unique record IDs', () {
    expect(
      () => const CarbonDataTable(
        columns: _columns,
        rows: [
          CarbonTableRow(cells: [Text('A')]),
        ],
        virtualized: true,
      ).createElement(),
      throwsAssertionError,
    );
    expect(
      () => const CarbonDataTable(
        columns: _columns,
        rows: [
          CarbonTableRow(id: 1, cells: [Text('A')]),
          CarbonTableRow(id: 1, cells: [Text('B')]),
        ],
        virtualized: true,
      ).createElement(),
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
  test('virtual view heights reject zero, negative and infinite values', () {
    for (final height in [0.0, -1.0, double.infinity, double.nan]) {
      expect(
        () => CarbonDataTable(
          columns: _columns,
          rows: const [],
          virtualized: true,
          viewportHeight: height,
        ),
        throwsAssertionError,
      );
      expect(
        () => CarbonTreeView(
          nodes: const [],
          label: 'Files',
          virtualized: true,
          viewportHeight: height,
        ),
        throwsAssertionError,
      );
    }
  });
  test('virtual table state uses stable-ID selection and expansion APIs', () {
    expect(
      () => CarbonDataTable(
        columns: _columns,
        rows: _rows(1),
        virtualized: true,
        onSelectionChanged: (_) {},
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonDataTable(
        columns: _columns,
        rows: _rows(1),
        virtualized: true,
        onExpandedChanged: (_) {},
      ),
      throwsAssertionError,
    );
  });
  check(
    'virtual table semantics expose only mounted rows with table/cell roles',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            CarbonDataTable(
              columns: _columns,
              rows: [
                for (int i = 0; i < 1000; i++)
                  CarbonTableRow(
                    id: i,
                    cells: [Text('Item $i'), const Text('Available')],
                  ),
              ],
              virtualized: true,
              stickyHeader: true,
              viewportHeight: 240,
              semanticsLabel: 'Records',
            ),
          ),
        );
        await tester.pumpAndSettle();
        final table = tester.getSemantics(find.bySemanticsLabel('Records'));
        expect(table.getSemanticsData().role, SemanticsRole.table);
        final labels = tester.semantics
            .simulatedAccessibilityTraversal()
            .map((node) => node.label)
            .toList();
        expect(labels, contains('Item 0'));
        expect(labels, isNot(contains('Item 999')));
        final rowNodes = tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where((node) => node.properties.role == SemanticsRole.row)
            .toList();
        expect(rowNodes.length, lessThanOrEqualTo(8));
        expect(rowNodes.length, greaterThan(1));
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        semantics.dispose();
      }
    },
  );
  check(
    'virtual view data shrink and empty sources preserve valid scroll positions',
    (tester) async {
      final count = ValueNotifier(1000), scroll = ScrollController();
      addTearDown(count.dispose);
      addTearDown(scroll.dispose);
      for (final table in [true, false]) {
        count.value = 1000;
        await tester.pumpWidget(
          _host(
            ValueListenableBuilder(
              valueListenable: count,
              builder: (_, n, _) => table
                  ? CarbonDataTable(
                      columns: _columns,
                      rows: _rows(n),
                      virtualized: true,
                      scrollController: scroll,
                    )
                  : CarbonTreeView(
                      nodes: _nodes(n),
                      label: 'Files',
                      virtualized: true,
                      scrollController: scroll,
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        scroll.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        count.value = 3;
        await tester.pumpAndSettle();
        expect(
          scroll.offset,
          lessThanOrEqualTo(scroll.position.maxScrollExtent),
        );
        count.value = 0;
        await tester.pumpAndSettle();
        expect(scroll.position.maxScrollExtent, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    },
  );
  check(
    'virtual tree expansion and hidden-child focus recover to its stable parent',
    (tester) async {
      final expanded = ValueNotifier<Set<Object>>({}),
          scroll = ScrollController();
      addTearDown(expanded.dispose);
      addTearDown(scroll.dispose);
      final nodes = [
        const CarbonTreeNode(
          id: 'folder',
          label: 'Folder',
          children: [CarbonTreeNode(id: 'child', label: 'Child')],
        ),
        ..._nodes(1000),
      ];
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder(
            valueListenable: expanded,
            builder: (_, ids, _) => CarbonTreeView(
              nodes: nodes,
              label: 'Files',
              virtualized: true,
              scrollController: scroll,
              expandedIds: ids,
              onExpansionChanged: (next) => expanded.value = next,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Folder'));
      await tester.pumpAndSettle();
      final folder = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(expanded.value, contains('folder'));
      expect(find.text('Child'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus!.debugLabel, 'tree-child');
      expanded.value = {};
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, same(folder));
      expect(find.text('Child'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(find.text('Record 999').hitTestable(), findsOneWidget);
    },
  );
  check('a kept-alive offscreen editor retains its root semantics value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics(),
        scroll = ScrollController(),
        focus = FocusNode(),
        controller = TextEditingController(text: 'Retained draft');
    addTearDown(scroll.dispose);
    addTearDown(focus.dispose);
    addTearDown(controller.dispose);
    try {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: [
              CarbonTableRow(
                id: 0,
                cells: [
                  CarbonTextInput(
                    labelText: 'Draft',
                    controller: controller,
                    focusNode: focus,
                  ),
                  const Text('Available'),
                ],
              ),
              for (int i = 1; i < 1000; i++)
                CarbonTableRow(
                  id: i,
                  cells: [Text('Item $i'), const Text('Available')],
                ),
            ],
            virtualized: true,
            scrollController: scroll,
            stickyHeader: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      focus.requestFocus();
      await tester.pumpAndSettle();
      final node = tester.getSemantics(find.bySemanticsLabel('Draft'));
      final owner = tester
          .renderObject(find.byType(CarbonDataTable))
          .owner!
          .semanticsOwner!;
      bool present() {
        bool found = false;
        void visit(SemanticsNode current) {
          if (current.id == node.id) found = true;
          current.visitChildren((SemanticsNode child) {
            visit(child);
            return true;
          });
        }

        visit(owner.rootSemanticsNode!);
        return found;
      }

      scroll.jumpTo(1200);
      await tester.pumpAndSettle();
      expect(focus.hasPrimaryFocus, isTrue);
      expect(present(), isTrue);
      expect(node.value, 'Retained draft');
      expect(node.flagsCollection.isHidden, isTrue);
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(controller.text, 'Retained draft');
      expect(tester.getSemantics(find.bySemanticsLabel('Draft')).id, node.id);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    } finally {
      semantics.dispose();
    }
  });
  check('eager table supports intrinsic measurement', (tester) async {
    await tester.pumpWidget(
      _host(
        IntrinsicHeight(
          child: CarbonDataTable(columns: _columns, rows: _rows(3)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(_Cell), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
  for (final table in [true, false]) {
    check('virtual ${table ? 'table' : 'tree'} goldens at 2x', (tester) async {
      await expectThemeGoldens(
        tester,
        name: table ? 'virtual_table_scaled' : 'virtual_tree_scaled',
        containsText: true,
        size: table ? const Size(760, 540) : const Size(320, 420),
        directions: const {TextDirection.ltr, TextDirection.rtl},
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2)),
        builder: (_) => Align(
          alignment: Alignment.topLeft,
          child: table
              ? CarbonDataTable(
                  columns: _columns,
                  rows: [
                    for (int i = 0; i < 1000; i++)
                      CarbonTableRow(
                        id: i,
                        label: 'Record $i',
                        cells: [Text('Record $i'), const Text('Available')],
                        expandedContent: Text('Details $i'),
                      ),
                  ],
                  virtualized: true,
                  viewportHeight: 320,
                  stickyHeader: true,
                  expandable: true,
                  expandedRowIds: const {0},
                  onExpansionChanged: (_) {},
                  selection: CarbonTableSelection.multi,
                  selectedRowIds: const {0},
                  onSelectedRowIdsChanged: (_) {},
                )
              : CarbonTreeView(
                  nodes: [
                    const CarbonTreeNode(
                      id: 'folder',
                      label: 'Folder',
                      children: [CarbonTreeNode(id: 'child', label: 'Child')],
                    ),
                    ..._nodes(1000),
                  ],
                  label: 'Files',
                  virtualized: true,
                  expandedIds: const {'folder'},
                  selectedId: 'child',
                ),
        ),
        afterPump: (tester) async {
          await tester.pumpAndSettle();
          expectNoClippedTextAtScale(tester, 2);
        },
      );
    });
  }
  check('eager table and tree rendering remain available', (tester) async {
    await tester.pumpWidget(
      _host(
        CarbonDataTable(
          columns: _columns,
          rows: _rows(100),
          stickyHeader: true,
        ),
      ),
    );
    expect(find.byType(_Cell), findsNWidgets(100));
    await tester.pumpWidget(
      _host(
        SizedBox(
          height: 240,
          child: SingleChildScrollView(
            child: CarbonTreeView(nodes: _nodes(100), label: 'Files'),
          ),
        ),
      ),
    );
    expect(find.text('Record 99'), findsOneWidget);
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
