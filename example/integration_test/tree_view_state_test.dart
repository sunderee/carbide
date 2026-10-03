// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  _test('native row focus and keyboard survive removal and replacement', (
    tester,
  ) async {
    final state = await _mount(tester);
    _row('Child').focus();
    await _settle(tester);
    expect(_activeName, 'Child');
    expect(state.selections, isEmpty);
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(
        id: 'folder',
        label: 'Folder',
        children: <CarbonTreeNode>[
          CarbonTreeNode(id: 'branch', label: 'Branch'),
          CarbonTreeNode(id: 'sibling', label: 'Sibling'),
        ],
      ),
      CarbonTreeNode(id: 'root', label: 'Root'),
    ]);
    await _settle(tester);
    expect(_activeName, 'Branch');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await _settle(tester);
    expect(_activeName, 'Sibling');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(state.selections, <Object>['sibling']);
  });

  _test(
    'native controlled collapse returns focus to parent without selection',
    (tester) async {
      final state = await _mount(tester);
      _row('Child').focus();
      await _settle(tester);
      state.expansion(<Object>{});
      await _settle(tester);
      expect(_activeName, 'Folder');
      expect(_row('Folder').getAttribute('aria-expanded'), 'false');
      expect(find.text('Child'), findsNothing);
      expect(state.selections, isEmpty);
      expect(state.proposals, isEmpty);
    },
  );

  _test('native controlled toggles respect rejection and acceptance', (
    tester,
  ) async {
    final state = await _mount(tester);
    state.expansion(<Object>{});
    await _settle(tester);
    _row('Folder').focus();
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(_row('Folder').getAttribute('aria-expanded'), 'false');
    expect(state.proposals, <Set<Object>>[
      <Object>{'folder'},
    ]);
    state.accept = true;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(_row('Folder').getAttribute('aria-expanded'), 'true');
    expect(_activeName, 'Folder');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester);
    expect(_activeName, 'Branch');
    expect(state.selections, isEmpty);
  });

  _test('native navigation skips disabled rows and disabled ancestors', (
    tester,
  ) async {
    final state = await _mount(tester);
    _row('Child').focus();
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await _settle(tester);
    expect(_activeName, 'Sibling');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await _settle(tester);
    expect(_activeName, 'Child');
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(
        id: 'folder',
        label: 'Folder',
        children: <CarbonTreeNode>[
          CarbonTreeNode(
            id: 'branch',
            label: 'Branch',
            disabled: true,
            children: <CarbonTreeNode>[
              CarbonTreeNode(id: 'child', label: 'Child'),
            ],
          ),
        ],
      ),
    ]);
    await _settle(tester);
    expect(_activeName, 'Child');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester);
    expect(_activeName, 'Folder');
  });

  _test('native disabled active row recovers to enabled grandparent', (
    tester,
  ) async {
    final state = await _mount(tester);
    _row('Child').focus();
    await _settle(tester);
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(
        id: 'folder',
        label: 'Folder',
        children: <CarbonTreeNode>[
          CarbonTreeNode(
            id: 'branch',
            label: 'Branch',
            disabled: true,
            children: <CarbonTreeNode>[
              CarbonTreeNode(id: 'child', label: 'Child', disabled: true),
            ],
          ),
        ],
      ),
    ]);
    await _settle(tester);
    expect(_activeName, 'Folder');
    expect(state.selections, isEmpty);
  });

  _test('native unrelated replacement focuses first enabled row', (
    tester,
  ) async {
    final state = await _mount(tester);
    _row('Child').focus();
    await _settle(tester);
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'disabled', label: 'Disabled', disabled: true),
      CarbonTreeNode(id: 'new', label: 'New'),
    ]);
    await _settle(tester);
    expect(_activeName, 'New');
    expect(state.selections, isEmpty);
  });

  _test('native outside focus is preserved during tree refresh', (
    tester,
  ) async {
    final state = await _mount(tester);
    await tester.tap(find.byType(EditableText));
    await _settle(tester);
    expect(state.outside.hasPrimaryFocus, isTrue);
    expect(_activeName, 'Outside');
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'new', label: 'New'),
    ]);
    await _settle(tester);
    expect(_activeName, 'Outside');
  });

  _test('native focus survives rename and controlled/local handoffs', (
    tester,
  ) async {
    final state = await _mount(tester);
    _row('Root').focus();
    await _settle(tester);
    state.expansion(null);
    await _settle(tester);
    expect(_activeName, 'Root');
    expect(find.text('Child'), findsOneWidget);
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'root', label: 'Renamed'),
    ]);
    await _settle(tester);
    expect(_activeName, 'Renamed');
    state.expansion(<Object>{});
    await _settle(tester);
    expect(_activeName, 'Renamed');
    expect(state.proposals, isEmpty);
  });

  _test('refreshing one native tree does not steal focus from another', (
    tester,
  ) async {
    final state = await _mount(tester, second: true);
    _row('Other root').focus();
    await _settle(tester);
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'new', label: 'New'),
    ]);
    await _settle(tester);
    expect(_activeName, 'Other root');
  });

  _test('retained native actions reject removed and disposed rows', (
    tester,
  ) async {
    final state = await _mount(tester);
    final semantics = tester
        .widgetList<Semantics>(
          find.ancestor(
            of: find.text('Child'),
            matching: find.byType(Semantics),
          ),
        )
        .firstWhere((s) => s.properties.label == 'Child');
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'new', label: 'New'),
    ]);
    await _settle(tester);
    semantics.properties.onTap!();
    semantics.properties.onFocus!();
    await _settle(tester);
    expect(state.selections, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    semantics.properties.onTap!();
    semantics.properties.onFocus!();
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
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Future<_FixtureState> _mount(WidgetTester tester, {bool second = false}) async {
  final key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (_, _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: 400,
            child: _Fixture(key: key, second: second),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  // Activate the Flutter view before driving native accessibility focus.
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

const _initial = <CarbonTreeNode>[
  CarbonTreeNode(
    id: 'folder',
    label: 'Folder',
    children: <CarbonTreeNode>[
      CarbonTreeNode(
        id: 'branch',
        label: 'Branch',
        children: <CarbonTreeNode>[CarbonTreeNode(id: 'child', label: 'Child')],
      ),
      CarbonTreeNode(id: 'disabled', label: 'Disabled', disabled: true),
      CarbonTreeNode(id: 'sibling', label: 'Sibling'),
    ],
  ),
  CarbonTreeNode(id: 'root', label: 'Root'),
];

class _Fixture extends StatefulWidget {
  const _Fixture({super.key, this.second = false});
  final bool second;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  List<CarbonTreeNode> nodes = _initial;
  Set<Object>? expanded = <Object>{'folder', 'branch'};
  final proposals = <Set<Object>>[], selections = <Object>[];
  final outside = FocusNode();
  Object? selected;
  bool accept = false;
  void replace(List<CarbonTreeNode> next) => setState(() => nodes = next);
  void expansion(Set<Object>? next) => setState(() => expanded = next);
  @override
  void dispose() {
    outside.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      CarbonTreeView(
        label: 'Files',
        nodes: nodes,
        expandedIds: expanded,
        selectedId: selected,
        onSelect: (id) => setState(() {
          selected = id;
          selections.add(id);
        }),
        onExpansionChanged: (ids) {
          proposals.add(ids);
          if (accept) setState(() => expanded = ids);
        },
      ),
      if (widget.second)
        const CarbonTreeView(
          label: 'Other files',
          nodes: <CarbonTreeNode>[
            CarbonTreeNode(id: 'other', label: 'Other root'),
          ],
        ),
      CarbonTextInput(labelText: 'Outside', focusNode: outside),
    ],
  );
}

_Element _row(String name) {
  final nodes = _document.querySelectorAll(
    'flt-semantics[role="button"], flt-semantics input',
  );
  for (int i = 0; i < nodes.length; i++) {
    final node = nodes.item(i)!;
    if (node.textContent?.trim() == name ||
        node.getAttribute('aria-label') == name) {
      return node;
    }
  }
  throw StateError('Missing native row $name');
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
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external String? getAttribute(String name);
  external void focus();
}
