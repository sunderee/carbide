// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/semantics.dart';
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
            .getSemantics(find.text('Quarterly report'))
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
              .getSemantics(find.text('Quarterly report'))
              .getSemanticsData()
              .headingLevel,
          level,
        );
        expect(find.text('Edits: 0'), findsOneWidget);
      }
      final SemanticsNode edit = tester.getSemantics(
        find.bySemanticsLabel('Edit'),
      );
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: edit.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edits: 1'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });
}
