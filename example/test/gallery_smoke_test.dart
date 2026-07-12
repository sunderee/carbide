// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide_gallery/src/gallery_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots to the overview with the shell chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    // Header brand + landing content.
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Carbide'), findsWidgets);
    expect(find.text('Overview'), findsOneWidget);
    // A foundations category is present in the nav.
    expect(find.text('Foundations'), findsOneWidget);
  });
}
