# Fluid styles

The contained, edge-hugging variant of Carbide's fields — when to reach
for `CarbonFluidForm` and the `fluid` flag, and when to stay with the
default style.

> Adapted from the Carbon Design System "Fluid styles" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Opt a whole subtree in | `CarbonFluidForm(child: ...)` (inherited scope) |
| Opt one field in | `fluid: true` on the field itself |
| Fluid-capable fields | `CarbonTextInput`, `CarbonPasswordInput`, `CarbonTextArea`, `CarbonNumberInput`, `CarbonDropdown`, `CarbonComboBox`, `CarbonMultiSelect`, `CarbonSelect`, `CarbonSearch`, `CarbonDatePicker`, `CarbonDateRangePicker`, `CarbonTimePicker`, `CarbonTimePickerSelect` |
| Full-width buttons | `CarbonButton` in an `Expanded` row (no `fluid` flag) |
| Fluid containers | `CarbonModal`, side panels, sign-in tiles |
| Fluid skeletons | component skeletons accept the same `fluid` flag |

## What "fluid" means

A fluid field is part of a larger compound surface: its chrome bleeds to
the edges of its container instead of floating with outside margins. The
label moves *inside* the field box, above the entered text, and the
field renders at a single 64px height with a width that always fills its
container. Fluid components never appear alone — they exist inside
something, like a modal, a side panel, or a sign-in card.

The default style is the productive workhorse for everyday forms; fluid
is the expressive counterpart for high-emphasis moments. Both share
identical behavior and parameters — only presentation changes.

## Opting in

Two equivalent routes, which combine:

```dart
// Whole form: every fluid-capable descendant renders fluid.
CarbonFluidForm(
  child: Column(
    children: <Widget>[
      CarbonTextInput(labelText: 'Email', onChanged: _setEmail),
      CarbonPasswordInput(labelText: 'Password'),
    ],
  ),
)

// Single field.
CarbonTextInput(labelText: 'Email', fluid: true)
```

`CarbonFluidForm` is an `InheritedWidget` flag; a field is fluid when
either the scope encloses it or its own `fluid` parameter is set.

## When to use fluid

- Expressive, focal moments: sign-in panels, first-run setup, a single
  prominent form on a marketing-style page.
- Inside or attached to a containing component — a `CarbonModal`, a side
  sheet, a `CarbonTile`-based card.
- Spacious layouts where the contained fields have room to breathe.

## When not to

- Not in dense, hyper-productive UIs or complex multi-section forms —
  use the default style there ([Forms](forms.md)).
- Not when you need white space between inputs: fluid fields are meant
  to stack flush.
- Not inside a `CarbonAccordion` or similar sectioned container, where
  the fluid edges collide with the section dividers and muddle the
  hierarchy.
- Never mix fluid and default fields in the same form. The one blessed
  hybrid is default *fields* with full-width *buttons* in a contained
  form.

## Layout rules

- **Stack flush.** Fluid fields sit directly against each other with 0px
  between — no `SizedBox` spacers, unlike a default form. The fields'
  own borders separate them; keep those borders at 3:1 contrast against
  the field fill (Carbide's theme tokens satisfy this).
- **Bleed to the container.** No horizontal padding between a fluid
  field and its container edge; the field is architectural, part of the
  surface.
- **Buttons.** Carbide has no `fluid` flag on `CarbonButton`; a
  full-bleed button pair is layout: a `Row` of `Expanded` buttons
  attached to the container's bottom edge (the [forms](forms.md) example
  shows this). `CarbonModal` renders its footer actions full-bleed
  automatically. Free-standing default buttons should not be stretched
  this way — `CarbonButtonSet` caps default button widths per spec.
- **Skeletons.** When a fluid form loads, use the matching component
  skeletons with `fluid: true` so the placeholder geometry matches the
  64px fields.

## Carbide gaps

Upstream also ships fluid variants of some non-field components (for
example the fluid `TimePicker` inside `FluidDatePicker` compositions);
in Carbide fluidity is limited to the field family listed above.
`CarbonSlider` and `CarbonFileUploader` have no fluid treatment, same as
upstream.

## Related

- [Forms pattern](forms.md) — default vs. fluid form composition
- [Dialogs pattern](dialog.md) — modals as fluid containers
- [Read-only states pattern](read-only-states.md) — fluid fields keep
  their background when read-only
- [Loading pattern](loading.md) — skeleton states
