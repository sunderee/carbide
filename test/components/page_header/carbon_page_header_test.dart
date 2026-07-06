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
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 640, child: child),
    ),
  ),
);

BoxDecoration _bandDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(CarbonPageHeader),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
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

  group('band', () {
    testWidgets('is a layer-01 surface with a 1px border-subtle bottom rule', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonPageHeader(title: 'Reports')));
      final BoxDecoration deco = _bandDecoration(tester);
      expect(deco.color, theme.layer01);
      expect((deco.border! as Border).bottom.color, theme.borderSubtle01);
      expect((deco.border! as Border).bottom.width, 1);
    });

    testWidgets('exposes a page-header container', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonPageHeader(title: 'Reports')));
      expect(find.bySemanticsLabel('Page header'), findsOneWidget);
      handle.dispose();
    });
  });

  group('title', () {
    testWidgets('renders in productive-heading-04, two lines by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonPageHeader(title: 'Quarterly report')),
      );
      final Text title = tester.widget<Text>(find.text('Quarterly report'));
      expect(title.style!.fontSize, 28);
      expect(title.style!.color, theme.textPrimary);
      expect(title.maxLines, 2);
    });

    testWidgets('clamps to one line when page actions are present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPageHeader(
            title: 'Quarterly report',
            pageActions: CarbonButton(label: 'Edit', onPressed: () {}),
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('Quarterly report')).maxLines, 1);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('an icon precedes the title', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonPageHeader(title: 'Reports', icon: CarbonIcons.dashboard),
        ),
      );
      expect(find.byType(CarbonIcon), findsOneWidget);
    });
  });

  group('breadcrumb', () {
    testWidgets('the bar appears (40px) only when breadcrumbs are given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonPageHeader(title: 'Reports')));
      expect(find.byType(CarbonBreadcrumb), findsNothing);

      await tester.pumpWidget(
        _host(
          CarbonPageHeader(
            title: 'Reports',
            breadcrumbs: <CarbonBreadcrumbItem>[
              CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
              const CarbonBreadcrumbItem(label: 'Reports', isCurrentPage: true),
            ],
          ),
        ),
      );
      expect(find.byType(CarbonBreadcrumb), findsOneWidget);
      final ConstrainedBox bar = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.byType(CarbonBreadcrumb),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(bar.constraints.maxHeight, CarbonPageHeader.breadcrumbBarHeight);
    });

    testWidgets('breadcrumbBorder adds a 1px bottom rule to the bar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPageHeader(
            title: 'Reports',
            breadcrumbBorder: true,
            breadcrumbs: <CarbonBreadcrumbItem>[
              const CarbonBreadcrumbItem(label: 'Home', isCurrentPage: true),
            ],
          ),
        ),
      );
      // The band DecoratedBox + the bar's bordered DecoratedBox both exist.
      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(CarbonPageHeader),
          matching: find.byType(DecoratedBox),
        ),
      );
      final bool barRule = boxes.any((DecoratedBox b) {
        final BoxDecoration d = b.decoration as BoxDecoration;
        return d.color == null &&
            d.border is Border &&
            (d.border! as Border).bottom.color == theme.borderSubtle01;
      });
      expect(barRule, isTrue);
    });
  });

  group('description', () {
    testWidgets('subtitle and body render with their type styles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPageHeader(
            title: 'Reports',
            subtitle: 'Finance',
            body: 'A summary of revenue and spend for the quarter.',
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('Finance')).style!.fontSize, 20);
      expect(
        tester
            .widget<Text>(
              find.text('A summary of revenue and spend for the quarter.'),
            )
            .style!
            .fontSize,
        CarbonTypeStyles.body01.fontSize,
      );
    });

    testWidgets('tags and a tabs slot render', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonPageHeader(
            title: 'Reports',
            tags: const <Widget>[Text('v2'), Text('beta')],
            tabs: const Text('TABS'),
          ),
        ),
      );
      expect(find.text('v2'), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);
      expect(find.text('TABS'), findsOneWidget);
    });
  });

  group('goldens', () {
    testWidgets('page header across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'page_header',
        containsText: true,
        size: const Size(640, 220),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 640,
            child: CarbonPageHeader(
              title: 'Quarterly report',
              subtitle: 'Finance',
              body: 'A summary of revenue and spend for the quarter.',
              breadcrumbs: <CarbonBreadcrumbItem>[
                CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
                CarbonBreadcrumbItem(label: 'Finance', onPressed: () {}),
                const CarbonBreadcrumbItem(
                  label: 'Reports',
                  isCurrentPage: true,
                ),
              ],
              breadcrumbBorder: true,
              pageActions: CarbonButton(
                label: 'Edit',
                kind: CarbonButtonKind.tertiary,
                size: CarbonButtonSize.md,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // Composite band: gate the title + lg page action configuration.
      // Breadcrumb links are text-height by design and carry their own
      // sweep (with the 48dp exemption) in the breadcrumb suite, so they
      // stay out of this pump.
      await tester.pumpWidget(
        _host(
          CarbonPageHeader(
            title: 'Reports',
            pageActions: CarbonButton(label: 'Edit', onPressed: () {}),
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });
}
