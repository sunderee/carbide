# Dialogs

When to interrupt with a modal dialog, when to float a non-modal one
alongside the page, and how to build both with `CarbonModal` and
`CarbonDialog`.

> Adapted from the Carbon Design System "Dialogs" pattern (Apache-2.0,
> carbon-design-system/carbon-website; see NOTICE). Guidance is rewritten
> for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Preassembled modal | `CarbonModal` + `CarbonModalAction`, `CarbonModalSize` |
| Composable dialog (modal or not) | `CarbonDialog` (`modal:` flag) |
| Dialog slots | `CarbonDialogHeader`, `CarbonDialogTitle`, `CarbonDialogSubtitle`, `CarbonDialogBody`, `CarbonDialogFooter` |
| Close affordance | `CarbonDialogControls` + `CarbonDialogCloseButton` |
| Footer buttons | `CarbonButton` (via `CarbonModalAction` in `CarbonModal`) |
| In-dialog validation | field `invalid`/`invalidText`, `CarbonInlineNotification` |
| Submit-in-flight | `CarbonInlineLoading` |

## Choosing modal vs. non-modal

A dialog is a short conversation with the user. **Modal** dialogs block
the page behind a scrim and trap focus — use them when the workflow
cannot continue without an answer: required input, urgent consequences,
confirming a destructive action. **Non-modal** dialogs float above the
page while it stays interactive — use them for optional, repeatable
tasks (find-and-replace, in-context help) where the user needs to keep
reading or working underneath.

In Carbide the split is explicit:

- `CarbonModal` is always modal: scrim, focus trap, outside-tap dismissal
  (suppress with `preventCloseOnClickOutside: true`).
- `CarbonDialog(modal: true)` is the composable equivalent (Carbon's
  `showModal()` posture); `CarbonDialog(modal: false)` floats without a
  scrim and without blocking the page (`show()` posture). `CarbonDialog`
  never closes on an outside tap, matching the native `<dialog>` element.

Both are controlled: pass `open`, respond to `onClose` /
`onRequestClose` (close button, Escape) by flipping your own state.

## When to use a dialog at all

- Focus attention on one short task or one piece of urgent information.
- Gather a small amount of input the flow depends on.

And when not to:

- Not for content unrelated to the current workflow, and never
  system-initiated — a user action (button, link, menu item) opens it.
- Not for large or complex content; a dialog is not a page. Don't nest
  one dialog on top of another.

## Modal variants

`CarbonModal` covers Carbon's variants through its parameters:

| Variant | Recipe |
|---|---|
| Passive | `passiveModal: true` — no footer; informs only |
| Transactional | `primaryButton` + `secondaryButton` ("Cancel" left) |
| Acknowledgment | `primaryButton` only |
| Danger | transactional + `danger: true` |
| Progress | not built in — compose a `CarbonDialog` with a `CarbonProgressIndicator` in the body and Cancel/Previous/Next in the footer |

Name buttons for the action they perform (Add, Delete, Save) — never
"OK" or "Done" for transactional work. One primary action per dialog;
Cancel is always the leftmost button. Footer buttons are full-bleed and
attached to the bottom edge; `CarbonModal` lays this out for you.

```dart
CarbonModal(
  open: _open,
  title: 'Add tag',
  onClose: () => setState(() => _open = false),
  primaryButton: CarbonModalAction(label: 'Add', onPressed: _submit),
  secondaryButton: CarbonModalAction(label: 'Cancel', onPressed: _close),
  child: CarbonTextInput(
    labelText: 'Tag name',
    invalid: _nameError != null,
    invalidText: _nameError,
    onChanged: _validate,
  ),
)
```

## Behavior

- **Focus.** Both components trap focus while open (modal case) and
  restore it to the launcher on close. Initial focus should land on the
  first input, not on the footer buttons.
- **Scrolling.** `CarbonModal` sizes come from `CarbonModalSize`; when
  content exceeds the max height the body scrolls while header and
  footer stay fixed. In `CarbonDialog`, the `CarbonDialogBody` slot owns
  the scrollable middle row.
- **Validation.** Validate before closing. Keep the dialog open on
  error, mark the field with `invalid` + `invalidText`, and surface
  server-side failures as a `CarbonInlineNotification` inside the body.
  Prefer bounded controls (`CarbonDropdown`, `CarbonRadioButtonGroup`)
  over free text to prevent errors up front.
- **Completion.** Act immediately on the primary action. If a short wait
  is unavoidable, disable the primary action and show
  `CarbonInlineLoading`; for long operations close the dialog and report
  progress on the page instead.

## Content to avoid inside dialogs

Skip components that pull the user away (`CarbonLink` to elsewhere),
hide content (`CarbonAccordion`, `CarbonTabs`), or bring their own
workflow (`CarbonDataTable` with batch actions). If the task needs them,
it has outgrown the dialog — give it a page.

## Related

- [Common actions pattern](common-actions.md) — delete confirmation tiers
- [Forms pattern](forms.md) — validation rules reused inside dialogs
- [Loading pattern](loading.md) — in-flight primary actions
- [Disclosures pattern](disclosures.md) — lighter-weight popovers
