// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/foundation.dart' show immutable, mapEquals;
import 'package:flutter/painting.dart' show TextStyle;

import 'layout.dart';

/// A Carbon fluid (responsive) type style.
///
/// Fluid styles change with the viewport: a [base] style applies from the
/// smallest breakpoint, and per-breakpoint [overrides] adjust it at wider
/// viewports. Overrides **cascade** like Carbon's CSS — a property set at one
/// breakpoint persists at wider ones until another breakpoint overrides it —
/// so each override only needs to specify the properties that change.
///
/// Styles of the same runtime type compare by their base and override values,
/// independent of the override map's insertion order.
@immutable
class CarbonFluidTextStyle {
  /// Creates a fluid type style from a [base] and breakpoint [overrides].
  const CarbonFluidTextStyle({
    required this.base,
    this.overrides = const <String, TextStyle>{},
  });

  /// The style at the smallest breakpoint, before any override applies.
  final TextStyle base;

  /// Partial style overrides keyed by breakpoint name (`md`, `lg`, `xlg`,
  /// `max`). Each contains only the properties that change at that breakpoint.
  ///
  /// Treat this map as immutable after construction. Mutating it while the
  /// style is a map or set key invalidates value-based collection lookup.
  final Map<String, TextStyle> overrides;

  /// Creates a variant with a different base or override map.
  ///
  /// Omitted or `null` arguments retain their current values. Supplying
  /// [overrides] replaces the entire map; an empty map removes every
  /// breakpoint override. For example, a color can be applied to the base
  /// without reconstructing the breakpoint cascade:
  ///
  /// ```dart
  /// final variant = style.copyWith(base: style.base.copyWith(color: color));
  /// ```
  CarbonFluidTextStyle copyWith({
    TextStyle? base,
    Map<String, TextStyle>? overrides,
  }) => CarbonFluidTextStyle(
    base: base ?? this.base,
    overrides: overrides ?? this.overrides,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CarbonFluidTextStyle &&
          other.runtimeType == runtimeType &&
          other.base == base &&
          mapEquals(other.overrides, overrides);

  @override
  int get hashCode => Object.hash(
    runtimeType,
    base,
    Object.hashAllUnordered(
      overrides.entries.map(
        (MapEntry<String, TextStyle> entry) =>
            Object.hash(entry.key, entry.value),
      ),
    ),
  );

  /// The effective [TextStyle] for a viewport of [width] logical pixels.
  ///
  /// Cascades [base] through every breakpoint override whose minimum width the
  /// viewport meets, in ascending order.
  TextStyle resolve(double width) {
    TextStyle style = base;
    for (final CarbonBreakpoint breakpoint in CarbonBreakpoint.values) {
      final TextStyle? override = overrides[breakpoint.name];
      if (override != null && width >= breakpoint.width) {
        style = style.merge(override);
      }
    }
    return style;
  }
}
