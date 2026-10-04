// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/context_menu_fixture.dart';
import 'support/failure_diagnostics.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  retainIntegrationFailureDetails(binding);
  for (final direction in TextDirection.values) {
    for (final kind in <String>['selectable', 'radio']) {
      testWidgets('native first $kind item owns focus $direction (#315)', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final key = GlobalKey<ContextMenuFixtureState>();
        try {
          await tester.pumpWidget(
            contextMenuHost(
              ContextMenuFixture(key: key, selectionKind: kind),
              direction: direction,
            ),
          );
          await _settle(tester);
          final state = key.currentState!;
          final target = _named('button', 'Context target');
          target.focus();
          await _settle(tester);
          await _key(tester, 'ContextMenu');
          final radio = kind == 'radio';
          final first = _named(
            radio ? 'radio' : 'checkbox',
            radio ? 'First mode' : 'Pinned',
          );
          expect(_document.activeElement, same(first));
          if (radio) {
            await _key(tester, 'ArrowDown');
            await _key(tester, ' ');
            expect(state.mode, 2);
            expect(
              _document.activeElement,
              same(_named('radio', 'Second mode')),
            );
            expect(
              _named('radio', 'Second mode').getAttribute('aria-checked'),
              'true',
            );
          } else {
            await _key(tester, ' ');
            expect(state.pinned, isTrue);
            expect(_document.activeElement, same(first));
            expect(first.getAttribute('aria-checked'), 'true');
          }
          await _key(tester, 'ArrowDown');
          expect(_document.activeElement, same(_named('button', 'Cut')));
          await _key(tester, 'Escape');
          expect(state.target.hasPrimaryFocus, isTrue);
          expect(_document.activeElement, same(target));
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          semantics.dispose();
        }
      });
    }
  }
  for (final direction in TextDirection.values) {
    for (final editable in <bool>[false, true]) {
      testWidgets(
        'native context-menu opening and restoration $direction editor=$editable (#315)',
        (tester) async {
          final semantics = tester.ensureSemantics();
          final key = GlobalKey<ContextMenuFixtureState>();
          try {
            await tester.pumpWidget(
              contextMenuHost(
                ContextMenuFixture(key: key, editable: editable),
                direction: direction,
              ),
            );
            await _settle(tester);
            final state = key.currentState!;
            if (editable) {
              await tester.tap(find.byType(EditableText));
              await _settle(tester);
            }
            final target = _named(
              editable ? 'textbox' : 'button',
              editable ? 'Context editor' : 'Context target',
            );
            target.focus();
            await _settle(tester);
            expect(
              state.target.hasPrimaryFocus,
              isTrue,
              reason: 'initial native opener ownership',
            );
            await _key(tester, 'F10', shift: true);
            expect(_document.activeElement, same(_named('button', 'Cut')));
            expect(
              _named('button', 'Unavailable').getAttribute('aria-disabled'),
              'true',
            );
            await _key(tester, 'Escape');
            expect(state.target.hasPrimaryFocus, isTrue);
            expect(_document.activeElement, same(target));
            await _key(tester, 'ContextMenu');
            expect(_document.activeElement, same(_named('button', 'Cut')));
            await _key(tester, 'Enter');
            expect(state.actions, 1);
            expect(_document.activeElement, same(target));
            await _key(tester, 'ContextMenu');
            await _key(tester, 'Tab');
            expect(state.second.hasPrimaryFocus, isTrue);
            expect(
              _document.activeElement,
              same(_named('button', 'Second target')),
            );
            await _key(tester, 'ContextMenu');
            expect(_document.activeElement, same(_named('button', 'Cut')));
            await _key(tester, 'Escape');
            expect(
              _document.activeElement,
              same(_named('button', 'Second target')),
            );
            target.focus();
            await _settle(tester);
            await _key(tester, 'ContextMenu');
            await tester.tapAt(const Offset(2, 2));
            await _settle(tester);
            expect(_document.activeElement, same(target));
            await _key(tester, 'ContextMenu');
            await _key(tester, 'F2');
            expect(state.enabled, isFalse);
            expect(state.target.hasPrimaryFocus, isTrue);
            expect(_document.activeElement, same(target));
            await _key(tester, 'ContextMenu');
            expect(_find('button', 'Cut'), isNull);
            state.enabled = true;
            state.handoff = true;
            state.refresh();
            await _settle(tester);
            expect(
              state.target.hasPrimaryFocus,
              isTrue,
              reason: 'opener survives re-enable',
            );
            expect(
              _document.activeElement,
              same(target),
              reason: 'native opener survives re-enable',
            );
            await _key(tester, 'ContextMenu');
            expect(
              _document.activeElement,
              same(_named('button', 'Cut')),
              reason: 're-enabled entry',
            );
            await _key(tester, 'Enter');
            expect(state.actions, 2);
            expect(state.outside.hasPrimaryFocus, isTrue);
            expect(
              _document.activeElement,
              same(_named('button', 'Outside region')),
            );
            await _key(tester, 'F10', shift: true);
            await _key(tester, 'ContextMenu');
            expect(_find('button', 'Cut'), isNull);
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

_Element? _find(String role, String name) {
  final nodes = _document.querySelectorAll(
    role == 'textbox' ? 'input,textarea' : 'flt-semantics[role="$role"]',
  );
  for (int i = 0; i < nodes.length; i++) {
    final node = nodes.item(i)!;
    if ((node.getAttribute('aria-label') ?? node.textContent?.trim()) == name) {
      return node;
    }
  }
  return null;
}

_Element _named(String role, String name) {
  final result = _find(role, name);
  if (result != null) return result;
  final nodes = _document.querySelectorAll('[role="$role"]');
  final labels = <String?>[
    for (int i = 0; i < nodes.length; i++)
      nodes.item(i)!.getAttribute('aria-label') ?? nodes.item(i)!.textContent,
  ];
  throw StateError('Missing $role $name; found $labels');
}

Future<void> _key(WidgetTester tester, String key, {bool shift = false}) async {
  final target = _document.activeElement!;
  if (shift) {
    target.dispatchEvent(
      _KeyboardEvent(
        'keydown',
        _KeyboardEventInit(
          key: 'Shift',
          code: 'ShiftLeft',
          shiftKey: true,
          bubbles: true,
          cancelable: true,
        ),
      ),
    );
  }
  target.dispatchEvent(
    _KeyboardEvent(
      'keydown',
      _KeyboardEventInit(
        key: key,
        code: key == ' ' ? 'Space' : key,
        shiftKey: shift,
        bubbles: true,
        cancelable: true,
      ),
    ),
  );
  target.dispatchEvent(
    _KeyboardEvent(
      'keyup',
      _KeyboardEventInit(
        key: key,
        code: key == ' ' ? 'Space' : key,
        shiftKey: shift,
        bubbles: true,
        cancelable: true,
      ),
    ),
  );
  if (shift) {
    target.dispatchEvent(
      _KeyboardEvent(
        'keyup',
        _KeyboardEventInit(
          key: 'Shift',
          code: 'ShiftLeft',
          shiftKey: false,
          bubbles: true,
          cancelable: true,
        ),
      ),
    );
  }
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
  external void focus();
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
    required bool shiftKey,
    required bool bubbles,
    required bool cancelable,
  });
}
