// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Icon fidelity harness (ADR 0001): renders icon artwork via dart:ui and
// compares it pixel-wise against committed rsvg-convert rasterizations of
// the upstream SVGs. Promoted from the #29 spike for the per-PR sweep.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';

/// Paints [artwork] at [width]×[height] through [CarbonIconPainter] — the
/// exact paint path the `CarbonIcon` widget uses, so the sweep verifies what
/// apps actually draw, never a parallel code path.
Future<ui.Image> _renderArtwork(
  CarbonIconArtwork artwork,
  int width,
  int height,
) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  CarbonIconPainter(
    artwork: artwork,
    color: const ui.Color(0xFF000000),
  ).paint(canvas, ui.Size(width.toDouble(), height.toDouble()));
  return recorder.endRecording().toImage(width, height);
}

/// Renders [artwork] at [width]×[height] and returns its alpha channel.
Future<Uint8List> renderArtworkAlpha(
  CarbonIconArtwork artwork,
  int width,
  int height,
) async {
  return alphaChannel(await _renderArtwork(artwork, width, height));
}

/// Renders [artwork] at [width]×[height] and returns PNG bytes, for failure
/// dumps.
Future<Uint8List> renderArtworkPng(
  CarbonIconArtwork artwork,
  int width,
  int height,
) async {
  final ui.Image image = await _renderArtwork(artwork, width, height);
  final ByteData data = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!;
  return data.buffer.asUint8List();
}

/// Decodes a reference PNG and returns its alpha channel, asserting its
/// dimensions are [width]×[height].
Future<Uint8List> decodePngAlpha(Uint8List png, int width, int height) async {
  final ui.Codec codec = await ui.instantiateImageCodec(png);
  final ui.Image image = (await codec.getNextFrame()).image;
  if (image.width != width || image.height != height) {
    throw StateError(
      'reference is ${image.width}x${image.height}, want ${width}x$height',
    );
  }
  return alphaChannel(image);
}

/// Extracts the alpha channel of [image] as one byte per pixel.
Future<Uint8List> alphaChannel(ui.Image image) async {
  final ByteData data = (await image.toByteData())!;
  final Uint8List rgba = data.buffer.asUint8List();
  final Uint8List alpha = Uint8List(rgba.length ~/ 4);
  for (int i = 0; i < alpha.length; i++) {
    alpha[i] = rgba[i * 4 + 3];
  }
  return alpha;
}

/// The result of comparing a render against its upstream reference.
class FidelityResult {
  const FidelityResult({
    required this.mismatchFraction,
    required this.coverageMismatchFraction,
    required this.meanAbsDiff,
  });

  /// Fraction of pixels whose raw alpha differs by more than the band.
  ///
  /// Sensitive to anti-aliasing differences between renderers along curved
  /// edges (Skia draws arcs as conics; rsvg approximates with béziers), so
  /// it overstates visual difference on arc-heavy icons.
  final double mismatchFraction;

  /// Fraction of pixels differing after a 3×3 box blur of both images.
  ///
  /// Blurring forgives sub-pixel edge-sampling differences while still
  /// catching real geometry errors: a shape displaced by a full pixel or a
  /// missing/extra shape survives the blur. This is the fidelity gate.
  final double coverageMismatchFraction;

  /// Mean absolute alpha difference, normalized to 0–1.
  final double meanAbsDiff;
}

Uint8List _boxBlur(Uint8List src, int width, int height) {
  final Uint8List out = Uint8List(src.length);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      int sum = 0, n = 0;
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final int nx = x + dx, ny = y + dy;
          if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
            sum += src[ny * width + nx];
            n++;
          }
        }
      }
      out[y * width + x] = sum ~/ n;
    }
  }
  return out;
}

/// Compares two alpha channels of a [width]×[height] image with a per-pixel
/// band of [band] (0–255).
FidelityResult compareAlphaRect(
  Uint8List ours,
  Uint8List reference,
  int width,
  int height, {
  int band = 32,
}) {
  assert(ours.length == reference.length);
  assert(ours.length == width * height);
  int mismatches = 0;
  int totalDiff = 0;
  for (int i = 0; i < ours.length; i++) {
    final int diff = (ours[i] - reference[i]).abs();
    totalDiff += diff;
    if (diff > band) {
      mismatches++;
    }
  }
  final Uint8List blurredOurs = _boxBlur(ours, width, height);
  final Uint8List blurredRef = _boxBlur(reference, width, height);
  int coverageMismatches = 0;
  for (int i = 0; i < blurredOurs.length; i++) {
    if ((blurredOurs[i] - blurredRef[i]).abs() > band) {
      coverageMismatches++;
    }
  }
  return FidelityResult(
    mismatchFraction: mismatches / ours.length,
    coverageMismatchFraction: coverageMismatches / ours.length,
    meanAbsDiff: totalDiff / ours.length / 255,
  );
}

/// Square-image convenience over [compareAlphaRect].
FidelityResult compareAlpha(
  Uint8List ours,
  Uint8List reference, {
  int band = 32,
}) {
  final int size = _isqrt(ours.length);
  return compareAlphaRect(ours, reference, size, size, band: band);
}

int _isqrt(int value) {
  final int root = math.sqrt(value).round();
  assert(root * root == value, 'images must be square');
  return root;
}
