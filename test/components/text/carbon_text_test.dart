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
    child: Center(child: child),
  ),
);

TextStyle _styleOf(WidgetTester tester) =>
    tester.widget<Text>(find.byType(Text)).style!;

void main() {
  testWidgets('defaults to body01 in the theme text color', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CarbonText('Carbide')));
    final TextStyle style = _styleOf(tester);
    expect(style.fontFamily, CarbonTypeStyles.body01.fontFamily);
    expect(style.fontSize, CarbonTypeStyles.body01.fontSize);
    expect(style.fontWeight, CarbonTypeStyles.body01.fontWeight);
    expect(style.height, CarbonTypeStyles.body01.height);
    expect(style.letterSpacing, CarbonTypeStyles.body01.letterSpacing);
    expect(style.color, CarbonThemeData.white.textPrimary);
  });

  testWidgets('text color follows the active theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const CarbonText('Carbide'), theme: CarbonThemeData.gray100),
    );
    expect(_styleOf(tester).color, CarbonThemeData.gray100.textPrimary);
  });

  testWidgets('applies a named Carbon style', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(const CarbonText('Title', style: CarbonTypeStyles.heading04)),
    );
    final TextStyle style = _styleOf(tester);
    expect(style.fontSize, CarbonTypeStyles.heading04.fontSize);
    expect(style.fontWeight, CarbonTypeStyles.heading04.fontWeight);
  });

  testWidgets('color precedence: explicit > style color > theme', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarbonText(
          'Hint',
          style: CarbonTypeStyles.helperText01.copyWith(
            color: CarbonColors.red60,
          ),
          color: CarbonColors.blue60,
        ),
      ),
    );
    expect(_styleOf(tester).color, CarbonColors.blue60);

    await tester.pumpWidget(
      _host(
        CarbonText(
          'Hint',
          style: CarbonTypeStyles.helperText01.copyWith(
            color: CarbonColors.red60,
          ),
        ),
      ),
    );
    expect(_styleOf(tester).color, CarbonColors.red60);
  });

  testWidgets('passes through layout and semantics options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonText(
          'A long label that truncates',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.center,
          semanticsLabel: 'short label',
        ),
      ),
    );
    final Text text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.softWrap, false);
    expect(text.textAlign, TextAlign.center);
    expect(text.semanticsLabel, 'short label');
    expect(find.bySemanticsLabel('short label'), findsOneWidget);
  });

  testWidgets('type specimen across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'carbon_text',
      containsText: true,
      size: const Size(220, 96),
      builder: (BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CarbonText('Heading', style: CarbonTypeStyles.heading03),
            CarbonText('Body copy in body01.'),
            CarbonText('code01 sample', style: CarbonTypeStyles.code01),
          ],
        ),
      ),
    );
  });
}
