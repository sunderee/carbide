// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// Loads the bundled IBM Plex fonts (shipped by the `carbide` package) so
// gallery widget tests render with real glyphs instead of the placeholder
// font.

import 'dart:async';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, List<String>> _fonts = <String, List<String>>{
  CarbonFontFamily.sans: <String>[
    'packages/carbide/fonts/IBMPlexSans-Light.ttf',
    'packages/carbide/fonts/IBMPlexSans-Regular.ttf',
    'packages/carbide/fonts/IBMPlexSans-SemiBold.ttf',
  ],
  CarbonFontFamily.mono: <String>[
    'packages/carbide/fonts/IBMPlexMono-Regular.ttf',
    'packages/carbide/fonts/IBMPlexMono-SemiBold.ttf',
  ],
  CarbonFontFamily.serif: <String>[
    'packages/carbide/fonts/IBMPlexSerif-Light.ttf',
    'packages/carbide/fonts/IBMPlexSerif-Regular.ttf',
  ],
};

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final MapEntry<String, List<String>> family in _fonts.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String asset in family.value) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
  await testMain();
}
