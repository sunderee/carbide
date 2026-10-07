// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Text _rendered(WidgetTester tester, Finder parent) => tester.widget<Text>(
  find.descendant(of: parent, matching: find.byType(Text)).first,
);

void main() {
  testWidgets('fluid page uses live viewport, column and preview consumers', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(1312, 1200)),
          child: CarbonTheme(
            data: CarbonThemeData.gray100,
            child: entryForSlug(kCatalog, 'fluid-type')!.builder(),
          ),
        ),
      ),
    );
    await tester.pump();
    final Finder live = find.byWidgetPredicate(
      (Widget widget) =>
          widget is CarbonFluidText && widget.data == 'A responsive title',
    );
    final Finder column = find.byWidgetPredicate(
      (Widget widget) =>
          widget is CarbonFluidText &&
          widget.data == 'A quotation sized for this column.',
    );
    expect(_rendered(tester, live).style!.fontSize, 48);
    expect(_rendered(tester, column).style!.fontSize, 20);
    expect(
      _rendered(tester, column).style!.fontFamily,
      'packages/carbide/IBM Plex Serif',
    );
    final Finder preview = find.byWidgetPredicate(
      (Widget widget) =>
          widget is CarbonFluidText &&
          widget.data == 'Carbide is carbon, fluid.',
    );
    expect(preview, findsNWidgets(4));
    for (final double width in <double>[320, 672, 1056, 1312, 1584]) {
      tester.widget<CarbonSlider>(find.byType(CarbonSlider)).onChanged!(width);
      await tester.pumpAndSettle();
      for (final Element element in preview.evaluate()) {
        final CarbonFluidText widget = element.widget as CarbonFluidText;
        final Text text = _rendered(tester, find.byWidget(widget));
        expect(text.style!.fontSize, widget.style.resolve(width).fontSize);
        expect(text.style!.color, CarbonThemeData.gray100.textPrimary);
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
      expect(_rendered(tester, live).style!.fontSize, 48);
      expect(_rendered(tester, column).style!.fontSize, 20);
      expect(tester.takeException(), isNull);
    }
  });
}
