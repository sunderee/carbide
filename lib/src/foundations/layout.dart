// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Values are ported from the Apache-2.0 licensed Carbon Design System
// (@carbon/layout). See the NOTICE file for attribution.
//
// Carbon expresses these as rem (1rem = 16px base); they are given here in
// logical pixels. Viewport-relative spacing is generated in fluid_spacing.dart;
// the deprecated `layout01`–`layout07` tokens are intentionally omitted.

import 'package:flutter/foundation.dart' show immutable;

/// The Carbon spacing scale, in logical pixels.
///
/// A single scale used for margins, padding, and gaps, from [spacing01] (2)
/// to [spacing13] (160). Built on Carbon's 8px mini-unit.
abstract final class CarbonSpacing {
  /// 2px.
  static const double spacing01 = 2;

  /// 4px.
  static const double spacing02 = 4;

  /// 8px.
  static const double spacing03 = 8;

  /// 12px.
  static const double spacing04 = 12;

  /// 16px.
  static const double spacing05 = 16;

  /// 24px.
  static const double spacing06 = 24;

  /// 32px.
  static const double spacing07 = 32;

  /// 40px.
  static const double spacing08 = 40;

  /// 48px.
  static const double spacing09 = 48;

  /// 64px.
  static const double spacing10 = 64;

  /// 80px.
  static const double spacing11 = 80;

  /// 96px.
  static const double spacing12 = 96;

  /// 160px.
  static const double spacing13 = 160;

  /// The 13 steps in order, from [spacing01] to [spacing13].
  static const List<double> steps = <double>[
    spacing01,
    spacing02,
    spacing03,
    spacing04,
    spacing05,
    spacing06,
    spacing07,
    spacing08,
    spacing09,
    spacing10,
    spacing11,
    spacing12,
    spacing13,
  ];
}

/// Fixed element heights (`$size-*`), in logical pixels.
abstract final class CarbonSize {
  /// 24px.
  static const double xSmall = 24;

  /// 32px.
  static const double small = 32;

  /// 40px.
  static const double medium = 40;

  /// 48px.
  static const double large = 48;

  /// 64px.
  static const double xLarge = 64;

  /// 80px.
  static const double xxLarge = 80;
}

/// Container heights (`$container-*`), in logical pixels.
abstract final class CarbonContainer {
  /// 24px.
  static const double container01 = 24;

  /// 32px.
  static const double container02 = 32;

  /// 40px.
  static const double container03 = 40;

  /// 48px.
  static const double container04 = 48;

  /// 64px.
  static const double container05 = 64;
}

/// Icon sizes (`$icon-size-*`), in logical pixels.
abstract final class CarbonIconSize {
  /// 16px.
  static const double iconSize01 = 16;

  /// 20px.
  static const double iconSize02 = 20;
}

/// A Carbon responsive breakpoint: its minimum width, grid columns, and margin.
@immutable
class CarbonBreakpoint {
  /// Creates a breakpoint definition.
  const CarbonBreakpoint({
    required this.name,
    required this.width,
    required this.columns,
    required this.margin,
  });

  /// The breakpoint name (`sm`, `md`, `lg`, `xlg`, `max`).
  final String name;

  /// The minimum viewport width, in logical pixels, at which it applies.
  final double width;

  /// The number of grid columns at this breakpoint.
  final int columns;

  /// The grid margin, in logical pixels, at this breakpoint.
  final double margin;

  /// Small — from 320px, 4 columns.
  static const CarbonBreakpoint sm = CarbonBreakpoint(
    name: 'sm',
    width: 320,
    columns: 4,
    margin: 0,
  );

  /// Medium — from 672px, 8 columns.
  static const CarbonBreakpoint md = CarbonBreakpoint(
    name: 'md',
    width: 672,
    columns: 8,
    margin: 16,
  );

  /// Large — from 1056px, 16 columns.
  static const CarbonBreakpoint lg = CarbonBreakpoint(
    name: 'lg',
    width: 1056,
    columns: 16,
    margin: 16,
  );

  /// X-Large — from 1312px, 16 columns.
  static const CarbonBreakpoint xlg = CarbonBreakpoint(
    name: 'xlg',
    width: 1312,
    columns: 16,
    margin: 16,
  );

  /// Max — from 1584px, 16 columns.
  static const CarbonBreakpoint max = CarbonBreakpoint(
    name: 'max',
    width: 1584,
    columns: 16,
    margin: 24,
  );

  /// All breakpoints, ascending by [width].
  static const List<CarbonBreakpoint> values = <CarbonBreakpoint>[
    sm,
    md,
    lg,
    xlg,
    max,
  ];

  /// The active breakpoint for a viewport of [width] logical pixels.
  ///
  /// Returns the largest breakpoint whose minimum [width] the viewport meets
  /// (Carbon's "breakpoint up" behaviour); never smaller than [sm].
  static CarbonBreakpoint of(double width) {
    CarbonBreakpoint active = sm;
    for (final CarbonBreakpoint breakpoint in values) {
      if (width >= breakpoint.width) {
        active = breakpoint;
      }
    }
    return active;
  }
}
