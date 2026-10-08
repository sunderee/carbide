// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:io';

import 'package:flutter/services.dart';

Future<void> loadDateLocaleFonts() async {
  for (final (String family, String asset) in <(String, String)>[
    ('Carbide Test Arabic', 'CarbideTestArabic.ttf'),
    ('Carbide Test Japanese', 'CarbideTestJapanese.ttf'),
  ]) {
    final Uint8List bytes = await File('test/support/fonts/$asset')
        .readAsBytes();
    final FontLoader loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
