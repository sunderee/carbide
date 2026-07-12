// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/animation.dart' show Cubic;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('durations match the Carbon source (ms)', () {
    expect(CarbonDuration.fast01.inMilliseconds, 70);
    expect(CarbonDuration.fast02.inMilliseconds, 110);
    expect(CarbonDuration.moderate01.inMilliseconds, 150);
    expect(CarbonDuration.moderate02.inMilliseconds, 240);
    expect(CarbonDuration.slow01.inMilliseconds, 400);
    expect(CarbonDuration.slow02.inMilliseconds, 700);
  });

  test('easing curves match the Carbon cubic-bezier values', () {
    void expectCubic(Cubic curve, double a, double b, double c, double d) {
      expect(
        <double>[curve.a, curve.b, curve.c, curve.d],
        <double>[a, b, c, d],
      );
    }

    expectCubic(CarbonEasing.standardProductive, 0.2, 0, 0.38, 0.9);
    expectCubic(CarbonEasing.standardExpressive, 0.4, 0.14, 0.3, 1);
    expectCubic(CarbonEasing.entranceProductive, 0, 0, 0.38, 0.9);
    expectCubic(CarbonEasing.entranceExpressive, 0, 0, 0.3, 1);
    expectCubic(CarbonEasing.exitProductive, 0.2, 0, 1, 0.9);
    expectCubic(CarbonEasing.exitExpressive, 0.4, 0.14, 1, 1);
  });

  test('resolve maps every style/mode pair to the right curve', () {
    expect(
      CarbonEasing.resolve(
        CarbonEasingStyle.standard,
        CarbonEasingMode.productive,
      ),
      same(CarbonEasing.standardProductive),
    );
    expect(
      CarbonEasing.resolve(
        CarbonEasingStyle.entrance,
        CarbonEasingMode.expressive,
      ),
      same(CarbonEasing.entranceExpressive),
    );
    expect(
      CarbonEasing.resolve(CarbonEasingStyle.exit, CarbonEasingMode.productive),
      same(CarbonEasing.exitProductive),
    );
  });
}
