// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:collection';

/// A read-only indexed data source, without materializing its option models.
/// Keyboard search and reconciliation can read offscreen metadata independently
/// of the menu's mounted widget window. Builders must be pure and return stable
/// option values; the model objects themselves need not retain their identity.
class CarbonIndexedOptions<E> extends ListBase<E> {
  /// Creates an indexed data source with [count] options.
  CarbonIndexedOptions(int count, this.builder) : _count = count {
    RangeError.checkNotNegative(count, 'count');
  }

  final int _count;

  /// Reads one option's data, including options that have never mounted.
  final E Function(int index) builder;

  @override
  int get length => _count;

  @override
  set length(int value) => throw UnsupportedError('Options are read-only.');

  @override
  E operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return builder(index);
  }

  @override
  void operator []=(int index, E value) =>
      throw UnsupportedError('Options are read-only.');
}

/// Filters metadata into indices, retaining no additional option-model list.
List<E> carbonFilteredOptions<E>(List<E> source, bool Function(E) predicate) {
  final List<int> indices = <int>[
    for (int i = 0; i < source.length; i++)
      if (predicate(source[i])) i,
  ];
  return CarbonIndexedOptions<E>(indices.length, (int i) => source[indices[i]]);
}
