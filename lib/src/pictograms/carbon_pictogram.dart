// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import '../icons/carbon_icon_data.dart';
import '../icons/carbon_icon_painter.dart';
import '../theme/carbon_theme.dart';

/// Renders a Carbon pictogram.
///
/// ```dart
/// const CarbonPictogram(CarbonPictograms.solarPanel);
/// const CarbonPictogram(CarbonPictograms.cloud, size: 96);
/// ```
///
/// Pictograms are Carbon's larger expressive illustrations. They share the
/// icon data model and paint path ([CarbonIconData], `CarbonIconPainter`),
/// but their display contract differs, which is why this is a separate
/// widget rather than `CarbonIcon`: per Carbon guidance pictograms render at
/// **48 logical pixels minimum** (asserted), defaulting to 48, and each has
/// exactly one 32-grid artwork — there is no per-size variant selection.
/// Below ~32px the thin strokes alias badly (measured in ADR 0001).
///
/// The color defaults to the theme's `iconPrimary` token. Pictograms are
/// decorative by default; pass [semanticLabel] to expose a labeled image.
class CarbonPictogram extends StatelessWidget {
  /// Creates a pictogram from [pictogram] data (a `CarbonPictograms`
  /// constant).
  const CarbonPictogram(
    this.pictogram, {
    super.key,
    this.size = minSize,
    this.color,
    this.semanticLabel,
  }) : assert(
         size >= minSize,
         'Carbon guidance: pictograms render at $minSize px minimum',
       );

  /// The minimum (and default) pictogram size per Carbon guidance.
  static const double minSize = 48;

  /// The pictogram to render.
  final CarbonIconData pictogram;

  /// The rendered edge length in logical pixels (≥ [minSize]).
  final double size;

  /// Overrides the color; defaults to the theme's `iconPrimary`.
  final Color? color;

  /// Exposes the pictogram to assistive technology with this label. When
  /// null, it is decorative and excluded from the semantics tree.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget painted = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: CarbonIconPainter(
          artwork: pictogram.artworkFor(size),
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
