// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'date_locale_fonts_io.dart'
    if (dart.library.js_interop) 'date_locale_fonts_web.dart'
    as platform;

const List<String> dateLocaleFontFallbacks = <String>[
  'Carbide Test Arabic',
  'Carbide Test Japanese',
];

Future<void> loadDateLocaleFonts() => platform.loadDateLocaleFonts();
