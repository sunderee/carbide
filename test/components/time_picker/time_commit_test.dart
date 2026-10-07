// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(
  Widget picker, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
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
        child: TapRegionSurface(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: Column(
                children: <Widget>[
                  picker,
                  CarbonButton(
                    label: 'Outside',
                    onPressed: () =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

Future<void> _enter(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}

Future<void> _commit(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump();
}

void main() {
  testWidgets('unconfigured picker preserves arbitrary immediate typing', (
    WidgetTester tester,
  ) async {
    final List<String> edits = <String>[];
    await tester.pumpWidget(
      _host(CarbonTimePicker(labelText: 'Time', onChanged: edits.add)),
    );
    await _enter(tester, 'banana');
    expect(edits, <String>['banana']);
    await _commit(tester);
    expect(_text(tester), 'banana');
    expect(edits, <String>['banana']);
    expect(
      tester.widget<CarbonField>(find.byType(CarbonField)).status,
      CarbonFieldStatus.none,
    );
  });

  for (final bool normalize in <bool>[true, false]) {
    testWidgets('formatted draft commits once with normalize=$normalize', (
      WidgetTester tester,
    ) async {
      final List<String> edits = <String>[];
      final List<CarbonTimeValue?> times = <CarbonTimeValue?>[];
      await tester.pumpWidget(
        _host(
          CarbonTimePicker(
            labelText: 'Time',
            format: CarbonTimeFormat.twentyFourHour,
            normalizeOnCommit: normalize,
            onChanged: edits.add,
            onCommitted: times.add,
          ),
        ),
      );
      await _enter(tester, '3:5');
      expect(edits, isEmpty);
      expect(times, isEmpty);
      await _commit(tester);
      final String expected = normalize ? '03:05' : '3:5';
      expect(_text(tester), expected);
      expect(edits, <String>[expected]);
      expect(times, <CarbonTimeValue?>[
        const CarbonTimeValue(hour: 3, minute: 5),
      ]);
      await _commit(tester);
      await tester.tap(find.text('Outside'));
      await tester.pump();
      expect(edits, hasLength(1));
      expect(times, hasLength(1));
    });
  }

  testWidgets(
    'leaving the focus group commits and Done follows the same model',
    (WidgetTester tester) async {
      final List<String> edits = <String>[];
      await tester.pumpWidget(
        _host(
          CarbonTimePicker(
            labelText: 'Time',
            format: CarbonTimeFormat.twentyFourHour,
            onChanged: edits.add,
          ),
        ),
      );
      await _enter(tester, '3:5');
      await tester.tap(find.text('Outside'));
      await tester.pump();
      expect(edits, <String>['03:05']);
      await _enter(tester, '4:6');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(edits, <String>['03:05', '04:06']);
      expect(_text(tester), '04:06');
    },
  );

  for (final String draft in <String>['banana', '3', '3:', '24:00', '03:60']) {
    testWidgets(
      'invalid commit retains "$draft" and uses existing error chrome',
      (WidgetTester tester) async {
        final List<String> edits = <String>[];
        await tester.pumpWidget(
          _host(
            CarbonTimePicker(
              labelText: 'Time',
              format: CarbonTimeFormat.twentyFourHour,
              invalidText: 'Enter a valid time',
              onChanged: edits.add,
            ),
          ),
        );
        await _enter(tester, draft);
        expect(find.text('Enter a valid time'), findsNothing);
        await _commit(tester);
        expect(_text(tester), draft);
        expect(edits, isEmpty);
        expect(find.text('Enter a valid time'), findsOneWidget);
        expect(
          tester.widget<CarbonField>(find.byType(CarbonField)).status,
          CarbonFieldStatus.invalid,
        );
        await _enter(tester, '3:5');
        await _commit(tester);
        expect(find.text('Enter a valid time'), findsNothing);
        expect(edits, <String>['03:05']);
      },
    );
  }

  testWidgets('empty drafts clear a previously committed time exactly once', (
    WidgetTester tester,
  ) async {
    final List<CarbonTimeValue?> times = <CarbonTimeValue?>[];
    await tester.pumpWidget(
      _host(
        CarbonTimePicker(
          labelText: 'Time',
          initialValue: '09:30',
          format: CarbonTimeFormat.twentyFourHour,
          onCommitted: times.add,
        ),
      ),
    );
    await _enter(tester, '');
    await _commit(tester);
    expect(_text(tester), '');
    expect(times, <CarbonTimeValue?>[null]);
    await _commit(tester);
    expect(times, hasLength(1));
  });

  for (final TextDirection direction in TextDirection.values) {
    for (final CarbonTimePeriod period in CarbonTimePeriod.values) {
      testWidgets(
        '12-hour selection coordinates midnight/noon $period $direction',
        (WidgetTester tester) async {
          final List<CarbonTimeValue?> times = <CarbonTimeValue?>[];
          final List<CarbonTimePeriod> periods = <CarbonTimePeriod>[];
          await tester.pumpWidget(
            _host(
              CarbonTimePicker(
                labelText: 'Time',
                format: CarbonTimeFormat.twelveHour,
                initialPeriod: period,
                onCommitted: times.add,
                onPeriodChanged: periods.add,
              ),
              direction: direction,
            ),
          );
          expect(
            find.byType(CarbonTimePickerSelect<CarbonTimePeriod>),
            findsOneWidget,
          );
          await _enter(tester, '12:0');
          await _commit(tester);
          expect(_text(tester), '12:00');
          expect(times, <CarbonTimeValue?>[
            CarbonTimeValue(
              hour: period == CarbonTimePeriod.am ? 0 : 12,
              minute: 0,
            ),
          ]);
          final CarbonTimePickerSelect<CarbonTimePeriod> select = tester.widget(
            find.byType(CarbonTimePickerSelect<CarbonTimePeriod>),
          );
          final CarbonTimePeriod next = period == CarbonTimePeriod.am
              ? CarbonTimePeriod.pm
              : CarbonTimePeriod.am;
          select.onChanged!(next);
          await tester.pump();
          expect(periods, <CarbonTimePeriod>[next]);
          expect(
            times.last,
            CarbonTimeValue(
              hour: next == CarbonTimePeriod.am ? 0 : 12,
              minute: 0,
            ),
          );
          expect(times, hasLength(2));
          await tester.tap(find.text('Outside'));
          await tester.pump();
          expect(times, hasLength(2));
        },
      );
    }
  }

  testWidgets(
    'moving into period select preserves a draft until period choice',
    (WidgetTester tester) async {
      final List<CarbonTimeValue?> times = <CarbonTimeValue?>[];
      await tester.pumpWidget(
        _host(
          CarbonTimePicker(
            labelText: 'Time',
            format: CarbonTimeFormat.twelveHour,
            onCommitted: times.add,
          ),
        ),
      );
      await _enter(tester, '3:5');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(times, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(times, <CarbonTimeValue?>[
        const CarbonTimeValue(hour: 15, minute: 5),
      ]);
      expect(_text(tester), '03:05');
    },
  );

  testWidgets('24-hour mode omits period select and keeps timezone children', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonTimePicker(
          labelText: 'Time',
          format: CarbonTimeFormat.twentyFourHour,
          children: <Widget>[
            CarbonTimePickerSelect<String>(
              labelText: 'Timezone',
              value: 'UTC',
              items: <CarbonSelectEntry<String>>[
                CarbonSelectItem<String>(value: 'UTC', label: 'UTC'),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.byType(CarbonTimePickerSelect<CarbonTimePeriod>), findsNothing);
    expect(find.text('UTC'), findsOneWidget);
  });

  testWidgets('IME candidate Enter remains draft until composition ends', (
    WidgetTester tester,
  ) async {
    final List<String> edits = <String>[];
    await tester.pumpWidget(
      _host(
        CarbonTimePicker(
          labelText: 'Time',
          format: CarbonTimeFormat.twentyFourHour,
          onChanged: edits.add,
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '3:5',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      ),
    );
    await tester.pump();
    await _commit(tester);
    expect(edits, isEmpty);
    expect(_text(tester), '3:5');
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '3:5',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    await _commit(tester);
    expect(edits, <String>['03:05']);
  });

  testWidgets('localized format, hint and period labels remain coherent', (
    WidgetTester tester,
  ) async {
    final List<String> edits = <String>[];
    final CarbonTimeFormat format = CarbonTimeFormat(
      pattern: 'HH.mm',
      hourCycle: CarbonTimeHourCycle.twentyFourHour,
      formatter: (CarbonTimeValue time) =>
          CarbonTimeFormat.twentyFourHour.format(time).replaceAll(':', '.'),
      parser: (String text, CarbonTimePeriod _) =>
          CarbonTimeFormat.twentyFourHour.tryParse(text.replaceAll('.', ':')),
    );
    await tester.pumpWidget(
      _host(
        CarbonTimePicker(
          labelText: 'Zeit',
          format: format,
          onChanged: edits.add,
        ),
      ),
    );
    expect(find.text('hh.mm'), findsOneWidget);
    await _enter(tester, '3.5');
    await _commit(tester);
    expect(edits, <String>['03.05']);
    await tester.pumpWidget(
      _host(
        const CarbonTimePicker(
          key: ValueKey<String>('localized-period'),
          labelText: 'Zeit',
          format: CarbonTimeFormat.twelveHour,
          amLabel: 'vorm.',
          pmLabel: 'nachm.',
          periodLabel: 'Tageshälfte',
          placeholder: 'Stunden:Minuten',
        ),
      ),
    );
    expect(find.text('Stunden:Minuten'), findsOneWidget);
    expect(find.text('vorm.'), findsOneWidget);
    expect(
      tester
          .widget<CarbonTimePickerSelect<CarbonTimePeriod>>(
            find.byType(CarbonTimePickerSelect<CarbonTimePeriod>),
          )
          .labelText,
      'Tageshälfte',
    );
  });

  for (final bool disabled in <bool>[false, true]) {
    testWidgets(
      'locked picker cannot commit or change period disabled=$disabled',
      (WidgetTester tester) async {
        final TextEditingController controller = TextEditingController(
          text: '3:5',
        );
        addTearDown(controller.dispose);
        final List<String> edits = <String>[];
        final List<CarbonTimePeriod> periods = <CarbonTimePeriod>[];
        await tester.pumpWidget(
          _host(
            CarbonTimePicker(
              labelText: 'Time',
              format: CarbonTimeFormat.twelveHour,
              controller: controller,
              disabled: disabled,
              readOnly: !disabled,
              onChanged: edits.add,
              onPeriodChanged: periods.add,
            ),
          ),
        );
        final CarbonTimePickerSelect<CarbonTimePeriod> select = tester.widget(
          find.byType(CarbonTimePickerSelect<CarbonTimePeriod>),
        );
        expect(select.disabled, isTrue);
        select.onChanged!(CarbonTimePeriod.pm);
        await _commit(tester);
        expect(edits, isEmpty);
        expect(periods, isEmpty);
        expect(controller.text, '3:5');
      },
    );
  }

  testWidgets('invalid period edit retains draft without reporting a time', (
    WidgetTester tester,
  ) async {
    final List<CarbonTimeValue?> times = <CarbonTimeValue?>[];
    final List<CarbonTimePeriod> periods = <CarbonTimePeriod>[];
    await tester.pumpWidget(
      _host(
        CarbonTimePicker(
          labelText: 'Time',
          format: CarbonTimeFormat.twelveHour,
          invalidText: 'Invalid time',
          onCommitted: times.add,
          onPeriodChanged: periods.add,
        ),
      ),
    );
    await _enter(tester, '13:00');
    tester
        .widget<CarbonTimePickerSelect<CarbonTimePeriod>>(
          find.byType(CarbonTimePickerSelect<CarbonTimePeriod>),
        )
        .onChanged!(CarbonTimePeriod.pm);
    await tester.pump();
    expect(periods, <CarbonTimePeriod>[CarbonTimePeriod.pm]);
    expect(times, isEmpty);
    expect(_text(tester), '13:00');
    expect(find.text('Invalid time'), findsOneWidget);
    await _enter(tester, '1:0');
    await _commit(tester);
    expect(times, <CarbonTimeValue?>[
      const CarbonTimeValue(hour: 13, minute: 0),
    ]);
    expect(find.text('Invalid time'), findsNothing);
  });

  testWidgets(
    'parent rebuild preserves draft, then a format change uses new policy',
    (WidgetTester tester) async {
      final List<String> edits = <String>[];
      final List<CarbonTimeValue?> times = <CarbonTimeValue?>[];
      Widget picker(CarbonTimeFormat format) => CarbonTimePicker(
        labelText: 'Time',
        format: format,
        onChanged: edits.add,
        onCommitted: times.add,
        initialPeriod: CarbonTimePeriod.pm,
      );
      await tester.pumpWidget(_host(picker(CarbonTimeFormat.twentyFourHour)));
      await _enter(tester, '3:5');
      await tester.pumpWidget(_host(picker(CarbonTimeFormat.twentyFourHour)));
      expect(_text(tester), '3:5');
      expect(edits, isEmpty);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.pumpWidget(_host(picker(CarbonTimeFormat.twelveHour)));
      expect(_text(tester), '3:5');
      expect(find.text('PM'), findsOneWidget);
      await _commit(tester);
      expect(edits, <String>['03:05']);
      expect(times, <CarbonTimeValue?>[
        const CarbonTimeValue(hour: 15, minute: 5),
      ]);
    },
  );

  testWidgets(
    'controller and focus replacement discard outgoing validation safely',
    (WidgetTester tester) async {
      final TextEditingController first = TextEditingController();
      final TextEditingController second = TextEditingController(text: '4:6');
      final FocusNode firstFocus = FocusNode();
      final FocusNode secondFocus = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      addTearDown(firstFocus.dispose);
      addTearDown(secondFocus.dispose);
      final List<String> edits = <String>[];
      Widget picker(TextEditingController? controller, FocusNode focus) =>
          CarbonTimePicker(
            labelText: 'Time',
            format: CarbonTimeFormat.twentyFourHour,
            controller: controller,
            focusNode: focus,
            invalidText: 'Invalid time',
            onChanged: edits.add,
          );
      await tester.pumpWidget(_host(picker(first, firstFocus)));
      await _enter(tester, 'banana');
      await _commit(tester);
      expect(find.text('Invalid time'), findsOneWidget);
      await tester.pumpWidget(_host(picker(second, secondFocus)));
      await tester.pump();
      expect(_text(tester), '4:6');
      expect(find.text('Invalid time'), findsNothing);
      expect(secondFocus.hasFocus, isTrue);
      first.text = '5:7';
      await tester.pump();
      expect(_text(tester), '4:6');
      await _commit(tester);
      expect(second.text, '04:06');
      expect(edits, <String>['04:06']);
      second.selection = const TextSelection(baseOffset: 1, extentOffset: 4);
      await tester.pumpWidget(_host(picker(null, secondFocus)));
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.value,
        second.value,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      first.text = 'caller still owns first';
      second.text = 'caller still owns second';
      firstFocus.addListener(() {});
      secondFocus.addListener(() {});
    },
  );

  testWidgets(
    'external invalid status and message retain priority after valid commit',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonTimePicker(
            labelText: 'Time',
            format: CarbonTimeFormat.twentyFourHour,
            invalid: true,
            invalidText: 'Server rejected time',
            warn: true,
            warnText: 'Warning',
            helperText: 'Help',
          ),
        ),
      );
      await _enter(tester, '3:5');
      await _commit(tester);
      expect(find.text('Server rejected time'), findsOneWidget);
      expect(find.text('Warning'), findsNothing);
      expect(find.text('Help'), findsNothing);
      expect(
        tester.widget<CarbonField>(find.byType(CarbonField)).status,
        CarbonFieldStatus.invalid,
      );
    },
  );

  testWidgets('built-in period follows fluid treatment and translated width', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonTimePicker(
          labelText: 'Time',
          format: CarbonTimeFormat.twelveHour,
          fluid: true,
          amLabel: 'vormittags',
          pmLabel: 'nachmittags',
          periodWidth: 140,
        ),
      ),
    );
    final CarbonTimePickerSelect<CarbonTimePeriod> period = tester.widget(
      find.byType(CarbonTimePickerSelect<CarbonTimePeriod>),
    );
    expect(period.fluid, isTrue);
    expect(period.width, 140);
    expect(
      tester
          .widget<CarbonSelect<CarbonTimePeriod>>(
            find.byType(CarbonSelect<CarbonTimePeriod>),
          )
          .fluid,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  for (final bool fluid in <bool>[false, true]) {
    for (final double scale in <double>[1.3, 2]) {
      testWidgets('formatted fields accommodate scale=$scale fluid=$fluid', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _host(
            CarbonTimePicker(
              labelText: 'Time',
              format: CarbonTimeFormat.twelveHour,
              initialValue: '03:05',
              fluid: fluid,
            ),
            scale: scale,
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('AM'), findsOneWidget);
        expect(
          tester
              .widget<CarbonTimePickerSelect<CarbonTimePeriod>>(
                find.byType(CarbonTimePickerSelect<CarbonTimePeriod>),
              )
              .width,
          closeTo(CarbonTimePickerSelect.defaultWidth * scale, 0.01),
        );
      });
    }
  }

  testWidgets('formatted 12-hour picker across themes and RTL', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'time_picker_formatted',
      containsText: true,
      size: const Size(240, 100),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => const Align(
        alignment: AlignmentDirectional.topStart,
        child: CarbonTimePicker(
          labelText: 'Time',
          initialValue: '03:05',
          initialPeriod: CarbonTimePeriod.pm,
          format: CarbonTimeFormat.twelveHour,
        ),
      ),
    );
  });

  testWidgets('parse errors reuse invalid chrome across themes', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'time_picker_parse_error',
      containsText: true,
      size: const Size(240, 110),
      builder: (_) => const Align(
        alignment: Alignment.topLeft,
        child: CarbonTimePicker(
          labelText: 'Time',
          initialValue: 'banana',
          format: CarbonTimeFormat.twentyFourHour,
          invalidText: 'Enter a valid time',
        ),
      ),
      afterPump: (WidgetTester tester) async {
        await _enter(tester, 'banana');
        await _commit(tester);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets(
    'fluid formatted time grows at twofold scaling across themes/RTL',
    (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'time_picker_formatted_fluid_scale2',
        containsText: true,
        size: const Size(300, 250),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(2)),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => const Align(
          alignment: AlignmentDirectional.topStart,
          child: CarbonTimePicker(
            labelText: 'Time',
            initialValue: '03:05',
            initialPeriod: CarbonTimePeriod.pm,
            fluid: true,
            format: CarbonTimeFormat.twelveHour,
          ),
        ),
      );
    },
  );
}
