// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double scale = 1}) => WidgetsApp(
  color: const Color(0xffffffff),
  builder: (BuildContext context, Widget? _) => MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Center(child: SizedBox(width: 340, child: child)),
    ),
  ),
);

TextEditingController _controller(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller;

Finder _icon(CarbonIconData icon) => find.byWidgetPredicate(
  (Widget widget) => widget is CarbonIcon && widget.icon == icon,
);

void main() {
  testWidgets(
    'a focused draft survives focus-node replacement and unrelated rebuilds',
    (WidgetTester tester) async {
      try {
        final FocusNode a = FocusNode();
        final FocusNode b = FocusNode();
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        FocusNode focus = a;
        bool warning = false;
        num value = 5;
        late StateSetter update;
        final List<num?> changes = <num?>[];
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                update = setState;
                return CarbonNumberInput(
                  labelText: 'Quantity',
                  value: value,
                  focusNode: focus,
                  warn: warning,
                  max: 10,
                  onChanged: changes.add,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        a.requestFocus();
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), '99');
        expect(a.hasFocus, isTrue);
        update(() {
          focus = b;
          warning = true;
        });
        await tester.pumpAndSettle();
        expect(b.hasFocus, isTrue);
        expect(_controller(tester).text, '99');
        expect(changes, isEmpty);
        update(() => value = 6);
        await tester.pump();
        expect(_controller(tester).text, '6');
        b.unfocus();
        await tester.pumpAndSettle();
        expect(changes, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('Tab into a stepper retains the draft until activation', (
    WidgetTester tester,
  ) async {
    final List<num?> changes = <num?>[];
    await tester.pumpWidget(
      _host(
        CarbonNumberInput(
          labelText: 'Quantity',
          value: 5,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '-');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(changes, isEmpty);
    expect(_controller(tester).text, '-');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, <num?>[4]);
    expect(_controller(tester).text, '4');
  });

  for (final bool disabled in <bool>[true, false]) {
    testWidgets(
      '${disabled ? 'disabled' : 'read-only'} blocks every commit action',
      (WidgetTester tester) async {
        final List<num?> changes = <num?>[];
        final FocusNode focus = FocusNode();
        addTearDown(focus.dispose);
        await tester.pumpWidget(
          _host(
            CarbonNumberInput(
              labelText: 'Quantity',
              value: 5,
              disabled: disabled,
              readOnly: !disabled,
              focusNode: focus,
              onChanged: changes.add,
            ),
          ),
        );
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.tap(_icon(CarbonIcons.add));
        focus.unfocus();
        await tester.pumpAndSettle();
        expect(_controller(tester).text, '5');
        expect(changes, isEmpty);
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).readOnly,
          isTrue,
        );
      },
    );
  }

  for (final double value in <double>[1e308, -1e308]) {
    testWidgets(
      'an overflowing step from $value cannot report infinity or reverse direction',
      (WidgetTester tester) async {
        final List<num?> changes = <num?>[];
        await tester.pumpWidget(
          _host(
            CarbonNumberInput(
              labelText: 'Quantity',
              value: value,
              step: 1e308,
              onChanged: changes.add,
            ),
          ),
        );
        await tester.showKeyboard(find.byType(EditableText));
        await tester.sendKeyEvent(
          value > 0 ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowDown,
        );
        await tester.pump();
        expect(_controller(tester).text, value.toString());
        expect(changes, isEmpty);
      },
    );
  }

  testWidgets(
    'IME candidate navigation does not commit or step composing drafts',
    (WidgetTester tester) async {
      final List<num?> changes = <num?>[];
      await tester.pumpWidget(
        _host(
          CarbonNumberInput(
            labelText: 'Quantity',
            value: 5,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      const TextEditingValue composing = TextEditingValue(
        text: '1e',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      );
      tester.testTextInput.updateEditingValue(composing);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(changes, isEmpty);
      expect(_controller(tester).text, '1e');
      expect(_controller(tester).value.composing, composing.composing);
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pumpAndSettle();
      expect(changes, <num?>[5]);
      expect(_controller(tester).text, '5');
      expect(_controller(tester).value.composing, TextRange.empty);
    },
  );

  for (final (num? min, num? max, num? value) in <(num?, num?, num?)>[
    (10, 0, 5),
    (double.nan, null, 5),
    (null, double.infinity, 5),
    (null, null, double.nan),
  ]) {
    test('invalid bounds/value ($min, $max, $value) fail early', () {
      expect(
        () => CarbonNumberInput(
          labelText: 'Quantity',
          min: min,
          max: max,
          value: value,
        ),
        throwsAssertionError,
      );
    });
  }
  for (final String draft in <String>[
    '-',
    '.',
    '1e',
    '',
    'not a number',
    '-9',
    '99',
    'NaN',
    'Infinity',
    '0003.50',
  ]) {
    for (final bool allowEmpty in <bool>[false, true]) {
      for (final bool blur in <bool>[false, true]) {
        testWidgets(
          'draft "$draft" allowEmpty=$allowEmpty commits on ${blur ? 'blur' : 'Enter'}',
          (WidgetTester tester) async {
            final FocusNode focus = FocusNode();
            addTearDown(focus.dispose);
            final List<num?> changes = <num?>[];
            num? value = 5;
            await tester.pumpWidget(
              _host(
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) =>
                      CarbonNumberInput(
                        labelText: 'Quantity',
                        value: value,
                        min: 0,
                        max: 10,
                        allowEmpty: allowEmpty,
                        focusNode: focus,
                        onChanged: (num? next) {
                          changes.add(next);
                          setState(() => value = next);
                        },
                      ),
                ),
              ),
            );
            await tester.enterText(find.byType(EditableText), draft);
            await tester.pump();
            expect(changes, isEmpty);
            expect(value, 5);
            expect(_controller(tester).text, draft);
            if (blur) {
              focus.unfocus();
            } else {
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            }
            await tester.pumpAndSettle();
            final num? expected = switch (draft) {
              '' => allowEmpty ? null : 0,
              '-9' => 0,
              '99' => 10,
              '0003.50' => 3.5,
              _ => 5,
            };
            expect(changes, <num?>[expected]);
            expect(value, expected);
            expect(_controller(tester).text, expected?.toString() ?? '');
            expect(_controller(tester).value.composing, TextRange.empty);
            if (!blur) {
              expect(focus.hasFocus, isTrue);
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              focus.unfocus();
              await tester.pumpAndSettle();
              expect(changes, <num?>[expected]);
            }
          },
        );
      }
    }
  }

  testWidgets('the editing-complete action commits a draft once', (
    WidgetTester tester,
  ) async {
    final List<num?> changes = <num?>[];
    await tester.pumpWidget(
      _host(
        CarbonNumberInput(
          labelText: 'Quantity',
          value: 5,
          max: 10,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(changes, <num?>[10]);
    expect(_controller(tester).text, '10');
  });

  for (final String draft in <String>['-', '', '-9', '99', '5.5']) {
    for (final bool keyboard in <bool>[false, true]) {
      testWidgets(
        '${keyboard ? 'arrow' : 'pointer stepper'} commits "$draft" once before stepping',
        (WidgetTester tester) async {
          final List<num?> changes = <num?>[];
          await tester.pumpWidget(
            _host(
              CarbonNumberInput(
                labelText: 'Quantity',
                value: 5,
                min: 0,
                max: 10,
                onChanged: changes.add,
              ),
            ),
          );
          await tester.enterText(find.byType(EditableText), draft);
          await tester.pump();
          expect(changes, isEmpty);
          if (keyboard) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          } else {
            await tester.tap(_icon(CarbonIcons.add));
          }
          await tester.pumpAndSettle();
          final num expected = switch (draft) {
            '-' => 6,
            '' || '-9' => 1,
            '99' => 10,
            _ => 6.5,
          };
          expect(changes, <num?>[expected]);
          expect(_controller(tester).text, expected.toString());
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('empty coercion respects a maximum below zero', (
    WidgetTester tester,
  ) async {
    final List<num?> changes = <num?>[];
    await tester.pumpWidget(
      _host(
        CarbonNumberInput(
          labelText: 'Quantity',
          value: -5,
          max: -2,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_controller(tester).text, '-2');
    expect(changes, <num?>[-2]);
  });

  for (final bool fluid in <bool>[false, true]) {
    for (final (bool invalid, bool warning) in <(bool, bool)>[
      (false, true),
      (true, false),
      (true, true),
    ]) {
      testWidgets(
        'shared chrome fluid=$fluid invalid=$invalid warning=$warning',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _host(
              CarbonNumberInput(
                labelText: 'Quantity',
                value: 5,
                fluid: fluid,
                invalid: invalid,
                warn: warning,
                invalidText: 'Invalid',
                warnText: 'Warning',
              ),
            ),
          );
          final CarbonField field = tester.widget<CarbonField>(
            find.byType(CarbonField),
          );
          expect(
            field.status,
            invalid ? CarbonFieldStatus.invalid : CarbonFieldStatus.warning,
          );
          expect(field.fluid, fluid);
          expect(
            _icon(
              invalid ? CarbonIcons.errorFilled : CarbonIcons.warningAltFilled,
            ),
            findsOneWidget,
          );
          expect(
            _icon(
              invalid ? CarbonIcons.warningAltFilled : CarbonIcons.errorFilled,
            ),
            findsNothing,
          );
          expect(find.text(invalid ? 'Invalid' : 'Warning'), findsOneWidget);
          expect(find.text(invalid ? 'Warning' : 'Invalid'), findsNothing);
        },
      );
    }
  }

  for (final double scale in <double>[1, 2, 3]) {
    testWidgets(
      'fluid with a hidden label stays fluid and scales at ${scale}x',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _host(
            const CarbonNumberInput(
              labelText: 'Quantity',
              value: 5,
              fluid: true,
              hideLabel: true,
            ),
            scale: scale,
          ),
        );
        final CarbonField field = tester.widget<CarbonField>(
          find.byType(CarbonField),
        );
        expect(field.fluid, isTrue);
        expect(
          tester.getSize(find.byType(CarbonField)).height,
          greaterThanOrEqualTo(64),
        );
        expect(find.text('Quantity'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('the semantic field value contains one copy of the draft', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(const CarbonNumberInput(labelText: 'Quantity', value: 5)),
      );
      await tester.enterText(find.byType(EditableText), '1e');
      await tester.pump();
      final SemanticsData field = tester
          .getSemantics(find.bySemanticsLabel('Quantity'))
          .getSemanticsData();
      expect(field.value, '1e');
      expect(field.flagsCollection.isTextField, isTrue);
    } finally {
      handle.dispose();
    }
  });

  for (final num step in <num>[0, -1, double.nan, double.infinity]) {
    test('step $step fails with a clear assertion', () {
      expect(
        () => CarbonNumberInput(labelText: 'Quantity', step: step),
        throwsAssertionError,
      );
    });
  }
}
