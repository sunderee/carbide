// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';
import 'dart:ui'
    show PointerDeviceKind, ViewFocusDirection, ViewFocusEvent, ViewFocusState;

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

// Uses the same native field/key/settling helpers as the keyboard contracts.
// A separate entrypoint keeps the original keyboard matrix independently runnable.
void testNativePickerOptionSemantics() {
  for (final TextDirection direction in TextDirection.values) {
    for (final KeyboardPickerKind kind in KeyboardPickerKind.values) {
      for (final bool dialog in <bool>[false, true]) {
        testWidgets(
          'native active option ${kind.name}, $direction dialog=$dialog (#311)',
          (tester) async {
            final SemanticsHandle semantics = tester.ensureSemantics();
            final key = GlobalKey<PickerKeyboardFixtureState>();
            _MutationObserver? observer;
            final List<String> announcements = <String>[];
            try {
              final Widget fixture = PickerKeyboardFixture(
                key: key,
                kind: kind,
                provideAncestorShortcuts: !dialog,
              );
              await tester.pumpWidget(
                _host(
                  dialog
                      ? CarbonDialog(
                          open: true,
                          onRequestClose: () {},
                          children: <Widget>[CarbonDialogBody(child: fixture)],
                        )
                      : fixture,
                  direction,
                ),
              );
              await _settle(tester);
              final state = key.currentState!;
              state.configure(
                choices: const <KeyboardChoice>[
                  KeyboardChoice('a', 'Alpha'),
                  KeyboardChoice('b', 'Beta', disabled: true),
                  KeyboardChoice('c', 'Charlie'),
                ],
              );
              await _settle(tester);
              await _focusClosed(tester, state);
              expect(_expanded(), 'false');
              observer = _MutationObserver(
                ((JSObject records, JSObject observer) {
                  final String? message = _liveAnnouncement();
                  if (message != null && message.isNotEmpty) {
                    announcements.add(message);
                  }
                }).toJS,
              );
              observer.observe(
                _document.querySelectorAll('[aria-live="polite"]').item(0)!,
                _ObserverOptions(
                  childList: true,
                  subtree: true,
                  characterData: true,
                ),
              );
              final native = _field();
              final parents = _nativeParents(native);
              await _key(tester, 'ArrowDown');
              expect(_expanded(), 'true');
              _expectNativeActive(announcements, state, 'Alpha', 1, 3);
              await _key(tester, 'ArrowDown');
              _expectNativeActive(announcements, state, 'Charlie', 3, 3);
              expect(_field(), same(native));
              if (kind == KeyboardPickerKind.combo ||
                  kind == KeyboardPickerKind.filteredMulti) {
                expect(_nativeParents(native), parents);
              }
              for (final String label in <String>['Alpha', 'Beta', 'Charlie']) {
                expect(
                  _nativeOptions(label),
                  hasLength(1),
                  reason: 'one native option: $label',
                );
              }
              final multiple =
                  kind == KeyboardPickerKind.multi ||
                  kind == KeyboardPickerKind.filteredMulti;
              expect(
                _nativeOptions('Beta').single.getAttribute('aria-disabled'),
                'true',
              );
              expect(
                _nativeOptions('Beta').single
                    .getAttribute(multiple ? 'aria-checked' : 'aria-current'),
                'true',
              );
              expect(
                _nativeOptions('Charlie').single
                    .getAttribute(multiple ? 'aria-checked' : 'aria-current'),
                'false',
              );
              expect(state.value, 'b');
              expect(state.selected, <String>{'b'});
              expect(state.changes, 0);
              state.configure(
                activeOptionFormatter: (label, position, count) =>
                    'Option active : $label ($position/$count)',
              );
              await _settle(tester);
              const localized = 'Option active : Charlie (3/3)';
              expect(_field().getAttribute('aria-description'), localized);
              expect(
                _nativeOptions('Charlie').single
                    .getAttribute('aria-description'),
                localized,
              );
              expect(announcements, contains(localized));
              expect(_document.activeElement == _field(), isTrue);
              // Model the native blur caused by a real pointer on a disabled
              // row, then exercise the complete Flutter row hit target.
              _document.querySelectorAll('flutter-view').item(0)!.focus();
              final TestGesture pointer = await tester.startGesture(
                tester.getCenter(
                  find.descendant(
                    of: find.byType(CompositedTransformFollower),
                    matching: find.text('Beta'),
                  ),
                ),
                kind: PointerDeviceKind.mouse,
              );
              await _settle(tester);
              expect(_document.activeElement == _field(), isTrue);
              // A trusted browser click can blur again after the down-frame
              // repair. Model that final native default before pointer-up.
              _document.querySelectorAll('flutter-view').item(0)!.focus();
              await pointer.up();
              await _settle(tester);
              expect(_document.activeElement == _field(), isTrue);
              expect(state.focus.hasPrimaryFocus, isTrue);
              expect(state.changes, 0);
              _nativeOptions('Beta').single.click();
              await _settle(tester);
              expect(state.changes, 0);
              state.configure(
                activeOptionFormatter: carbonListBoxActiveOptionLabel,
              );
              await _settle(tester);
              if (kind == KeyboardPickerKind.combo ||
                  kind == KeyboardPickerKind.filteredMulti) {
                _field().value = 'Ch';
                _field().dispatchEvent(
                  _InputEvent('input', _InputEventInit(bubbles: true)),
                );
                await _settle(tester);
                expect(
                  tester
                      .widget<EditableText>(find.byType(EditableText))
                      .controller
                      .text,
                  'Ch',
                );
                _expectNativeActive(announcements, state, 'Charlie', 1, 1);
                expect(_field().value, 'Ch');
                expect(_nativeOptions('Alpha'), isEmpty);
                expect(_nativeOptions('Beta'), isEmpty);
                _field().value = 'Missing';
                _field().dispatchEvent(
                  _InputEvent('input', _InputEventInit(bubbles: true)),
                );
                await _settle(tester);
                expect(_field().getAttribute('aria-description'), isNull);
                expect(
                  tester
                      .widget<EditableText>(find.byType(EditableText))
                      .controller
                      .text,
                  'Missing',
                );
                _field().value = '';
                _field().dispatchEvent(
                  _InputEvent('input', _InputEventInit(bubbles: true)),
                );
                await _settle(tester);
                _expectNativeActive(announcements, state, 'Alpha', 1, 3);
                expect(
                  _nativeParents(_field()),
                  parents,
                  reason: 'native editor ancestry after clearing no matches',
                );
              }
              _nativeOptions('Charlie').single.click();
              await _settle(tester);
              expect(state.changes, 1);
              if (multiple) {
                expect(state.selected, <String>{'b', 'c'});
                expect(
                  _nativeOptions('Charlie').single.getAttribute('aria-checked'),
                  'true',
                );
                await _key(tester, 'Escape');
              } else {
                expect(state.value, 'c');
              }
              expect(_expanded(), 'false');
              expect(_field().getAttribute('aria-description'), isNull);
              expect(_document.activeElement == _field(), isTrue);
              await _key(tester, 'ArrowDown');
              state.configure(readOnly: true);
              await _settle(tester);
              expect(_open, isFalse);
              expect(_field().getAttribute('aria-description'), 'Read only');
              expect(state.changes, 1);
              expect(_document.activeElement == _field(), isTrue);
            } finally {
              observer?.disconnect();
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

String? _expanded() {
  final field = _field();
  if (field.tagName != 'INPUT' && field.tagName != 'TEXTAREA') {
    return field.getAttribute('aria-expanded');
  }
  // Flutter's SemanticTextField uses SemanticRole.blank and does not translate
  // expanded. The adjacent named popup button supplies native web expansion;
  // the input itself still carries expanded in Flutter's semantics tree.
  return _nativeOptions('Field').single.getAttribute('aria-expanded');
}

List<_Element> _nativeOptions(String label) {
  final elements = _document.querySelectorAll(
    'flt-semantics[role="button"],flt-semantics[role="checkbox"]',
  );
  return <_Element>[
    for (int i = 0; i < elements.length; i++)
      if ((elements.item(i)!.getAttribute('aria-label') ??
                  elements.item(i)!.textContent ??
                  '')
              .trim() ==
          label)
        elements.item(i)!,
  ];
}

String? _liveAnnouncement() => _document
    .querySelectorAll('[aria-live="polite"]')
    .item(0)
    ?.textContent
    ?.trim();

void _expectNativeActive(
  List<String> announcements,
  PickerKeyboardFixtureState state,
  String label,
  int position,
  int count,
) {
  final hint = 'Active option: $label, $position of $count';
  expect(_field().getAttribute('aria-description'), hint);
  expect(_nativeOptions(label).single.getAttribute('aria-description'), hint);
  expect(announcements, contains(hint));
  expect(state.focus.hasPrimaryFocus, isTrue);
  expect(_document.activeElement == _field(), isTrue, reason: _describe(state));
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
            state.configure(
              choices: const <KeyboardChoice>[
                KeyboardChoice('a', 'Alpha'),
                KeyboardChoice('b', 'Beta', disabled: true),
                KeyboardChoice('c', 'Charlie'),
              ],
            );
            await _settle(tester);
            await _key(tester, 'ArrowDown');
            // The browser's default canvas pointer action blurs its ordinary
            // editing host before the framework delivers the option gesture.
            _document.querySelectorAll('flutter-view').item(0)!.focus();
            await tester.tapAt(
              tester.getCenter(
                find.descendant(
                  of: find.byType(CompositedTransformFollower),
                  matching: find.text('Beta'),
                ),
              ),
            );
            await _settle(tester);
            expect(state.changes, 0);
            expect(
              state.focus.hasPrimaryFocus,
              isTrue,
              reason: 'a disabled row preserves the ordinary editor focus',
            );
            final _Element retained = _document.activeElement!;
            expect(<String>['INPUT', 'TEXTAREA'], contains(retained.tagName));
            retained.value = 'Charlie';
            retained.dispatchEvent(
              _InputEvent('input', _InputEventInit(bubbles: true)),
            );
            await _settle(tester);
            expect(
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .controller
                  .text,
              'Charlie',
            );
            expect(state.changes, 0);
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
    'framework=${state.focus.hasPrimaryFocus}, document=${_document.hasFocus()}, primary=${FocusManager.instance.primaryFocus?.debugLabel}, active=${_document.activeElement?.tagName}/${_document.activeElement?.getAttribute('aria-label')}/${_document.activeElement?.getAttribute('flt-semantics-identifier')}, parents=${_nativeParents(_field())}, field=${_field().outerHTML}';

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
  external _Element? get activeElement;
  external bool hasFocus();
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
  external void click();
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

@JS('MutationObserver')
extension type _MutationObserver._(JSObject _) implements JSObject {
  external factory _MutationObserver(JSFunction callback);
  external void observe(JSObject target, _ObserverOptions options);
  external void disconnect();
}

extension type _ObserverOptions._(JSObject _) implements JSObject {
  external factory _ObserverOptions({
    bool childList,
    bool subtree,
    bool characterData,
  });
}
