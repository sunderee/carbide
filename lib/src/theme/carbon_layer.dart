// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// The layer model and its token mappings are ported from the Apache-2.0
// licensed Carbon Design System (@carbon/react Layer and the layer-sets in
// @carbon/styles). See the NOTICE file for attribution.

import 'package:flutter/widgets.dart';

import 'carbon_theme.dart';
import 'carbon_theme_data.dart';

/// Carbon's contextual layering model.
///
/// Carbon defines three layers. Content at the root of an app sits on layer
/// one; wrapping a subtree in a [CarbonLayer] moves it one layer up (capped at
/// layer three), which re-points the contextual tokens — `layer`, `field`,
/// `borderSubtle`, and friends — to the next step so nested surfaces stay
/// distinguishable from their background.
///
/// Components read the active set with [CarbonLayer.of]:
///
/// ```dart
/// final CarbonLayerTokens tokens = CarbonLayer.of(context);
/// return ColoredBox(color: tokens.layer, child: ...);
/// ```
class CarbonLayer extends StatelessWidget {
  /// Moves [child] one layer up, or to an explicit [level].
  const CarbonLayer({
    super.key,
    this.level,
    this.withBackground = false,
    required this.child,
  }) : assert(
         level == null || (level >= minLevel && level <= maxLevel),
         'level must be between $minLevel and $maxLevel',
       );

  /// The lowest layer level (the implicit level of root content).
  static const int minLevel = 0;

  /// The highest layer level; nesting beyond it stays at this level.
  static const int maxLevel = 2;

  /// Overrides the level for this subtree instead of incrementing the
  /// ancestor's. Must be between [minLevel] and [maxLevel].
  final int? level;

  /// Whether to paint the layer's `layerBackground` token behind [child],
  /// mirroring the upstream `withBackground` behaviour.
  final bool withBackground;

  /// The subtree that lives on the new layer.
  final Widget child;

  /// The layer level active at [context], without resolving tokens.
  ///
  /// Returns [minLevel] when there is no [CarbonLayer] ancestor — root content
  /// sits on the first layer.
  static int levelOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CarbonLayerScope>()?.level ??
      minLevel;

  /// The contextual layer tokens active at [context].
  ///
  /// Resolves the ambient level against the ambient [CarbonTheme]; requires
  /// both in scope (the theme assert fires otherwise).
  static CarbonLayerTokens of(BuildContext context) =>
      CarbonLayerTokens.resolve(CarbonTheme.of(context), levelOf(context));

  @override
  Widget build(BuildContext context) {
    final int contentLevel = _clamp(level ?? (levelOf(context) + 1));
    Widget content = child;
    if (withBackground) {
      final CarbonLayerTokens tokens = CarbonLayerTokens.resolve(
        CarbonTheme.of(context),
        contentLevel,
      );
      content = ColoredBox(color: tokens.layerBackground, child: content);
    }
    return _CarbonLayerScope(level: contentLevel, child: content);
  }

  static int _clamp(int value) =>
      value < minLevel ? minLevel : (value > maxLevel ? maxLevel : value);
}

class _CarbonLayerScope extends InheritedWidget {
  const _CarbonLayerScope({required this.level, required super.child});

  final int level;

  @override
  bool updateShouldNotify(_CarbonLayerScope oldWidget) =>
      level != oldWidget.level;
}

/// The contextual tokens for one layer level of a theme.
///
/// Mirrors Carbon's layer sets: each contextual token re-points to the
/// concrete theme token for the active [level]. Note `borderSubtle` is
/// offset by design — layer one uses `borderSubtle00`, so `borderSubtle03`
/// is only reachable through explicit theme usage, exactly as upstream.
@immutable
class CarbonLayerTokens {
  const CarbonLayerTokens._({
    required this.level,
    required this.layer,
    required this.layerActive,
    required this.layerBackground,
    required this.layerHover,
    required this.layerSelected,
    required this.layerSelectedHover,
    required this.layerAccent,
    required this.layerAccentHover,
    required this.layerAccentActive,
    required this.field,
    required this.fieldHover,
    required this.borderSubtle,
    required this.borderSubtleSelected,
    required this.borderStrong,
    required this.borderTile,
  });

  /// Resolves the layer set for [level] (0-based) of [theme].
  ///
  /// Throws a [RangeError] if [level] is outside
  /// [CarbonLayer.minLevel]–[CarbonLayer.maxLevel].
  factory CarbonLayerTokens.resolve(CarbonThemeData theme, int level) {
    return switch (level) {
      0 => CarbonLayerTokens._(
        level: 0,
        layer: theme.layer01,
        layerActive: theme.layerActive01,
        layerBackground: theme.layerBackground01,
        layerHover: theme.layerHover01,
        layerSelected: theme.layerSelected01,
        layerSelectedHover: theme.layerSelectedHover01,
        layerAccent: theme.layerAccent01,
        layerAccentHover: theme.layerAccentHover01,
        layerAccentActive: theme.layerAccentActive01,
        field: theme.field01,
        fieldHover: theme.fieldHover01,
        borderSubtle: theme.borderSubtle00,
        borderSubtleSelected: theme.borderSubtleSelected01,
        borderStrong: theme.borderStrong01,
        borderTile: theme.borderTile01,
      ),
      1 => CarbonLayerTokens._(
        level: 1,
        layer: theme.layer02,
        layerActive: theme.layerActive02,
        layerBackground: theme.layerBackground02,
        layerHover: theme.layerHover02,
        layerSelected: theme.layerSelected02,
        layerSelectedHover: theme.layerSelectedHover02,
        layerAccent: theme.layerAccent02,
        layerAccentHover: theme.layerAccentHover02,
        layerAccentActive: theme.layerAccentActive02,
        field: theme.field02,
        fieldHover: theme.fieldHover02,
        borderSubtle: theme.borderSubtle01,
        borderSubtleSelected: theme.borderSubtleSelected02,
        borderStrong: theme.borderStrong02,
        borderTile: theme.borderTile02,
      ),
      2 => CarbonLayerTokens._(
        level: 2,
        layer: theme.layer03,
        layerActive: theme.layerActive03,
        layerBackground: theme.layerBackground03,
        layerHover: theme.layerHover03,
        layerSelected: theme.layerSelected03,
        layerSelectedHover: theme.layerSelectedHover03,
        layerAccent: theme.layerAccent03,
        layerAccentHover: theme.layerAccentHover03,
        layerAccentActive: theme.layerAccentActive03,
        field: theme.field03,
        fieldHover: theme.fieldHover03,
        borderSubtle: theme.borderSubtle02,
        borderSubtleSelected: theme.borderSubtleSelected03,
        borderStrong: theme.borderStrong03,
        borderTile: theme.borderTile03,
      ),
      _ => throw RangeError.range(
        level,
        CarbonLayer.minLevel,
        CarbonLayer.maxLevel,
        'level',
      ),
    };
  }

  /// The 0-based layer level these tokens were resolved for.
  final int level;

  /// The contextual `layer` token.
  final Color layer;

  /// The contextual `layer-active` token.
  final Color layerActive;

  /// The contextual `layer-background` token.
  final Color layerBackground;

  /// The contextual `layer-hover` token.
  final Color layerHover;

  /// The contextual `layer-selected` token.
  final Color layerSelected;

  /// The contextual `layer-selected-hover` token.
  final Color layerSelectedHover;

  /// The contextual `layer-accent` token.
  final Color layerAccent;

  /// The contextual `layer-accent-hover` token.
  final Color layerAccentHover;

  /// The contextual `layer-accent-active` token.
  final Color layerAccentActive;

  /// The contextual `field` token.
  final Color field;

  /// The contextual `field-hover` token.
  final Color fieldHover;

  /// The contextual `border-subtle` token (offset: layer one resolves to
  /// `borderSubtle00`).
  final Color borderSubtle;

  /// The contextual `border-subtle-selected` token.
  final Color borderSubtleSelected;

  /// The contextual `border-strong` token.
  final Color borderStrong;

  /// The contextual `border-tile` token.
  final Color borderTile;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CarbonLayerTokens &&
        other.level == level &&
        other.layer == layer &&
        other.layerActive == layerActive &&
        other.layerBackground == layerBackground &&
        other.layerHover == layerHover &&
        other.layerSelected == layerSelected &&
        other.layerSelectedHover == layerSelectedHover &&
        other.layerAccent == layerAccent &&
        other.layerAccentHover == layerAccentHover &&
        other.layerAccentActive == layerAccentActive &&
        other.field == field &&
        other.fieldHover == fieldHover &&
        other.borderSubtle == borderSubtle &&
        other.borderSubtleSelected == borderSubtleSelected &&
        other.borderStrong == borderStrong &&
        other.borderTile == borderTile;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    level,
    layer,
    layerActive,
    layerBackground,
    layerHover,
    layerSelected,
    layerSelectedHover,
    layerAccent,
    layerAccentHover,
    layerAccentActive,
    field,
    fieldHover,
    borderSubtle,
    borderSubtleSelected,
    borderStrong,
    borderTile,
  ]);
}
