// Copyright 2026 Bizjak Tech OÜ

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/demo_scaffold.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Visits real router paths and verifies their expected page and live preview.
Future<void> verifyGalleryRoutes(WidgetTester tester) async {
  final GoRouter router = GoRouter.of(
    tester.element(find.byType(CarbonSideNav)),
  );
  for (final GalleryEntry entry in allEntries(kCatalog)) {
    debugPrintSynchronously('Gallery route ${entry.path}');
    router.go(entry.path);
    // Loading and motion examples animate forever. Advance bounded frames
    // instead of waiting for all animations to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull, reason: '${entry.path} threw');
    expect(router.routeInformationProvider.value.uri.path, entry.path);
    expect(find.text('Page not found'), findsNothing, reason: entry.path);
    expect(
      find.byType(entry.builder().runtimeType),
      findsOneWidget,
      reason: '${entry.path} must render its registered page',
    );
    expect(find.byKey(kDemoPreviewKey), findsOneWidget, reason: entry.path);
    expect(
      tester.getSize(find.byKey(kDemoPreviewKey)).shortestSide,
      greaterThan(0),
      reason: '${entry.path} must have a visible preview surface',
    );
  }
  router.go('/');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('Overview'), findsOneWidget);
}
