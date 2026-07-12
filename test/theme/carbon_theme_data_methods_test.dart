// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui';

import 'package:carbide/carbide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('copyWith', () {
    test('replaces only the named tokens', () {
      final CarbonThemeData themed = CarbonThemeData.white.copyWith(
        background: CarbonColors.blue60,
      );
      expect(themed.background, CarbonColors.blue60);
      expect(themed.textPrimary, CarbonThemeData.white.textPrimary);
      expect(themed.brightness, CarbonThemeData.white.brightness);
    });

    test('is equal to the original when given no arguments', () {
      expect(CarbonThemeData.white.copyWith(), CarbonThemeData.white);
    });
  });

  group('lerp', () {
    test('returns the endpoints at t = 0 and t = 1', () {
      expect(
        CarbonThemeData.lerp(CarbonThemeData.white, CarbonThemeData.gray100, 0),
        CarbonThemeData.white,
      );
      expect(
        CarbonThemeData.lerp(CarbonThemeData.white, CarbonThemeData.gray100, 1),
        CarbonThemeData.gray100,
      );
    });

    test('interpolates tokens at the midpoint', () {
      final CarbonThemeData mid = CarbonThemeData.lerp(
        CarbonThemeData.white,
        CarbonThemeData.gray100,
        0.5,
      );
      expect(
        mid.background,
        Color.lerp(
          CarbonThemeData.white.background,
          CarbonThemeData.gray100.background,
          0.5,
        ),
      );
    });

    test('brightness snaps to b from the midpoint', () {
      CarbonThemeData at(double t) => CarbonThemeData.lerp(
        CarbonThemeData.white,
        CarbonThemeData.gray100,
        t,
      );
      expect(at(0.4).brightness, Brightness.light);
      expect(at(0.5).brightness, Brightness.dark);
      expect(at(0.6).brightness, Brightness.dark);
    });
  });

  group('component tokens (hand-sourced from component-tokens/*.ts)', () {
    test('button tokens fold into every theme', () {
      for (final CarbonThemeData theme in <CarbonThemeData>[
        CarbonThemeData.white,
        CarbonThemeData.gray10,
        CarbonThemeData.gray90,
        CarbonThemeData.gray100,
      ]) {
        expect(theme.buttonPrimary, CarbonColors.blue60);
        expect(theme.buttonDangerPrimary, CarbonColors.red60);
      }
    });

    test('theme-dependent component tokens diverge light vs dark', () {
      expect(CarbonThemeData.white.buttonSeparator, CarbonColors.gray20);
      expect(CarbonThemeData.gray100.buttonSeparator, CarbonColors.gray100);
      expect(CarbonThemeData.white.tagBackgroundRed, CarbonColors.red20);
      expect(CarbonThemeData.gray100.tagBackgroundRed, CarbonColors.red70);
      expect(
        CarbonThemeData.gray90.buttonDisabled,
        const Color.fromRGBO(141, 141, 141, 0.3),
      );
    });
  });

  group('AI tokens (ai-* group)', () {
    final List<CarbonThemeData> themes = <CarbonThemeData>[
      CarbonThemeData.white,
      CarbonThemeData.gray10,
      CarbonThemeData.gray90,
      CarbonThemeData.gray100,
    ];

    test('the aura gradient fades from a translucent start to transparent', () {
      for (final CarbonThemeData theme in themes) {
        expect(theme.aiAuraEnd.a, 0.0);
        expect(theme.aiAuraHoverEnd.a, 0.0);
        expect(theme.aiAuraStart.a, greaterThan(0.0));
        expect(theme.aiAuraStart.a, lessThan(1.0));
        expect(theme.aiAuraHoverStart.a, greaterThan(theme.aiAuraStart.a));
      }
    });

    test(
      'the popover background follows the theme surface (light vs dark)',
      () {
        expect(CarbonThemeData.white.aiPopoverBackground, CarbonColors.white);
        expect(
          CarbonThemeData.gray100.aiPopoverBackground,
          CarbonColors.gray100,
        );
        expect(
          CarbonThemeData.white.aiPopoverBackground,
          isNot(CarbonThemeData.gray100.aiPopoverBackground),
        );
      },
    );

    test('border stops are solid blues; the drop shadow is translucent', () {
      expect(CarbonThemeData.white.aiBorderStrong, CarbonColors.blue50);
      expect(CarbonThemeData.gray100.aiBorderStrong, CarbonColors.blue40);
      expect(CarbonThemeData.white.aiDropShadow.a, lessThan(1.0));
    });

    test('fold into copyWith, lerp, and equality like every other token', () {
      final CarbonThemeData themed = CarbonThemeData.white.copyWith(
        aiPopoverBackground: CarbonColors.blue60,
      );
      expect(themed.aiPopoverBackground, CarbonColors.blue60);
      expect(themed.aiBorderStrong, CarbonThemeData.white.aiBorderStrong);
      expect(themed, isNot(CarbonThemeData.white));

      final CarbonThemeData mid = CarbonThemeData.lerp(
        CarbonThemeData.white,
        CarbonThemeData.gray100,
        0.5,
      );
      expect(
        mid.aiOverlay,
        Color.lerp(
          CarbonThemeData.white.aiOverlay,
          CarbonThemeData.gray100.aiOverlay,
          0.5,
        ),
      );
    });
  });

  group('equality', () {
    test('a theme equals itself and a field-identical copy', () {
      expect(CarbonThemeData.white, CarbonThemeData.white);
      expect(CarbonThemeData.white.copyWith(), equals(CarbonThemeData.white));
      expect(
        CarbonThemeData.white.hashCode,
        CarbonThemeData.white.copyWith().hashCode,
      );
    });

    test('themes differing by one token are not equal', () {
      final CarbonThemeData changed = CarbonThemeData.white.copyWith(
        focus: CarbonColors.blue40,
      );
      expect(changed, isNot(CarbonThemeData.white));
      expect(CarbonThemeData.white, isNot(CarbonThemeData.gray100));
    });
  });
}
