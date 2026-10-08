// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/foundation.dart' show immutable;

/// The hour cycle used by a time format and its coordinated period selector.
enum CarbonTimeHourCycle {
  /// Hours 1 through 12, with an AM/PM selector owned by the time picker.
  twelveHour,

  /// Hours 0 through 23, without a built-in AM/PM selector.
  twentyFourHour,
}

/// The half of a day selected for a twelve-hour time.
enum CarbonTimePeriod {
  /// Midnight through the minute before noon.
  am,

  /// Noon through the minute before midnight.
  pm,
}

/// A civil time without a date or timezone, stored in the 24-hour cycle.
@immutable
class CarbonTimeValue {
  /// Creates a time with [hour] in 0–23 and [minute] in 0–59.
  const CarbonTimeValue({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  /// The hour in the 24-hour cycle.
  final int hour;

  /// The minute within the hour.
  final int minute;

  /// The half of the day containing this time.
  CarbonTimePeriod get period =>
      hour < 12 ? CarbonTimePeriod.am : CarbonTimePeriod.pm;

  @override
  bool operator ==(Object other) =>
      other is CarbonTimeValue && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Formats a canonical civil time with a configured concrete pattern.
typedef CarbonTimeFormatter = String Function(CarbonTimeValue time);

/// Parses text using the selected period, returning null for invalid input.
///
/// Twenty-four-hour formats ignore [period]. Twelve-hour formats convert the
/// entered hour and [period] to a canonical 0–23 hour.
typedef CarbonTimeParser = CarbonTimeValue? Function(
  String text,
  CarbonTimePeriod period,
);

/// A time's concrete pattern and matching formatter/parser pair.
///
/// Like `CarbonDateFormat`, this accepts a consumer's formatting backend
/// without a runtime dependency. The picker supplies an AM/PM selector exactly
/// when [hourCycle] is [CarbonTimeHourCycle.twelveHour]; the parser and selector
/// share the same typed period. Callbacks own locale-specific digits, field
/// ordering and separators.
@immutable
class CarbonTimeFormat {
  /// Creates a format whose callbacks use [pattern] and [hourCycle].
  const CarbonTimeFormat({
    required this.pattern,
    required this.formatter,
    required this.parser,
    required this.hourCycle,
  }) : assert(pattern.length > 0, 'The time pattern must not be empty.');

  /// Colon-separated 24-hour times, accepting `3:5` and displaying `03:05`.
  static const CarbonTimeFormat twentyFourHour = CarbonTimeFormat(
    pattern: 'HH:mm',
    formatter: _formatTwentyFourHour,
    parser: _parseTwentyFourHour,
    hourCycle: CarbonTimeHourCycle.twentyFourHour,
  );

  /// Colon-separated 12-hour times, paired with the picker's AM/PM selector.
  ///
  /// The period is displayed in the selector, rather than duplicated in the
  /// text field. `12:00 AM` represents midnight; `12:00 PM` represents noon.
  static const CarbonTimeFormat twelveHour = CarbonTimeFormat(
    pattern: 'hh:mm',
    formatter: _formatTwelveHour,
    parser: _parseTwelveHour,
    hourCycle: CarbonTimeHourCycle.twelveHour,
  );

  /// The concrete time pattern shared by both callbacks.
  final String pattern;

  /// Formats a canonical time with [pattern].
  final CarbonTimeFormatter formatter;

  /// Parses the field text with [pattern] and the selected period.
  final CarbonTimeParser parser;

  /// The hour policy that also controls the picker's period selector.
  final CarbonTimeHourCycle hourCycle;

  /// A pattern-derived hint with unquoted hour tokens shown as lowercase `h`.
  String get placeholder {
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
        result.write(!quoted && character == 'H' ? 'h' : character);
      }
    }
    return result.toString();
  }

  /// Formats [time] with the configured backend.
  String format(CarbonTimeValue time) => formatter(time);

  /// Parses [text], returning null for invalid input or a [FormatException].
  ///
  /// Twelve-hour backends must return a time in the selected [period]. Other
  /// backend errors propagate, as with the date formatter, so programming
  /// mistakes remain visible.
  CarbonTimeValue? tryParse(
    String text, {
    CarbonTimePeriod period = CarbonTimePeriod.am,
  }) {
    try {
      final CarbonTimeValue? result = parser(text, period);
      if (result == null ||
          result.hour < 0 ||
          result.hour > 23 ||
          result.minute < 0 ||
          result.minute > 59 ||
          (hourCycle == CarbonTimeHourCycle.twelveHour &&
              result.period != period)) {
        return null;
      }
      return result;
    } on FormatException {
      return null;
    }
  }
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _formatTwentyFourHour(CarbonTimeValue time) =>
    '${_twoDigits(time.hour)}:${_twoDigits(time.minute)}';

String _formatTwelveHour(CarbonTimeValue time) =>
    '${_twoDigits(time.hour % 12 == 0 ? 12 : time.hour % 12)}:'
    '${_twoDigits(time.minute)}';

(int, int)? _parts(String text) {
  final RegExpMatch? match = RegExp(r'^(\d{1,2}):(\d{1,2})$')
      .firstMatch(text.trim());
  if (match == null) return null;
  final int hour = int.parse(match[1]!);
  final int minute = int.parse(match[2]!);
  return minute <= 59 ? (hour, minute) : null;
}

CarbonTimeValue? _parseTwentyFourHour(String text, CarbonTimePeriod _) {
  final (int, int)? parts = _parts(text);
  if (parts == null || parts.$1 > 23) return null;
  return CarbonTimeValue(hour: parts.$1, minute: parts.$2);
}

CarbonTimeValue? _parseTwelveHour(String text, CarbonTimePeriod period) {
  final (int, int)? parts = _parts(text);
  if (parts == null || parts.$1 < 1 || parts.$1 > 12) return null;
  return CarbonTimeValue(
    hour: parts.$1 % 12 + (period == CarbonTimePeriod.pm ? 12 : 0),
    minute: parts.$2,
  );
}
