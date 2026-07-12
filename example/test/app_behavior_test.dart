// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide_gallery/src/gallery_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cycling the header theme action changes the active theme', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    // The overview reports the active theme; it starts White.
    expect(find.text('White'), findsOneWidget);
    expect(find.bySemanticsLabel('Switch theme (White)'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Switch theme (White)'));
    await tester.pumpAndSettle();

    expect(find.text('Gray 10'), findsWidgets);
    handle.dispose();
  });

  testWidgets('navigating the side nav opens a component page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    // Expand the Foundational category, then open Button.
    await tester.tap(find.text('Foundational'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Button'));
    await tester.pumpAndSettle();

    // The Button page is shown (title + its description).
    expect(
      find.text('Eight kinds across six sizes, with an optional icon.'),
      findsOneWidget,
    );
  });

  testWidgets('the menu button collapses the side nav to its rail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Toggle navigation'));
    await tester.pumpAndSettle();

    // Collapsed: the rail hides its labels.
    expect(find.text('Overview'), findsNothing);
  });
}
