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
    child: Center(child: SizedBox(width: 340, child: child)),
  ),
);

BoxDecoration _boxOf(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(CarbonTextArea),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((DecoratedBox d) => d.decoration as BoxDecoration)
    .firstWhere((BoxDecoration d) => d.color != null);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('spec locks (_text-area.scss)', () {
    testWidgets('field bg + 1px border-strong bottom; multiline; min 40', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonTextArea(labelText: 'Bio')));
      final BoxDecoration box = _boxOf(tester);
      expect(box.color, theme.field01);
      final Border border = box.border! as Border;
      expect(border.bottom.width, 1);
      expect(border.bottom.color, theme.borderStrong01);

      final EditableText editable = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editable.maxLines, isNull);
      expect(editable.minLines, 4);
      expect(CarbonTextArea.minHeight, 40);
    });
  });

  group('counter', () {
    testWidgets('character counter shows N/max and updates on entry', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            initialValue: 'abc',
            enableCounter: true,
            maxCount: 100,
          ),
        ),
      );
      expect(find.text('3/100'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'abcd');
      await tester.pump();
      expect(find.text('4/100'), findsOneWidget);
    });

    testWidgets('word counter counts whitespace-separated words', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            initialValue: 'hello there world',
            enableCounter: true,
            maxCount: 50,
            counterMode: CarbonCounterMode.word,
          ),
        ),
      );
      expect(find.text('3/50'), findsOneWidget);
    });
  });

  group('states', () {
    testWidgets('disabled greys + transparent border; invalid shows message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonTextArea(labelText: 'D', disabled: true)),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
      expect(
        (_boxOf(tester).border! as Border).bottom.color,
        const Color(0x00000000),
      );

      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'E',
            invalid: true,
            invalidText: 'Too long',
            helperText: 'Helper',
          ),
        ),
      );
      expect(find.text('Too long'), findsOneWidget);
      expect(find.text('Helper'), findsNothing);
    });
  });

  group('fluid + semantics', () {
    testWidgets('fluid hides the outer label row (label moves inside)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Fluid',
            initialValue: 'x',
            fluid: true,
          ),
        ),
      );
      // Label rendered once, inside the box (above the editable).
      expect(find.text('Fluid'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Fluid')).dy,
        lessThan(tester.getTopLeft(find.byType(EditableText)).dy),
      );
    });

    testWidgets('exposes a text field with its label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonTextArea(labelText: 'Comments')),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Comments')),
        isSemantics(label: 'Comments', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonTextArea(labelText: 'Bio')));
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('states + counter across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'text_area_states',
        containsText: true,
        size: const Size(360, 420),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CarbonTextArea(
                  labelText: 'Default',
                  placeholder: 'Tell us more',
                  rows: 2,
                ),
                const SizedBox(height: 12),
                const CarbonTextArea(
                  labelText: 'With counter',
                  initialValue: 'Some content',
                  rows: 2,
                  enableCounter: true,
                  maxCount: 100,
                ),
                const SizedBox(height: 12),
                const CarbonTextArea(
                  labelText: 'Invalid',
                  initialValue: 'Oops',
                  rows: 2,
                  invalid: true,
                  invalidText: 'Error message',
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
        name: 'text_area_focus',
        containsText: true,
        size: const Size(360, 130),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 320,
            child: CarbonTextArea(
              labelText: 'Focused',
              initialValue: 'Value',
              rows: 2,
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
