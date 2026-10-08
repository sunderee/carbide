// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:carbide/src/utils/anchored_overlay.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';
import '../../support/picker_keyboard_fixture.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (_, _) => Directionality(
        textDirection: direction,
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) =>
                    Center(child: SizedBox(width: 360, child: child)),
              ),
            ],
          ),
        ),
      ),
    );

void _enterView(WidgetTester tester) => tester.binding.handleViewFocusChanged(
  ViewFocusEvent(
    viewId: tester.view.viewId,
    state: ViewFocusState.focused,
    direction: ViewFocusDirection.undefined,
  ),
);

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

bool get _open => find.byType(CarbonAnchoredOverlay).evaluate().isNotEmpty;

Future<void> _focusClosed(
  WidgetTester tester,
  PickerKeyboardFixtureState state,
) async {
  _enterView(tester);
  state.focus.requestFocus();
  await tester.pumpAndSettle();
  if (_open) await _press(tester, LogicalKeyboardKey.escape);
  expect(_open, isFalse);
  expect(state.focus.hasPrimaryFocus, isTrue);
}

void _test(String description, WidgetTesterCallback body) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
}

void main() {
  for (final KeyboardPickerKind kind in <KeyboardPickerKind>[
    KeyboardPickerKind.dropdown,
    KeyboardPickerKind.select,
  ]) {
    for (final LogicalKeyboardKey opening in <LogicalKeyboardKey>[
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
    ]) {
      for (final String scenario in <String>[
        'selected middle',
        'no selection',
        'disabled edges',
        'disabled selection',
      ]) {
        _test(
          '$kind opens ${opening.keyLabel} at the enabled edge: $scenario (#313)',
          (tester) async {
            final GlobalKey<PickerKeyboardFixtureState> key =
                GlobalKey<PickerKeyboardFixtureState>();
            await tester.pumpWidget(
              _host(PickerKeyboardFixture(key: key, kind: kind)),
            );
            final PickerKeyboardFixtureState state = key.currentState!;
            if (scenario == 'no selection') state.configure(clearValue: true);
            if (scenario == 'disabled edges') {
              state.configure(
                choices: const <KeyboardChoice>[
                  KeyboardChoice('x', 'Disabled first', disabled: true),
                  ...keyboardChoices,
                  KeyboardChoice('y', 'Disabled last', disabled: true),
                ],
              );
            }
            if (scenario == 'disabled selection') {
              state.configure(
                choices: const <KeyboardChoice>[
                  KeyboardChoice('a', 'Alpha'),
                  KeyboardChoice('b', 'Beta', disabled: true),
                  KeyboardChoice('c', 'Charlie'),
                ],
              );
            }
            await tester.pumpAndSettle();
            await _focusClosed(tester, state);
            await _press(tester, opening);
            expect(_open, isTrue);
            expect(state.calls(opening), 0);
            expect(state.changes, 0);
            await _press(tester, LogicalKeyboardKey.enter);
            expect(
              state.value,
              opening == LogicalKeyboardKey.arrowUp ? 'c' : 'a',
            );
            expect(state.changes, 1);
            expect(state.calls(LogicalKeyboardKey.enter), 0);
            expect(_open, isFalse);
          },
        );
      }
    }

    for (final bool readOnly in <bool>[true, false]) {
      _test(
        '$kind blocks all opening keys when ${readOnly ? 'read-only' : 'disabled'} (#313)',
        (tester) async {
          final GlobalKey<PickerKeyboardFixtureState> key =
              GlobalKey<PickerKeyboardFixtureState>();
          await tester.pumpWidget(
            _host(PickerKeyboardFixture(key: key, kind: kind)),
          );
          final PickerKeyboardFixtureState state = key.currentState!;
          await _focusClosed(tester, state);
          state.configure(readOnly: readOnly, disabled: !readOnly);
          await tester.pumpAndSettle();
          for (final LogicalKeyboardKey opening in <LogicalKeyboardKey>[
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.enter,
            LogicalKeyboardKey.space,
          ]) {
            await _press(tester, opening);
            expect(_open, isFalse);
            expect(state.changes, 0);
          }
        },
      );
    }

    _test('$kind Enter and Space reopen at the enabled selection (#313)', (
      tester,
    ) async {
      final GlobalKey<PickerKeyboardFixtureState> key =
          GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: kind)),
      );
      final PickerKeyboardFixtureState state = key.currentState!;
      await _focusClosed(tester, state);
      for (final LogicalKeyboardKey opening in <LogicalKeyboardKey>[
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
      ]) {
        await _press(tester, opening);
        expect(_open, isTrue);
        await _press(tester, LogicalKeyboardKey.enter);
        expect(state.value, 'b');
        expect(_open, isFalse);
      }
      expect(state.changes, 2);
      expect(state.calls(LogicalKeyboardKey.enter), 0);
      expect(state.calls(LogicalKeyboardKey.space), 0);
    });
  }

  for (final LogicalKeyboardKey opening in <LogicalKeyboardKey>[
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
  ]) {
    _test(
      'grouped select has the same edge contract in RTL: ${opening.keyLabel} (#313)',
      (tester) async {
        final GlobalKey<PickerKeyboardFixtureState> key =
            GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(
            PickerKeyboardFixture(
              key: key,
              kind: KeyboardPickerKind.select,
              grouped: true,
            ),
            direction: TextDirection.rtl,
          ),
        );
        final PickerKeyboardFixtureState state = key.currentState!;
        await _focusClosed(tester, state);
        await _press(tester, opening);
        await _press(tester, LogicalKeyboardKey.enter);
        expect(state.value, opening == LogicalKeyboardKey.arrowUp ? 'c' : 'a');
        expect(state.changes, 1);
        expect(state.calls(LogicalKeyboardKey.enter), 0);
      },
    );
  }

  for (final KeyboardPickerKind kind in KeyboardPickerKind.values) {
    _test('$kind ignores a retained key handler after disposal (#314)', (
      tester,
    ) async {
      final GlobalKey<PickerKeyboardFixtureState> key =
          GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: kind)),
      );
      final PickerKeyboardFixtureState state = key.currentState!;
      await _focusClosed(tester, state);
      final Focus field = tester
          .widgetList<Focus>(
            find.descendant(
              of: switch (kind) {
                KeyboardPickerKind.dropdown => find.byType(
                  CarbonDropdown<String>,
                ),
                KeyboardPickerKind.select => find.byType(CarbonSelect<String>),
                KeyboardPickerKind.combo => find.byType(CarbonComboBox<String>),
                KeyboardPickerKind.multi || KeyboardPickerKind.filteredMulti =>
                  find.byType(CarbonMultiSelect<String>),
              },
              matching: find.byType(Focus),
            ),
          )
          .firstWhere((widget) => widget.onKeyEvent != null);
      final FocusOnKeyEventCallback retained = field.onKeyEvent!;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(
        retained(
          state.focus,
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowDown,
            logicalKey: LogicalKeyboardKey.arrowDown,
            timeStamp: Duration.zero,
          ),
        ),
        KeyEventResult.ignored,
      );
    });

    _test('$kind leaves a stationary highlight key for the ancestor (#314)', (
      tester,
    ) async {
      final GlobalKey<PickerKeyboardFixtureState> key =
          GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: kind)),
      );
      final PickerKeyboardFixtureState state = key.currentState!;
      state.configure(
        choices: const <KeyboardChoice>[KeyboardChoice('b', 'Beta')],
      );
      await tester.pumpAndSettle();
      await _focusClosed(tester, state);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.arrowUp);
      expect(state.calls(LogicalKeyboardKey.arrowDown), 1);
      expect(state.calls(LogicalKeyboardKey.arrowUp), 1);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(state.changes, 1);
      expect(state.calls(LogicalKeyboardKey.enter), 0);
    });

    _test('$kind lets an actual dialog dismiss only after its popup (#314)', (
      tester,
    ) async {
      final GlobalKey<PickerKeyboardFixtureState> key =
          GlobalKey<PickerKeyboardFixtureState>();
      int dismissals = 0;
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
        ),
      );
      await tester.pumpAndSettle();
      final PickerKeyboardFixtureState state = key.currentState!;
      await _focusClosed(tester, state);
      expect(dismissals, 0);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      expect(_open, isTrue);
      await _press(tester, LogicalKeyboardKey.escape);
      expect(_open, isFalse);
      expect(dismissals, 0);
      await _press(tester, LogicalKeyboardKey.escape);
      expect(dismissals, 1);
      expect(state.changes, 0);
      expect(state.value, 'b');
    });

    _test(
      '$kind read-only keys reach ancestor actions without opening (#314)',
      (tester) async {
        final GlobalKey<PickerKeyboardFixtureState> key =
            GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind)),
        );
        final PickerKeyboardFixtureState state = key.currentState!;
        await _focusClosed(tester, state);
        state.configure(readOnly: true);
        await tester.pumpAndSettle();
        await _press(tester, LogicalKeyboardKey.enter);
        await _press(tester, LogicalKeyboardKey.escape);
        expect(state.calls(LogicalKeyboardKey.enter), 1);
        expect(state.calls(LogicalKeyboardKey.escape), 1);
        expect(state.changes, 0);
        expect(_open, isFalse);
      },
    );

    _test(
      '$kind dismisses a popup once, then lets the ancestor dismiss (#314)',
      (tester) async {
        final GlobalKey<PickerKeyboardFixtureState> key =
            GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind)),
        );
        final PickerKeyboardFixtureState state = key.currentState!;
        await _focusClosed(tester, state);
        await _press(tester, LogicalKeyboardKey.f8);
        expect(state.calls(LogicalKeyboardKey.f8), 1);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        expect(_open, isTrue);
        await _press(tester, LogicalKeyboardKey.escape);
        expect(_open, isFalse);
        expect(state.calls(LogicalKeyboardKey.escape), 0);
        await _press(tester, LogicalKeyboardKey.escape);
        expect(state.calls(LogicalKeyboardKey.escape), 1);
        expect(state.changes, 0);
        expect(state.value, 'b');
        expect(_open, isFalse);
      },
    );

    for (final String scenario in <String>[
      'empty',
      'all disabled',
      'live disabled highlight',
    ]) {
      _test(
        '$kind passes no-action Enter and arrows to the ancestor: $scenario (#314)',
        (tester) async {
          final GlobalKey<PickerKeyboardFixtureState> key =
              GlobalKey<PickerKeyboardFixtureState>();
          await tester.pumpWidget(
            _host(PickerKeyboardFixture(key: key, kind: kind)),
          );
          final PickerKeyboardFixtureState state = key.currentState!;
          if (scenario != 'live disabled highlight') {
            state.configure(
              choices: scenario == 'empty'
                  ? const <KeyboardChoice>[]
                  : const <KeyboardChoice>[
                      KeyboardChoice('a', 'Alpha', disabled: true),
                      KeyboardChoice('b', 'Beta', disabled: true),
                    ],
            );
          }
          await tester.pumpAndSettle();
          await _focusClosed(tester, state);
          await _press(tester, LogicalKeyboardKey.arrowDown);
          expect(_open, isTrue);
          if (scenario == 'live disabled highlight') {
            state.configure(
              choices: const <KeyboardChoice>[
                KeyboardChoice('a', 'Alpha', disabled: true),
                KeyboardChoice('b', 'Beta', disabled: true),
                KeyboardChoice('c', 'Charlie', disabled: true),
              ],
            );
            await tester.pumpAndSettle();
          }
          await _press(tester, LogicalKeyboardKey.enter);
          expect(state.calls(LogicalKeyboardKey.enter), 1);
          expect(state.changes, 0);
          expect(_open, isTrue);
          // Vertical movement in an editable single-line field may still be
          // claimed by Flutter's own text shortcuts; non-text triggers bubble.
          if (kind != KeyboardPickerKind.combo &&
              kind != KeyboardPickerKind.filteredMulti) {
            final int downBefore = state.calls(LogicalKeyboardKey.arrowDown);
            await _press(tester, LogicalKeyboardKey.arrowDown);
            await _press(tester, LogicalKeyboardKey.arrowUp);
            expect(state.calls(LogicalKeyboardKey.arrowDown), downBefore + 1);
            expect(state.calls(LogicalKeyboardKey.arrowUp), 1);
          }
        },
      );
    }

    _test(
      '$kind selects one highlighted option without submitting the ancestor (#314)',
      (tester) async {
        final GlobalKey<PickerKeyboardFixtureState> key =
            GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind)),
        );
        final PickerKeyboardFixtureState state = key.currentState!;
        await _focusClosed(tester, state);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        await _press(tester, LogicalKeyboardKey.enter);
        expect(state.changes, 1);
        expect(state.calls(LogicalKeyboardKey.enter), 0);
        expect(state.focus.hasPrimaryFocus, isTrue);
      },
    );
  }

  _test(
    'closed combo Enter submits without altering the committed value (#314)',
    (tester) async {
      final GlobalKey<PickerKeyboardFixtureState> key =
          GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: KeyboardPickerKind.combo)),
      );
      final PickerKeyboardFixtureState state = key.currentState!;
      await _focusClosed(tester, state);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(state.calls(LogicalKeyboardKey.enter), 1);
      expect(state.value, 'b');
      expect(state.changes, 0);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Beta',
      );
      expect(_open, isFalse);
    },
  );

  _test('combo focus from another control still opens after dismissal (#314)', (
    tester,
  ) async {
    final GlobalKey<PickerKeyboardFixtureState> key =
        GlobalKey<PickerKeyboardFixtureState>();
    final FocusNode other = FocusNode();
    try {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Focus(
                focusNode: other,
                child: const SizedBox(width: 40, height: 40),
              ),
              PickerKeyboardFixture(key: key, kind: KeyboardPickerKind.combo),
            ],
          ),
        ),
      );
      final PickerKeyboardFixtureState state = key.currentState!;
      await _focusClosed(tester, state);
      other.requestFocus();
      await tester.pumpAndSettle();
      expect(other.hasPrimaryFocus, isTrue);
      state.focus.requestFocus();
      await tester.pumpAndSettle();
      expect(_open, isTrue);
      expect(state.changes, 0);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      other.dispose();
    }
  });

  _test(
    'filtered combo Enter with no match submits without a free-text selection (#314)',
    (tester) async {
      final GlobalKey<PickerKeyboardFixtureState> key =
          GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: KeyboardPickerKind.combo)),
      );
      final PickerKeyboardFixtureState state = key.currentState!;
      await _focusClosed(tester, state);
      await tester.enterText(find.byType(EditableText), 'No matching choice');
      await tester.pumpAndSettle();
      expect(_open, isTrue);
      await _press(tester, LogicalKeyboardKey.enter);
      expect(state.calls(LogicalKeyboardKey.enter), 1);
      expect(state.changes, 0);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'No matching choice',
      );
    },
  );

  _test('closed combo ArrowUp does not claim an action (#314)', (tester) async {
    final GlobalKey<PickerKeyboardFixtureState> key =
        GlobalKey<PickerKeyboardFixtureState>();
    await tester.pumpWidget(
      _host(PickerKeyboardFixture(key: key, kind: KeyboardPickerKind.combo)),
    );
    final PickerKeyboardFixtureState state = key.currentState!;
    await _focusClosed(tester, state);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(state.calls(LogicalKeyboardKey.arrowUp), 1);
    expect(_open, isFalse);
  });

  _test(
    'filterable multi-select leaves Space to the query or ancestor (#314)',
    (tester) async {
      final GlobalKey<PickerKeyboardFixtureState> key =
          GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(
          PickerKeyboardFixture(
            key: key,
            kind: KeyboardPickerKind.filteredMulti,
          ),
        ),
      );
      final PickerKeyboardFixtureState state = key.currentState!;
      await _focusClosed(tester, state);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      await _press(tester, LogicalKeyboardKey.space);
      expect(state.calls(LogicalKeyboardKey.space), 1);
      expect(state.changes, 0);
      expect(_open, isTrue);
    },
  );
}
