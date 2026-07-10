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
import '../../support/overlay_entries.dart';

/// OverlayPortal needs an Overlay ancestor.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        managedOverlayEntry(
          builder: (BuildContext context) =>
              Center(child: SizedBox(width: 320, child: child)),
        ),
      ],
    ),
  ),
);

const List<CarbonDropdownItem<String>> _items = <CarbonDropdownItem<String>>[
  CarbonDropdownItem<String>(value: 'a', label: 'Apple'),
  CarbonDropdownItem<String>(value: 'b', label: 'Banana'),
  CarbonDropdownItem<String>(value: 'c', label: 'Cherry', disabled: true),
  CarbonDropdownItem<String>(value: 'd', label: 'Date'),
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

  Widget dropdown({
    String? value,
    ValueChanged<String>? onChanged = _noop,
    bool disabled = false,
    bool readOnly = false,
    bool invalid = false,
    String? invalidText,
    bool warn = false,
    String? warnText,
    String? helperText,
    bool inline = false,
    FocusNode? focusNode,
  }) => _host(
    CarbonDropdown<String>(
      titleText: 'Fruit',
      label: 'Choose',
      items: _items,
      selectedItem: value,
      onChanged: onChanged,
      disabled: disabled,
      readOnly: readOnly,
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
    testWidgets('title, placeholder, helper', (WidgetTester tester) async {
      await tester.pumpWidget(dropdown(helperText: 'Pick one'));
      expect(find.text('Fruit'), findsOneWidget);
      expect(find.text('Choose'), findsOneWidget);
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.byType(CarbonListBox), findsOneWidget);
    });

    testWidgets('selected value replaces the placeholder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(dropdown(value: 'b'));
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Choose'), findsNothing);
    });
  });

  group('open / select', () {
    testWidgets('tap opens the menu; tapping an item selects + closes', (
      WidgetTester tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(dropdown(onChanged: (String v) => chosen = v));
      await tester.tap(find.byType(CarbonListBox));
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsOneWidget);
      // All option labels are visible in the menu.
      expect(find.text('Date'), findsOneWidget);
      await tester.tap(find.text('Date'));
      await tester.pump();
      expect(chosen, 'd');
      expect(find.byType(CarbonListBoxMenu), findsNothing);
    });

    testWidgets('selected item shows a checkmark in the menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(dropdown(value: 'a'));
      await tester.tap(find.byType(CarbonListBox));
      await tester.pump();
      // One chevron (closed-state field already gone; field chevron + a
      // checkmark on the selected row).
      expect(find.byType(CarbonListBoxMenu), findsOneWidget);
      final bool hasCheck = tester
          .widgetList<CarbonIcon>(find.byType(CarbonIcon))
          .any((CarbonIcon i) => i.icon == CarbonIcons.checkmark);
      expect(hasCheck, isTrue);
    });

    testWidgets('disabled and read-only do not open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(dropdown(disabled: true));
      await tester.tap(find.byType(CarbonListBox));
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsNothing);

      await tester.pumpWidget(dropdown(readOnly: true));
      await tester.tap(find.byType(CarbonListBox));
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('Down opens; arrows skip disabled; Enter selects', (
      WidgetTester tester,
    ) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        dropdown(onChanged: (String v) => chosen = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsOneWidget);
      // From Apple (0): Down → Banana (1), Down → skips Cherry (disabled) → Date (3).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, 'd');
    });

    testWidgets('Escape closes without selecting', (WidgetTester tester) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        dropdown(onChanged: (String v) => chosen = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsNothing);
      expect(chosen, isNull);
    });

    testWidgets('type-ahead highlights the matching item', (
      WidgetTester tester,
    ) async {
      String? chosen;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        dropdown(onChanged: (String v) => chosen = v, focusNode: node),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, 'd');
    });
  });

  group('validation', () {
    testWidgets('invalid shows the error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        dropdown(
          invalid: true,
          invalidText: 'Required',
          helperText: 'Optional',
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
      await tester.pumpWidget(dropdown(warn: true, warnText: 'Careful'));
      expect(find.text('Careful'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('inline places the title beside the field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(dropdown(inline: true));
      expect(
        tester.getTopLeft(find.text('Fruit')).dx,
        lessThan(tester.getTopLeft(find.byType(CarbonListBox)).dx),
      );
    });
  });

  group('semantics', () {
    testWidgets('exposes a button with title + value', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(dropdown(value: 'a'));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Fruit')),
        isSemantics(label: 'Fruit', isButton: true, value: 'Apple'),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md trigger is 40px (_list-box.scss layout.use('size',
      // $default: 'md')) — below the 48dp android guideline, so pump the
      // real lg (48px) variant instead.
      await tester.pumpWidget(
        _host(
          const CarbonDropdown<String>(
            titleText: 'Fruit',
            label: 'Choose',
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
        name: 'dropdown_states',
        containsText: true,
        size: const Size(340, 360),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                CarbonDropdown<String>(
                  titleText: 'Default',
                  label: 'Choose an option',
                  items: _items,
                  onChanged: _noop,
                ),
                SizedBox(height: 12),
                CarbonDropdown<String>(
                  titleText: 'Selected',
                  items: _items,
                  selectedItem: 'b',
                  onChanged: _noop,
                ),
                SizedBox(height: 12),
                CarbonDropdown<String>(
                  titleText: 'Invalid',
                  label: 'Choose',
                  items: _items,
                  invalid: true,
                  invalidText: 'Required',
                  onChanged: _noop,
                ),
                SizedBox(height: 12),
                CarbonDropdown<String>(
                  titleText: 'Disabled',
                  label: 'Choose',
                  items: _items,
                  disabled: true,
                  onChanged: _noop,
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('open menu across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'dropdown_open',
        containsText: true,
        size: const Size(320, 260),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (BuildContext context) => Padding(
                padding: const EdgeInsets.all(12),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 280,
                    child: CarbonDropdown<String>(
                      titleText: 'Fruit',
                      label: 'Choose',
                      items: _items,
                      selectedItem: 'b',
                      onChanged: _noop,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.tap(find.byType(CarbonListBox));
          await tester.pumpAndSettle();
        },
      );
    });
  });
}

void _noop(String _) {}
