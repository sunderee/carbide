// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/picker_fixture.dart';

void main() {
  for (final bool fluid in <bool>[false, true]) {
    testWidgets('read-only and disabled picker family, fluid=$fluid (#312)', (
      tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: fluid ? 'picker-read-only-fluid' : 'picker-read-only',
        containsText: true,
        directions: <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        size: const Size(800, 1040),
        afterPump: (tester) async {
          final PickerFixtureState state = tester.state(
            find.byType(PickerFixture).first,
          );
          state.focus.requestFocus();
          await tester.pump();
          await tester.pump();
          expect(state.focus.hasPrimaryFocus, isTrue);
          expect(
            tester
                .widget<CarbonFocusRing>(
                  find
                      .descendant(
                        of: find.byType(PickerFixture).first,
                        matching: find.byType(CarbonFocusRing),
                      )
                      .first,
                )
                .visible,
            isTrue,
          );
        },
        builder: (context) => DefaultTextStyle(
          style: CarbonTypeStyles.bodyCompact01.copyWith(
            color: CarbonTheme.of(context).textPrimary,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final bool disabled in <bool>[false, true]) ...<Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(disabled ? 'Disabled' : 'Read only'),
                        for (final PickerKind kind in PickerKind.values)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(kind.name),
                                const SizedBox(height: 4),
                                PickerFixture(
                                  kind: kind,
                                  disabled: disabled,
                                  fluid: fluid,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!disabled) const SizedBox(width: 24),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
