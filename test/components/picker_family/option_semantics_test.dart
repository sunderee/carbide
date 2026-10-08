// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui'
    show Tristate, ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:carbide/src/utils/anchored_overlay.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/overlay_entries.dart';
import '../../support/picker_keyboard_fixture.dart';

Widget _host(Widget child, TextDirection direction) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (_, _) => Directionality(
    textDirection: direction,
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (_) => Center(child: SizedBox(width: 360, child: child)),
          ),
        ],
      ),
    ),
  ),
);

Iterable<SemanticsNode> _nodes(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal();

SemanticsData _field(WidgetTester tester) => _nodes(tester).singleWhere((node) {
  final data = node.getSemanticsData();
  return data.label == 'Field' &&
      (data.flagsCollection.isTextField ||
          data.identifier.startsWith('carbide-control-'));
}).getSemanticsData();

SemanticsNode _option(WidgetTester tester, String label) =>
    _nodes(tester)
        .singleWhere((node) => node.getSemanticsData().label == label);

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _focusClosed(
  WidgetTester tester,
  PickerKeyboardFixtureState state,
) async {
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  state.focus.requestFocus();
  await tester.pumpAndSettle();
  if (find.byType(CarbonAnchoredOverlay).evaluate().isNotEmpty) {
    await _press(tester, LogicalKeyboardKey.escape);
  }
}

void _test(String name, WidgetTesterCallback body) {
  testWidgets(name, (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      semantics.dispose();
    }
  });
}

void _expectActive(WidgetTester tester, String label, int position, int count) {
  final String hint = 'Active option: $label, $position of $count';
  expect(_field(tester).hint, hint);
  expect(_option(tester, label).getSemanticsData().hint, hint);
  final List<SemanticsData> live = _nodes(tester)
      .map((node) => node.getSemanticsData())
      .where((data) => data.flagsCollection.isLiveRegion && data.label == hint)
      .toList();
  expect(live, hasLength(1));
  expect(live.single.hasAction(SemanticsAction.tap), isFalse);
  expect(live.single.flagsCollection.isFocused, Tristate.none);
}

void main() {
  for (final KeyboardPickerKind kind in KeyboardPickerKind.values) {
    _test('$kind localizes and updates the active-option phrase live', (
      tester,
    ) async {
      final key = GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: kind), TextDirection.ltr),
      );
      final state = key.currentState!;
      await _focusClosed(tester, state);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      state.configure(
        activeOptionFormatter: (label, position, count) =>
            'Option active : $label ($position/$count)',
      );
      await tester.pumpAndSettle();
      final int index = kind == KeyboardPickerKind.combo ? 1 : 0;
      final String label = keyboardChoices[index].label;
      final String phrase = 'Option active : $label (${index + 1}/3)';
      expect(_field(tester).hint, phrase);
      expect(_option(tester, label).getSemanticsData().hint, phrase);
      expect(
        _nodes(tester).where(
          (node) =>
              node.getSemanticsData().flagsCollection.isLiveRegion &&
              node.label == phrase,
        ),
        hasLength(1),
      );
      expect(state.focus.hasPrimaryFocus, isTrue);
      expect(state.changes, 0);
    });

    _test('$kind removes a stale active announcement on policy/item changes', (
      tester,
    ) async {
      final key = GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: kind), TextDirection.ltr),
      );
      final state = key.currentState!;
      await _focusClosed(tester, state);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      state.configure(
        choices: const <KeyboardChoice>[
          KeyboardChoice('a', 'Alpha', disabled: true),
          KeyboardChoice('b', 'Beta', disabled: true),
          KeyboardChoice('c', 'Charlie', disabled: true),
        ],
      );
      await tester.pumpAndSettle();
      expect(_field(tester).hint, isEmpty);
      expect(
        _nodes(tester).where(
          (node) =>
              node.getSemanticsData().flagsCollection.isLiveRegion &&
              node.label.isNotEmpty,
        ),
        isEmpty,
      );
      await _press(tester, LogicalKeyboardKey.enter);
      expect(state.changes, 0);
      expect(state.calls(LogicalKeyboardKey.enter), 1);
      state.configure(choices: const <KeyboardChoice>[]);
      await tester.pumpAndSettle();
      expect(_field(tester).hint, isEmpty);
      state.configure(readOnly: true);
      await tester.pumpAndSettle();
      expect(_field(tester).flagsCollection.isExpanded, Tristate.isFalse);
      expect(_field(tester).hint, 'Read only');
      expect(state.changes, 0);
    });

    _test('$kind ignores retained option actions after disable/disposal', (
      tester,
    ) async {
      final key = GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: kind), TextDirection.ltr),
      );
      final state = key.currentState!;
      await _focusClosed(tester, state);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      final VoidCallback activate = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere(
            (widget) =>
                widget.properties.label == 'Charlie' && widget.excludeSemantics,
          )
          .properties
          .onTap!;
      state.configure(
        choices: const <KeyboardChoice>[
          KeyboardChoice('a', 'Alpha'),
          KeyboardChoice('b', 'Beta'),
          KeyboardChoice('c', 'Charlie', disabled: true),
        ],
      );
      await tester.pumpAndSettle();
      activate();
      await tester.pumpAndSettle();
      expect(state.changes, 0);
      await _press(tester, LogicalKeyboardKey.escape);
      activate();
      await tester.pumpAndSettle();
      expect(state.changes, 0);
      expect(tester.takeException(), isNull);
    });

    _test('$kind keeps duplicate labels as distinct selected/active options', (
      tester,
    ) async {
      final key = GlobalKey<PickerKeyboardFixtureState>();
      await tester.pumpWidget(
        _host(PickerKeyboardFixture(key: key, kind: kind), TextDirection.ltr),
      );
      final state = key.currentState!;
      state.configure(
        choices: const <KeyboardChoice>[
          KeyboardChoice('a', 'Same'),
          KeyboardChoice('b', 'Same', disabled: true),
          KeyboardChoice('c', 'Other'),
        ],
        clearValue: true,
      );
      await tester.pumpAndSettle();
      state.configure(value: 'b');
      await tester.pumpAndSettle();
      await _focusClosed(tester, state);
      await _press(tester, LogicalKeyboardKey.arrowDown);
      final same = _nodes(tester)
          .where((node) => node.label == 'Same')
          .map((node) => node.getSemanticsData())
          .toList();
      expect(same, hasLength(2));
      expect(
        same.where(
          (data) => data.flagsCollection.isSelected == Tristate.isTrue,
        ),
        hasLength(1),
      );
      expect(
        same.where((data) => data.hint == 'Active option: Same, 1 of 3'),
        hasLength(1),
      );
      expect(
        same.where(
          (data) => data.flagsCollection.isEnabled == Tristate.isFalse,
        ),
        hasLength(1),
      );
      await _press(tester, LogicalKeyboardKey.arrowDown);
      _expectActive(tester, 'Other', 3, 3);
      expect(state.changes, 0);
    });
  }

  for (final KeyboardPickerKind kind in <KeyboardPickerKind>[
    KeyboardPickerKind.combo,
    KeyboardPickerKind.filteredMulti,
  ]) {
    for (final TextDirection direction in TextDirection.values) {
      _test(
        '$kind describes filtered position without replacing query, $direction',
        (tester) async {
          final key = GlobalKey<PickerKeyboardFixtureState>();
          await tester.pumpWidget(
            _host(PickerKeyboardFixture(key: key, kind: kind), direction),
          );
          final state = key.currentState!;
          await _focusClosed(tester, state);
          await tester.enterText(find.byType(EditableText), 'Ch');
          await tester.pumpAndSettle();
          _expectActive(tester, 'Charlie', 1, 1);
          expect(_field(tester).value, 'Ch');
          expect(state.changes, 0);
          await tester.enterText(find.byType(EditableText), 'Missing');
          await tester.pumpAndSettle();
          expect(_field(tester).hint, isEmpty);
          expect(_field(tester).value, 'Missing');
          expect(
            _nodes(tester).where(
              (node) =>
                  node.getSemanticsData().flagsCollection.isLiveRegion &&
                  node.label.isNotEmpty,
            ),
            isEmpty,
          );
          expect(state.focus.hasPrimaryFocus, isTrue);
          expect(state.changes, 0);
        },
      );
    }
  }

  for (final TextDirection direction in TextDirection.values) {
    for (final KeyboardPickerKind kind in KeyboardPickerKind.values) {
      _test('$kind exposes expanded on its value trigger, $direction (#311)', (
        tester,
      ) async {
        final key = GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind), direction),
        );
        final state = key.currentState!;
        await _focusClosed(tester, state);
        expect(_field(tester).flagsCollection.isExpanded, Tristate.isFalse);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        expect(_field(tester).flagsCollection.isExpanded, Tristate.isTrue);
        await _press(tester, LogicalKeyboardKey.escape);
        expect(_field(tester).flagsCollection.isExpanded, Tristate.isFalse);
        expect(_field(tester).hint, isEmpty);
        expect(state.changes, 0);
      });

      _test('$kind announces navigation before commitment, $direction (#311)', (
        tester,
      ) async {
        final key = GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind), direction),
        );
        final state = key.currentState!;
        await _focusClosed(tester, state);
        final String value = _field(tester).value;
        await _press(tester, LogicalKeyboardKey.arrowDown);
        final int first = kind == KeyboardPickerKind.combo ? 1 : 0;
        _expectActive(tester, keyboardChoices[first].label, first + 1, 3);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        final int next = (first + 1) % 3;
        _expectActive(tester, keyboardChoices[next].label, next + 1, 3);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        final int last = (first + 2) % 3;
        _expectActive(tester, keyboardChoices[last].label, last + 1, 3);
        await _press(tester, LogicalKeyboardKey.arrowUp);
        _expectActive(tester, keyboardChoices[next].label, next + 1, 3);
        expect(_field(tester).value, value);
        expect(state.value, 'b');
        expect(state.selected, <String>{'b'});
        expect(state.changes, 0);
        expect(state.focus.hasPrimaryFocus, isTrue);
        final nodes = <SemanticsData>[
          for (final choice in keyboardChoices)
            _option(tester, choice.label).getSemanticsData(),
        ];
        expect(nodes.map((data) => data.flagsCollection.isSelected), <Tristate>[
          Tristate.isFalse,
          Tristate.isTrue,
          Tristate.isFalse,
        ]);
        // List-box rows are 40px in upstream _list-box.scss.
        await expectA11y(tester, tapTargets: false);
      });

      _test('$kind distinguishes disabled and active rows, $direction (#311)', (
        tester,
      ) async {
        final key = GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind), direction),
        );
        final state = key.currentState!;
        state.configure(
          choices: const <KeyboardChoice>[
            KeyboardChoice('a', 'Alpha'),
            KeyboardChoice('b', 'Beta', disabled: true),
            KeyboardChoice('c', 'Charlie'),
          ],
        );
        await tester.pumpAndSettle();
        await _focusClosed(tester, state);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        _expectActive(tester, 'Charlie', 3, 3);
        final disabled = _option(tester, 'Beta').getSemanticsData();
        expect(disabled.flagsCollection.isEnabled, Tristate.isFalse);
        expect(disabled.flagsCollection.isSelected, Tristate.isTrue);
        expect(disabled.hasAction(SemanticsAction.tap), isFalse);
        expect(disabled.hint, isEmpty);
        expect(_option(tester, 'Alpha').getSemanticsData().hint, isEmpty);
        expect(state.changes, 0);
      });

      _test('$kind disabled-row pointer retains trigger focus, $direction', (
        tester,
      ) async {
        final key = GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind), direction),
        );
        final state = key.currentState!;
        state.configure(
          choices: const <KeyboardChoice>[
            KeyboardChoice('a', 'Alpha'),
            KeyboardChoice('b', 'Beta', disabled: true),
            KeyboardChoice('c', 'Charlie'),
          ],
        );
        await tester.pumpAndSettle();
        await _focusClosed(tester, state);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        final Finder row = find.descendant(
          of: find.byType(CarbonAnchoredOverlay),
          matching: find.text('Beta'),
        );
        await tester.tapAt(tester.getCenter(row));
        await tester.pumpAndSettle();
        expect(state.changes, 0);
        expect(state.focus.hasPrimaryFocus, isTrue);
        expect(_field(tester).flagsCollection.isExpanded, Tristate.isTrue);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        _expectActive(tester, 'Charlie', 3, 3);
      });

      _test('$kind exposes exactly one actionable row, $direction (#311)', (
        tester,
      ) async {
        final key = GlobalKey<PickerKeyboardFixtureState>();
        await tester.pumpWidget(
          _host(PickerKeyboardFixture(key: key, kind: kind), direction),
        );
        final state = key.currentState!;
        await _focusClosed(tester, state);
        await _press(tester, LogicalKeyboardKey.arrowDown);
        final option = _option(tester, 'Charlie');
        expect(
          option.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
        );
        tester
            .renderObject(find.bySemanticsLabel('Charlie'))
            .owner!
            .semanticsOwner!
            .performAction(option.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(state.changes, 1);
        if (kind == KeyboardPickerKind.multi ||
            kind == KeyboardPickerKind.filteredMulti) {
          expect(state.selected, <String>{'b', 'c'});
        } else {
          expect(state.value, 'c');
        }
      });
    }

    for (final KeyboardPickerKind kind in <KeyboardPickerKind>[
      KeyboardPickerKind.multi,
      KeyboardPickerKind.filteredMulti,
    ]) {
      for (final double fraction in <double>[0.07, 0.5, 0.93]) {
        _test('$kind full-row pointer toggles once at $fraction, $direction', (
          tester,
        ) async {
          final key = GlobalKey<PickerKeyboardFixtureState>();
          await tester.pumpWidget(
            _host(PickerKeyboardFixture(key: key, kind: kind), direction),
          );
          final state = key.currentState!;
          await _focusClosed(tester, state);
          await _press(tester, LogicalKeyboardKey.arrowDown);
          final Rect row = tester.getRect(
            find.ancestor(
              of: find.text('Charlie'),
              matching: find.byType(CarbonListBoxMenuItem),
            ),
          );
          await tester.tapAt(
            Offset(row.left + row.width * fraction, row.center.dy),
          );
          await tester.pumpAndSettle();
          expect(state.selected, <String>{'b', 'c'});
          expect(state.changes, 1);
          await tester.tapAt(
            Offset(row.left + row.width * fraction, row.center.dy),
          );
          await tester.pumpAndSettle();
          expect(state.selected, <String>{'b'});
          expect(state.changes, 2);
        });
      }
    }
  }
}
