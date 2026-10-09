// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0; see LICENSE.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';
import '../support/legibility.dart';
import '../support/specimens.dart';

Widget _chrome() => SizedBox(
  width: 620,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      for (final CarbonAILabelSize size in CarbonAILabelSize.values)
        CarbonAILabel(size: size),
      CarbonTableToolbar(
        onSearchChanged: (_) {},
        actions: <Widget>[
          CarbonButton(label: 'Add resource', onPressed: () {}),
        ],
      ),
    ],
  ),
);

void main() {
  for (final double scale in <double>[1.3, 2]) {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('AI sizes and toolbar preserve glyphs at $scale $direction', (
        tester,
      ) async {
        await tester.pumpWidget(
          carbideSpecimenHost(
            scale: scale,
            direction: direction,
            child: _chrome(),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expectNoClippedTextAtScale(tester, scale);
        final Rect toolbar = tester.getRect(find.byType(CarbonTableToolbar));
        final Rect button = tester.getRect(find.byType(CarbonButton));
        expect(toolbar.top, lessThanOrEqualTo(button.top));
        expect(toolbar.bottom, greaterThanOrEqualTo(button.bottom));
        await tester.tap(find.text('Add resource'));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('expanded chrome golden at $scale', (tester) async {
      await expectThemeGoldens(
        tester,
        name: 'expanded_chrome_$scale',
        containsText: true,
        size: const Size(660, 600),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
        builder: (_) => Align(alignment: Alignment.topLeft, child: _chrome()),
      );
    });
  }
}
