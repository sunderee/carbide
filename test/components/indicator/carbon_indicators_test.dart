// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child, {CarbonThemeData? theme}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: theme ?? CarbonThemeData.white,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

void main() {
  group('badge indicator', () {
    testWidgets('renders a dot when no count is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonBadgeIndicator()));
      final Container dot = tester.widget<Container>(
        find.descendant(
          of: find.byType(CarbonBadgeIndicator),
          matching: find.byType(Container),
        ),
      );
      final BoxDecoration decoration = dot.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(decoration.color, CarbonThemeData.white.supportError);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('shows a count and caps it at 999+', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonBadgeIndicator(count: 5)));
      expect(find.text('5'), findsOneWidget);

      await tester.pumpWidget(_host(const CarbonBadgeIndicator(count: 4000)));
      expect(find.text('999+'), findsOneWidget);
    });

    testWidgets('semantics: the dot reads New, counts read the capped text', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(CarbonBadgeIndicator()));
      expect(find.bySemanticsLabel('New'), findsOneWidget);

      await tester.pumpWidget(_host(CarbonBadgeIndicator(count: 1000)));
      expect(find.bySemanticsLabel('999+'), findsOneWidget);
      handle.dispose();
    });
  });

  group('icon indicator', () {
    testWidgets('renders the kind icon, colour, and label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.failed,
            label: 'Failed',
          ),
        ),
      );
      final CarbonIcon icon = tester.widget<CarbonIcon>(
        find.byType(CarbonIcon),
      );
      expect(icon.icon, CarbonIcons.errorFilled);
      expect(icon.color, CarbonColors.red60); // light theme: status-red = red60
      expect(icon.size, 16);
      expect(find.text('Failed'), findsOneWidget);
    });

    testWidgets('status colour steps down on dark themes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.succeeded,
            label: 'Succeeded',
          ),
          theme: CarbonThemeData.gray100,
        ),
      );
      final CarbonIcon icon = tester.widget<CarbonIcon>(
        find.byType(CarbonIcon),
      );
      // status-green is green50 on light, green40 on dark.
      expect(icon.color, CarbonColors.green40);
    });

    testWidgets('the 20px size uses body-compact-02', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.normal,
            label: 'Normal',
            size: 20,
          ),
        ),
      );
      expect(tester.widget<CarbonIcon>(find.byType(CarbonIcon)).size, 20);
      expect(
        tester.widget<Text>(find.text('Normal')).style!.fontSize,
        CarbonTypeStyles.bodyCompact02.fontSize,
      );
    });

    test('rejects icon sizes other than 16 or 20', () {
      expect(
        () => CarbonIconIndicator(
          kind: CarbonIconIndicatorKind.normal,
          label: 'Normal',
          size: 18,
        ),
        throwsAssertionError,
      );
    });
  });

  group('shape indicator', () {
    testWidgets('renders a distinct shape, colour, and label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.stable,
            label: 'Stable',
          ),
        ),
      );
      final CarbonIcon icon = tester.widget<CarbonIcon>(
        find.byType(CarbonIcon),
      );
      expect(icon.icon, CarbonIcons.circleFill);
      expect(icon.color, CarbonColors.green50);
      expect(find.text('Stable'), findsOneWidget);
    });

    testWidgets('failed and draft use different shapes', (
      WidgetTester tester,
    ) async {
      expect(
        CarbonShapeIndicatorKind.failed.shape,
        isNot(CarbonShapeIndicatorKind.draft.shape),
      );
    });

    testWidgets('the 14px text size uses body-compact-01; others rejected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.draft,
            label: 'Draft',
            textSize: 14,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Draft')).style!.fontSize,
        CarbonTypeStyles.bodyCompact01.fontSize,
      );
      expect(
        () => CarbonShapeIndicator(
          kind: CarbonShapeIndicatorKind.draft,
          label: 'Draft',
          textSize: 13,
        ),
        throwsAssertionError,
      );
    });
  });

  group('semantics (#226)', () {
    testWidgets('icon and shape indicators expose their status as a '
        'semantic label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // Status conveyed by shape + label is the whole point of these
      // indicators; the label must therefore reach assistive technology.
      await tester.pumpWidget(
        _host(
          const CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.failed,
            label: 'Failed',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Failed'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.stable,
            label: 'Stable',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Stable'), findsOneWidget);
      handle.dispose();
    });
  });

  group('goldens', () {
    Widget column(List<Widget> rows) => Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Widget r in rows)
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: r),
        ],
      ),
    );

    testWidgets('icon indicators', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'icon_indicator',
        containsText: true,
        size: const Size(220, 160),
        builder: (BuildContext context) => column(const <Widget>[
          CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.failed,
            label: 'Failed',
          ),
          CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.succeeded,
            label: 'Succeeded',
          ),
          CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.inProgress,
            label: 'In progress',
          ),
          CarbonIconIndicator(
            kind: CarbonIconIndicatorKind.pending,
            label: 'Pending',
          ),
        ]),
      );
    });

    testWidgets('shape indicators', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'shape_indicator',
        containsText: true,
        size: const Size(200, 160),
        builder: (BuildContext context) => column(const <Widget>[
          CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.critical,
            label: 'Critical',
          ),
          CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.medium,
            label: 'Medium',
          ),
          CarbonShapeIndicator(
            kind: CarbonShapeIndicatorKind.stable,
            label: 'Stable',
          ),
        ]),
      );
    });

    testWidgets('badge indicators', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'badge_indicator',
        containsText: true,
        size: const Size(120, 80),
        builder: (BuildContext context) => column(const <Widget>[
          CarbonBadgeIndicator(),
          CarbonBadgeIndicator(count: 8),
          CarbonBadgeIndicator(count: 4000),
        ]),
      );
    });
  });
}
