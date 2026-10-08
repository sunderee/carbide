// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide/src/components/list_box/list_box_semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/legibility.dart';
import '../../support/overlay_entries.dart';

Widget _host(
  Widget child, {
  double width = 760,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (_) => Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: width, child: child),
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  test('pagination rejects invalid scalar inputs at construction', () {
    for (final int size in <int>[0, -1]) {
      expect(
        () => CarbonPagination(page: 1, pageSize: size, totalItems: 100),
        throwsAssertionError,
      );
    }
    for (final int page in <int>[0, -1]) {
      expect(
        () => CarbonPagination(page: page, pageSize: 10, totalItems: 100),
        throwsAssertionError,
      );
    }
    expect(
      () => CarbonPagination(page: 1, pageSize: 10, totalItems: -1),
      throwsAssertionError,
    );
  });
  for (final List<int> sizes in <List<int>>[
    <int>[],
    <int>[10, 10],
    <int>[0, 10],
    <int>[-1, 10],
  ]) {
    testWidgets('pagination rejects invalid page sizes $sizes', (tester) async {
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 1,
            pageSize: 10,
            totalItems: 100,
            pageSizes: sizes,
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  }
  testWidgets('page choices stay bounded for 10,000 pages', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      _host(
        CarbonPagination(
          page: 5000,
          pageSize: 10,
          totalItems: 100000,
          onPageChanged: (_) {},
        ),
      ),
    );
    final CarbonSelect<int> pages = tester
        .widgetList<CarbonSelect<int>>(find.byType(CarbonSelect<int>))
        .last;
    expect(pages.items.length, lessThanOrEqualTo(7));
    final List<int> values = pages.items
        .whereType<CarbonSelectItem<int>>()
        .map((item) => item.value)
        .toList();
    expect(values, containsAll(<int>[1, 4999, 5000, 5001, 10000]));
    await tester.tap(find.text('5000'));
    await tester.pumpAndSettle();
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      find.byType(CarbonListBoxOptionSemantics).evaluate().length,
      lessThanOrEqualTo(7),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('a result shrink clamps page, readout and navigation together', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final ValueNotifier<int> total = ValueNotifier<int>(100);
    addTearDown(total.dispose);
    int? chosen;
    await tester.pumpWidget(
      _host(
        ValueListenableBuilder<int>(
          valueListenable: total,
          builder: (_, value, _) => CarbonPagination(
            page: 10,
            pageSize: 10,
            totalItems: value,
            onPageChanged: (page) => chosen = page,
          ),
        ),
      ),
    );
    total.value = 15;
    await tester.pumpAndSettle();
    expect(find.text('11–15 of 15 items'), findsOneWidget);
    expect(
      tester
          .widgetList<CarbonSelect<int>>(find.byType(CarbonSelect<int>))
          .last
          .value,
      2,
    );
    final List<CarbonButton> arrows = tester
        .widgetList<CarbonButton>(find.byType(CarbonButton))
        .toList();
    expect(arrows.last.onPressed, isNull);
    arrows.first.onPressed!();
    expect(chosen, 1);
    total.value = 0;
    await tester.pumpAndSettle();
    expect(find.text('0–0 of 0 items'), findsOneWidget);
    expect(
      tester
          .widgetList<CarbonSelect<int>>(find.byType(CarbonSelect<int>))
          .last
          .value,
      1,
    );
    expect(
      tester
          .widgetList<CarbonButton>(find.byType(CarbonButton))
          .every((button) => button.onPressed == null),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('an enormous page size avoids integer overflow', (tester) async {
    await tester.pumpWidget(
      _host(
        const CarbonPagination(
          page: 2,
          pageSize: 0x7fffffffffffffff,
          totalItems: 95,
        ),
      ),
    );
    expect(find.text('1–95 of 95 items'), findsOneWidget);
    expect(find.text('of 1 pages'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final TextDirection direction in TextDirection.values) {
    for (final double scale in <double>[1, 2]) {
      testWidgets('320px pagination stays legible in $direction at $scale', (
        tester,
      ) async {
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        await tester.pumpWidget(
          _host(
            CarbonPagination(
              page: 3,
              pageSize: 10,
              totalItems: 95,
              onPageChanged: (_) {},
              onPageSizeChanged: (_) {},
            ),
            width: 320,
            scale: scale,
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expectNoClippedTextAtScale(tester, scale);
        final Rect bar = tester.getRect(find.byType(CarbonPagination));
        for (final Finder control in <Finder>[
          find.byType(CarbonSelect<int>),
          find.byType(CarbonButton),
        ]) {
          for (final Element element in control.evaluate()) {
            final Rect bounds = tester.getRect(
              find.byElementPredicate(
                (candidate) => identical(candidate, element),
              ),
            );
            expect(bounds.left, greaterThanOrEqualTo(bar.left));
            expect(bounds.right, lessThanOrEqualTo(bar.right));
          }
        }
      });
    }
  }
}
