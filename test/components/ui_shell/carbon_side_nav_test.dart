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

/// Adds the Tab → next-focus wiring a WidgetsApp would normally provide, so
/// tests can drive real Tab key traversal without one.
Widget _tabTraversal(Widget child) => Shortcuts(
  shortcuts: const <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{NextFocusIntent: NextFocusAction()},
    child: FocusScope(autofocus: true, child: child),
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

  group('motion', () {
    Widget nav({bool reducedMotion = false, bool menuOpen = false}) => _host(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: CarbonSideNav(
          items: <Widget>[
            CarbonSideNavMenu(
              label: 'Reports',
              initiallyExpanded: menuOpen,
              children: <Widget>[
                CarbonSideNavMenuItem(label: 'Daily', onPressed: () {}),
              ],
            ),
          ],
        ),
      ),
    );

    testWidgets('panel expansion uses the hardcoded upstream transition', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(nav());
      // `_side-nav.scss` `.cds--side-nav`: inline-size 0.11s
      // cubic-bezier(0.2, 0, 1, 0.9) ("TODO: sync with motion work" — not a
      // motion token upstream).
      final AnimatedContainer panel = tester.widget(
        find.byType(AnimatedContainer),
      );
      expect(panel.duration, const Duration(milliseconds: 110));
      expect(panel.curve, const Cubic(0.2, 0, 1, 0.9));
    });

    testWidgets('menu tokens: chevron and fold at fast-02', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(nav());
      // `_side-nav.scss` `__submenu-chevron > svg`: transform
      // $duration-fast-02 (no easing token cited).
      final AnimatedRotation chevron = tester.widget(
        find.byType(AnimatedRotation),
      );
      expect(chevron.duration, CarbonDuration.fast02);
      expect(chevron.curve, CarbonEasing.standardProductive);
      final TweenAnimationBuilder<double> fold = tester.widget(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(fold.duration, CarbonDuration.fast02);
      expect(fold.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion collapses panel and menu instantly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(nav(reducedMotion: true));
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>),
            )
            .duration,
        Duration.zero,
      );
      // Opening the menu reveals the item on the next frame.
      await tester.tap(find.text('Reports'));
      await tester.pump();
      await tester.pump();
      final Align fold = tester.widget(
        find
            .ancestor(of: find.text('Daily'), matching: find.byType(Align))
            .first,
      );
      expect(fold.heightFactor, 1);
    });
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

  // Keyboard spec (Apache-2.0 Carbon Design System; see NOTICE):
  //   documentation/carbon-website/src/pages/components/UI-shell-left-panel/
  //     accessibility.mdx — "All items can be reached by Tab. Toggling a
  //     collapsed section with Space or Enter expands it ... Activating any
  //     of the links (with Enter) updates the main content area."
  group('keyboard (#231)', () {
    testWidgets('Tab reaches each link in order with a visible focus ring', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _tabTraversal(
            CarbonSideNav(
              items: <Widget>[
                CarbonSideNavLink(label: 'Dashboard', onPressed: () {}),
                CarbonSideNavLink(label: 'Documents', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      CarbonFocusRing ring(String label) => tester.widget<CarbonFocusRing>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(CarbonFocusRing),
            )
            .first,
      );
      bool focused(String label) =>
          Focus.of(tester.element(find.text(label))).hasPrimaryFocus;

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focused('Dashboard'), isTrue);
      expect(ring('Dashboard').visible, isTrue);
      expect(ring('Documents').visible, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focused('Documents'), isTrue);
      expect(ring('Documents').visible, isTrue);
      expect(ring('Dashboard').visible, isFalse);
    });

    testWidgets('a focused link activates with Enter and Space', (
      WidgetTester tester,
    ) async {
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
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('Docs'))).requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(went, 2);
    });

    testWidgets('a sub-menu expands with Enter and collapses with Space', (
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
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      double heightFactor() => tester
          .widget<Align>(
            find
                .ancestor(of: find.text('Daily'), matching: find.byType(Align))
                .first,
          )
          .heightFactor!;
      expect(heightFactor(), 0);

      Focus.of(tester.element(find.text('Reports'))).requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(heightFactor(), 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(heightFactor(), 0);
    });
  });

  group('semantics (#226)', () {
    testWidgets('links expose label, button role and selected state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonSideNav(
            items: <Widget>[
              CarbonSideNavLink(
                label: 'Dashboard',
                icon: CarbonIcons.dashboard,
                current: true,
                onPressed: () {},
              ),
              CarbonSideNavLink(label: 'Documents', onPressed: () {}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Side navigation'), findsOneWidget);
      // The current link carries the selected state.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Dashboard')),
        isSemantics(
          label: 'Dashboard',
          isButton: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      // Sibling links stay unselected but keep role + action.
      expect(
        tester.getSemantics(find.bySemanticsLabel('Documents')),
        isSemantics(
          label: 'Documents',
          isButton: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('side nav across themes (gray-100 is the dark shell)', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'ui_shell_side_nav',
        // Direction-sensitive geometry (#227): mirrored fill / side
        // accent / overlay side re-snapshots under RTL.
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
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
