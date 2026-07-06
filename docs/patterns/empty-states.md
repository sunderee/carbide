# Empty states

What to show when there is no data — first use, no search results, or an
error keeping data out of reach — so the empty space still moves the
user forward.

> Adapted from the Carbon Design System "Empty states" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

Carbide has no dedicated empty-state component (neither does upstream
Carbon); an empty state is a composition:

| Role | Carbide API |
|---|---|
| Illustration (optional) | `CarbonPictogram` (decorative by default) |
| Title | `CarbonHeading` or `CarbonText` with a heading style |
| Body copy | `CarbonText` |
| Primary action | `CarbonButton` (or a `CarbonLink` inside the copy) |
| Secondary call to action | `CarbonLink` below the copy |
| Common hosts | `CarbonTile`, `CarbonDataTable` regions, full pages |

## Anatomy

1. **Image (optional)** — a `CarbonPictogram` related to the situation.
   Skip it when space is tight.
2. **Title** — short, and positive where possible: "Start by adding
   data assets" beats "You don't have any data assets."
3. **Body** — the next action that fills the space, and optionally why
   it is empty and what the user gains by acting.
4. **Primary action** — a button under the copy, a link in the copy, or
   a pointer to the on-page element that performs the action (which also
   teaches where that element lives).
5. **Secondary call to action (optional)** — a `CarbonLink` to
   documentation or further reading.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    const CarbonPictogram(CarbonPictograms.addDocument, size: 64),
    const SizedBox(height: CarbonSpacing.spacing05),
    const CarbonHeading('Start by adding data assets'),
    const SizedBox(height: CarbonSpacing.spacing03),
    const CarbonText(
      'Assets you add appear here, ready to be organized into '
      'catalogs and shared with your team.',
    ),
    const SizedBox(height: CarbonSpacing.spacing06),
    CarbonButton(label: 'Add asset', onPressed: _addAsset),
  ],
)
```

## Layout

- **Left-align the block.** Title, body, and action align as one
  left-aligned group. The exception is a small tile, where the image is
  centered above the left-aligned text so the state reads as a state,
  not skippable content.
- **Positioning in large spaces** — either give the block a wide left
  margin or center the left-aligned block in the empty area. Wide images
  sit above the title; tall images sit to the left of the block.
- **Replace, don't overlay.** The empty state takes the place of the
  element that would normally render: an empty `CarbonDataTable` should
  render the message instead of headers and an empty body, so a screen
  reader isn't walked through a hollow table first.
- **Many at once** — on a dashboard where several tiles can be empty
  together, drop the pictograms and use `CarbonButtonKind.tertiary` for
  the calls to action so the page doesn't shout in unison.

## Types of empty states

| Type | Trigger | The state's job |
|---|---|---|
| No data | First use; nothing added yet | Say what will appear here and give the one step that populates it. |
| User action | No search results; a flow completed | Explain the outcome; suggest adjusting the `CarbonSearch` terms or filters, or confirm success. |
| Error management | Permissions, system issues, configuration required | Say why the data is unavailable and give a specific corrective path. |

Content rules that hold across all three:

- One state, one action. Don't catalogue everything the user could do.
- Stay contextual — no tours of other parts of the app, no product
  jargon a new user can't know yet.
- Never a dead end: if there is a useful next step, include it. For
  error states, plain language and a respectful tone; no jokes.
- Sometimes silence is right: "no triggered alerts" needs no
  supplementary text at all.

## In-depth alternatives for first use

For a primary feature's first-use moment, a basic message may be too
thin. Options, in increasing investment: in-line documentation (a richer
explanation, possibly with a populated-state screenshot and a
`CarbonLink` out to docs), an optional onboarding flow launched from the
empty state, or starter content — sample data the user can safely poke
at and delete. Onboarding and starter content are always *supplements*:
the basic empty state must still exist for when they are skipped or the
sample data is removed.

## Accessibility

Empty-state illustrations are decorative. `CarbonPictogram` is excluded
from the semantics tree unless you pass `semanticLabel` — leave it unset
here so screen readers land directly on the title and action.

## Related

- [Common actions pattern](common-actions.md) — the Add action
- [Loading pattern](loading.md) — before you know the space is empty,
  show a skeleton
- [Notifications pattern](notification.md) — transient failures vs.
  persistent error states
