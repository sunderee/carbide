// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';
import '../support/high_contrast_specimen.dart';

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('high-contrast specimens at $scale text scale', (tester) async {
      await expectThemeGoldens(
        tester,
        name: 'high_contrast_${scale == 1 ? 'normal' : 'scaled'}',
        size: const Size(1200, 900),
        containsText: true,
        strict: true,
        directions: {TextDirection.ltr, TextDirection.rtl},
        mediaQuery: MediaQueryData(
          highContrast: true,
          disableAnimations: true,
          textScaler: TextScaler.linear(scale),
        ),
        builder: (_) => const Align(
          alignment: Alignment.topCenter,
          child: HighContrastSpecimen(),
        ),
        afterPump: (tester) async {
          final state = tester.state<HighContrastSpecimenState>(
            find.byType(HighContrastSpecimen),
          );
          state.buttonFocus[scale == 1 ? 0 : 2].requestFocus();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    });
  }
}
