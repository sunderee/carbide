# Global header

How to compose Carbide's UI-shell widgets into a header that keeps users
oriented and gives them one consistent place to navigate from.

> Adapted from the Carbon Design System "Global header" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Header bar | `CarbonHeader` |
| Main menu (hamburger) | `CarbonHeaderMenuButton` via `CarbonHeader.menuButton` |
| Header name | `CarbonHeaderName` (`prefix` + `name`) |
| Header links | `CarbonHeaderMenuItem` in `CarbonHeader.navigation` |
| Sub-menus | `CarbonHeaderMenu` |
| Utilities | `CarbonHeaderGlobalAction` in `CarbonHeader.globalActions` |
| Switcher | `CarbonHeaderPanel` + `CarbonSwitcher` + `CarbonSwitcherItem` |
| Left panel | `CarbonSideNav` with `CarbonSideNavLink`, `CarbonSideNavMenu`, `CarbonSideNavMenuItem`, `CarbonSideNavDivider` |
| Skip link | `CarbonSkipToContent` |
| Page body | `CarbonShellContent` |

(Upstream's "switcher" is `CarbonSwitcher` here — there is no
`CarbonHeaderSwitcher` class.)

## Anatomy

- **Menu button** toggles the side nav; pass `isOpen` so the icon swaps
  between hamburger and close.
- **Header name** links only to the product home. `prefix` renders the
  lighter company name before the bold product name.
- **Header links** (`CarbonHeaderMenuItem`) are product navigation; mark
  the current page with `selected: true`. `CarbonHeaderMenu` groups
  related links behind a chevron; the menu label itself must never
  navigate.
- **Global actions** open panels (notifications, profile, switcher) —
  they should not navigate directly. Set `isActive: true` while the
  action's panel is open.
- **Switcher** lists sibling products or accounts inside a
  `CarbonHeaderPanel`; mark the current one `selected: true`.

## Configurations

- *Header only* — a handful of top-level sections, no secondary
  navigation. Maximizes horizontal content space but cannot keep a
  sub-menu open alongside the page.
- *Header with left panel* — `CarbonSideNav(expanded: ...)` stacks more
  destinations vertically and lets `CarbonSideNavMenu` groups stay open
  without covering content. Use `rail: true` for a 48px icon rail that
  expands over the page on hover or focus.

Product-level links sit at the start of the header; system-level actions
sit at the end. Carbide does not yet auto-collapse header links into the
side panels at narrow widths — switch layouts yourself (for example with
`LayoutBuilder`), which also lets you keep the visual order aligned with
the semantic order.

## Best practices

- The header is *global*: keep it identical on every screen so users can
  reference it to orient themselves. Product-specific navigation belongs
  in the side nav, which may vary per area.
- Use the header to signal state — signed-in account, active mode — not
  just location. Pair with `CarbonBreadcrumb` in the page body for
  drill-down trails back to the root.
- Order side-nav items by user tasks, not by org chart. Avoid unbounded,
  user-generated lists in `CarbonSideNav`; use drill-down pages instead.

## Accessibility

- Put `CarbonSkipToContent` first in the tree so keyboard users can jump
  past the navigation; it stays invisible until focused.
- `CarbonHeader`, `CarbonHeaderPanel`, `CarbonSwitcher`, and
  `CarbonSideNav` each emit a labelled semantics container — Carbide's
  analogue of landmark regions — so screen-reader users can move between
  header, panel, and content directly.

## Example

```dart
CarbonHeader(
  menuButton: CarbonHeaderMenuButton(
    label: 'Open menu',
    isOpen: _navOpen,
    onPressed: _toggleNav,
  ),
  name: CarbonHeaderName(prefix: 'Acme', name: 'Console'),
  navigation: <Widget>[
    CarbonHeaderMenuItem(label: 'Dashboards', selected: true),
    CarbonHeaderMenuItem(label: 'Reports', onPressed: _goReports),
  ],
  globalActions: <Widget>[
    CarbonHeaderGlobalAction(
      icon: CarbonIcons.switcher,
      label: 'Switch product',
      isActive: _switcherOpen,
      onPressed: _toggleSwitcher,
    ),
  ],
)
```

## Related

- [Search pattern](search.md) — global search placement
- [Overflow content pattern](overflow-content.md) — collapsing controls
- Gallery: UI shell, Breadcrumb pages
