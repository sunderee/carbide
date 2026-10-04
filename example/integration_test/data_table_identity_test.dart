// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';

const _columns = <CarbonTableColumn>[
  CarbonTableColumn(title: 'Name', sortable: true),
  CarbonTableColumn(title: 'Value'),
];
const _names = <Object, String>{'a': 'Alpha', 'b': 'Beta', 'g': 'Gamma'};
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  retainIntegrationFailureDetails(binding);
  _test(
    'native selection, expansion, focus and cell state follow sorted records',
    (tester) async {
      final state = await _mount(tester);
      final counter = _counter(tester, 'a');
      counter.increment();
      _node('button', 'Expand row Alpha').click();
      await _settle(tester);
      _node('checkbox', 'Select row Alpha').focus();
      await _settle(tester);
      _node('checkbox', 'Select row Alpha').click();
      await _settle(tester);
      final id = _node('checkbox', 'Select row Alpha').getAttribute('id');
      expect(_activeName, 'Select row Alpha');
      expect(state.selected, <Object>{'a'});
      expect(state.expanded, <Object>{'a'});
      state.replace(<Object>['g', 'b', 'a']);
      await _settle(tester);
      expect(_activeName, 'Select row Alpha');
      expect(_node('checkbox', 'Select row Alpha').getAttribute('id'), id);
      expect(
        _node('checkbox', 'Select row Alpha').getAttribute('aria-checked'),
        'true',
      );
      expect(
        _node('button', 'Expand row Alpha').getAttribute('aria-expanded'),
        'true',
      );
      expect(_counter(tester, 'a'), same(counter));
      expect(counter.count, 1);
      expect(state.selections.length, 1);
      expect(state.expansions.length, 1);
      await tester.sendKeyEvent(
        LogicalKeyboardKey.space,
        physicalKey: PhysicalKeyboardKey.space,
      );
      await _settle(tester);
      expect(state.selected, isEmpty);
      expect(_activeName, 'Select row Alpha');
    },
  );
  _test('native expander focus and Enter follow current identity', (
    tester,
  ) async {
    final state = await _mount(tester);
    _node('button', 'Expand row Beta').focus();
    await _settle(tester);
    state.replace(<Object>['g', 'a', 'b']);
    await _settle(tester);
    expect(_activeName, 'Expand row Beta');
    await tester.sendKeyEvent(
      LogicalKeyboardKey.enter,
      physicalKey: PhysicalKeyboardKey.enter,
    );
    await _settle(tester);
    expect(state.expanded, <Object>{'b'});
    expect(
      _node('button', 'Expand row Beta').getAttribute('aria-expanded'),
      'true',
    );
  });
  _test('native selection toggles retain control focus and cell state', (
    tester,
  ) async {
    final state = await _mount(tester);
    final counter = _counter(tester, 'a');
    counter.increment();
    _node('checkbox', 'Select row Alpha').focus();
    await _settle(tester);
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(
        LogicalKeyboardKey.space,
        physicalKey: PhysicalKeyboardKey.space,
      );
      await _settle(tester);
      expect(_activeName, 'Select row Alpha');
      expect(_counter(tester, 'a'), same(counter));
      expect(counter.count, 1);
      expect(state.selected, i.isEven ? <Object>{'a'} : <Object>{});
    }
  });
  _test(
    'native filtering and paging ignore absent IDs and restore returned records',
    (tester) async {
      final state = await _mount(tester);
      state.selected = <Object>{'a', 'absent'};
      state.expanded = <Object>{'a', 'absent'};
      state.refresh();
      await _settle(tester);
      state.replace(<Object>['b', 'g']);
      await _settle(tester);
      expect(
        _node('checkbox', 'Select all rows').getAttribute('aria-checked'),
        'false',
      );
      state.replace(<Object>['other']);
      await _settle(tester);
      expect(state.selected, <Object>{'a', 'absent'});
      state.replace(<Object>['g', 'a']);
      await _settle(tester);
      expect(
        _node('checkbox', 'Select row Alpha').getAttribute('aria-checked'),
        'true',
      );
      expect(
        _node('button', 'Expand row Alpha').getAttribute('aria-expanded'),
        'true',
      );
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
    _test('native header and count intersect current records: $ids', (
      tester,
    ) async {
      final state = await _mount(tester);
      state.selected = ids;
      state.refresh();
      await _settle(tester);
      final count = ids.intersection(<Object>{'a', 'b', 'g'}).length;
      expect(
        _node('checkbox', 'Select all rows').getAttribute('aria-checked'),
        count == 3 ? 'true' : 'false',
      );
      expect(
        find.text('$count item${count == 1 ? '' : 's'} selected'),
        findsOneWidget,
      );
    });
  }
  _test('native select-all retains absent IDs and Cancel clears the full set', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.selected = <Object>{'absent'};
    state.refresh();
    await _settle(tester);
    _node('checkbox', 'Select all rows').click();
    await _settle(tester);
    expect(state.selected, <Object>{'a', 'b', 'g', 'absent'});
    expect(find.text('3 items selected'), findsOneWidget);
    _node('button', 'Cancel').click();
    await _settle(tester);
    expect(state.selected, isEmpty);
  });
  _test('native disabled policy gates expander, selectors and Cancel', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.selected = <Object>{'a'};
    state.refresh();
    await _settle(tester);
    _node('button', 'Expand row Alpha').focus();
    await _settle(tester);
    state.enabled = false;
    state.refresh();
    await _settle(tester);
    expect(
      _node('button', 'Expand row Alpha').getAttribute('aria-disabled'),
      'true',
    );
    expect(
      _node('checkbox', 'Select row Alpha').getAttribute('aria-disabled'),
      'true',
    );
    expect(_node('button', 'Cancel').getAttribute('aria-disabled'), 'true');
    expect(_focus(tester, 'Expand row Alpha').hasPrimaryFocus, isFalse);
    await tester.sendKeyEvent(
      LogicalKeyboardKey.enter,
      physicalKey: PhysicalKeyboardKey.enter,
    );
    await _settle(tester);
    expect(state.selections, isEmpty);
    expect(state.expansions, isEmpty);
  });
  _test(
    'native controlled rejection does not change checked or expanded state',
    (tester) async {
      final state = await _mount(tester);
      state.accept = false;
      state.refresh();
      await _settle(tester);
      _node('checkbox', 'Select row Alpha').click();
      _node('button', 'Expand row Alpha').click();
      await _settle(tester);
      expect(
        _node('checkbox', 'Select row Alpha').getAttribute('aria-checked'),
        'false',
      );
      expect(
        _node('button', 'Expand row Alpha').getAttribute('aria-expanded'),
        'false',
      );
      expect(state.selections, <Set<Object>>[
        <Object>{'a'},
      ]);
      expect(state.expansions, <Set<Object>>[
        <Object>{'a'},
      ]);
    },
  );
  _test('native single-select radio state follows records', (tester) async {
    final state = await _mount(tester);
    state.mode = CarbonTableSelection.single;
    state.refresh();
    await _settle(tester);
    _node('radio', 'Select row Beta').focus();
    await _settle(tester);
    await tester.sendKeyEvent(
      LogicalKeyboardKey.space,
      physicalKey: PhysicalKeyboardKey.space,
    );
    await _settle(tester);
    state.replace(<Object>['g', 'a', 'b']);
    await _settle(tester);
    expect(_activeName, 'Select row Beta');
    expect(
      _node('radio', 'Select row Beta').getAttribute('aria-checked'),
      'true',
    );
    expect(state.selected, <Object>{'b'});
  });
  _test('native empty data disables select-all and ignores stale counts', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.selected = <Object>{'a'};
    state.replace(<Object>[]);
    await _settle(tester);
    expect(
      _node('checkbox', 'Select all rows').getAttribute('aria-disabled'),
      'true',
    );
    expect(
      _node('checkbox', 'Select all rows').getAttribute('aria-checked'),
      'false',
    );
    expect(state.selected, <Object>{'a'});
    expect(state.selections, isEmpty);
  });
  for (final direction in TextDirection.values) {
    _test(
      'native $direction selection and expansion retain focus across DOM moves',
      (tester) async {
        final state = await _mount(tester);
        state.direction = direction;
        state.refresh();
        await _settle(tester);
        _node('checkbox', 'Select row Beta').focus();
        await _settle(tester);
        _node('checkbox', 'Select row Beta').click();
        await _settle(tester);
        expect(_activeName, 'Select row Beta');
        expect(_focus(tester, 'Select row Beta').hasPrimaryFocus, isTrue);
        state.replace(<Object>['g', 'b', 'a']);
        await _settle(tester);
        expect(_activeName, 'Select row Beta');
        expect(_focus(tester, 'Select row Beta').hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(
          LogicalKeyboardKey.space,
          physicalKey: PhysicalKeyboardKey.space,
        );
        await _settle(tester);
        expect(state.selected, isEmpty);
        _node('button', 'Expand row Gamma').focus();
        await _settle(tester);
        state.replace(<Object>['a', 'b', 'g']);
        await _settle(tester);
        expect(_activeName, 'Expand row Gamma');
        expect(_focus(tester, 'Expand row Gamma').hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(
          LogicalKeyboardKey.enter,
          physicalKey: PhysicalKeyboardKey.enter,
        );
        await _settle(tester);
        expect(state.expanded, <Object>{'g'});
      },
    );
  }
  _test('native table refresh preserves outside input focus', (tester) async {
    final state = await _mount(tester);
    state.direction = TextDirection.rtl;
    state.refresh();
    await _settle(tester);
    _node('checkbox', 'Select row Beta').focus();
    await _settle(tester);
    state.replace(<Object>['g', 'b', 'a']);
    await _settle(tester);
    // Move focus outside, then refresh the table without taking it back.
    await tester.tap(find.byType(EditableText));
    await _settle(tester);
    expect(_activeName, 'Outside');
    expect(state.outside.hasPrimaryFocus, isTrue);
    state.replace(<Object>['b', 'a', 'g']);
    await _settle(tester);
    expect(_activeName, 'Outside');
    expect(state.outside.hasPrimaryFocus, isTrue);
  });
  _test('native focus reconciliation preserves sticky-body scroll offset', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.sticky = true;
    state.direction = TextDirection.rtl;
    state.replace(<Object>[for (int i = 0; i < 30; i++) i]);
    await _settle(tester);
    await tester.drag(_tableScroll, const Offset(0, -500));
    await _settle(tester);
    final position = tester.state<ScrollableState>(_tableScroll).position;
    final selector = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .firstWhere((w) {
          final label = w.properties.label;
          if (label == null || !label.startsWith('Select row ')) return false;
          final rect = tester.getRect(find.byWidget(w));
          final viewport = tester.getRect(_tableScroll);
          return rect.top >= viewport.top && rect.bottom <= viewport.bottom;
        });
    final label = selector.properties.label!;
    _node('checkbox', label).focus();
    await _settle(tester);
    final offset = position.pixels;
    state.refresh();
    await _settle(tester);
    expect(_activeName, label);
    expect(position.pixels, offset);
  });
  _test('native retained callbacks are inert after removal or disposal', (
    tester,
  ) async {
    final state = await _mount(tester);
    final select = _row(tester, 'Select row Alpha').properties.onTap!,
        expand = _row(tester, 'Expand row Alpha').properties.onTap!,
        focus = _row(tester, 'Expand row Alpha').properties.onFocus!;
    state.replace(<Object>['b']);
    await _settle(tester);
    select();
    expand();
    focus();
    await _settle(tester);
    expect(state.selections, isEmpty);
    expect(state.expansions, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    select();
    expand();
    focus();
    await _settle(tester);
    expect(tester.takeException(), isNull);
  });
}

void _test(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    });
Finder get _tableScroll => find.descendant(
  of: find.byType(CarbonDataTable),
  matching: find.byType(Scrollable),
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

_Element _node(String role, String name) {
  final nodes = _document.querySelectorAll('flt-semantics[role="$role"]');
  for (int i = 0; i < nodes.length; i++) {
    final node = nodes.item(i)!;
    final label = node.getAttribute('aria-label') ?? node.textContent?.trim();
    if (label == name || label?.startsWith('$name ') == true) return node;
  }
  throw StateError('Missing $role $name');
}

String? get _activeName =>
    _document.activeElement?.getAttribute('aria-label') ??
    _document.activeElement?.textContent?.trim();
@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
  external _Element? get activeElement;
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int i);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external String? getAttribute(String name);
  external void focus();
  external void click();
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
  _document.querySelectorAll('flutter-view').item(0)!.focus();
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  await _settle(tester);
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
  final FocusNode outside = FocusNode(debugLabel: 'table-outside');
  @override
  void dispose() {
    outside.dispose();
    super.dispose();
  }

  CarbonTableSelection mode = CarbonTableSelection.multi;
  void refresh() => setState(() {});
  void replace(List<Object> value) => setState(() => ids = value);
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: direction,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CarbonDataTable(
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
        CarbonTextInput(labelText: 'Outside', focusNode: outside),
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
