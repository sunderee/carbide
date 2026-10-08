// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'all curated thresholds have measured budgets and structural contracts',
    () {
      final Map<String, dynamic> manifest = jsonDecode(
        File('tool/fidelity/stories.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final List<dynamic> stories = manifest['stories'] as List<dynamic>;
      expect(stories.length, 33);
      expect(
        stories
            .map(
              (dynamic story) => (story as Map<String, dynamic>)['component'],
            )
            .toSet()
            .length,
        33,
      );
      for (final dynamic item in stories) {
        final Map<String, dynamic> story = item as Map<String, dynamic>;
        final Map<String, dynamic> baseline =
            story['baseline'] as Map<String, dynamic>;
        final Map<String, dynamic> themes =
            baseline['themes'] as Map<String, dynamic>;
        expect(themes.keys.toSet(), <String>{'white', 'g10', 'g90', 'g100'});
        final double maximum = themes.values
            .map((dynamic value) => (value as num).toDouble())
            .reduce(math.max);
        expect(baseline['maximum'], maximum);
        final double margin = (baseline['margin'] as num).toDouble();
        expect(margin, inExclusiveRange(0, .010001));
        expect(
          (story['threshold'] as num).toDouble(),
          closeTo(maximum + margin, .000001),
        );
        expect(baseline['platform'], 'Linux');
        expect(baseline['algorithm'], 'mean-absolute-24x24-luminance');
        expect(baseline['sourceCommit'], matches(RegExp(r'^[a-f0-9]{40}$')));
        expect((story['rationale'] as String).length, greaterThan(50));
        final Map<String, dynamic> structure =
            story['structural'] as Map<String, dynamic>;
        final List<dynamic> size = structure['size'] as List<dynamic>;
        expect(size.length, 2);
        for (final dynamic dimension in size) {
          expect((dimension as num).toDouble(), greaterThan(0));
        }
        expect(structure['sizeTolerance'], lessThanOrEqualTo(3));
        expect(structure['rationale'], isNotEmpty);
      }
    },
  );
}
