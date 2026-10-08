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

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

Widget _appHost(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (BuildContext context, _, _) => builder(context),
      ),
  home: _host(child),
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

  List<CarbonBreadcrumbItem> crumbs(void Function(String) sink) =>
      <CarbonBreadcrumbItem>[
        CarbonBreadcrumbItem(label: 'Home', onPressed: () => sink('home')),
        CarbonBreadcrumbItem(label: 'Reports', onPressed: () => sink('rep')),
        const CarbonBreadcrumbItem(label: 'Q3', isCurrentPage: true),
      ];

  group('structure', () {
    testWidgets('links + separators; current page is plain text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(CarbonBreadcrumb(items: crumbs((_) {}))));
      expect(find.byType(CarbonLink), findsNWidgets(2));
      // Two separators between three crumbs (no trailing slash by default).
      expect(find.text('/'), findsNWidgets(2));
      // The current page is a Text, not a link, in text-primary.
      expect(find.widgetWithText(CarbonLink, 'Q3'), findsNothing);
      expect(
        tester.widget<Text>(find.text('Q3')).style!.color,
        theme.textPrimary,
      );
    });

    testWidgets('noTrailingSlash:false adds a trailing separator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonBreadcrumb(items: crumbs((_) {}), noTrailingSlash: false)),
      );
      expect(find.text('/'), findsNWidgets(3));
    });

    testWidgets('tapping a crumb navigates', (WidgetTester tester) async {
      String? went;
      await tester.pumpWidget(
        _host(CarbonBreadcrumb(items: crumbs((String s) => went = s))),
      );
      await tester.tap(find.text('Reports'));
      expect(went, 'rep');
    });
  });

  group('semantics', () {
    testWidgets('exposes a Breadcrumb container with link children', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CarbonBreadcrumb(items: crumbs((_) {}))));
      expect(find.bySemanticsLabel('Breadcrumb'), findsOneWidget);
      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      handle.dispose();
    });
  });

  group('keyboard (#231)', () {
    // Upstream spec: documentation/carbon-website/src/pages/components/
    // breadcrumb/accessibility.mdx — each page link in the breadcrumb is
    // reached by Tab and activated by Enter; when the breadcrumb is
    // truncated, the ellipsis button for the overflow menu is in the tab
    // order and follows the overflow menu's keyboard spec
    // (documentation/carbon-website/src/pages/components/overflow-menu/
    // accessibility.mdx).

    Widget tabHost(Widget child) => _host(
      FocusTraversalGroup(
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{NextFocusIntent: NextFocusAction()},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // A focus anchor before the component, so the first Tab
                // press moves focus onto the first crumb link.
                const Focus(autofocus: true, child: SizedBox.shrink()),
                child,
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('Tab reaches each link in order; Enter activates it', (
      WidgetTester tester,
    ) async {
      String? went;
      await tester.pumpWidget(
        tabHost(CarbonBreadcrumb(items: crumbs((String s) => went = s))),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(find.text('Home'))).hasPrimaryFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(find.text('Reports'))).hasPrimaryFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(went, 'rep');
    });

    testWidgets(
      'ellipsis overflow trigger: Enter/Space open the menu, Escape closes '
      'it and restores focus to the trigger',
      (WidgetTester tester) async {
        // Spec shape: a truncated breadcrumb collapses the middle crumbs
        // behind an ellipsis CarbonOverflowMenu trigger in the tab order.
        await tester.pumpWidget(
          _appHost(
            SizedBox(
              width: 240,
              child: CarbonBreadcrumb(
                items: <CarbonBreadcrumbItem>[
                  for (int i = 0; i < 6; i++)
                    CarbonBreadcrumbItem(label: 'Level $i', onPressed: () {}),
                  const CarbonBreadcrumbItem(
                    label: 'Here',
                    isCurrentPage: true,
                  ),
                ],
              ),
            ),
          ),
        );
        final Finder ellipsisTrigger = find.descendant(
          of: find.byType(CarbonBreadcrumb),
          matching: find.byType(CarbonOverflowMenu),
        );
        expect(ellipsisTrigger, findsOneWidget);
        final FocusNode trigger = Focus.of(
          tester.element(
            find
                .descendant(
                  of: ellipsisTrigger,
                  matching: find.byType(CarbonIcon),
                )
                .first,
          ),
        );
        trigger.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(CarbonMenu), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(CarbonMenu), findsNothing);
        expect(trigger.hasPrimaryFocus, isTrue);
      },
    );
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CarbonBreadcrumb(items: crumbs((_) {}))));
      // Crumbs are text-height CarbonLinks; nodes flagged `isLink` are
      // exempt from the 48dp rule (WCAG 2.1 target-size link exception,
      // applied by androidTapTargetGuideline itself), so both axes stay on.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('breadcrumb across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'breadcrumb',
        containsText: true,
        size: const Size(360, 60),
        builder: (BuildContext context) => Center(
          child: CarbonBreadcrumb(
            items: <CarbonBreadcrumbItem>[
              CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
              CarbonBreadcrumbItem(label: 'Reports', onPressed: () {}),
              const CarbonBreadcrumbItem(label: 'Q3', isCurrentPage: true),
            ],
          ),
        ),
      );
    });
  });
}
