// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/foundation.dart' show immutable, listEquals;

/// The drawable definition of one Carbon icon.
///
/// Carbon authors icons at 32×32 and hand-tunes some at smaller sizes, so an
/// icon carries one or more [artwork] variants. Pick the variant whose
/// [CarbonIconArtwork.size] matches the rendered size when one exists and
/// fall back to the 32px master otherwise (the icon widget does this
/// automatically).
///
/// Instances are generated from the Carbon sources into `CarbonIcons`;
/// constructing custom instances is supported for icons outside Carbon.
@immutable
class CarbonIconData {
  /// Creates an icon definition from its artwork variants.
  ///
  /// [artwork] must not be empty. (Not asserted: list lengths cannot be read
  /// in constant expressions, and icon data is constructed const.)
  const CarbonIconData({required this.name, required this.artwork});

  /// The upstream Carbon icon name (kebab-case, e.g. `arrow--down`).
  final String name;

  /// The artwork variants, ascending by [CarbonIconArtwork.size] with
  /// bespoke "glyph" artwork (no nominal size) first.
  final List<CarbonIconArtwork> artwork;

  /// The artwork variant best suited to render at [size] logical pixels.
  ///
  /// Selection mirrors upstream behaviour: an exact size match wins (Carbon
  /// hand-tunes some icons at 16/20/24); otherwise the smallest artwork
  /// larger than [size] is scaled down (typically the 32px master);
  /// otherwise the largest sized artwork is scaled up. Bespoke glyph
  /// artwork is only used when an icon has no sized artwork at all (the
  /// glyph-only status indicators such as `circle-fill`).
  CarbonIconArtwork artworkFor(double size) {
    CarbonIconArtwork? larger;
    CarbonIconArtwork? largest;
    for (final CarbonIconArtwork variant in artwork) {
      final int? nominal = variant.size;
      if (nominal == null) {
        continue;
      }
      if (nominal == size) {
        return variant;
      }
      if (nominal > size && (larger == null || nominal < larger.size!)) {
        larger = variant;
      }
      if (largest == null || nominal > largest.size!) {
        largest = variant;
      }
    }
    return larger ?? largest ?? artwork.first;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CarbonIconData &&
        other.name == name &&
        listEquals(other.artwork, artwork);
  }

  @override
  int get hashCode => Object.hash(name, Object.hashAll(artwork));
}

/// One size variant of an icon's artwork.
@immutable
class CarbonIconArtwork {
  /// Creates an artwork variant.
  const CarbonIconArtwork({
    this.size,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.shapes,
  });

  /// The nominal pixel size this artwork was drawn for (16, 20, 24, or 32),
  /// or null for a bespoke "glyph" asset with no nominal size.
  final int? size;

  /// The viewBox width the [shapes] are expressed in.
  final double viewBoxWidth;

  /// The viewBox height. Equal to [viewBoxWidth] for all sized artwork;
  /// bespoke glyph assets can be rectangular (the caret glyphs are 8×4).
  final double viewBoxHeight;

  /// The visible shapes, in paint order.
  final List<CarbonIconShape> shapes;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CarbonIconArtwork &&
        other.size == size &&
        other.viewBoxWidth == viewBoxWidth &&
        other.viewBoxHeight == viewBoxHeight &&
        listEquals(other.shapes, shapes);
  }

  @override
  int get hashCode =>
      Object.hash(size, viewBoxWidth, viewBoxHeight, Object.hashAll(shapes));
}

/// One filled shape of an icon: SVG path data plus its fill rule and an
/// optional 2D affine transform.
@immutable
class CarbonIconShape {
  /// Creates a shape from SVG path data.
  const CarbonIconShape({required this.d, this.evenOdd = false, this.matrix});

  /// The SVG path data (the `d` attribute grammar).
  final String d;

  /// Whether the shape fills with the even-odd rule instead of non-zero.
  final bool evenOdd;

  /// An SVG-style 2D affine matrix `[a, b, c, d, e, f]` applied to the
  /// shape, or null for identity.
  final List<double>? matrix;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CarbonIconShape &&
        other.d == d &&
        other.evenOdd == evenOdd &&
        listEquals(other.matrix, matrix);
  }

  @override
  int get hashCode =>
      Object.hash(d, evenOdd, matrix == null ? null : Object.hashAll(matrix!));
}
