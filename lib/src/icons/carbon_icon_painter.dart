// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:typed_data' show Float64List;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'carbon_icon_data.dart';
import 'svg_path_parser.dart';

/// Paints one [CarbonIconArtwork] variant in a single color.
///
/// This is the only icon paint path in Carbide: the `CarbonIcon` widget and
/// the fidelity sweep (which verifies every asset against upstream rasters,
/// see ADR 0001) both render through it, so what the tests verify is exactly
/// what apps draw.
///
/// Shapes are parsed once and cached: parsed [ui.Path]s (with their fill rule
/// and transform applied) are memoized per value-equal [CarbonIconShape].
/// Entries live for the Dart isolate's lifetime, shared by icons and pictograms,
/// with no eviction. Size and colour changes reuse the same parsed paths. See
/// [the measured cache policy](https://github.com/sunderee/carbide/blob/master/docs/ARCHITECTURE.md#icon-path-cache-policy).
/// The artwork is scaled uniformly to fit the paint size and centered, which
/// is a no-op for the square sized artwork and letterboxes the few
/// rectangular glyph assets.
/// **Advanced API.** A supported low-level building block. Prefer the family
/// widgets or generated artwork constants unless custom composition requires it.
/// Changes follow the published compatibility policy; advanced does not mean
/// breaking changes may be shipped silently in patch releases.
class CarbonIconPainter extends CustomPainter {
  /// Creates a painter for [artwork] filled with [color].
  const CarbonIconPainter({required this.artwork, required this.color});

  /// The artwork variant to paint.
  final CarbonIconArtwork artwork;

  /// The fill color for every shape.
  final Color color;

  static final Map<CarbonIconShape, ui.Path> _pathCache =
      <CarbonIconShape, ui.Path>{};

  static ui.Path _pathFor(CarbonIconShape shape) {
    return _pathCache.putIfAbsent(shape, () {
      ui.Path path = parseSvgPath(shape.d);
      final List<double>? m = shape.matrix;
      if (m != null) {
        path = path.transform(
          Float64List.fromList(<double>[
            m[0], m[1], 0, 0, //
            m[2], m[3], 0, 0, //
            0, 0, 1, 0, //
            m[4], m[5], 0, 1, //
          ]),
        );
      }
      path.fillType = shape.evenOdd
          ? ui.PathFillType.evenOdd
          : ui.PathFillType.nonZero;
      return path;
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = _min(
      size.width / artwork.viewBoxWidth,
      size.height / artwork.viewBoxHeight,
    );
    final double dx = (size.width - artwork.viewBoxWidth * scale) / 2;
    final double dy = (size.height - artwork.viewBoxHeight * scale) / 2;
    final Paint fill = Paint()..color = color;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);
    for (final CarbonIconShape shape in artwork.shapes) {
      canvas.drawPath(_pathFor(shape), fill);
    }
    canvas.restore();
  }

  static double _min(double a, double b) => a < b ? a : b;

  @override
  bool shouldRepaint(CarbonIconPainter oldDelegate) =>
      artwork != oldDelegate.artwork || color != oldDelegate.color;
}
