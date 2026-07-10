// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled IBM Plex font assets, grouped by family.
///
/// Mirrors the `fonts:` declaration in `pubspec.yaml`. Kept here so tests and
/// the golden harness register exactly the fonts the package ships.
const Map<String, List<String>> carbidePlexFontAssets = <String, List<String>>{
  CarbonFontFamily.sans: <String>[
    'fonts/IBMPlexSans-Light.ttf',
    'fonts/IBMPlexSans-Regular.ttf',
    'fonts/IBMPlexSans-SemiBold.ttf',
  ],
  CarbonFontFamily.mono: <String>[
    'fonts/IBMPlexMono-Regular.ttf',
    'fonts/IBMPlexMono-SemiBold.ttf',
  ],
  CarbonFontFamily.serif: <String>[
    'fonts/IBMPlexSerif-Light.ttf',
    'fonts/IBMPlexSerif-Regular.ttf',
  ],
};

/// Loads the bundled IBM Plex fonts into the test font registry.
///
/// Widget tests render with a placeholder font unless real fonts are loaded.
/// Call this (typically in `setUpAll`) before any golden or layout assertion
/// that depends on Plex metrics. Requires an initialized test binding, which
/// `testWidgets` and `flutter_test`'s default `main` provide.
///
/// On the web test platform this is a no-op: under `flutter test
/// --platform chrome` the `rootBundle.load` future for a font asset never
/// completes, so awaiting it wedges every suite in the "loading" phase
/// (#271 — bisected there; the empty-config run passes, the fonts-only
/// config hangs). Web runs are behavioral-only (goldens are skipped and
/// Linux-VM-authoritative), so placeholder glyphs are acceptable.
Future<void> loadCarbidePlexFonts() async {
  if (kIsWeb) {
    debugPrint(
      'carbide: Plex font loading SKIPPED on the web test platform (#271) — '
      'text renders with placeholder glyphs.',
    );
    return;
  }
  for (final MapEntry<String, List<String>> family
      in carbidePlexFontAssets.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String asset in family.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
