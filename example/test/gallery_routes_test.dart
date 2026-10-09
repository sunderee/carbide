// Copyright 2026 Bizjak Tech OÜ

import 'package:carbide_gallery/src/gallery_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/support/gallery_routes.dart';

void main() {
  testWidgets('every registered route renders its page and preview', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();
    await verifyGalleryRoutes(tester);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
