// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/typeahead_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final String family in <String>[
    'menu',
    'select',
    'dropdown',
    'overflow',
  ]) {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('native Unicode $family in $direction', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          for (final (String input, String expected) in <(String, String)>[
            ('e', 'Éditer'),
            ('E\u0301', 'Éditer'),
            ('u', 'Über'),
            ('Д', 'Данные'),
            ('東', '東京'),
            ('𐐀', '𐐨eseret'),
            ('١', '١ item'),
          ]) {
            final key = GlobalKey<TypeaheadFixtureState>();
            await tester.pumpWidget(
              typeaheadHost(
                TypeaheadFixture(key: key, family: family),
                direction: direction,
              ),
            );
            await _settle(tester);
            _document.querySelector('flutter-view')!.focus();
            tester.binding.handleViewFocusChanged(
              ViewFocusEvent(
                viewId: tester.view.viewId,
                state: ViewFocusState.focused,
                direction: ViewFocusDirection.undefined,
              ),
            );
            await _settle(tester);
            if (family == 'overflow') {
              _named('Open actions').click();
            } else if (family == 'select' || family == 'dropdown') {
              key.currentState!.trigger.requestFocus();
              await _settle(tester);
              await tester.sendKeyEvent(
                LogicalKeyboardKey.arrowDown,
                physicalKey: PhysicalKeyboardKey.arrowDown,
              );
            }
            await _settle(tester);
            await tester.sendKeyEvent(
              LogicalKeyboardKey.keyE,
              physicalKey: PhysicalKeyboardKey.keyE,
              character: input,
            );
            await _settle(tester);
            expect(key.currentState!.chosen, isNull);
            expect(key.currentState!.changes, 0);
            if (family == 'select' || family == 'dropdown') {
              final String text =
                  _document.querySelector('flutter-view')!.textContent ?? '';
              expect(text, contains('Active option: $expected'));
            }
            await tester.sendKeyEvent(
              LogicalKeyboardKey.enter,
              physicalKey: PhysicalKeyboardKey.enter,
            );
            await _settle(tester);
            expect(key.currentState!.chosen, expected);
            expect(key.currentState!.changes, 1);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          semantics.dispose();
        }
      });
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}

_Element _named(String label) {
  final _NodeList nodes = _document.querySelectorAll('[role="button"], button');
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if (node.getAttribute('aria-label') == label ||
        node.textContent?.trim() == label) {
      return node;
    }
  }
  throw StateError('No native semantics node named $label');
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _NodeList querySelectorAll(String selector);
}

extension type _Element(JSObject _) implements JSObject {
  external void focus();
  external void click();
  external String? getAttribute(String name);
  external String? get textContent;
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}
