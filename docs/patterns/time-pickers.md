# Time picker formatting and commits

`CarbonTimePicker` remains a permissive text field when `format` is omitted:
typing calls `onChanged` immediately, and values such as `banana` are allowed.
Supplying a `CarbonTimeFormat` opts into parsing and commit behavior. This
pattern/formatter/parser object follows the injectable backend approach of
[date pickers](date-pickers.md), without a runtime formatting dependency.

```dart
CarbonTimePicker(
  labelText: 'Start time',
  format: CarbonTimeFormat.twentyFourHour,
  invalidText: 'Enter a time from 00:00 to 23:59.',
  onChanged: (String displayText) { /* Store the displayed commit. */ },
  onCommitted: (CarbonTimeValue? time) { /* Store canonical time, or null. */ },
)
```

Typing changes a draft. Enter, the keyboard's Done action and leaving the whole
input/select focus group commit it. Moving from the text field into its AM/PM
or timezone select keeps the draft. Active IME composition remains a draft;
candidate-selection Enter does not normalize or report a successful commit.
The commit boundaries match number input's model. Rebuilding with the same
format preserves the pending draft and focus; changing the policy retains text
and applies the new parser at the next commit.

The built-in formats accept one or two ASCII hour/minute digits and optional
outer whitespace. A valid `3:5` becomes `03:05`. With
`normalizeOnCommit: false`, parsing and validation still run but the displayed
draft spelling is retained. Empty drafts commit null. Partial input (`3:`),
out-of-range times and unparseable text stay visible with the existing invalid
field styling and `invalidText`; they do not call either success callback.
Editing clears the local parse error, and the next commit validates again.
Explicit `invalid` supplied by the consumer retains priority. Supply a
localized `invalidText` when enabling a format so the error has an explanation.

Successful commits call `onChanged` with the displayed text and `onCommitted`
with the canonical civil time, after normalization. Repeated unchanged
Enter/Done/blur does not notify again. The time is independent of dates,
timezones and daylight-saving rules; `CarbonTimeValue.hour` always uses 0–23.

## Hour cycle and AM/PM

| Format | Entered hours | Period interaction |
| --- | --- | --- |
| `CarbonTimeFormat.twentyFourHour` | 0–23 | No built-in period selector |
| `CarbonTimeFormat.twelveHour` | 1–12 | Picker owns a typed AM/PM selector |

The format's `hourCycle` determines whether the built-in selector exists. Its
selected `CarbonTimePeriod` is passed to the same parser; a twelve-hour backend
that returns the wrong period is rejected. `12:00 AM` commits hour 0 and
`12:00 PM` commits hour 12. Changing the period commits a valid pending draft
in that period; an invalid draft remains invalid. `initialPeriod` seeds this
selector, and `onPeriodChanged` reports later choices. Disabled/read-only
pickers block both editing and period changes.

Use `periodLabel`, `amLabel`, `pmLabel` and, for longer labels, `periodWidth`
to localize the selector. Its base width follows user text scaling, and it
follows the picker's fluid treatment. `children`
remain available for independent timezone or other selects. When migrating an
existing manually controlled AM/PM child to `twelveHour`, remove that child;
the built-in selector now owns period coordination. Twenty-four-hour mode
does not reinterpret independently supplied children as a period policy.

## Custom locale policies

The concrete `pattern` derives the default empty hint. An explicit
`placeholder:` still overrides it. A custom backend owns separators, digits,
ordering and the hour cycle; Carbide does not infer these from the ambient
locale. For example, a 24-hour dot-separated policy can delegate civil range
validation to the built-in format:

```dart
final CarbonTimeFormat dotFormat = CarbonTimeFormat(
  pattern: 'HH.mm',
  hourCycle: CarbonTimeHourCycle.twentyFourHour,
  formatter: (CarbonTimeValue time) =>
      CarbonTimeFormat.twentyFourHour.format(time).replaceAll(':', '.'),
  parser: (String text, CarbonTimePeriod _) =>
      CarbonTimeFormat.twentyFourHour.tryParse(text.replaceAll('.', ':')),
);
```

The callbacks must use the same pattern and return a canonical civil time.
Returning null or throwing `FormatException` reports invalid input. Other
backend errors propagate, so programming mistakes are visible. A custom
twelve-hour parser must combine its entered hour with the supplied period.
No input mask rewrites text during typing; normalization happens only at a
successful opt-in commit. Controllers and focus nodes retain the existing
caller-owned lifecycle and focused handoff behavior.
