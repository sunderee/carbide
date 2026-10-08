// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overlay_entries.dart';
import '../support/scaled_fields.dart';

Widget _host(Widget child, TextDirection direction, Alignment corner) =>
    Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: const MediaQueryData(size: Size(320, 360)),
        child: TapRegionSurface(
          child: CarbonTheme(
            data: CarbonThemeData.white,
            child: Overlay(
              initialEntries: <OverlayEntry>[
                managedOverlayEntry(
                  builder: (_) => Align(
                    alignment: corner,
                    child: SizedBox(width: 180, child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

void main() {
  final Map<String, WidgetBuilder> surfaces = <String, WidgetBuilder>{
    for (final String name in <String>[
      'dropdown',
      'select',
      'combo box',
      'multi select',
      'filterable multi select',
    ])
      name: scaledFieldSpecimens()[name]!,
    'overflow menu': (_) => CarbonOverflowMenu(
      items: <Widget>[
        CarbonMenuItem(label: 'Edit', onPressed: () {}),
        CarbonMenuItem(label: 'Duplicate', onPressed: () {}),
      ],
    ),
    'popover': (_) => const CarbonPopover(
      open: true,
      autoAlign: true,
      content: SizedBox(
        key: ValueKey<String>('popup'),
        width: 250,
        height: 130,
      ),
      child: SizedBox(width: 180, height: 32),
    ),
  };
  for (final TextDirection direction in TextDirection.values) {
    for (final Alignment corner in <Alignment>[
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ]) {
      for (final MapEntry<String, WidgetBuilder> entry in surfaces.entries) {
        testWidgets('${entry.key} fits $corner in $direction', (tester) async {
          tester.view.physicalSize = const Size(320, 360);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          await tester.pumpWidget(
            _host(Builder(builder: entry.value), direction, corner),
          );
          if (entry.key != 'popover') {
            final Finder trigger = switch (entry.key) {
              'combo box' ||
              'filterable multi select' => find.byType(EditableText),
              'overflow menu' => find.byType(CarbonButton),
              'select' => find.text('gypy 0'),
              _ => find.byType(CarbonListBox),
            };
            await tester.tap(trigger.first);
            if (entry.key == 'filterable multi select') {
              await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            }
          }
          await tester.pumpAndSettle();
          final Finder popup = switch (entry.key) {
            'popover' => find.byKey(const ValueKey<String>('popup')),
            'overflow menu' => find.byType(CarbonMenu),
            'select' => find.byType(SingleChildScrollView),
            _ => find.byType(CarbonListBoxMenu),
          };
          final Rect bounds = tester.getRect(popup.first);
          expect(bounds.left, greaterThanOrEqualTo(-0.01));
          expect(bounds.right, lessThanOrEqualTo(320.01));
          expect(bounds.top, greaterThanOrEqualTo(-0.01));
          expect(bounds.bottom, lessThanOrEqualTo(360.01));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
