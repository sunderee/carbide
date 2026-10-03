// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';

void main() {
  for (final (String name, CarbonDateRange? snapshot)
      in <(String, CarbonDateRange?)>[
        ('null', null),
        (
          'complete',
          CarbonDateRange(DateTime(2026, 6, 10), DateTime(2026, 6, 12)),
        ),
        ('partial', CarbonDateRange(DateTime(2026, 6, 10))),
      ]) {
    for (final String path in <String>[
      'Escape',
      'outside',
      'start toggle',
      'end toggle',
      'disabled',
      'request close',
    ]) {
      testWidgets(
        '$path cancels a draft against a $name snapshot without notifications',
        (WidgetTester tester) async {
          final _FixtureState state = await _mount(tester, value: snapshot);
          await tester.tap(find.text('Start date'));
          await tester.pumpAndSettle();
          final String heading = _heading(tester);
          final CarbonCalendar calendar = tester.widget<CarbonCalendar>(
            find.byType(CarbonCalendar),
          );
          final VoidCallback oldClose = tester
              .widget<CarbonPopover>(find.byType(CarbonPopover))
              .onRequestClose!;
          // Selecting a day earlier than the snapshot restarts a partial range.
          await tester.tap(find.text('5'));
          await tester.pumpAndSettle();
          expect(state.value, snapshot);
          expect(state.changes, isEmpty);
          expect(
            tester
                .widget<CarbonCalendar>(find.byType(CarbonCalendar))
                .range
                ?.end,
            isNull,
          );
          expect(
            tester
                .widget<CarbonCalendar>(find.byType(CarbonCalendar))
                .range
                ?.start
                .day,
            5,
          );
          switch (path) {
            case 'Escape':
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            case 'outside':
              await tester.tapAt(const Offset(700, 500));
            case 'start toggle':
              await tester.tap(find.text('Start date'));
            case 'end toggle':
              await tester.tap(find.text('End date'));
            case 'disabled':
              state.update(disabled: true);
            case 'request close':
              tester
                  .widget<CarbonPopover>(find.byType(CarbonPopover))
                  .onRequestClose!();
          }
          await tester.pumpAndSettle();
          expect(find.byType(CarbonCalendar), findsNothing);
          expect(state.value, snapshot);
          expect(state.changes, isEmpty);
          if (path != 'disabled') {
            expect(
              FocusManager.instance.primaryFocus?.debugLabel,
              'CarbonDateRangePicker.start',
            );
          }
          // Events retained by the detached calendar must not restart a session.
          calendar.onRangeChanged!(
            CarbonDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 2)),
          );
          await tester.pumpAndSettle();
          expect(state.changes, isEmpty);
          if (path == 'disabled') state.update(disabled: false);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Start date'));
          await tester.pumpAndSettle();
          expect(_heading(tester), heading);
          expect(
            tester.widget<CarbonCalendar>(find.byType(CarbonCalendar)).range,
            snapshot,
          );
          calendar.onRangeChanged!(
            CarbonDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 2)),
          );
          calendar.onEscape!();
          oldClose();
          await tester.pumpAndSettle();
          expect(find.byType(CarbonCalendar), findsOneWidget);
          expect(state.changes, isEmpty);
        },
      );
    }
  }

  for (final bool end in <bool>[false, true]) {
    testWidgets(
      'completion notifies once and returns focus to ${end ? 'end' : 'start'} opener',
      (WidgetTester tester) async {
        final _FixtureState state = await _mount(tester);
        await tester.tap(find.text(end ? 'End date' : 'Start date'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('10'));
        await tester.pumpAndSettle();
        expect(state.changes, isEmpty);
        final CarbonCalendar calendar = tester.widget<CarbonCalendar>(
          find.byType(CarbonCalendar),
        );
        final DateTime start = calendar.range!.start;
        final CarbonDateRange committed = CarbonDateRange(
          start,
          DateTime(start.year, start.month, 20),
        );
        await tester.tap(find.text('20'));
        await tester.pumpAndSettle();
        expect(state.changes, <CarbonDateRange>[committed]);
        expect(state.value, committed);
        expect(find.byType(CarbonCalendar), findsNothing);
        expect(
          FocusManager.instance.primaryFocus?.debugLabel,
          'CarbonDateRangePicker.${end ? 'end' : 'start'}',
        );
        calendar.onRangeChanged!(committed);
        calendar.onEscape!();
        await tester.pumpAndSettle();
        expect(state.changes, <CarbonDateRange>[committed]);
      },
    );
  }

  testWidgets('restarts and unrelated rebuilds preserve the local draft', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    await tester.tap(find.text('Start date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    final CarbonDateRange draft = tester
        .widget<CarbonCalendar>(find.byType(CarbonCalendar))
        .range!;
    state.update();
    await tester.pumpAndSettle();
    expect(
      tester.widget<CarbonCalendar>(find.byType(CarbonCalendar)).range,
      draft,
    );
    expect(draft.start.day, 5);
    expect(state.value, isNull);
    expect(state.changes, isEmpty);
  });

  testWidgets('new external values rebase a session without notifying', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    await tester.tap(find.text('Start date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    final CarbonDateRange replacement = CarbonDateRange(
      DateTime(2027, 2, 10),
      DateTime(2027, 2, 15),
    );
    state.update(value: replacement);
    await tester.pumpAndSettle();
    expect(find.text('February 2027'), findsOneWidget);
    expect(
      tester.widget<CarbonCalendar>(find.byType(CarbonCalendar)).range,
      replacement,
    );
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(state.value, replacement);
    expect(state.changes, isEmpty);
  });

  testWidgets(
    'external clearing keeps a null snapshot distinct from no session',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(
        tester,
        value: CarbonDateRange(DateTime(2026, 6, 10), DateTime(2026, 6, 12)),
      );
      await tester.tap(find.text('Start date'));
      await tester.pumpAndSettle();
      state.update(value: null);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(state.value, isNull);
      expect(state.changes, isEmpty);
    },
  );

  testWidgets(
    'single-picker outside dismissal returns focus from its calendar',
    (WidgetTester tester) async {
      await _mount(tester, single: true);
      await tester.tap(find.text('06/15/2026'));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'CarbonCalendar');
      await tester.tapAt(const Offset(700, 500));
      await tester.pumpAndSettle();
      expect(find.byType(CarbonCalendar), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'CarbonDatePicker',
      );
    },
  );
  testWidgets('narrowed bounds discard invalid drafts and gate late commits', (
    WidgetTester tester,
  ) async {
    final CarbonDateRange initial = CarbonDateRange(
      DateTime(2026, 6, 10),
      DateTime(2026, 6, 12),
    );
    final _FixtureState state = await _mount(tester, value: initial);
    await tester.tap(find.text('Start date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    final CarbonCalendar oldCalendar = tester.widget<CarbonCalendar>(
      find.byType(CarbonCalendar),
    );
    state.update(first: DateTime(2026, 6, 18), last: DateTime(2026, 6, 20));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CarbonCalendar>(find.byType(CarbonCalendar)).range,
      isNull,
    );
    oldCalendar.onRangeChanged!(
      CarbonDateRange(DateTime(2026, 6, 5), DateTime(2026, 6, 19)),
    );
    await tester.pumpAndSettle();
    expect(state.value, initial);
    expect(state.changes, isEmpty);
    await tester.tap(find.text('18'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    expect(state.changes, <CarbonDateRange>[
      CarbonDateRange(DateTime(2026, 6, 18), DateTime(2026, 6, 20)),
    ]);
  });

  testWidgets('rejected controlled commits still notify only once', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    state.accept = false;
    await tester.tap(find.text('Start date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    final CarbonCalendar calendar = tester.widget<CarbonCalendar>(
      find.byType(CarbonCalendar),
    );
    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    expect(state.value, isNull);
    expect(state.changes, hasLength(1));
    calendar.onRangeChanged!(state.changes.single);
    await tester.pumpAndSettle();
    expect(state.changes, hasLength(1));
    expect(find.byType(CarbonCalendar), findsNothing);
  });

  testWidgets('disposing an open session makes retained callbacks inert', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    await tester.tap(find.text('Start date'));
    await tester.pumpAndSettle();
    final CarbonCalendar calendar = tester.widget<CarbonCalendar>(
      find.byType(CarbonCalendar),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    calendar.onRangeChanged!(
      CarbonDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 2)),
    );
    calendar.onEscape!();
    await tester.pumpAndSettle();
    expect(state.changes, isEmpty);
    expect(tester.takeException(), isNull);
  });
  for (final bool single in <bool>[false, true]) {
    testWidgets(
      'outside dismissal preserves the new target focus, single=$single',
      (WidgetTester tester) async {
        final _FixtureState state = await _mount(tester, single: single);
        await tester.tap(find.text(single ? '06/15/2026' : 'Start date'));
        await tester.pumpAndSettle();
        if (!single) {
          await tester.tap(find.text('10'));
          await tester.pumpAndSettle();
        }
        // Native browser focus can arrive before the TapRegion pointer event.
        state.outside.requestFocus();
        await tester.pump();
        await tester.tap(find.text('Outside'));
        await tester.pumpAndSettle();
        expect(find.byType(CarbonCalendar), findsNothing);
        expect(FocusManager.instance.primaryFocus, state.outside);
        expect(state.changes, isEmpty);
      },
    );
  }
  for (final bool single in <bool>[false, true]) {
    testWidgets(
      'disabling an open picker closes it and removes trigger actions, single=$single',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          final _FixtureState state = await _mount(tester, single: single);
          await tester.tap(find.text(single ? '06/15/2026' : 'Start date'));
          await tester.pumpAndSettle();
          state.update(disabled: true);
          await tester.pumpAndSettle();
          expect(find.byType(CarbonCalendar), findsNothing);
          for (final String label in <String>[
            if (single) 'Date' else ...<String>['Start date', 'End date'],
          ]) {
            final SemanticsNode node = tester.getSemantics(
              find.bySemanticsLabel(label),
            );
            expect(
              node,
              isSemantics(
                isButton: true,
                isEnabled: false,
                hasTapAction: false,
              ),
            );
          }
          expect(state.changes, isEmpty);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          handle.dispose();
        }
      },
    );
  }
}

Future<_FixtureState> _mount(
  WidgetTester tester, {
  CarbonDateRange? value,
  bool single = false,
}) async {
  final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (_, _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: TapRegionSurface(
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) => Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        excludeFromSemantics: true,
                        onTap: () {},
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 16,
                      child: _Fixture(
                        key: key,
                        initialValue: value,
                        single: single,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

const Object _unchanged = Object();

class _Fixture extends StatefulWidget {
  const _Fixture({super.key, required this.initialValue, required this.single});
  final CarbonDateRange? initialValue;
  final bool single;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  late CarbonDateRange? value = widget.initialValue;
  bool disabled = false;
  bool accept = true;
  DateTime? first;
  DateTime? last;
  final List<CarbonDateRange> changes = <CarbonDateRange>[];
  final FocusNode outside = FocusNode(debugLabel: 'Outside');
  @override
  void dispose() {
    outside.dispose();
    super.dispose();
  }

  void update({
    Object? value = _unchanged,
    bool? disabled,
    Object? first = _unchanged,
    Object? last = _unchanged,
  }) => setState(() {
    if (value != _unchanged) this.value = value as CarbonDateRange?;
    this.disabled = disabled ?? this.disabled;
    if (first != _unchanged) this.first = first as DateTime?;
    if (last != _unchanged) this.last = last as DateTime?;
  });
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _picker,
      const SizedBox(width: 48),
      CarbonButton(label: 'Outside', focusNode: outside, onPressed: () {}),
    ],
  );
  Widget get _picker => widget.single
      ? SizedBox(
          width: 288,
          child: CarbonDatePicker(
            labelText: 'Date',
            disabled: disabled,
            value: DateTime(2026, 6, 15),
            onChanged: (_) {},
          ),
        )
      : CarbonDateRangePicker(
          value: value,
          disabled: disabled,
          firstDate: first,
          lastDate: last,
          onChanged: (CarbonDateRange next) {
            changes.add(next);
            if (accept) setState(() => value = next);
          },
        );
}

String _heading(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(CarbonCalendar),
        matching: find.byType(Text),
      ),
    )
    .firstWhere((Text text) => text.data!.contains(' '))
    .data!;
