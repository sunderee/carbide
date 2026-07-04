# Loading

Which loading treatment to reach for — skeleton, spinner, inline status, or
progress bar — and when.

> Adapted from the Carbon Design System "Loading" pattern (Apache-2.0,
> carbon-design-system/carbon-website; see NOTICE). Guidance is rewritten
> for Carbide's API.

## The decision

| Situation | Use | Carbide API |
|---|---|---|
| First paint of a page or region; content structure is known | Skeleton states | `CarbonSkeletonText`, `CarbonSkeletonPlaceholder`, `CarbonSkeletonIcon`, per-component skeletons (`CarbonTextInputSkeleton`, `CarbonCheckboxSkeleton`, `CarbonDataTableSkeleton`, …) |
| AI-generated content is being produced | AI skeletons | `CarbonAISkeletonText`, `CarbonAISkeletonIcon`, `CarbonAISkeletonPlaceholder` |
| The whole application is busy; interaction must pause | Full-screen loading | `CarbonLoading` over a scrim |
| One control or row is busy after a user action | Inline loading | `CarbonInlineLoading` (active → finished/error) |
| Progress is measurable (bytes, steps, percent) | Progress bar | `CarbonProgressBar(value: …)` |
| Progress is measurable across discrete stages | Progress indicator | `CarbonProgressIndicator` |
| Duration is unknown and short, inside a small area | Indeterminate bar | `CarbonProgressBar(value: null)` |

Two rules of thumb:

- **Skeletons are for structure, spinners are for actions.** A page that is
  arriving gets skeletons; a button that is working gets inline loading.
- **Prefer determinate over indeterminate** whenever you can compute
  progress — an indeterminate animation only says "not frozen".

## Skeleton states

Skeletons stand in for *container* and *data* content — tiles, lists,
tables, text blocks — during the first seconds of a load, then disappear.

- Do not skeleton action components (buttons, inputs, checkboxes, toggles)
  in place; they simply appear when ready.
- Never skeleton toasts, overflow menus, dropdown items, modals, or
  loaders. Content *inside* a modal may use skeletons; the modal itself
  must not.
- Skeletons animate to show the page is alive; under reduced motion they
  render as static fills automatically.

```dart
loading
    ? const CarbonDataTableSkeleton(rowCount: 5, columnCount: 4)
    : CarbonDataTable(columns: _columns, rows: _rows)
```

## Full-screen loading

Use `CarbonLoading` centered over a scrim when a user action temporarily
disables the whole application — typically right after submitting or
saving. If the wait can exceed a few minutes, surface a
[notification](notification.md) instead of holding the screen.

## Inline loading

Use `CarbonInlineLoading` when a single component is processing — sending
an invite, deleting a row. It replaces or joins the triggering control,
reports `active`, then resolves to `finished` or `error` before the UI
moves on:

```dart
_sending
    ? const CarbonInlineLoading(
        status: CarbonInlineLoadingStatus.active,
        description: 'Sending invite…',
      )
    : CarbonButton(label: 'Send invite', onPressed: _send)
```

## Progressive loading

Load pages in batches: first the structural skeletons and static text, then
data text, then images and below-the-fold content. Items without a natural
skeleton can hold empty space at their final size, so the layout never
jumps. Use this for dashboards and any view fed by several sources, and for
table refreshes after filter changes.

## Accessibility

Announce busy states to assistive technology. `CarbonLoading` and
`CarbonInlineLoading` carry semantics already; when you build custom
composites, wrap the region in `Semantics(liveRegion: true)` and update its
label when loading starts, finishes, or fails. All Carbide loading and
skeleton animations respect `MediaQuery.disableAnimations`.

## Related

- [Notifications pattern](notification.md) — long-running process updates
- [Forms pattern](forms.md) — submission-in-flight buttons
- Gallery: Loading, Progress bar, Skeletons pages
