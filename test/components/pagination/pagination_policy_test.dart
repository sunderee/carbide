// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide/src/components/list_box/list_box_semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/legibility.dart';
import '../../support/golden.dart';
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
        CarbonPagination(
          page: 2,
          pageSize: int.parse(
            kIsWeb ? '9007199254740991' : '9223372036854775807',
          ),
          totalItems: 95,
        ),
      ),
    );
    expect(find.text('1–95 of 95 items'), findsOneWidget);
    expect(find.text('of 1 page'), findsOneWidget);
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
  testWidgets('all text, numbering and active hints can be localized', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final CarbonPaginationLocalizations labels =
          CarbonPaginationLocalizations(
            locale: const Locale('de'),
            paginationLabel: 'Seitennavigation',
            itemsPerPageLabel: 'Ergebnisse pro Anzeigeseite',
            pageLabel: 'Anzeigeseite',
            previousPageLabel: 'Zurück',
            nextPageLabel: 'Weiter',
            rangeFormatter: (start, end, total) => 'Bereich $start:$end:$total',
            pageCountFormatter: (total) => '$total Seiten',
            numberFormatter: (value) => 'Nr.$value',
            activeOptionFormatter: (label, position, count) =>
                '$label ($position/$count)',
          );
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 3,
            pageSize: 10,
            totalItems: 95,
            localizations: labels,
            onPageChanged: (_) {},
            onPageSizeChanged: (_) {},
          ),
          width: 320,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bereich 21:30:95'), findsOneWidget);
      expect(find.text('10 Seiten'), findsOneWidget);
      expect(find.text('Ergebnisse pro Anzeigeseite'), findsOneWidget);
      expect(find.text('Nr.3'), findsOneWidget);
      expect(find.bySemanticsLabel('Seitennavigation'), findsOneWidget);
      final List<CarbonButton> arrows = tester
          .widgetList<CarbonButton>(find.byType(CarbonButton))
          .toList();
      expect(arrows.first.label, 'Zurück');
      expect(arrows.last.label, 'Weiter');
      final CarbonSelect<int> pages = tester
          .widgetList<CarbonSelect<int>>(find.byType(CarbonSelect<int>))
          .last;
      expect(pages.labelText, 'Anzeigeseite');
      await tester.tap(find.text('Nr.3'));
      await tester.pumpAndSettle();
      expect(
        tester.semantics.simulatedAccessibilityTraversal().any(
          (node) => node.getSemanticsData().hint == 'Nr.3 (3/6)',
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      expectNoClippedTextAtScale(tester, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      semantics.dispose();
    }
  });
  test('legacy label overrides take precedence over the delegate', () {
    const CarbonPagination widget = CarbonPagination(
      page: 1,
      pageSize: 10,
      totalItems: 100,
      localizations: CarbonPaginationLocalizations(
        itemsPerPageLabel: 'Delegate',
        previousPageLabel: 'Vorher',
        nextPageLabel: 'Weiter',
      ),
      itemsPerPageText: 'Legacy size',
      backwardText: 'Legacy back',
      forwardText: 'Legacy next',
    );
    expect(widget.itemsPerPageText, 'Legacy size');
    expect(widget.backwardText, 'Legacy back');
    expect(widget.forwardText, 'Legacy next');
  });
  testWidgets('an open selector retains state and focus across reflow', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    double width = 760;
    late StateSetter resize;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) => StatefulBuilder(
                  builder: (_, setState) {
                    resize = setState;
                    return Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: width,
                        child: CarbonPagination(
                          page: 3,
                          pageSize: 10,
                          totalItems: 95,
                          onPageChanged: (_) {},
                          onPageSizeChanged: (_) {},
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    final State<StatefulWidget> state = tester.state(
      find.byType(CarbonSelect<int>).last,
    );
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    resize(() => width = 320);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(CarbonSelect<int>).last), same(state));
    expect(FocusManager.instance.primaryFocus, same(focus));
    expect(find.byType(CarbonListBoxOptionSemantics), findsNWidgets(6));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CarbonListBoxOptionSemantics), findsNothing);
    resize(() => width = 760);
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(CarbonSelect<int>).last), same(state));
    expect(tester.takeException(), isNull);
  });
  testWidgets('page windows stay ordered, unique and bounded at both ends', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    for (final int page in <int>[1, 2, 5, 9999, 10000, 20000]) {
      await tester.pumpWidget(
        KeyedSubtree(
          key: ValueKey<int>(page),
          child: _host(
            CarbonPagination(page: page, pageSize: 10, totalItems: 100000),
          ),
        ),
      );
      final CarbonSelect<int> select = tester
          .widgetList<CarbonSelect<int>>(find.byType(CarbonSelect<int>))
          .last;
      final List<int> values = select.items
          .whereType<CarbonSelectItem<int>>()
          .map((item) => item.value)
          .toList();
      expect(values.length, lessThanOrEqualTo(7));
      expect(values.toSet().length, values.length);
      expect(values, orderedEquals(<int>[...values]..sort()));
      expect(values, contains(select.value));
      expect(values.first, 1);
      expect(values.last, 10000);
      expect(select.value, page.clamp(1, 10000));
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('maximum integer page counts terminate with correct range', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final int maximum = int.parse(
      kIsWeb ? '9007199254740991' : '9223372036854775807',
    );
    await tester.pumpWidget(
      _host(CarbonPagination(page: maximum, pageSize: 1, totalItems: maximum)),
    );
    final CarbonSelect<int> select = tester
        .widgetList<CarbonSelect<int>>(find.byType(CarbonSelect<int>))
        .last;
    expect(select.items.length, 4);
    expect(select.value, maximum);
    expect(find.text('$maximum–$maximum of $maximum items'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('large page numbers are visible without an ellipsis at 2x', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarbonPagination(
          page: 5000,
          pageSize: 10,
          totalItems: 100000,
          onPageChanged: (_) {},
        ),
        width: 320,
        scale: 2,
      ),
    );
    final text = find.text('5000');
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      text,
    );
    final painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      maxLines: 1,
    )..layout(maxWidth: paragraph.size.width);
    expect(painter.didExceedMaxLines, isFalse);
    painter.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets('a horizontal scrolling host supplies a finite bar width', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CarbonPagination(page: 1, pageSize: 10, totalItems: 95),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(CarbonPagination)).width.isFinite,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  for (final double scale in <double>[1, 2]) {
    testWidgets('narrow pagination goldens at $scale', (tester) async {
      await expectThemeGoldens(
        tester,
        name: 'pagination_narrow_$scale',
        containsText: true,
        size: const Size(320, 420),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: CarbonPagination(
                  page: 3,
                  pageSize: 10,
                  totalItems: 95,
                  onPageChanged: (_) {},
                  onPageSizeChanged: (_) {},
                ),
              ),
            ),
          ],
        ),
        afterPump: (tester) async {
          await tester.pumpAndSettle();
          expectNoClippedTextAtScale(tester, scale);
        },
      );
    });
  }
  testWidgets('bounded open page-window goldens', (tester) async {
    await expectThemeGoldens(
      tester,
      name: 'pagination_open_page_window',
      containsText: true,
      size: const Size(320, 600),
      mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2)),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (_) => Align(
              alignment: Alignment.topLeft,
              child: CarbonPagination(
                page: 5000,
                pageSize: 10,
                totalItems: 100000,
                onPageChanged: (_) {},
                onPageSizeChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
      afterPump: (tester) async {
        await tester.tap(find.text('5000'));
        await tester.pumpAndSettle();
        expect(find.byType(CarbonListBoxOptionSemantics), findsNWidgets(7));
        expectNoClippedTextAtScale(tester, 2);
      },
    );
  });
  testWidgets('localized narrow pagination goldens', (tester) async {
    final CarbonPaginationLocalizations labels = CarbonPaginationLocalizations(
      locale: const Locale('de'),
      paginationLabel: 'Seitennavigation',
      itemsPerPageLabel: 'Ergebnisse pro Anzeigeseite',
      pageLabel: 'Anzeigeseite',
      previousPageLabel: 'Zurück',
      nextPageLabel: 'Weiter',
      rangeFormatter: (start, end, total) =>
          '$start–$end von $total Ergebnissen',
      pageCountFormatter: (total) => 'von $total Seiten',
    );
    await expectThemeGoldens(
      tester,
      name: 'pagination_localized_narrow',
      containsText: true,
      size: const Size(320, 440),
      mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2)),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (_) => Align(
              alignment: Alignment.topLeft,
              child: CarbonPagination(
                page: 3,
                pageSize: 10,
                totalItems: 95,
                localizations: labels,
                onPageChanged: (_) {},
                onPageSizeChanged: (_) {},
              ),
            ),
          ),
        ],
      ),
      afterPump: (tester) async {
        await tester.pumpAndSettle();
        expectNoClippedTextAtScale(tester, 2);
      },
    );
  });
}
