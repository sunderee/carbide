// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Text-scaling legibility sweep (#228): every specimen renders under the
// two scales that matter — 1.3x (the most common system accessibility
// setting) and 2.0x (the WCAG 1.4.4 requirement) — and must lay out
// without exceptions (overflow errors throw in tests) and without
// squeezing any text below one scaled line box. Policy in
// docs/text-scaling.md.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';
import '../support/legibility.dart';
import '../support/specimens.dart';

Widget _host(double scale, Widget child) =>
    carbideSpecimenHost(scale: scale, child: child);

void main() {
  for (final double scale in <double>[1.3, 2.0]) {
    group('${scale}x text scale', () {
      for (final MapEntry<String, WidgetBuilder> entry
          in carbideSpecimens.entries) {
        testWidgets('${entry.key} lays out legibly', (
          WidgetTester tester,
        ) async {
          // Wide surface: scaled text grows widths too, and wide
          // specimens (pagination) must not clamp to the 800px default.
          tester.view.physicalSize = const Size(1400, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(_host(scale, Builder(builder: entry.value)));
          await tester.pump();
          expect(tester.takeException(), isNull);
          expectNoClippedTextAtScale(tester, scale);
        });
      }
    });
  }

  for (final double scale in <double>[1.3, 2.0]) {
    for (final TextDirection direction in TextDirection.values) {
      for (final entry in carbideOpenSpecimens.entries) {
        testWidgets('${entry.key} open at ${scale}x $direction', (
          tester,
        ) async {
          await tester.pumpWidget(
            carbideSpecimenHost(
              scale: scale,
              direction: direction,
              child: Builder(builder: carbideSpecimens[entry.key]!),
            ),
          );
          await tester.pump();
          await entry.value.$1?.call(tester);
          await tester.pump(const Duration(milliseconds: 300));
          await tester.pump();
          expect(
            entry.value.$2,
            findsWidgets,
            reason: 'The popup must actually be open.',
          );
          final Rect popupMarker = tester.getRect(entry.value.$2.first);
          expect(
            popupMarker.left,
            greaterThanOrEqualTo(-0.5),
            reason: '${entry.key}: $popupMarker',
          );
          expect(popupMarker.top, greaterThanOrEqualTo(-0.5));
          expect(popupMarker.right, lessThanOrEqualTo(1400.5));
          expect(popupMarker.bottom, lessThanOrEqualTo(1000.5));
          expect(tester.takeException(), isNull);
          expectNoClippedTextAtScale(tester, scale);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  group('goldens', () {
    testWidgets('text input canary at 1.3x pins the grown chrome', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'text_input_scaled_1_3',
        containsText: true,
        size: const Size(320, 140),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 280,
            child: CarbonTextInput(
              labelText: 'Email',
              placeholder: 'you@example.com',
              helperText: 'Helper',
            ),
          ),
        ),
      );
    });
  });
}
