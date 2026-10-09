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
