// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// CSS lower-latin representation of a zero-based item [index].
///
/// Uses bijective base 26: a … z, aa … az, ba … zz, aaa …. Work is bounded
/// by the number of letters. Avoids adding one to [index], so the largest
/// native integer is supported without overflow. Negative indices are invalid.
String lowerLatin(int index) {
  RangeError.checkNotNegative(index, 'index');
  final List<int> letters = <int>[];
  do {
    letters.add(0x61 + index % 26);
    index = index ~/ 26 - 1;
  } while (index >= 0);
  return String.fromCharCodes(letters.reversed);
}
