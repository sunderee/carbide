// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/date_localizations.dart';

void main() {
  test(
    'default format preserves existing values and validates civil dates',
    () {
      const CarbonDateFormat format = CarbonDateFormat.enUS;
      expect(format.placeholder, 'mm/dd/yyyy');
      for (final DateTime date in <DateTime>[
        DateTime(2025, 9, 13),
        DateTime(2024, 2, 29),
        DateTime(1, 1, 1),
        DateTime(-44, 3, 15),
      ]) {
        expect(format.tryParse(format.format(date)), date);
      }
      for (final String input in <String>[
        '02/29/2025',
        '04/31/2025',
        '00/10/2025',
        '13/01/2025',
        '01/00/2025',
        'not a date',
        '1/2/2025',
        '01/01/999999999999999999999999',
      ]) {
        expect(format.tryParse(input), isNull, reason: input);
      }
    },
  );
  test('custom locale formats and parsers share their contract', () {
    for (final (_, CarbonDatePickerLocalizations labels, String formatted, _)
        in dateLocaleFixtures) {
      final DateTime date = DateTime(2025, 9, 13);
      expect(labels.dateFormat.format(date), formatted);
      expect(labels.dateFormat.tryParse(formatted), date);
      expect(labels.dateFormat.tryParse('invalid'), isNull);
    }
  });
  test('pattern-derived hints preserve quoted literals and escaped quotes', () {
    for (final (String pattern, String expected) in <(String, String)>[
      ('MM/dd/yyyy', 'mm/dd/yyyy'),
      ('dd.MM.yyyy', 'dd.mm.yyyy'),
      ('yyyy年M月d日', 'yyyy年m月d日'),
      ("'Month:' yyyy LLLL d", "Month: yyyy mmmm d"),
      ("yyyy 'M' MM''dd", "yyyy M mm'dd"),
    ]) {
      final CarbonDateFormat format = CarbonDateFormat(
        pattern: pattern,
        formatter: (DateTime _) => '',
        parser: (String _) => null,
      );
      expect(format.placeholder, expected);
    }
  });
  test(
    'format errors are invalid input while unexpected backend errors surface',
    () {
      final CarbonDateFormat invalid = CarbonDateFormat(
        pattern: 'y',
        formatter: (DateTime _) => '',
        parser: (String _) => throw const FormatException('invalid'),
      );
      expect(invalid.tryParse('bad'), isNull);
      final CarbonDateFormat broken = CarbonDateFormat(
        pattern: 'y',
        formatter: (DateTime _) => '',
        parser: (String _) => throw StateError('broken backend'),
      );
      expect(() => broken.tryParse('bad'), throwsStateError);
    },
  );
}
