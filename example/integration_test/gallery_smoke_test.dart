// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// End-to-end smoke of the deployed configuration (#233): boots the real
// gallery app, navigates through the side nav and visits every catalog route.
// Driven on the web by shared PR/release verification and the OS canary because
// the gallery ships as a web app; the same test
// runs on any device `flutter drive` supports.

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/gallery_routes.dart';
import 'support/failure_diagnostics.dart';

void main() {
  retainIntegrationFailureDetails(
    IntegrationTestWidgetsFlutterBinding.ensureInitialized(),
  );

  testWidgets('gallery boots and navigates to the Button page', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    // The shell is up: header name + side nav.
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.byType(CarbonSideNav), findsOneWidget);

    // Expand the Foundational category and open the Button page.
    await tester.tap(find.text('Foundational'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Button').first);
    await tester.pumpAndSettle();

    // The Button demo page rendered its description and a live button.
    expect(
      find.text('Button kinds and sizes, with an optional icon.'),
      findsOneWidget,
    );
    expect(find.byType(CarbonButton), findsWidgets);
  });

  testWidgets('every real gallery route renders in the browser', (
    WidgetTester tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();
    await verifyGalleryRoutes(tester);
  });
}
