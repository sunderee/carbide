// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/legibility.dart';

const String _title = 'Quarterly report with a deliberately long title';

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xff000000),
  builder: (BuildContext context, Widget? _) => MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: Directionality(
      textDirection: direction,
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

List<CarbonPageHeaderAction> _actions(List<String> calls) =>
    <CarbonPageHeaderAction>[
      CarbonPageHeaderAction(
        id: 'edit',
        label: 'Edit report',
        onPressed: () => calls.add('edit'),
      ),
      CarbonPageHeaderAction(
        id: 'download',
        label: 'Download report',
        kind: CarbonButtonKind.secondary,
        onPressed: () => calls.add('download'),
      ),
      const CarbonPageHeaderAction(
        id: 'archive',
        label: 'Archive report',
        kind: CarbonButtonKind.tertiary,
      ),
    ];

void main() {
  testWidgets(
    'structured actions are opt-in and reject ambiguous composition',
    (WidgetTester tester) async {
      expect(
        () => CarbonPageHeader(
          title: 'Report',
          pageActions: const Text('Custom'),
          actions: _actions(<String>[]),
        ),
        throwsAssertionError,
      );
      await tester.pumpWidget(
        _host(
          const CarbonPageHeader(title: 'Report', pageActions: Text('Custom')),
        ),
      );
      expect(find.text('Custom'), findsOneWidget);
      expect(find.byType(CarbonOverflowMenu), findsNothing);
    },
  );

  testWidgets('unique action identity is required', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonPageHeader(
          title: 'Report',
          actions: <CarbonPageHeaderAction>[
            CarbonPageHeaderAction(id: 'same', label: 'A'),
            CarbonPageHeaderAction(id: 'same', label: 'B'),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('wide actions preserve names, kinds, order and callbacks', (
    WidgetTester tester,
  ) async {
    final List<String> calls = <String>[];
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _host(
        CarbonPageHeader(title: 'Report', actions: _actions(calls)),
        width: 1100,
      ),
    );
    expect(find.byType(CarbonOverflowMenu), findsNothing);
    expect(find.text('Edit report'), findsOneWidget);
    expect(find.text('Download report'), findsOneWidget);
    final CarbonButton disabled = tester.widget<CarbonButton>(
      find.widgetWithText(CarbonButton, 'Archive report'),
    );
    expect(disabled.onPressed, isNull);
    expect(disabled.kind, CarbonButtonKind.tertiary);
    await tester.tap(find.text('Edit report'));
    await tester.tap(find.text('Download report'));
    await tester.tap(find.text('Archive report'));
    expect(calls, <String>['edit', 'download']);
  });

  for (final TextDirection direction in TextDirection.values) {
    for (final double scale in <double>[1, 1.3, 2]) {
      testWidgets(
        'narrow actions retain usable title and menu $direction $scale',
        (WidgetTester tester) async {
          final List<String> calls = <String>[];
          final SemanticsHandle handle = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              _host(
                CarbonPageHeader(title: _title, actions: _actions(calls)),
                scale: scale,
                direction: direction,
              ),
            );
            expect(tester.takeException(), isNull);
            expectNoClippedTextAtScale(tester, scale);
            final Rect title = tester.getRect(find.text(_title));
            expect(title.width, greaterThan(200));
            expect(
              tester.getRect(find.text('Edit report')).top,
              greaterThanOrEqualTo(title.bottom),
            );
            expect(
              tester.getSemantics(find.text(_title)).getSemanticsData().label,
              _title,
            );
            expect(
              tester
                  .getSemantics(find.text(_title))
                  .getSemanticsData()
                  .headingLevel,
              1,
            );
            expect(find.text('Download report'), findsNothing);
            await tester.tap(find.bySemanticsLabel('More page actions'));
            await tester.pumpAndSettle();
            expect(find.text('Download report'), findsOneWidget);
            expect(find.text('Archive report'), findsOneWidget);
            final CarbonMenuItem disabled = tester.widget<CarbonMenuItem>(
              find.widgetWithText(CarbonMenuItem, 'Archive report'),
            );
            expect(disabled.disabled, isTrue);
            // Carbon's md action button is 40px and sm menu rows are 32px:
            // styles/scss/components/{button,menu}/_*.scss.
            await expectA11y(tester, tapTargets: false);
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(calls, <String>['download']);
            expect(find.byType(CarbonMenu), findsNothing);
            expect(
              FocusManager.instance.primaryFocus!.context!
                  .findAncestorWidgetOfExactType<CarbonButton>(),
              isNotNull,
            );
          } finally {
            handle.dispose();
          }
        },
      );
    }
  }

  testWidgets(
    'resize keeps menu ownership, Escape and focus without callbacks',
    (WidgetTester tester) async {
      final List<String> calls = <String>[];
      double width = 320;
      late StateSetter update;
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            update = setState;
            return _host(
              CarbonPageHeader(title: _title, actions: _actions(calls)),
              width: width,
            );
          },
        ),
      );
      await tester.tap(find.bySemanticsLabel('More page actions'));
      await tester.pumpAndSettle();
      update(() => width = 500);
      await tester.pumpAndSettle();
      expect(find.byType(CarbonMenu), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CarbonMenu), findsNothing);
      update(() => width = 1100);
      await tester.pumpAndSettle();
      expect(find.byType(CarbonOverflowMenu), findsNothing);
      expect(find.text('Download report'), findsOneWidget);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('very narrow hosts disclose even primary actions', (
    WidgetTester tester,
  ) async {
    final List<String> calls = <String>[];
    await tester.pumpWidget(
      _host(
        CarbonPageHeader(title: _title, actions: _actions(calls)),
        width: 160,
        scale: 2,
      ),
    );
    expect(find.text('Edit report'), findsNothing);
    await tester.tap(find.bySemanticsLabel('More page actions'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<CarbonMenuItem>(find.byType(CarbonMenuItem))
          .map((CarbonMenuItem item) => item.label),
      <String>['Edit report', 'Download report', 'Archive report'],
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, <String>['edit']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty structured actions add no chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonPageHeader(
          title: 'Report',
          actions: <CarbonPageHeaderAction>[],
        ),
      ),
    );
    expect(find.byType(CarbonButton), findsNothing);
    expect(find.byType(CarbonOverflowMenu), findsNothing);
    expect(tester.widget<Text>(find.text('Report')).maxLines, 2);
  });

  for (final (String name, double width, double scale, bool open)
      in <(String, double, double, bool)>[
        ('wide', 1100, 1, false),
        ('narrow', 320, 1.3, false),
        ('stress', 320, 2, false),
        ('open', 320, 2, true),
      ]) {
    testWidgets('golden responsive actions $name', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'page_header_actions_$name',
        size: Size(width, 440),
        containsText: true,
        directions: TextDirection.values.toSet(),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
        builder: (BuildContext context) => WidgetsApp(
          color: const Color(0xff000000),
          builder: (BuildContext context, Widget? _) => Align(
            alignment: Alignment.topLeft,
            child: CarbonPageHeader(
              title: _title,
              actions: _actions(<String>[]),
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          if (open) {
            await tester.tap(find.bySemanticsLabel('More page actions'));
          }
          await tester.pumpAndSettle();
        },
      );
    });
  }
}
