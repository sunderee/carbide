// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/a11y.dart';
import '../../support/legibility.dart';
import '../../support/overlay_entries.dart';

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  builder: (BuildContext context, Widget? _) => Directionality(
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
  testWidgets(
    'custom font and label changes recompute exact hidden membership',
    (WidgetTester tester) async {
      double fontSize = 12;
      String label = 'WWWWWW';
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              update = setState;
              return CarbonPageHeader(
                title: 'Report',
                collapseTags: true,
                tags: <Widget>[
                  const CarbonTag(key: ValueKey<String>('first'), label: 'One'),
                  Text(
                    label,
                    key: const ValueKey<String>('custom'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CarbonTypeStyles.label01.copyWith(
                      fontSize: fontSize,
                    ),
                  ),
                  const CarbonTag(key: ValueKey<String>('last'), label: 'Two'),
                ],
              );
            },
          ),
          width: 240,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^\+\d+$')), findsNothing);
      update(() => fontSize = 40);
      await tester.pumpAndSettle();
      expect(find.text('+2'), findsOneWidget);
      update(() {
        fontSize = 12;
        label = 'I';
      });
      await tester.pumpAndSettle();
      expect(find.textContaining(RegExp(r'^\+\d+$')), findsNothing);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('count has a named AT activation action and restores focus', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          CarbonPageHeader(
            title: 'Report',
            tags: _tags(<String>[]),
            collapseTags: true,
            tagsOverflowLabel: (int count) => '$count weitere Schlagwörter',
            tagsDisclosureLabel: 'Weitere Schlagwörter',
          ),
          width: 160,
        ),
      );
      await tester.pumpAndSettle();
      final int hidden = int.parse(
        tester
            .widget<Text>(find.textContaining(RegExp(r'^\+\d+$')))
            .data!
            .substring(1),
      );
      final SemanticsNode count = tester.getSemantics(
        find.bySemanticsLabel('$hidden weitere Schlagwörter'),
      );
      expect(count.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: count.id,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Weitere Schlagwörter'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<CarbonOperationalTag>()!
            .label,
        'View regional report',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      final CarbonOperationalTag trigger = tester
          .widgetList<CarbonOperationalTag>(find.byType(CarbonOperationalTag))
          .singleWhere((CarbonOperationalTag tag) => tag.label.startsWith('+'));
      expect(trigger.focusNode!.hasFocus, isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    'custom keyed tag retains one state through disclosure and reorder',
    (WidgetTester tester) async {
      final GlobalKey<_CounterTagState> key = GlobalKey<_CounterTagState>();
      final List<String> lifecycle = <String>[];
      bool reversed = false;
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              update = setState;
              final List<Widget> tags = <Widget>[
                const CarbonTag(
                  key: ValueKey<String>('first'),
                  label: 'Finance',
                ),
                const CarbonTag(
                  key: ValueKey<String>('long'),
                  label: 'A deliberately long region',
                ),
                _CounterTag(key: key, lifecycle: lifecycle),
              ];
              return CarbonPageHeader(
                title: 'Report',
                collapseTags: true,
                tags: reversed ? tags.reversed.toList() : tags,
              );
            },
          ),
          width: 160,
        ),
      );
      await tester.pumpAndSettle();
      final _CounterTagState original = key.currentState!;
      original.increment();
      await tester.pumpAndSettle();
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.textContaining(RegExp(r'^\+\d+$')));
        await tester.pumpAndSettle();
        expect(key.currentState, same(original));
        expect(find.text('Custom 1'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(key.currentState, same(original));
      }
      update(() => reversed = true);
      await tester.pumpAndSettle();
      expect(key.currentState, same(original));
      expect(lifecycle, <String>['created']);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(lifecycle, <String>['created', 'disposed']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('legacy tags wrap; collapse is opt-in', (tester) async {
    await tester.pumpWidget(
      _host(CarbonPageHeader(title: 'Report', tags: _tags([]))),
    );
    expect(find.byType(Wrap), findsOneWidget);
    expect(find.text('View regional report'), findsOneWidget);
    expect(find.text('+2'), findsNothing);
  });
  for (final direction in TextDirection.values) {
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
            // At 1x this action fits inline. Its outside tap dismisses the
            // popover, so reopen before exercising the hidden dismiss action.
            if (find.bySemanticsLabel('Dismiss Draft').evaluate().isEmpty) {
              await tester.tap(count);
              await tester.pumpAndSettle();
            }
            await tester.tap(find.bySemanticsLabel('Dismiss Draft'));
            await tester.pumpAndSettle();
            expect(calls, ['view', 'dismiss']);
            expectNoClippedTextAtScale(tester, scale);
            // Carbon's md tags/close affordance use 24px density:
            // styles/scss/components/tag/_tag.scss. Keep name checks active.
            await expectA11y(tester, tapTargets: false);
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

class _CounterTag extends StatefulWidget {
  const _CounterTag({required this.lifecycle, super.key});
  final List<String> lifecycle;
  @override
  State<_CounterTag> createState() => _CounterTagState();
}

class _CounterTagState extends State<_CounterTag> {
  int count = 0;
  @override
  void initState() {
    super.initState();
    widget.lifecycle.add('created');
  }

  void increment() => setState(() => count++);
  @override
  void dispose() {
    widget.lifecycle.add('disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CarbonOperationalTag(label: 'Custom $count', onPressed: increment);
}
