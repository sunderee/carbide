// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/grid_gutters_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Pinned Carbon _css-grid.scss: narrow removes start half-gutter only.
  for (final CarbonGridMode mode in CarbonGridMode.values) {
    for (final TextDirection direction in TextDirection.values) {
      for (final bool fullWidth in <bool>[false, true]) {
        for (final bool nested in <bool>[false, true]) {
          testWidgets(
            'native $mode $direction full=$fullWidth nested=$nested',
            (WidgetTester tester) async {
              final SemanticsHandle semantics = tester.ensureSemantics();
              try {
                await tester.pumpWidget(
                  gridGuttersHost(
                    GridGuttersFixture(
                      mode: mode,
                      fullWidth: fullWidth,
                      nested: nested,
                      gridWidth: 672,
                    ),
                    direction: direction,
                  ),
                );
                await _settle(tester);
                final _Rect parent = _bounds('grid-parent');
                final _Rect first = _bounds('grid-cell-0');
                final _Rect second = _bounds('grid-cell-1');
                final double start = switch (mode) {
                  CarbonGridMode.wide => 16,
                  CarbonGridMode.narrow => 0,
                  CarbonGridMode.condensed => 0.5,
                };
                final double end = mode == CarbonGridMode.condensed ? 0.5 : 16;
                final double margin = fullWidth ? 0 : 16;
                expect(parent.width, closeTo(672, 0.01));
                expect(
                  direction == TextDirection.ltr
                      ? first.left - parent.left
                      : parent.right - first.right,
                  closeTo(margin + start, 0.01),
                );
                expect(
                  direction == TextDirection.ltr
                      ? parent.right - second.right
                      : second.left - parent.left,
                  closeTo(margin + end + 1, 0.01),
                );
                expect(
                  direction == TextDirection.ltr
                      ? second.left - first.right
                      : first.left - second.right,
                  closeTo(start + end, 0.01),
                );
                for (int row = 1; row < 3; row++) {
                  final _Rect a = _bounds('grid-cell-${row * 2}');
                  expect(a.left, closeTo(first.left, 0.01));
                  expect(a.top - first.top, closeTo(row * 56, 0.01));
                }
                if (nested) {
                  final _Rect leaf = _bounds('grid-nested-leaf');
                  expect(
                    direction == TextDirection.ltr ? leaf.left : leaf.right,
                    closeTo(
                      direction == TextDirection.ltr ? first.left : first.right,
                      0.01,
                    ),
                  );
                }
                expect(tester.takeException(), isNull);
              } finally {
                await tester.pumpWidget(const SizedBox.shrink());
                await _settle(tester);
                semantics.dispose();
              }
            },
          );
        }
      }
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

_Rect _bounds(String id) {
  final _Element? element = _document.querySelector(
    '[flt-semantics-identifier="$id"]',
  );
  if (element == null) throw StateError('No native grid node $id');
  return element.getBoundingClientRect();
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
}

extension type _Element(JSObject _) implements JSObject {
  external _Rect getBoundingClientRect();
}

extension type _Rect(JSObject _) implements JSObject {
  external double get left;
  external double get right;
  external double get top;
  external double get width;
}
