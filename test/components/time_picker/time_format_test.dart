// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('24-hour parsing normalizes short input and civil boundaries', () {
    const CarbonTimeFormat format = CarbonTimeFormat.twentyFourHour;
    for (final (String input, int hour, int minute, String output)
        in <(String, int, int, String)>[
          ('3:5', 3, 5, '03:05'),
          (' 0:0 ', 0, 0, '00:00'),
          ('23:59', 23, 59, '23:59'),
          ('12:0', 12, 0, '12:00'),
        ]) {
      final CarbonTimeValue expected = CarbonTimeValue(
        hour: hour,
        minute: minute,
      );
      expect(format.tryParse(input), expected);
      expect(format.format(expected), output);
      expect(format.tryParse(output), expected);
    }
    expect(format.placeholder, 'hh:mm');
  });

  test('12-hour parsing distinguishes noon and midnight with the period', () {
    const CarbonTimeFormat format = CarbonTimeFormat.twelveHour;
    for (final CarbonTimePeriod period in CarbonTimePeriod.values) {
      for (final int hour in <int>[1, 3, 11, 12]) {
        final CarbonTimeValue expected = CarbonTimeValue(
          hour: hour % 12 + (period == CarbonTimePeriod.pm ? 12 : 0),
          minute: 5,
        );
        expect(format.tryParse('$hour:5', period: period), expected);
        expect(expected.period, period);
        expect(
          format.tryParse(format.format(expected), period: period),
          expected,
        );
      }
    }
    expect(format.format(const CarbonTimeValue(hour: 0, minute: 0)), '12:00');
    expect(format.format(const CarbonTimeValue(hour: 12, minute: 0)), '12:00');
  });

  for (final String input in <String>[
    '',
    ' ',
    'banana',
    '3',
    '3:',
    ':5',
    '24:00',
    '25:1',
    '3:60',
    '-1:30',
    '3:-5',
    '003:05',
    '3:005',
    '3.5',
    '3:5 PM',
  ]) {
    test('24-hour rejects partial or out-of-range input "$input"', () {
      expect(CarbonTimeFormat.twentyFourHour.tryParse(input), isNull);
    });
  }

  for (final String input in <String>['0:00', '13:00', '23:59', '12:60']) {
    test('12-hour rejects an incompatible hour or minute "$input"', () {
      for (final CarbonTimePeriod period in CarbonTimePeriod.values) {
        expect(
          CarbonTimeFormat.twelveHour.tryParse(input, period: period),
          isNull,
        );
      }
    });
  }

  test('value equality, hashing and const civil ranges', () {
    const CarbonTimeValue a = CarbonTimeValue(hour: 3, minute: 5);
    expect(a, const CarbonTimeValue(hour: 3, minute: 5));
    expect(a.hashCode, const CarbonTimeValue(hour: 3, minute: 5).hashCode);
    expect(a, isNot(const CarbonTimeValue(hour: 3, minute: 6)));
    expect(() => CarbonTimeValue(hour: 24, minute: 0), throwsAssertionError);
    expect(() => CarbonTimeValue(hour: 0, minute: 60), throwsAssertionError);
  });

  test(
    'format callbacks preserve locale separator and quoted hint literals',
    () {
      final CarbonTimeFormat format = CarbonTimeFormat(
        pattern: "HH'.'mm 'H'",
        hourCycle: CarbonTimeHourCycle.twentyFourHour,
        formatter: (CarbonTimeValue value) =>
            CarbonTimeFormat.twentyFourHour.format(value).replaceAll(':', '.'),
        parser: (String text, CarbonTimePeriod period) =>
            CarbonTimeFormat.twentyFourHour.tryParse(text.replaceAll('.', ':')),
      );
      const CarbonTimeValue expected = CarbonTimeValue(hour: 3, minute: 5);
      expect(format.tryParse('3.5'), expected);
      expect(format.format(expected), '03.05');
      expect(format.placeholder, 'hh.mm H');
    },
  );

  test('invalid period conversion and format failures do not become times', () {
    CarbonTimeValue? parser(String text, CarbonTimePeriod period) =>
        const CarbonTimeValue(hour: 3, minute: 5);
    final CarbonTimeFormat format = CarbonTimeFormat(
      pattern: 'hh:mm',
      formatter: CarbonTimeFormat.twelveHour.format,
      parser: parser,
      hourCycle: CarbonTimeHourCycle.twelveHour,
    );
    expect(format.tryParse('3:5', period: CarbonTimePeriod.pm), isNull);
    final CarbonTimeFormat invalid = CarbonTimeFormat(
      pattern: 'HH:mm',
      formatter: CarbonTimeFormat.twentyFourHour.format,
      parser: (_, _) => throw const FormatException('Invalid time'),
      hourCycle: CarbonTimeHourCycle.twentyFourHour,
    );
    expect(invalid.tryParse('banana'), isNull);
    final CarbonTimeFormat broken = CarbonTimeFormat(
      pattern: 'HH:mm',
      formatter: CarbonTimeFormat.twentyFourHour.format,
      parser: (_, _) => throw StateError('Backend bug'),
      hourCycle: CarbonTimeHourCycle.twentyFourHour,
    );
    expect(() => broken.tryParse('3:5'), throwsStateError);
  });
}
