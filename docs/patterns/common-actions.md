# Common actions

How to present the actions that recur across every product — add, cancel,
clear, close, copy, delete, edit, next, refresh, remove, reset — so they
behave the same way everywhere in a Carbide app.

> Adapted from the Carbon Design System "Common actions" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Buttons (all emphases) | `CarbonButton` with `CarbonButtonKind` |
| Icon-only actions | `CarbonIconButton` |
| Copy with feedback | `CarbonCopyButton`, `CarbonCopy` |
| Clearable search | `CarbonSearch` (`onClear`) |
| Menu actions | `CarbonOverflowMenu`, `CarbonMenuItem` |
| Confirmation | `CarbonModal` (`danger: true` for destructive) |
| Failure surfaces | `CarbonInlineNotification`, `CarbonToastNotification` |
| Inline actions | `CarbonLink` |
| Icons | `CarbonIcons.add`, `.close`, `.copy`, `.edit`, `.trashCan`, `.renew`, `.subtract`, `.arrowRight` |

## Add

Inserts an existing object into a list, set, or system. Scale the emphasis
to the page: a primary `CarbonButton` with `CarbonIcons.add` when adding
is the page's main job, `CarbonButtonKind.tertiary` or `ghost` otherwise.
Before shipping, decide what happens on failure, whether the action is
permanent, and whether it can apply to many items at once.

## Cancel

Stops the current action and closes the surface it lives on. Use
`CarbonButtonKind.secondary` (in modals and forms) or a `CarbonLink`.
Warn the user first if abandoning the flow loses their work.

## Clear

Removes entered data or selections and restores defaults. Render as a
trailing `CarbonIcons.close` inside the field — `CarbonSearch` ships this
built in (`onClear`); `CarbonDismissibleTag` covers removable filter tags.

## Close

Ends the current surface or dismisses information. Use the close icon in
the top-right corner — `CarbonModal` and `CarbonDialogCloseButton` provide
it; notifications dismiss the same way. Never label a button "Close".

## Copy

Duplicates the selected value. Use `CarbonCopyButton`, which shows the
transient "Copied!" feedback bubble after activation; `CarbonCodeSnippet`
embeds the same behavior for code.

## Delete

Destroys an object, usually permanently. Use `CarbonIcons.trashCan`, a
`CarbonButton(kind: CarbonButtonKind.danger)`, or a
`CarbonMenuItem(kind: CarbonMenuItemKind.danger)` in a menu. Match the
ceremony to the impact:

- **Low impact** — trivially recreated data: delete immediately.
- **Moderate impact** — hard to undo, or bulk: confirm in a
  `CarbonModal(danger: true)` that states what will be lost.
- **High impact** — expensive to recreate or cascading: additionally make
  the user type the resource name into a `CarbonTextInput` before the
  danger button enables.

After deletion, return to the list and confirm with a
`CarbonToastNotification`. On failure, say so with an error notification.

```dart
CarbonModal(
  open: _confirming,
  danger: true,
  label: 'Cluster ap-eu-1',
  title: 'Delete cluster',
  onClose: () => setState(() => _confirming = false),
  primaryButton: CarbonModalAction(label: 'Delete', onPressed: _delete),
  secondaryButton: CarbonModalAction(label: 'Cancel', onPressed: _cancel),
  child: const Text('Deleting a cluster cannot be undone.'),
)
```

## Edit

Switches a value to a changeable state. Offer it as a
`CarbonIconButton` with `CarbonIcons.edit`, a button, or a menu item in a
`CarbonOverflowMenu`.

## Errors

When an action fails, say what happened and how to continue. Use field
`invalidText` for input errors, `CarbonInlineNotification` for form- and
page-level failures, and keep messages under two lines for fields, three
for pages. Be honest and specific; offer a path forward.

## Next

Advances a sequence (wizard steps, `CarbonProgressIndicator` flows). Use a
primary `CarbonButton` with `CarbonIcons.arrowRight`, icon after label.

## Refresh

Reloads a view that has drifted from its source. Use `CarbonIcons.renew`
as a `CarbonIconButton` or a labeled button.

## Remove

Takes an object out of a list without destroying it — unlike delete, the
object survives. Use `CarbonIcons.subtract` or a low-emphasis button;
remove is rarely the page's primary action. Tell users if the removal is
permanent for them (for example, losing access).

## Reset

Reverts values to the last applied state, typically as a `CarbonLink`
next to the controls it resets (common in filter panels).

## Related

- [Dialogs pattern](dialog.md) — confirmation and danger modals
- [Forms pattern](forms.md) — validation and error text
- [Notifications pattern](notification.md) — success and failure surfaces
- [Disclosures pattern](disclosures.md) — menu-borne actions
