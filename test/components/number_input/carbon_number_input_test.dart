// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 320, child: child)),
  ),
);

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('anatomy', () {
    testWidgets('field height per size; two steppers (Subtract, Add)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonNumberInput(labelText: 'Qty', value: 3, onChanged: (_) {})),
      );
      expect(tester.getSize(find.byType(CarbonNumberInput)).width, 320);
      // The field box itself is 40px (md) tall.
      final double boxHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.byType(EditableText),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .height;
      expect(boxHeight, 40);
      expect(find.byType(CarbonIcon), findsNWidgets(2));
    });

    testWidgets('hideSteppers removes them', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonNumberInput(labelText: 'Q', value: 1, hideSteppers: true),
        ),
      );
      expect(find.byType(CarbonIcon), findsNothing);
    });
  });

  group('stepping & clamping', () {
    // A self-managing host that owns the controlled value and reports each
    // change through [sink]; a UniqueKey keeps each pump's State fresh.
    Widget controlled(
      num? initial,
      void Function(num?) sink, {
      num? min,
      num? max,
      num step = 1,
      bool allowEmpty = false,
      FocusNode? focusNode,
    }) {
      num? value = initial;
      return _host(
        StatefulBuilder(
          key: UniqueKey(),
          builder: (BuildContext context, StateSetter setState) =>
              CarbonNumberInput(
                labelText: 'N',
                value: value,
                min: min,
                max: max,
                step: step,
                allowEmpty: allowEmpty,
                focusNode: focusNode,
                onChanged: (num? v) {
                  setState(() => value = v);
                  sink(v);
                },
              ),
        ),
      );
    }

    testWidgets('Add / Subtract step by step and clamp at bounds', (
      WidgetTester tester,
    ) async {
      num? reported;
      await tester.pumpWidget(
        controlled(5, (num? v) => reported = v, min: 0, max: 6, step: 2),
      );
      // Increment (last icon = Add) → 7 clamped to 6.
      await tester.tap(find.byType(CarbonIcon).last);
      await tester.pump();
      expect(reported, 6);
      // At max, increment is disabled (no change reported).
      reported = null;
      await tester.tap(find.byType(CarbonIcon).last);
      await tester.pump();
      expect(reported, isNull);
      // Decrement (first icon = Subtract) → 4.
      await tester.tap(find.byType(CarbonIcon).first);
      await tester.pump();
      expect(reported, 4);
    });

    testWidgets('arrow Up/Down step the value', (WidgetTester tester) async {
      num? reported;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        controlled(5, (num? v) => reported = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(reported, 6);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(reported, 5);
    });

    testWidgets('typing a number reports it at commit', (
      WidgetTester tester,
    ) async {
      num? reported;
      await tester.pumpWidget(controlled(1, (num? v) => reported = v));
      await tester.enterText(find.byType(EditableText), '42');
      await tester.pump();
      expect(reported, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(reported, 42);
    });

    testWidgets('empty reports null when allowed', (WidgetTester tester) async {
      num? reported = 5;
      await tester.pumpWidget(
        controlled(5, (num? v) => reported = v, allowEmpty: true),
      );
      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      expect(reported, 5);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(reported, isNull);
    });

    testWidgets('empty coerces to min when not allowed', (
      WidgetTester tester,
    ) async {
      num? reported;
      await tester.pumpWidget(controlled(5, (num? v) => reported = v, min: 2));
      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      expect(reported, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(reported, 2);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '2',
      );
    });
  });

  group('validation, fluid, semantics', () {
    testWidgets('invalid shows the message', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonNumberInput(
            labelText: 'N',
            value: 99,
            invalid: true,
            invalidText: 'Out of range',
          ),
        ),
      );
      expect(find.text('Out of range'), findsOneWidget);
    });

    testWidgets('fluid puts the label inside a 64px box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonNumberInput(labelText: 'Fluid', value: 1, fluid: true),
        ),
      );
      expect(find.byType(CarbonFormLabel), findsNothing);
      expect(find.text('Fluid'), findsOneWidget);
      final double boxHeight = tester
          .getSize(
            find
                .ancestor(
                  of: find.byType(EditableText),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .height;
      expect(boxHeight, 64);
    });

    testWidgets('steppers expose accessible labels', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonNumberInput(labelText: 'N', value: 1, onChanged: (_) {})),
      );
      expect(find.bySemanticsLabel('Increment number'), findsOneWidget);
      expect(find.bySemanticsLabel('Decrement number'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md steppers are 40px squares (_number-input.scss block-size:
      // convert.to-rem(40px)) — below the 48dp android guideline, so pump
      // the real lg (48px) variant instead.
      await tester.pumpWidget(
        _host(
          CarbonNumberInput(
            labelText: 'Qty',
            value: 3,
            size: CarbonFieldSize.lg,
            onChanged: (_) {},
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('warning precedence and hidden fluid label across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'number_input_status',
        containsText: true,
        size: const Size(340, 380),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonNumberInput(
                  labelText: 'Warning',
                  value: 5,
                  warn: true,
                  warnText: 'Check quantity',
                ),
                SizedBox(height: 12),
                CarbonNumberInput(
                  labelText: 'Invalid before warning',
                  value: 99,
                  invalid: true,
                  invalidText: 'Out of range',
                  warn: true,
                  warnText: 'Check quantity',
                ),
                SizedBox(height: 12),
                CarbonNumberInput(
                  labelText: 'Fluid warning',
                  value: 8,
                  fluid: true,
                  warn: true,
                  warnText: 'Check quantity',
                ),
                SizedBox(height: 12),
                CarbonNumberInput(
                  labelText: 'Hidden fluid label',
                  value: 8,
                  fluid: true,
                  hideLabel: true,
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('states + fluid across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'number_input_states',
        containsText: true,
        size: const Size(340, 320),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonNumberInput(
                  labelText: 'Quantity',
                  value: 5,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                const CarbonNumberInput(
                  labelText: 'Invalid',
                  value: 99,
                  invalid: true,
                  invalidText: 'Out of range',
                ),
                const SizedBox(height: 12),
                const CarbonNumberInput(
                  labelText: 'Disabled',
                  value: 3,
                  disabled: true,
                ),
                const SizedBox(height: 12),
                const CarbonNumberInput(
                  labelText: 'Fluid',
                  value: 8,
                  fluid: true,
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('focus ring', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'number_input_focus',
        containsText: true,
        size: const Size(340, 90),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 300,
            child: CarbonNumberInput(
              labelText: 'Focused',
              value: 5,
              focusNode: node,
              onChanged: (_) {},
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          node.requestFocus();
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
