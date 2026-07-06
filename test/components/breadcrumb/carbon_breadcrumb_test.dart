// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
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
