// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

CarbonThemeData _custom(CarbonThemeData base) => base.copyWith(
  statusRed: CarbonColors.cyan60,
  statusOrange: CarbonColors.purple50,
  statusYellow: CarbonColors.blue50,
  statusPurple: CarbonColors.green50,
  statusGreen: CarbonColors.magenta50,
  statusBlue: CarbonColors.red50,
  statusGray: CarbonColors.teal50,
);

Color _iconColor(CarbonIconIndicatorKind kind, CarbonThemeData theme) =>
    switch (kind) {
      CarbonIconIndicatorKind.failed => theme.statusRed,
      CarbonIconIndicatorKind.cautionMajor => theme.statusOrange,
      CarbonIconIndicatorKind.cautionMinor => theme.statusYellow,
      CarbonIconIndicatorKind.undefined => theme.statusPurple,
      CarbonIconIndicatorKind.succeeded => theme.statusGreen,
      CarbonIconIndicatorKind.normal ||
      CarbonIconIndicatorKind.inProgress ||
      CarbonIconIndicatorKind.incomplete ||
      CarbonIconIndicatorKind.informative => theme.statusBlue,
      CarbonIconIndicatorKind.notStarted ||
      CarbonIconIndicatorKind.pending ||
      CarbonIconIndicatorKind.unknown => theme.statusGray,
    };

Color _shapeColor(CarbonShapeIndicatorKind kind, CarbonThemeData theme) =>
    switch (kind) {
      CarbonShapeIndicatorKind.failed ||
      CarbonShapeIndicatorKind.critical ||
      CarbonShapeIndicatorKind.high => theme.statusRed,
      CarbonShapeIndicatorKind.medium => theme.statusOrange,
      CarbonShapeIndicatorKind.low ||
      CarbonShapeIndicatorKind.cautious => theme.statusYellow,
      CarbonShapeIndicatorKind.undefined => theme.statusPurple,
      CarbonShapeIndicatorKind.stable => theme.statusGreen,
      CarbonShapeIndicatorKind.informative ||
      CarbonShapeIndicatorKind.incomplete => theme.statusBlue,
      CarbonShapeIndicatorKind.draft => theme.statusGray,
    };

Widget _host(CarbonThemeData theme, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: theme,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

void main() {
  // Variant-to-token assignments follow Carbon's icon/shape-indicator SCSS;
  // distinctly overridden tokens expose any fallback to the old palette map.
  for (final MapEntry<String, CarbonThemeData> entry
      in <String, CarbonThemeData>{
        'white': CarbonThemeData.white,
        'g10': CarbonThemeData.gray10,
        'g90': CarbonThemeData.gray90,
        'g100': CarbonThemeData.gray100,
      }.entries) {
    final CarbonThemeData theme = _custom(entry.value);
    testWidgets('all icon kinds use custom status tokens (${entry.key})', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        for (final CarbonIconIndicatorKind kind
            in CarbonIconIndicatorKind.values) {
          final String label = 'Icon ${kind.name}';
          await tester.pumpWidget(
            _host(theme, CarbonIconIndicator(kind: kind, label: label)),
          );
          expect(
            tester.widget<CarbonIcon>(find.byType(CarbonIcon)).color,
            _iconColor(kind, theme),
          );
          expect(find.bySemanticsLabel(label), findsOneWidget);
          expect(find.text(label), findsOneWidget);
        }
        await expectA11y(tester);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('all shape kinds use custom status tokens (${entry.key})', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        for (final CarbonShapeIndicatorKind kind
            in CarbonShapeIndicatorKind.values) {
          final String label = 'Shape ${kind.name}';
          await tester.pumpWidget(
            _host(theme, CarbonShapeIndicator(kind: kind, label: label)),
          );
          expect(
            tester.widget<CarbonIcon>(find.byType(CarbonIcon)).color,
            _shapeColor(kind, theme),
          );
          expect(find.bySemanticsLabel(label), findsOneWidget);
          expect(find.text(label), findsOneWidget);
        }
        await expectA11y(tester);
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets('custom status colors repaint when the theme changes', (
    WidgetTester tester,
  ) async {
    const CarbonIconIndicator indicator = CarbonIconIndicator(
      kind: CarbonIconIndicatorKind.normal,
      label: 'Current status',
    );
    await tester.pumpWidget(_host(CarbonThemeData.white, indicator));
    expect(
      tester.widget<CarbonIcon>(find.byType(CarbonIcon)).color,
      CarbonThemeData.white.statusBlue,
    );
    await tester.pumpWidget(_host(_custom(CarbonThemeData.white), indicator));
    expect(
      tester.widget<CarbonIcon>(find.byType(CarbonIcon)).color,
      CarbonColors.red50,
    );
  });

  testWidgets('custom status token golden', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'custom_status_tokens',
      builder: (BuildContext context) => CarbonTheme(
        data: _custom(CarbonTheme.of(context)),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CarbonIconIndicator(
              kind: CarbonIconIndicatorKind.failed,
              label: 'Custom failure',
            ),
            SizedBox(height: 8),
            CarbonIconIndicator(
              kind: CarbonIconIndicatorKind.normal,
              label: 'Custom normal',
            ),
            SizedBox(height: 8),
            CarbonShapeIndicator(
              kind: CarbonShapeIndicatorKind.stable,
              label: 'Custom stable',
            ),
          ],
        ),
      ),
      size: const Size(260, 100),
      containsText: true,
    );
  });
}
