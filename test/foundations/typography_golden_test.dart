// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Renders the Carbon type scale as a specimen. typography_test.dart locks
// every style's numeric metrics; this golden pins the *rendered* result — the
// real IBM Plex glyphs at each size, both families (Sans + Mono) and all three
// weights (300 / 400 / 600) — so a regression in font loading, weight mapping,
// or line height is caught visually.
//
// Contains text, so it is Linux-authoritative (see CONTRIBUTING).

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

void main() {
  testWidgets('the type scale specimen renders on each theme', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'typography',
      containsText: true,
      size: const Size(420, 520),
      builder: (BuildContext context) => const _TypeSpecimen(),
    );
  });
}

class _TypeSpecimen extends StatelessWidget {
  const _TypeSpecimen();

  // The visually distinct ladder: the display/heading sizes (54 → 14) plus the
  // body, label and mono styles. Every size, weight and family in the scale is
  // exercised at least once; the styles that are exact aliases are covered by
  // the value-lock test and omitted here to keep the specimen legible.
  static const List<(String, TextStyle)> _styles = <(String, TextStyle)>[
    ('heading07', CarbonTypeStyles.heading07),
    ('heading06', CarbonTypeStyles.heading06),
    ('heading05', CarbonTypeStyles.heading05),
    ('heading04', CarbonTypeStyles.heading04),
    ('heading03', CarbonTypeStyles.heading03),
    ('heading02', CarbonTypeStyles.heading02),
    ('heading01', CarbonTypeStyles.heading01),
    ('body02', CarbonTypeStyles.body02),
    ('body01', CarbonTypeStyles.body01),
    ('label01', CarbonTypeStyles.label01),
    ('helperText01', CarbonTypeStyles.helperText01),
    ('code02', CarbonTypeStyles.code02),
    ('code01', CarbonTypeStyles.code01),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final (String name, TextStyle style) in _styles)
            CarbonText('$name Ag', style: style),
        ],
      ),
    );
  }
}
