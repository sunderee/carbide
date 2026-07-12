// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

TextStyle _styleOf(WidgetTester tester) => tester
    .widget<AnimatedDefaultTextStyle>(find.byType(AnimatedDefaultTextStyle))
    .style;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('spec locks (styles/scss/components/link/_link.scss)', () {
    test('sizes map to the spec type styles and icon sizes', () {
      expect(CarbonLinkSize.sm.style, CarbonTypeStyles.helperText01);
      expect(CarbonLinkSize.md.style, CarbonTypeStyles.bodyCompact01);
      expect(CarbonLinkSize.lg.style, CarbonTypeStyles.bodyCompact02);
      expect(CarbonLinkSize.sm.iconSize, 16);
      expect(CarbonLinkSize.lg.iconSize, 20);
    });

    testWidgets('trailing icon: 8px gap, color follows the link', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonLink(label: 'Docs', icon: CarbonIcons.launch, onPressed: () {}),
        ),
      );
      final double gap =
          tester.getTopLeft(find.byType(CarbonIcon)).dx -
          tester.getTopRight(find.text('Docs')).dx;
      expect(gap, 8);
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CarbonIcon),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as CarbonIconPainter).color, theme.linkPrimary);
    });
  });

  group('state colors and underline', () {
    testWidgets('rest: linkPrimary, no underline (standalone)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(CarbonLink(label: 'L', onPressed: () {})));
      expect(_styleOf(tester).color, theme.linkPrimary);
      expect(_styleOf(tester).decoration, isNull);
    });

    testWidgets('hover: linkPrimaryHover + underline; wins over visited', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonLink(label: 'L', visited: true, onPressed: () {})),
      );
      expect(_styleOf(tester).color, theme.linkVisited);

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CarbonLink)),
      );
      await tester.pumpAndSettle();
      expect(_styleOf(tester).color, theme.linkPrimaryHover);
      expect(_styleOf(tester).decoration, TextDecoration.underline);
    });

    testWidgets('focus: rest color + underline + 1px focus outline', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonLink(
            label: 'L',
            visited: true,
            focusNode: node,
            onPressed: () {},
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      // Focus snaps visited back to the rest color, per spec.
      expect(_styleOf(tester).color, theme.linkPrimary);
      expect(_styleOf(tester).decoration, TextDecoration.underline);
      final DecoratedBox outline = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CarbonLink),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (outline.decoration as BoxDecoration).border!.top.color,
        theme.focus,
      );
    });

    testWidgets('inline is always underlined, even disabled; standalone '
        'disabled is not', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonLink(label: 'L', inline: true, onPressed: null)),
      );
      expect(_styleOf(tester).color, theme.textDisabled);
      expect(_styleOf(tester).decoration, TextDecoration.underline);

      await tester.pumpWidget(
        _host(const CarbonLink(label: 'L', onPressed: null)),
      );
      await tester.pumpAndSettle();
      expect(_styleOf(tester).decoration, isNull);
    });
  });

  group('interaction & semantics', () {
    testWidgets('tap and keyboard activate; disabled does not', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonLink(label: 'Go', focusNode: node, onPressed: () => pressed++),
        ),
      );
      await tester.tap(find.byType(CarbonLink));
      expect(pressed, 1);
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, 2);

      await tester.pumpWidget(
        _host(const CarbonLink(label: 'Go', onPressed: null)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CarbonLink));
      expect(pressed, 2);
    });

    testWidgets('exposes link semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonLink(label: 'Guidelines', onPressed: () {})),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Guidelines')),
        isSemantics(label: 'Guidelines', isLink: true, isEnabled: true),
      );
      handle.dispose();
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonLink(label: 'Standalone', onPressed: () {}),
              CarbonLink(
                label: 'With icon',
                icon: CarbonIcons.launch,
                onPressed: () {},
              ),
              CarbonLink(label: 'Inline', inline: true, onPressed: () {}),
            ],
          ),
        ),
      );
      // Links are text-height by design (`_link.scss` sets no min
      // block-size); nodes flagged `isLink` are exempt from the 48dp rule
      // (WCAG 2.1 target-size link exception, applied by
      // androidTapTargetGuideline itself), so both axes stay on.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  testWidgets('link states across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'link',
      containsText: true,
      size: const Size(260, 130),
      builder: (BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CarbonLink(label: 'Standalone link', onPressed: () {}),
            CarbonLink(label: 'Visited link', visited: true, onPressed: () {}),
            const CarbonLink(label: 'Disabled link', onPressed: null),
            CarbonLink(
              label: 'With icon',
              icon: CarbonIcons.launch,
              onPressed: () {},
            ),
            CarbonLink(
              label: 'Large inline',
              size: CarbonLinkSize.lg,
              inline: true,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('focused link shows the 1px focus outline', (
    WidgetTester tester,
  ) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);
    await expectThemeGoldens(
      tester,
      name: 'link_focus',
      containsText: true,
      size: const Size(220, 80),
      builder: (BuildContext context) => Center(
        child: CarbonLink(
          label: 'Focused link',
          focusNode: node,
          onPressed: () {},
        ),
      ),
      afterPump: (WidgetTester tester) async {
        node.requestFocus();
        await tester.pumpAndSettle();
      },
    );
  });
}
