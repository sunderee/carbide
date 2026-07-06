// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

/// Web half of the golden-comparator install (see `flutter_test_config.dart`
/// and `golden_comparator_io.dart` for the VM half).
///
/// Golden baselines are Linux-VM-authoritative; a browser run compares
/// nothing. The web smoke exists to execute behavior on the web engine
/// (`flutter test --platform chrome`), so it must always be invoked with
/// `--dart-define=CARBIDE_SKIP_GOLDENS=true`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs a pass-through comparator under [skipGoldens]; otherwise leaves
/// the framework default in place (and any golden test will fail loudly,
/// which is correct — web pixels are not baselines).
void installCarbideGoldenComparator({required bool skipGoldens}) {
  if (!skipGoldens) {
    return;
  }
  debugPrint(
    'carbide: golden comparisons SKIPPED (CARBIDE_SKIP_GOLDENS) — '
    'this run does not validate pixels.',
  );
  goldenFileComparator = _PassThroughGoldenComparator();
}

/// Accepts every comparison; used only under `CARBIDE_SKIP_GOLDENS`.
class _PassThroughGoldenComparator extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async => true;

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {}
}
