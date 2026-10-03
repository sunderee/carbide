// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/src/utils/list_markers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_test/flutter_test.dart';

BigInt _number(String marker) => marker.codeUnits.fold(
  BigInt.zero,
  (value, letter) => value * BigInt.from(26) + BigInt.from(letter - 0x60),
);

void main() {
  for (final entry in <int, String>{
    0: 'a',
    1: 'b',
    24: 'y',
    25: 'z',
    26: 'aa',
    27: 'ab',
    51: 'az',
    52: 'ba',
    701: 'zz',
    702: 'aaa',
    18277: 'zzz',
    18278: 'aaaa',
  }.entries) {
    test('lower-latin index ${entry.key} is ${entry.value}', () {
      expect(lowerLatin(entry.key), entry.value);
    });
  }
  test('50,000 markers are unique lowercase letters and decode to their item numbers', () {
    final seen = <String>{};
    for (int i = 0; i < 50000; i++) {
      final marker = lowerLatin(i);
      expect(marker, matches(RegExp(r'^[a-z]+$')));
      expect(seen.add(marker), isTrue, reason: 'duplicate at index $i');
      expect(_number(marker), BigInt.from(i) + BigInt.one);
    }
  });
  test(
    'largest platform integer converts without overflow or unbounded work',
    () {
      final index = kIsWeb
          ? 9007199254740991
          : int.parse('9223372036854775807');
      final marker = lowerLatin(index);
      expect(marker, matches(RegExp(r'^[a-z]+$')));
      expect(marker.length, lessThanOrEqualTo(14));
      expect(_number(marker), BigInt.from(index) + BigInt.one);
    },
  );
  for (final index in <int>[-1, -26, -1000000]) {
    test('negative index $index is rejected', () {
      expect(() => lowerLatin(index), throwsRangeError);
    });
  }
}
