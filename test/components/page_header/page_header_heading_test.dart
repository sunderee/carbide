// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    Directionality(
      textDirection: direction,
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(child: SizedBox(width: 320, child: child)),
      ),
    );

void main() {
  testWidgets('native heading node changes only when hierarchy changes', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(const CarbonPageHeader(title: 'Report')));
      final int original = tester.getSemantics(find.text('Report')).id;
      await tester.pumpWidget(_host(const CarbonPageHeader(title: 'Bericht')));
      expect(tester.getSemantics(find.text('Bericht')).id, original);
      await tester.pumpWidget(
        _host(const CarbonPageHeader(title: 'Bericht', headingLevel: 2)),
      );
      expect(tester.getSemantics(find.text('Bericht')).id, isNot(original));
    } finally {
      handle.dispose();
    }
  });
  for (int level = 1; level <= 6; level++) {
    testWidgets('heading level $level preserves title styling', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(CarbonPageHeader(title: 'Report', headingLevel: level)),
        );
        final SemanticsData data = tester
            .getSemantics(find.text('Report'))
            .getSemanticsData();
        expect(data.headingLevel, level);
        expect(data.label, 'Report');
        expect(tester.widget<Text>(find.text('Report')).style!.fontSize, 28);
      } finally {
        handle.dispose();
      }
    });
  }
  for (final int level in <int>[0, 7]) {
    test('heading level $level is rejected', () {
      expect(
        () => CarbonPageHeader(title: 'Report', headingLevel: level),
        throwsAssertionError,
      );
    });
  }
  testWidgets('only the title participates in heading navigation', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          const CarbonPageHeader(
            title: 'Report',
            subtitle: 'Finance',
            body: 'Revenue and spend.',
          ),
        ),
      );
      final List<SemanticsData> headings = <SemanticsData>[];
      void visit(SemanticsNode node) {
        final SemanticsData data = node.getSemanticsData();
        if (data.headingLevel > 0) headings.add(data);
        node.visitChildren((SemanticsNode child) {
          visit(child);
          return true;
        });
      }

      visit(tester.getSemantics(find.byType(CarbonPageHeader)));
      expect(headings.map((SemanticsData data) => data.label), <String>[
        'Report',
      ]);
    } finally {
      handle.dispose();
    }
  });
  testWidgets('localized title and hierarchy update without action callbacks', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    int actions = 0;
    try {
      for (final (String title, int level) in <(String, int)>[
        ('Report', 1),
        ('Bericht', 2),
        ('レポート', 3),
      ]) {
        await tester.pumpWidget(
          _host(
            CarbonPageHeader(
              title: title,
              headingLevel: level,
              pageActions: CarbonButton(
                label: 'Edit',
                onPressed: () => actions++,
              ),
            ),
          ),
        );
        final SemanticsData data = tester
            .getSemantics(find.text(title))
            .getSemanticsData();
        expect(data.label, title);
        expect(data.headingLevel, level);
        expect(find.bySemanticsLabel('Page header'), findsNothing);
      }
      expect(actions, 0);
    } finally {
      handle.dispose();
    }
  });
  testWidgets('page title is a level-one heading with its complete name', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(const CarbonPageHeader(title: 'Quarterly report')),
      );
      final SemanticsData title = tester
          .getSemantics(find.text('Quarterly report'))
          .getSemanticsData();
      expect(title.headingLevel, 1);
      expect(title.label, 'Quarterly report');
    } finally {
      handle.dispose();
    }
  });
  testWidgets('generic English header announcement is removed', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_host(const CarbonPageHeader(title: 'Bericht')));
      expect(find.bySemanticsLabel('Page header'), findsNothing);
      expect(
        tester.getSemantics(find.text('Bericht')).getSemanticsData().label,
        'Bericht',
      );
    } finally {
      handle.dispose();
    }
  });
  testWidgets('subtitle and description remain supporting prose', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          const CarbonPageHeader(
            title: 'Report',
            subtitle: 'Finance',
            body: 'Revenue and spend.',
          ),
        ),
      );
      for (final String label in <String>['Finance', 'Revenue and spend.']) {
        expect(
          tester.getSemantics(find.text(label)).getSemanticsData().headingLevel,
          0,
        );
      }
    } finally {
      handle.dispose();
    }
  });
  for (final TextDirection direction in TextDirection.values) {
    testWidgets('ellipsized title retains full heading name $direction', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        const String title =
            'A very long localized report title that cannot fit';
        await tester.pumpWidget(
          _host(
            CarbonPageHeader(
              title: title,
              pageActions: CarbonButton(label: 'Edit', onPressed: () {}),
            ),
            direction: direction,
          ),
        );
        final SemanticsData data = tester
            .getSemantics(find.text(title))
            .getSemanticsData();
        expect(data.headingLevel, 1);
        expect(data.label, title);
        expect(tester.widget<Text>(find.text(title)).maxLines, 1);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });
  }
}
