// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/tabs_overflow_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final (bool vertical, CarbonTabVariant variant)
      in <(bool, CarbonTabVariant)>[
        (false, CarbonTabVariant.line),
        (false, CarbonTabVariant.contained),
        (true, CarbonTabVariant.contained),
      ]) {
    for (final CarbonTabActivationMode activation
        in CarbonTabActivationMode.values) {
      for (final TextDirection direction in TextDirection.values) {
        for (final bool reduced in <bool>[false, true]) {
          testWidgets(
            'native overflow vertical=$vertical $variant $activation $direction reduced=$reduced',
            (WidgetTester tester) async {
              final SemanticsHandle semantics = tester.ensureSemantics();
              final GlobalKey<TabsOverflowFixtureState> key =
                  GlobalKey<TabsOverflowFixtureState>();
              try {
                await tester.pumpWidget(
                  tabsOverflowHost(
                    TabsOverflowFixture(
                      key: key,
                      vertical: vertical,
                      variant: variant,
                      activation: activation,
                      reduced: reduced,
                    ),
                    direction: direction,
                  ),
                );
                await _settle(tester);
                final TabsOverflowFixtureState state = key.currentState!;
                expect(_document.querySelector('[role="tablist"]'), isNotNull);
                expect(_document.querySelector('[role="tabpanel"]'), isNotNull);
                _oneTabStop(0);
                _tab(0).focus();
                await _settle(tester);
                expect(_tab(0).tabIndex, 0);
                await _send(
                  tester,
                  LogicalKeyboardKey.end,
                  PhysicalKeyboardKey.end,
                );
                _visible(tester, 17, vertical);
                expect(_tab(17).tabIndex, 0);
                expect(_tab(0).tabIndex, -1);
                _oneTabStop(17);
                if (activation == CarbonTabActivationMode.manual) {
                  expect(state.changes, 0);
                  expect(state.selected, 0);
                  await _send(
                    tester,
                    LogicalKeyboardKey.enter,
                    PhysicalKeyboardKey.enter,
                  );
                }
                expect(state.selected, 17);
                expect(state.changes, 1);
                expect(_tab(17).getAttribute('aria-selected'), 'true');
                final _Element panel = _document.querySelector(
                  '[role="tabpanel"]',
                )!;
                expect(_tab(17).getAttribute('aria-controls'), panel.id);
                await _send(
                  tester,
                  LogicalKeyboardKey.home,
                  PhysicalKeyboardKey.home,
                );
                _visible(tester, 0, vertical);
                if (activation == CarbonTabActivationMode.manual) {
                  expect(state.selected, 17);
                  await _send(
                    tester,
                    LogicalKeyboardKey.space,
                    PhysicalKeyboardKey.space,
                  );
                }
                expect(state.selected, 0);
                expect(state.changes, 2);
                final LogicalKeyboardKey forward = vertical
                    ? LogicalKeyboardKey.arrowDown
                    : direction == TextDirection.ltr
                    ? LogicalKeyboardKey.arrowRight
                    : LogicalKeyboardKey.arrowLeft;
                final PhysicalKeyboardKey physical = vertical
                    ? PhysicalKeyboardKey.arrowDown
                    : direction == TextDirection.ltr
                    ? PhysicalKeyboardKey.arrowRight
                    : PhysicalKeyboardKey.arrowLeft;
                await _send(tester, forward, physical);
                await _send(tester, forward, physical);
                _visible(tester, 3, vertical);
                expect(_tab(3).tabIndex, 0);
                _oneTabStop(3);
                expect(_tab(2).getAttribute('aria-disabled'), 'true');
                if (activation == CarbonTabActivationMode.manual) {
                  await _send(
                    tester,
                    LogicalKeyboardKey.enter,
                    PhysicalKeyboardKey.enter,
                  );
                  expect(state.changes, 3);
                } else {
                  expect(state.changes, 4);
                }
                expect(state.selected, 3);
                state.select(17);
                await _settle(tester);
                _visible(tester, 17, vertical);
                final int before = state.changes;
                state.shrink();
                await _settle(tester);
                expect(state.selected, 3);
                expect(state.changes, before);
                _visible(tester, 3, vertical);
                expect(_tab(3).tabIndex, 0);
                expect(tester.takeException(), isNull);
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
  }
}

void _oneTabStop(int index) {
  final _NodeList elements = _document.querySelectorAll('[role="tab"]');
  int stops = 0;
  for (int i = 0; i < elements.length; i++) {
    final _Element node = elements.item(i)!;
    if (node.tabIndex == 0) stops++;
  }
  expect(stops, 1);
  expect(_tab(index).tabIndex, 0);
}

void _visible(WidgetTester tester, int index, bool vertical) {
  final Finder parent = vertical
      ? find.byType(CarbonTabsVertical)
      : find.byType(CarbonTabs);
  final Finder scroll = find.descendant(
    of: parent,
    matching: find.byType(Scrollable),
  );
  final Rect viewport = tester.getRect(scroll.first);
  final _Rect rect = _tab(index).getBoundingClientRect();
  if (vertical) {
    expect(rect.top, greaterThanOrEqualTo(viewport.top - 0.5));
    expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + 0.5));
  } else {
    expect(rect.left, greaterThanOrEqualTo(viewport.left - 0.5));
    expect(rect.right, lessThanOrEqualTo(viewport.right + 0.5));
  }
}

Future<void> _send(
  WidgetTester tester,
  LogicalKeyboardKey key,
  PhysicalKeyboardKey physical,
) async {
  await tester.sendKeyEvent(key, physicalKey: physical);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

_Element _tab(int index) {
  final String label = 'Tab ${index.toString().padLeft(2, '0')}';
  final _NodeList elements = _document.querySelectorAll('[role="tab"]');
  for (int i = 0; i < elements.length; i++) {
    final _Element node = elements.item(i)!;
    if (node.getAttribute('aria-label') == label ||
        node.textContent?.trim() == label) {
      return node;
    }
  }
  throw StateError('No native tab $label');
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
  external _Element? querySelector(String selector);
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? getAttribute(String name);
  external String? get textContent;
  external String get id;
  external int get tabIndex;
  external void focus();
  external _Rect getBoundingClientRect();
}

extension type _Rect(JSObject _) implements JSObject {
  external double get left;
  external double get right;
  external double get top;
  external double get bottom;
}
