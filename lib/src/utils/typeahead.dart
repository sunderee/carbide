// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart' show StringCharacters;

final RegExp _letterOrNumber = RegExp(r'[\p{L}\p{N}]', unicode: true);
final RegExp _combiningMarks = RegExp(r'[\u0300-\u036f]');

const Map<int, String> _latin1 = <int, String>{
  0x00e0: 'a',
  0x00e1: 'a',
  0x00e2: 'a',
  0x00e3: 'a',
  0x00e4: 'a',
  0x00e5: 'a',
  0x00e6: 'ae',
  0x00e7: 'c',
  0x00e8: 'e',
  0x00e9: 'e',
  0x00ea: 'e',
  0x00eb: 'e',
  0x00ec: 'i',
  0x00ed: 'i',
  0x00ee: 'i',
  0x00ef: 'i',
  0x00f0: 'd',
  0x00f1: 'n',
  0x00f2: 'o',
  0x00f3: 'o',
  0x00f4: 'o',
  0x00f5: 'o',
  0x00f6: 'o',
  0x00f8: 'o',
  0x00f9: 'u',
  0x00fa: 'u',
  0x00fb: 'u',
  0x00fc: 'u',
  0x00fd: 'y',
  0x00fe: 'th',
  0x00ff: 'y',
  0x00df: 'ss',
};

/// Whether [input] is one Unicode letter/number grapheme for menu navigation.
///
/// Supplementary letters and letters with combining marks count as one
/// character. Whitespace, punctuation, emoji and multi-character commits do
/// not enter the menu's existing single-character cycling path.
bool isCarbonTypeaheadCharacter(String? input) =>
    input != null &&
    input.characters.length == 1 &&
    _letterOrNumber.hasMatch(input);

/// The lowercase, Latin-1-folded key used to compare typeahead prefixes.
///
/// Latin-1 accents and stroked letters fold to ASCII, `æ`/`þ`/`ß` expand to
/// `ae`/`th`/`ss`, and combining marks U+0300–036F are removed from Latin-base
/// graphemes. Other scripts and extended Latin characters retain their marks
/// after Unicode lowercasing. This is a documented limited fold, not full NFD
/// normalization or locale-specific collation. Visible labels are unchanged.
String carbonTypeaheadKey(String text) =>
    text.toLowerCase().characters.map((String cluster) {
      final int first = cluster.runes.first;
      final bool latin =
          first >= 0x61 && first <= 0x7a || _latin1.containsKey(first);
      final String folded = cluster.runes
          .map((int rune) => _latin1[rune] ?? String.fromCharCode(rune))
          .join();
      return latin ? folded.replaceAll(_combiningMarks, '') : folded;
    }).join();
