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

import 'support/overlay_entries.dart';
import 'support/picker_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final TextDirection direction in TextDirection.values) {
    for (final PickerKind kind in PickerKind.values) {
      testWidgets('native read-only ${kind.name}, $direction (#312)', (
        tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final GlobalKey<PickerFixtureState> key =
            GlobalKey<PickerFixtureState>();
        try {
          await tester.pumpWidget(
            WidgetsApp(
              color: const Color(0xFFFFFFFF),
              builder: (_, _) => Directionality(
                textDirection: direction,
                child: CarbonTheme(
                  data: CarbonThemeData.white,
                  child: Overlay(
                    initialEntries: <OverlayEntry>[
                      managedOverlayEntry(
                        builder: (_) => Center(
                          child: SizedBox(
                            width: 400,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                CarbonButton(label: 'Before', onPressed: () {}),
                                PickerFixture(key: key, kind: kind),
                                CarbonButton(label: 'After', onPressed: () {}),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await _settle(tester);
          _document.querySelectorAll('flutter-view').item(0)!.focus();
          tester.binding.handleViewFocusChanged(
            ViewFocusEvent(
              viewId: tester.view.viewId,
              state: ViewFocusState.focused,
              direction: ViewFocusDirection.undefined,
            ),
          );
          await _settle(tester);
          _button('Before').focus();
          await _settle(tester);
          await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
          final _Element field = _field();
          expect(
            _document.activeElement == field,
            isTrue,
            reason:
                'active=${_document.activeElement?.getAttribute('aria-label')}/${_document.activeElement?.getAttribute('role')} expected=${field.getAttribute('aria-label')}/${field.getAttribute('role')}',
          );
          expect(field.getAttribute('aria-description'), 'Nur lesen');
          if (_isText(kind)) {
            expect(field.readOnly, isTrue);
            expect(field.disabled, isFalse);
            expect(field.value, key.currentState!.announcedValue);
          } else {
            expect(field.getAttribute('aria-disabled'), 'true');
            expect(
              field.getAttribute('aria-label') ?? field.textContent,
              contains(key.currentState!.announcedValue),
            );
          }
          for (final (LogicalKeyboardKey logical, PhysicalKeyboardKey physical)
              in <(LogicalKeyboardKey, PhysicalKeyboardKey)>[
                (LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter),
                (LogicalKeyboardKey.space, PhysicalKeyboardKey.space),
                (LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown),
                (LogicalKeyboardKey.arrowUp, PhysicalKeyboardKey.arrowUp),
                (LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape),
                (LogicalKeyboardKey.keyB, PhysicalKeyboardKey.keyB),
              ]) {
            await _key(tester, logical, physical);
          }
          field.click();
          await _settle(tester);
          _expectClosed();
          expect(key.currentState!.changes, 0);
          expect(key.currentState!.inputs, 0);
          expect(key.currentState!.clears, 0);
          if (_isText(kind)) {
            expect(_field().value, key.currentState!.announcedValue);
          }
          _button('After').focus();
          await _settle(tester);
          expect(_document.activeElement == _button('After'), isTrue);
          key.currentState!.configure(disabled: true);
          await _settle(tester);
          _button('Before').focus();
          await _settle(tester);
          await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
          expect(_document.activeElement == _button('After'), isTrue);
          key.currentState!.configure(disabled: false, readOnly: false);
          await _settle(tester);
          if (kind == PickerKind.expandableSearch) {
            _button('Expand search').click();
            await _settle(tester);
          }
          if (kind.hasPopup) {
            _field().focus();
            await _settle(tester);
            if (!_hasPopup()) {
              await _key(
                tester,
                kind == PickerKind.date || kind == PickerKind.range
                    ? LogicalKeyboardKey.enter
                    : LogicalKeyboardKey.arrowDown,
                kind == PickerKind.date || kind == PickerKind.range
                    ? PhysicalKeyboardKey.enter
                    : PhysicalKeyboardKey.arrowDown,
              );
            }
            expect(_hasPopup(), isTrue);
            key.currentState!.configure(readOnly: true);
            await _settle(tester);
            _expectClosed();
            expect(key.currentState!.changes, 0);
          }
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          semantics.dispose();
        }
      });
    }
  }
}

bool _isText(PickerKind kind) => <PickerKind>[
  PickerKind.combo,
  PickerKind.filteredMulti,
  PickerKind.search,
  PickerKind.expandableSearch,
].contains(kind);

bool _hasPopup() =>
    find.byType(CarbonCalendar).evaluate().isNotEmpty ||
    find.byType(CarbonListBoxMenu).evaluate().isNotEmpty ||
    find.text('Alpha').evaluate().isNotEmpty;

void _expectClosed() => expect(_hasPopup(), isFalse);

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 70));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical,
) async {
  await tester.sendKeyEvent(logical, physicalKey: physical);
  await _settle(tester);
}

_Element _field() {
  final _NodeList fields = _document.querySelectorAll(
    'input,textarea,[role="button"]',
  );
  return <_Element>[for (int i = 0; i < fields.length; i++) fields.item(i)!]
      .firstWhere(
        (element) =>
            (element.getAttribute('aria-label') ?? element.textContent ?? '')
                .trim()
                .startsWith('Field'),
      );
}

_Element _button(String name) {
  final _NodeList buttons = _document.querySelectorAll('[role="button"]');
  return <_Element>[for (int i = 0; i < buttons.length; i++) buttons.item(i)!]
      .firstWhere(
        (element) =>
            (element.getAttribute('aria-label') ?? element.textContent ?? '')
                .trim() ==
            name,
      );
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
  external String? get textContent;
  external String get value;
  external bool get readOnly;
  external bool get disabled;
  external String? getAttribute(String name);
  external void click();
  external void focus();
}
