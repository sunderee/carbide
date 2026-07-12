// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// Captures full-window screenshots of the gallery for visual review. Generate
// with `flutter test --update-goldens test/screenshots_test.dart`; the PNGs
// land in test/screenshots/. They are not asserted in CI (glyph rasterization
// differs across platforms) — they exist for humans to look at.

import 'package:carbide_gallery/src/gallery_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Screenshots are a local-only tool. They render macOS-specific glyphs, so
/// they must not run (and be compared) in CI. Generate with:
///   flutter test --dart-define=SCREENSHOTS=true --update-goldens \
///     test/screenshots_test.dart
const bool _enabled = bool.fromEnvironment('SCREENSHOTS');

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  testWidgets('overview, white theme', skip: !_enabled, (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(GalleryApp),
      matchesGoldenFile('screenshots/overview.png'),
    );
  });

  testWidgets('button page, dark theme', skip: !_enabled, (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    // Switch to a dark theme (cycle White -> Gray 10 -> Gray 90).
    await tester.tap(find.bySemanticsLabel('Switch theme (White)'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Switch theme (Gray 10)'));
    await tester.pumpAndSettle();

    // Open the Button page.
    await tester.tap(find.text('Foundational'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GalleryApp),
      matchesGoldenFile('screenshots/button_dark.png'),
    );
  });

  testWidgets('data table page, white theme', skip: !_enabled, (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    // Open the Data table page (Complex & data category).
    await tester.tap(find.text('Complex & data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Data table'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(GalleryApp),
      matchesGoldenFile('screenshots/data_table.png'),
    );
  });
}
