// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

void main() {
  group('level semantics (Heading/index.tsx)', () {
    testWidgets('root headings are level 1; sections increment; clamps at 6', (
      WidgetTester tester,
    ) async {
      final List<int> seen = <int>[];
      Widget probe(Widget child) => Builder(
        builder: (BuildContext context) {
          seen.add(CarbonSection.levelOf(context));
          return child;
        },
      );

      Widget nest(int depth, Widget innermost) => depth == 0
          ? innermost
          : CarbonSection(child: probe(nest(depth - 1, innermost)));

      await tester.pumpWidget(_host(probe(nest(7, const SizedBox()))));
      // Root probe + seven nested sections: 1, then 2..6 clamped.
      expect(seen.first, 1);
      expect(seen.sublist(1), <int>[2, 3, 4, 5, 6, 6, 6]);
    });

    testWidgets('an explicit section level overrides the hierarchy', (
      WidgetTester tester,
    ) async {
      late int level;
      await tester.pumpWidget(
        _host(
          CarbonSection(
            child: CarbonSection(
              level: 2,
              child: Builder(
                builder: (BuildContext context) {
                  level = CarbonSection.levelOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      expect(level, 2);
    });
  });

  group('visual mapping (Carbide default; upstream ships unstyled)', () {
    test('h1→heading-06 down to h6→heading-01', () {
      expect(CarbonHeading.styleForLevel(1), CarbonTypeStyles.heading06);
      expect(CarbonHeading.styleForLevel(2), CarbonTypeStyles.heading05);
      expect(CarbonHeading.styleForLevel(3), CarbonTypeStyles.heading04);
      expect(CarbonHeading.styleForLevel(4), CarbonTypeStyles.heading03);
      expect(CarbonHeading.styleForLevel(5), CarbonTypeStyles.heading02);
      expect(CarbonHeading.styleForLevel(6), CarbonTypeStyles.heading01);
    });

    testWidgets('a heading renders the ambient level style in textPrimary; '
        'style override keeps the semantic level', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonSection(child: CarbonHeading('Title'))),
      );
      TextStyle styleOf() => tester.widget<Text>(find.text('Title')).style!;
      expect(styleOf().fontSize, CarbonTypeStyles.heading05.fontSize);
      expect(styleOf().color, CarbonThemeData.white.textPrimary);

      await tester.pumpWidget(
        _host(
          const CarbonSection(
            child: CarbonHeading('Title', style: CarbonTypeStyles.heading01),
          ),
        ),
      );
      expect(styleOf().fontSize, CarbonTypeStyles.heading01.fontSize);
    });
  });

  group('accessibility', () {
    testWidgets('headings expose the header flag and level', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonSection(
            child: CarbonSection(child: CarbonHeading('Sub')),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sub')),
        isSemantics(label: 'Sub', isHeader: true),
      );
      handle.dispose();
    });
  });

  testWidgets('heading hierarchy across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'heading',
      containsText: true,
      size: const Size(320, 220),
      builder: (BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const CarbonHeading('Heading one'),
            CarbonSection(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CarbonHeading('Heading two'),
                  CarbonSection(child: const CarbonHeading('Heading three')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}
