// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(builder: (BuildContext context) => Center(child: child)),
        ],
      ),
    ),
  ),
);

CarbonButton _arrow(WidgetTester tester, String label) =>
    tester.widget<CarbonButton>(
      find.byWidgetPredicate(
        (Widget w) => w is CarbonButton && w.label == label,
      ),
    );

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('layout / spec-lock', () {
    testWidgets('renders every page when they fit, no overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonPaginationNav(totalItems: 5, page: 0, onChange: (_) {})),
      );
      for (final String n in <String>['1', '2', '3', '4', '5']) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.byType(CarbonOverflowMenu), findsNothing);
    });

    testWidgets('page buttons take the size height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 3,
            page: 0,
            size: CarbonPaginationNavSize.md,
            onChange: (_) {},
          ),
        ),
      );
      final Size box = tester.getSize(
        find
            .ancestor(of: find.text('2'), matching: find.byType(Container))
            .first,
      );
      expect(box.height, 40);
      expect(box.width, greaterThanOrEqualTo(40));
    });

    testWidgets('the active page is bold', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(CarbonPaginationNav(totalItems: 5, page: 2, onChange: (_) {})),
      );
      expect(
        tester.widget<Text>(find.text('3')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(
        tester.widget<Text>(find.text('1')).style!.fontWeight,
        FontWeight.w400,
      );
    });
  });

  group('navigation', () {
    testWidgets('tapping a page reports its index', (
      WidgetTester tester,
    ) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 5,
            page: 0,
            onChange: (int p) => changed = p,
          ),
        ),
      );
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();
      expect(changed, 3);
    });

    testWidgets('arrows are bounded without loop', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(CarbonPaginationNav(totalItems: 5, page: 0, onChange: (_) {})),
      );
      expect(_arrow(tester, 'Previous page').onPressed, isNull);
      expect(_arrow(tester, 'Next page').onPressed, isNotNull);
    });

    testWidgets('next advances the page', (WidgetTester tester) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 5,
            page: 1,
            onChange: (int p) => changed = p,
          ),
        ),
      );
      _arrow(tester, 'Next page').onPressed!();
      expect(changed, 2);
    });

    testWidgets('loop wraps the previous arrow at the first page', (
      WidgetTester tester,
    ) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 5,
            page: 0,
            loop: true,
            onChange: (int p) => changed = p,
          ),
        ),
      );
      final CarbonButton prev = _arrow(tester, 'Previous page');
      expect(prev.onPressed, isNotNull);
      prev.onPressed!();
      expect(changed, 4);
    });

    testWidgets('hovering a page button fills backgroundHover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonPaginationNav(totalItems: 5, page: 0, onChange: (_) {})),
      );
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('2')));
      await tester.pumpAndSettle();
      final Container box = tester.widget<Container>(
        find
            .ancestor(of: find.text('2'), matching: find.byType(Container))
            .first,
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        CarbonThemeData.white.backgroundHover,
      );
    });
  });

  group('truncation', () {
    testWidgets('collapses the middle into overflow menus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 20,
            page: 10,
            itemsShown: 7,
            onChange: (_) {},
          ),
        ),
      );
      // First and last pages are always shown.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
      // At least one overflow menu is rendered.
      expect(find.byType(CarbonOverflowMenu), findsWidgets);
    });

    testWidgets('start-anchored window collapses only the back', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 20,
            page: 0,
            itemsShown: 7,
            onChange: (_) {},
          ),
        ),
      );
      // The front cut is negative and folds into the back cut: 1..5 stay.
      for (final String n in <String>['1', '2', '3', '4', '5', '20']) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.byType(CarbonOverflowMenu), findsOneWidget);
    });

    testWidgets('end-anchored window collapses only the front', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 20,
            page: 19,
            itemsShown: 7,
            onChange: (_) {},
          ),
        ),
      );
      // The back cut is negative and folds into the front cut: 16..20 stay.
      for (final String n in <String>['1', '16', '17', '18', '19', '20']) {
        expect(find.text(n), findsOneWidget);
      }
      expect(find.byType(CarbonOverflowMenu), findsOneWidget);
    });

    testWidgets('disableOverflow renders static ellipses instead of menus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 20,
            page: 10,
            itemsShown: 7,
            disableOverflow: true,
            onChange: (_) {},
          ),
        ),
      );
      expect(find.text('…'), findsNWidgets(2));
      expect(find.byType(CarbonOverflowMenu), findsNothing);
    });

    testWidgets('an overflow menu item navigates to its page', (
      WidgetTester tester,
    ) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          CarbonPaginationNav(
            totalItems: 20,
            page: 10,
            itemsShown: 7,
            onChange: (int p) => changed = p,
          ),
        ),
      );
      await tester.tap(find.byType(CarbonOverflowMenu).first);
      await tester.pumpAndSettle();
      // The front menu lists the hidden pages 2..9.
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      expect(changed, 1);
    });
  });

  group('semantics', () {
    testWidgets('exposes the current page', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonPaginationNav(totalItems: 5, page: 2, onChange: (_) {})),
      );
      expect(find.bySemanticsLabel('Page 3 of 5'), findsOneWidget);
      handle.dispose();
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // Default size is lg (48px, `_pagination-nav.scss` layout default
      // 'lg' and $button-direction-size: $spacing-09), so the 48dp gate
      // stays fully on. A middle page keeps both arrows enabled.
      await tester.pumpWidget(
        _host(CarbonPaginationNav(totalItems: 5, page: 2, onChange: (_) {})),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    Widget overlaid(Widget child) => Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(builder: (BuildContext context) => Center(child: child)),
      ],
    );

    testWidgets('full range', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'pagination_nav_full',
        containsText: true,
        size: const Size(420, 80),
        builder: (BuildContext context) => overlaid(
          CarbonPaginationNav(totalItems: 5, page: 2, onChange: (_) {}),
        ),
      );
    });

    testWidgets('truncated', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'pagination_nav_truncated',
        containsText: true,
        size: const Size(480, 80),
        builder: (BuildContext context) => overlaid(
          CarbonPaginationNav(
            totalItems: 20,
            page: 10,
            itemsShown: 7,
            onChange: (_) {},
          ),
        ),
      );
    });
  });
}
