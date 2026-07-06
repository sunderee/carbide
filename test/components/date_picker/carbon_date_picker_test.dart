// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// The date-picker field always mounts a [CarbonPopover] (OverlayPortal), so it
/// needs an Overlay + TapRegionSurface — a real app's scaffold supplies both.
Widget _overlay(Widget child) => TapRegionSurface(
  child: Overlay(
    initialEntries: <OverlayEntry>[
      OverlayEntry(
        builder: (BuildContext context) => Stack(
          children: <Widget>[
            Positioned.fill(
              // Tap-outside backdrop is test scaffolding; keep it out of
              // the semantics tree so a11y sweeps only see the picker.
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: () {},
              ),
            ),
            Align(alignment: Alignment.topLeft, child: child),
          ],
        ),
      ),
    ],
  ),
);

/// Hosts a date-picker field with the Directionality + theme + overlay it needs.
Widget _fieldHost(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(data: CarbonThemeData.white, child: _overlay(child)),
);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('calendar', () {
    testWidgets('renders the month, weekday headers and every day', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: CarbonCalendar(
              value: DateTime(2026, 6, 15),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('June 2026'), findsOneWidget);
      expect(find.text('Su'), findsOneWidget);
      expect(find.text('Sa'), findsOneWidget);
      // June has 30 days.
      expect(find.text('30'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('the selected day fills with button-primary / text-on-color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: CarbonCalendar(
              value: DateTime(2026, 6, 15),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      final ColoredBox box = tester.widget<ColoredBox>(
        find
            .ancestor(of: find.text('15'), matching: find.byType(ColoredBox))
            .first,
      );
      expect(box.color, theme.buttonPrimary);
      expect(
        tester.widget<Text>(find.text('15')).style!.color,
        theme.textOnColor,
      );
    });

    testWidgets('tapping a day reports it', (WidgetTester tester) async {
      DateTime? picked;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: CarbonCalendar(
              value: DateTime(2026, 6, 15),
              onChanged: (DateTime d) => picked = d,
            ),
          ),
        ),
      );
      await tester.tap(find.text('20'));
      expect(picked, DateTime(2026, 6, 20));
    });

    testWidgets('next/previous arrows change the visible month', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: CarbonCalendar(
              value: DateTime(2026, 6, 15),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();
      expect(find.text('July 2026'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pump();
      expect(find.text('May 2026'), findsOneWidget);
    });

    testWidgets('days outside min/max are disabled and unselectable', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: CarbonCalendar(
              value: DateTime(2026, 6, 15),
              firstDate: DateTime(2026, 6, 10),
              lastDate: DateTime(2026, 6, 20),
              onChanged: (_) => taps++,
            ),
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('5')).style!.color,
        theme.textDisabled,
      );
      await tester.tap(find.text('5'));
      expect(taps, 0);
      await tester.tap(find.text('12'));
      expect(taps, 1);
    });

    testWidgets('the selected day exposes selected semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: CarbonCalendar(
              value: DateTime(2026, 6, 15),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('15')),
        isSemantics(label: '15', isButton: true, isSelected: true),
      );
      handle.dispose();
    });
  });

  group('date picker field', () {
    testWidgets('shows the placeholder when empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _fieldHost(
          SizedBox(
            width: 320,
            child: CarbonDatePicker(labelText: 'Date', onChanged: (_) {}),
          ),
        ),
      );
      expect(find.text('mm/dd/yyyy'), findsOneWidget);
    });

    testWidgets('shows the formatted date when set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _fieldHost(
          SizedBox(
            width: 320,
            child: CarbonDatePicker(
              labelText: 'Date',
              value: DateTime(2026, 6, 5),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('06/05/2026'), findsOneWidget);
    });

    testWidgets('tapping opens the calendar; picking closes and reports', (
      WidgetTester tester,
    ) async {
      DateTime? picked;
      await tester.pumpWidget(
        _fieldHost(
          SizedBox(
            width: 320,
            child: CarbonDatePicker(
              labelText: 'Date',
              value: DateTime(2026, 6, 15),
              onChanged: (DateTime d) => picked = d,
            ),
          ),
        ),
      );
      expect(find.text('June 2026'), findsNothing);
      await tester.tap(find.text('06/15/2026'));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsOneWidget);
      await tester.tap(find.text('22'));
      await tester.pumpAndSettle();
      expect(picked, DateTime(2026, 6, 22));
      expect(find.text('June 2026'), findsNothing);
    });

    testWidgets('a disabled field does not open', (WidgetTester tester) async {
      await tester.pumpWidget(
        _fieldHost(
          SizedBox(
            width: 320,
            child: CarbonDatePicker(
              labelText: 'Date',
              disabled: true,
              value: DateTime(2026, 6, 15),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('06/15/2026'));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsNothing);
    });

    testWidgets('invalid shows the error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        _fieldHost(
          SizedBox(
            width: 320,
            child: CarbonDatePicker(
              labelText: 'Date',
              invalid: true,
              invalidText: 'Date is required',
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Date is required'), findsOneWidget);
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md field is 40px (_date-picker.scss block-size:
      // convert.to-rem(40px)) — below the 48dp android guideline, so pump
      // the real lg (48px) variant instead.
      await tester.pumpWidget(
        _fieldHost(
          SizedBox(
            width: 320,
            child: CarbonDatePicker(
              labelText: 'Date',
              size: CarbonFieldSize.lg,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('calendar across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'date_picker_calendar',
        containsText: true,
        size: const Size(360, 400),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: CarbonCalendar(
              value: DateTime(2026, 6, 15),
              firstDate: DateTime(2026, 6, 3),
              onChanged: (_) {},
            ),
          ),
        ),
      );
    });

    testWidgets('date picker field across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'date_picker_field',
        containsText: true,
        size: const Size(320, 90),
        builder: (BuildContext context) => _overlay(
          SizedBox(
            width: 288,
            child: CarbonDatePicker(
              labelText: 'Date',
              value: DateTime(2026, 6, 15),
              onChanged: (_) {},
            ),
          ),
        ),
      );
    });
  });

  group('range calendar (_flatpickr.scss inRange/startRange/endRange)', () {
    Widget rangeCalendar({
      CarbonDateRange? range,
      required ValueChanged<CarbonDateRange> onRangeChanged,
      bool autofocus = false,
      VoidCallback? onEscape,
    }) => _host(
      SizedBox(
        width: 320,
        child: CarbonCalendar(
          range: range,
          onRangeChanged: onRangeChanged,
          autofocus: autofocus,
          onEscape: onEscape,
        ),
      ),
    );

    Color dayFill(WidgetTester tester, String day) => tester
        .widget<Container>(
          find
              .ancestor(of: find.text(day), matching: find.byType(Container))
              .first,
        )
        .color!;

    testWidgets('selection machine: start, complete, restart', (
      WidgetTester tester,
    ) async {
      final List<CarbonDateRange> changes = <CarbonDateRange>[];
      CarbonDateRange? range;
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) =>
                  CarbonCalendar(
                    range: range ?? CarbonDateRange(DateTime(2026, 6, 10)),
                    onRangeChanged: (CarbonDateRange r) {
                      changes.add(r);
                      setState(() => range = r);
                    },
                  ),
            ),
          ),
        ),
      );

      // A later day completes the in-progress range.
      await tester.tap(find.text('20'));
      await tester.pump();
      expect(changes.last.start, DateTime(2026, 6, 10));
      expect(changes.last.end, DateTime(2026, 6, 20));

      // Any activation after a completed range starts a new one.
      await tester.tap(find.text('15'));
      await tester.pump();
      expect(changes.last, CarbonDateRange(DateTime(2026, 6, 15)));

      // An earlier day than the start restarts the range.
      await tester.tap(find.text('5'));
      await tester.pump();
      expect(changes.last, CarbonDateRange(DateTime(2026, 6, 5)));
    });

    testWidgets('committed range paints ends primary and the band highlight', (
      WidgetTester tester,
    ) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(
        rangeCalendar(
          range: CarbonDateRange(DateTime(2026, 6, 10), DateTime(2026, 6, 14)),
          onRangeChanged: (_) {},
        ),
      );
      expect(dayFill(tester, '10'), theme.buttonPrimary);
      expect(dayFill(tester, '14'), theme.buttonPrimary);
      expect(dayFill(tester, '12'), theme.highlight);
      expect(dayFill(tester, '15'), const Color(0x00000000));
    });

    testWidgets('the band spans a month boundary', (WidgetTester tester) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(
        rangeCalendar(
          range: CarbonDateRange(DateTime(2026, 5, 28), DateTime(2026, 6, 4)),
          onRangeChanged: (_) {},
        ),
      );
      // The calendar opens on the end month; the first days are in range.
      expect(dayFill(tester, '2'), theme.highlight);
      expect(dayFill(tester, '4'), theme.buttonPrimary);
      // Stepping back shows the start month's tail in range.
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pump();
      expect(dayFill(tester, '30'), theme.highlight);
      expect(dayFill(tester, '28'), theme.buttonPrimary);
    });

    testWidgets('hovering previews the band and outlines the preview end', (
      WidgetTester tester,
    ) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(
        rangeCalendar(
          range: CarbonDateRange(DateTime(2026, 6, 10)),
          onRangeChanged: (_) {},
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('17')));
      await tester.pumpAndSettle();

      // In-between days highlight; the hovered preview end sits on
      // layer-01 with the 2px focus outline.
      expect(dayFill(tester, '13'), theme.highlight);
      expect(dayFill(tester, '17'), theme.layer01);
      final Container preview = tester.widget<Container>(
        find
            .ancestor(of: find.text('17'), matching: find.byType(Container))
            .first,
      );
      final BoxDecoration outline =
          preview.foregroundDecoration! as BoxDecoration;
      expect(outline.border!.top.width, 2);
      expect(outline.border!.top.color, theme.focus);
    });

    testWidgets('arrow keys move the focused day and cross months; Enter '
        'activates; Escape cancels', (WidgetTester tester) async {
      final List<CarbonDateRange> changes = <CarbonDateRange>[];
      int escapes = 0;
      await tester.pumpWidget(
        rangeCalendar(
          range: CarbonDateRange(DateTime(2026, 6, 10)),
          onRangeChanged: changes.add,
          autofocus: true,
          onEscape: () => escapes++,
        ),
      );
      await tester.pump();

      // Focus anchors on the range start; Down + Right = +8 days.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes.single.end, DateTime(2026, 6, 18));

      // Crossing the month edge turns the page.
      for (int i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pump();
      expect(find.text('July 2026'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(escapes, 1);
    });
  });

  group('range picker field', () {
    testWidgets('two labelled 143.5px fields with a 1px gap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _fieldHost(
          CarbonDateRangePicker(
            value: CarbonDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 8)),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);
      expect(find.text('06/01/2026'), findsOneWidget);
      expect(find.text('06/08/2026'), findsOneWidget);

      final Rect start = tester.getRect(find.byType(CarbonField).first);
      final Rect end = tester.getRect(find.byType(CarbonField).last);
      expect(start.width, 143.5);
      expect(end.width, 143.5);
      expect(end.left - start.right, 1);
    });

    testWidgets('start keeps the popover open; the end closes it', (
      WidgetTester tester,
    ) async {
      CarbonDateRange? value = CarbonDateRange(
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 12),
      );
      await tester.pumpWidget(
        _fieldHost(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                CarbonDateRangePicker(
                  value: value,
                  onChanged: (CarbonDateRange r) => setState(() => value = r),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Start date'));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsOneWidget);

      // Restarting keeps the calendar open with a start-only value.
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsOneWidget);
      expect(value, CarbonDateRange(DateTime(2026, 6, 5)));

      // Completing the range closes the calendar.
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsNothing);
      expect(
        value,
        CarbonDateRange(DateTime(2026, 6, 5), DateTime(2026, 6, 20)),
      );
    });

    testWidgets('Escape restores the value from when the popover opened', (
      WidgetTester tester,
    ) async {
      CarbonDateRange? value = CarbonDateRange(
        DateTime(2026, 6, 10),
        DateTime(2026, 6, 12),
      );
      await tester.pumpWidget(
        _fieldHost(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                CarbonDateRangePicker(
                  value: value,
                  onChanged: (CarbonDateRange r) => setState(() => value = r),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Start date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(value, CarbonDateRange(DateTime(2026, 6, 5)));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        value,
        CarbonDateRange(DateTime(2026, 6, 10), DateTime(2026, 6, 12)),
      );
      expect(find.text('June 2026'), findsNothing);
    });
  });

  group('range goldens', () {
    testWidgets('committed range across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'date_picker_range',
        containsText: true,
        size: const Size(360, 400),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: CarbonCalendar(
              range: CarbonDateRange(
                DateTime(2026, 6, 10),
                DateTime(2026, 6, 19),
              ),
              onRangeChanged: (_) {},
            ),
          ),
        ),
      );
    });

    testWidgets('in-progress preview across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'date_picker_range_preview',
        containsText: true,
        size: const Size(360, 400),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: CarbonCalendar(
              range: CarbonDateRange(DateTime(2026, 6, 10)),
              onRangeChanged: (_) {},
              autofocus: true,
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          // Arrow a week down: the keyboard focus previews the band.
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('range picker fields across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'date_picker_range_fields',
        containsText: true,
        size: const Size(360, 100),
        builder: (BuildContext context) => _overlay(
          CarbonDateRangePicker(
            value: CarbonDateRange(DateTime(2026, 6, 1), DateTime(2026, 6, 8)),
            onChanged: (_) {},
          ),
        ),
      );
    });
  });
}
