// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show Tristate;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

const List<String> _labels = <String>[
  'Home',
  'Organization',
  'Projects',
  'Research',
  'Reports',
  'Quarter',
  'Here',
];

List<CarbonBreadcrumbItem> _items(List<int> calls) => <CarbonBreadcrumbItem>[
  for (int i = 0; i < _labels.length; i++)
    CarbonBreadcrumbItem(
      label: _labels[i],
      onPressed: () => calls.add(i),
      isCurrentPage: i == _labels.length - 1,
    ),
];

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (BuildContext context, _, _) => builder(context),
      ),
  home: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

FocusNode _triggerFocus(WidgetTester tester) => Focus.of(
  tester.element(
    find
        .descendant(
          of: find.byType(CarbonOverflowMenu),
          matching: find.byType(CarbonIcon),
        )
        .first,
  ),
);

void main() {
  testWidgets('localized region, trigger and current-page names', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          CarbonBreadcrumb(
            items: _items(<int>[]),
            breadcrumbLabel: 'Fil d’Ariane',
            overflowLabel: 'Autres pages',
            currentPageLabel: 'Page actuelle',
          ),
          width: 160,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Fil d’Ariane'), findsOneWidget);
      expect(find.bySemanticsLabel('Autres pages'), findsOneWidget);
      expect(find.bySemanticsLabel('Here, Page actuelle'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  for (final double width in <double>[0, 16, 40, 80]) {
    testWidgets('extreme constraints remain bounded width=$width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonBreadcrumb(items: _items(<int>[])), width: width),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CarbonBreadcrumb)).width,
        lessThanOrEqualTo(width),
      );
      expect(
        tester.getSize(find.byType(CarbonBreadcrumb)).height,
        lessThanOrEqualTo(24),
      );
    });
  }

  testWidgets('font notifications remeasure and release their listener', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CarbonBreadcrumb(items: _items(<int>[]))));
    await tester.pumpAndSettle();
    await tester.binding.handleSystemMessage(<String, dynamic>{
      'type': 'fontsChange',
    });
    await tester.pumpAndSettle();
    expect(find.byType(CarbonOverflowMenu), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.handleSystemMessage(<String, dynamic>{
      'type': 'fontsChange',
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a noninteractive hidden crumb remains a disabled named row', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          CarbonBreadcrumb(
            items: <CarbonBreadcrumbItem>[
              CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
              const CarbonBreadcrumbItem(label: 'Unavailable ancestor'),
              CarbonBreadcrumbItem(label: 'Enabled ancestor', onPressed: () {}),
              const CarbonBreadcrumbItem(label: 'Here', isCurrentPage: true),
            ],
          ),
          width: 160,
        ),
      );
      await tester.pumpAndSettle();
      _triggerFocus(tester).requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.enter);
      final Finder row = find.widgetWithText(
        CarbonMenuItem,
        'Unavailable ancestor',
      );
      expect(row, findsOneWidget);
      expect(
        tester.getSemantics(row).getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      await _key(tester, LogicalKeyboardKey.escape);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('unbounded trails retain every crumb without a menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: CarbonBreadcrumb(items: _items(<int>[])),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CarbonOverflowMenu), findsNothing);
    for (final String label in _labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  for (final TextDirection direction in TextDirection.values) {
    for (final CarbonLinkSize size in CarbonLinkSize.values) {
      for (final double scale in <double>[1, 2]) {
        testWidgets(
          '320px collapse is one line $direction $size scale=$scale',
          (WidgetTester tester) async {
            final List<int> calls = <int>[];
            await tester.pumpWidget(
              _host(
                CarbonBreadcrumb(items: _items(calls), size: size),
                direction: direction,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(CarbonOverflowMenu), findsOneWidget);
            expect(find.byType(Wrap), findsNothing);
            expect(find.text('Home'), findsOneWidget);
            expect(find.text('Here'), findsOneWidget);
            final Rect first = tester.getRect(find.text('Home'));
            final Rect last = tester.getRect(find.text('Here'));
            expect(first.center.dy, closeTo(last.center.dy, 6));
            if (direction == TextDirection.ltr) {
              expect(first.left, lessThan(last.left));
            } else {
              expect(first.left, greaterThan(last.left));
            }
            expect(calls, isEmpty);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('every hidden crumb is reachable by keyboard and reports once', (
    WidgetTester tester,
  ) async {
    final List<int> calls = <int>[];
    await tester.pumpWidget(
      _host(CarbonBreadcrumb(items: _items(calls)), width: 160),
    );
    await tester.pumpAndSettle();
    final List<int> hidden = <int>[
      for (int i = 1; i < _labels.length - 1; i++)
        if (find.text(_labels[i]).evaluate().isEmpty) i,
    ];
    expect(hidden, isNotEmpty);
    for (int row = 0; row < hidden.length; row++) {
      final FocusNode trigger = _triggerFocus(tester);
      trigger.requestFocus();
      await tester.pump();
      await _key(
        tester,
        row.isEven ? LogicalKeyboardKey.enter : LogicalKeyboardKey.space,
      );
      expect(find.byType(CarbonMenu), findsOneWidget);
      for (final int index in hidden) {
        expect(
          find.widgetWithText(CarbonMenuItem, _labels[index]),
          findsOneWidget,
        );
      }
      await _key(tester, LogicalKeyboardKey.home);
      for (int step = 0; step < row; step++) {
        await _key(tester, LogicalKeyboardKey.arrowDown);
      }
      await _key(tester, LogicalKeyboardKey.enter);
      expect(calls, hidden.take(row + 1).toList());
      expect(find.byType(CarbonMenu), findsNothing);
      expect(trigger.hasPrimaryFocus, isTrue);
    }
  });

  testWidgets('current page is selected plain text even with a callback', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final List<int> calls = <int>[];
      await tester.pumpWidget(
        _host(CarbonBreadcrumb(items: _items(calls)), width: 160),
      );
      await tester.pumpAndSettle();
      final SemanticsNode current = tester.getSemantics(find.text('Here'));
      expect(current.getSemanticsData().label, 'Here, Current page');
      expect(
        current.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(current.getSemanticsData().flagsCollection.isLink, isFalse);
      await tester.tap(find.text('Here'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('resizing a collapsed open trail removes its menu safely', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1800, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final List<int> calls = <int>[];
    final Widget breadcrumb = CarbonBreadcrumb(items: _items(calls));
    await tester.pumpWidget(_host(breadcrumb, width: 160));
    await tester.pumpAndSettle();
    _triggerFocus(tester).requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.enter);
    expect(find.byType(CarbonMenu), findsOneWidget);
    await tester.pumpWidget(_host(breadcrumb, width: 1500));
    await tester.pumpAndSettle();
    expect(find.byType(CarbonMenu), findsNothing);
    expect(find.byType(CarbonOverflowMenu), findsNothing);
    for (final String label in _labels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(_host(breadcrumb, width: 160));
    await tester.pumpAndSettle();
    expect(find.byType(CarbonOverflowMenu), findsOneWidget);
  });

  for (final int count in <int>[0, 1, 2]) {
    testWidgets('short trails remain stable at narrow widths count=$count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonBreadcrumb(
            items: <CarbonBreadcrumbItem>[
              for (int i = 0; i < count; i++)
                CarbonBreadcrumbItem(
                  label: 'A very long level $i',
                  isCurrentPage: i == count - 1,
                ),
            ],
          ),
          width: 80,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CarbonOverflowMenu), findsNothing);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CarbonBreadcrumb)).height,
        lessThanOrEqualTo(24),
      );
    });
  }

  testWidgets('long anchors ellipsize within one line and retain full names', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          CarbonBreadcrumb(
            items: <CarbonBreadcrumbItem>[
              CarbonBreadcrumbItem(
                label: 'Very long organization home',
                onPressed: () {},
              ),
              CarbonBreadcrumbItem(label: 'Hidden project', onPressed: () {}),
              const CarbonBreadcrumbItem(
                label: 'Very long current report name',
                isCurrentPage: true,
              ),
            ],
          ),
          width: 160,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CarbonOverflowMenu), findsOneWidget);
      expect(
        find.bySemanticsLabel('Very long organization home'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Very long current report name, Current page'),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(CarbonBreadcrumb)).height,
        lessThanOrEqualTo(24),
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  for (final bool trailing in <bool>[false, true]) {
    testWidgets('narrow breadcrumbs noTrailingSlash=$trailing goldens', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'breadcrumb_narrow_${trailing ? 'no_trailing' : 'trailing'}',
        containsText: true,
        size: const Size(320, 72),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (BuildContext context) => Center(
          child: CarbonBreadcrumb(
            items: _items(<int>[]),
            noTrailingSlash: trailing,
          ),
        ),
      );
    });
  }
}
