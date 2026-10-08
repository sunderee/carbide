# Page headers

`CarbonPageHeader` retains Carbide's constructor composition. Its visual
reference is Carbon core v11.118.0's historical PageHeader SCSS; the former
React preview moved to IBM Products and is deprecated. This port does not
adopt the IBM Products component API.

## Responsive actions

Use `actions` for named actions that can move into an overflow menu. Give each
action a stable, unique `id`; list the primary action first. A null callback
disables the action in both presentations. Localize `actionsOverflowLabel`.

```dart
CarbonPageHeader(
  title: 'Quarterly report',
  actions: <CarbonPageHeaderAction>[
    CarbonPageHeaderAction(id: 'edit', label: 'Edit report', onPressed: edit),
    CarbonPageHeaderAction(
      id: 'download',
      label: 'Download report',
      kind: CarbonButtonKind.secondary,
      onPressed: download,
    ),
    const CarbonPageHeaderAction(id: 'archive', label: 'Archive report'),
  ],
)
```

The actual header width, including its gutters, selects Carbon's `md` layout
at 672 px. Below it, the title and actions occupy separate rows. At wider
widths they share a row, reserving up to 240 scaled pixels for the title.
Buttons use measured Plex label widths, Carbon's `md` height minimum and
standard horizontal padding. Fitting leading actions remain visible; the
remaining actions appear in logical order through `CarbonOverflowMenu`.
If even the first action cannot fit alongside the trigger, it moves into the
menu too. Long button labels use Carbon's existing 320 px maximum and ellipsis;
their complete names remain accessible.

Widths are recalculated when constraints, labels, direction, text scaling or
system fonts change. Reflow does not call action callbacks. The menu uses the
existing arrow, Home/End, type-ahead and Escape behavior; activation and Escape
restore trigger focus. An open menu retains ownership when the visible/hidden
membership changes, including when only disabled rows remain. If the menu
disappears, focus moves to the first enabled visible action.

An Overlay host is required, as provided by a `WidgetsApp` Navigator. A
`WidgetsApp.builder` that replaces its navigator must supply its own Overlay.

Existing `pageActions` remains an arbitrary widget slot with its previous
layout. It is mutually exclusive with `actions`; custom action widgets retain
caller ownership and require the caller to manage their responsive layout.
The structured model supports named button/menu actions and optional Carbon
icons; arbitrary editor/controller widgets belong in the existing slot.

The 320 px, 2× scale stress case has the long title on its own two-line row and
keeps `Edit report` visible while disclosing secondary actions. Widths below
the room needed by a title glyph/icon remain the host's composition decision.

## Tag disclosure

Set `collapseTags: true` to keep fitting leading tags on one row and expose
remaining tags through Carbon's `+N` operational tag and popover. By default,
the existing `tags` list wraps. Localize `tagsOverflowLabel` with a count
formatter and `tagsDisclosureLabel` with the disclosed list name.

```dart
CarbonPageHeader(
  title: 'Quarterly report',
  collapseTags: true,
  tags: <Widget>[
    const CarbonTag(key: ValueKey('finance'), label: 'Finance'),
    CarbonOperationalTag(
      key: const ValueKey('region'),
      label: 'View regional report',
      onPressed: openRegion,
    ),
    CarbonDismissibleTag(
      key: const ValueKey('draft'),
      label: 'Draft',
      onClose: removeDraft,
    ),
  ],
)
```

The row measures the actual children with their current typeface and text
scale, reserving space for the exact hidden count. A prefix stays inline;
every remaining tag appears once in the popover, in original order, with its
original label, disabled state and actions. Even a single long tag can move
into disclosure. Carbon's ordinary 208 px tag maximum and ellipsis still apply
inside the popover; complete names remain accessible.

Give stateful or reordered tags stable, unique keys. Hidden children stay
mounted offstage, outside focus traversal and accessibility, then move into
the popover. They are not cloned: local widget state and caller-owned
controllers remain intact. Widths update after layout, including changes to
labels, font, scale or constraints. A resize or text-scale change dismisses an
open disclosure, following the reference's resize behavior. Enter/Space and
accessibility activation open it; Tab reaches interactive tags, and Escape
returns focus to the count trigger while it remains present.

The collapse mode supports Carbon tags and custom tags that can report their
natural size through Flutter's dry-layout contract, within the 208 px tag
maximum. Use wrapping mode for custom scroll views, `LayoutBuilder` content or
other children that cannot be measured this way. Unkeyed tags use their list
position as identity; reordering stateful unkeyed children has normal Flutter
positional-state behavior.

`CarbonPopover.portalController` is an optional coordination hook for owners
moving keyed content between inline and popup layouts. Ordinary popovers need
only `open`; advanced owners call the controller outside build and update
`open` together. `CarbonOperationalTag` accepts a caller-owned `focusNode`; the
count uses shared control semantics and guarded native focus restoration.
