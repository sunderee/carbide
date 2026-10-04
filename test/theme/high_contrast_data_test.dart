// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final base in [
    CarbonThemeData.white,
    CarbonThemeData.gray10,
    CarbonThemeData.gray90,
    CarbonThemeData.gray100,
  ]) {
    test(
      '${base.brightness} derivation is cached, idempotent and immutable',
      () {
        final before = base.copyWith();
        final derived = CarbonThemeData.highContrast(base);
        expect(base, before);
        expect(derived, isNot(same(base)));
        expect(CarbonThemeData.highContrast(base), same(derived));
        expect(CarbonThemeData.highContrast(derived), same(derived));
        expect(derived.brightness, base.brightness);
        expect(derived.background, base.background);
        expect(
          [derived.layer01, derived.layer02, derived.layer03],
          [base.layer01, base.layer02, base.layer03],
        );
        expect(
          [
            derived.buttonPrimary,
            derived.buttonSecondary,
            derived.buttonDangerPrimary,
          ],
          [base.buttonPrimary, base.buttonSecondary, base.buttonDangerPrimary],
        );
        expect(
          [
            derived.supportError,
            derived.supportSuccess,
            derived.supportWarning,
            derived.supportInfo,
          ],
          [
            base.supportError,
            base.supportSuccess,
            base.supportWarning,
            base.supportInfo,
          ],
        );
        expect([
          derived.textSecondary.a,
          derived.textHelper.a,
          derived.textPlaceholder.a,
          derived.textDisabled.a,
        ], everyElement(1.0));
      },
    );
  }

  test('custom surfaces and brand colors survive derivation without sharing a cache entry', () {
    final base = CarbonThemeData.white.copyWith(
      background: CarbonColors.gray10,
      backgroundBrand: CarbonColors.purple60,
      buttonPrimary: CarbonColors.purple60,
      supportError: CarbonColors.red70,
    );
    final derived = CarbonThemeData.highContrast(base);
    expect(derived.background, CarbonColors.gray10);
    expect(derived.backgroundBrand, CarbonColors.purple60);
    expect(derived.buttonPrimary, CarbonColors.purple60);
    expect(derived.supportError, CarbonColors.red70);
    expect(
      derived,
      isNot(same(CarbonThemeData.highContrast(CarbonThemeData.white))),
    );
    expect(base.borderSubtle00, CarbonThemeData.white.borderSubtle00);
  });
}
