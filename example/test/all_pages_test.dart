// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hosts a single page with everything Carbide components need at runtime: a
/// theme, a media query, an overlay (for popovers/menus/modals) and a tap
/// region surface.
Widget _host(Widget page) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(1200, 900)),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: TapRegionSurface(
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) =>
                  Padding(padding: const EdgeInsets.all(24), child: page),
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  group('every catalog page builds and renders', () {
    for (final GalleryEntry entry in allEntries(kCatalog)) {
      testWidgets('${entry.slug} renders without error', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_host(entry.builder()));
        // Advance a few frames without settling — some pages host perpetual
        // animations (the loading spinner, indeterminate progress).
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.slug} threw while building',
        );
        expect(find.byType(Text), findsWidgets);
      });
    }
  });

  test('every entry has a unique slug', () {
    final List<String> slugs = <String>[
      for (final GalleryEntry e in allEntries(kCatalog)) e.slug,
    ];
    expect(slugs.toSet().length, slugs.length);
  });
}
