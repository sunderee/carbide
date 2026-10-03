// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

const _columns = <CarbonTableColumn>[
  CarbonTableColumn(title: 'Name', sortable: true),
  CarbonTableColumn(title: 'Value'),
];
const _names = <Object, String>{'a': 'Alpha', 'b': 'Beta', 'g': 'Gamma'};
void main() {
  testWidgets(
    'selection, expansion, cell state and focus follow IDs through sorting',
    (tester) async {
      final state = await _mount(tester);
      state.selected = <Object>{'a'};
      state.expanded = <Object>{'a'};
      state.refresh();
      await tester.pumpAndSettle();
      final counter = _counter(tester, 'a');
      counter.increment();
      await tester.pumpAndSettle();
      final focus = _focus(tester, 'Select row Alpha');
      focus.requestFocus();
      await tester.pumpAndSettle();
      state.replace(state.ids.reversed.toList());
      await tester.pumpAndSettle();
      expect(state.ids, <Object>['g', 'b', 'a']);
      expect(_row(tester, 'Select row Alpha').properties.checked, isTrue);
      expect(_row(tester, 'Select row Gamma').properties.checked, isFalse);
      expect(_detailHeight(tester, 'Alpha'), greaterThan(0));
      expect(_detailHeight(tester, 'Gamma'), 0);
      expect(_counter(tester, 'a'), same(counter));
      expect(counter.count, 1);
      expect(_focus(tester, 'Select row Alpha'), same(focus));
      expect(focus.hasPrimaryFocus, isTrue);
      expect(state.selections, isEmpty);
      expect(state.expansions, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(state.selected, isEmpty);
    },
  );

  testWidgets(
    'selection changes preserve selector focus and embedded cell state',
    (tester) async {
      final state = await _mount(tester);
      final counter = _counter(tester, 'a');
      counter.increment();
      final focus = _focus(tester, 'Select row Alpha');
      focus.requestFocus();
      await tester.pumpAndSettle();
      for (int i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(_focus(tester, 'Select row Alpha'), same(focus));
        expect(focus.hasPrimaryFocus, isTrue);
        expect(_counter(tester, 'a'), same(counter));
        expect(counter.count, 1);
        expect(state.selected, i.isEven ? <Object>{'a'} : <Object>{});
      }
    },
  );

  testWidgets(
    'RTL selection and expansion keep their focused record after reorder',
    (tester) async {
      final state = await _mount(tester);
      state.direction = TextDirection.rtl;
      state.refresh();
      await tester.pumpAndSettle();
      _focus(tester, 'Select row Beta').requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      state.replace(<Object>['g', 'b', 'a']);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Select row Beta').hasPrimaryFocus, isTrue);
      expect(state.selected, <Object>{'b'});
      _focus(tester, 'Expand row Gamma').requestFocus();
      await tester.pumpAndSettle();
      state.replace(<Object>['a', 'b', 'g']);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Expand row Gamma').hasPrimaryFocus, isTrue);
      expect(state.expanded, <Object>{'g'});
    },
  );
  for (final direction in TextDirection.values) {
    testWidgets('sorted ID selection, expansion and focus goldens $direction', (
      tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'data_table_identity_${direction.name}',
        containsText: true,
        size: const Size(760, 400),
        builder: (_) =>
            const Center(child: SizedBox(width: 700, child: _Fixture())),
        afterPump: (tester) async {
          final state = tester.state<_FixtureState>(find.byType(_Fixture));
          state.direction = direction;
          state.selected = <Object>{'a', 'absent'};
          state.expanded = <Object>{'a', 'absent'};
          state.replace(<Object>['g', 'b', 'a']);
          await tester.pumpAndSettle();
          _focus(tester, 'Expand row Alpha').requestFocus();
          await tester.pumpAndSettle();
        },
      );
    });
  }
  testWidgets(
    'filter/page out and back ignore absent IDs and restore their state',
    (tester) async {
      final state = await _mount(tester);
      state.selected = <Object>{'a', 'absent'};
      state.expanded = <Object>{'a', 'absent'};
      state.refresh();
      await tester.pumpAndSettle();
      expect(find.text('1 item selected'), findsOneWidget);
      state.replace(<Object>['b', 'g']);
      await tester.pumpAndSettle();
      expect(_row(tester, 'Select all rows').properties.checked, isFalse);
      expect(_row(tester, 'Select all rows').properties.mixed, isFalse);
      expect(find.text('0 items selected'), findsOneWidget);
      expect(state.selected, <Object>{'a', 'absent'});
      expect(state.expanded, <Object>{'a', 'absent'});
      state.replace(<Object>['g', 'a']);
      await tester.pumpAndSettle();
      expect(_row(tester, 'Select row Alpha').properties.checked, isTrue);
      expect(_detailHeight(tester, 'Alpha'), greaterThan(0));
      expect(find.text('1 item selected'), findsOneWidget);
      expect(state.selections, isEmpty);
      expect(state.expansions, isEmpty);
    },
  );

  for (final ids in <Set<Object>>[
    <Object>{'stale', 'other', 'third'},
    <Object>{'a', 'stale'},
    <Object>{'a', 'b', 'g', 'stale'},
  ]) {
    testWidgets('header and batch count use the present intersection: $ids', (
      tester,
    ) async {
      final state = await _mount(tester);
      state.selected = ids;
      state.refresh();
      await tester.pumpAndSettle();
      final present = ids.intersection(<Object>{'a', 'b', 'g'}).length;
      expect(
        _row(tester, 'Select all rows').properties.checked,
        present == 3
            ? true
            : present > 0
            ? null
            : false,
      );
      expect(
        _row(tester, 'Select all rows').properties.mixed,
        present > 0 && present < 3,
      );
      expect(
        find.text('$present item${present == 1 ? '' : 's'} selected'),
        findsOneWidget,
      );
    });
  }

  testWidgets('select-all toggles current IDs and retains absent selections', (
    tester,
  ) async {
    final state = await _mount(tester);
    final original = <Object>{'absent'};
    state.selected = original;
    state.refresh();
    await tester.pumpAndSettle();
    final action = _row(tester, 'Select all rows').properties.onTap!;
    action();
    await tester.pumpAndSettle();
    expect(state.selected, <Object>{'a', 'b', 'g', 'absent'});
    expect(original, <Object>{'absent'});
    action();
    await tester.pumpAndSettle();
    expect(state.selected, <Object>{'absent'});
    expect(state.selections.length, 2);
  });

  testWidgets('Cancel explicitly clears present and absent selected IDs', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.selected = <Object>{'a', 'absent'};
    state.refresh();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(state.selected, isEmpty);
    expect(state.selections, <Set<Object>>[<Object>{}]);
  });

  testWidgets(
    'single selection replaces absent selection and repeated activation stays selected',
    (tester) async {
      final state = await _mount(tester);
      state.mode = CarbonTableSelection.single;
      state.selected = <Object>{'absent'};
      state.refresh();
      await tester.pumpAndSettle();
      for (int i = 0; i < 2; i++) {
        _row(tester, 'Select row Beta').properties.onTap!();
        await tester.pumpAndSettle();
        expect(state.selected, <Object>{'b'});
      }
    },
  );

  testWidgets('insertion and deletion do not transfer selection or expansion', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.selected = <Object>{'b'};
    state.expanded = <Object>{'b'};
    state.refresh();
    await tester.pumpAndSettle();
    state.replace(<Object>['new', 'a', 'b', 'g']);
    await tester.pumpAndSettle();
    expect(_row(tester, 'Select row Beta').properties.checked, isTrue);
    expect(_row(tester, 'Select row Alpha').properties.checked, isFalse);
    expect(_row(tester, 'Select row new').properties.checked, isFalse);
    expect(_detailHeight(tester, 'Beta'), greaterThan(0));
    state.replace(<Object>['new', 'a', 'g']);
    await tester.pumpAndSettle();
    expect(state.selected, <Object>{'b'});
    expect(state.expanded, <Object>{'b'});
    expect(_row(tester, 'Select all rows').properties.checked, isFalse);
  });

  testWidgets(
    'controlled proposals can be rejected without changing data or caller sets',
    (tester) async {
      final state = await _mount(tester);
      state.accept = false;
      final selected = <Object>{'absent'}, expanded = <Object>{'absent'};
      state.selected = selected;
      state.expanded = expanded;
      state.refresh();
      await tester.pumpAndSettle();
      _row(tester, 'Select row Alpha').properties.onTap!();
      _row(tester, 'Expand row Alpha').properties.onTap!();
      await tester.pumpAndSettle();
      expect(state.selections, <Set<Object>>[
        <Object>{'a', 'absent'},
      ]);
      expect(state.expansions, <Set<Object>>[
        <Object>{'a', 'absent'},
      ]);
      expect(selected, <Object>{'absent'});
      expect(expanded, <Object>{'absent'});
      expect(_row(tester, 'Select row Alpha').properties.checked, isFalse);
      expect(_detailHeight(tester, 'Alpha'), 0);
    },
  );

  for (final policy in <String>[
    'removed',
    'disabled',
    'selection mode',
    'detail removed',
    'disposed',
  ]) {
    testWidgets(
      'retained row events resolve live identity and policy: $policy',
      (tester) async {
        final state = await _mount(tester);
        final select = _row(tester, 'Select row Alpha').properties.onTap!,
            expand = _row(tester, 'Expand row Alpha').properties.onTap!;
        switch (policy) {
          case 'removed':
            state.replace(<Object>['b', 'g']);
          case 'disabled':
            state.enabled = false;
            state.refresh();
          case 'selection mode':
            state.mode = CarbonTableSelection.none;
            state.expandable = false;
            state.refresh();
          case 'detail removed':
            state.details = false;
            state.refresh();
          case 'disposed':
            await tester.pumpWidget(const SizedBox.shrink());
        }
        await tester.pumpAndSettle();
        select();
        expand();
        await tester.pumpAndSettle();
        expect(state.expansions, isEmpty);
        expect(
          state.selections,
          policy == 'detail removed'
              ? <Set<Object>>[
                  <Object>{'a'},
                ]
              : isEmpty,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'retained row event after reorder targets its current index/record',
    (tester) async {
      final state = await _mount(tester);
      final action = _row(tester, 'Select row Alpha').properties.onTap!;
      state.replace(<Object>['g', 'b', 'a']);
      await tester.pumpAndSettle();
      action();
      await tester.pumpAndSettle();
      expect(state.selected, <Object>{'a'});
    },
  );

  testWidgets(
    'renamed label updates accessible controls without changing identity',
    (tester) async {
      final state = await _mount(tester);
      final counter = _counter(tester, 'a');
      state.renamed = true;
      state.refresh();
      await tester.pumpAndSettle();
      expect(
        _row(tester, 'Select row Renamed Alpha').properties.checked,
        isFalse,
      );
      expect(_counter(tester, 'a'), same(counter));
    },
  );

  testWidgets(
    'expander focus and its semantics follow the record across reorder',
    (tester) async {
      final state = await _mount(tester);
      final focus = _focus(tester, 'Expand row Beta');
      focus.requestFocus();
      await tester.pumpAndSettle();
      state.replace(<Object>['g', 'a', 'b']);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Expand row Beta'), same(focus));
      expect(focus.hasPrimaryFocus, isTrue);
      expect(_row(tester, 'Expand row Beta').properties.focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(state.expanded, <Object>{'b'});
      expect(_row(tester, 'Expand row Beta').properties.expanded, isTrue);
    },
  );
  testWidgets(
    'disabled selection/expansion rejects keyboard and stored focus actions',
    (tester) async {
      final state = await _mount(tester);
      state.selected = <Object>{'a'};
      state.refresh();
      await tester.pumpAndSettle();
      final focus = _focus(tester, 'Expand row Alpha');
      final action = _row(tester, 'Expand row Alpha').properties.onFocus!;
      focus.requestFocus();
      await tester.pumpAndSettle();
      state.enabled = false;
      state.refresh();
      await tester.pumpAndSettle();
      action();
      await tester.pumpAndSettle();
      expect(focus.hasPrimaryFocus, isFalse);
      expect(_row(tester, 'Expand row Alpha').properties.enabled, isFalse);
      expect(_row(tester, 'Expand row Alpha').properties.onFocus, isNull);
      expect(
        tester
            .widget<CarbonButton>(
              find.byWidgetPredicate(
                (w) => w is CarbonButton && w.label == 'Cancel',
              ),
            )
            .onPressed,
        isNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(state.expansions, isEmpty);
      expect(state.selections, isEmpty);
    },
  );
  testWidgets(
    'removed expander focus resource is disposed and saved focus action is inert',
    (tester) async {
      final state = await _mount(tester);
      final focus = _focus(tester, 'Expand row Alpha');
      final action = _row(tester, 'Expand row Alpha').properties.onFocus!;
      state.replace(<Object>['b']);
      await tester.pumpAndSettle();
      action();
      await tester.pumpAndSettle();
      expect(() => focus.addListener(() {}), throwsFlutterError);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('empty table ignores stale IDs and disables select-all', (
    tester,
  ) async {
    final state = await _mount(tester);
    final action = _row(tester, 'Select all rows').properties.onTap!;
    state.selected = <Object>{'a', 'b'};
    state.replace(<Object>[]);
    await tester.pumpAndSettle();
    expect(_row(tester, 'Select all rows').properties.checked, isFalse);
    expect(_row(tester, 'Select all rows').properties.mixed, isFalse);
    expect(_row(tester, 'Select all rows').properties.enabled, isFalse);
    action();
    await tester.pumpAndSettle();
    expect(state.selections, isEmpty);
    expect(state.selected, <Object>{'a', 'b'});
  });
  for (final empty in <bool>[false, true]) {
    testWidgets(
      'stored all/cancel events use current callback policy, empty=$empty',
      (tester) async {
        final state = await _mount(tester);
        state.selected = <Object>{'a'};
        state.refresh();
        await tester.pumpAndSettle();
        final all = _row(tester, 'Select all rows').properties.onTap!,
            cancel = tester
                .widget<CarbonButton>(
                  find.byWidgetPredicate(
                    (w) => w is CarbonButton && w.label == 'Cancel',
                  ),
                )
                .onPressed!;
        if (empty) {
          state.replace(<Object>[]);
        } else {
          state.enabled = false;
          state.refresh();
        }
        await tester.pumpAndSettle();
        all();
        cancel();
        await tester.pumpAndSettle();
        expect(state.selections, isEmpty);
      },
    );
  }
  testWidgets(
    'sticky table preserves scroll position across reorder and controlled updates',
    (tester) async {
      final state = await _mount(tester);
      state.sticky = true;
      state.replace(<Object>[for (int i = 0; i < 30; i++) i]);
      await tester.pumpAndSettle();
      final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
      scroll.position.jumpTo(400);
      await tester.pumpAndSettle();
      state.selected = <Object>{0};
      state.expanded = <Object>{29};
      state.replace(state.ids.reversed.toList());
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)),
        same(scroll),
      );
      expect(scroll.position.pixels, 400);
      expect(state.selected, <Object>{0});
      expect(state.expanded, <Object>{29});
    },
  );
  testWidgets(
    'legacy out-of-range indices do not mark the header or batch count selected',
    (tester) async {
      Set<int>? proposal;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CarbonTheme(
            data: CarbonThemeData.white,
            child: CarbonDataTable(
              columns: _columns,
              rows: const <CarbonTableRow>[
                CarbonTableRow(cells: <Widget>[Text('A'), Text('B')]),
              ],
              selection: CarbonTableSelection.multi,
              selectedRows: const <int>{8},
              onSelectionChanged: (value) => proposal = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_row(tester, 'Select all rows').properties.checked, isFalse);
      expect(find.text('0 items selected'), findsOneWidget);
      _row(tester, 'Select all rows').properties.onTap!();
      expect(proposal, <int>{0, 8});
    },
  );
  testWidgets('explicit numeric IDs and index fallback keys cannot collide', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: const CarbonDataTable(
            columns: _columns,
            rows: <CarbonTableRow>[
              CarbonTableRow(id: 1, cells: <Widget>[Text('A'), Text('B')]),
              CarbonTableRow(cells: <Widget>[Text('C'), Text('D')]),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('ID APIs reject missing IDs before allocating child resources', () {
    const table = CarbonDataTable(
      columns: _columns,
      rows: <CarbonTableRow>[
        CarbonTableRow(cells: <Widget>[Text('A'), Text('B')]),
      ],
      selectedRowIds: <Object>{},
    );
    expect(table.createElement, throwsAssertionError);
  });
  test('duplicate IDs are rejected even without selection', () {
    const table = CarbonDataTable(
      columns: _columns,
      rows: <CarbonTableRow>[
        CarbonTableRow(id: 'same', cells: <Widget>[]),
        CarbonTableRow(id: 'same', cells: <Widget>[]),
      ],
    );
    expect(table.createElement, throwsAssertionError);
  });
  test('const ID-based table construction is preserved', () {
    const table = CarbonDataTable(
      columns: _columns,
      rows: <CarbonTableRow>[
        CarbonTableRow(id: 'a', cells: <Widget>[Text('A'), Text('B')]),
      ],
      selectedRowIds: <Object>{'a'},
      expandedRowIds: <Object>{},
    );
    expect(table.selectedRowIds, <Object>{'a'});
  });
  for (final callback in <bool>[false, true]) {
    test('mixed selection APIs assert, callback=$callback', () {
      expect(
        () => CarbonDataTable(
          columns: _columns,
          rows: const <CarbonTableRow>[],
          selectedRows: callback ? null : <int>{},
          onSelectionChanged: callback ? (_) {} : null,
          selectedRowIds: const <Object>{},
        ),
        throwsAssertionError,
      );
    });
    test('mixed expansion APIs assert, callback=$callback', () {
      expect(
        () => CarbonDataTable(
          columns: _columns,
          rows: const <CarbonTableRow>[],
          expandedRows: callback ? null : <int>{},
          onExpandedChanged: callback ? (_) {} : null,
          expandedRowIds: const <Object>{},
        ),
        throwsAssertionError,
      );
    });
  }
}

Future<_FixtureState> _mount(WidgetTester tester) async {
  final key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (_, _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(width: 700, child: _Fixture(key: key)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

class _Fixture extends StatefulWidget {
  const _Fixture({super.key});
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  List<Object> ids = <Object>['a', 'b', 'g'];
  Set<Object> selected = <Object>{}, expanded = <Object>{};
  final selections = <Set<Object>>[], expansions = <Set<Object>>[];
  bool accept = true,
      enabled = true,
      expandable = true,
      details = true,
      renamed = false;
  bool sticky = false;
  TextDirection direction = TextDirection.ltr;
  CarbonTableSelection mode = CarbonTableSelection.multi;
  void refresh() => setState(() {});
  void replace(List<Object> value) => setState(() => ids = value);
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: direction,
    child: CarbonDataTable(
      columns: _columns,
      stickyHeader: sticky,
      stickyHeaderHeight: 160,
      selection: mode,
      selectedRowIds: selected,
      expandedRowIds: expanded,
      expandable: expandable,
      onSort: (_) => replace(ids.reversed.toList()),
      onSelectedRowIdsChanged: enabled
          ? (value) {
              selections.add(value);
              if (accept) setState(() => selected = value);
            }
          : null,
      onExpansionChanged: enabled
          ? (value) {
              expansions.add(value);
              if (accept) setState(() => expanded = value);
            }
          : null,
      rows: <CarbonTableRow>[
        for (final id in ids)
          CarbonTableRow(
            id: id,
            label: id == 'a' && renamed
                ? 'Renamed Alpha'
                : _names[id] ?? id.toString(),
            cells: <Widget>[
              Text(_names[id] ?? id.toString()),
              _Counter(id: id),
            ],
            expandedContent: details
                ? Text('Details ${_names[id] ?? id}')
                : null,
          ),
      ],
    ),
  );
}

class _Counter extends StatefulWidget {
  const _Counter({required this.id});
  final Object id;
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;
  void increment() => setState(() => count++);
  @override
  Widget build(BuildContext context) => Text('$count');
}

_CounterState _counter(WidgetTester tester, Object id) =>
    tester.state<_CounterState>(
      find.byWidgetPredicate((w) => w is _Counter && w.id == id),
    );
Semantics _row(WidgetTester tester, String label) => tester
    .widgetList<Semantics>(find.byType(Semantics, skipOffstage: false))
    .firstWhere((w) => w.properties.label == label);
FocusNode _focus(WidgetTester tester, String label) => Focus.of(
  tester.element(
    find
        .descendant(
          of: find.byWidget(_row(tester, label)),
          matching: find.byWidgetPredicate(
            (w) => w is CarbonFocusRing || w is CustomPaint,
          ),
        )
        .first,
  ),
);
double _detailHeight(WidgetTester tester, String name) => tester
    .getSize(
      find
          .ancestor(
            of: find.text('Details $name'),
            matching: find.byType(ClipRect),
          )
          .first,
    )
    .height;
