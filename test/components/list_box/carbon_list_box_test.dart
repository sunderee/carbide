// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 320, child: child)),
  ),
);

BoxDecoration _fieldDecoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration
        as BoxDecoration;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('CarbonListBox field (_list-box.scss)', () {
    testWidgets('heights per size; bg field; chevron present', (
      WidgetTester tester,
    ) async {
      for (final (CarbonFieldSize size, double height)
          in <(CarbonFieldSize, double)>[
            (CarbonFieldSize.sm, 32),
            (CarbonFieldSize.md, 40),
            (CarbonFieldSize.lg, 48),
          ]) {
        await tester.pumpWidget(
          _host(CarbonListBox(size: size, child: const Text('Pick one'))),
        );
        // The field height animates (fast-01) between re-pumps; settle it.
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(CarbonListBox)).height,
          height,
          reason: '$size',
        );
      }
      expect(_fieldDecoration(tester).color, theme.field01);
      expect(find.byType(CarbonListBoxMenuIcon), findsOneWidget);
    });

    testWidgets('rest border is 1px border-strong bottom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonListBox(child: Text('v'))));
      final Border border = _fieldDecoration(tester).border! as Border;
      expect(border.bottom.width, 1);
      expect(border.bottom.color, theme.borderStrong01);
      expect(border.top, BorderSide.none);
    });

    testWidgets('expanded softens the border to border-subtle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonListBox(expanded: true, child: Text('v'))),
      );
      final Border border = _fieldDecoration(tester).border! as Border;
      expect(border.bottom.color, theme.borderSubtle00);
    });

    testWidgets('background is contextual inside a CarbonLayer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonLayer(child: CarbonListBox(child: Text('v')))),
      );
      expect(_fieldDecoration(tester).color, theme.field02);
    });

    testWidgets('disabled: transparent border, disabled label, inert tap', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _host(
          CarbonListBox(
            disabled: true,
            onTap: () => taps++,
            child: const Text('v'),
          ),
        ),
      );
      final Border border = _fieldDecoration(tester).border! as Border;
      expect(border.bottom.color, const Color(0x00000000));
      expect(tester.widget<Text>(find.text('v')).style?.color, isNull);
      // DefaultTextStyle carries the disabled colour.
      final DefaultTextStyle ds = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('v'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(ds.style.color, theme.textDisabled);
      await tester.tap(find.byType(CarbonListBox));
      expect(taps, 0);
    });

    testWidgets('invalid: 2px error ring + ErrorFilled icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonListBox(invalid: true, child: Text('v'))),
      );
      final Border border = _fieldDecoration(tester).border! as Border;
      expect(border.top.width, 2);
      expect(border.top.color, theme.supportError);
      final CarbonIconPainter icon =
          tester
                  .widget<CustomPaint>(
                    find
                        .descendant(
                          of: find.byType(CarbonIcon),
                          matching: find.byType(CustomPaint),
                        )
                        .first,
                  )
                  .painter!
              as CarbonIconPainter;
      expect(icon.color, theme.supportError);
    });

    testWidgets('warning: WarningAltFilled, bottom border stays', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonListBox(warn: true, child: Text('v'))),
      );
      final Border border = _fieldDecoration(tester).border! as Border;
      expect(border.bottom.color, theme.borderStrong01);
      final CarbonIconPainter icon =
          tester
                  .widget<CustomPaint>(
                    find
                        .descendant(
                          of: find.byType(CarbonIcon),
                          matching: find.byType(CustomPaint),
                        )
                        .first,
                  )
                  .painter!
              as CarbonIconPainter;
      expect(icon.color, theme.supportWarning);
    });

    testWidgets('tap fires onTap; focus ring when focused', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _host(CarbonListBox(onTap: () => taps++, child: const Text('v'))),
      );
      await tester.tap(find.byType(CarbonListBox));
      expect(taps, 1);

      await tester.pumpWidget(
        _host(const CarbonListBox(focused: true, child: Text('v'))),
      );
      final CustomPaint ring = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CarbonFocusRing),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(ring.foregroundPainter, isNotNull);
    });
  });

  group('CarbonListBoxMenuIcon', () {
    testWidgets('24x24; rotates 0.5 turns when open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const Align(child: CarbonListBoxMenuIcon(open: false))),
      );
      expect(
        tester.getSize(find.byType(CarbonListBoxMenuIcon)),
        const Size(24, 24),
      );
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0,
      );

      await tester.pumpWidget(_host(const CarbonListBoxMenuIcon(open: true)));
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0.5,
      );
    });
  });

  group('CarbonListBoxMenu', () {
    testWidgets('layer background + 5.5-row max height per size', (
      WidgetTester tester,
    ) async {
      for (final (CarbonFieldSize size, double maxHeight)
          in <(CarbonFieldSize, double)>[
            (CarbonFieldSize.sm, 176),
            (CarbonFieldSize.md, 220),
            (CarbonFieldSize.lg, 264),
          ]) {
        await tester.pumpWidget(
          _host(
            CarbonListBoxMenu(
              size: size,
              children: const <Widget>[Text('item')],
            ),
          ),
        );
        final bool hasCap = tester
            .widgetList<ConstrainedBox>(find.byType(ConstrainedBox))
            .any((ConstrainedBox b) => b.constraints.maxHeight == maxHeight);
        expect(hasCap, isTrue, reason: '$size → $maxHeight');
      }
      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(CarbonListBoxMenu),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(deco.color, theme.layer01);
      expect(deco.boxShadow, isNotNull);
    });
  });

  group('CarbonListBoxMenuItem', () {
    BoxDecoration dividerDecoration(WidgetTester tester) =>
        tester
                .widget<Container>(
                  find.descendant(
                    of: find.byType(CarbonListBoxMenuItem),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration;

    Color background(WidgetTester tester) => tester
        .widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(CarbonListBoxMenuItem),
                matching: find.byType(ColoredBox),
              )
              .first,
        )
        .color;

    testWidgets('height per size; default secondary text, no active bg', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonListBoxMenuItem(
            size: CarbonFieldSize.lg,
            child: Text('Option'),
          ),
        ),
      );
      expect(tester.getSize(find.byType(Container)).height, 48);
      expect(background(tester), const Color(0x00000000));
      final DefaultTextStyle ds = tester.widget<DefaultTextStyle>(
        find
            .descendant(
              of: find.byType(CarbonListBoxMenuItem),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(ds.style.color, theme.textSecondary);
    });

    testWidgets('active row: layer-selected bg + primary text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonListBoxMenuItem(isActive: true, child: Text('Option')),
        ),
      );
      expect(background(tester), theme.layerSelected01);
    });

    testWidgets('highlighted row: layer-hover bg, no divider, focus ring', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonListBoxMenuItem(
            isHighlighted: true,
            child: Text('Option'),
          ),
        ),
      );
      expect(background(tester), theme.layerHover01);
      expect(
        (dividerDecoration(tester).border! as Border).top.color,
        const Color(0x00000000),
      );
      final CustomPaint ring = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CarbonFocusRing),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(ring.foregroundPainter, isNotNull);
    });

    testWidgets('first row suppresses its divider; others show border-subtle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonListBoxMenuItem(isFirst: true, child: Text('A'))),
      );
      expect(
        (dividerDecoration(tester).border! as Border).top.color,
        const Color(0x00000000),
      );

      await tester.pumpWidget(
        _host(const CarbonListBoxMenuItem(child: Text('B'))),
      );
      expect(
        (dividerDecoration(tester).border! as Border).top.color,
        theme.borderSubtle00,
      );
    });

    testWidgets('tap fires; disabled is inert and greyed', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _host(
          CarbonListBoxMenuItem(onTap: () => taps++, child: const Text('Opt')),
        ),
      );
      await tester.tap(find.byType(CarbonListBoxMenuItem));
      expect(taps, 1);

      taps = 0;
      await tester.pumpWidget(
        _host(
          CarbonListBoxMenuItem(
            disabled: true,
            onTap: () => taps++,
            child: const Text('Opt'),
          ),
        ),
      );
      await tester.tap(find.byType(CarbonListBoxMenuItem));
      expect(taps, 0);
      final DefaultTextStyle ds = tester.widget<DefaultTextStyle>(
        find
            .descendant(
              of: find.byType(CarbonListBoxMenuItem),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(ds.style.color, theme.textDisabled);
    });
  });

  group('CarbonListBoxSelection', () {
    testWidgets('24x24 clear button; fires onClear; labeled', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int clears = 0;
      await tester.pumpWidget(
        _host(Align(child: CarbonListBoxSelection(onClear: () => clears++))),
      );
      expect(
        tester.getSize(find.byType(CarbonListBoxSelection)),
        const Size(24, 24),
      );
      expect(find.bySemanticsLabel('Clear selection'), findsOneWidget);
      await tester.tap(find.byType(CarbonListBoxSelection));
      expect(clears, 1);
      handle.dispose();
    });
  });

  group('CarbonListBoxSelectionCount', () {
    testWidgets('count pill: inverse bg, radius 12, clear control', (
      WidgetTester tester,
    ) async {
      int clears = 0;
      await tester.pumpWidget(
        _host(
          Align(
            child: CarbonListBoxSelectionCount(
              count: 3,
              onClear: () => clears++,
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      // The pill is a fixed 24px box; assert the count renders at its full
      // line height (regression for the clip bug #162 — find.text passing only
      // proves the widget exists, not that it is legible).
      expectTextNotClipped(tester, find.text('3'));
      expect(
        tester.getSize(find.byType(CarbonListBoxSelectionCount)).height,
        24,
      );
      final BoxDecoration deco =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(CarbonListBoxSelectionCount),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(deco.color, theme.backgroundInverse);
      expect(deco.borderRadius, BorderRadius.circular(12));
      await tester.tap(find.byType(CarbonIcon));
      expect(clears, 1);
    });

    testWidgets('disabled uses layer bg + disabled text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Align(
            child: CarbonListBoxSelectionCount(
              count: 2,
              disabled: true,
              onClear: () {},
            ),
          ),
        ),
      );
      final BoxDecoration deco =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byType(CarbonListBoxSelectionCount),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(deco.color, theme.layer01);
      expect(
        tester.widget<Text>(find.text('2')).style!.color,
        theme.textDisabled,
      );
    });
  });

  group('goldens', () {
    testWidgets('field states across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'list_box_field_states',
        containsText: true,
        size: const Size(320, 320),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonListBox(child: Text('Default')),
                SizedBox(height: 12),
                CarbonListBox(expanded: true, child: Text('Open')),
                SizedBox(height: 12),
                CarbonListBox(invalid: true, child: Text('Invalid')),
                SizedBox(height: 12),
                CarbonListBox(warn: true, child: Text('Warning')),
                SizedBox(height: 12),
                CarbonListBox(disabled: true, child: Text('Disabled')),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('menu with rows across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'list_box_menu',
        containsText: true,
        size: const Size(320, 220),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 280,
            child: CarbonListBoxMenu(
              children: <Widget>[
                CarbonListBoxMenuItem(isFirst: true, child: Text('Apple')),
                CarbonListBoxMenuItem(isActive: true, child: Text('Banana')),
                CarbonListBoxMenuItem(
                  isHighlighted: true,
                  child: Text('Cherry'),
                ),
                CarbonListBoxMenuItem(child: Text('Date')),
                CarbonListBoxMenuItem(
                  disabled: true,
                  child: Text('Elderberry'),
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('field focus ring', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'list_box_field_focus',
        containsText: true,
        size: const Size(320, 70),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 280,
            child: CarbonListBox(focused: true, child: Text('Focused')),
          ),
        ),
      );
    });

    testWidgets('multi-select count badge across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'list_box_count',
        containsText: true,
        size: const Size(200, 80),
        builder: (BuildContext context) => Center(
          child: CarbonListBoxSelectionCount(count: 4, onClear: () {}),
        ),
      );
    });
  });
}
