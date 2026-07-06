// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

/// OverlayPortal needs an Overlay ancestor.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          builder: (BuildContext context) =>
              Center(child: SizedBox(width: 320, child: child)),
        ),
      ],
    ),
  ),
);

const List<CarbonComboBoxItem<String>> _items = <CarbonComboBoxItem<String>>[
  CarbonComboBoxItem<String>(value: 'a', label: 'Apple'),
  CarbonComboBoxItem<String>(value: 'b', label: 'Banana'),
  CarbonComboBoxItem<String>(value: 'c', label: 'Cherry'),
  CarbonComboBoxItem<String>(value: 'd', label: 'Date'),
];

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Widget combo({
    String? value,
    ValueChanged<String?>? onChanged = _noop,
    String? helperText,
    bool invalid = false,
    String? invalidText,
    bool warn = false,
    String? warnText,
    bool disabled = false,
    FocusNode? focusNode,
  }) => _host(
    CarbonComboBox<String>(
      titleText: 'Fruit',
      placeholder: 'Filter…',
      items: _items,
      selectedItem: value,
      onChanged: onChanged,
      helperText: helperText,
      invalid: invalid,
      invalidText: invalidText,
      warn: warn,
      warnText: warnText,
      disabled: disabled,
      focusNode: focusNode,
    ),
  );

  group('anatomy', () {
    testWidgets('title, placeholder, editable input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(combo(helperText: 'Pick one'));
      expect(find.text('Fruit'), findsOneWidget);
      expect(find.text('Filter…'), findsOneWidget);
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('selected value seeds the field text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(combo(value: 'b'));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Banana',
      );
    });
  });

  group('filtering', () {
    testWidgets('typing opens the menu and filters options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(combo());
      await tester.enterText(find.byType(EditableText), 'ch');
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('selecting a filtered item fills the field and reports it', (
      WidgetTester tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(combo(onChanged: (String? v) => chosen = v));
      await tester.enterText(find.byType(EditableText), 'ch');
      await tester.pump();
      await tester.tap(find.text('Cherry'));
      await tester.pump();
      expect(chosen, 'c');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Cherry',
      );
      expect(find.byType(CarbonListBoxMenu), findsNothing);
    });
  });

  group('clear', () {
    testWidgets('clear control resets the value and reopens', (
      WidgetTester tester,
    ) async {
      String? chosen = 'b';
      await tester.pumpWidget(
        combo(value: 'b', onChanged: (String? v) => chosen = v),
      );
      // The clear (X) selection control is shown when there is text.
      expect(find.byType(CarbonListBoxSelection), findsOneWidget);
      await tester.tap(find.byType(CarbonListBoxSelection));
      await tester.pump();
      expect(chosen, isNull);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        '',
      );
    });
  });

  group('keyboard', () {
    testWidgets('Down opens; arrows move; Enter selects highlighted', (
      WidgetTester tester,
    ) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        combo(onChanged: (String? v) => chosen = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      // Focusing opens the menu.
      expect(find.byType(CarbonListBoxMenu), findsOneWidget);
      // Apple highlighted → Down → Banana → Enter.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, 'b');
    });

    testWidgets('Escape closes, then clears', (WidgetTester tester) async {
      String? chosen = 'a';
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        combo(
          value: 'a',
          onChanged: (String? v) => chosen = v,
          focusNode: node,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      // First Escape closes the (focus-opened) menu.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsNothing);
      // Second Escape clears the field.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(chosen, isNull);
    });
  });

  group('validation + semantics', () {
    testWidgets('invalid shows the error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        combo(invalid: true, invalidText: 'Required', helperText: 'Optional'),
      );
      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Optional'), findsNothing);
      expect(
        tester.widget<Text>(find.text('Required')).style!.color,
        theme.textError,
      );
    });

    testWidgets('exposes a text field with its title', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(combo());
      expect(
        tester.getSemantics(find.bySemanticsLabel('Fruit')),
        isSemantics(label: 'Fruit', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md field is 40px (_list-box.scss layout.use('size',
      // $default: 'md')) — below the 48dp android guideline, so pump the
      // real lg (48px) variant instead.
      await tester.pumpWidget(
        _host(
          const CarbonComboBox<String>(
            titleText: 'Fruit',
            placeholder: 'Filter…',
            items: _items,
            size: CarbonFieldSize.lg,
            onChanged: _noop,
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('states across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'combo_box_states',
        containsText: true,
        size: const Size(340, 280),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                CarbonComboBox<String>(
                  titleText: 'Empty',
                  placeholder: 'Filter…',
                  items: _items,
                  onChanged: _noop,
                ),
                SizedBox(height: 12),
                CarbonComboBox<String>(
                  titleText: 'Selected',
                  items: _items,
                  selectedItem: 'b',
                  onChanged: _noop,
                ),
                SizedBox(height: 12),
                CarbonComboBox<String>(
                  titleText: 'Invalid',
                  placeholder: 'Filter…',
                  items: _items,
                  invalid: true,
                  invalidText: 'Required',
                  onChanged: _noop,
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}

void _noop(String? _) {}
