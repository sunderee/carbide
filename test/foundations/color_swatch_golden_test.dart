// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Renders the full Carbon color palette — every family's 10–100 ramp — as a
// grid of solid swatches. The numeric value of each colour is locked exactly
// in colors_test.dart; this golden additionally pins the *rendered* palette so
// a regression in any swatch (or its position in the ramp) is caught visually.
//
// It deliberately renders only solid rectangles (no text, no anti-aliased
// edges) so the baseline is pixel-stable across the development machine and CI.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

void main() {
  testWidgets('the full color palette renders on each theme background', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'color_swatch',
      size: const Size(376, 296),
      builder: (BuildContext context) => const _Palette(),
    );
  });
}

class _Palette extends StatelessWidget {
  const _Palette();

  // Every family's full 10 → 100 ramp, ordered as the Carbon palette is.
  static const List<List<Color>> _families = <List<Color>>[
    <Color>[
      CarbonColors.yellow10, CarbonColors.yellow20, CarbonColors.yellow30,
      CarbonColors.yellow40, CarbonColors.yellow50, CarbonColors.yellow60,
      CarbonColors.yellow70, CarbonColors.yellow80, CarbonColors.yellow90,
      CarbonColors.yellow100, //
    ],
    <Color>[
      CarbonColors.orange10, CarbonColors.orange20, CarbonColors.orange30,
      CarbonColors.orange40, CarbonColors.orange50, CarbonColors.orange60,
      CarbonColors.orange70, CarbonColors.orange80, CarbonColors.orange90,
      CarbonColors.orange100, //
    ],
    <Color>[
      CarbonColors.red10, CarbonColors.red20, CarbonColors.red30,
      CarbonColors.red40, CarbonColors.red50, CarbonColors.red60,
      CarbonColors.red70, CarbonColors.red80, CarbonColors.red90,
      CarbonColors.red100, //
    ],
    <Color>[
      CarbonColors.magenta10, CarbonColors.magenta20, CarbonColors.magenta30,
      CarbonColors.magenta40, CarbonColors.magenta50, CarbonColors.magenta60,
      CarbonColors.magenta70, CarbonColors.magenta80, CarbonColors.magenta90,
      CarbonColors.magenta100, //
    ],
    <Color>[
      CarbonColors.purple10, CarbonColors.purple20, CarbonColors.purple30,
      CarbonColors.purple40, CarbonColors.purple50, CarbonColors.purple60,
      CarbonColors.purple70, CarbonColors.purple80, CarbonColors.purple90,
      CarbonColors.purple100, //
    ],
    <Color>[
      CarbonColors.blue10, CarbonColors.blue20, CarbonColors.blue30,
      CarbonColors.blue40, CarbonColors.blue50, CarbonColors.blue60,
      CarbonColors.blue70, CarbonColors.blue80, CarbonColors.blue90,
      CarbonColors.blue100, //
    ],
    <Color>[
      CarbonColors.cyan10, CarbonColors.cyan20, CarbonColors.cyan30,
      CarbonColors.cyan40, CarbonColors.cyan50, CarbonColors.cyan60,
      CarbonColors.cyan70, CarbonColors.cyan80, CarbonColors.cyan90,
      CarbonColors.cyan100, //
    ],
    <Color>[
      CarbonColors.teal10, CarbonColors.teal20, CarbonColors.teal30,
      CarbonColors.teal40, CarbonColors.teal50, CarbonColors.teal60,
      CarbonColors.teal70, CarbonColors.teal80, CarbonColors.teal90,
      CarbonColors.teal100, //
    ],
    <Color>[
      CarbonColors.green10, CarbonColors.green20, CarbonColors.green30,
      CarbonColors.green40, CarbonColors.green50, CarbonColors.green60,
      CarbonColors.green70, CarbonColors.green80, CarbonColors.green90,
      CarbonColors.green100, //
    ],
    <Color>[
      CarbonColors.coolGray10, CarbonColors.coolGray20, CarbonColors.coolGray30,
      CarbonColors.coolGray40, CarbonColors.coolGray50, CarbonColors.coolGray60,
      CarbonColors.coolGray70, CarbonColors.coolGray80, CarbonColors.coolGray90,
      CarbonColors.coolGray100, //
    ],
    <Color>[
      CarbonColors.gray10, CarbonColors.gray20, CarbonColors.gray30,
      CarbonColors.gray40, CarbonColors.gray50, CarbonColors.gray60,
      CarbonColors.gray70, CarbonColors.gray80, CarbonColors.gray90,
      CarbonColors.gray100, //
    ],
    <Color>[
      CarbonColors.warmGray10, CarbonColors.warmGray20, CarbonColors.warmGray30,
      CarbonColors.warmGray40, CarbonColors.warmGray50, CarbonColors.warmGray60,
      CarbonColors.warmGray70, CarbonColors.warmGray80, CarbonColors.warmGray90,
      CarbonColors.warmGray100, //
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final List<Color> ramp in _families)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final Color color in ramp)
                  SizedBox(
                    width: 36,
                    height: 22,
                    child: ColoredBox(color: color),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
