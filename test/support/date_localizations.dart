// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

const CarbonDatePickerLocalizations germanDateLabels =
    CarbonDatePickerLocalizations(
      locale: Locale('de', 'DE'),
      monthNames: <String>[
        'Januar',
        'Februar',
        'März',
        'April',
        'Mai',
        'Juni',
        'Juli',
        'August',
        'September',
        'Oktober',
        'November',
        'Dezember',
      ],
      weekdayNames: <String>['So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa'],
      firstDayOfWeek: DateTime.monday,
      previousMonthLabel: 'Vorheriger Monat',
      nextMonthLabel: 'Nächster Monat',
      dateFormat: CarbonDateFormat(
        pattern: 'dd.MM.yyyy',
        formatter: _formatGerman,
        parser: _parseGerman,
      ),
      dayLabelFormatter: _germanDayLabel,
    );
const CarbonDatePickerLocalizations japaneseDateLabels =
    CarbonDatePickerLocalizations(
      locale: Locale('ja', 'JP'),
      monthNames: <String>[
        '1月',
        '2月',
        '3月',
        '4月',
        '5月',
        '6月',
        '7月',
        '8月',
        '9月',
        '10月',
        '11月',
        '12月',
      ],
      weekdayNames: <String>['日', '月', '火', '水', '木', '金', '土'],
      previousMonthLabel: '前の月',
      nextMonthLabel: '次の月',
      monthYearFormatter: _japaneseMonthYear,
      dateFormat: CarbonDateFormat(
        pattern: 'yyyy/MM/dd',
        formatter: _formatJapanese,
        parser: _parseJapanese,
      ),
      dayLabelFormatter: _japaneseDayLabel,
    );
const CarbonDatePickerLocalizations arabicDateLabels =
    CarbonDatePickerLocalizations(
      locale: Locale('ar'),
      monthNames: <String>[
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ],
      weekdayNames: <String>['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'],
      firstDayOfWeek: DateTime.saturday,
      previousMonthLabel: 'الشهر السابق',
      nextMonthLabel: 'الشهر التالي',
      monthYearFormatter: _arabicMonthYear,
      dayFormatter: _arabicDay,
      dateFormat: CarbonDateFormat(
        pattern: 'dd/MM/yyyy',
        formatter: _formatArabic,
        parser: _parseArabic,
      ),
      dayLabelFormatter: _arabicDayLabel,
    );

const List<(String, CarbonDatePickerLocalizations, String, String)>
dateLocaleFixtures = <(String, CarbonDatePickerLocalizations, String, String)>[
  ('en-US', CarbonDatePickerLocalizations.enUS, '09/13/2025', 'September 2025'),
  ('de-DE', germanDateLabels, '13.09.2025', 'September 2025'),
  ('ja-JP', japaneseDateLabels, '2025/09/13', '2025年9月'),
  ('ar', arabicDateLabels, '١٣/٠٩/٢٠٢٥', 'سبتمبر ٢٠٢٥'),
];

String _two(int value) => value.toString().padLeft(2, '0');
String _formatGerman(DateTime date) =>
    '${_two(date.day)}.${_two(date.month)}.${date.year}';
String _formatJapanese(DateTime date) =>
    '${date.year}/${_two(date.month)}/${_two(date.day)}';
String _formatArabic(DateTime date) =>
    arabicDigits('${_two(date.day)}/${_two(date.month)}/${date.year}');
String _germanDayLabel(DateTime date) =>
    '${date.day}. ${germanDateLabels.monthNames[date.month - 1]} ${date.year}';
String _japaneseDayLabel(DateTime date) =>
    '${date.year}年${date.month}月${date.day}日';
String _japaneseMonthYear(DateTime date) => '${date.year}年${date.month}月';
String _arabicMonthYear(DateTime date) =>
    '${arabicDateLabels.monthNames[date.month - 1]} ${arabicDigits('${date.year}')}';
String _arabicDay(DateTime date) => arabicDigits('${date.day}');
String _arabicDayLabel(DateTime date) =>
    '${arabicDigits('${date.day}')} ${_arabicMonthYear(date)}';

String arabicDigits(String text) => text.runes
    .map(
      (int rune) => rune >= 0x30 && rune <= 0x39
          ? String.fromCharCode(rune + 0x630)
          : String.fromCharCode(rune),
    )
    .join();
String latinDigits(String text) => text.runes
    .map(
      (int rune) => rune >= 0x660 && rune <= 0x669
          ? String.fromCharCode(rune - 0x630)
          : String.fromCharCode(rune),
    )
    .join();
DateTime? _parseGerman(String text) => _parseParts(text, '.', false);
DateTime? _parseJapanese(String text) => _parseParts(text, '/', true);
DateTime? _parseArabic(String text) =>
    _parseParts(latinDigits(text), '/', false);
DateTime? _parseParts(String text, String separator, bool yearFirst) {
  final List<String> parts = text.split(separator);
  if (parts.length != 3) return null;
  final int? year = int.tryParse(parts[yearFirst ? 0 : 2]);
  final int? month = int.tryParse(parts[1]);
  final int? day = int.tryParse(parts[yearFirst ? 2 : 0]);
  if (year == null || month == null || day == null) return null;
  try {
    final DateTime date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  } on ArgumentError {
    return null;
  }
}

CarbonDatePickerLocalizations longDateLabels(
  CarbonDatePickerLocalizations base,
) => CarbonDatePickerLocalizations(
  locale: base.locale,
  monthNames: base.monthNames,
  weekdayNames: base.weekdayNames,
  firstDayOfWeek: base.firstDayOfWeek,
  previousMonthLabel: base.previousMonthLabel,
  nextMonthLabel: base.nextMonthLabel,
  monthYearFormatter: base.monthYearFormatter,
  dayFormatter: base.dayFormatter,
  dayLabelFormatter: base.dayLabelFormatter,
  dateFormat: base.locale.languageCode == 'ja'
      ? const CarbonDateFormat(
          pattern: 'Gy年MM月dd日',
          formatter: _formatJapaneseEra,
          parser: _parseJapaneseEra,
        )
      : const CarbonDateFormat(
          pattern: 'dd. MMMM yyyy',
          formatter: _formatLongGerman,
          parser: _parseLongGerman,
        ),
);
String _formatLongGerman(DateTime date) =>
    '${date.day}. ${germanDateLabels.monthNames[date.month - 1]} ${date.year}';
DateTime? _parseLongGerman(String text) {
  final List<String> parts = text.split(' ');
  if (parts.length != 3) return null;
  final int month = germanDateLabels.monthNames.indexOf(parts[1]) + 1;
  if (month == 0) return null;
  return _parseParts(
    '${parts[0].replaceAll('.', '')}/$month/${parts[2]}',
    '/',
    false,
  );
}

String _formatJapaneseEra(DateTime date) =>
    '令和${date.year - 2018}年${_two(date.month)}月${_two(date.day)}日';
DateTime? _parseJapaneseEra(String text) {
  final RegExpMatch? match = RegExp(r'^令和(\d+)年(\d{2})月(\d{2})日$')
      .firstMatch(text);
  if (match == null) return null;
  final int? year = int.tryParse(match[1]!);
  if (year == null || year <= 0) return null;
  return _parseParts('${year + 2018}/${match[2]}/${match[3]}', '/', true);
}
