// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Align(alignment: Alignment.topLeft, child: child),
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

  group('panel', () {
    testWidgets('expanded is 256px and shows labels; rail is 48px', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonSideNav(
            items: <Widget>[
              CarbonSideNavLink(
                label: 'Dashboard',
                icon: CarbonIcons.dashboard,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(CarbonSideNav)).width, 256);
      expect(find.text('Dashboard'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          CarbonSideNav(
            expanded: false,
            items: <Widget>[
              CarbonSideNavLink(
                label: 'Dashboard',
                icon: CarbonIcons.dashboard,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(CarbonSideNav)).width, 48);
      // The rail hides labels (icon only).
      expect(find.text('Dashboard'), findsNothing);
    });
  });

  group('links', () {
    testWidgets('current link: layer-selected + 4px interactive marker', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonSideNav(
            items: <Widget>[
              CarbonSideNavLink(label: 'Home', current: true, onPressed: () {}),
            ],
          ),
        ),
      );
      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('Home'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(deco.color, theme.layerSelected01);
      final BorderDirectional border = deco.border! as BorderDirectional;
      expect(border.start.width, 3);
      expect(border.start.color, theme.borderInteractive);
      expect(
        tester.widget<Text>(find.text('Home')).style!.fontWeight,
        FontWeight.w600,
      );
    });

    testWidgets('tapping a link navigates', (WidgetTester tester) async {
      int went = 0;
      await tester.pumpWidget(
        _host(
          CarbonSideNav(
            items: <Widget>[
              CarbonSideNavLink(label: 'Docs', onPressed: () => went++),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Docs'));
      expect(went, 1);
    });
  });

  group('menu', () {
    testWidgets('a menu expands and collapses its children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonSideNav(
            items: <Widget>[
              CarbonSideNavMenu(
                label: 'Reports',
                children: <Widget>[
                  CarbonSideNavMenuItem(label: 'Daily', onPressed: () {}),
                  CarbonSideNavMenuItem(label: 'Weekly', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Children present but collapsed (height factor 0).
      final double collapsed = tester
          .widget<Align>(
            find
                .ancestor(of: find.text('Daily'), matching: find.byType(Align))
                .first,
          )
          .heightFactor!;
      expect(collapsed, 0);
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      final double open = tester
          .widget<Align>(
            find
                .ancestor(of: find.text('Daily'), matching: find.byType(Align))
                .first,
          )
          .heightFactor!;
      expect(open, 1);
    });
  });

  group('goldens', () {
    testWidgets('side nav across themes (gray-100 is the dark shell)', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'ui_shell_side_nav',
        containsText: true,
        size: const Size(280, 260),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topLeft,
          child: CarbonSideNav(
            items: <Widget>[
              CarbonSideNavLink(
                label: 'Dashboard',
                icon: CarbonIcons.dashboard,
                current: true,
                onPressed: () {},
              ),
              CarbonSideNavLink(
                label: 'Documents',
                icon: CarbonIcons.document,
                onPressed: () {},
              ),
              const CarbonSideNavDivider(),
              CarbonSideNavMenu(
                label: 'Reports',
                icon: CarbonIcons.chartBar,
                initiallyExpanded: true,
                children: <Widget>[
                  CarbonSideNavMenuItem(label: 'Daily', onPressed: () {}),
                  CarbonSideNavMenuItem(label: 'Weekly', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });
  });

  group('rail (_side-nav.scss --side-nav--rail, SideNav isRail)', () {
    List<Widget> items() => <Widget>[
      CarbonSideNavLink(
        label: 'Dashboard',
        icon: CarbonIcons.dashboard,
        current: true,
        onPressed: () {},
      ),
      CarbonSideNavLink(
        label: 'Documents',
        icon: CarbonIcons.document,
        onPressed: () {},
      ),
    ];

    /// Hosts the rail beside a content marker inside the Overlay a portal
    /// needs; returns nothing — the marker key is [contentKey].
    const Key contentKey = Key('content');
    Widget railHost({bool reducedMotion = false}) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              OverlayEntry(
                builder: (BuildContext context) => SizedBox(
                  height: 400,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CarbonSideNav(rail: true, items: items()),
                      const Expanded(child: SizedBox(key: contentKey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    testWidgets('hovering expands a 256px overlay without reflowing content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(railHost());
      expect(tester.getSize(find.byType(CarbonSideNav)).width, 48);
      // Rail: icons only, no visible labels.
      expect(find.text('Dashboard'), findsNothing);
      final double contentLeft = tester.getTopLeft(find.byKey(contentKey)).dx;

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(const Offset(24, 24));
      await tester.pumpAndSettle();

      // The overlay expands to 256px and reveals the labels...
      expect(find.text('Dashboard'), findsOneWidget);
      final Finder overlayBox = find.ancestor(
        of: find.text('Dashboard'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(overlayBox.first).width, 256);
      // ...while the page content does not move (overlay, not reflow).
      expect(tester.getTopLeft(find.byKey(contentKey)).dx, contentLeft);
      expect(tester.getSize(find.byType(CarbonSideNav)).width, 48);

      // Leaving collapses and removes the overlay.
      await gesture.moveTo(const Offset(600, 24));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('focus entering the rail expands; blur collapses; Escape '
        'closes', (WidgetTester tester) async {
      await tester.pumpWidget(railHost());
      // Focus the first rail item.
      final FocusNode node =
          tester
              .widget<Focus>(
                find
                    .descendant(
                      of: find.byType(CarbonSideNavLink),
                      matching: find.byWidgetPredicate(
                        (Widget w) => w is Focus && w.onKeyEvent != null,
                      ),
                    )
                    .first,
              )
              .focusNode ??
          Focus.of(
            tester.element(
              find
                  .descendant(
                    of: find.byType(CarbonSideNavLink),
                    matching: find.byType(CarbonIcon),
                  )
                  .first,
            ),
          );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);

      // Escape collapses and drops focus.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('reduced motion expands and collapses without animating', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(railHost(reducedMotion: true));
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(const Offset(24, 24));
      await tester.pump();
      await tester.pump();
      final Finder overlayBox = find.ancestor(
        of: find.text('Dashboard'),
        matching: find.byType(AnimatedContainer),
      );
      expect(tester.getSize(overlayBox.first).width, 256);

      await gesture.moveTo(const Offset(600, 24));
      await tester.pump();
      await tester.pump();
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('rail collapsed, mid-transition and expanded across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'ui_shell_side_nav_rail',
        containsText: true,
        size: const Size(360, 240),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => SizedBox(
                height: 240,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    CarbonSideNav(rail: true, items: items()),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          final TestGesture gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await gesture.addPointer(location: Offset.zero);
          await gesture.moveTo(const Offset(24, 24));
          await tester.pumpAndSettle();
          await gesture.removePointer();
        },
      );
    });
  });
}
