// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show BoxHeightStyle;

import 'package:carbide/carbide.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(
  Widget child, {
  double width = 1600,
  double scale = 1,
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(
      size: Size(width, 600),
      textScaler: TextScaler.linear(scale),
    ),
    child: CarbonTheme(
      data: theme ?? CarbonThemeData.white,
      child: Align(alignment: AlignmentDirectional.topStart, child: child),
    ),
  ),
);

Text _text(WidgetTester tester) => tester.widget<Text>(find.byType(Text));

const List<(double, double)> _steps = <(double, double)>[
  (0, 32),
  (319, 32),
  (320, 32),
  (671, 32),
  (672, 36),
  (1055, 36),
  (1056, 42),
  (1311, 42),
  (1312, 48),
  (1583, 48),
  (1584, 60),
  (2000, 60),
];

void main() {
  testWidgets(
    'viewport cascade rebuilds at every boundary in both directions',
    (WidgetTester tester) async {
      const Widget child = SizedBox(
        width: 200,
        child: CarbonFluidText(
          'Fluid',
          style: CarbonFluidTypeStyles.expressiveHeading05,
        ),
      );
      for (final (double width, double expected) in <(double, double)>[
        ..._steps,
        ..._steps.reversed,
      ]) {
        await tester.pumpWidget(_host(child, width: width));
        expect(
          _text(tester).style!.fontSize,
          expected,
          reason: '$width viewport',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('view resize updates a constant descendant automatically', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(670, 600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery.fromView(
          view: tester.view,
          child: CarbonTheme(
            data: CarbonThemeData.white,
            child: const CarbonFluidText(
              'Fluid',
              style: CarbonFluidTypeStyles.expressiveHeading05,
            ),
          ),
        ),
      ),
    );
    expect(_text(tester).style!.fontSize, 32);
    tester.view.physicalSize = const Size(1056, 600);
    await tester.pump();
    expect(_text(tester).style!.fontSize, 42);
    tester.view.physicalSize = const Size(672, 600);
    await tester.pump();
    expect(_text(tester).style!.fontSize, 36);
  });

  testWidgets('constraint cascade reacts to parent width without a viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(2200, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ValueNotifier<double> width = ValueNotifier<double>(2000);
    addTearDown(width.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder<double>(
              valueListenable: width,
              child: const CarbonFluidText(
                'Fluid',
                style: CarbonFluidTypeStyles.expressiveHeading05,
                widthSource: CarbonFluidTextWidthSource.constraints,
              ),
              builder: (BuildContext context, double value, Widget? child) =>
                  SizedBox(width: value, child: child),
            ),
          ),
        ),
      ),
    );
    for (final (double value, double expected) in <(double, double)>[
      ..._steps,
      ..._steps.reversed,
    ]) {
      width.value = value;
      await tester.pump();
      expect(_text(tester).style!.fontSize, expected, reason: '$value parent');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('bounded constraints take precedence over a wider viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 700,
          child: CarbonFluidText(
            'Fluid',
            style: CarbonFluidTypeStyles.expressiveHeading05,
            widthSource: CarbonFluidTextWidthSource.constraints,
          ),
        ),
      ),
    );
    expect(_text(tester).style!.fontSize, 36);
  });

  testWidgets('unbounded constraints fall back to the viewport cascade', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CarbonFluidText(
            'Fluid',
            style: CarbonFluidTypeStyles.expressiveHeading05,
            widthSource: CarbonFluidTextWidthSource.constraints,
          ),
        ),
        width: 1056,
      ),
    );
    expect(_text(tester).style!.fontSize, 42);
  });

  for (final double scale in <double>[1, 1.3, 2]) {
    testWidgets('fluid base and user scaling compose at ${scale}x', (
      WidgetTester tester,
    ) async {
      for (final (double width, double fontSize) in <(double, double)>[
        (672, 36),
        (1056, 42),
        (1584, 60),
      ]) {
        await tester.pumpWidget(
          _host(
            const CarbonFluidText(
              'Fluid',
              style: CarbonFluidTypeStyles.expressiveHeading05,
            ),
            width: width,
          ),
        );
        final RenderParagraph baseline = tester.renderObject<RenderParagraph>(
          find.byType(RichText),
        );
        final TextBox baselineBox = baseline
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 5),
              boxHeightStyle: BoxHeightStyle.includeLineSpacingMiddle,
            )
            .single;
        final double baselineHeight = baseline.size.height;
        await tester.pumpWidget(
          _host(
            const CarbonFluidText(
              'Fluid',
              style: CarbonFluidTypeStyles.expressiveHeading05,
            ),
            width: width,
            scale: scale,
          ),
        );
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
          find.byType(RichText),
        );
        expect(_text(tester).style!.fontSize, fontSize);
        expect(paragraph.textScaler.scale(fontSize), fontSize * scale);
        final TextBox box = paragraph
            .getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 5),
              boxHeightStyle: BoxHeightStyle.includeLineSpacingMiddle,
            )
            .single;
        expect(
          box.bottom - box.top,
          closeTo((baselineBox.bottom - baselineBox.top) * scale, 0.1),
        );
        expect(paragraph.size.height, closeTo(baselineHeight * scale, 1));
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'preserves semantics, truncation, alignment and explicit direction',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            const SizedBox(
              width: 180,
              child: CarbonFluidText(
                'A long quotation that cannot fit on a single line',
                style: CarbonFluidTypeStyles.quotation01,
                semanticsLabel: 'Accessible quotation',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.end,
                textDirection: TextDirection.ltr,
              ),
            ),
            direction: TextDirection.rtl,
          ),
        );
        final Text text = _text(tester);
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(text.softWrap, false);
        expect(text.textAlign, TextAlign.end);
        expect(text.textDirection, TextDirection.ltr);
        expect(find.bySemanticsLabel('Accessible quotation'), findsOneWidget);
        final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
          find.byType(RichText),
        );
        expect(paragraph.didExceedMaxLines, isTrue);
        expect(paragraph.text.toPlainText(), contains('quotation'));
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets('defaults to expressive paragraph and inherits ambient RTL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonFluidText('Fluid'),
        width: 1056,
        direction: TextDirection.rtl,
      ),
    );
    expect(_text(tester).style!.fontSize, 28);
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(paragraph.textDirection, TextDirection.rtl);
  });

  testWidgets('color precedence and theme changes match CarbonText', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CarbonFluidText('Fluid')));
    expect(_text(tester).style!.color, CarbonThemeData.white.textPrimary);
    await tester.pumpWidget(
      _host(const CarbonFluidText('Fluid'), theme: CarbonThemeData.gray100),
    );
    expect(_text(tester).style!.color, CarbonThemeData.gray100.textPrimary);
    final CarbonFluidTextStyle colored = CarbonFluidTypeStyles.quotation01
        .copyWith(
          base: CarbonFluidTypeStyles.quotation01.base.copyWith(
            color: CarbonColors.red60,
          ),
        );
    await tester.pumpWidget(_host(CarbonFluidText('Fluid', style: colored)));
    expect(_text(tester).style!.color, CarbonColors.red60);
    await tester.pumpWidget(
      _host(
        CarbonFluidText('Fluid', style: colored, color: CarbonColors.blue60),
      ),
    );
    expect(_text(tester).style!.color, CarbonColors.blue60);
  });

  testWidgets('serif quotation uses bundled Plex Serif at viewport lg', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonFluidText(
          'A quotation',
          style: CarbonFluidTypeStyles.quotation01,
        ),
        width: 1056,
      ),
    );
    expect(
      _text(tester).style!.fontFamily,
      'packages/carbide/${CarbonFontFamily.serif}',
    );
    expect(_text(tester).style!.fontSize, 24);
  });

  testWidgets('bundled families qualify while custom families remain intact', (
    WidgetTester tester,
  ) async {
    for (final String family in <String>[
      CarbonFontFamily.sans,
      CarbonFontFamily.mono,
      CarbonFontFamily.serif,
      'Application Font',
      'packages/another_package/Custom Font',
    ]) {
      await tester.pumpWidget(
        _host(
          CarbonFluidText(
            'Fluid',
            style: CarbonFluidTextStyle(
              base: TextStyle(
                fontFamily: family,
                fontFamilyFallback: const <String>['Application Fallback'],
              ),
            ),
          ),
        ),
      );
      expect(
        _text(tester).style!.fontFamily,
        family.startsWith('IBM Plex') ? 'packages/carbide/$family' : family,
      );
      expect(_text(tester).style!.fontFamilyFallback, <String>[
        'Application Fallback',
      ]);
    }
  });

  testWidgets('style replacement and inherited cascade properties rebuild', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonFluidText(
          'Fluid',
          style: CarbonFluidTypeStyles.expressiveHeading05,
        ),
        width: 1056,
      ),
    );
    expect(_text(tester).style!.fontWeight, FontWeight.w300);
    expect(_text(tester).style!.height, 1.19);
    await tester.pumpWidget(
      _host(
        const CarbonFluidText(
          'Fluid',
          style: CarbonFluidTypeStyles.quotation01,
        ),
        width: 1056,
      ),
    );
    expect(_text(tester).style!.fontSize, 24);
    expect(_text(tester).style!.fontWeight, FontWeight.w400);
    expect(_text(tester).style!.height, 1.334);
    expect(_text(tester).style!.fontFamily, 'packages/carbide/IBM Plex Serif');
  });

  testWidgets('serif quotation golden across themes', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'carbon_fluid_quotation',
      containsText: true,
      size: const Size(520, 130),
      mediaQuery: const MediaQueryData(size: Size(1056, 600)),
      builder: (BuildContext context) => const Padding(
        padding: EdgeInsets.all(16),
        child: CarbonFluidText(
          '“Design is how it works.”',
          style: CarbonFluidTypeStyles.quotation01,
          maxLines: 2,
        ),
      ),
    );
  });
}
