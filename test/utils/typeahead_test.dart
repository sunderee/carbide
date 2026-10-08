// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/src/utils/typeahead.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('menu accepts one letter/number grapheme across scripts', () {
    for (final String input in <String>[
      'a',
      'Z',
      '9',
      'É',
      'ü',
      'ñ',
      'å',
      'ć',
      'Д',
      'Ω',
      '東',
      '한',
      'م',
      'א',
      '١',
      '𐐀',
      'E\u0301',
      'कि',
      '1\ufe0f\u20e3',
    ]) {
      expect(isCarbonTypeaheadCharacter(input), isTrue, reason: input);
    }
  });

  test('menu rejects controls, punctuation, emoji and multiple graphemes', () {
    for (final String? input in <String?>[
      null,
      '',
      ' ',
      '\n',
      '\t',
      '\u001b',
      '\u007f',
      '?',
      '🙂',
      '👨‍👩‍👧',
      'ab',
      '東京',
      'e\u0301x',
      '\u0301',
    ]) {
      expect(isCarbonTypeaheadCharacter(input), isFalse, reason: '$input');
    }
  });

  test('Latin-1 lowercase and uppercase groups fold consistently', () {
    for (final (String input, String expected) in <(String, String)>[
      ('ÀÁÂÃÄÅàáâãäå', 'aaaaaaaaaaaa'),
      ('ÈÉÊËèéêë', 'eeeeeeee'),
      ('ÌÍÎÏìíîï', 'iiiiiiii'),
      ('ÒÓÔÕÖØòóôõöø', 'oooooooooooo'),
      ('ÙÚÛÜùúûü', 'uuuuuuuu'),
      ('ÇçÑñÐð', 'ccnndd'),
      ('Ýýÿ', 'yyy'),
      ('ÆæÞþßẞ', 'aeaeththssss'),
    ]) {
      expect(carbonTypeaheadKey(input), expected);
    }
  });

  test('composed and decomposed Latin prefixes match the same label', () {
    for (final String input in <String>['Éditer', 'E\u0301diter', 'EDITER']) {
      expect(carbonTypeaheadKey(input), 'editer');
    }
    expect(carbonTypeaheadKey('U\u0308ber'), 'uber');
    expect(carbonTypeaheadKey('İstanbul'), 'istanbul');
    expect(carbonTypeaheadKey('a\u0327\u0301'), 'a');
  });

  test('non-Latin and extended Latin marks retain their documented policy', () {
    expect(carbonTypeaheadKey('ДАННЫЕ'), 'данные');
    expect(carbonTypeaheadKey('𐐀eseret'), '𐐨eseret');
    expect(carbonTypeaheadKey('東京'), '東京');
    expect(carbonTypeaheadKey('कि'), 'कि');
    expect(carbonTypeaheadKey('α\u0301'), 'α\u0301');
    expect(carbonTypeaheadKey('ć'), 'ć');
    expect(carbonTypeaheadKey('🙂 status'), '🙂 status');
  });

  test(
    'prefix input and label punctuation are retained for picker commits',
    () {
      expect(carbonTypeaheadKey('EX'), 'ex');
      expect(carbonTypeaheadKey('?HELP'), '?help');
      expect(carbonTypeaheadKey('  Éditer'), '  editer');
      expect(carbonTypeaheadKey(''), '');
    },
  );
}
