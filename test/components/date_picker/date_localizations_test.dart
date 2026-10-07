// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/date_localizations.dart';
import '../../support/overlay_entries.dart';
import '../../support/legibility.dart';
import '../../support/golden.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(
      size: const Size(1000, 800),
      textScaler: TextScaler.linear(scale),
    ),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (BuildContext context) => Center(child: child),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('long Arabic weekday labels grow at 2x instead of clipping', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final CarbonDatePickerLocalizations labels = CarbonDatePickerLocalizations(
      locale: arabicDateLabels.locale,
      monthNames: arabicDateLabels.monthNames,
      weekdayNames: const <String>[
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ],
      firstDayOfWeek: DateTime.saturday,
      dateFormat: arabicDateLabels.dateFormat,
      monthYearFormatter: arabicDateLabels.monthYearFormatter,
      dayFormatter: arabicDateLabels.dayFormatter,
    );
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 312,
          child: CarbonCalendar(
            value: DateTime(2025, 10, 17),
            localizations: labels,
            onChanged: (DateTime _) {},
          ),
        ),
        direction: TextDirection.rtl,
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expectNoClippedTextAtScale(tester, 2);
    expect(tester.getSize(find.text('الأربعاء')).height, greaterThan(40));
  });
  testWidgets('malformed label lists fail before indexing calendar cells', (
    WidgetTester tester,
  ) async {
    for (final CarbonDatePickerLocalizations labels
        in <CarbonDatePickerLocalizations>[
          const CarbonDatePickerLocalizations(monthNames: <String>[]),
          const CarbonDatePickerLocalizations(weekdayNames: <String>[]),
        ]) {
      await tester.pumpWidget(
        _host(
          CarbonCalendar(
            value: DateTime(2025, 10, 17),
            localizations: labels,
            onChanged: (DateTime _) {},
          ),
        ),
      );
      expect(tester.takeException(), isArgumentError);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  const List<String> headings = <String>[
    'October 2025',
    'Oktober 2025',
    '2025年10月',
    'أكتوبر ٢٠٢٥',
  ];
  for (int i = 0; i < dateLocaleFixtures.length; i++) {
    final (
      String name,
      CarbonDatePickerLocalizations labels,
      String formatted,
      _,
    ) = dateLocaleFixtures[i];
    testWidgets(
      '$name localizes calendar heading, navigation and weekday labels',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _host(
              SizedBox(
                width: 312,
                child: CarbonCalendar(
                  value: DateTime(2025, 10, 17),
                  localizations: labels,
                  onChanged: (DateTime _) {},
                ),
              ),
            ),
          );
          expect(find.text(headings[i]), findsOneWidget);
          expect(
            find.bySemanticsLabel(labels.previousMonthLabel),
            findsOneWidget,
          );
          expect(find.bySemanticsLabel(labels.nextMonthLabel), findsOneWidget);
          for (final String weekday in labels.weekdayNames) {
            expect(find.text(weekday), findsOneWidget);
          }
          final DateTime selected = DateTime(2025, 10, 17);
          expect(
            find.bySemanticsLabel(labels.formatDayLabel(selected)),
            findsOneWidget,
          );
          expect(find.text(labels.formatDay(selected)), findsOneWidget);
        } finally {
          semantics.dispose();
        }
      },
    );
    testWidgets('$name single and range fields share the same date format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 320,
                child: CarbonDatePicker(
                  labelText: 'Date',
                  value: DateTime(2025, 9, 13),
                  localizations: labels,
                  onChanged: (DateTime _) {},
                ),
              ),
              const SizedBox(height: 16),
              CarbonDateRangePicker(
                startLabelText: 'From',
                endLabelText: 'Until',
                value: CarbonDateRange(
                  DateTime(2025, 9, 13),
                  DateTime(2025, 9, 14),
                ),
                localizations: labels,
                onChanged: (CarbonDateRange _) {},
              ),
            ],
          ),
        ),
      );
      expect(find.text(formatted), findsNWidgets(2));
      expect(
        find.text(labels.dateFormat.format(DateTime(2025, 9, 14))),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      '$name derives both picker placeholders from the active pattern',
      (WidgetTester tester) async {
        final CarbonDatePicker single = CarbonDatePicker(
          labelText: 'Date',
          localizations: labels,
          onChanged: (DateTime _) {},
        );
        final CarbonDateRangePicker range = CarbonDateRangePicker(
          startLabelText: 'From',
          endLabelText: 'Until',
          localizations: labels,
          onChanged: (CarbonDateRange _) {},
        );
        expect(single.placeholder, labels.dateFormat.placeholder);
        expect(range.placeholder, labels.dateFormat.placeholder);
        await tester.pumpWidget(
          _host(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(width: 320, child: single),
                const SizedBox(height: 16),
                range,
              ],
            ),
          ),
        );
        expect(find.text(labels.dateFormat.placeholder), findsNWidgets(3));
      },
    );
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('$name starts the week correctly in $direction', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 312,
              child: CarbonCalendar(
                value: DateTime(2025, 10, 17),
                localizations: labels,
                onChanged: (DateTime _) {},
              ),
            ),
            direction: direction,
          ),
        );
        final Rect calendar = tester.getRect(find.byType(CarbonCalendar));
        final int offset =
            (DateTime(2025, 10).weekday - labels.firstDayOfWeek + 7) % 7;
        final double expected = direction == TextDirection.ltr
            ? calendar.left + 16 + 20 + offset * 40
            : calendar.right - 16 - 20 - offset * 40;
        expect(
          tester
              .getCenter(find.text(labels.formatDay(DateTime(2025, 10, 1))))
              .dx,
          closeTo(expected, 0.1),
        );
        final String firstLabel =
            labels.weekdayNames[labels.firstDayOfWeek % 7];
        final double firstX = direction == TextDirection.ltr
            ? calendar.left + 36
            : calendar.right - 36;
        expect(
          tester.getCenter(find.text(firstLabel)).dx,
          closeTo(firstX, 0.1),
        );
      });
      testWidgets(
        '$name uses logical arrows and mirrored month chevrons in $direction',
        (WidgetTester tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          try {
            DateTime? chosen;
            await tester.pumpWidget(
              _host(
                SizedBox(
                  width: 312,
                  child: CarbonCalendar(
                    value: DateTime(2025, 10, 17),
                    localizations: labels,
                    autofocus: true,
                    onChanged: (DateTime value) => chosen = value,
                  ),
                ),
                direction: direction,
              ),
            );
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(
              direction == TextDirection.ltr
                  ? LogicalKeyboardKey.arrowRight
                  : LogicalKeyboardKey.arrowLeft,
            );
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(chosen, DateTime(2025, 10, 18));
            final CarbonIcon previous = tester.widget<CarbonIcon>(
              find.descendant(
                of: find.bySemanticsLabel(labels.previousMonthLabel),
                matching: find.byType(CarbonIcon),
              ),
            );
            final CarbonIcon next = tester.widget<CarbonIcon>(
              find.descendant(
                of: find.bySemanticsLabel(labels.nextMonthLabel),
                matching: find.byType(CarbonIcon),
              ),
            );
            expect(
              previous.icon,
              direction == TextDirection.ltr
                  ? CarbonIcons.chevronLeft
                  : CarbonIcons.chevronRight,
            );
            expect(
              next.icon,
              direction == TextDirection.ltr
                  ? CarbonIcons.chevronRight
                  : CarbonIcons.chevronLeft,
            );
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
  for (final CarbonDatePickerLocalizations base
      in <CarbonDatePickerLocalizations>[
        germanDateLabels,
        japaneseDateLabels,
      ]) {
    final CarbonDatePickerLocalizations labels = longDateLabels(base);
    for (final double scale in <double>[1.3, 2]) {
      for (final bool fluid in <bool>[false, true]) {
        testWidgets(
          '${base.locale} long date values remain legible at ${scale}x fluid=$fluid',
          (WidgetTester tester) async {
            tester.view.physicalSize = const Size(1200, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              _host(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: 320,
                      child: CarbonDatePicker(
                        labelText: 'Date',
                        value: DateTime(2025, 9, 13),
                        localizations: labels,
                        fluid: fluid,
                        onChanged: (DateTime _) {},
                      ),
                    ),
                    const SizedBox(height: 16),
                    CarbonDateRangePicker(
                      startLabelText: 'From',
                      endLabelText: 'Until',
                      value: CarbonDateRange(
                        DateTime(2025, 9, 13),
                        DateTime(2025, 9, 14),
                      ),
                      localizations: labels,
                      fluid: fluid,
                      onChanged: (CarbonDateRange _) {},
                    ),
                  ],
                ),
                scale: scale,
              ),
            );
            expect(tester.takeException(), isNull);
            expectNoClippedTextAtScale(tester, scale);
            for (final Element element
                in find
                    .text(labels.dateFormat.format(DateTime(2025, 9, 13)))
                    .evaluate()) {
              final Finder text = find.byWidget(element.widget);
              final Finder field = find
                  .ancestor(of: text, matching: find.byType(CarbonField))
                  .first;
              final Rect bounds = tester.getRect(field).inflate(0.5);
              final Rect content = tester.getRect(text);
              expect(bounds.contains(content.topLeft), isTrue);
              expect(bounds.contains(content.bottomRight), isTrue);
            }
          },
        );
      }
    }
  }
  testWidgets('explicit placeholder overrides retain the public named API', (
    WidgetTester tester,
  ) async {
    final CarbonDatePicker single = CarbonDatePicker(
      labelText: 'Date',
      placeholder: 'Choose a date',
      localizations: germanDateLabels,
      onChanged: (DateTime _) {},
    );
    final CarbonDateRangePicker range = CarbonDateRangePicker(
      placeholder: 'Choose a day',
      localizations: germanDateLabels,
      onChanged: (CarbonDateRange _) {},
    );
    expect(single.placeholder, 'Choose a date');
    expect(range.placeholder, 'Choose a day');
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(width: 320, child: single),
            range,
          ],
        ),
      ),
    );
    expect(find.text('Choose a date'), findsOneWidget);
    expect(find.text('Choose a day'), findsNWidgets(2));
  });
  testWidgets(
    'locale changes while open retain focused civil date and controlled value',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final ValueNotifier<CarbonDatePickerLocalizations> labels =
          ValueNotifier<CarbonDatePickerLocalizations>(
            CarbonDatePickerLocalizations.enUS,
          );
      addTearDown(labels.dispose);
      try {
        DateTime? chosen;
        await tester.pumpWidget(
          _host(
            ValueListenableBuilder<CarbonDatePickerLocalizations>(
              valueListenable: labels,
              builder:
                  (
                    BuildContext context,
                    CarbonDatePickerLocalizations value,
                    Widget? _,
                  ) => SizedBox(
                    width: 320,
                    child: CarbonDatePicker(
                      labelText: 'Date',
                      value: DateTime(2025, 10, 17),
                      localizations: value,
                      onChanged: (DateTime value) => chosen = value,
                    ),
                  ),
            ),
          ),
        );
        await tester.tap(find.text('10/17/2025'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        labels.value = germanDateLabels;
        await tester.pumpAndSettle();
        expect(find.text('Oktober 2025'), findsOneWidget);
        expect(find.text('17.10.2025'), findsOneWidget);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('18. Oktober 2025'))
              .flagsCollection
              .isFocused
              .toBoolOrNull(),
          isTrue,
        );
        expect(chosen, isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(chosen, DateTime(2025, 10, 18));
        expect(find.byType(CarbonCalendar), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets('locale changes preserve a range draft and commit it once', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final ValueNotifier<CarbonDatePickerLocalizations> labels =
        ValueNotifier<CarbonDatePickerLocalizations>(
          CarbonDatePickerLocalizations.enUS,
        );
    addTearDown(labels.dispose);
    try {
      final List<CarbonDateRange> commits = <CarbonDateRange>[];
      await tester.pumpWidget(
        _host(
          ValueListenableBuilder<CarbonDatePickerLocalizations>(
            valueListenable: labels,
            builder:
                (
                  BuildContext context,
                  CarbonDatePickerLocalizations value,
                  Widget? _,
                ) => CarbonDateRangePicker(
                  value: CarbonDateRange(
                    DateTime(2025, 10, 17),
                    DateTime(2025, 10, 20),
                  ),
                  localizations: value,
                  onChanged: commits.add,
                ),
          ),
        ),
      );
      await tester.tap(find.text('10/17/2025'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('19'));
      await tester.pumpAndSettle();
      expect(commits, isEmpty);
      labels.value = germanDateLabels;
      await tester.pumpAndSettle();
      expect(find.text('19.10.2025'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('20. Oktober 2025'));
      await tester.pumpAndSettle();
      expect(commits, <CarbonDateRange>[
        CarbonDateRange(DateTime(2025, 10, 19), DateTime(2025, 10, 20)),
      ]);
      expect(find.byType(CarbonCalendar), findsNothing);
    } finally {
      semantics.dispose();
    }
  });
  for (final CarbonDatePickerLocalizations labels
      in <CarbonDatePickerLocalizations>[
        germanDateLabels,
        japaneseDateLabels,
        arabicDateLabels,
      ]) {
    testWidgets('${labels.locale} localized calendar goldens', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'calendar_locale_${labels.locale.languageCode}',
        containsText: true,
        size: const Size(336, 360),
        directions: <TextDirection>{
          labels.locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
        },
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 312,
            child: CarbonCalendar(
              value: DateTime(2025, 10, 17),
              localizations: labels,
              onChanged: (DateTime _) {},
            ),
          ),
        ),
      );
    });
  }
}
