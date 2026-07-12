// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// VM half of the golden-comparator install (see `flutter_test_config.dart`).
///
/// The web half is `golden_comparator_web.dart`; the two are selected by a
/// conditional import because `LocalFileComparator` and `dart:io` do not
/// exist on the web platform.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs the Carbide golden comparator (or a pass-through when
/// [skipGoldens], for toolchains where baselines are not authoritative —
/// the min-SDK CI job and the web smoke).
void installCarbideGoldenComparator({required bool skipGoldens}) {
  if (skipGoldens) {
    debugPrint(
      'carbide: golden comparisons SKIPPED (CARBIDE_SKIP_GOLDENS) — '
      'this run does not validate pixels.',
    );
    goldenFileComparator = _PassThroughGoldenComparator();
    return;
  }
  final GoldenFileComparator comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = _CarbideGoldenComparator(comparator.basedir);
  }
}

/// A [LocalFileComparator] that accepts a tiny fraction of differing pixels.
///
/// Golden baselines are compared across platforms. Vector geometry renders
/// bit-identically everywhere (validated empirically by the icon spike), but
/// **glyph rasterization does not**: macOS (CoreText) and Linux (FreeType)
/// produce ~8–9% differing pixels on the same text. So:
///
/// - Goldens whose name contains `.text.` are generated **on Linux** (CI is
///   authoritative; use the “Regenerate goldens” workflow) and compared
///   strictly there; on other platforms they get a lenient bound that still
///   catches gross errors (missing text, wrong layout) without false
///   failures from rasterizer differences. When that loose path saves a
///   comparison, a loud notice is printed — an off-Linux local pass of a
///   text golden is NOT authoritative (#236).
/// - Goldens whose name contains `.strict.` allow only 0.05% differing
///   pixels (#236): the default 0.5% is ~5px on a 32×32 tile — a whole
///   checkmark row — so small-surface and hairline canaries opt into the
///   tight bound via `expectThemeGoldens(strict: true)`.
/// - All other goldens use the small default tolerance everywhere.
class _CarbideGoldenComparator extends LocalFileComparator {
  _CarbideGoldenComparator(Uri baseDir)
    : super(Uri.parse('$baseDir$_dummyTestFile'));

  // LocalFileComparator derives its base directory from the directory of the
  // file it is given; the file itself never needs to exist.
  static const String _dummyTestFile = 'carbide_goldens.dart';

  // Fractions (0..1) of pixels allowed to differ. `diffPercent` is reported
  // as a fraction by the framework, so 0.005 is 0.5%.
  static const double _maxDiffFraction = 0.005;
  static const double _maxStrictDiffFraction = 0.0005;
  static const double _maxTextDiffFractionOffCi = 0.15;

  static double _toleranceFor(Uri golden) {
    if (golden.path.contains('.text.') && !Platform.isLinux) {
      return _maxTextDiffFractionOffCi;
    }
    if (golden.path.contains('.strict.')) {
      return _maxStrictDiffFraction;
    }
    return _maxDiffFraction;
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed) {
      return true;
    }
    if (result.diffPercent <= _toleranceFor(golden)) {
      if (golden.path.contains('.text.') && !Platform.isLinux) {
        debugPrint(
          'carbide: LOOSE text-golden tolerance applied to '
          '${golden.pathSegments.last} '
          '(${(result.diffPercent * 100).toStringAsFixed(2)}% differing '
          'pixels; limit 15%). This platform is not authoritative for text '
          'goldens — only the Linux CI comparison validates them.',
        );
      }
      return true;
    }
    final String error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

/// Accepts every comparison; used only under `CARBIDE_SKIP_GOLDENS`.
class _PassThroughGoldenComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}
