// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.
import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/gallery_app.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _desktop(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const GalleryApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first Tab reveals skip and Enter transfers focus to main', (
    WidgetTester tester,
  ) async {
    await _desktop(tester);
    expect(find.text('Skip to main content'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Skip to main content'), findsOneWidget);
    final Size headerBefore = tester.getSize(find.byType(CarbonHeader));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final CarbonShellContent main = tester.widget<CarbonShellContent>(
      find.byType(CarbonShellContent),
    );
    expect(main.focusNode!.hasPrimaryFocus, isTrue);
    expect(find.text('Skip to main content'), findsNothing);
    expect(tester.getSize(find.byType(CarbonHeader)), headerBefore);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus!.ancestors,
      contains(main.focusNode),
    );
  });
  testWidgets('header Home is keyboard and AT activatable', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await _desktop(tester);
      if (find.text('Button').hitTestable().evaluate().isEmpty) {
        await tester.tap(find.text('Foundational'));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Button').hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.text('Button kinds and sizes, with an optional icon.'),
        findsOneWidget,
      );
      final CarbonHeaderName home = tester.widget<CarbonHeaderName>(
        find.byType(CarbonHeaderName),
      );
      expect(home.onPressed, isNotNull);
      Focus.of(tester.element(find.text('Gallery'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('White'), findsOneWidget);
      if (find.text('Button').hitTestable().evaluate().isEmpty) {
        await tester.tap(find.text('Foundational'));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Button').hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.text('Button kinds and sizes, with an optional icon.'),
        findsOneWidget,
      );
      final SemanticsNode node = tester.getSemantics(
        find.byType(CarbonHeaderName),
      );
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('White'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });
  testWidgets(
    'mobile navigation opens over full width main and closes on navigation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const GalleryApp());
      await tester.pumpAndSettle();
      expect(find.byType(CarbonSideNav), findsNothing);
      expect(tester.getSize(find.byType(CarbonShellContent)).width, 320);
      await tester.tap(find.bySemanticsLabel('Toggle navigation'));
      await tester.pumpAndSettle();
      expect(find.byType(CarbonSideNav), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(tester.getSize(find.byType(CarbonShellContent)).width, 320);
      if (find.text('Button').hitTestable().evaluate().isEmpty) {
        await tester.tap(find.text('Foundational'));
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Button').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(CarbonSideNav), findsNothing);
      expect(
        find.text('Button kinds and sizes, with an optional icon.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
