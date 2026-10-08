// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show immutable;

/// Formats a civil date for display.
typedef CarbonDateFormatter = String Function(DateTime date);

/// Parses a formatted civil date, returning null when the input is invalid.
typedef CarbonDateParser = DateTime? Function(String text);

/// A date's formatting pattern and matching formatter/parser pair.
///
/// [pattern] is the concrete date pattern used by [formatter] and [parser],
/// including its field order and separators. [placeholder] derives from that
/// pattern, so the picker does not maintain a second independent format hint.
/// Consumers can adapt `intl.DateFormat` or their own backend without adding
/// a dependency to Carbide. The backend owns date-pattern interpretation.
@immutable
class CarbonDateFormat {
  /// Creates a format whose callbacks use the same [pattern].
  const CarbonDateFormat({
    required this.pattern,
    required this.formatter,
    required this.parser,
  }) : assert(pattern.length > 0, 'The date pattern must not be empty.');

  /// The existing month/day/year format, with strict civil-date parsing.
  static const CarbonDateFormat enUS = CarbonDateFormat(
    pattern: 'MM/dd/yyyy',
    formatter: _formatEnUS,
    parser: _parseEnUS,
  );

  /// The concrete date pattern shared by both callbacks.
  final String pattern;

  /// Formats a date with [pattern].
  final CarbonDateFormatter formatter;

  /// Parses a date with [pattern].
  final CarbonDateParser parser;

  /// A hint derived from [pattern], with month tokens shown as lowercase `m`.
  ///
  /// ICU-style quoted literals keep their spelling and escape quotes are
  /// unwrapped. This preserves the existing `mm/dd/yyyy` default without
  /// converting a literal `M` into a month token.
  String get placeholder => _placeholderFromPattern(pattern);

  /// Formats [date] with the configured backend.
  String format(DateTime date) => formatter(date);

  /// Parses [text], returning null for invalid input or a [FormatException].
  ///
  /// Other backend errors propagate so programming mistakes are visible.
  /// Calendar-only pickers do not accept typed text; this callback lets
  /// consumers use the same format in their own text-entry workflows.
  DateTime? tryParse(String text) {
    try {
      return parser(text);
    } on FormatException {
      return null;
    }
  }
}

String _placeholderFromPattern(String pattern) {
  final StringBuffer result = StringBuffer();
  bool quoted = false;
  for (int i = 0; i < pattern.length; i++) {
    final String character = pattern[i];
    if (character == "'") {
      if (i + 1 < pattern.length && pattern[i + 1] == "'") {
        result.write("'");
        i++;
      } else {
        quoted = !quoted;
      }
    } else {
      result.write(
        !quoted && (character == 'M' || character == 'L') ? 'm' : character,
      );
    }
  }
  return result.toString();
}

String _formatEnUS(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.day.toString().padLeft(2, '0')}/${date.year}';

DateTime? _parseEnUS(String text) {
  final RegExpMatch? match = RegExp(r'^(\d{2})/(\d{2})/(-?\d+)$')
      .firstMatch(text.trim());
  if (match == null) return null;
  final int month = int.parse(match[1]!);
  final int day = int.parse(match[2]!);
  final int? year = int.tryParse(match[3]!);
  if (year == null) return null;
  try {
    final DateTime date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  } on ArgumentError {
    return null;
  }
}

const List<String> _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const List<String> _weekdayNames = <String>[
  'Su',
  'Mo',
  'Tu',
  'We',
  'Th',
  'Fr',
  'Sa',
];

/// Injectable date-picker text, week layout and formatting.
///
/// Defaults preserve the existing English, Sunday-first calendar. Supply
/// localized labels and a [dateFormat] to the calendar, single picker or range
/// picker. Keep [monthNames] and [weekdayNames] immutable after construction.
/// Direction comes from the widget's ambient directionality, rather than being
/// inferred from these labels. Updating this object does not change selection.
@immutable
class CarbonDatePickerLocalizations {
  /// Creates the calendar's labels and formatting policy.
  const CarbonDatePickerLocalizations({
    this.locale = const Locale('en', 'US'),
    this.monthNames = _monthNames,
    this.weekdayNames = _weekdayNames,
    this.firstDayOfWeek = DateTime.sunday,
    this.dateFormat = CarbonDateFormat.enUS,
    this.previousMonthLabel = 'Previous month',
    this.nextMonthLabel = 'Next month',
    this.monthYearFormatter,
    this.dayFormatter,
    this.dayLabelFormatter,
  }) : assert(
         firstDayOfWeek >= 1 && firstDayOfWeek <= 7,
         'Use DateTime.monday through DateTime.sunday.',
       );

  /// The default English localization.
  static const CarbonDatePickerLocalizations enUS =
      CarbonDatePickerLocalizations();

  /// The locale used to shape calendar and field text.
  final Locale locale;

  /// Month names indexed January through December.
  final List<String> monthNames;

  /// Weekday names indexed Sunday through Saturday, independent of week start.
  final List<String> weekdayNames;

  /// The first weekday, using [DateTime.monday] through [DateTime.sunday].
  final int firstDayOfWeek;

  /// The common format for field values, parsing and placeholder hints.
  final CarbonDateFormat dateFormat;

  /// The accessible previous-month navigation label.
  final String previousMonthLabel;

  /// The accessible next-month navigation label.
  final String nextMonthLabel;

  /// Optional month/year heading formatter, including locale-specific ordering.
  final CarbonDateFormatter? monthYearFormatter;

  /// Optional visible day-number formatter, for localized numbering systems.
  final CarbonDateFormatter? dayFormatter;

  /// Optional complete accessible day label; defaults to the visible number.
  final CarbonDateFormatter? dayLabelFormatter;

  /// Formats a month/year heading, falling back to [monthNames] and the year.
  String formatMonthYear(DateTime date) =>
      monthYearFormatter?.call(date) ??
      '${monthNames[date.month - 1]} ${date.year}';

  /// Formats the visible day number, retaining the existing numeric default.
  String formatDay(DateTime date) => dayFormatter?.call(date) ?? '${date.day}';

  /// Formats the accessible day label independently of its visible number.
  String formatDayLabel(DateTime date) =>
      dayLabelFormatter?.call(date) ?? formatDay(date);
}
