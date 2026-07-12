// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui';

import 'package:carbide/src/icons/svg_path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Rect bounds(String d) => parseSvgPath(d).getBounds();

  test('absolute and relative move/line commands', () {
    expect(bounds('M2,3 L10,3 L10,8 Z'), const Rect.fromLTRB(2, 3, 10, 8));
    expect(bounds('m2,3 l8,0 l0,5 z'), const Rect.fromLTRB(2, 3, 10, 8));
  });

  test('implicit repetition after M is treated as lineto', () {
    expect(bounds('M0,0 4,0 4,4 0,4 Z'), const Rect.fromLTRB(0, 0, 4, 4));
    // Relative form: each pair advances from the previous point.
    expect(bounds('m1,1 3,0 0,3 -3,0 z'), const Rect.fromLTRB(1, 1, 4, 4));
  });

  test('horizontal and vertical commands', () {
    expect(bounds('M1,1 H9 V7 H1 Z'), const Rect.fromLTRB(1, 1, 9, 7));
    expect(bounds('M1,1 h8 v6 h-8 z'), const Rect.fromLTRB(1, 1, 9, 7));
  });

  test('cubic curves and smooth reflection', () {
    final Path explicit = parseSvgPath('M0,8 C2,0 6,0 8,8 C10,16 14,16 16,8');
    final Path smooth = parseSvgPath('M0,8 C2,0 6,0 8,8 S14,16 16,8');
    expect(
      smooth.getBounds(),
      rectMoreOrLessEquals(explicit.getBounds(), epsilon: 1e-6),
    );
  });

  test('quadratic curves and smooth reflection', () {
    final Path explicit = parseSvgPath('M0,8 Q4,0 8,8 Q12,16 16,8');
    final Path smooth = parseSvgPath('M0,8 Q4,0 8,8 T16,8');
    expect(
      smooth.getBounds(),
      rectMoreOrLessEquals(explicit.getBounds(), epsilon: 1e-6),
    );
  });

  test('unreflected S falls back to the current point as first control', () {
    // S without a preceding C/S: first control point == current point.
    final Path s = parseSvgPath('M0,0 S8,8 8,0');
    final Path c = parseSvgPath('M0,0 C0,0 8,8 8,0');
    expect(s.getBounds(), rectMoreOrLessEquals(c.getBounds(), epsilon: 1e-6));
  });

  test('arcs: a full circle from two arc halves', () {
    // The generator's circle conversion: two a-commands of radius 5 at (8,8).
    final Rect b = bounds('M3,8 a5,5 0 1 0 10,0 a5,5 0 1 0 -10,0 z');
    expect(b, rectMoreOrLessEquals(const Rect.fromLTRB(3, 3, 13, 13)));
  });

  test('arcs: compact flag syntax without separators', () {
    // "0 011 1" packs large-arc=0, sweep=1, then x=1 y=1.
    final Rect compact = bounds('M0,0 a1,1 0 011,1');
    final Rect spaced = bounds('M0,0 a1,1 0 0 1 1,1');
    expect(compact, rectMoreOrLessEquals(spaced, epsilon: 1e-6));
  });

  test('Z resets the current point to the subpath start', () {
    // After Z the current point is the subpath start (0,0), so m0,8 lands at
    // (0,8) — were Z ignored, it would land at (4,12).
    final Rect b = bounds('M0,0 L4,0 L4,4 Z m0,8 l2,0');
    expect(b, const Rect.fromLTRB(0, 0, 4, 8));
  });

  test('scientific notation and packed negative numbers', () {
    expect(bounds('M1e1,5e-1 L2E1,1.5'), const Rect.fromLTRB(10, 0.5, 20, 1.5));
    // "1.5-2.5" packs two numbers; the minus starts the second.
    expect(bounds('M1.5-2.5L3,4'), const Rect.fromLTRB(1.5, -2.5, 3, 4));
  });

  test('malformed input throws FormatException', () {
    expect(() => parseSvgPath('M0,0 X9'), throwsFormatException);
    expect(() => parseSvgPath('M0,0 a1,1 0 2 0 1,1'), throwsFormatException);
    expect(() => parseSvgPath('5,5 L1,1'), throwsFormatException);
  });
}
