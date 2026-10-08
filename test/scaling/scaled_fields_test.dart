// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide/src/utils/scroll_into_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/legibility.dart';
import '../support/golden.dart';
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
  testWidgets('scaled focused field keeps its line inside the inset outline', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(
      _host(2, Builder(builder: scaledFieldSpecimens()['combo box']!)),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    final Finder outline = find
        .ancestor(
          of: find.byType(EditableText),
          matching: find.byType(CarbonFocusRing),
        )
        .first;
    expect(tester.widget<CarbonFocusRing>(outline).visible, isTrue);
    final Rect field = tester.getRect(outline);
    final Rect line = tester.getRect(find.text('gypy'));
    expect(line.top, greaterThanOrEqualTo(field.top + 2));
    expect(line.bottom, lessThanOrEqualTo(field.bottom - 2));
  });
  testWidgets('a fluid filterable multi-select retains its inside title', (
    tester,
  ) async {
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
    });
    await tester.pumpWidget(
      _host(
        1,
        Builder(
          builder: scaledFieldSpecimens(
            fluid: true,
          )['filterable multi select']!,
        ),
      ),
    );
    expect(find.text('Cities'), findsOneWidget);
    expect(
      tester.getSize(find.byType(CarbonMultiSelect<int>)).height,
      greaterThanOrEqualTo(64),
    );
  });
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
          // Reach options beyond the original 5.5-row fold after rows grow.
          // Their presence in an eager tree alone does not prove visibility.
          for (int step = 0; step < 10; step++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
            final Finder active = find.byWidgetPredicate(
              (Widget widget) => widget is ScrollIntoView && widget.active,
            );
            expect(active, findsOneWidget);
            final Rect row = tester.getRect(active);
            expect(row.top, greaterThanOrEqualTo(popup.top - 0.5));
            expect(row.bottom, lessThanOrEqualTo(popup.bottom + 0.5));
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(popupFinder, findsNothing);
        });
      }
    }
  }
  testWidgets('long fluid search labels stay bounded with the complete name', (
    tester,
  ) async {
    const String label = 'Search for people, projects and archived documents';
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          2,
          const CarbonSearch(
            labelText: label,
            initialValue: 'gypy',
            fluid: true,
            size: CarbonFieldSize.sm,
          ),
        ),
      );
      expectNoClippedTextAtScale(tester, 2);
      expect(tester.getSize(find.text(label)).width, lessThanOrEqualTo(288));
      expect(find.bySemanticsLabel(label), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      handle.dispose();
    }
  });
  for (final (double scale, bool fluid) state in <(double, bool)>[
    (1, false),
    (2, false),
    (1.3, true),
    (2, true),
  ]) {
    testWidgets('field chrome golden ${state.$1}/fluid=${state.$2}', (
      tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name:
            'fields_${state.$1.toString().replaceAll('.', '_')}_fluid_${state.$2}',
        containsText: true,
        size: const Size(720, 900),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(state.$1)),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 24,
            runSpacing: 20,
            children: <Widget>[
              for (final MapEntry<String, WidgetBuilder> entry
                  in scaledFieldSpecimens(fluid: state.$2).entries)
                SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(entry.key, style: CarbonTypeStyles.label01),
                      const SizedBox(height: 8),
                      Builder(builder: entry.value),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
  for (final bool fluid in <bool>[false, true]) {
    testWidgets('open dropdown grown rows golden/fluid=$fluid', (tester) async {
      await expectThemeGoldens(
        tester,
        name: 'dropdown_open_scale_2_fluid_$fluid',
        containsText: true,
        size: const Size(360, 520),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2)),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 320,
                    child: Builder(
                      builder: scaledFieldSpecimens(fluid: fluid)['dropdown']!,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.tap(find.byType(CarbonListBox));
          await tester.pumpAndSettle();
          expectNoClippedTextAtScale(tester, 2);
        },
      );
    });
  }
}
