// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/overlay_entries.dart';

/// OverlayPortal (submenus) needs an Overlay ancestor.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        managedOverlayEntry(
          builder: (BuildContext context) => Center(child: child),
        ),
      ],
    ),
  ),
);

AnimatedContainer _row(WidgetTester tester, String label) =>
    tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          )
          .first,
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

  group('surface (_menu.scss)', () {
    testWidgets('layer background + drop shadow; no border by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItem(label: 'Cut', onPressed: () {}),
              CarbonMenuItem(label: 'Copy', onPressed: () {}),
            ],
          ),
        ),
      );
      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(CarbonMenu),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(deco.color, theme.layer01);
      expect(deco.boxShadow, isNotNull);
      expect(deco.border, isNull);
    });

    testWidgets('border modifier outlines with 1px border-subtle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            border: true,
            autofocus: false,
            children: <Widget>[CarbonMenuItem(label: 'A', onPressed: () {})],
          ),
        ),
      );
      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(CarbonMenu),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      final Border border = deco.border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, theme.borderSubtle00);
    });

    testWidgets('row height follows size', (WidgetTester tester) async {
      const List<(CarbonMenuSize, double)> sizes = <(CarbonMenuSize, double)>[
        (CarbonMenuSize.xs, 24),
        (CarbonMenuSize.sm, 32),
        (CarbonMenuSize.md, 40),
        (CarbonMenuSize.lg, 48),
      ];
      // Render all sizes in one tree (the test Overlay honours its entries
      // once, so re-pumping a fresh host would not swap the menu).
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final (CarbonMenuSize size, _) in sizes)
                CarbonMenu(
                  size: size,
                  autofocus: false,
                  children: <Widget>[
                    CarbonMenuItem(
                      label: 'Item ${size.name}',
                      onPressed: () {},
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
      for (final (CarbonMenuSize size, double height) in sizes) {
        expect(
          _row(tester, 'Item ${size.name}').constraints?.maxHeight,
          height,
          reason: '$size',
        );
      }
    });
  });

  group('CarbonMenuItem', () {
    testWidgets('tap activates and closes the menu', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      int closes = 0;
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            onClose: () => closes++,
            children: <Widget>[
              CarbonMenuItem(label: 'Run', onPressed: () => pressed++),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Run'));
      await tester.pump();
      expect(pressed, 1);
      expect(closes, 1);
    });

    testWidgets('disabled item is inert and greyed', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItem(
                label: 'Nope',
                disabled: true,
                onPressed: () => pressed++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Nope'));
      expect(pressed, 0);
      expect(
        tester.widget<Text>(find.text('Nope')).style!.color,
        theme.textDisabled,
      );
    });

    testWidgets('danger item fills with danger token on focus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            // The lone item autofocuses, so it is focused after settling.
            children: <Widget>[
              CarbonMenuItem(
                label: 'Delete',
                kind: CarbonMenuItemKind.danger,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_focusedLabel(tester), 'Delete');
      expect(
        (_row(tester, 'Delete').decoration! as BoxDecoration).color,
        theme.buttonDangerPrimary,
      );
      expect(
        tester.widget<Text>(find.text('Delete')).style!.color,
        theme.textOnColor,
      );
    });

    testWidgets('Enter activates the focused item and closes the menu', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      int closes = 0;
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            onClose: () => closes++,
            children: <Widget>[
              CarbonMenuItem(label: 'Run', onPressed: () => pressed++),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_focusedLabel(tester), 'Run');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, 1);
      expect(closes, 1);
    });

    testWidgets('hovering an item paints the hover layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItem(label: 'Cut', onPressed: () {}),
              CarbonMenuItem(label: 'Copy', onPressed: () {}),
            ],
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('Copy')));
      await tester.pumpAndSettle();
      expect(
        (_row(tester, 'Copy').decoration! as BoxDecoration).color,
        theme.layerHover01,
      );
      expect(
        tester.widget<Text>(find.text('Copy')).style!.color,
        theme.textPrimary,
      );

      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(
        (_row(tester, 'Copy').decoration! as BoxDecoration).color,
        const Color(0x00000000),
      );
    });

    testWidgets('exposes a button with its label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[CarbonMenuItem(label: 'Save', onPressed: () {})],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')),
        isSemantics(label: 'Save', isButton: true),
      );
      handle.dispose();
    });
  });

  group('keyboard roving', () {
    Future<void> pumpMenu(WidgetTester tester) => tester.pumpWidget(
      _host(
        CarbonMenu(
          children: <Widget>[
            CarbonMenuItem(label: 'Apple', onPressed: () {}),
            CarbonMenuItem(label: 'Banana', onPressed: () {}),
            CarbonMenuItem(label: 'Cherry', onPressed: () {}),
          ],
        ),
      ),
    );

    testWidgets('autofocus lands on the first item', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();
      expect(_focusedLabel(tester), 'Apple');
    });

    testWidgets('arrow down/up rove and wrap', (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(tester), 'Banana');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_focusedLabel(tester), 'Cherry'); // wrapped past the top
    });

    testWidgets('Home/End jump to the ends', (WidgetTester tester) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(_focusedLabel(tester), 'Cherry');
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(_focusedLabel(tester), 'Apple');
    });

    testWidgets('type-ahead jumps to the next matching label', (
      WidgetTester tester,
    ) async {
      await pumpMenu(tester);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
      await tester.pump();
      expect(_focusedLabel(tester), 'Cherry');
    });

    testWidgets('Escape requests close', (WidgetTester tester) async {
      int closes = 0;
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            onClose: () => closes++,
            children: <Widget>[
              CarbonMenuItem(label: 'Apple', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closes, 1);
    });
  });

  group('selectable + radio + divider', () {
    testWidgets('selectable toggles and shows the checkmark', (
      WidgetTester tester,
    ) async {
      bool selected = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => CarbonMenu(
              autofocus: false,
              children: <Widget>[
                CarbonMenuItemSelectable(
                  label: 'Wrap',
                  selected: selected,
                  onChanged: (bool v) => setState(() => selected = v),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(CarbonIcon), findsNothing);
      await tester.tap(find.text('Wrap'));
      await tester.pump();
      expect(selected, isTrue);
      expect(find.byType(CarbonIcon), findsOneWidget); // the checkmark
    });

    testWidgets('selectable exposes a checked state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItemSelectable(
                label: 'Wrap',
                selected: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Wrap')),
        isSemantics(hasCheckedState: true, isChecked: true),
      );
      handle.dispose();
    });

    testWidgets('radio group single-selects with exclusive semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      String value = 'a';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) => CarbonMenu(
              autofocus: false,
              children: <Widget>[
                CarbonMenuItemRadioGroup<String>(
                  label: 'Sort',
                  value: value,
                  onChanged: (String v) => setState(() => value = v),
                  options: const <(String, String)>[
                    ('a', 'Ascending'),
                    ('b', 'Descending'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ascending')),
        isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
      );
      await tester.tap(find.text('Descending'));
      await tester.pump();
      expect(value, 'b');
      handle.dispose();
    });

    testWidgets('Space toggles the focused selectable', (
      WidgetTester tester,
    ) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            children: <Widget>[
              CarbonMenuItemSelectable(
                label: 'Wrap',
                selected: false,
                onChanged: (bool v) => changed = v,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Focus paints the hover tokens on the row.
      expect(
        (_row(tester, 'Wrap').decoration! as BoxDecoration).color,
        theme.layerHover01,
      );
      expect(
        tester.widget<Text>(find.text('Wrap')).style!.color,
        theme.textPrimary,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(changed, isTrue);
    });

    testWidgets('disabled selectable is inert and greyed', (
      WidgetTester tester,
    ) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItemSelectable(
                label: 'Wrap',
                selected: false,
                disabled: true,
                onChanged: (bool v) => changed = v,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Wrap'));
      await tester.pump();
      expect(changed, isNull);
      expect(
        tester.widget<Text>(find.text('Wrap')).style!.color,
        theme.textDisabled,
      );
    });

    testWidgets('hover paints selectable and radio rows with layer-hover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItemSelectable(
                label: 'Wrap',
                selected: false,
                onChanged: (_) {},
              ),
              CarbonMenuItemRadioGroup<String>(
                label: 'Sort',
                value: 'a',
                onChanged: (_) {},
                options: const <(String, String)>[('a', 'Ascending')],
              ),
            ],
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      for (final String label in <String>['Wrap', 'Ascending']) {
        await gesture.moveTo(tester.getCenter(find.text(label)));
        await tester.pumpAndSettle();
        expect(
          (_row(tester, label).decoration! as BoxDecoration).color,
          theme.layerHover01,
          reason: label,
        );
        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        expect(
          (_row(tester, label).decoration! as BoxDecoration).color,
          const Color(0x00000000),
          reason: label,
        );
      }
    });

    testWidgets('Enter selects the focused radio option', (
      WidgetTester tester,
    ) async {
      String? value;
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            children: <Widget>[
              CarbonMenuItemRadioGroup<String>(
                label: 'Sort',
                value: 'a',
                onChanged: (String v) => value = v,
                options: const <(String, String)>[
                  ('a', 'Ascending'),
                  ('b', 'Descending'),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(tester), 'Descending');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(value, 'b');
    });

    testWidgets('group labels its items; keyboard roves through them', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            children: <Widget>[
              CarbonMenuItemGroup(
                label: 'Actions',
                children: <Widget>[
                  CarbonMenuItem(label: 'One', onPressed: () {}),
                  CarbonMenuItemDivider(key: UniqueKey()),
                  CarbonMenuItem(label: 'Two', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Actions'), findsOneWidget);
      expect(find.byType(CarbonMenuItemDivider), findsOneWidget);
      // Grouped items still register with the menu's roving order.
      expect(_focusedLabel(tester), 'One');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusedLabel(tester), 'Two');
      handle.dispose();
    });

    testWidgets('divider is a 1px border-subtle rule', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: const <Widget>[CarbonMenuItemDivider()],
          ),
        ),
      );
      final SizedBox rule = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(CarbonMenuItemDivider),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(rule.height, 1);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(CarbonMenuItemDivider),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        theme.borderSubtle00,
      );
    });
  });

  group('submenu', () {
    testWidgets('chevron item opens a nested menu; Left closes it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            children: <Widget>[
              CarbonMenuItem(
                label: 'Share',
                submenu: <Widget>[
                  CarbonMenuItem(label: 'Email', onPressed: () {}),
                  CarbonMenuItem(label: 'Link', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Email'), findsNothing);
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItem(label: 'Cut', onPressed: () {}),
              CarbonMenuItem(label: 'Copy', onPressed: () {}),
              CarbonMenuItem(label: 'Paste', onPressed: () {}),
            ],
          ),
        ),
      );
      // Tap targets are off: menu rows are 32px by upstream default
      // (`.cds--menu-item { block-size: 2rem }` in documentation/carbon/
      // packages/styles/scss/components/menu/_menu.scss), so 48dp is
      // unattainable at the default `sm` size.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });

    testWidgets('traversal visits items in source order', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItem(label: 'One', onPressed: () {}),
              CarbonMenuItem(label: 'Two', onPressed: () {}),
              CarbonMenuItem(label: 'Three', onPressed: () {}),
            ],
          ),
        ),
      );
      final List<String> labels = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((SemanticsNode n) => n.label)
          .where((String l) => l.isNotEmpty)
          .toList();
      expect(labels, containsAllInOrder(<String>['One', 'Two', 'Three']));
      handle.dispose();
    });
  });

  group('motion (#235)', () {
    // Spec source: `_menu.scss` (line 84): the row's only motion is
    // `transition: background-color $duration-fast-01
    // motion(standard, productive)`; the menu itself has no open
    // transition, so it appears instantly.
    testWidgets('spec lock: row tint is fast-01 × standard-productive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            autofocus: false,
            children: <Widget>[CarbonMenuItem(label: 'Run', onPressed: () {})],
          ),
        ),
      );
      final AnimatedContainer row = _row(tester, 'Run');
      expect(row.duration, CarbonDuration.fast01);
      expect(row.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion: row tint applies instantly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(
            CarbonMenu(
              autofocus: false,
              children: <Widget>[
                CarbonMenuItem(label: 'Run', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      expect(_row(tester, 'Run').duration, Duration.zero);
    });
  });

  group('goldens', () {
    testWidgets('action menu across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'menu_actions',
        // Direction-sensitive geometry (#227): mirrored fill / side
        // accent / overlay side re-snapshots under RTL.
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        containsText: true,
        size: const Size(260, 220),
        builder: (BuildContext context) => Center(
          child: CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItem(
                label: 'Cut',
                icon: CarbonIcons.close,
                shortcut: 'Ctrl+X',
                onPressed: () {},
              ),
              CarbonMenuItem(
                label: 'Copy',
                icon: CarbonIcons.copy,
                onPressed: () {},
              ),
              const CarbonMenuItemDivider(),
              CarbonMenuItem(
                label: 'Delete',
                icon: CarbonIcons.trashCan,
                kind: CarbonMenuItemKind.danger,
                onPressed: () {},
              ),
              CarbonMenuItem(
                label: 'Disabled',
                icon: CarbonIcons.edit,
                disabled: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('selectable + radio across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'menu_selectable',
        containsText: true,
        size: const Size(240, 200),
        builder: (BuildContext context) => Center(
          child: CarbonMenu(
            autofocus: false,
            children: <Widget>[
              CarbonMenuItemSelectable(
                label: 'Word wrap',
                selected: true,
                onChanged: (_) {},
              ),
              CarbonMenuItemSelectable(
                label: 'Minimap',
                selected: false,
                onChanged: (_) {},
              ),
              const CarbonMenuItemDivider(),
              CarbonMenuItemRadioGroup<String>(
                label: 'Theme',
                value: 'light',
                onChanged: (_) {},
                options: const <(String, String)>[
                  ('light', 'Light'),
                  ('dark', 'Dark'),
                ],
              ),
            ],
          ),
        ),
      );
    });
  });
}

/// The label of the menu row that currently owns primary focus.
String? _focusedLabel(WidgetTester tester) {
  for (final Focus f in tester.widgetList<Focus>(find.byType(Focus))) {
    if (f.focusNode?.hasPrimaryFocus ?? false) {
      final Finder textIn = find.descendant(
        of: find.byWidget(f),
        matching: find.byType(Text),
      );
      if (textIn.evaluate().isNotEmpty) {
        return (textIn.evaluate().first.widget as Text).data;
      }
    }
  }
  return null;
}
