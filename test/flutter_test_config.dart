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
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import 'support/golden_comparator_io.dart'
    if (dart.library.js_interop) 'support/golden_comparator_web.dart';
import 'support/load_fonts.dart';

/// Set with `--dart-define=CARBIDE_SKIP_GOLDENS=true` to disable golden
/// comparison for the run.
const bool _skipGoldens = bool.fromEnvironment('CARBIDE_SKIP_GOLDENS');

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Leak tracking (#234): every `testWidgets` case doubles as a leak
  // test — a forgotten dispose() or an overlay entry that outlives its
  // trigger fails the test that pumped it. Objects the harness itself
  // allocates (fonts, decoded golden images) are ignored; anything else
  // is fixed in lib/ or allowlisted per-test with a justification.
  LeakTesting.enable();
  LeakTesting.settings = LeakTesting.settings.withIgnored(
    createdByTestHelpers: true,
    // Golden capture/decoding allocates ui.Images inside the framework's
    // matchesGoldenFile flow and reports them against the pumping test.
    // Nothing in lib/ allocates a ui.Image (icons and pictograms are
    // vector CustomPaints), so ignoring the class hides no product leak.
    classes: <String>['Image'],
  );
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadCarbidePlexFonts();
  installCarbideGoldenComparator(skipGoldens: _skipGoldens);
  await testMain();
}
