// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/gallery_app.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final String opener in <String>['Date', 'Start date', 'End date']) {
    for (final bool focusTrigger in <bool>[false, true]) {
      testWidgets(
        'native $opener opening replaces ${focusTrigger ? "trigger" : "outside"} focus and Escape restores it',
        (WidgetTester tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          try {
            final _FixtureState state = await _mount(
              tester,
              mode: opener == 'Date' ? 2 : 1,
              range: CarbonDateRange(
                DateTime(2026, 6, 10),
                DateTime(2026, 6, 12),
              ),
            );
            _button(focusTrigger ? opener : 'Outside').focus();
            await _settle(tester);
            final CarbonDateRange? snapshot = state.range;
            for (int i = 0; i < 2; i++) {
              await tester.tap(
                find.text(
                  opener == 'Date'
                      ? '06/15/2026'
                      : opener == 'Start date'
                      ? '06/10/2026'
                      : '06/12/2026',
                ),
              );
              await _settle(tester);
              expect(_activeName, opener == 'Date' ? '15' : '12');
              await _key(tester, LogicalKeyboardKey.escape);
              await _settle(tester);
              expect(find.byType(CarbonCalendar), findsNothing);
              expect(_activeName, startsWith(opener));
              expect(state.range, snapshot);
              expect(state.ranges, isEmpty);
              expect(state.dates, isEmpty);
            }
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            handle.dispose();
          }
        },
      );
    }
  }

  testWidgets('gallery popup keeps native opening and dismissal focus', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(const GalleryApp());
      await _settle(tester);
      await tester.tap(find.text('Complex & data'));
      await _settle(tester);
      await tester.tap(find.text('Date picker'));
      await _settle(tester);
      _button('Appointment date').focus();
      await _settle(tester);
      final DateTime? snapshot = tester
          .widget<CarbonDatePicker>(find.byType(CarbonDatePicker))
          .value;
      await tester.tap(find.text('06/16/2026'));
      await _settle(tester);
      expect(_activeName, '16');
      // The popup is a sibling of the trigger in accessibility navigation.
      expect(_button('Appointment date').textContent, isNot(contains('June')));
      await _key(tester, LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(find.byType(CarbonCalendar), findsNothing);
      expect(_activeName, startsWith('Appointment date'));
      expect(
        tester.widget<CarbonDatePicker>(find.byType(CarbonDatePicker)).value,
        snapshot,
      );
      await _key(tester, LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(_activeName, '16');
      await _key(tester, LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(_activeName, startsWith('Appointment date'));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      handle.dispose();
    }
  });

  for (final bool single in <bool>[false, true]) {
    testWidgets('new native focus wins during popup removal, single=$single', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await _mount(tester, mode: single ? 2 : 1);
        await tester.tap(find.text(single ? '06/15/2026' : 'Start date'));
        await _settle(tester);
        await _key(tester, LogicalKeyboardKey.escape);
        // The opener's return is queued while OverlayPortal is still hiding.
        await tester.pump();
        _button('Outside').focus();
        await _settle(tester);
        expect(find.byType(CarbonCalendar), findsNothing);
        expect(_activeName, 'Outside');
        await tester.pumpWidget(const SizedBox.shrink());
        await _settle(tester);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    });
  }

  testWidgets(
    'native focus follows calendar navigation and controlled bounds',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        final _FixtureState state = await _mount(tester);
        _button('15').focus();
        await _settle(tester);
        await _key(tester, LogicalKeyboardKey.arrowRight);
        await _settle(tester);
        expect(_activeName, '16');
        expect(_button('15').getAttribute('aria-current'), 'true');
        expect(_button('16').getAttribute('aria-current'), 'false');
        expect(state.dates, isEmpty);
        state.update();
        await _settle(tester);
        expect(_activeName, '16');
        state.update(value: DateTime(2026, 8, 9));
        await _settle(tester);
        expect(find.text('August 2026'), findsOneWidget);
        expect(_activeName, '9');
        state.update(first: DateTime(2026, 7, 20), last: DateTime(2026, 7, 25));
        await _settle(tester);
        expect(find.text('July 2026'), findsOneWidget);
        expect(_activeName, '25');
        expect(_button('Previous month').getAttribute('aria-disabled'), 'true');
        expect(_button('Next month').getAttribute('aria-disabled'), 'true');
        for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
          LogicalKeyboardKey.arrowRight,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.pageDown,
        ]) {
          await _key(tester, key);
        }
        await _settle(tester);
        expect(_activeName, '25');
        await _key(tester, LogicalKeyboardKey.arrowUp);
        await _settle(tester);
        expect(_activeName, '20');
        for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.pageUp,
        ]) {
          await _key(tester, key);
        }
        await _settle(tester);
        expect(_activeName, '20');
        await _key(tester, LogicalKeyboardKey.enter);
        await _settle(tester);
        expect(state.dates, <DateTime>[DateTime(2026, 7, 20)]);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    },
  );

  for (final CarbonDateRange? snapshot in <CarbonDateRange?>[
    null,
    CarbonDateRange(DateTime(2026, 6, 10), DateTime(2026, 6, 12)),
    CarbonDateRange(DateTime(2026, 6, 12)),
  ]) {
    testWidgets('native Escape/outside/toggle preserve snapshot $snapshot', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        final _FixtureState state = await _mount(
          tester,
          mode: 1,
          range: snapshot,
        );
        for (final String path in <String>['Escape', 'outside', 'toggle']) {
          await tester.tap(find.text('Start date'));
          await _settle(tester);
          await tester.tap(find.text('11'));
          await _settle(tester);
          expect(state.range, snapshot);
          expect(state.ranges, isEmpty);
          final CarbonCalendar calendar = tester.widget<CarbonCalendar>(
            find.byType(CarbonCalendar),
          );
          switch (path) {
            case 'Escape':
              await _key(tester, LogicalKeyboardKey.escape);
            case 'outside':
              await tester.tapAt(const Offset(900, 650));
            case 'toggle':
              await tester.tap(find.text('End date'));
          }
          await _settle(tester);
          expect(find.byType(CarbonCalendar), findsNothing);
          expect(state.range, snapshot);
          expect(state.ranges, isEmpty);
          expect(_activeName, startsWith('Start date'));
          calendar.onRangeChanged!(
            CarbonDateRange(DateTime(2026, 6, 11), DateTime(2026, 6, 15)),
          );
          await _settle(tester);
          expect(state.ranges, isEmpty);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    });
  }

  for (final bool end in <bool>[false, true]) {
    testWidgets(
      'native completed range returns to ${end ? 'end' : 'start'} opener once',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          final _FixtureState state = await _mount(tester, mode: 1);
          await tester.tap(find.text(end ? 'End date' : 'Start date'));
          await _settle(tester);
          await tester.tap(find.text('11'));
          await _settle(tester);
          expect(state.ranges, isEmpty);
          final CarbonCalendar calendar = tester.widget<CarbonCalendar>(
            find.byType(CarbonCalendar),
          );
          await tester.tap(find.text('18'));
          await _settle(tester);
          final CarbonDateRange expected = CarbonDateRange(
            DateTime(2026, 6, 11),
            DateTime(2026, 6, 18),
          );
          expect(state.range, expected);
          expect(state.ranges, <CarbonDateRange>[expected]);
          expect(_activeName, startsWith(end ? 'End date' : 'Start date'));
          calendar.onRangeChanged!(expected);
          await _settle(tester);
          expect(state.ranges, <CarbonDateRange>[expected]);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          handle.dispose();
        }
      },
    );
  }

  testWidgets('external replacement and disabling invalidate native drafts', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      final _FixtureState state = await _mount(tester, mode: 1);
      await tester.tap(find.text('Start date'));
      await _settle(tester);
      await tester.tap(find.text('11'));
      await _settle(tester);
      final CarbonCalendar oldCalendar = tester.widget<CarbonCalendar>(
        find.byType(CarbonCalendar),
      );
      final CarbonDateRange replacement = CarbonDateRange(
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 15),
      );
      state.update(range: replacement);
      await _settle(tester);
      expect(find.text('August 2026'), findsOneWidget);
      oldCalendar.onRangeChanged!(
        CarbonDateRange(DateTime(2026, 6, 11), DateTime(2026, 6, 18)),
      );
      await _settle(tester);
      expect(state.range, replacement);
      expect(state.ranges, isEmpty);
      await tester.tap(find.text('12'));
      await _settle(tester);
      state.update(disabled: true);
      await _settle(tester);
      expect(find.byType(CarbonCalendar), findsNothing);
      expect(state.range, replacement);
      expect(state.ranges, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      handle.dispose();
    }
  });

  testWidgets(
    'single-picker native trigger focus returns on outside dismissal',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await _mount(tester, mode: 2);
        await tester.tap(find.text('06/15/2026'));
        await _settle(tester);
        expect(_activeName, '15');
        await tester.tapAt(const Offset(900, 650));
        await _settle(tester);
        expect(find.byType(CarbonCalendar), findsNothing);
        expect(_activeName, startsWith('Date'));
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    },
  );

  testWidgets(
    'late semantics enable and disposal do not retain a range session',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(tester, mode: 1);
      await tester.tap(find.text('Start date'));
      await _settle(tester);
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await _settle(tester);
        expect(_button('Previous month').getAttribute('aria-disabled'), 'true');
        final CarbonCalendar calendar = tester.widget<CarbonCalendar>(
          find.byType(CarbonCalendar),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        calendar.onEscape!();
        calendar.onRangeChanged!(
          CarbonDateRange(DateTime(2026, 6, 11), DateTime(2026, 6, 18)),
        );
        await _settle(tester);
        expect(state.ranges, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    },
  );
  for (final bool single in <bool>[false, true]) {
    testWidgets(
      'native outside target keeps focus after dismissal, single=$single',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          await _mount(tester, mode: single ? 2 : 1);
          await tester.tap(find.text(single ? '06/15/2026' : 'Start date'));
          await _settle(tester);
          _button('Outside').focus();
          await _settle(tester);
          await tester.tap(find.text('Outside'));
          await _settle(tester);
          expect(find.byType(CarbonCalendar), findsNothing);
          expect(_activeName, 'Outside');
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          handle.dispose();
        }
      },
    );
  }
  for (final bool single in <bool>[false, true]) {
    testWidgets(
      'native disabled picker closes and announces disabled fields, single=$single',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          final _FixtureState state = await _mount(
            tester,
            mode: single ? 2 : 1,
          );
          await tester.tap(find.text(single ? '06/15/2026' : 'Start date'));
          await _settle(tester);
          state.update(disabled: true);
          await _settle(tester);
          expect(find.byType(CarbonCalendar), findsNothing);
          for (final String label in <String>[
            if (single) 'Date' else ...<String>['Start date', 'End date'],
          ]) {
            expect(_button(label).getAttribute('aria-disabled'), 'true');
          }
          expect(state.ranges, isEmpty);
          expect(state.dates, isEmpty);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          handle.dispose();
        }
      },
    );
  }
}

// Flutter's key simulator infers physical keys from debug names, which are
// stripped in release mode. Supply the physical key explicitly in both modes.
Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(
    key,
    physicalKey: switch (key) {
      LogicalKeyboardKey.escape => PhysicalKeyboardKey.escape,
      LogicalKeyboardKey.enter => PhysicalKeyboardKey.enter,
      LogicalKeyboardKey.arrowLeft => PhysicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight => PhysicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp => PhysicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown => PhysicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.pageUp => PhysicalKeyboardKey.pageUp,
      LogicalKeyboardKey.pageDown => PhysicalKeyboardKey.pageDown,
      _ => throw ArgumentError.value(key, 'key'),
    },
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  // Native focus events can request a frame after the semantics DOM update.
  await tester.pumpAndSettle();
}

Future<_FixtureState> _mount(
  WidgetTester tester, {
  int mode = 0,
  CarbonDateRange? range,
}) async {
  final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      onGenerateRoute: (_) => PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => CarbonTheme(
          data: CarbonThemeData.white,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _Fixture(key: key, mode: mode, range: range),
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  return key.currentState!;
}

class _Fixture extends StatefulWidget {
  const _Fixture({super.key, required this.mode, required this.range});
  final int mode;
  final CarbonDateRange? range;
  @override
  State<_Fixture> createState() => _FixtureState();
}

const Object _unchanged = Object();

class _FixtureState extends State<_Fixture> {
  DateTime value = DateTime(2026, 6, 15);
  late DateTime first = widget.mode == 0
      ? DateTime(2026, 6, 10)
      : DateTime(2026, 6, 1);
  late DateTime last = widget.mode == 0
      ? DateTime(2026, 8, 20)
      : DateTime(2026, 6, 30);
  late CarbonDateRange? range = widget.range;
  bool disabled = false;
  final List<DateTime> dates = <DateTime>[];
  final List<CarbonDateRange> ranges = <CarbonDateRange>[];
  final FocusNode outside = FocusNode(debugLabel: 'Outside');
  @override
  void dispose() {
    outside.dispose();
    super.dispose();
  }

  void update({
    DateTime? value,
    DateTime? first,
    DateTime? last,
    Object? range = _unchanged,
    bool? disabled,
  }) => setState(() {
    this.value = value ?? this.value;
    this.first = first ?? this.first;
    this.last = last ?? this.last;
    if (range != _unchanged) this.range = range as CarbonDateRange?;
    // Expand this window with an explicit external range replacement.
    if (range != _unchanged && this.range != null) {
      this.first = DateTime(this.range!.start.year, this.range!.start.month, 1);
      this.last = DateTime(
        this.range!.start.year,
        this.range!.start.month + 1,
        0,
      );
    }
    this.disabled = disabled ?? this.disabled;
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
  Widget get _picker => SizedBox(
    width: 320,
    child: switch (widget.mode) {
      0 => CarbonCalendar(
        value: value,
        firstDate: first,
        lastDate: last,
        autofocus: true,
        onChanged: (DateTime next) {
          dates.add(next);
          setState(() => value = next);
        },
      ),
      1 => CarbonDateRangePicker(
        value: range,
        firstDate: first,
        lastDate: last,
        disabled: disabled,
        onChanged: (CarbonDateRange next) {
          ranges.add(next);
          setState(() => range = next);
        },
      ),
      _ => CarbonDatePicker(
        labelText: 'Date',
        disabled: disabled,
        value: value,
        firstDate: first,
        lastDate: last,
        onChanged: (DateTime next) {
          dates.add(next);
          setState(() => value = next);
        },
      ),
    },
  );
}

_Element _button(String name) {
  final _NodeList nodes = _document.querySelectorAll('[role="button"]');
  return <_Element>[for (int i = 0; i < nodes.length; i++) nodes.item(i)!]
      .firstWhere(
        (_Element element) =>
            (element.getAttribute('aria-label') ?? element.textContent ?? '')
                .trim()
                .startsWith(name) &&
            (int.tryParse(name) == null || element.textContent?.trim() == name),
      );
}

String? get _activeName => _document.activeElement?.textContent?.trim();

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
  external _Element? get activeElement;
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external String? getAttribute(String name);
  external void focus();
}
