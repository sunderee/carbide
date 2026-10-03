// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final direction in TextDirection.values) {
    for (final ordered in <bool>[true, false]) {
      _test(
        'native lower-latin boundary labels and scrolling: $direction, ordered parent=$ordered',
        (tester) async {
          await tester.pumpWidget(
            _host(direction: direction, ordered: ordered),
          );
          await _settle(tester);
          for (final marker in <String>[
            'y.',
            'z.',
            'aa.',
            'ab.',
            'az.',
            'ba.',
          ]) {
            expect(_nativeText(marker), isNotNull);
          }
          expect(_nativeText('{.'), isNull);
          expect(_nativeText('|.'), isNull);
          await tester.ensureVisible(find.text('Item 53'));
          await _settle(tester);
          expect(_nativeText('ba.'), isNotNull);
          expect(_nativeText('Item 53'), isNotNull);
          expect(
            tester.getRect(find.text('ba.')).top,
            tester.getRect(find.text('Item 53')).top,
          );
          expect(
            tester
                .getRect(find.text('ba.'))
                .overlaps(tester.getRect(find.byType(SingleChildScrollView))),
            isTrue,
          );
          await tester.ensureVisible(find.text('Item 1'));
          await _settle(tester);
          expect(_nativeText('a.'), isNotNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final direction in TextDirection.values) {
    _test(
      'native wide expressive markers stay beside their items: $direction',
      (tester) async {
        await tester.pumpWidget(
          _host(direction: direction, count: 703, expressive: true),
        );
        await _settle(tester);
        await tester.ensureVisible(find.text('Item 703'));
        await _settle(tester);
        for (final entry in <String, int>{
          'zw.': 699,
          'zz.': 702,
          'aaa.': 703,
        }.entries) {
          expect(_nativeText(entry.key), isNotNull);
          final marker = tester.getRect(find.text(entry.key));
          final item = tester.getRect(find.text('Item ${entry.value}'));
          expect(marker.height, item.height);
          expect(
            direction == TextDirection.ltr ? marker.right : marker.left,
            closeTo(
              direction == TextDirection.ltr ? item.left - 4 : item.right + 4,
              0.01,
            ),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  _test(
    'native list length updates replace boundary labels and handle empty content',
    (tester) async {
      for (final count in <int>[53, 0, 1, 30]) {
        await tester.pumpWidget(_host(count: count));
        await _settle(tester);
        expect(_nativeText('ba.') != null, count >= 53);
        expect(_nativeText('a.') != null, count > 0);
        expect(_nativeText('aa.') != null, count >= 27);
        expect(_nativeText('{.'), isNull);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

void _test(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    });
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Widget _host({
  TextDirection direction = TextDirection.ltr,
  bool ordered = true,
  int count = 53,
  bool expressive = false,
}) {
  final items = <CarbonListItem>[
    CarbonListItem(
      child: CarbonOrderedList(
        children: <CarbonListItem>[
          for (int i = 0; i < count; i++)
            CarbonListItem(child: Text('Item ${i + 1}')),
        ],
      ),
    ),
  ];
  return WidgetsApp(
    color: const Color(0xffffffff),
    builder: (_, _) => CarbonTheme(
      data: CarbonThemeData.white,
      child: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(
            width: 360,
            height: 240,
            child: SingleChildScrollView(
              child: ordered
                  ? CarbonOrderedList(expressive: expressive, children: items)
                  : CarbonUnorderedList(
                      expressive: expressive,
                      children: items,
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}

_Element? _nativeText(String text) {
  final nodes = _document.querySelectorAll('flt-semantics');
  for (int i = 0; i < nodes.length; i++) {
    final node = nodes.item(i)!;
    if (node.textContent?.trim() == text ||
        node.getAttribute('aria-label') == text) {
      return node;
    }
  }
  return null;
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int i);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external String? getAttribute(String name);
}
