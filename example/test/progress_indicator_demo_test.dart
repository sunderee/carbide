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
    'gallery progress shows narrow, scaled, optional and interactive states',
    (tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => CarbonTheme(
              data: CarbonThemeData.white,
              child: entryForSlug(kCatalog, 'progress-indicator')!.builder(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widgetList<CarbonToggle>(find.byType(CarbonToggle))
          .singleWhere((t) => t.labelText == 'Narrow flow')
          .onToggled!(true);
      tester
          .widget<CarbonDropdown<double>>(find.byType(CarbonDropdown<double>))
          .onChanged!(2);
      await tester.pumpAndSettle();
      final indicator = tester.widget<CarbonProgressIndicator>(
        find.byType(CarbonProgressIndicator),
      );
      expect(indicator.vertical, isFalse);
      expect(indicator.steps[1].secondaryLabel, 'Optional');
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(CarbonProgressIndicator)),
        ).scale(1),
        2,
      );
      final label = find.text('Confirm with a deliberately long name');
      await tester.ensureVisible(label);
      await tester.pumpAndSettle();
      tester.binding.handleViewFocusChanged(
        ViewFocusEvent(
          viewId: tester.view.viewId,
          state: ViewFocusState.focused,
          direction: ViewFocusDirection.undefined,
        ),
      );
      Focus.of(tester.element(label)).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Current step: 3'), findsOneWidget);
      tester
          .widgetList<CarbonToggle>(find.byType(CarbonToggle))
          .singleWhere((t) => t.labelText == 'Vertical')
          .onToggled!(true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CarbonProgressIndicator>(
              find.byType(CarbonProgressIndicator),
            )
            .vertical,
        isTrue,
      );
      tester
          .widgetList<CarbonToggle>(find.byType(CarbonToggle))
          .singleWhere((t) => t.labelText == 'Interactive')
          .onToggled!(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Current step: 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
