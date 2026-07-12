// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spike #29: renders the representative icon sample via dart:ui and compares
// each render pixel-wise against rsvg-convert rasterizations of the upstream
// SVGs. The printed table feeds docs/adr/0001-icon-rendering.md.

import 'dart:io';
import 'dart:typed_data';

import 'package:carbide/src/icons/svg_path_parser.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import 'spike_icon_data.dart';
import 'support.dart';

/// Gate for the blurred-coverage metric: forgives cross-renderer
/// anti-aliasing on curve edges (Skia conics vs rsvg béziers) but catches
/// real geometry errors (a shape displaced ≥1px survives the blur). The raw
/// per-pixel mismatch is reported for the ADR but not gated. Value chosen
/// from measured results with margin; see the ADR table.
const double maxCoverageMismatch = 0.005;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> report = <String>[];

  test('every spike icon matches its upstream raster', () async {
    final List<String> failures = <String>[];
    for (final SpikeIcon icon in spikeIcons) {
      for (final int size in icon.renderSizes) {
        final Uint8List ours = await renderIconAlpha(icon, size);
        final Uint8List png = File(
          'test/spike/references/${icon.name}_$size.png',
        ).readAsBytesSync();
        final Uint8List reference = await decodeReferenceAlpha(png, size);
        final FidelityResult result = compareAlpha(ours, reference);
        report.add(
          '${icon.name.padRight(20)} ${'$size'.padLeft(3)}px  '
          'raw ${(result.mismatchFraction * 100).toStringAsFixed(3)}%  '
          'coverage ${(result.coverageMismatchFraction * 100).toStringAsFixed(3)}%  '
          'meanAbsDiff ${(result.meanAbsDiff * 100).toStringAsFixed(3)}%',
        );
        if (result.coverageMismatchFraction > maxCoverageMismatch) {
          failures.add(report.last);
        }
      }
    }
    // The measured-results table for the ADR.
    debugPrint('--- spike fidelity results ---');
    report.forEach(debugPrint);
    expect(failures, isEmpty);
  });

  test('runtime path parsing is cheap enough to skip pre-parsing', () {
    final Stopwatch watch = Stopwatch()..start();
    const int rounds = 100;
    for (int i = 0; i < rounds; i++) {
      for (final SpikeIcon icon in spikeIcons) {
        for (final SpikeShape shape in icon.shapes) {
          parseSvgPath(shape.d);
        }
      }
    }
    watch.stop();
    final double microsPerIcon =
        watch.elapsedMicroseconds / (rounds * spikeIcons.length);
    debugPrint(
      '--- parse cost: ${microsPerIcon.toStringAsFixed(1)}µs per icon ---',
    );
    // An icon parsing in well under a millisecond means a runtime parser
    // (cached) beats shipping pre-parsed command lists, which roughly double
    // generated code size. Recorded in the ADR.
    expect(microsPerIcon, lessThan(1000));
  });
}
