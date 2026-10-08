// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/src/utils/indexed_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('length and offscreen reads do not materialize the data source', () {
    final List<int> reads = <int>[];
    final CarbonIndexedOptions<String> source = CarbonIndexedOptions<String>(
      1000,
      (int index) {
        reads.add(index);
        return 'Option $index';
      },
    );
    expect(source.length, 1000);
    expect(reads, isEmpty);
    expect(source[997], 'Option 997');
    expect(reads, <int>[997]);
    expect(() => source[-1], throwsRangeError);
    expect(() => source[1000], throwsRangeError);
    expect(reads, <int>[997]);
    expect(() => source.length = 5, throwsUnsupportedError);
    expect(() => source[1] = 'Replaced', throwsUnsupportedError);
    expect(
      () => CarbonIndexedOptions<int>(-1, (index) => index),
      throwsRangeError,
    );
  });

  test('filtering retains indices and reads current metadata on demand', () {
    String suffix = 'first';
    final CarbonIndexedOptions<String> source = CarbonIndexedOptions<String>(
      1000,
      (int index) => '$index $suffix',
    );
    final List<String> filtered = carbonFilteredOptions<String>(
      source,
      (String label) => label.startsWith('997 ') || label.startsWith('999 '),
    );
    expect(filtered.length, 2);
    expect(filtered[0], '997 first');
    suffix = 'updated';
    expect(filtered[1], '999 updated');
    expect(() => filtered.add('Extra'), throwsUnsupportedError);
  });
}
