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
import '../../support/legibility.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    // Selection/style cases fit four labels even with the web test font.
    // tabs_overflow_test.dart separately forces and navigates 320px overflow.
    child: Center(child: SizedBox(width: 760, child: child)),
  ),
);

const List<CarbonTab> _tabs = <CarbonTab>[
  CarbonTab(label: 'Overview'),
  CarbonTab(label: 'Details'),
  CarbonTab(label: 'Settings', disabled: true),
  CarbonTab(label: 'Activity'),
];

const List<Widget> _panels = <Widget>[
  Text('Overview panel'),
  Text('Details panel'),
  Text('Settings panel'),
  Text('Activity panel'),
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

  group('motion', () {
    testWidgets('tab transition tokens match _tabs.scss', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(CarbonTabs(tabs: _tabs, panels: _panels)));
      // `__nav-item`: color / border-bottom-color / outline
      // $duration-fast-01 motion(standard, productive).
      final AnimatedContainer tab = tester.widget(
        find.byType(AnimatedContainer).first,
      );
      expect(tab.duration, CarbonDuration.fast01);
      expect(tab.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion is instant', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: CarbonTabs(tabs: _tabs, panels: _panels),
          ),
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
            .duration,
        Duration.zero,
      );
    });
  });

  BoxDecoration decorationOf(WidgetTester tester, String label) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .ancestor(
                      of: find.text(label),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;

  group('selection', () {
    testWidgets('first panel shown by default; tapping switches', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(CarbonTabs(tabs: _tabs, panels: _panels)));
      expect(find.text('Overview panel'), findsOneWidget);
      expect(find.text('Details panel'), findsNothing);
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Details panel'), findsOneWidget);
      expect(find.text('Overview panel'), findsNothing);
    });

    testWidgets('disabled tab does not activate', (WidgetTester tester) async {
      await tester.pumpWidget(_host(CarbonTabs(tabs: _tabs, panels: _panels)));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings panel'), findsNothing);
      expect(find.text('Overview panel'), findsOneWidget);
    });

    testWidgets('controlled selectedIndex + onChanged', (
      WidgetTester tester,
    ) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          CarbonTabs(
            tabs: _tabs,
            panels: _panels,
            selectedIndex: 1,
            onChanged: (int i) => changed = i,
          ),
        ),
      );
      expect(find.text('Details panel'), findsOneWidget);
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      expect(changed, 3);
      // Controlled: panel stays until the parent updates selectedIndex.
      expect(find.text('Details panel'), findsOneWidget);
    });
  });

  group('keyboard roving', () {
    testWidgets('Right/Left move + activate, skipping disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(CarbonTabs(tabs: _tabs, panels: _panels)));
      // Focus the first tab, then arrow across.
      tester
          .widget<Focus>(
            find
                .ancestor(
                  of: find.text('Overview'),
                  matching: find.byType(Focus),
                )
                .first,
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Details panel'), findsOneWidget);
      // Right again skips the disabled 'Settings' and lands on 'Activity'.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Activity panel'), findsOneWidget);
      // End/Home jump to the last/first enabled tab.
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(find.text('Overview panel'), findsOneWidget);
    });
  });

  group('chrome', () {
    testWidgets('line: selected tab has a 2px interactive underline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(CarbonTabs(tabs: _tabs, panels: _panels)));
      await tester.pumpAndSettle();
      final Border border = decorationOf(tester, 'Overview').border! as Border;
      expect(border.bottom.width, 2);
      expect(border.bottom.color, theme.borderInteractive);
      // An unselected tab uses the 1px subtle underline.
      final Border other = decorationOf(tester, 'Details').border! as Border;
      expect(other.bottom.width, 1);
      expect(other.bottom.color, theme.borderSubtle00);
      // Tab labels sit in a fixed-height tab; keep them legible.
      expectTextNotClipped(tester, find.text('Overview'));
    });

    testWidgets('contained: selected tab is filled with the layer token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonTabs(
            tabs: _tabs,
            panels: _panels,
            variant: CarbonTabVariant.contained,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester, 'Overview').color, theme.layer01);
      expect(decorationOf(tester, 'Details').color, theme.layerAccent01);
    });

    testWidgets('dismissable tab exposes a labelled close', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int dismissed = 0;
      await tester.pumpWidget(
        _host(
          CarbonTabs(
            tabs: <CarbonTab>[
              CarbonTab(
                label: 'Draft',
                dismissable: true,
                onDismiss: () => dismissed++,
              ),
            ],
            panels: const <Widget>[Text('Draft panel')],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Dismiss Draft'), findsOneWidget);
      await tester.tap(find.byType(CarbonIcon));
      expect(dismissed, 1);
      handle.dispose();
    });
  });

  group('semantics', () {
    testWidgets('tabs expose selected state', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CarbonTabs(tabs: _tabs, panels: _panels)));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Overview')),
        isSemantics(label: 'Overview', isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Details')),
        isSemantics(label: 'Details', isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The Dart default is already lg (48px); _tabs.scss defaults the tab
      // bar to md (40px), which would sit below the 48dp android guideline.
      await tester.pumpWidget(_host(CarbonTabs(tabs: _tabs, panels: _panels)));
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('line + contained across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tabs_variants',
        // Direction-sensitive geometry (#227): mirrored fill / side
        // accent / overlay side re-snapshots under RTL.
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        containsText: true,
        size: const Size(440, 220),
        builder: (BuildContext context) => DefaultTextStyle(
          style: CarbonTypeStyles.body01.copyWith(
            color: CarbonTheme.of(context).textPrimary,
          ),
          child: Center(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonTabs(tabs: _tabs, panels: _panels),
                  const SizedBox(height: 24),
                  CarbonTabs(
                    tabs: _tabs,
                    panels: _panels,
                    variant: CarbonTabVariant.contained,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  });

  group('vertical (_tabs.scss --tabs--vertical, TabListVertical)', () {
    Widget verticalHost({
      double width = 640,
      double height = 400,
      List<CarbonTab> tabs = _tabs,
      List<Widget> panels = _panels,
      CarbonTabsVerticalSize size = CarbonTabsVerticalSize.xl,
      int? selectedIndex,
      ValueChanged<int>? onChanged,
    }) => Directionality(
      textDirection: TextDirection.ltr,
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: CarbonTabsVertical(
              tabs: tabs,
              panels: panels,
              size: size,
              selectedIndex: selectedIndex,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );

    // The outer (decorated) row container is the furthest Container
    // ancestor of the label; the nearer one is the padding container.
    Container rowOf(WidgetTester tester, String label) =>
        tester.widget<Container>(
          find
              .ancestor(of: find.text(label), matching: find.byType(Container))
              .last,
        );

    testWidgets('rows are 64px by default; the list spans a quarter width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(verticalHost());
      expect(tester.getSize(find.text('Overview').first).height, isNonZero);
      final Finder overviewRow = find.ancestor(
        of: find.text('Overview'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(overviewRow.last).height, 64);
      // grid-column span 2 of 8 (span 4 of 16): a quarter of the width.
      expect(tester.getSize(overviewRow.last).width, 160);
    });

    testWidgets('row heights follow the size; sm clamps labels to one line', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(verticalHost(size: CarbonTabsVerticalSize.sm));
      final Finder overviewRow = find.ancestor(
        of: find.text('Overview'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(overviewRow.last).height, 32);
      expect(tester.widget<Text>(find.text('Overview')).maxLines, 1);

      await tester.pumpWidget(verticalHost());
      expect(tester.widget<Text>(find.text('Overview')).maxLines, 2);
    });

    testWidgets('selected row: interactive bar, heading label, no end border', (
      WidgetTester tester,
    ) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(verticalHost());

      // The 3px start bar of the selected row is border-interactive.
      final Finder selectedBar = find.descendant(
        of: find.ancestor(
          of: find.text('Overview'),
          matching: find.byType(Container),
        ),
        matching: find.byType(ColoredBox),
      );
      expect(
        tester.widget<ColoredBox>(selectedBar.first).color,
        theme.borderInteractive,
      );
      expect(tester.getSize(selectedBar.first).width, 3);

      final TextStyle selected = tester
          .widget<Text>(find.text('Overview'))
          .style!;
      expect(selected.fontWeight, FontWeight.w600);

      final BoxDecoration selectedDecoration =
          rowOf(tester, 'Overview').decoration! as BoxDecoration;
      final BorderDirectional border =
          selectedDecoration.border! as BorderDirectional;
      expect(border.end, BorderSide.none);
      expect(border.bottom.color, theme.borderSubtle00);

      // Unselected rows: subtle bar, layer-01 fill, 1px end border.
      final BoxDecoration unselected =
          rowOf(tester, 'Details').decoration! as BoxDecoration;
      expect(unselected.color, theme.layer01);
      expect(
        (unselected.border! as BorderDirectional).end.color,
        theme.borderSubtle00,
      );
      final Finder detailsBar = find.descendant(
        of: find.ancestor(
          of: find.text('Details'),
          matching: find.byType(Container),
        ),
        matching: find.byType(ColoredBox),
      );
      expect(
        tester.widget<ColoredBox>(detailsBar.first).color,
        theme.borderSubtle00,
      );
    });

    testWidgets('tap selects; Up/Down/Home/End rove, Left/Right ignored', (
      WidgetTester tester,
    ) async {
      final List<int> changes = <int>[];
      await tester.pumpWidget(verticalHost(onChanged: changes.add));
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(changes, <int>[1]);
      expect(find.text('Details panel'), findsOneWidget);

      // Down from Details skips disabled Settings to Activity.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(changes, <int>[1, 3]);

      // Left/Right do nothing in the vertical list.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(changes, <int>[1, 3]);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(changes, <int>[1, 3, 0]);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(changes, <int>[1, 3, 0, 3]);
    });

    testWidgets('overflowing lists scroll, fade, and reveal the selection', (
      WidgetTester tester,
    ) async {
      final List<CarbonTab> many = <CarbonTab>[
        for (int i = 1; i <= 12; i++) CarbonTab(label: 'Tab $i'),
      ];
      final List<Widget> panels = <Widget>[
        for (int i = 1; i <= 12; i++) Text('Panel $i'),
      ];
      await tester.pumpWidget(
        verticalHost(tabs: many, panels: panels, height: 320),
      );
      await tester.pump();

      // 12 × 64 = 768 in a 320 viewport: the bottom fade gradient shows.
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration?)?.gradient != null,
        ),
        findsOneWidget,
      );

      // Selecting a far tab scrolls it into view ((index - 1) × height).
      final ScrollController controller = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      await tester.tap(find.text('Tab 4'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      // Tab 5 (index 4) sits below the 320px viewport → scrolled to 3 × 64.
      expect(controller.offset, 192);
      expect(find.text('Panel 5'), findsOneWidget);
    });

    testWidgets('dismissable tabs assert in the vertical variant', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        verticalHost(
          tabs: const <CarbonTab>[CarbonTab(label: 'A', dismissable: true)],
          panels: const <Widget>[Text('A panel')],
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('tabs expose selected button semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(verticalHost());
      expect(
        tester.getSemantics(find.bySemanticsLabel('Overview')),
        isSemantics(label: 'Overview', isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Details')),
        isSemantics(label: 'Details', isButton: true, isSelected: false),
      );
      handle.dispose();
    });

    testWidgets('vertical tabs across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tabs_vertical',
        containsText: true,
        size: const Size(640, 300),
        builder: (BuildContext context) => DefaultTextStyle(
          style: CarbonTypeStyles.body01.copyWith(
            color: CarbonTheme.of(context).textPrimary,
          ),
          child: Center(
            child: SizedBox(
              width: 600,
              height: 260,
              child: CarbonTabsVertical(
                tabs: const <CarbonTab>[
                  CarbonTab(label: 'Overview'),
                  CarbonTab(label: 'Details'),
                  CarbonTab(label: 'Settings', disabled: true),
                  CarbonTab(label: 'A longer label that wraps to two lines'),
                ],
                panels: const <Widget>[
                  Text('Overview panel'),
                  Text('Details panel'),
                  Text('Settings panel'),
                  Text('Long panel'),
                ],
              ),
            ),
          ),
        ),
      );
    });
  });
}
