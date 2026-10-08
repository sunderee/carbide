// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/load_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('font family names match the Carbon families', () {
    expect(CarbonFontFamily.sans, 'IBM Plex Sans');
    expect(CarbonFontFamily.mono, 'IBM Plex Mono');
    expect(CarbonFontFamily.serif, 'IBM Plex Serif');
    expect(CarbonFontFamily.package, 'carbide');
  });

  test('bundled Plex fonts load from the asset bundle', () async {
    // Throws if any declared asset is missing from the bundle, which keeps the
    // pubspec font declaration honest.
    await loadCarbidePlexFonts();
  });

  testWidgets('text renders in the bundled Plex families', (
    WidgetTester tester,
  ) async {
    await loadCarbidePlexFonts();

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: <Widget>[
            Text(
              'Carbide',
              style: TextStyle(
                fontFamily: CarbonFontFamily.sans,
                package: CarbonFontFamily.package,
              ),
            ),
            Text(
              'const x = 1;',
              style: TextStyle(
                fontFamily: CarbonFontFamily.mono,
                package: CarbonFontFamily.package,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Carbide'), findsOneWidget);
    expect(find.text('const x = 1;'), findsOneWidget);

    final Text sans = tester.widget<Text>(find.text('Carbide'));
    expect(sans.style?.fontFamily, 'packages/carbide/${CarbonFontFamily.sans}');

    // The paragraph lays out with real glyph metrics, so it has a non-zero size.
    final Size size = tester.getSize(find.text('Carbide'));
    expect(size.width, greaterThan(0));
    expect(size.height, greaterThan(0));
  });
}
