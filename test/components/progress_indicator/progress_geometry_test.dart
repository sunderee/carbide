// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0. See LICENSE.
import 'dart:ui' show ViewFocusEvent, ViewFocusState, ViewFocusDirection;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';

const steps = <CarbonProgressStep>[
  CarbonProgressStep(label: 'Account'),
  CarbonProgressStep(label: 'Details', secondaryLabel: 'Optional'),
  CarbonProgressStep(label: 'Problem', invalid: true),
  CarbonProgressStep(label: 'Review with a deliberately long name'),
  CarbonProgressStep(label: 'Locked', disabled: true),
];
Widget host(
  Widget child, {
  double width = 800,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  onGenerateRoute: (_) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: direction,
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  ),
);
void main() {
  testWidgets(
    'horizontal step grid is 128px with 88px labels beside 16px glyphs',
    (tester) async {
      await tester.pumpWidget(
        host(const CarbonProgressIndicator(steps: steps, currentIndex: 1)),
      );
      final a = tester.getRect(find.text('Account')),
          b = tester.getRect(find.text('Details'));
      expect(b.left - a.left, 128);
      expect(a.width, 88);
      final glyph = tester.getRect(find.byType(CarbonIcon).first);
      expect(glyph.size, const Size(16, 16));
      expect(a.left - glyph.left, 24);
      expect(a.top, glyph.top - 2);
      expect(
        tester
            .widget<Text>(find.text('Review with a deliberately long name'))
            .maxLines,
        1,
      );
      expect(
        tester
            .widget<Text>(find.text('Review with a deliberately long name'))
            .overflow,
        TextOverflow.ellipsis,
      );
      final lines = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => tester.getSize(find.byWidget(box)).height == 2)
          .toList();
      expect(lines, hasLength(5));
      for (final line in lines) {
        expect(tester.getSize(find.byWidget(line)).width, 128);
      }
      expect(lines[0].color, CarbonThemeData.white.interactive);
      expect(lines[1].color, CarbonThemeData.white.interactive);
    },
  );
  testWidgets(
    'vertical steps retain the 58px minimum, full line and wrapped 160px labels',
    (tester) async {
      await tester.pumpWidget(
        host(
          const CarbonProgressIndicator(
            steps: steps,
            currentIndex: 1,
            vertical: true,
          ),
        ),
      );
      expect(
        tester.getRect(find.text('Details')).top -
            tester.getRect(find.text('Account')).top,
        58,
      );
      expect(tester.getSize(find.text('Account')).width, 160);
      expect(
        tester
            .widget<Text>(find.text('Review with a deliberately long name'))
            .maxLines,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final vertical in [false, true])
    for (final direction in TextDirection.values)
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('narrow progress usable $vertical/$direction/$scale', (
          tester,
        ) async {
          final h = tester.ensureSemantics();
          try {
            var selected = -1;
            await tester.pumpWidget(
              host(
                CarbonProgressIndicator(
                  steps: steps,
                  currentIndex: 1,
                  vertical: vertical,
                  interactive: true,
                  onStepSelected: (i) => selected = i,
                ),
                width: 160,
                scale: scale,
                direction: direction,
              ),
            );
            await tester.pumpAndSettle();
            expectNoClippedTextAtScale(tester, scale);
            expect(tester.takeException(), isNull);
            tester.binding.handleViewFocusChanged(
              ViewFocusEvent(
                viewId: tester.view.viewId,
                state: ViewFocusState.focused,
                direction: ViewFocusDirection.undefined,
              ),
            );
            final f = find.text('Review with a deliberately long name');
            await tester.ensureVisible(f);
            await tester.pumpAndSettle();
            Focus.of(tester.element(f)).requestFocus();
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pump();
            expect(selected, 3);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pump();
            expect(selected, 3);
            final s = tester
                .getSemantics(find.bySemanticsLabel('Details'))
                .getSemanticsData();
            expect(s.hint, contains('Optional'));
            expect(s.flagsCollection.isSelected, isTrue);
          } finally {
            h.dispose();
          }
        });
      }
  for (final vertical in [false, true])
    for (final scale in [1.0, 2.0]) {
      testWidgets('golden progress geometry $vertical/$scale', (tester) async {
        await expectThemeGoldens(
          tester,
          name:
              'progress_geometry_${vertical ? 'vertical' : 'horizontal'}_${scale.toInt()}',
          size: Size(vertical ? 220 : 640, vertical ? 700 : 140),
          containsText: true,
          directions: TextDirection.values.toSet(),
          mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
          builder: (_) => Align(
            alignment: Alignment.topLeft,
            child: CarbonProgressIndicator(
              steps: steps,
              currentIndex: 1,
              vertical: vertical,
              interactive: true,
              onStepSelected: (_) {},
            ),
          ),
        );
      });
    }
}
