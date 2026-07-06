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

const List<CarbonSelectEntry<String>> _items = <CarbonSelectEntry<String>>[
  CarbonSelectItem<String>(value: 'a', label: 'Apple'),
  CarbonSelectItem<String>(value: 'b', label: 'Banana'),
  CarbonSelectItem<String>(value: 'c', label: 'Cherry', disabled: true),
  CarbonSelectItem<String>(value: 'd', label: 'Date'),
];

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Widget select({
    String? value,
    ValueChanged<String>? onChanged = _noop,
    bool fluid = false,
    bool disabled = false,
    bool invalid = false,
    String? invalidText,
    bool warn = false,
    String? warnText,
    String? helperText,
    bool inline = false,
    String placeholder = 'Choose',
    List<CarbonSelectEntry<String>> items = _items,
    FocusNode? focusNode,
  }) => _host(
    CarbonSelect<String>(
      labelText: 'Fruit',
      items: items,
      value: value,
      onChanged: disabled ? null : onChanged,
      placeholder: placeholder,
      fluid: fluid,
      disabled: disabled,
      invalid: invalid,
      invalidText: invalidText,
      warn: warn,
      warnText: warnText,
      helperText: helperText,
      inline: inline,
      focusNode: focusNode,
    ),
  );

  group('anatomy', () {
    testWidgets('placeholder shown when empty; chevron present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(select());
      expect(find.text('Choose'), findsOneWidget);
      expect(find.byType(CarbonIcon), findsOneWidget); // the chevron
      expect(tester.getSize(find.byType(CarbonField)).height, 40);
    });

    testWidgets('selected value is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(select(value: 'b'));
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Choose'), findsNothing);
    });
  });

  group('open / select / close', () {
    testWidgets('tap opens the menu; tapping an item selects and closes', (
      WidgetTester tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(select(onChanged: (String v) => chosen = v));
      // Menu closed: only the trigger placeholder is shown.
      expect(find.text('Banana'), findsNothing);
      await tester.tap(find.byType(CarbonField));
      await tester.pumpAndSettle();
      // Menu open: all items rendered.
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);

      await tester.tap(find.text('Date'));
      await tester.pumpAndSettle();
      expect(chosen, 'd');
      // Closed again: only the trigger value remains.
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('a disabled item cannot be selected', (
      WidgetTester tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(select(onChanged: (String v) => chosen = v));
      await tester.tap(find.byType(CarbonField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
    });

    testWidgets('disabled select does not open', (WidgetTester tester) async {
      await tester.pumpWidget(select(disabled: true));
      await tester.tap(find.byType(CarbonField));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('Down opens; arrows move; Enter selects; Escape closes', (
      WidgetTester tester,
    ) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        select(onChanged: (String v) => chosen = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget); // opened

      // Highlight starts at Apple (0); Down → Banana (1).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'b');

      // Re-open and Escape.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Date'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Date'), findsNothing);
    });

    testWidgets('Enter and Space also open the closed menu', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(select(focusNode: node));
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('Up wraps backwards; Space selects the highlight', (
      WidgetTester tester,
    ) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        select(onChanged: (String v) => chosen = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // Highlight starts at Apple (0); Up wraps to Date (3).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(chosen, 'd');
    });

    testWidgets('type-ahead jumps to the next matching label', (
      WidgetTester tester,
    ) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        select(onChanged: (String v) => chosen = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // No label starts with x: the highlight stays put.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
      await tester.pump();
      // 'b' jumps the highlight to Banana; Enter selects it.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'b');
    });

    testWidgets('Down skips the disabled item', (WidgetTester tester) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        select(
          value: 'b',
          onChanged: (String v) => chosen = v,
          focusNode: node,
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // Highlight at Banana(1); Down skips Cherry(2, disabled) → Date(3).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(chosen, 'd');
    });
  });

  group('groups, validation, fluid, semantics', () {
    testWidgets('group label renders in the menu', (WidgetTester tester) async {
      await tester.pumpWidget(
        select(
          items: const <CarbonSelectEntry<String>>[
            CarbonSelectItemGroup<String>(
              label: 'Citrus',
              items: <CarbonSelectItem<String>>[
                CarbonSelectItem<String>(value: 'o', label: 'Orange'),
                CarbonSelectItem<String>(value: 'l', label: 'Lemon'),
              ],
            ),
          ],
        ),
      );
      await tester.tap(find.byType(CarbonField));
      await tester.pumpAndSettle();
      expect(find.text('Citrus'), findsOneWidget);
      expect(find.text('Orange'), findsOneWidget);
    });

    testWidgets('invalid shows the message', (WidgetTester tester) async {
      await tester.pumpWidget(select(invalid: true, invalidText: 'Pick one'));
      expect(find.text('Pick one'), findsOneWidget);
    });

    testWidgets('fluid puts the label inside a 64px box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(select(value: 'a', fluid: true));
      expect(find.byType(CarbonField), findsNothing);
      expect(find.text('Fruit'), findsOneWidget); // label inside
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('exposes a button with the selected value', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(select(value: 'a'));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Fruit')),
        isSemantics(label: 'Fruit', value: 'Apple', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md trigger is 40px (_select.scss layout.use('size',
      // $default: 'md')) — below the 48dp android guideline, so pump the
      // real lg (48px) variant instead.
      await tester.pumpWidget(
        _host(
          const CarbonSelect<String>(
            labelText: 'Fruit',
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
    testWidgets('closed field states across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'select_states',
        containsText: true,
        size: const Size(340, 280),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Center(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const CarbonSelect<String>(
                        labelText: 'Default',
                        items: _items,
                        placeholder: 'Choose a fruit',
                        onChanged: _noop,
                      ),
                      const SizedBox(height: 12),
                      const CarbonSelect<String>(
                        labelText: 'Selected',
                        items: _items,
                        value: 'b',
                        onChanged: _noop,
                      ),
                      const SizedBox(height: 12),
                      const CarbonSelect<String>(
                        labelText: 'Invalid',
                        items: _items,
                        value: 'a',
                        invalid: true,
                        invalidText: 'Error message',
                        onChanged: _noop,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  });
}

void _noop(String _) {}
