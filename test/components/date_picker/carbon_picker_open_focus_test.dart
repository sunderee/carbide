// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';

void main() {
  for (final String opener in <String>['Date', 'Start date', 'End date']) {
    for (final bool focusTrigger in <bool>[false, true]) {
      testWidgets(
        '$opener pointer opening transfers ${focusTrigger ? "trigger" : "outside"} focus to the grid',
        (WidgetTester tester) async {
          final FocusNode outside = FocusNode(debugLabel: 'Outside');
          addTearDown(outside.dispose);
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          int changes = 0;
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: CarbonTheme(
                data: CarbonThemeData.white,
                child: TapRegionSurface(
                  child: Overlay(
                    initialEntries: <OverlayEntry>[
                      managedOverlayEntry(
                        builder: (_) => Align(
                          alignment: Alignment.topLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CarbonButton(
                                label: 'Outside',
                                focusNode: outside,
                                onPressed: () {},
                              ),
                              SizedBox(
                                width: 320,
                                child: opener == 'Date'
                                    ? CarbonDatePicker(
                                        labelText: 'Date',
                                        value: DateTime(2026, 6, 15),
                                        onChanged: (_) => changes++,
                                      )
                                    : CarbonDateRangePicker(
                                        value: CarbonDateRange(
                                          DateTime(2026, 6, 10),
                                          DateTime(2026, 6, 12),
                                        ),
                                        onChanged: (_) => changes++,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          final String focusLabel = opener == 'Date'
              ? 'CarbonDatePicker'
              : 'CarbonDateRangePicker.${opener == "Start date" ? "start" : "end"}';
          final FocusNode trigger = tester
              .widgetList<Focus>(find.byType(Focus))
              .map((Focus widget) => widget.focusNode)
              .whereType<FocusNode>()
              .singleWhere((FocusNode node) => node.debugLabel == focusLabel);
          (focusTrigger ? trigger : outside).requestFocus();
          await tester.pumpAndSettle();
          // The browser focuses the value chrome before pointer activation.
          // Range labels cover their separate activation path too.
          final String text = opener == 'Date'
              ? '06/15/2026'
              : opener == 'Start date'
              ? '06/10/2026'
              : '06/12/2026';
          for (final String target in <String>[
            text,
            opener == 'Date' ? text : opener,
          ]) {
            await tester.tap(find.text(target));
            await tester.pumpAndSettle();
            expect(
              FocusManager.instance.primaryFocus?.debugLabel,
              'CarbonCalendar',
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            expect(find.byType(CarbonCalendar), findsNothing);
            expect(FocusManager.instance.primaryFocus, trigger);
            expect(changes, 0);
          }
        },
      );
    }
  }

  testWidgets('single commit closes before a reentrant notification', (
    WidgetTester tester,
  ) async {
    int changes = 0;
    late CarbonCalendar calendar;
    calendar = await _openSingle(tester, (DateTime day) {
      changes++;
      if (changes == 1) calendar.onChanged!(day);
    });
    calendar.onChanged!(DateTime(2026, 6, 20));
    await tester.pumpAndSettle();
    expect(changes, 1);
    expect(find.byType(CarbonCalendar), findsNothing);
  });

  testWidgets('unmounting an open single picker gates retained callbacks', (
    WidgetTester tester,
  ) async {
    int changes = 0;
    final CarbonCalendar calendar = await _openSingle(tester, (_) => changes++);
    await tester.pumpWidget(const SizedBox.shrink());
    calendar.onChanged!(DateTime(2026, 6, 20));
    calendar.onEscape!();
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(tester.takeException(), isNull);
  });
}

Future<CarbonCalendar> _openSingle(
  WidgetTester tester,
  ValueChanged<DateTime> onChanged,
) async {
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: TapRegionSurface(
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) => Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 320,
                    child: CarbonDatePicker(
                      labelText: 'Date',
                      value: DateTime(2026, 6, 15),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('06/15/2026'));
  await tester.pumpAndSettle();
  return tester.widget<CarbonCalendar>(find.byType(CarbonCalendar));
}
