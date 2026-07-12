// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import '../theme/carbon_theme.dart';
import 'carbon_icon_data.dart';
import 'carbon_icon_painter.dart';

/// Renders a Carbon icon.
///
/// ```dart
/// const CarbonIcon(CarbonIcons.add);
/// const CarbonIcon(CarbonIcons.search, size: 20);
/// CarbonIcon(CarbonIcons.warning, color: CarbonTheme.of(context).supportWarning);
/// ```
///
/// Sizing follows Carbon: the default is 16 logical pixels (the productive
/// icon size), and the artwork variant is chosen per
/// [CarbonIconData.artworkFor] — hand-tuned artwork at an exact size match,
/// the 32px master scaled otherwise.
///
/// The color defaults to the active theme's `iconPrimary` token. Icon color
/// is a theme-level token in Carbon — it deliberately does not vary with
/// [CarbonLayer] context.
///
/// Mirroring upstream accessibility semantics, an icon is **decorative by
/// default** (hidden from assistive technology, like `aria-hidden`); pass
/// [semanticLabel] to expose it as a labeled image instead.
class CarbonIcon extends StatelessWidget {
  /// Creates an icon from [icon] data (typically a `CarbonIcons` constant).
  const CarbonIcon(
    this.icon, {
    super.key,
    this.size = 16,
    this.color,
    this.semanticLabel,
  }) : assert(size > 0, 'size must be positive');

  /// The icon to render.
  final CarbonIconData icon;

  /// The rendered edge length in logical pixels; defaults to Carbon's
  /// productive size of 16.
  final double size;

  /// Overrides the icon color; defaults to the theme's `iconPrimary`.
  final Color? color;

  /// Exposes the icon to assistive technology with this label. When null,
  /// the icon is decorative and excluded from the semantics tree.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget painted = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: CarbonIconPainter(
          artwork: icon.artworkFor(size),
          color: color ?? CarbonTheme.of(context).iconPrimary,
        ),
      ),
    );
    final String? label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: painted);
    }
    return Semantics(label: label, image: true, child: painted);
  }
}
