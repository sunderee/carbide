// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spike #29 fixtures. The renderer and comparator that started here were
// promoted to test/support/fidelity.dart for the production sweep; this file
// keeps the spike's data model and delegates rendering to them.

import 'dart:typed_data';

import 'package:carbide/carbide.dart';

import '../support/fidelity.dart';

export '../support/fidelity.dart' show FidelityResult, compareAlpha;

/// One extracted icon: shape data plus the sizes to verify at.
class SpikeIcon {
  const SpikeIcon({
    required this.name,
    required this.viewBox,
    required this.renderSizes,
    required this.shapes,
  });

  final String name;
  final double viewBox;
  final List<int> renderSizes;
  final List<SpikeShape> shapes;
}

/// One visible shape: an SVG path, its fill rule, and an optional 2D matrix.
class SpikeShape {
  const SpikeShape({required this.d, this.evenOdd = false, this.matrix});

  final String d;
  final bool evenOdd;

  /// SVG-style 2D affine matrix `[a, b, c, d, e, f]`, if not identity.
  final List<double>? matrix;
}

/// Renders [icon] at [size]×[size] and returns its alpha channel.
Future<Uint8List> renderIconAlpha(SpikeIcon icon, int size) {
  final CarbonIconArtwork artwork = CarbonIconArtwork(
    viewBoxWidth: icon.viewBox,
    viewBoxHeight: icon.viewBox,
    shapes: <CarbonIconShape>[
      for (final SpikeShape shape in icon.shapes)
        CarbonIconShape(
          d: shape.d,
          evenOdd: shape.evenOdd,
          matrix: shape.matrix,
        ),
    ],
  );
  return renderArtworkAlpha(artwork, size, size);
}

/// Decodes a square reference PNG and returns its alpha channel.
Future<Uint8List> decodeReferenceAlpha(Uint8List png, int size) =>
    decodePngAlpha(png, size, size);
