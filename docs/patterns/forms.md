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
