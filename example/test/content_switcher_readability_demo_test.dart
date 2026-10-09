// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0. See LICENSE.
import 'dart:ui' show ViewFocusEvent, ViewFocusState, ViewFocusDirection;

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'gallery switcher demonstrates 160px at actual 2x and named icons',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xffffffff),
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => CarbonTheme(
                data: CarbonThemeData.white,
                child: entryForSlug(kCatalog, 'content-switcher')!.builder(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .widgetList<CarbonDropdown<double>>(
              find.byType(CarbonDropdown<double>),
            )
            .singleWhere((w) => w.titleText == 'Control width')
            .onChanged!(160);
        tester
            .widgetList<CarbonDropdown<double>>(
              find.byType(CarbonDropdown<double>),
            )
            .singleWhere((w) => w.titleText == 'Text scale')
            .onChanged!(2);
        await tester.pumpAndSettle();
        expect(
          MediaQuery.textScalerOf(
            tester.element(find.byType(CarbonContentSwitcher)),
          ).scale(1),
          2,
        );
        tester.binding.handleViewFocusChanged(
          ViewFocusEvent(
            viewId: tester.view.viewId,
            state: ViewFocusState.focused,
            direction: ViewFocusDirection.undefined,
          ),
        );
        Focus.of(tester.element(find.text('Day'))).requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CarbonContentSwitcher>(find.byType(CarbonContentSwitcher))
              .selectedIndex,
          2,
        );
        final selected = tester.getRect(find.bySemanticsLabel('Month')),
            control = tester.getRect(find.byType(CarbonContentSwitcher));
        expect(selected.left, greaterThanOrEqualTo(control.left - .1));
        expect(selected.right, lessThanOrEqualTo(control.right + .1));
        tester
            .widgetList<CarbonToggle>(find.byType(CarbonToggle))
            .singleWhere((t) => t.labelText == 'Icon only')
            .onToggled!(true);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Archived view'), findsOneWidget);
        expect(
          tester
              .widget<CarbonContentSwitcher>(find.byType(CarbonContentSwitcher))
              .selectedIndex,
          2,
        );
        tester
            .widgetList<CarbonToggle>(find.byType(CarbonToggle))
            .singleWhere((t) => t.labelText == 'Disable last segment')
            .onToggled!(true);
        await tester.pumpAndSettle();
        final s = tester
            .getSemantics(find.bySemanticsLabel('Archived view'))
            .getSemanticsData();
        expect(s.flagsCollection.isEnabled.name, 'isFalse');
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    },
  );
}
