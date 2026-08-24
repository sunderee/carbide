// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
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
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('anatomy & spec locks', () {
    testWidgets('label, field height per size, placeholder when empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextInput(
            labelText: 'Email',
            placeholder: 'you@example.com',
          ),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(tester.getSize(find.byType(CarbonField)).height, 40);
      expect(find.text('you@example.com'), findsOneWidget);

      await tester.pumpWidget(
        _host(const CarbonTextInput(labelText: 'L', size: CarbonFieldSize.lg)),
      );
      expect(tester.getSize(find.byType(CarbonField)).height, 48);
    });

    testWidgets('hideLabel removes the visible label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonTextInput(labelText: 'Hidden', hideLabel: true)),
      );
      expect(find.text('Hidden'), findsNothing);
    });
  });

  group('text entry', () {
    testWidgets(
      'typing updates the value, fires onChanged, hides placeholder',
      (WidgetTester tester) async {
        String? last;
        await tester.pumpWidget(
          _host(
            CarbonTextInput(
              labelText: 'Name',
              placeholder: 'Type here',
              onChanged: (String v) => last = v,
            ),
          ),
        );
        await tester.enterText(find.byType(EditableText), 'Ada');
        await tester.pump();
        expect(last, 'Ada');
        expect(find.text('Type here'), findsNothing);
        expect(find.text('Ada'), findsOneWidget);
      },
    );

    testWidgets('disabled and read-only block editing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonTextInput(labelText: 'D', disabled: true)),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
      // Disabled label is greyed.
      expect(
        tester.widget<Text>(find.text('D')).style!.color,
        theme.textDisabled,
      );

      await tester.pumpWidget(
        _host(const CarbonTextInput(labelText: 'R', readOnly: true)),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });
  });

  group('validation', () {
    testWidgets('invalid shows the error message in text-error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextInput(
            labelText: 'E',
            invalid: true,
            invalidText: 'Required',
            helperText: 'Optional',
          ),
        ),
      );
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Optional'), findsNothing);
      expect(
        tester.widget<Text>(find.text('Required')).style!.color,
        theme.textError,
      );
    });

    testWidgets('warn shows the warning message', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextInput(
            labelText: 'W',
            warn: true,
            warnText: 'Careful',
          ),
        ),
      );
      expect(find.text('Careful'), findsOneWidget);
    });
  });

  group('layouts', () {
    testWidgets('inline places the label beside the field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonTextInput(labelText: 'Inline', inline: true)),
      );
      // Label and field share a row → similar vertical position.
      expect(
        tester.getTopLeft(find.text('Inline')).dx,
        lessThan(tester.getTopLeft(find.byType(CarbonField)).dx),
      );
    });

    testWidgets('fluid puts the label inside a 64px field box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextInput(
            labelText: 'Fluid',
            placeholder: 'inside',
            fluid: true,
          ),
        ),
      );
      // The fluid field has no separate CarbonField; the label and editable
      // share the 64px box.
      expect(find.byType(CarbonField), findsNothing);
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
  });

  group('CarbonPasswordInput', () {
    testWidgets('obscures by default; the toggle shows/hides', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonPasswordInput(labelText: 'Password')),
      );
      EditableText editable() =>
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editable().obscureText, isTrue);

      await tester.enterText(find.byType(EditableText), 'secret');
      await tester.pump();

      // Tapping the View/ViewOff toggle reveals the text.
      await tester.tap(find.byType(CarbonIcon));
      await tester.pump();
      expect(editable().obscureText, isFalse);
    });

    testWidgets('toggle exposes a button label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonPasswordInput(labelText: 'Password')),
      );
      expect(find.bySemanticsLabel('Show password'), findsOneWidget);
      handle.dispose();
    });
  });

  group('semantics', () {
    testWidgets('exposes a text field with its label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonTextInput(labelText: 'Username')),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Username')),
        isSemantics(label: 'Username', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonTextInput(labelText: 'Email')));
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('states across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'text_input_states',
        containsText: true,
        size: const Size(340, 440),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonTextInput(
                  labelText: 'Default',
                  placeholder: 'Placeholder',
                ),
                SizedBox(height: 12),
                CarbonTextInput(labelText: 'Filled', initialValue: 'Value'),
                SizedBox(height: 12),
                CarbonTextInput(
                  labelText: 'Invalid',
                  initialValue: 'Bad',
                  invalid: true,
                  invalidText: 'Error message',
                ),
                SizedBox(height: 12),
                CarbonTextInput(
                  labelText: 'Warning',
                  initialValue: 'Hmm',
                  warn: true,
                  warnText: 'Warning message',
                ),
                SizedBox(height: 12),
                CarbonTextInput(
                  labelText: 'Disabled',
                  initialValue: 'Off',
                  disabled: true,
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('fluid + password across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'text_input_fluid_password',
        containsText: true,
        size: const Size(340, 200),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonTextInput(
                  labelText: 'Fluid label',
                  initialValue: 'Fluid value',
                  fluid: true,
                ),
                SizedBox(height: 12),
                CarbonPasswordInput(
                  labelText: 'Password',
                  initialValue: 'secret',
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
        name: 'text_input_focus',
        containsText: true,
        size: const Size(340, 90),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 300,
            child: CarbonTextInput(
              labelText: 'Focused',
              initialValue: 'Value',
              focusNode: node,
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
