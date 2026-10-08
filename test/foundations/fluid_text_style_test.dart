// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:collection';

import 'package:carbide/carbide.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

CarbonFluidTextStyle _style() {
  final Map<String, TextStyle> overrides = <String, TextStyle>{
    'md': const TextStyle(fontSize: 20),
    'lg': const TextStyle(height: 1.5),
    'max': const TextStyle(fontSize: 40),
  };
  return CarbonFluidTextStyle(
    base: const TextStyle(fontSize: 14, height: 1.25).copyWith(),
    overrides: overrides,
  );
}

class _DerivedFluidTextStyle extends CarbonFluidTextStyle {
  const _DerivedFluidTextStyle({required super.base, super.overrides});
}

void main() {
  group('CarbonFluidTextStyle equality', () {
    test('separately constructed styles compare by all field values', () {
      final CarbonFluidTextStyle left = _style();
      final CarbonFluidTextStyle right = _style();
      expect(identical(left, right), isFalse);
      expect(identical(left.base, right.base), isFalse);
      expect(identical(left.overrides, right.overrides), isFalse);
      expect(left, equals(right));
      expect(right, equals(left));
      expect(left.hashCode, right.hashCode);
    });

    test('equal styles remain reflexive and transitive', () {
      final CarbonFluidTextStyle first = _style();
      final CarbonFluidTextStyle second = _style();
      final CarbonFluidTextStyle third = _style();
      expect(first, first);
      expect(first, second);
      expect(second, third);
      expect(first, third);
    });

    test('hashing ignores override insertion order', () {
      final CarbonFluidTextStyle left = _style();
      final Map<String, TextStyle> reversed = <String, TextStyle>{
        'max': const TextStyle(fontSize: 40),
        'lg': const TextStyle(height: 1.5),
        'md': const TextStyle(fontSize: 20),
      };
      final CarbonFluidTextStyle right = CarbonFluidTextStyle(
        base: left.base.copyWith(),
        overrides: reversed,
      );
      expect(left, right);
      expect(left.hashCode, right.hashCode);
      for (final double width in <double>[320, 672, 1056, 1312, 1584]) {
        expect(left.resolve(width), right.resolve(width));
      }
    });

    test('sorted and unmodifiable maps have the same value semantics', () {
      final CarbonFluidTextStyle original = _style();
      for (final Map<String, TextStyle> map in <Map<String, TextStyle>>[
        SplayTreeMap<String, TextStyle>.of(original.overrides),
        Map<String, TextStyle>.unmodifiable(original.overrides),
      ]) {
        final CarbonFluidTextStyle other = CarbonFluidTextStyle(
          base: original.base,
          overrides: map,
        );
        expect(other, original);
        expect(other.hashCode, original.hashCode);
      }
    });

    test('separately constructed empty maps compare equally', () {
      final Map<String, TextStyle> firstEmpty = <String, TextStyle>{};
      final Map<String, TextStyle> secondEmpty = <String, TextStyle>{};
      final CarbonFluidTextStyle left = CarbonFluidTextStyle(
        base: const TextStyle(fontSize: 14),
        overrides: firstEmpty,
      );
      final CarbonFluidTextStyle right = CarbonFluidTextStyle(
        base: const TextStyle(fontSize: 14),
        overrides: secondEmpty,
      );
      expect(identical(left.overrides, right.overrides), isFalse);
      expect(left, right);
      expect(left.hashCode, right.hashCode);
    });

    test('equal styles can retrieve map values and deduplicate in sets', () {
      final CarbonFluidTextStyle first = _style();
      final CarbonFluidTextStyle second = _style();
      expect(<CarbonFluidTextStyle, String>{first: 'cached'}[second], 'cached');
      expect(<CarbonFluidTextStyle>{first, second}, hasLength(1));
    });

    test('a changed base produces a different style', () {
      final CarbonFluidTextStyle original = _style();
      expect(
        CarbonFluidTextStyle(
          base: original.base.copyWith(color: const Color(0xFF123456)),
          overrides: original.overrides,
        ),
        isNot(original),
      );
    });

    test('a changed override value produces a different style', () {
      final CarbonFluidTextStyle original = _style();
      expect(
        CarbonFluidTextStyle(
          base: original.base,
          overrides: <String, TextStyle>{
            ...original.overrides,
            'md': const TextStyle(fontSize: 21),
          },
        ),
        isNot(original),
      );
    });

    test('a missing override key produces a different style', () {
      final CarbonFluidTextStyle original = _style();
      final Map<String, TextStyle> fewer = <String, TextStyle>{
        ...original.overrides,
      }..remove('lg');
      expect(
        CarbonFluidTextStyle(base: original.base, overrides: fewer),
        isNot(original),
      );
    });

    test(
      'an additional key matters even when current resolution ignores it',
      () {
        final CarbonFluidTextStyle original = _style();
        final CarbonFluidTextStyle additional = CarbonFluidTextStyle(
          base: original.base,
          overrides: <String, TextStyle>{
            ...original.overrides,
            'future': const TextStyle(fontSize: 100),
          },
        );
        expect(original.resolve(2000), additional.resolve(2000));
        expect(original, isNot(additional));
      },
    );

    test('override values stay associated with their breakpoint keys', () {
      const CarbonFluidTextStyle first = CarbonFluidTextStyle(
        base: TextStyle(fontSize: 14),
        overrides: <String, TextStyle>{
          'md': TextStyle(fontSize: 20),
          'lg': TextStyle(fontSize: 24),
        },
      );
      final CarbonFluidTextStyle second = CarbonFluidTextStyle(
        base: first.base,
        overrides: const <String, TextStyle>{
          'md': TextStyle(fontSize: 24),
          'lg': TextStyle(fontSize: 20),
        },
      );
      expect(first, isNot(second));
      expect(<CarbonFluidTextStyle>{first, second}, hasLength(2));
    });

    test('a style does not equal unrelated objects', () {
      expect(_style(), isNot(equals('fluid style')));
      expect(_style(), isNot(equals(const TextStyle(fontSize: 14))));
    });

    test(
      'a style does not equal another runtime type with the same fields',
      () {
        final CarbonFluidTextStyle original = _style();
        final CarbonFluidTextStyle derived = _DerivedFluidTextStyle(
          base: original.base,
          overrides: original.overrides,
        );
        expect(original, isNot(derived));
        expect(derived, isNot(original));
      },
    );
  });

  group('CarbonFluidTextStyle copyWith', () {
    test('omitted or null arguments preserve the value and hash', () {
      final CarbonFluidTextStyle original = _style();
      for (final CarbonFluidTextStyle copy in <CarbonFluidTextStyle>[
        original.copyWith(),
        original.copyWith(base: null, overrides: null),
      ]) {
        expect(copy, original);
        expect(copy.hashCode, original.hashCode);
        expect(
          <CarbonFluidTextStyle, String>{original: 'cached'}[copy],
          'cached',
        );
      }
    });

    test('derives a new base color without losing breakpoint overrides', () {
      final CarbonFluidTextStyle original = _style();
      const Color color = Color(0xFF123456);
      final CarbonFluidTextStyle copy = original.copyWith(
        base: original.base.copyWith(color: color),
      );
      expect(copy, isNot(original));
      expect(copy.overrides, original.overrides);
      for (final double width in <double>[320, 672, 1056, 1312, 1584]) {
        expect(
          copy.resolve(width),
          original.resolve(width).copyWith(color: color),
        );
      }
      expect(original.base.color, isNull);
    });

    test('replaces the overrides without changing the base', () {
      final CarbonFluidTextStyle original = _style();
      final CarbonFluidTextStyle copy = original.copyWith(
        overrides: <String, TextStyle>{'max': const TextStyle(fontSize: 48)},
      );
      expect(copy.base, original.base);
      expect(copy.overrides.keys, <String>['max']);
      expect(copy.resolve(672), original.base);
      expect(copy.resolve(1584).fontSize, 48);
      expect(original.resolve(672).fontSize, 20);
    });

    test('an empty overrides map clears the cascade', () {
      final CarbonFluidTextStyle original = _style();
      final CarbonFluidTextStyle copy = original.copyWith(
        overrides: <String, TextStyle>{},
      );
      expect(copy.overrides, isEmpty);
      expect(copy.resolve(2000), original.base);
      expect(copy, isNot(original));
      expect(original.overrides, hasLength(3));
    });

    test(
      'can change the base and overrides together without changing the source',
      () {
        final CarbonFluidTextStyle original = _style();
        final int originalHash = original.hashCode;
        final CarbonFluidTextStyle copy = original.copyWith(
          base: const TextStyle(fontSize: 18, height: 1.6),
          overrides: <String, TextStyle>{'md': const TextStyle(fontSize: 28)},
        );
        expect(copy.resolve(320), const TextStyle(fontSize: 18, height: 1.6));
        expect(copy.resolve(672), const TextStyle(fontSize: 28, height: 1.6));
        expect(
          original.resolve(320),
          const TextStyle(fontSize: 14, height: 1.25),
        );
        expect(
          original.resolve(672),
          const TextStyle(fontSize: 20, height: 1.25),
        );
        expect(original.hashCode, originalHash);
      },
    );

    test(
      'a separately constructed equivalent override map preserves equality',
      () {
        final CarbonFluidTextStyle original = _style();
        final CarbonFluidTextStyle copy = original.copyWith(
          overrides: _style().overrides,
        );
        expect(identical(original.overrides, copy.overrides), isFalse);
        expect(copy, original);
        expect(copy.hashCode, original.hashCode);
      },
    );
  });
}
