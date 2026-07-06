# Read-only states

Showing values users may review but not modify, without the contrast and
accessibility losses of a disabled state.

> Adapted from the Carbon Design System "Read-only states" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Text entry | `readOnly: true` on `CarbonTextInput`, `CarbonTextArea` |
| Bound entry | `readOnly: true` on `CarbonNumberInput`, `CarbonSlider`, `CarbonTimePicker` |
| Selection | `readOnly: true` on `CarbonCheckbox`, `CarbonRadioButton` / `CarbonRadioButtonGroup`, `CarbonToggle`, `CarbonDropdown` |
| Field chrome | `CarbonField(readOnly: true)` for custom field content |
| Not yet available | no `readOnly` on `CarbonComboBox`, `CarbonMultiSelect`, `CarbonSelect`, `CarbonDatePicker` — see gaps below |

## When to use

Apply `readOnly` only to components that would be editable when enabled.
The value is still live — the application uses it — but for this user,
at this moment, it is informative rather than interactive. The three
classic triggers:

| Use case | Example |
|---|---|
| Application process | A deploy is running; its settings lock until it finishes. |
| Locked | Another user holds the edit lock on this record. |
| Permissions | The viewer role can see the configuration, not change it. |

When *not* to use:

- Not for static display of information that was never editable — use
  plain `CarbonText` / structured layout instead.
- Not as a substitute for disabled. A control that is temporarily
  unavailable pending user action (finish the form, pick an option) is
  *disabled*, not read-only.
- A control that is disabled for its own reasons stays disabled even
  inside an otherwise read-only view; don't promote it to read-only.

## What changes visually

Carbide applies Carbon's read-only recipe through theme tokens when you
set `readOnly: true` — you do not restyle anything:

- **Field background** goes transparent so the value sits on the page
  (fluid fields keep their contained background).
- **Borders** drop to subtle to remove the "click me" affordance.
- **Text keeps full contrast** — unlike disabled, the value is meant to
  be read, and still passes 4.5:1.
- **Signifier icons** (chevrons, clocks) recolor with the disabled icon
  token to show they are inert, but remain for context.

Structure and spacing stay identical to the enabled state, so toggling a
form between edit and review modes never reflows the page.

```dart
CarbonTextInput(
  labelText: 'Cluster name',
  controller: _name,
  readOnly: !_canEdit,
),
const SizedBox(height: CarbonSpacing.spacing06),
CarbonToggle(
  labelText: 'Public endpoint',
  toggled: _public,
  readOnly: !_canEdit,
  onToggled: (bool v) => setState(() => _public = v),
)
```

## Interaction and accessibility

The distinction from disabled is navigable vs. operable:

- Read-only components stay **navigable**: they keep keyboard focus and
  are announced by screen readers, so users can review the value.
- They are not **operable**: taps, key presses, and drags change
  nothing, and the cursor stays a plain arrow rather than an I-beam or
  hand.

If the enabled state shows instructive placeholder content ("Choose an
option"), swap it for informative content in read-only mode — an unset
read-only dropdown should say something like "None selected", not issue
an instruction the user cannot follow.

## Carbide gaps

`CarbonComboBox`, `CarbonMultiSelect`, `CarbonSelect`, `CarbonSearch`,
and `CarbonDatePicker` do not expose a public `readOnly` parameter yet.
Until they do, render the committed value with a read-only
`CarbonTextInput` (or plain text) in review contexts rather than
disabling the richer control.

## Related

- [Disabled states pattern](disabled-states.md) — the temporary,
  non-readable sibling
- [Forms pattern](forms.md) — review modes of editable forms
- [Fluid styles pattern](fluid-styles.md) — read-only backgrounds differ
  for fluid fields
