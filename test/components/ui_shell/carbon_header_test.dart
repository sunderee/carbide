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

import '../../support/golden.dart';

/// CarbonHeaderMenu's dropdown needs an Overlay + TapRegionSurface + backdrop.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) => Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),
                Align(alignment: Alignment.topCenter, child: child),
              ],
            ),
          ),
        ],
      ),
    ),
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

  group('structure', () {
    testWidgets('48px bar with name, nav and global actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(prefix: 'IBM', name: 'Carbide'),
            navigation: <Widget>[
              CarbonHeaderMenuItem(label: 'Catalog', onPressed: () {}),
            ],
            globalActions: <Widget>[
              CarbonHeaderGlobalAction(
                icon: CarbonIcons.notification,
                label: 'Notifications',
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('IBM'), findsOneWidget);
      expect(find.text('Carbide'), findsOneWidget);
      expect(find.text('Catalog'), findsOneWidget);
      expect(tester.getSize(find.byType(CarbonHeader)).height, 48);
      expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    });

    testWidgets('selected nav item has the 2px interactive underline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            navigation: <Widget>[
              CarbonHeaderMenuItem(
                label: 'Home',
                selected: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
      final Border border =
          (tester
                          .widget<DecoratedBox>(
                            find
                                .ancestor(
                                  of: find.text('Home'),
                                  matching: find.byType(DecoratedBox),
                                )
                                .first,
                          )
                          .decoration
                      as BoxDecoration)
                  .border!
              as Border;
      expect(border.bottom.width, 2);
      expect(border.bottom.color, theme.borderInteractive);
    });
  });

  group('interaction', () {
    testWidgets('nav item + global action fire', (WidgetTester tester) async {
      int nav = 0;
      int action = 0;
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            navigation: <Widget>[
              CarbonHeaderMenuItem(label: 'Docs', onPressed: () => nav++),
            ],
            globalActions: <Widget>[
              CarbonHeaderGlobalAction(
                icon: CarbonIcons.search,
                label: 'Search',
                onPressed: () => action++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Docs'));
      await tester.tap(find.bySemanticsLabel('Search'));
      expect(nav, 1);
      expect(action, 1);
    });

    testWidgets('menu button swaps to a close icon when open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonHeader(
            menuButton: CarbonHeaderMenuButton(
              label: 'Open menu',
              isOpen: true,
            ),
            name: CarbonHeaderName(name: 'App'),
          ),
        ),
      );
      final bool hasClose = tester
          .widgetList<CarbonIcon>(find.byType(CarbonIcon))
          .any((CarbonIcon i) => i.icon == CarbonIcons.close);
      expect(hasClose, isTrue);
    });

    testWidgets('header name fires onPressed when tapped', (
      WidgetTester tester,
    ) async {
      int tapped = 0;
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: CarbonHeaderName(
              prefix: 'IBM',
              name: 'Carbide',
              onPressed: () => tapped++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Carbide'));
      expect(tapped, 1);
    });

    testWidgets('nav item activates with Enter and Space and shows the '
        'focus ring', (WidgetTester tester) async {
      int pressed = 0;
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            navigation: <Widget>[
              CarbonHeaderMenuItem(label: 'Docs', onPressed: () => pressed++),
            ],
          ),
        ),
      );
      Focus.of(tester.element(find.text('Docs'))).requestFocus();
      await tester.pumpAndSettle();
      final CarbonFocusRing ring = tester.widget<CarbonFocusRing>(
        find
            .ancestor(
              of: find.text('Docs'),
              matching: find.byType(CarbonFocusRing),
            )
            .first,
      );
      expect(ring.visible, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(pressed, 2);
    });

    testWidgets('hovering a nav item shows the hover background', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            navigation: <Widget>[
              CarbonHeaderMenuItem(label: 'Docs', onPressed: () {}),
            ],
          ),
        ),
      );
      BoxDecoration decoration() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('Docs'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Docs')));
      await tester.pump();
      expect(decoration().color, theme.backgroundHover);

      await gesture.moveTo(const Offset(700, 400));
      await tester.pump();
      expect(decoration().color, const Color(0x00000000));
    });

    testWidgets('global action hover tint, focus ring and keyboard '
        'activation', (WidgetTester tester) async {
      int pressed = 0;
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            globalActions: <Widget>[
              CarbonHeaderGlobalAction(
                icon: CarbonIcons.search,
                label: 'Search',
                onPressed: () => pressed++,
              ),
            ],
          ),
        ),
      );
      final Finder action = find.byType(CarbonHeaderGlobalAction);
      Color background() => tester
          .widget<ColoredBox>(
            find.descendant(of: action, matching: find.byType(ColoredBox)),
          )
          .color;

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(action));
      await tester.pump();
      expect(background(), theme.backgroundHover);

      await gesture.moveTo(const Offset(700, 400));
      await tester.pump();
      expect(background(), const Color(0x00000000));

      Focus.of(tester.element(find.byType(CarbonIcon))).requestFocus();
      await tester.pumpAndSettle();
      final CarbonFocusRing ring = tester.widget<CarbonFocusRing>(
        find.descendant(of: action, matching: find.byType(CarbonFocusRing)),
      );
      expect(ring.visible, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(pressed, 2);
    });

    testWidgets('header dropdown menu opens its items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            navigation: <Widget>[
              CarbonHeaderMenu(
                label: 'Products',
                items: <Widget>[
                  CarbonMenuItem(label: 'Cloud', onPressed: () {}),
                  CarbonMenuItem(label: 'AI', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      );
      expect(find.text('Cloud'), findsNothing);
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.text('Cloud'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('header dropdown closes after selection and on an outside '
        'tap', (WidgetTester tester) async {
      int chosen = 0;
      await tester.pumpWidget(
        _host(
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            navigation: <Widget>[
              CarbonHeaderMenu(
                label: 'Products',
                items: <Widget>[
                  CarbonMenuItem(label: 'Cloud', onPressed: () => chosen++),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.text('Cloud'), findsOneWidget);

      // Selecting an item both fires it and dismisses the menu.
      await tester.tap(find.text('Cloud'));
      await tester.pumpAndSettle();
      expect(chosen, 1);
      expect(find.text('Cloud'), findsNothing);

      // Reopen; a tap outside the popover dismisses it.
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();
      expect(find.text('Cloud'), findsOneWidget);
      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(find.text('Cloud'), findsNothing);
    });
  });

  group('skip to content', () {
    testWidgets('hidden until focused; Enter and Space activate it', (
      WidgetTester tester,
    ) async {
      int skipped = 0;
      await tester.pumpWidget(
        _host(CarbonSkipToContent(onPressed: () => skipped++)),
      );
      final Finder label = find.text(
        'Skip to main content',
        skipOffstage: false,
      );
      expect(find.text('Skip to main content'), findsNothing);
      expect(label, findsOneWidget);

      Focus.of(tester.element(label)).requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Skip to main content'), findsOneWidget);
      expect(tester.widget<Text>(label).style!.color, theme.focus);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(skipped, 2);
    });
  });

  group('traversal (#226)', () {
    testWidgets('visits header name, nav, global actions, then side nav', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TapRegionSurface(
            child: CarbonTheme(
              data: CarbonThemeData.white,
              child: Overlay(
                initialEntries: <OverlayEntry>[
                  OverlayEntry(
                    builder: (BuildContext context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        CarbonHeader(
                          name: const CarbonHeaderName(
                            prefix: 'IBM',
                            name: 'Carbide',
                          ),
                          navigation: <Widget>[
                            CarbonHeaderMenuItem(
                              label: 'Catalog',
                              onPressed: () {},
                            ),
                          ],
                          globalActions: <Widget>[
                            CarbonHeaderGlobalAction(
                              icon: CarbonIcons.notification,
                              label: 'Notifications',
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              CarbonSideNav(
                                items: <Widget>[
                                  CarbonSideNavLink(
                                    label: 'Dashboard',
                                    current: true,
                                    onPressed: () {},
                                  ),
                                  CarbonSideNavLink(
                                    label: 'Documents',
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final List<String> labels = tester.semantics
          .simulatedAccessibilityTraversal()
          .map((SemanticsNode n) => n.label)
          .where((String l) => l.isNotEmpty)
          .toList();
      expect(
        labels,
        containsAllInOrder(<String>[
          'IBM Carbide',
          'Catalog',
          'Notifications',
          'Dashboard',
          'Documents',
        ]),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('header across themes (gray-100 is the dark shell)', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'ui_shell_header',
        containsText: true,
        size: const Size(640, 48),
        builder: (BuildContext context) => CarbonHeader(
          menuButton: CarbonHeaderMenuButton(
            label: 'Open menu',
            onPressed: () {},
          ),
          name: const CarbonHeaderName(prefix: 'IBM', name: 'Carbide'),
          navigation: <Widget>[
            CarbonHeaderMenuItem(
              label: 'Catalog',
              selected: true,
              onPressed: () {},
            ),
            CarbonHeaderMenuItem(label: 'Docs', onPressed: () {}),
          ],
          globalActions: <Widget>[
            CarbonHeaderGlobalAction(
              icon: CarbonIcons.search,
              label: 'Search',
              onPressed: () {},
            ),
            CarbonHeaderGlobalAction(
              icon: CarbonIcons.notification,
              label: 'Notifications',
              onPressed: () {},
            ),
          ],
        ),
      );
    });
  });
}
