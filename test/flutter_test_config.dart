// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Loaded automatically by `flutter_test` for every test in this package. It
// registers the bundled IBM Plex fonts (so text renders with real glyphs
// instead of the placeholder font) and installs the golden comparator for
// the platform: the VM comparator applies the Carbide tolerances
// (`golden_comparator_io.dart`); on the web there is nothing to compare
// against. Passing `--dart-define=CARBIDE_SKIP_GOLDENS=true` (the min-SDK CI
// job and the web smoke) replaces comparison with a loud pass-through, so a
// toolchain whose rasterization is not the baseline can still execute the
// behavioral suite.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator_io.dart'
    if (dart.library.js_interop) 'support/golden_comparator_web.dart';
import 'support/load_fonts.dart';

/// Set with `--dart-define=CARBIDE_SKIP_GOLDENS=true` to disable golden
/// comparison for the run.
const bool _skipGoldens = bool.fromEnvironment('CARBIDE_SKIP_GOLDENS');

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadCarbidePlexFonts();
  installCarbideGoldenComparator(skipGoldens: _skipGoldens);
  await testMain();
}
