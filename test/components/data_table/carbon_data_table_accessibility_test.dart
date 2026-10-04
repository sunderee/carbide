// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui'
    show
        SemanticsRole,
        Tristate,
        ViewFocusDirection,
        ViewFocusEvent,
        ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/overlay_entries.dart';

const _columns = <CarbonTableColumn>[
  CarbonTableColumn(title: 'Name', sortable: true),
  CarbonTableColumn(title: 'Status'),
];
const _rows = <CarbonTableRow>[
  CarbonTableRow(id: 'a', cells: <Widget>[Text('Alpha'), Text('Ready')]),
  CarbonTableRow(id: 'b', cells: <Widget>[Text('Beta'), Text('Stopped')]),
];

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (_, _) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (_) => Center(child: SizedBox(width: 480, child: child)),
            ),
          ],
        ),
      ),
    ),
  ),
);

Iterable<SemanticsNode> _nodes(WidgetTester tester) {
  Iterable<SemanticsNode> visit(SemanticsNode node) sync* {
    if (node.isMergedIntoParent) return;
    yield node;
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      yield* visit(child);
    }
  }

  return visit(
    tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!,
  );
}

SemanticsNode _label(WidgetTester tester, String label) =>
    _nodes(tester)
        .singleWhere((node) => node.getSemanticsData().label == label);

void _action(WidgetTester tester, SemanticsNode node, SemanticsAction action) {
  if (action == SemanticsAction.focus) {
    tester.binding.handleViewFocusChanged(
      ViewFocusEvent(
        viewId: tester.view.viewId,
        state: ViewFocusState.focused,
        direction: ViewFocusDirection.undefined,
      ),
    );
  }
  tester.binding.platformDispatcher.onSemanticsActionEvent!(
    SemanticsActionEvent(
      type: action,
      nodeId: node.id,
      viewId: tester.view.viewId,
    ),
  );
}

void _test(String name, WidgetTesterCallback body) {
  testWidgets(name, (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await body(tester);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      semantics.dispose();
    }
  });
}

void main() {
  for (final direction in TextDirection.values) {
    for (final size in CarbonTableSize.values) {
      _test('sort target fills $size band in $direction (#307)', (
        tester,
      ) async {
        final calls = <int>[];
        await tester.pumpWidget(
          _host(
            CarbonDataTable(
              size: size,
              columns: _columns,
              rows: _rows,
              onSort: calls.add,
            ),
            direction: direction,
          ),
        );
        final SemanticsData header = _label(tester, 'Name').getSemanticsData();
        expect(header.rect.height, size.height);
        expect(header.rect.width, 240);
        expect(header.flagsCollection.isButton, isTrue);
        expect(header.flagsCollection.isFocused, isNot(Tristate.none));
        expect(header.hasAction(SemanticsAction.tap), isTrue);
        expect(header.value, 'Not sorted');
        final Rect band = tester.getRect(
          find.byWidgetPredicate(
            (widget) =>
                widget is ColoredBox &&
                widget.color == CarbonThemeData.white.layerAccent01,
          ),
        );
        final double start = direction == TextDirection.ltr
            ? band.left
            : band.center.dx;
        for (final x in <double>[0.02, 0.5, 0.98]) {
          for (final y in <double>[0.02, 0.5, 0.98]) {
            await tester.tapAt(
              Offset(start + band.width / 2 * x, band.top + band.height * y),
            );
            await tester.pumpAndSettle();
          }
        }
        expect(calls, List<int>.filled(9, 0));
        // Carbon's xs/sm/md bands intentionally stay below 48dp; lg/xl must
        // meet the complete target guideline (_data-table.scss size tokens).
        await expectA11y(tester, tapTargets: size.height >= 48);
      });
    }

    for (final directionState in CarbonSortDirection.values) {
      _test('sort state $directionState is named in $direction (#307)', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            CarbonDataTable(
              columns: _columns,
              rows: _rows,
              sortColumnIndex: 0,
              sortDirection: directionState,
              onSort: (_) {},
            ),
            direction: direction,
          ),
        );
        final SemanticsData header = _label(tester, 'Name').getSemanticsData();
        expect(header.value, switch (directionState) {
          CarbonSortDirection.none => 'Not sorted',
          CarbonSortDirection.ascending => 'Sorted ascending',
          CarbonSortDirection.descending => 'Sorted descending',
        });
        expect(header.flagsCollection.isButton, isTrue);
        final SemanticsData plain = _label(tester, 'Status').getSemanticsData();
        expect(plain.flagsCollection.isButton, isFalse);
        expect(plain.hasAction(SemanticsAction.tap), isFalse);
        expect(plain.role, SemanticsRole.columnHeader);
      });
    }

    for (final sticky in <bool>[false, true]) {
      _test(
        'named table reads title, headers, cells in $direction sticky=$sticky',
        (tester) async {
          await tester.pumpWidget(
            _host(
              CarbonDataTable(
                title: 'Jobs',
                description: 'Overview',
                stickyHeader: sticky,
                columns: _columns,
                rows: _rows,
                onSort: (_) {},
              ),
              direction: direction,
            ),
          );
          final tables = _nodes(tester).where(
            (node) => node.getSemanticsData().role == SemanticsRole.table,
          );
          expect(tables, hasLength(1));
          expect(tables.single.getSemanticsData().label, 'Jobs');
          expect(
            _nodes(tester).where(
              (node) => node.getSemanticsData().role == SemanticsRole.row,
            ),
            hasLength(3),
          );
          expect(
            _nodes(tester).where(
              (node) =>
                  node.getSemanticsData().role == SemanticsRole.columnHeader,
            ),
            hasLength(2),
          );
          expect(
            _nodes(tester).where(
              (node) => node.getSemanticsData().role == SemanticsRole.cell,
            ),
            hasLength(4),
          );
          final labels = _nodes(tester)
              .where(
                (node) => node.getSemanticsData().role != SemanticsRole.table,
              )
              .map((node) => node.getSemanticsData().label)
              .where((label) => label.isNotEmpty)
              .toList();
          expect(labels, <String>[
            'Jobs',
            'Overview',
            'Name',
            'Status',
            'Alpha',
            'Ready',
            'Beta',
            'Stopped',
          ]);
        },
      );
    }

    _test(
      'semantic and keyboard sorts cycle once and retain focus $direction',
      (tester) async {
        CarbonSortDirection state = CarbonSortDirection.none;
        final calls = <int>[];
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, update) => CarbonDataTable(
                columns: _columns,
                rows: state == CarbonSortDirection.descending
                    ? _rows.reversed.toList()
                    : _rows,
                sortColumnIndex: 0,
                sortDirection: state,
                onSort: (index) => update(() {
                  calls.add(index);
                  state =
                      CarbonSortDirection.values[(state.index + 1) %
                          CarbonSortDirection.values.length];
                }),
              ),
            ),
            direction: direction,
          ),
        );
        _action(tester, _label(tester, 'Name'), SemanticsAction.focus);
        await tester.pumpAndSettle();
        final FocusNode? focus = FocusManager.instance.primaryFocus;
        _action(tester, _label(tester, 'Name'), SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(state, CarbonSortDirection.ascending);
        expect(
          _label(tester, 'Name').getSemanticsData().value,
          'Sorted ascending',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(state, CarbonSortDirection.descending);
        expect(
          _label(tester, 'Name').getSemanticsData().value,
          'Sorted descending',
        );
        expect(FocusManager.instance.primaryFocus, same(focus));
        expect(
          _nodes(tester)
              .map((node) => node.getSemanticsData().label)
              .where((label) => label == 'Alpha' || label == 'Beta'),
          <String>['Beta', 'Alpha'],
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(state, CarbonSortDirection.none);
        expect(calls, <int>[0, 0, 0]);
        expect(FocusManager.instance.primaryFocus, same(focus));
      },
    );

    for (final state in CarbonSortDirection.values) {
      _test(
        'localized direction and independent column names $state $direction',
        (tester) async {
          const names = <CarbonSortDirection, String>{
            CarbonSortDirection.none: 'Sans tri',
            CarbonSortDirection.ascending: 'Tri croissant',
            CarbonSortDirection.descending: 'Tri décroissant',
          };
          await tester.pumpWidget(
            _host(
              CarbonDataTable(
                title: 'Travaux',
                semanticsLabel: 'Travaux planifiés',
                sortDirectionFormatter: (value) => names[value]!,
                columns: const <CarbonTableColumn>[
                  CarbonTableColumn(title: 'Nom', sortable: true),
                  CarbonTableColumn(title: 'État', sortable: true),
                ],
                rows: _rows,
                sortColumnIndex: 0,
                sortDirection: state,
                onSort: (_) {},
              ),
              direction: direction,
            ),
          );
          expect(
            _nodes(tester)
                .singleWhere((node) => node.role == SemanticsRole.table)
                .label,
            'Travaux planifiés',
          );
          expect(_label(tester, 'Nom').value, names[state]);
          expect(_label(tester, 'État').value, names[CarbonSortDirection.none]);
          expect(
            _label(tester, 'Nom').getSemanticsData().flagsCollection.isButton,
            isTrue,
          );
          expect(
            _label(tester, 'État').getSemanticsData().flagsCollection.isButton,
            isTrue,
          );
        },
      );
    }

    _test('untitled table has an accessible fallback name $direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonDataTable(columns: _columns, rows: _rows),
          direction: direction,
        ),
      );
      expect(
        _nodes(tester)
            .singleWhere((node) => node.role == SemanticsRole.table)
            .label,
        'Data table',
      );
    });

    _test(
      'saved sort actions respect disabled, static and removed headers $direction',
      (tester) async {
        bool enabled = true, sortable = true, shown = true;
        int calls = 0;
        late StateSetter update;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return shown
                    ? CarbonDataTable(
                        columns: <CarbonTableColumn>[
                          CarbonTableColumn(title: 'Name', sortable: sortable),
                        ],
                        rows: const <CarbonTableRow>[],
                        onSort: enabled ? (_) => calls++ : null,
                      )
                    : const SizedBox.shrink();
              },
            ),
            direction: direction,
          ),
        );
        Semantics headerWidget() => tester
            .widgetList<Semantics>(find.byType(Semantics))
            .singleWhere(
              (widget) =>
                  widget.properties.label == 'Name' &&
                  widget.properties.button == true,
            );
        final oldTap = headerWidget().properties.onTap!,
            oldFocus = headerWidget().properties.onFocus!;
        _action(tester, _label(tester, 'Name'), SemanticsAction.focus);
        await tester.pumpAndSettle();
        update(() => enabled = false);
        await tester.pumpAndSettle();
        oldTap();
        oldFocus();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        final disabled = _label(tester, 'Name').getSemanticsData();
        expect(disabled.hasAction(SemanticsAction.tap), isFalse);
        expect(disabled.hasAction(SemanticsAction.focus), isFalse);
        expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
        expect(calls, 0);
        update(() {
          enabled = true;
          sortable = false;
        });
        await tester.pumpAndSettle();
        oldTap();
        oldFocus();
        expect(
          _label(tester, 'Name').getSemanticsData().flagsCollection.isButton,
          isFalse,
        );
        expect(calls, 0);
        update(() => shown = false);
        await tester.pumpAndSettle();
        oldTap();
        oldFocus();
        await tester.pumpAndSettle();
        expect(calls, 0);
      },
    );

    _test('consumer focus requests win sort activation $direction', (
      tester,
    ) async {
      final outside = FocusNode();
      addTearDown(outside.dispose);
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Focus(focusNode: outside, child: const Text('Outside')),
              CarbonDataTable(
                columns: _columns,
                rows: _rows,
                onSort: (_) => outside.requestFocus(),
              ),
            ],
          ),
          direction: direction,
        ),
      );
      _action(tester, _label(tester, 'Name'), SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(outside.hasPrimaryFocus, isTrue);
    });

    for (final size in CarbonTableSize.values) {
      _test('full header grows with scaled text $size $direction', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            CarbonDataTable(
              size: size,
              columns: _columns,
              rows: _rows,
              onSort: (_) {},
            ),
            direction: direction,
            scale: 2,
          ),
        );
        expect(
          _label(tester, 'Name').rect.height,
          greaterThanOrEqualTo(size.height),
        );
        expect(
          _label(tester, 'Name').rect.height,
          greaterThanOrEqualTo(tester.getSize(find.text('Name')).height),
        );
        await expectA11y(tester, tapTargets: size.height >= 48);
      });
    }

    _test('AI header action remains independent of full-cell sort $direction', (
      tester,
    ) async {
      int sorts = 0;
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: const <CarbonTableColumn>[
              CarbonTableColumn(
                title: 'Name',
                sortable: true,
                aiLabel: CarbonAILabel(content: Text('Generated column')),
              ),
              CarbonTableColumn(title: 'Status'),
            ],
            rows: _rows,
            onSort: (_) => sorts++,
          ),
          direction: direction,
        ),
      );
      final ai = _nodes(tester).singleWhere(
        (node) =>
            node.getSemanticsData().flagsCollection.isButton &&
            node.label != 'Name',
      );
      expect(ai.getSemanticsData().flagsCollection.isButton, isTrue);
      Focus.of(tester.element(find.text('AI'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Generated column'), findsOneWidget);
      expect(sorts, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CarbonAILabel));
      await tester.pumpAndSettle();
      expect(sorts, 0);
      _action(tester, _label(tester, 'Name'), SemanticsAction.tap);
      await tester.pumpAndSettle();
      expect(sorts, 1);
    });

    _test(
      'sticky table exposes bounded scrolling without moving header $direction',
      (tester) async {
        double height = 96;
        bool sticky = true;
        late StateSetter update;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return CarbonDataTable(
                  columns: _columns,
                  rows: <CarbonTableRow>[
                    for (int i = 0; i < (sticky ? 20 : 2); i++)
                      CarbonTableRow(
                        id: i,
                        cells: <Widget>[Text('Row $i'), const Text('Ready')],
                      ),
                  ],
                  onSort: (_) {},
                  stickyHeader: sticky,
                  stickyHeaderHeight: height,
                );
              },
            ),
            direction: direction,
          ),
        );
        SemanticsNode table() =>
            _nodes(tester)
                .singleWhere((node) => node.role == SemanticsRole.table);
        final headerBefore = tester.getRect(find.text('Name'));
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        expect(
          table().getSemanticsData().hasAction(SemanticsAction.scrollDown),
          isTrue,
        );
        expect(
          table().getSemanticsData().hasAction(SemanticsAction.scrollUp),
          isFalse,
        );
        expect(
          table().getSemanticsData().scrollExtentMax,
          position.maxScrollExtent,
        );
        _action(tester, table(), SemanticsAction.scrollDown);
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(96 * 0.8, 0.01));
        expect(table().getSemanticsData().scrollPosition, position.pixels);
        expect(tester.getRect(find.text('Name')), headerBefore);
        _action(tester, table(), SemanticsAction.scrollUp);
        await tester.pumpAndSettle();
        expect(position.pixels, 0);
        update(() => height = 144);
        await tester.pumpAndSettle();
        expect(
          table().getSemanticsData().scrollExtentMax,
          position.maxScrollExtent,
        );
        for (int i = 0; i < 12; i++) {
          _action(tester, table(), SemanticsAction.scrollDown);
          await tester.pumpAndSettle();
        }
        expect(position.pixels, position.maxScrollExtent);
        expect(
          table().getSemanticsData().hasAction(SemanticsAction.scrollDown),
          isFalse,
        );
        update(() => sticky = false);
        await tester.pumpAndSettle();
        expect(
          table().getSemanticsData().hasAction(SemanticsAction.scrollDown),
          isFalse,
        );
        expect(table().getSemanticsData().scrollPosition, isNull);
        // All records are visible again and still have valid row/cell parents.
        expect(
          _nodes(tester).where((node) => node.role == SemanticsRole.row),
          hasLength(3),
        );
      },
    );

    _test(
      'leading controls and expanded details keep valid cell roles $direction',
      (tester) async {
        Set<Object> expanded = <Object>{}, selected = <Object>{};
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, update) => CarbonDataTable(
                columns: _columns,
                rows: const <CarbonTableRow>[
                  CarbonTableRow(
                    id: 'a',
                    label: 'Alpha',
                    cells: <Widget>[Text('Alpha'), Text('Ready')],
                    expandedContent: CarbonButton(
                      label: 'Inspect',
                      onPressed: _nothing,
                    ),
                  ),
                ],
                expandable: true,
                expandedRowIds: expanded,
                onExpansionChanged: (next) => update(() => expanded = next),
                selection: CarbonTableSelection.multi,
                selectedRowIds: selected,
                onSelectedRowIdsChanged: (next) =>
                    update(() => selected = next),
                onSort: (_) {},
              ),
            ),
            direction: direction,
          ),
        );
        expect(
          _nodes(tester)
              .where((node) => node.role == SemanticsRole.columnHeader),
          hasLength(4),
        );
        expect(
          _nodes(tester).where((node) => node.role == SemanticsRole.cell),
          hasLength(4),
        );
        expect(
          _nodes(tester).where((node) => node.label == 'Inspect'),
          isEmpty,
        );
        _action(
          tester,
          _label(tester, 'Expand row Alpha'),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect(
          _nodes(tester).where((node) => node.role == SemanticsRole.row),
          hasLength(3),
        );
        expect(
          _label(
            tester,
            'Inspect',
          ).getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        _action(
          tester,
          _label(tester, 'Select row Alpha'),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect(
          _nodes(tester).where((node) => node.role == SemanticsRole.row),
          hasLength(4),
        );
        expect(selected, <Object>{'a'});
      },
    );
  }

  testWidgets('full-cell focused sort in all themes and directions (#307)', (
    tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'data_table_sort_focus',
      containsText: true,
      size: const Size(520, 180),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => Center(
        child: SizedBox(
          width: 480,
          child: CarbonDataTable(
            columns: _columns,
            rows: _rows,
            sortColumnIndex: 0,
            sortDirection: CarbonSortDirection.ascending,
            onSort: (_) {},
          ),
        ),
      ),
      afterPump: (tester) async {
        Focus.of(tester.element(find.text('Name'))).requestFocus();
        await tester.pumpAndSettle();
      },
    );
  });
}

void _nothing() {}
