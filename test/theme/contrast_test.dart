// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// WCAG 2.1 contrast gate (#226): walks the (foreground, background) token
// pairings components actually render — per theme — and asserts the ratio
// class: >=4.5:1 for normal text (SC 1.4.3), >=3:1 for meaningful
// non-text/icons (SC 1.4.11). The themes are plain data, so this is an
// exhaustive value sweep, not a widget test.
//
// Known, upstream-inherited exceptions live in [_allowlist] with citations
// into documentation/carbon/packages/themes. Disabled-state tokens
// (textDisabled, iconDisabled, textOnColorDisabled) are not swept at all:
// WCAG 1.4.3 exempts inactive UI components.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

/// One token pairing under test.
typedef _Pair = ({
  String name,
  Color Function(CarbonThemeData) fg,
  Color Function(CarbonThemeData) bg,
  double floor,
});

const double _text = 4.5;
const double _nonText = 3.0;

final List<_Pair> _pairs = <_Pair>[
  // Body text on every surface step.
  for (final (String surface, Color Function(CarbonThemeData) bg)
      in _surfaces) ...<_Pair>[
    (
      name: 'textPrimary on $surface',
      fg: (CarbonThemeData t) => t.textPrimary,
      bg: bg,
      floor: _text,
    ),
    (
      name: 'textSecondary on $surface',
      fg: (CarbonThemeData t) => t.textSecondary,
      bg: bg,
      floor: _text,
    ),
    (
      name: 'textHelper on $surface',
      fg: (CarbonThemeData t) => t.textHelper,
      bg: bg,
      floor: _text,
    ),
    (
      name: 'iconPrimary on $surface',
      fg: (CarbonThemeData t) => t.iconPrimary,
      bg: bg,
      floor: _nonText,
    ),
    (
      name: 'iconSecondary on $surface',
      fg: (CarbonThemeData t) => t.iconSecondary,
      bg: bg,
      floor: _nonText,
    ),
  ],
  // Placeholder text (fields render it on the field layer).
  (
    name: 'textPlaceholder on layer01',
    fg: (CarbonThemeData t) => t.textPlaceholder,
    bg: (CarbonThemeData t) => t.layer01,
    floor: _text,
  ),
  // Validation text.
  (
    name: 'textError on background',
    fg: (CarbonThemeData t) => t.textError,
    bg: (CarbonThemeData t) => t.background,
    floor: _text,
  ),
  (
    name: 'textError on layer01',
    fg: (CarbonThemeData t) => t.textError,
    bg: (CarbonThemeData t) => t.layer01,
    floor: _text,
  ),
  // Button fills.
  (
    name: 'textOnColor on buttonPrimary',
    fg: (CarbonThemeData t) => t.textOnColor,
    bg: (CarbonThemeData t) => t.buttonPrimary,
    floor: _text,
  ),
  (
    name: 'textOnColor on buttonSecondary',
    fg: (CarbonThemeData t) => t.textOnColor,
    bg: (CarbonThemeData t) => t.buttonSecondary,
    floor: _text,
  ),
  (
    name: 'textOnColor on buttonDangerPrimary',
    fg: (CarbonThemeData t) => t.textOnColor,
    bg: (CarbonThemeData t) => t.buttonDangerPrimary,
    floor: _text,
  ),
  (
    name: 'buttonTertiary on background',
    fg: (CarbonThemeData t) => t.buttonTertiary,
    bg: (CarbonThemeData t) => t.background,
    floor: _text,
  ),
  (
    name: 'iconOnColor on buttonPrimary',
    fg: (CarbonThemeData t) => t.iconOnColor,
    bg: (CarbonThemeData t) => t.buttonPrimary,
    floor: _nonText,
  ),
  // Links.
  (
    name: 'linkPrimary on background',
    fg: (CarbonThemeData t) => t.linkPrimary,
    bg: (CarbonThemeData t) => t.background,
    floor: _text,
  ),
  (
    name: 'linkPrimary on layer01',
    fg: (CarbonThemeData t) => t.linkPrimary,
    bg: (CarbonThemeData t) => t.layer01,
    floor: _text,
  ),
  (
    name: 'linkPrimaryHover on background',
    fg: (CarbonThemeData t) => t.linkPrimaryHover,
    bg: (CarbonThemeData t) => t.background,
    floor: _text,
  ),
  (
    name: 'linkSecondary on background',
    fg: (CarbonThemeData t) => t.linkSecondary,
    bg: (CarbonThemeData t) => t.background,
    floor: _text,
  ),
  // Inverse surfaces (tooltips, toasts).
  (
    name: 'textInverse on backgroundInverse',
    fg: (CarbonThemeData t) => t.textInverse,
    bg: (CarbonThemeData t) => t.backgroundInverse,
    floor: _text,
  ),
  (
    name: 'linkInverse on backgroundInverse',
    fg: (CarbonThemeData t) => t.linkInverse,
    bg: (CarbonThemeData t) => t.backgroundInverse,
    floor: _text,
  ),
  // The focus ring must be discernible against the canvas (SC 1.4.11).
  (
    name: 'focus on background',
    fg: (CarbonThemeData t) => t.focus,
    bg: (CarbonThemeData t) => t.background,
    floor: _nonText,
  ),
  // Interactive accent used for selected/active affordances.
  (
    name: 'iconInteractive on background',
    fg: (CarbonThemeData t) => t.iconInteractive,
    bg: (CarbonThemeData t) => t.background,
    floor: _nonText,
  ),
];

final List<(String, Color Function(CarbonThemeData))> _surfaces =
    <(String, Color Function(CarbonThemeData))>[
      ('background', (CarbonThemeData t) => t.background),
      ('layer01', (CarbonThemeData t) => t.layer01),
      ('layer02', (CarbonThemeData t) => t.layer02),
      ('layer03', (CarbonThemeData t) => t.layer03),
    ];

/// Upstream-inherited pairs that do not meet the floor, keyed
/// `'<theme>: <pair name>'`, each citing the upstream token choice.
///
/// Populate only with pairs whose values match upstream exactly — a new
/// entry requires the corresponding token in
/// documentation/carbon/packages/themes/src to produce the same ratio.
final Map<String, String> _allowlist = <String, String>{
  // Placeholder text is defined as 40%-alpha textPrimary in every theme —
  // sub-AA by construction (themes/src/<theme>.ts:
  // `textPlaceholder = adjustAlpha(textPrimary, 0.4)` @ v11.111.0).
  'white: textPlaceholder on layer01':
      'themes/src/white.ts textPlaceholder = adjustAlpha(textPrimary, 0.4)',
  'g10: textPlaceholder on layer01':
      'themes/src/g10.ts textPlaceholder = adjustAlpha(textPrimary, 0.4)',
  'g90: textPlaceholder on layer01':
      'themes/src/g90.ts textPlaceholder = adjustAlpha(textPrimary, 0.4)',
  'g100: textPlaceholder on layer01':
      'themes/src/g100.ts textPlaceholder = adjustAlpha(textPrimary, 0.4)',
  // Carbon's third layer step in the dark themes is a constrained surface:
  // gray30/gray40 secondary inks over gray60/gray70 fills are upstream's
  // own pairings (themes/src/g90.ts layer03 = gray60 with
  // textSecondary/textHelper/iconSecondary = gray30; themes/src/g100.ts
  // layer03 = gray70 with textHelper = gray40 @ v11.111.0).
  'g90: textSecondary on layer03':
      'themes/src/g90.ts textSecondary = gray30 over layer03 = gray60',
  'g90: textHelper on layer03':
      'themes/src/g90.ts textHelper = gray30 over layer03 = gray60',
  'g90: iconSecondary on layer03':
      'themes/src/g90.ts iconSecondary = gray30 over layer03 = gray60',
  'g100: textHelper on layer03':
      'themes/src/g100.ts textHelper = gray40 over layer03 = gray70',
};

void main() {
  final Map<String, CarbonThemeData> themes = <String, CarbonThemeData>{
    'white': CarbonThemeData.white,
    'g10': CarbonThemeData.gray10,
    'g90': CarbonThemeData.gray90,
    'g100': CarbonThemeData.gray100,
  };

  group('WCAG 2.1 token-pair contrast sweep', () {
    for (final MapEntry<String, CarbonThemeData> theme in themes.entries) {
      test(theme.key, () {
        final List<String> failures = <String>[];
        for (final _Pair pair in _pairs) {
          final String key = '${theme.key}: ${pair.name}';
          final double ratio = wcagContrastRatio(
            pair.fg(theme.value),
            pair.bg(theme.value),
          );
          final bool passes = ratio >= pair.floor;
          if (passes) {
            expect(
              _allowlist.containsKey(key),
              isFalse,
              reason:
                  '$key now passes (${ratio.toStringAsFixed(2)}:1) — '
                  'remove its stale allowlist entry.',
            );
          } else if (!_allowlist.containsKey(key)) {
            failures.add(
              '$key = ${ratio.toStringAsFixed(2)}:1 '
              '(needs ${pair.floor}:1)',
            );
          }
        }
        expect(
          failures,
          isEmpty,
          reason:
              'Token pairs below their WCAG floor and not allowlisted:\n'
              '${failures.join('\n')}',
        );
      });
    }
  });
}
