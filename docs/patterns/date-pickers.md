# Date picker localization

`CarbonCalendar`, `CarbonDatePicker` and `CarbonDateRangePicker` accept a
`CarbonDatePickerLocalizations` object. The default keeps English month and
weekday labels, a Sunday-first week and the existing `mm/dd/yyyy` field hint.
Applications supply translated field labels, read-only hints and validation
messages through the existing widget arguments.

A localization supplies twelve January–December month names, seven
Sunday–Saturday weekday names and a first weekday using `DateTime.monday`
through `DateTime.sunday`. The calendar reorders both its weekday headers and
day cells from that weekday. Previous/next month labels, the month/year heading,
visible day numbers and accessible day labels are injectable. The `locale`
shapes text; the surrounding `Directionality` controls layout and navigation.
Keep supplied label lists immutable after construction.

## One format for values and hints

`CarbonDateFormat` holds a concrete pattern and its formatter/parser pair.
Single and range fields use that format for their visible and accessible
values. Empty hints derive from the same pattern: month tokens become
lowercase `m`, and quoted literals retain their spelling. Existing explicit
`placeholder:` overrides remain available. Const widget construction and the
public non-nullable `placeholder` getter remain supported.

These pickers select civil dates through their calendar. `tryParse` makes the
same backend available to an application's separate text-entry workflow; it
returns null for invalid input or a `FormatException`. Other backend errors
remain visible. The built-in parser rejects normalized invalid dates such as
February 29 in a non-leap year and April 31.

## Using intl in an application

Add `intl` to the consuming application. Carbide has no `intl` dependency and
uses Flutter base widgets. Initialize the application's locale data before
creating its formatter, as described by [DateFormat](https://pub.dev/documentation/intl/latest/intl/DateFormat-class.html).

```dart
import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

await initializeDateFormatting('de_DE');
final format = DateFormat.yMd('de_DE');
final labels = CarbonDatePickerLocalizations(
  locale: const Locale('de', 'DE'),
  monthNames: format.dateSymbols.STANDALONEMONTHS,
  weekdayNames: format.dateSymbols.SHORTWEEKDAYS,
  firstDayOfWeek: format.dateSymbols.FIRSTDAYOFWEEK + 1,
  dateFormat: CarbonDateFormat(
    pattern: format.pattern!,
    formatter: format.format,
    parser: format.parseStrict,
  ),
  previousMonthLabel: 'Vorheriger Monat',
  nextMonthLabel: 'Nächster Monat',
  monthYearFormatter: DateFormat.yMMMM('de_DE').format,
  dayFormatter: DateFormat.d('de_DE').format,
  dayLabelFormatter: DateFormat.yMMMMEEEEd('de_DE').format,
);

CarbonDatePicker(
  labelText: 'Datum',
  localizations: labels,
  value: date,
  onChanged: (DateTime value) => setState(() => date = value),
);
final parsed = labels.dateFormat.tryParse('13.9.2025');
```

Intl's week-start index is Monday-based and starts at zero; adding one maps it
to Dart's weekday constants. Its weekday-name arrays are Sunday-based, matching
this API. The resolved pattern supplies the locale's ordering and separators.
The recipe is exercised with `intl` 0.20.3 for US English, German, Japanese and
Arabic in an isolated consumer package, without changing Carbide dependencies.
An application can supply a different backend for era-style display or another
numbering convention through the same callbacks.

## RTL and text scaling

Dates follow the visual week order. In LTR, Right moves one day forward and
Left one day backward. In RTL, Left moves forward and Right backward.
Up/Down keep their previous/next-week behavior; PageUp/PageDown keep their
previous/next-month behavior. Month buttons remain previous/next actions and
mirror their chevrons with directionality. Week layout and keyboard policy
update when their inputs change.

Field heights are minimums. Long formatted values wrap and grow the single,
range and fluid fields at 1.3× and 2× scaling. Weekday headers also grow for
long labels. Locale updates refresh text and week layout while preserving the
controlled civil date, focused day and any uncommitted range draft.
