// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';
import 'support/table_accessibility_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  retainIntegrationFailureDetails(binding);
  for (final direction in TextDirection.values) {
    for (final sticky in <bool>[false, true]) {
      testWidgets(
        'native table structure, sort and keyed focus $direction sticky=$sticky (#307)',
        (tester) async {
          final semantics = tester.ensureSemantics();
          final key = GlobalKey<TableAccessibilityFixtureState>();
          try {
            await tester.pumpWidget(
              tableAccessibilityHost(
                TableAccessibilityFixture(key: key, sticky: sticky),
                direction: direction,
              ),
            );
            await _settle(tester);
            final state = key.currentState!;
            final table = _named('table', 'Scheduled jobs');
            expect(table.querySelectorAll('[role="columnheader"]').length, 4);
            expect(
              _named(
                'columnheader',
                'Status',
              ).querySelectorAll('[role="button"]').length,
              1,
              reason: 'only the independent AI button',
            );
            expect(_name(_named('button', 'Name')), contains('Not sorted'));
            expect(_rowValues(table).take(3), <String>[
              'Alpha',
              'Beta',
              'Charlie',
            ]);
            final header = _named('button', 'Name');
            final parents = _parents(header);
            header.focus();
            await _settle(tester);
            await _key(tester, 'Enter');
            expect(state.sorts, 1);
            expect(
              _name(_named('button', 'Name')),
              contains('Sorted ascending'),
            );
            await _key(tester, ' ');
            expect(state.sorts, 2);
            expect(
              _name(_named('button', 'Name')),
              contains('Sorted descending'),
            );
            expect(_parents(_named('button', 'Name')), parents);
            expect(_document.activeElement, same(header));
            if (!sticky) {
              expect(_rowValues(table), <String>['Charlie', 'Beta', 'Alpha']);
            }
            await _key(tester, 'F4');
            expect(_named('table', 'Travaux planifiés'), same(table));
            expect(
              _name(_named('button', 'Name')),
              contains('Tri décroissant'),
            );
            await _key(tester, 'Enter');
            expect(state.sorts, 3);
            expect(_name(_named('button', 'Name')), contains('Sans tri'));
            final rect = tester.getRect(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label == 'Name' &&
                    widget.properties.button == true,
              ),
            );
            await tester.tapAt(Offset(rect.center.dx, rect.bottom - 1));
            await _settle(tester);
            expect(state.sorts, 4);
            final selector = _named('checkbox', 'Select row Alpha');
            selector.focus();
            await _settle(tester);
            selector.click();
            await _settle(tester);
            expect(state.selected, <Object>{'Alpha'});
            final selectorParents = _parents(selector);
            expect(_document.activeElement, same(selector));
            await _key(tester, 'F2');
            expect(_named('checkbox', 'Select row Alpha'), same(selector));
            expect(_parents(selector), selectorParents);
            expect(_document.activeElement, same(selector));
            expect(selector.getAttribute('aria-checked'), 'true');
            await _key(tester, 'F7');
            expect(state.selected, isEmpty);
            expect(_parents(selector), selectorParents);
            expect(_document.activeElement, same(selector));
            if (!sticky) {
              expect(_rowValues(table), <String>['Charlie', 'Beta', 'Alpha']);
            }
            state.handOff = true;
            state.refresh();
            await _settle(tester);
            _named('button', 'Name').click();
            await _settle(tester);
            expect(state.after.hasPrimaryFocus, isTrue);
            expect(
              _document.activeElement,
              same(_named('button', 'After table')),
            );
            final calls = state.sorts;
            state.enabled = false;
            state.refresh();
            await _settle(tester);
            expect(
              _named('button', 'Name').getAttribute('aria-disabled'),
              'true',
            );
            _named('button', 'Name').click();
            await _settle(tester);
            expect(state.sorts, calls);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            semantics.dispose();
          }
        },
      );
    }
  }
}

String _name(_Element node) =>
    node.getAttribute('aria-label') ?? node.textContent?.trim() ?? '';

List<String> _rowValues(_Element table) {
  final result = <String>[];
  final rows = table.querySelectorAll('[role="row"]');
  for (int i = 0; i < rows.length; i++) {
    final cells = rows.item(i)!.querySelectorAll('[role="cell"]');
    if (cells.length != 4) continue;
    final cell = cells.item(2)!;
    final labels = cell.querySelectorAll('[aria-label]');
    result.add(
      labels.length == 0
          ? cell.textContent?.trim() ?? ''
          : labels.item(0)!.getAttribute('aria-label')!,
    );
  }
  return result;
}

_Element _named(String role, String name) {
  final nodes = _document.querySelectorAll('flt-semantics[role="$role"]');
  for (int i = 0; i < nodes.length; i++) {
    final node = nodes.item(i)!;
    final label = node.getAttribute('aria-label') ?? node.textContent?.trim();
    if (label == name ||
        label?.startsWith('$name,') == true ||
        label?.startsWith('$name ') == true) {
      return node;
    }
  }
  throw StateError('Missing $role "$name"');
}

List<String?> _parents(_Element node) {
  final result = <String?>[];
  for (
    _Element? parent = node.parentElement;
    parent != null;
    parent = parent.parentElement
  ) {
    result.add(parent.getAttribute('id'));
  }
  return result;
}

Future<void> _key(WidgetTester tester, String key) async {
  final code = key == ' ' ? 'Space' : key;
  final target = _document.activeElement!;
  target.dispatchEvent(
    _KeyboardEvent(
      'keydown',
      _KeyboardEventInit(key: key, code: code, bubbles: true, cancelable: true),
    ),
  );
  target.dispatchEvent(
    _KeyboardEvent(
      'keyup',
      _KeyboardEventInit(key: key, code: code, bubbles: true, cancelable: true),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

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
  external String? getAttribute(String name);
  external String? get textContent;
  external _Element? get parentElement;
  external _NodeList querySelectorAll(String selector);
  external void focus();
  external void click();
  external bool dispatchEvent(JSObject event);
}

@JS('KeyboardEvent')
extension type _KeyboardEvent._(JSObject _) implements JSObject {
  external factory _KeyboardEvent(String type, _KeyboardEventInit init);
}

@JS()
@anonymous
extension type _KeyboardEventInit._(JSObject _) implements JSObject {
  external factory _KeyboardEventInit({
    required String key,
    required String code,
    required bool bubbles,
    required bool cancelable,
  });
}
