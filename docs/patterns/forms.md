# Forms

How to compose Carbide's form components into forms that are easy to scan,
fill in, and recover from errors in.

> Adapted from the Carbon Design System "Forms" pattern (Apache-2.0,
> carbon-design-system/carbon-website; see NOTICE). Guidance is rewritten
> for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Grouping + legend | `CarbonFormGroup` |
| Labels above controls | built into every labelled control (`labelText`); standalone `CarbonFormLabel` |
| Text entry | `CarbonTextInput`, `CarbonTextArea`, `CarbonPasswordInput`, `CarbonNumberInput` |
| Selection | `CarbonCheckbox`, `CarbonRadioButtonGroup`, `CarbonToggle`, `CarbonDropdown`, `CarbonComboBox`, `CarbonMultiSelect`, `CarbonSelect` |
| Dates and times | `CarbonDatePicker`, `CarbonDateRangePicker`, `CarbonTimePicker` |
| Helper / error text | `helperText`, `invalid` + `invalidText`, `warn` + `warnText` on each control |
| Fluid (contained) fields | wrap in `CarbonFluidForm` |
| Submission | `CarbonButton` (primary + secondary pair) |

## Labels

- Every input gets a label. Use one to three words, sentence-style
  capitalization, no trailing colon.
- Labels state *what* is being requested; constraints and formats belong in
  `helperText`, not the label.
- Labels sit above their control (Carbide's only arrangement, matching
  Carbon's top-aligned default): a consistent start edge scans fastest and
  survives translation into longer languages.

## Optional vs. required

Mark the *minority*. On short, consumer-style forms (sign-up, checkout)
most fields are required — mark the optional ones with the `(optional)`
suffix in the label. On long, expert-configuration forms the reverse is
common — mark required fields instead. Pick one convention per product and
keep it; never mix both on one form.

## Disabled and read-only controls

Use `readOnly: true` when a value is available for review but cannot be changed.
Read-only controls remain in keyboard traversal, retain value contrast and
announce their non-editability. Text-based controls allow selection and copying;
picker triggers keep their selected value available without opening a popup.
Pointer activation, editing keys, typeahead and accessibility edit actions cannot
change the value. Clear and selection-dismiss controls are hidden or inert.

Use `disabled: true` when the control is unavailable. Disabled controls skip
keyboard traversal and use the disabled text and icon tokens. Disabled takes
precedence when both flags are set. On callback-driven selectors (`CarbonSelect`,
`CarbonDropdown` and `CarbonMultiSelect`), an absent `onChanged` also disables the
control. Search and combo-box query editing retain their existing uncontrolled
behavior when a callback is omitted.

The picker and search family accepts a localizable `readOnlyHint` (default
`'Read only'`). Read-only text fields expose the native read-only state; button
triggers announce the hint while keeping their name and value. Switching an open
picker to read-only closes its popup and discards any uncommitted date-range
draft without notifying `onChanged`. Application updates to a controlled value
or text controller still appear normally.

Carbon's read-only field treatment uses a transparent background, subtle border,
full-contrast value and inert chevron/calendar icon. Focus remains visible.
See [read-only states](read-only-states.md) for review-screen composition.

## Navigating picker options

Date calendar localization and patterns are described in
[date pickers](date-pickers.md). Time inputs retain permissive typing by default;
[time picker policies](time-pickers.md) opt into parsing, normalization and
Enter/Done/group-blur commits with coordinated 12/24-hour behavior.

Dropdown, Select, ComboBox and both MultiSelect variants share one announcement
policy. Arrow keys move an active option without committing it. The trigger
keeps keyboard focus, exposes its expanded state and describes the active
option in a hint, for example, "Active option: Email, 2 of 3". A polite live
region also announces changes because platforms do not reliably re-read a
changed hint. The trigger's value remains the selection or current editor text;
navigation does not replace a query, selection range or composing range.

Flutter has no active-descendant relationship corresponding to the
[ARIA combobox pattern](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/).
Keeping focus on every trigger avoids a different navigation policy for
editable fields and protects text entry. Options each expose one named node
with selected and enabled states, an active-option hint when highlighted, and
one activation action when available. MultiSelect also exposes checked state;
its entire option row toggles once, including taps over the painted checkbox.

On Flutter 3.47.6 web, the native text-input role does not translate the input's
expanded semantics flag. Editable pickers therefore also expose expanded state
on their adjacent named popup button. The input still exposes expanded in
Flutter's semantics tree and receives the active-option hint natively. Live
announcements use Flutter's supported
[live-region semantics](https://api.flutter.dev/flutter/semantics/SemanticsProperties/liveRegion.html).

Use the same `activeOptionFormatter` for each picker in an application to
localize the complete announcement. Positions are one-based among currently
visible options, including disabled rows:

```dart
activeOptionFormatter: (label, position, count) =>
    'Option active : $label ($position/$count)',
```

## Validation

- Validate per field as soon as it loses focus (client-side), not only on
  submit. Set `invalid: true` and give `invalidText` that says what is
  wrong *and* what would fix it: "Password must be at least 16 characters",
  not "Invalid password".
- Use `warn`/`warnText` for conditions that do not block submission.
- On a failed submit (server-side), add a `CarbonInlineNotification` with
  `kind: CarbonNotificationKind.error` at the top of the form *and* mark
  each offending field inline. Clear inline errors as their criteria are
  met.
- Do not disable the submit button to signal an incomplete form; let the
  user submit and show them precisely what is missing. Disable it only
  while the submission itself is in flight (pair with
  `CarbonInlineLoading`).

## Layout

- One column. Multi-column forms break vertical scanning; group related
  short fields (city / postal code) in a `Row` only when they are read as
  one unit.
- Group related controls with `CarbonFormGroup(legendText: ...)`, and
  order groups by how users think about the task, most important first.
- Fluid (contained) fields — `CarbonFluidForm(child: ...)` — are for
  full-bleed compositions like sign-in panels and side sheets, where the
  field chrome joins into a contiguous surface. Default (non-fluid) fields
  are for everything else. Do not mix the two styles in one form.

## Example

```dart
CarbonFormGroup(
  legendText: 'Create account',
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      CarbonTextInput(
        labelText: 'Email',
        helperText: 'We never share your email.',
        invalid: _emailError != null,
        invalidText: _emailError,
        onChanged: _validateEmail,
      ),
      const SizedBox(height: CarbonSpacing.spacing06),
      CarbonPasswordInput(
        labelText: 'Password',
        helperText: 'At least 16 characters.',
      ),
      const SizedBox(height: CarbonSpacing.spacing06),
      const CarbonCheckbox(label: 'Keep me signed in', value: false),
      const SizedBox(height: CarbonSpacing.spacing07),
      Row(
        children: <Widget>[
          Expanded(
            child: CarbonButton(
              label: 'Cancel',
              kind: CarbonButtonKind.secondary,
              onPressed: _cancel,
            ),
          ),
          Expanded(
            child: CarbonButton(label: 'Create account', onPressed: _submit),
          ),
        ],
      ),
    ],
  ),
)
```

Buttons: one primary action per form, placed after the fields; the
secondary (ghost or secondary kind) action sits before it. Label buttons
with the action they perform ("Create account", not "Submit").

## Related

- [Notifications pattern](notification.md) — server-side error surfaces
- [Loading pattern](loading.md) — submission-in-flight states
- Gallery: Form, Text input, Checkbox, Dropdown pages
