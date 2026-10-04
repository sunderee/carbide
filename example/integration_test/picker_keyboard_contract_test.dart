// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart' show SemanticsBinding;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/overlay_entries.dart';
import 'support/picker_keyboard_fixture.dart';

void main() {
  // Native input races with portal semantics and deferred engine focus events.
  // Render the scheduled frames as the production gallery does during typing.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  for (final TextDirection direction in TextDirection.values) {
    for (final KeyboardPickerKind kind in KeyboardPickerKind.values) {
      testWidgets('native picker keys ${kind.name}, $direction (#313, #314)', (
        tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final GlobalKey<PickerKeyboardFixtureState> key =
            GlobalKey<PickerKeyboardFixtureState>();
        try {
          await tester.pumpWidget(
            _host(PickerKeyboardFixture(key: key, kind: kind), direction),
          );
          await _settle(tester);
          final PickerKeyboardFixtureState state = key.currentState!;
          await _focusClosed(tester, state);
          if (kind == KeyboardPickerKind.combo ||
              kind == KeyboardPickerKind.filteredMulti) {
            final TextEditingController controller = tester
                .widget<EditableText>(find.byType(EditableText))
                .controller;
            final TextEditingValue initial = controller.value;
            final _Element native = _field();
            final List<String?> parents = _nativeParents(native);
            for (final String query in <String>['Be', 'Bet']) {
              _field().value = query;
              _field().dispatchEvent(
                _InputEvent('input', _InputEventInit(bubbles: true)),
              );
              await _settle(tester);
              expect(
                controller.text,
                query,
                reason: 'native editing survives popup opening',
              );
              expect(_field(), same(native));
              expect(_nativeParents(native), parents);
            }
            controller.value = initial;
            await _settle(tester);
            if (_open) await _key(tester, 'Escape');
          }
          await _key(tester, 'F8');
          expect(state.calls(LogicalKeyboardKey.f8), 1);
          if (kind == KeyboardPickerKind.dropdown ||
              kind == KeyboardPickerKind.select) {
            for (final String opening in <String>['ArrowUp', 'ArrowDown']) {
              await _key(tester, opening);
              expect(_open, isTrue);
              expect(
                _document.activeElement == _field(),
                isTrue,
                reason: '$opening: ${_describe(state)}',
              );
              await _key(tester, 'Enter');
              expect(state.value, opening == 'ArrowUp' ? 'c' : 'a');
              expect(_open, isFalse);
            }
            expect(state.changes, 2);
          } else {
            if (kind == KeyboardPickerKind.combo) {
              await _key(tester, 'Enter');
              expect(state.calls(LogicalKeyboardKey.enter), 1);
              expect(state.changes, 0);
              expect(_field().value, 'Beta');
            }
            await _key(tester, 'ArrowDown');
            expect(_open, isTrue);
            expect(
              _document.activeElement == _field(),
              isTrue,
              reason: _describe(state),
            );
            await _key(tester, 'Enter');
            expect(state.changes, 1);
            if (_open) await _key(tester, 'Escape');
          }
          final int changes = state.changes;
          final int submissions = state.calls(LogicalKeyboardKey.enter);
          expect(submissions, kind == KeyboardPickerKind.combo ? 1 : 0);
          expect(state.calls(LogicalKeyboardKey.escape), 0);
          await _key(tester, 'Escape');
          expect(state.calls(LogicalKeyboardKey.escape), 1);
          expect(state.changes, changes);
          expect(_open, isFalse);
          // Removing or disabling the active option cannot consume submit.
          state.configure(
            choices: const <KeyboardChoice>[
              KeyboardChoice('a', 'Alpha', disabled: true),
              KeyboardChoice('b', 'Beta', disabled: true),
              KeyboardChoice('c', 'Charlie', disabled: true),
            ],
          );
          await _settle(tester);
          await _key(tester, 'ArrowDown');
          expect(_open, isTrue);
          await _key(tester, 'Enter');
          expect(state.calls(LogicalKeyboardKey.enter), submissions + 1);
          expect(state.changes, changes);
          state.configure(readOnly: true);
          await _settle(tester);
          expect(_open, isFalse);
          expect(
            _document.activeElement == _field(),
            isTrue,
            reason: _describe(state),
          );
          await _key(tester, 'Enter');
          await _key(tester, 'Escape');
          expect(state.calls(LogicalKeyboardKey.enter), submissions + 2);
          expect(state.calls(LogicalKeyboardKey.escape), 2);
          expect(state.changes, changes);
          if (kind == KeyboardPickerKind.combo ||
              kind == KeyboardPickerKind.filteredMulti) {
            state.configure(readOnly: false);
            await _settle(tester);
            expect(_field().readOnly, isFalse);
            expect(
              _open,
              isFalse,
              reason: 'inspection focus repair preserves dismissal',
            );
            state.configure(readOnly: true);
            await tester.pump();
            state.configure(readOnly: false);
            await _settle(tester);
            expect(
              _document.activeElement == _field(),
              isTrue,
              reason: _describe(state),
            );
            expect(_field().readOnly, isFalse);
            expect(
              _field().value,
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller
                  .text,
            );
            expect(_open, isFalse);
            // Exercise the native input listener after replacing the editor;
            // matching DOM flags alone does not prove its connection is active.
            _field().value = 'Al';
            _field().dispatchEvent(
              _InputEvent('input', _InputEventInit(bubbles: true)),
            );
            await _settle(tester);
            expect(
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller
                  .text,
              'Al',
            );
            expect(_field().value, 'Al');
            _field().value = 'Alp';
            _field().dispatchEvent(
              _InputEvent('input', _InputEventInit(bubbles: true)),
            );
            await _settle(tester);
            expect(
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller
                  .text,
              'Alp',
              reason: 'the next input also reaches the current editor',
            );
            expect(_field().value, 'Alp');
            for (final int delay in <int>[0, 15, 30, 100]) {
              await _key(tester, 'Escape');
              final TextEditingController controller = tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller;
              controller.clear();
              await _settle(tester);
              expect(_open, isFalse);
              final _Element native = _field();
              final List<String?> parents = _nativeParents(native);
              // Append to the native value so a lost intermediate input cannot
              // be hidden by replacing it with the complete query each time.
              // No test pump between characters: production frames can race
              // with continued input while the popup appears and filters.
              for (final String character in 'Alpha'.split('')) {
                _field().value = '${_field().value}$character';
                _field().dispatchEvent(
                  _InputEvent('input', _InputEventInit(bubbles: true)),
                );
                await Future<void>.delayed(Duration(milliseconds: delay));
              }
              await _settle(tester);
              expect(_field(), same(native));
              expect(_nativeParents(native), parents);
              expect(_field().value, 'Alpha');
              expect(
                controller.text,
                'Alpha',
                reason: 'rapid input survives popup semantics at ${delay}ms',
              );
              expect(_document.activeElement == _field(), isTrue);
              expect(state.changes, changes);
            }
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          semantics.dispose();
        }
      });

      testWidgets(
        'native nested dialog Escape ${kind.name}, $direction (#314)',
        (tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          final GlobalKey<PickerKeyboardFixtureState> key =
              GlobalKey<PickerKeyboardFixtureState>();
          int dismissals = 0;
          try {
            await tester.pumpWidget(
              _host(
                CarbonDialog(
                  open: true,
                  onRequestClose: () => dismissals++,
                  children: <Widget>[
                    CarbonDialogBody(
                      child: PickerKeyboardFixture(
                        key: key,
                        kind: kind,
                        provideAncestorShortcuts: false,
                      ),
                    ),
                  ],
                ),
                direction,
              ),
            );
            await _settle(tester);
            await _focusClosed(tester, key.currentState!);
            expect(dismissals, 0);
            await _key(tester, 'ArrowDown');
            expect(_open, isTrue);
            await _key(tester, 'Escape');
            expect(_open, isFalse);
            expect(dismissals, 0);
            await _key(tester, 'Escape');
            expect(dismissals, 1);
            expect(key.currentState!.changes, 0);
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

// Flutter web chooses its native editing strategy on first use. Register these
// cases from a separate browser entrypoint so they exercise the shared editing
// host from startup, rather than disabling a previously active semantics role.
void testSharedEditingHostPickerPolicy() {
  for (final TextDirection direction in TextDirection.values) {
    for (final KeyboardPickerKind kind in <KeyboardPickerKind>[
      KeyboardPickerKind.combo,
      KeyboardPickerKind.filteredMulti,
    ]) {
      testWidgets(
        'native picker policy without semantics ${kind.name}, $direction',
        (tester) async {
          final GlobalKey<PickerKeyboardFixtureState> key =
              GlobalKey<PickerKeyboardFixtureState>();
          try {
            tester.platformDispatcher.semanticsEnabledTestValue = false;
            expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
            await tester.pumpWidget(
              _host(PickerKeyboardFixture(key: key, kind: kind), direction),
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
            final PickerKeyboardFixtureState state = key.currentState!;
            state.focus.requestFocus();
            await _settle(tester);
            if (_open) await _key(tester, 'Escape');
            expect(state.focus.hasPrimaryFocus, isTrue);
            expect(
              _document.activeElement!.tagName,
              anyOf('INPUT', 'TEXTAREA'),
              reason: 'the ordinary native editor is connected before policy changes',
            );
            state.configure(readOnly: true);
            await _settle(tester);
            expect(state.focus.hasPrimaryFocus, isTrue);
            expect(_open, isFalse);
            await _key(tester, 'Escape');
            expect(state.calls(LogicalKeyboardKey.escape), 1);
            state.configure(readOnly: false);
            await _settle(tester);
            expect(state.focus.hasPrimaryFocus, isTrue);
            final _Element native = _document.activeElement!;
            expect(<String>['INPUT', 'TEXTAREA'], contains(native.tagName));
            native.value = 'Alpha';
            native.dispatchEvent(
              _InputEvent('input', _InputEventInit(bubbles: true)),
            );
            await _settle(tester);
            expect(
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller
                  .text,
              'Alpha',
            );
            expect(state.changes, 0);
            expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            tester.platformDispatcher.clearSemanticsEnabledTestValue();
          }
        },
        semanticsEnabled: false,
      );
    }
  }
}

Widget _host(Widget child, TextDirection direction) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (_, _) => Directionality(
    textDirection: direction,
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (_) => Center(child: SizedBox(width: 400, child: child)),
          ),
        ],
      ),
    ),
  ),
);

bool get _open =>
    find.byType(CompositedTransformFollower).evaluate().isNotEmpty;

Future<void> _focusClosed(
  WidgetTester tester,
  PickerKeyboardFixtureState state,
) async {
  _document.querySelectorAll('flutter-view').item(0)!.focus();
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  await _settle(tester);
  _field().focus();
  await _settle(tester);
  if (_open) await _key(tester, 'Escape');
  expect(_open, isFalse, reason: _describe(state));
  expect(state.focus.hasPrimaryFocus, isTrue);
  expect(_document.activeElement == _field(), isTrue, reason: _describe(state));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 70));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _key(WidgetTester tester, String key) async {
  final _Element target = _document.activeElement!;
  for (final String type in <String>['keydown', 'keyup']) {
    target.dispatchEvent(
      _KeyboardEvent(
        type,
        _KeyboardEventInit(
          key: key,
          code: key,
          bubbles: true,
          cancelable: true,
          // The web text-input strategy also processes the legacy key code.
          // Enter must exercise native editing completion, as real keys do.
          keyCode: switch (key) {
            'Enter' => 13,
            'Escape' => 27,
            'Space' => 32,
            'ArrowUp' => 38,
            'ArrowDown' => 40,
            'F8' => 119,
            _ => 0,
          },
        ),
      ),
    );
  }
  await _settle(tester);
}

_Element _field() {
  final _NodeList elements = _document.querySelectorAll(
    'input,textarea,[role="button"]',
  );
  final List<_Element> candidates = <_Element>[
    for (int i = 0; i < elements.length; i++) elements.item(i)!,
  ];
  candidates.sort(
    (a, b) => (a.tagName == 'INPUT' || a.tagName == 'TEXTAREA' ? 0 : 1)
        .compareTo(b.tagName == 'INPUT' || b.tagName == 'TEXTAREA' ? 0 : 1),
  );
  return candidates.firstWhere(
    (element) =>
        (element.getAttribute('aria-label') ?? element.textContent ?? '')
            .trim()
            .startsWith('Field'),
  );
}

List<String?> _nativeParents(_Element element) {
  final List<String?> parents = <String?>[];
  for (
    _Element? parent = element.parentElement;
    parent != null;
    parent = parent.parentElement
  ) {
    parents.add(parent.getAttribute('id'));
  }
  return parents;
}

String _describe(PickerKeyboardFixtureState state) =>
    'framework=${state.focus.hasPrimaryFocus}, primary=${FocusManager.instance.primaryFocus?.debugLabel}, active=${_document.activeElement?.tagName}/${_document.activeElement?.getAttribute('aria-label')}/${_document.activeElement?.getAttribute('flt-semantics-identifier')}, field=${_field().outerHTML}';

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
  external bool dispatchEvent(JSObject event);
  external _Element? get parentElement;
  external String get tagName;
  external String get outerHTML;
  external String? get textContent;
  external String get value;
  external set value(String value);
  external bool get readOnly;
  external String? getAttribute(String name);
  external void focus();
}

@JS('KeyboardEvent')
extension type _KeyboardEvent._(JSObject _) implements JSObject {
  external factory _KeyboardEvent(String type, _KeyboardEventInit options);
}

extension type _KeyboardEventInit._(JSObject _) implements JSObject {
  external factory _KeyboardEventInit({
    String key,
    String code,
    bool bubbles,
    bool cancelable,
    int keyCode,
  });
}

@JS('Event')
extension type _InputEvent._(JSObject _) implements JSObject {
  external factory _InputEvent(String type, _InputEventInit options);
}

extension type _InputEventInit._(JSObject _) implements JSObject {
  external factory _InputEventInit({bool bubbles});
}
