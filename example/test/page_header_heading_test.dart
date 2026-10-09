// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show ViewFocusEvent, ViewFocusState, ViewFocusDirection;

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('gallery page header demonstrates hierarchy and an AT action', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    try {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => CarbonTheme(
              data: CarbonThemeData.white,
              child: entryForSlug(kCatalog, 'page-header')!.builder(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.text('Page header'))
            .getSemanticsData()
            .headingLevel,
        1,
      );
      expect(
        tester
            .getSemantics(
              find.text('Quarterly report with a deliberately long title'),
            )
            .getSemanticsData()
            .headingLevel,
        2,
      );
      for (int level = 1; level <= 6; level++) {
        tester
            .widget<CarbonDropdown<int>>(find.byType(CarbonDropdown<int>))
            .onChanged!(level);
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(
                find.text('Quarterly report with a deliberately long title'),
              )
              .getSemanticsData()
              .headingLevel,
          level,
        );
        expect(find.text('Edits: 0 · Downloads: 0'), findsOneWidget);
      }
      final SemanticsNode edit = tester.getSemantics(
        find.bySemanticsLabel('Edit report'),
      );
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: edit.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edits: 1 · Downloads: 0'), findsOneWidget);
      tester.view.physicalSize = const Size(320, 1000);
      await tester.pumpAndSettle();
      final Finder count = find.bySemanticsLabel(RegExp(r'^\d+ more tags$'));
      expect(count, findsOneWidget);
      await tester.tap(count);
      await tester.pumpAndSettle();
      await tester.tap(find.text('View regional report'));
      await tester.pumpAndSettle();
      expect(find.text('Tag views: 1 · Dismissals: 0'), findsOneWidget);
      if (find.bySemanticsLabel('Dismiss Draft').evaluate().isEmpty) {
        await tester.tap(count);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.bySemanticsLabel('Dismiss Draft'));
      await tester.pumpAndSettle();
      expect(find.text('Tag views: 1 · Dismissals: 1'), findsOneWidget);
      final SemanticsNode title = tester.getSemantics(
        find.text('Quarterly report with a deliberately long title'),
      );
      tester.binding.handleViewFocusChanged(
        ViewFocusEvent(
          viewId: tester.view.viewId,
          state: ViewFocusState.focused,
          direction: ViewFocusDirection.undefined,
        ),
      );
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.focus,
          viewId: tester.view.viewId,
          nodeId: title.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Quarterly report with a deliberately long title'),
        findsNWidgets(2),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        find.text('Quarterly report with a deliberately long title'),
        findsOneWidget,
      );
      tester
          .widgetList<CarbonToggle>(find.byType(CarbonToggle))
          .singleWhere(
            (CarbonToggle toggle) => toggle.labelText == 'Long title',
          )
          .onToggled!(false);
      await tester.pumpAndSettle();
      expect(find.text('Report'), findsOneWidget);
      final CarbonDropdown<String> hero = tester.widget<CarbonDropdown<String>>(
        find.byType(CarbonDropdown<String>),
      );
      hero.onChanged!('Image');
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Manufacturing presentation'),
        findsOneWidget,
      );
      tester
          .widgetList<CarbonToggle>(find.byType(CarbonToggle))
          .singleWhere(
            (CarbonToggle toggle) => toggle.labelText == 'Decorative image',
          )
          .onToggled!(true);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Manufacturing presentation'), findsNothing);
      hero.onChanged!('Custom');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(EditableText),
        'Keep the gallery draft',
      );
      final TextEditingController controller = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      tester.view.physicalSize = const Size(1200, 1000);
      await tester.pumpAndSettle();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller,
        same(controller),
      );
      expect(controller.text, 'Keep the gallery draft');
      tester.view.physicalSize = const Size(320, 1000);
      await tester.pumpAndSettle();
      expect(controller.text, 'Keep the gallery draft');
    } finally {
      handle.dispose();
    }
  });
}
