// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/legibility.dart';
import '../support/overlay_entries.dart';
import '../support/scaled_fields.dart';

Widget _host(double scale, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (_) => Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(width: 320, child: child),
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  for (final double scale in <double>[1.3, 2]) {
    for (final bool fluid in <bool>[false, true]) {
      for (final MapEntry<String, WidgetBuilder> entry in scaledFieldSpecimens(
        fluid: fluid,
      ).entries) {
        testWidgets('${entry.key} small/fluid=$fluid at $scale', (
          tester,
        ) async {
          // Test failures must still remove overlays/editors before leak checks.
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox.shrink());
          });
          await tester.pumpWidget(_host(scale, Builder(builder: entry.value)));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expectNoClippedTextAtScale(tester, scale);
          for (final CarbonIcon icon in tester.widgetList<CarbonIcon>(
            find.byType(CarbonIcon),
          )) {
            expect(icon.size, isIn(<double>[12, 16, 20]));
            expect(tester.getSize(find.byWidget(icon)), Size.square(icon.size));
          }
        });
      }
      for (final String name in <String>[
        'dropdown',
        'select',
        'combo box',
        'multi select',
        'filterable multi select',
        'time picker',
      ]) {
        testWidgets('$name open/fluid=$fluid at $scale', (tester) async {
          addTearDown(() async {
            await tester.pumpWidget(const SizedBox.shrink());
          });
          await tester.pumpWidget(
            _host(
              scale,
              Builder(builder: scaledFieldSpecimens(fluid: fluid)[name]!),
            ),
          );
          await tester.pump();
          if (name == 'combo box' || name == 'filterable multi select') {
            await tester.tap(find.byType(EditableText).first);
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          } else if (name == 'select') {
            await tester.tap(find.text('gypy 0'));
          } else if (name == 'time picker') {
            await tester.tap(find.text('AM'));
          } else {
            await tester.tap(find.byType(CarbonListBox));
          }
          await tester.pumpAndSettle();
          final Finder popupFinder = name == 'select' || name == 'time picker'
              ? find.byType(SingleChildScrollView)
              : find.byType(CarbonListBoxMenu);
          expect(popupFinder, findsOneWidget);
          expect(tester.takeException(), isNull);
          expectNoClippedTextAtScale(tester, scale);
          final Rect popup = tester.getRect(popupFinder);
          expect(popup.top, greaterThanOrEqualTo(0));
          expect(
            popup.bottom,
            lessThanOrEqualTo(tester.view.physicalSize.height),
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(popupFinder, findsNothing);
        });
      }
    }
  }
}
