// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'controlled selection reanchors without selecting on navigation',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        final _FixtureState state = await _mount(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(
          _day(tester, '16').flagsCollection.isFocused.toBoolOrNull(),
          isTrue,
        );
        expect(
          _day(tester, '15').flagsCollection.isSelected.toBoolOrNull(),
          isTrue,
        );
        expect(
          _day(tester, '16').flagsCollection.isSelected.toBoolOrNull(),
          isFalse,
        );
        expect(state.changes, isEmpty);
        state.update(value: DateTime(2026, 8, 9));
        await tester.pumpAndSettle();
        expect(find.text('August 2026'), findsOneWidget);
        expect(
          _day(tester, '9').flagsCollection.isFocused.toBoolOrNull(),
          isTrue,
        );
        expect(
          _day(tester, '9').flagsCollection.isSelected.toBoolOrNull(),
          isTrue,
        );
        expect(state.changes, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );

  testWidgets('unrelated rebuilds and time-only changes preserve navigation', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    await tester.pump();
    expect(find.text('July 2026'), findsOneWidget);
    state.update();
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);
    state.update(value: DateTime(2026, 6, 15, 17));
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.changes, <DateTime>[DateTime(2026, 7, 6)]);
  });

  testWidgets('range endpoints and mode changes reanchor the focused day', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    state.update(rangeMode: true, range: CarbonDateRange(DateTime(2026, 4, 2)));
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);
    state.update(
      range: CarbonDateRange(DateTime(2026, 4, 2), DateTime(2026, 7, 8)),
    );
    await tester.pumpAndSettle();
    expect(find.text('July 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.rangeChanges.single, CarbonDateRange(DateTime(2026, 7, 8)));
  });

  for (final bool lower in <bool>[false, true]) {
    testWidgets(
      'initial and updated bounds clamp focus at ${lower ? 'lower' : 'upper'} edge',
      (WidgetTester tester) async {
        final _FixtureState state = await _mount(
          tester,
          first: DateTime(2026, 6, 10, 20),
          last: DateTime(2026, 6, 20, 8),
          value: lower ? DateTime(2026, 5, 1) : DateTime(2026, 8, 1),
        );
        expect(find.text('June 2026'), findsOneWidget);
        for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
          lower ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight,
          lower ? LogicalKeyboardKey.arrowUp : LogicalKeyboardKey.arrowDown,
          lower ? LogicalKeyboardKey.pageUp : LogicalKeyboardKey.pageDown,
        ]) {
          for (int i = 0; i < 4; i++) {
            await tester.sendKeyEvent(key);
          }
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(state.changes.single, DateTime(2026, 6, lower ? 10 : 20));
        state.update(first: DateTime(2027, 1, 5), last: DateTime(2027, 1, 7));
        await tester.pumpAndSettle();
        expect(find.text('January 2027'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(state.changes.last, DateTime(2027, 1, 5));
      },
    );
  }

  testWidgets('bounds narrowing clamps current navigation, not old selection', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    state.update(first: DateTime(2026, 6, 18), last: DateTime(2026, 6, 20));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(state.changes.single, DateTime(2026, 6, 20));
    expect(state.value, DateTime(2026, 6, 15));
  });

  testWidgets(
    'month chevrons disable at bounds and stale actions recheck them',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        final _FixtureState state = await _mount(
          tester,
          first: DateTime(2026, 6, 10),
          last: DateTime(2026, 8, 20),
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Previous month'))
              .flagsCollection
              .isEnabled
              .toBoolOrNull(),
          isFalse,
        );
        final VoidCallback stale = tester
            .widget<Semantics>(find.bySemanticsLabel('Next month'))
            .properties
            .onTap!;
        state.update(last: DateTime(2026, 6, 20));
        await tester.pumpAndSettle();
        stale();
        await tester.tap(find.bySemanticsLabel('Next month'));
        await tester.pumpAndSettle();
        expect(find.text('June 2026'), findsOneWidget);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Next month'))
              .flagsCollection
              .isEnabled
              .toBoolOrNull(),
          isFalse,
        );
        expect(state.changes, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );

  for (final (int year, int end) in <(int, int)>[(2026, 28), (2028, 29)]) {
    testWidgets('Page keys preserve the civil day and clamp February $year', (
      WidgetTester tester,
    ) async {
      final _FixtureState state = await _mount(
        tester,
        value: DateTime(year, 1, 31),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      expect(find.text('February $year'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(state.changes.single, DateTime(year, 2, end));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(state.changes.last, DateTime(year, 1, end));
    });
  }

  testWidgets('civil-day navigation does not repeat dates at daylight saving', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(
      tester,
      value: DateTime(2026, 10, 23),
    );
    for (int i = 24; i <= 28; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(state.changes.last, DateTime(2026, 10, i));
    }
  });
  testWidgets(
    'a one-day window ignores time-of-day order and blocks navigation',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(
        tester,
        value: DateTime(2026, 6, 20, 12),
        first: DateTime(2026, 6, 20, 20),
        last: DateTime(2026, 6, 20, 8),
      );
      for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.pageUp,
        LogicalKeyboardKey.pageDown,
      ]) {
        await tester.sendKeyEvent(key);
      }
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(state.changes, <DateTime>[DateTime(2026, 6, 20)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reversed civil-day bounds fail with a clear assertion', (
    WidgetTester tester,
  ) async {
    await _mount(
      tester,
      first: DateTime(2026, 6, 21),
      last: DateTime(2026, 6, 20),
    );
    final Object? exception = tester.takeException();
    expect(exception, isAssertionError);
    expect(
      exception.toString(),
      contains('firstDate must not be after lastDate'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Future<_FixtureState> _mount(
  WidgetTester tester, {
  DateTime? value,
  DateTime? first,
  DateTime? last,
}) async {
  final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (_, _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: 320,
            child: _Fixture(
              key: key,
              initialValue: value ?? DateTime(2026, 6, 15),
              first: first,
              last: last,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

class _Fixture extends StatefulWidget {
  const _Fixture({
    super.key,
    required this.initialValue,
    this.first,
    this.last,
  });
  final DateTime initialValue;
  final DateTime? first;
  final DateTime? last;
  @override
  State<_Fixture> createState() => _FixtureState();
}

const Object _unchanged = Object();

class _FixtureState extends State<_Fixture> {
  late DateTime? value = widget.initialValue;
  late DateTime? first = widget.first;
  late DateTime? last = widget.last;
  bool rangeMode = false;
  CarbonDateRange? range;
  final List<DateTime> changes = <DateTime>[];
  final List<CarbonDateRange> rangeChanges = <CarbonDateRange>[];
  void update({
    Object? value = _unchanged,
    Object? first = _unchanged,
    Object? last = _unchanged,
    Object? range = _unchanged,
    bool? rangeMode,
  }) => setState(() {
    if (value != _unchanged) this.value = value as DateTime?;
    if (first != _unchanged) this.first = first as DateTime?;
    if (last != _unchanged) this.last = last as DateTime?;
    if (range != _unchanged) this.range = range as CarbonDateRange?;
    this.rangeMode = rangeMode ?? this.rangeMode;
  });
  @override
  Widget build(BuildContext context) => CarbonCalendar(
    value: rangeMode ? null : value,
    range: rangeMode ? range : null,
    onChanged: rangeMode ? null : changes.add,
    onRangeChanged: rangeMode ? rangeChanges.add : null,
    firstDate: first,
    lastDate: last,
    autofocus: true,
  );
}

SemanticsNode _day(WidgetTester tester, String day) =>
    tester.getSemantics(find.bySemanticsLabel(day));
