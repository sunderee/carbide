// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('focus and unchanged submission do not report value changes', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    final EditableText input = tester.widget<EditableText>(
      find.byType(EditableText),
    );
    input.focusNode.requestFocus();
    await tester.pumpAndSettle();
    input.onSubmitted!('40');
    state.outside.requestFocus();
    await tester.pumpAndSettle();
    expect(state.lowerChanges, isEmpty);

    input.focusNode.requestFocus();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '45');
    input.onSubmitted!('45');
    await tester.pump();
    expect(state.lowerChanges, <num>[45]);
    state.outside.requestFocus();
    await tester.pumpAndSettle();
    expect(state.lowerChanges, <num>[45]);
  });

  for (final TextDirection direction in TextDirection.values) {
    for (final bool range in <bool>[false, true]) {
      for (final (String name, bool disabled, bool readOnly, bool callback)
          in <(String, bool, bool, bool)>[
            ('editable', false, false, true),
            ('disabled', true, false, true),
            ('read-only', false, true, true),
            ('both', true, true, true),
            ('no callback', false, false, false),
            ('read-only no callback', false, true, false),
          ]) {
        testWidgets('$name range=$range $direction gates every interaction', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          try {
            final _FixtureState state = await _mount(
              tester,
              range: range,
              direction: direction,
            );
            state.configure(
              disabled: disabled,
              readOnly: readOnly,
              callback: callback,
            );
            await tester.pumpAndSettle();
            final bool enabled = !disabled && !readOnly && callback;
            final bool focusable = !disabled && callback;
            final Rect rect = _track(tester);
            await tester.tapAt(
              Offset(rect.left + rect.width * .25, rect.center.dy),
            );
            await tester.dragFrom(rect.center, const Offset(70, 0));
            if (range) {
              await tester.tapAt(
                Offset(rect.left + rect.width * .8, rect.center.dy),
              );
            }
            await tester.pumpAndSettle();
            if (enabled) {
              expect(state.lowerChanges, isNotEmpty);
            } else {
              expect(state.lowerChanges, isEmpty);
              expect(state.upperChanges, isEmpty);
              expect(state.value, 40);
              expect(state.upper, 70);
            }
            for (int i = 0; i < (range ? 2 : 1); i++) {
              final FocusNode focus = _thumbFocus(tester, i);
              expect(focus.canRequestFocus, focusable);
              focus.requestFocus();
              await tester.pumpAndSettle();
              expect(focus.hasFocus, focusable);
              for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
                LogicalKeyboardKey.arrowLeft,
                LogicalKeyboardKey.arrowRight,
                LogicalKeyboardKey.arrowUp,
                LogicalKeyboardKey.arrowDown,
                LogicalKeyboardKey.home,
                LogicalKeyboardKey.end,
                LogicalKeyboardKey.pageUp,
                LogicalKeyboardKey.pageDown,
              ]) {
                await tester.sendKeyEvent(key);
                await tester.pump();
              }
              final SemanticsNode node = tester.getSemantics(
                find.byType(AnimatedScale).at(i),
              );
              expect(
                node,
                isSemantics(
                  isSlider: true,
                  isEnabled: enabled,
                  hint: focusable && readOnly ? 'Nur lesen' : '',
                ),
              );
              if (!enabled) {
                expect(
                  node.getSemanticsData().hasAction(
                    ui.SemanticsAction.increase,
                  ),
                  isFalse,
                );
                expect(
                  node.getSemanticsData().hasAction(
                    ui.SemanticsAction.decrease,
                  ),
                  isFalse,
                );
              }
              _semanticsOwner(tester)
                  .performAction(node.id, ui.SemanticsAction.increase);
              _semanticsOwner(tester)
                  .performAction(node.id, ui.SemanticsAction.decrease);
              await tester.pump();
            }
            if (!range) {
              final EditableText input = tester.widget<EditableText>(
                find.byType(EditableText),
              );
              expect(input.readOnly, !enabled);
              expect(input.focusNode.canRequestFocus, focusable);
              // Exercise a late submission even if the native editor has
              // already become read-only or lost its input connection.
              input.controller.text = '90';
              input.onSubmitted!('90');
              await tester.pump();
            }
            if (!enabled) {
              expect(state.lowerChanges, isEmpty);
              expect(state.upperChanges, isEmpty);
              expect(state.value, 40);
              expect(state.upper, 70);
            } else {
              expect(state.value, inInclusiveRange(0, 100));
              if (range) {
                expect(state.upper, inInclusiveRange(state.value, 100));
              }
            }
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            handle.dispose();
          }
        });
      }
    }
  }

  for (final bool readOnly in <bool>[false, true]) {
    testWidgets(
      'changing policy mid-drag blocks later events, readOnly=$readOnly',
      (WidgetTester tester) async {
        final _FixtureState state = await _mount(tester, range: true);
        final Rect rect = _track(tester);
        final TestGesture gesture = await tester.startGesture(
          Offset(rect.left + rect.width * .8, rect.center.dy),
        );
        await gesture.moveBy(const Offset(-10, 0));
        await tester.pump();
        state.configure(disabled: !readOnly, readOnly: readOnly);
        await tester.pump();
        state.lowerChanges.clear();
        state.upperChanges.clear();
        final num value = state.value;
        final num upper = state.upper;
        await gesture.moveBy(const Offset(-70, 0));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(state.lowerChanges, isEmpty);
        expect(state.upperChanges, isEmpty);
        expect(state.value, value);
        expect(state.upper, upper);
      },
    );

    testWidgets(
      'changing policy with a draft blocks submit and blur, readOnly=$readOnly',
      (WidgetTester tester) async {
        final _FixtureState state = await _mount(tester);
        await tester.enterText(find.byType(EditableText), '90');
        final ValueChanged<String> lateSubmit = tester
            .widget<EditableText>(find.byType(EditableText))
            .onSubmitted!;
        state.configure(disabled: !readOnly, readOnly: readOnly);
        await tester.pumpAndSettle();
        lateSubmit('90');
        state.outside.requestFocus();
        await tester.pumpAndSettle();
        expect(state.lowerChanges, isEmpty);
        expect(state.value, 40);
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          '40',
        );
      },
    );

    testWidgets(
      'a stale semantics action cannot bypass a new policy, readOnly=$readOnly',
      (WidgetTester tester) async {
        final _FixtureState state = await _mount(tester, range: true);
        final List<VoidCallback> callbacks = <VoidCallback>[
          for (int i = 0; i < 2; i++)
            tester
                .widget<Semantics>(
                  find
                      .ancestor(
                        of: find.byType(AnimatedScale).at(i),
                        matching: find.byType(Semantics),
                      )
                      .first,
                )
                .properties
                .onIncrease!,
        ];
        state.configure(disabled: !readOnly, readOnly: readOnly);
        await tester.pump();
        for (final VoidCallback callback in callbacks) {
          callback();
        }
        await tester.pump();
        expect(state.lowerChanges, isEmpty);
        expect(state.upperChanges, isEmpty);
      },
    );
  }

  testWidgets('semantics adjusts both handles and stops at their bounds', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      final _FixtureState state = await _mount(tester, range: true);
      Future<void> adjust(int thumb, ui.SemanticsAction action) async {
        final SemanticsNode node = tester.getSemantics(
          find.byType(AnimatedScale).at(thumb),
        );
        expect(node.getSemanticsData().hasAction(action), isTrue);
        _semanticsOwner(tester).performAction(node.id, action);
        await tester.pump();
      }

      await adjust(0, ui.SemanticsAction.increase);
      expect(state.value, 45);
      await adjust(1, ui.SemanticsAction.decrease);
      expect(state.upper, 65);
      for (int i = 0; i < 4; i++) {
        await adjust(0, ui.SemanticsAction.increase);
      }
      expect(state.value, state.upper);
      final SemanticsData lower = tester
          .getSemantics(find.byType(AnimatedScale).first)
          .getSemanticsData();
      final SemanticsData upper = tester
          .getSemantics(find.byType(AnimatedScale).last)
          .getSemanticsData();
      expect(lower.hasAction(ui.SemanticsAction.increase), isFalse);
      expect(upper.hasAction(ui.SemanticsAction.decrease), isFalse);
      expect(lower.decreasedValue, '60');
      expect(upper.increasedValue, '70');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      handle.dispose();
    }
  });
}

Future<_FixtureState> _mount(
  WidgetTester tester, {
  bool range = false,
  TextDirection direction = TextDirection.ltr,
}) async {
  final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    Directionality(
      textDirection: direction,
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: 400,
            child: _Fixture(key: key, range: range),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

class _Fixture extends StatefulWidget {
  const _Fixture({super.key, required this.range});
  final bool range;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  num value = 40;
  num upper = 70;
  bool disabled = false;
  bool readOnly = false;
  bool callback = true;
  final FocusNode outside = FocusNode();
  final List<num> lowerChanges = <num>[];
  final List<num> upperChanges = <num>[];
  void configure({bool? disabled, bool? readOnly, bool? callback}) =>
      setState(() {
        this.disabled = disabled ?? this.disabled;
        this.readOnly = readOnly ?? this.readOnly;
        this.callback = callback ?? this.callback;
      });
  @override
  void dispose() {
    outside.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      CarbonSlider(
        labelText: 'Volume',
        value: value,
        upperValue: widget.range ? upper : null,
        min: 0,
        max: 100,
        step: 5,
        disabled: disabled,
        readOnly: readOnly,
        readOnlyHint: 'Nur lesen',
        onChanged: !callback
            ? null
            : (num next) {
                lowerChanges.add(next);
                setState(() => value = next);
              },
        onUpperChanged: !widget.range
            ? null
            : (num next) {
                upperChanges.add(next);
                setState(() => upper = next);
              },
      ),
      Focus(focusNode: outside, child: const Text('Outside')),
    ],
  );
}

Rect _track(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(CarbonSlider),
        matching: find.byType(GestureDetector),
      )
      .first,
);

FocusNode _thumbFocus(WidgetTester tester, int i) => tester
    .widget<Focus>(
      find
          .ancestor(
            of: find.byType(AnimatedScale).at(i),
            matching: find.byType(Focus),
          )
          .first,
    )
    .focusNode!;

SemanticsOwner _semanticsOwner(WidgetTester tester) => tester
    .renderObject(find.byType(AnimatedScale).first)
    .owner!
    .semanticsOwner!;
