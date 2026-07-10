// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
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
import '../support/overlay_entries.dart';

Widget _host(double scale, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      // Overlay so portal-based specimens (dialog) can mount.
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (BuildContext context) =>
                Align(alignment: AlignmentDirectional.topStart, child: child),
          ),
        ],
      ),
    ),
  ),
);

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

  group('goldens', () {
    testWidgets('text input canary at 1.3x pins the grown chrome', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'text_input_scaled_1_3',
        containsText: true,
        size: const Size(320, 140),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(1.3)),
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
