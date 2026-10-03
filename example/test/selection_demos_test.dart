// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('progress demo responds to AT and both orientation controls', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host('progress-indicator'));
      final SemanticsNode confirm = tester.getSemantics(
        find.bySemanticsLabel('Confirm'),
      );
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: confirm.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CarbonProgressIndicator>(
              find.byType(CarbonProgressIndicator),
            )
            .currentIndex,
        2,
      );
      await tester.ensureVisible(_toggle('Vertical'));
      await tester.tap(_toggle('Vertical'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CarbonProgressIndicator>(
              find.byType(CarbonProgressIndicator),
            )
            .vertical,
        isTrue,
      );
      await tester.ensureVisible(_toggle('Interactive'));
      await tester.tap(_toggle('Interactive'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Confirm'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      await tester.tap(find.text('Account'));
      expect(
        tester
            .widget<CarbonProgressIndicator>(
              find.byType(CarbonProgressIndicator),
            )
            .currentIndex,
        2,
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('table demo responds to AT row selection', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host('data-table'));
      final SemanticsNode row = tester.getSemantics(
        find.bySemanticsLabel('Select row Load balancer 2'),
      );
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: row.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CarbonDataTable>(find.byType(CarbonDataTable))
            .selectedRowIds,
        <Object>{'Load balancer 2'},
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Select all rows')),
        isSemantics(isCheckStateMixed: true),
      );
    } finally {
      handle.dispose();
    }
  });
  testWidgets('table demo sorting preserves selected and expanded record IDs', (
    tester,
  ) async {
    await tester.pumpWidget(_host('data-table'));
    await tester.ensureVisible(_toggle('Expandable'));
    await tester.tap(_toggle('Expandable'));
    await tester.pumpAndSettle();
    final table = tester.widget<CarbonDataTable>(find.byType(CarbonDataTable));
    table.onSelectedRowIdsChanged!(<Object>{'Load balancer 2'});
    table.onExpansionChanged!(<Object>{'Load balancer 2'});
    await tester.pumpAndSettle();
    for (int i = 0; i < 3; i++) {
      tester.widget<CarbonDataTable>(find.byType(CarbonDataTable)).onSort!(0);
      await tester.pumpAndSettle();
      final current = tester.widget<CarbonDataTable>(
        find.byType(CarbonDataTable),
      );
      expect(current.selectedRowIds, <Object>{'Load balancer 2'});
      expect(current.expandedRowIds, <Object>{'Load balancer 2'});
      expect(
        current.rows.map((row) => row.id),
        i == 1
            ? <Object>['Load balancer 3', 'Load balancer 2', 'Load balancer 1']
            : <Object>['Load balancer 1', 'Load balancer 2', 'Load balancer 3'],
      );
    }
  });
}

Widget _host(String slug) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(
      child: SizedBox(
        width: 700,
        child: entryForSlug(kCatalog, slug)!.builder(),
      ),
    ),
  ),
);

Finder _toggle(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is Semantics && widget.properties.label == label,
);
