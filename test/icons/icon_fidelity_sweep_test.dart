// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// The full fidelity sweep (ADR 0001): every artwork variant of every Carbon
// icon is rendered through the production parser/painter pipeline and
// compared against the committed rsvg-convert rasterization of the upstream
// SVG at 2x scale. Gate: blurred-coverage mismatch ≤ 0.5%. On failure, our
// render is dumped to test/icons/failures/ next to the reference path for
// inspection; see CONTRIBUTING for the regeneration workflow.

import 'dart:io';
import 'dart:typed_data';

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';

import '../support/fidelity.dart';
import 'all_icons.dart';

const double maxCoverageMismatch = 0.005;
const int scale = 2;
const String referenceDir = 'test/icons/references';
const String failureDir = 'test/icons/failures';

(int, int) dimensionsOf(CarbonIconArtwork artwork) {
  final int? size = artwork.size;
  if (size != null) {
    return (size * scale, size * scale);
  }
  return (
    (artwork.viewBoxWidth * scale).round(),
    (artwork.viewBoxHeight * scale).round(),
  );
}

String referenceNameOf(CarbonIconData icon, CarbonIconArtwork artwork) =>
    '${icon.name}_${artwork.size?.toString() ?? 'glyph'}.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every icon asset matches its upstream raster',
    () async {
      final Stopwatch watch = Stopwatch()..start();
      final List<String> failures = <String>[];
      int assets = 0;
      double worst = 0;
      String worstName = '';

      for (final CarbonIconData icon in allCarbonIcons) {
        for (final CarbonIconArtwork artwork in icon.artwork) {
          assets++;
          final (int width, int height) = dimensionsOf(artwork);
          final String referenceName = referenceNameOf(icon, artwork);
          final Uint8List png = File(
            '$referenceDir/$referenceName',
          ).readAsBytesSync();
          final Uint8List ours = await renderArtworkAlpha(
            artwork,
            width,
            height,
          );
          final Uint8List reference = await decodePngAlpha(png, width, height);
          final FidelityResult result = compareAlphaRect(
            ours,
            reference,
            width,
            height,
          );
          if (result.coverageMismatchFraction > worst) {
            worst = result.coverageMismatchFraction;
            worstName = referenceName;
          }
          if (result.coverageMismatchFraction > maxCoverageMismatch) {
            failures.add(
              '$referenceName: coverage '
              '${(result.coverageMismatchFraction * 100).toStringAsFixed(3)}% '
              '(raw ${(result.mismatchFraction * 100).toStringAsFixed(3)}%)',
            );
            Directory(failureDir).createSync(recursive: true);
            File(
              '$failureDir/$referenceName',
            ).writeAsBytesSync(await renderArtworkPng(artwork, width, height));
          }
        }
      }
      watch.stop();
      debugPrint(
        'fidelity sweep: $assets assets in ${watch.elapsed.inSeconds}s; '
        'worst coverage mismatch '
        '${(worst * 100).toStringAsFixed(3)}% ($worstName)',
      );
      expect(
        failures,
        isEmpty,
        reason:
            'icons differ from upstream rasters; our renders were written to '
            '$failureDir for comparison against $referenceDir',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  test(
    'the gate catches a one-pixel geometry error (mutation guard)',
    () async {
      // Displace the add icon by 1.5px via a shape matrix; the sweep gate must
      // reject it, proving the comparator detects real geometry errors and not
      // only gross corruption.
      final CarbonIconArtwork original = CarbonIcons.add.artwork.single;
      final CarbonIconArtwork displaced = CarbonIconArtwork(
        size: original.size,
        viewBoxWidth: original.viewBoxWidth,
        viewBoxHeight: original.viewBoxHeight,
        shapes: <CarbonIconShape>[
          for (final CarbonIconShape shape in original.shapes)
            CarbonIconShape(
              d: shape.d,
              evenOdd: shape.evenOdd,
              matrix: const <double>[1, 0, 0, 1, 1.5, 0],
            ),
        ],
      );
      final (int width, int height) = dimensionsOf(displaced);
      final Uint8List png = File(
        '$referenceDir/${CarbonIcons.add.name}_32.png',
      ).readAsBytesSync();
      final Uint8List ours = await renderArtworkAlpha(displaced, width, height);
      final Uint8List reference = await decodePngAlpha(png, width, height);
      final FidelityResult result = compareAlphaRect(
        ours,
        reference,
        width,
        height,
      );
      expect(result.coverageMismatchFraction, greaterThan(maxCoverageMismatch));
    },
  );
}
