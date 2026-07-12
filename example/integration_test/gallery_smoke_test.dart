// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// End-to-end smoke of the deployed configuration (#233): boots the real
// gallery app and walks the primary user journey — shell renders, side-nav
// category expands, a component page loads. Driven on the web in CI
// (os-matrix.yaml) because the gallery ships as a web app; the same test
// runs on any device `flutter drive` supports.

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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
      find.text('Eight kinds across six sizes, with an optional icon.'),
      findsOneWidget,
    );
    expect(find.byType(CarbonButton), findsWidgets);
  });
}
