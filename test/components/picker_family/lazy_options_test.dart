// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide/src/components/list_box/list_box_semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';
import '../../support/legibility.dart';
import '../../support/golden.dart';

enum _Kind { dropdown, select, combo, multi, filteredMulti }

String _label(int index) => index == 500 ? 'Zebra 500' : 'Option $index';
bool _disabled(int index) => index == 0 || index == 501 || index >= 998;

Widget _picker(
  _Kind kind, {
  required FocusNode focus,
  required ValueChanged<int> onChanged,
  int count = 1000,
  int? selected,
  bool fluid = false,
}) => switch (kind) {
  _Kind.dropdown => CarbonDropdown<int>(
    titleText: 'City',
    focusNode: focus,
    fluid: fluid,
    size: CarbonFieldSize.sm,
    selectedItem: selected,
    itemCount: count,
    itemBuilder: (int index) => CarbonDropdownItem<int>(
      value: index,
      label: _label(index),
      disabled: _disabled(index),
    ),
    onChanged: onChanged,
  ),
  _Kind.select => CarbonSelect<int>(
    labelText: 'City',
    focusNode: focus,
    fluid: fluid,
    size: CarbonFieldSize.sm,
    value: selected,
    itemCount: count,
    itemBuilder: (int index) => CarbonSelectItem<int>(
      value: index,
      label: _label(index),
      disabled: _disabled(index),
    ),
    onChanged: (int? value) => onChanged(value!),
  ),
  _Kind.combo => CarbonComboBox<int>(
    titleText: 'City',
    focusNode: focus,
    fluid: fluid,
    size: CarbonFieldSize.sm,
    selectedItem: selected,
    itemCount: count,
    itemBuilder: (int index) => CarbonComboBoxItem<int>(
      value: index,
      label: _label(index),
      disabled: _disabled(index),
    ),
    onChanged: (int? value) => onChanged(value!),
  ),
  _Kind.multi || _Kind.filteredMulti => CarbonMultiSelect<int>(
    titleText: 'Cities',
    label: 'Choose',
    focusNode: focus,
    filterable: kind == _Kind.filteredMulti,
    fluid: fluid,
    size: CarbonFieldSize.sm,
    selectedValues: <int>{?selected},
    itemCount: count,
    itemBuilder: (int index) => CarbonMultiSelectItem<int>(
      value: index,
      label: _label(index),
      disabled: _disabled(index),
    ),
    onChanged: (Set<int> values) => onChanged(values.last),
  ),
};

Widget _host(Widget child, TextDirection direction, double scale) =>
    Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) => Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 320, child: child),
                ),
              ),
            ],
          ),
        ),
      ),
    );

Finder get _options => find.byType(CarbonListBoxOptionSemantics);
Finder get _active => find.byWidgetPredicate(
  (Widget widget) => widget is CarbonListBoxOptionSemantics && widget.active,
);

Future<void> _open(WidgetTester tester, FocusNode focus) async {
  focus.requestFocus();
  await tester.pumpAndSettle();
  if (_options.evaluate().isEmpty) {
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
  }
}

void _boundedAndVisible(WidgetTester tester, String label) {
  expect(_options.evaluate().length, lessThanOrEqualTo(12));
  expect(_active, findsOneWidget);
  final CarbonListBoxOptionSemantics active = tester.widget(_active);
  expect(active.label, label);
  expect(active.disabled, isFalse);
  final Rect row = tester.getRect(_active);
  final Rect fold = tester.getRect(find.byType(Scrollable).last);
  expect(row.top, greaterThanOrEqualTo(fold.top - 0.01));
  expect(row.bottom, lessThanOrEqualTo(fold.bottom + 0.01));
}

void main() {
  for (final _Kind kind in _Kind.values) {
    for (final TextDirection direction in TextDirection.values) {
      for (final double scale in <double>[1.3, 2]) {
        for (final bool fluid in <bool>[false, true]) {
          testWidgets(
            '$kind mounts a bounded 1000-option window, $direction/$scale/fluid=$fluid',
            (tester) async {
              final FocusNode focus = FocusNode();
              addTearDown(focus.dispose);
              addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
              int? chosen;
              await tester.pumpWidget(
                _host(
                  _picker(
                    kind,
                    focus: focus,
                    fluid: fluid,
                    onChanged: (v) => chosen = v,
                  ),
                  direction,
                  scale,
                ),
              );
              await _open(tester, focus);
              _boundedAndVisible(tester, 'Option 1');
              expectNoClippedTextAtScale(tester, scale);
              expect(find.text('Option 997'), findsNothing);
              // Wrap to an option that has never mounted, skipping disabled tails.
              await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
              await tester.pumpAndSettle();
              _boundedAndVisible(tester, 'Option 997');
              expectNoClippedTextAtScale(tester, scale);
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pumpAndSettle();
              expect(chosen, 997);
              expect(focus.hasPrimaryFocus, isTrue);
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await tester.pumpAndSettle();
              expect(_options, findsNothing);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
    testWidgets('$kind searches metadata for a never-mounted option', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        final FocusNode focus = FocusNode();
        addTearDown(focus.dispose);
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        await tester.pumpWidget(
          _host(
            _picker(kind, focus: focus, onChanged: (_) {}),
            TextDirection.ltr,
            1,
          ),
        );
        await _open(tester, focus);
        expect(find.text('Zebra 500'), findsNothing);
        if (kind == _Kind.combo || kind == _Kind.filteredMulti) {
          await tester.enterText(find.byType(EditableText), 'Zebra');
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.keyZ, character: 'z');
        }
        await tester.pumpAndSettle();
        _boundedAndVisible(tester, 'Zebra 500');
        // Accessibility describes the logical data set without mounting it.
        final String hint = tester.semantics
            .simulatedAccessibilityTraversal()
            .singleWhere((node) => node.getSemanticsData().label == 'Zebra 500')
            .getSemanticsData()
            .hint;
        expect(
          hint,
          contains(
            kind == _Kind.combo || kind == _Kind.filteredMulti
                ? '1 of 1'
                : '501 of 1000',
          ),
        );
        if (kind != _Kind.combo && kind != _Kind.filteredMulti) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          _boundedAndVisible(tester, 'Option 502');
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        semantics.dispose();
      }
    });
    testWidgets('$kind handles an empty source and live shrinking', (
      tester,
    ) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final ValueNotifier<int> count = ValueNotifier<int>(1000);
      addTearDown(count.dispose);
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder<int>(
            valueListenable: count,
            builder: (_, value, _) =>
                _picker(kind, count: value, focus: focus, onChanged: (_) {}),
          ),
          TextDirection.ltr,
          1,
        ),
      );
      await _open(tester, focus);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      _boundedAndVisible(tester, 'Option 997');
      count.value = 3;
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_options.evaluate().length, lessThanOrEqualTo(3));
      count.value = 0;
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_options, findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'mixed-script lazy labels keep their complete scaled line boxes',
    (tester) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        _host(
          CarbonDropdown<int>(
            titleText: 'Languages',
            focusNode: focus,
            size: CarbonFieldSize.sm,
            itemCount: 1000,
            itemBuilder: (index) => CarbonDropdownItem<int>(
              value: index,
              label: '日本語 हिन्दी العربية gypy $index',
            ),
            onChanged: (_) {},
          ),
          TextDirection.rtl,
          2,
        ),
      );
      await _open(tester, focus);
      expect(_options.evaluate().length, lessThanOrEqualTo(12));
      expectNoClippedTextAtScale(tester, 2);
    },
  );
  for (final _Kind kind in <_Kind>[_Kind.dropdown, _Kind.select, _Kind.combo]) {
    testWidgets('$kind opens a fresh-model preselection below the fold', (
      tester,
    ) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        _host(
          _picker(kind, selected: 500, focus: focus, onChanged: (_) {}),
          TextDirection.ltr,
          2,
        ),
      );
      if (kind == _Kind.combo) {
        focus.requestFocus();
      } else {
        await tester.tap(find.text('Zebra 500'));
      }
      await tester.pumpAndSettle();
      _boundedAndVisible(tester, 'Zebra 500');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      _boundedAndVisible(tester, 'Option 502');
    });
  }
  test('builder APIs reject incomplete, conflicting and negative sources', () {
    expect(
      () => CarbonDropdown<int>(titleText: 'City', itemCount: 1),
      throwsAssertionError,
    );
    expect(
      () => CarbonSelect<int>(labelText: 'City', itemCount: 1),
      throwsAssertionError,
    );
    expect(
      () => CarbonComboBox<int>(titleText: 'City', itemCount: 1),
      throwsAssertionError,
    );
    expect(
      () => CarbonMultiSelect<int>(
        titleText: 'City',
        label: 'Choose',
        itemCount: 1,
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonDropdown<int>(
        titleText: 'City',
        itemCount: -1,
        itemBuilder: (i) => CarbonDropdownItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonSelect<int>(
        labelText: 'City',
        itemCount: -1,
        itemBuilder: (i) => CarbonSelectItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonComboBox<int>(
        titleText: 'City',
        itemCount: -1,
        itemBuilder: (i) => CarbonComboBoxItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonMultiSelect<int>(
        titleText: 'City',
        label: 'Choose',
        itemCount: -1,
        itemBuilder: (i) => CarbonMultiSelectItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonDropdown<int>(
        titleText: 'City',
        items: const [],
        itemCount: 1,
        itemBuilder: (i) => CarbonDropdownItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonSelect<int>(
        labelText: 'City',
        items: const [],
        itemCount: 1,
        itemBuilder: (i) => CarbonSelectItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonComboBox<int>(
        titleText: 'City',
        items: const [],
        itemCount: 1,
        itemBuilder: (i) => CarbonComboBoxItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
    expect(
      () => CarbonMultiSelect<int>(
        titleText: 'City',
        label: 'Choose',
        items: const [],
        itemCount: 1,
        itemBuilder: (i) => CarbonMultiSelectItem<int>(value: i, label: '$i'),
      ),
      throwsAssertionError,
    );
  });
  for (final _Kind kind in _Kind.values) {
    testWidgets('$kind lazy scaled popup goldens', (tester) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      await expectThemeGoldens(
        tester,
        name: 'lazy_${kind.name}_scaled_window',
        containsText: true,
        size: const Size(320, 520),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2)),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 288,
                    child: _picker(kind, focus: focus, onChanged: (_) {}),
                  ),
                ),
              ),
            ),
          ],
        ),
        afterPump: (tester) async {
          await _open(tester, focus);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          _boundedAndVisible(tester, 'Option 997');
          expectNoClippedTextAtScale(tester, 2);
        },
      );
    });
  }
}
