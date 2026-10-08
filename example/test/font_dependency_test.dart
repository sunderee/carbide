// Copyright 2026 Bizjak Tech OÜ

import 'dart:convert';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('built-in styles match the independent consumer FontManifest', () async {
    final List<dynamic> entries = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    final Set<String> registered = <String>{
      for (final dynamic entry in entries)
        (entry as Map<String, dynamic>)['family'] as String,
    };
    // The test font loader can create extra aliases in memory. This independent
    // manifest records the names consumers receive without that loader.
    for (final String? family in <String?>[
      CarbonTypeStyles.body01.fontFamily,
      CarbonTypeStyles.code01.fontFamily,
      CarbonFluidTypeStyles.expressiveHeading01.base.fontFamily,
      CarbonFluidTypeStyles.quotation01.base.fontFamily,
    ]) {
      expect(registered, contains(family));
    }
    expect(
      registered.where((String name) => name.startsWith('packages/carbide/')),
      hasLength(3),
    );
  });
}
