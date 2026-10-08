// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';
import '../../support/overlay_entries.dart';

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: [
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

List<Widget> _tags(List<String> calls) => [
  const CarbonTag(
    key: ValueKey('a'),
    label: 'Finance',
    type: CarbonTagType.blue,
  ),
  CarbonOperationalTag(
    key: const ValueKey('b'),
    label: 'View regional report',
    onPressed: () => calls.add('view'),
  ),
  CarbonDismissibleTag(
    key: const ValueKey('c'),
    label: 'Draft',
    onClose: () => calls.add('dismiss'),
  ),
  const CarbonTag(
    key: ValueKey('d'),
    label: 'Reviewed',
    type: CarbonTagType.green,
  ),
];

void main() {
  testWidgets('legacy tags wrap; collapse is opt-in', (tester) async {
    await tester.pumpWidget(
      _host(CarbonPageHeader(title: 'Report', tags: _tags([]))),
    );
    expect(find.byType(Wrap), findsOneWidget);
    expect(find.text('View regional report'), findsOneWidget);
    expect(find.text('+2'), findsNothing);
  });
  for (final direction in TextDirection.values)
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'measured membership and full hidden labels $direction $scale',
        (tester) async {
          final calls = <String>[];
          final handle = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              _host(
                CarbonPageHeader(
                  title: 'Report',
                  tags: _tags(calls),
                  collapseTags: true,
                ),
                direction: direction,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text('Finance'), findsOneWidget);
            expect(find.text('Reviewed'), findsNothing);
            final count = find.textContaining(RegExp(r'^\+\d+$'));
            expect(count, findsOneWidget);
            final hidden = int.parse(
              tester.widget<Text>(count).data!.substring(1),
            );
            final visible =
                find.byType(CarbonTag).evaluate().length +
                find.byType(CarbonDismissibleTag).evaluate().length +
                find.byType(CarbonOperationalTag).evaluate().length -
                1;
            expect(visible + hidden, 4);
            await tester.tap(count);
            await tester.pumpAndSettle();
            expect(find.text('Reviewed'), findsOneWidget);
            expect(find.text('View regional report'), findsOneWidget);
            expect(find.text('Draft'), findsOneWidget);
            await tester.tap(find.text('View regional report'));
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsLabel('Dismiss Draft'));
            await tester.pumpAndSettle();
            expect(calls, ['view', 'dismiss']);
            expectNoClippedTextAtScale(tester, scale);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            expect(find.text('Reviewed'), findsNothing);
            expect(find.bySemanticsLabel('$hidden more tags'), findsOneWidget);
          } finally {
            handle.dispose();
          }
        },
      );
    }
  testWidgets(
    'tag resize and live labels preserve children without callbacks',
    (tester) async {
      var width = 160.0, scale = 1.0;
      late StateSetter update;
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return SizedBox(
                  width: width,
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: CarbonPageHeader(
                      title: 'Report',
                      collapseTags: true,
                      tags: _tags(calls),
                    ),
                  ),
                );
              },
            ),
          ),
          width: 760,
        ),
      );
      await tester.pumpAndSettle();
      final count = find.textContaining(RegExp(r'^\+\d+$'));
      await tester.tap(count);
      await tester.pumpAndSettle();
      expect(find.text('Reviewed'), findsOneWidget);
      update(() => width = 760);
      await tester.pumpAndSettle();
      expect(count, findsNothing);
      expect(find.text('Reviewed'), findsOneWidget);
      update(() {
        width = 320;
        scale = 2;
      });
      await tester.pumpAndSettle();
      expect(count, findsOneWidget);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'long and single tags disclose full text without duplicate mounting',
    (tester) async {
      const title = 'A very long informative tag that must remain recoverable';
      await tester.pumpWidget(
        _host(
          const CarbonPageHeader(
            title: 'Report',
            collapseTags: true,
            tags: [CarbonTag(key: ValueKey('long'), label: title)],
          ),
          width: 160,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+1'), findsOneWidget);
      await tester.tap(find.text('+1'));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('empty and fitting tags add no disclosure', (tester) async {
    for (final tags in <List<Widget>>[
      [],
      [const CarbonTag(label: 'One')],
    ]) {
      await tester.pumpWidget(
        _host(
          CarbonPageHeader(title: 'Report', collapseTags: true, tags: tags),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^\+\d+$')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
  for (final (name, width, scale, open) in [
    ('fitting', 760.0, 1.0, false),
    ('overflow', 320.0, 1.3, false),
    ('open', 320.0, 2.0, true),
  ]) {
    testWidgets('golden tag overflow $name', (tester) async {
      await expectThemeGoldens(
        tester,
        name: 'page_header_tags_$name',
        size: Size(width, 440),
        containsText: true,
        directions: TextDirection.values.toSet(),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
        builder: (_) => Overlay(
          initialEntries: [
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: CarbonPageHeader(
                  title: 'Report',
                  collapseTags: true,
                  tags: _tags([]),
                ),
              ),
            ),
          ],
        ),
        afterPump: (tester) async {
          await tester.pumpAndSettle();
          if (open) {
            await tester.tap(find.textContaining(RegExp(r'^\+\d+$')));
            await tester.pumpAndSettle();
          }
        },
      );
    });
  }
}
