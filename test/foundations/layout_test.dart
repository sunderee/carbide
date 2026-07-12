// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spacing scale matches the Carbon mini-unit values', () {
    expect(CarbonSpacing.steps, <double>[
      2,
      4,
      8,
      12,
      16,
      24,
      32,
      40,
      48,
      64,
      80,
      96,
      160,
    ]);
  });

  test('spacing scale is strictly ascending', () {
    for (int i = 1; i < CarbonSpacing.steps.length; i++) {
      expect(CarbonSpacing.steps[i], greaterThan(CarbonSpacing.steps[i - 1]));
    }
  });

  test('sizes, containers, and icon sizes match the Carbon source', () {
    expect(
      <double>[
        CarbonSize.xSmall,
        CarbonSize.small,
        CarbonSize.medium,
        CarbonSize.large,
        CarbonSize.xLarge,
        CarbonSize.xxLarge,
      ],
      <double>[24, 32, 40, 48, 64, 80],
    );
    expect(
      <double>[
        CarbonContainer.container01,
        CarbonContainer.container02,
        CarbonContainer.container03,
        CarbonContainer.container04,
        CarbonContainer.container05,
      ],
      <double>[24, 32, 40, 48, 64],
    );
    expect(CarbonIconSize.iconSize01, 16);
    expect(CarbonIconSize.iconSize02, 20);
  });

  test('breakpoints match the Carbon source (width/columns/margin)', () {
    expect(_triple(CarbonBreakpoint.sm), (320.0, 4, 0.0));
    expect(_triple(CarbonBreakpoint.md), (672.0, 8, 16.0));
    expect(_triple(CarbonBreakpoint.lg), (1056.0, 16, 16.0));
    expect(_triple(CarbonBreakpoint.xlg), (1312.0, 16, 16.0));
    expect(_triple(CarbonBreakpoint.max), (1584.0, 16, 24.0));
    expect(CarbonBreakpoint.values, hasLength(5));
  });

  test('breakpoint resolution selects the largest matching breakpoint', () {
    expect(CarbonBreakpoint.of(0).name, 'sm');
    expect(CarbonBreakpoint.of(320).name, 'sm');
    expect(CarbonBreakpoint.of(671).name, 'sm');
    expect(CarbonBreakpoint.of(672).name, 'md');
    expect(CarbonBreakpoint.of(1056).name, 'lg');
    expect(CarbonBreakpoint.of(1312).name, 'xlg');
    expect(CarbonBreakpoint.of(2000).name, 'max');
  });
}

(double, int, double) _triple(CarbonBreakpoint b) =>
    (b.width, b.columns, b.margin);
