# Breadcrumb overflow and navigation

`CarbonBreadcrumb` measures its trail using the active link/text styles, locale,
text scaling and available width. A trail that fits keeps its existing layout.
When it exceeds that width, the first and last items stay visible and middle
ancestors move into `CarbonOverflowMenu`. The nearest trailing ancestors remain
visible while space permits. A breadcrumb stays on one line; very long retained
labels ellipsize while keeping their full accessible names. Unbounded layouts
keep every item, and font changes trigger fresh measurements.

The pinned Carbon React component exposes the overflow composition through its
story rather than implementing an automatic measuring algorithm. Its design
guidance recommends retaining the first and last two links where space allows.
This port automates that composition and follows issue #320's stronger rule to
retain the first/current anchors on narrow screens.

Mark the final item with `isCurrentPage: true`. It renders selected plain text
and ignores a navigation callback supplied on that item. Its accessible name
includes `currentPageLabel`; Flutter maps its selected semantics to native
`aria-current` on the web. Other noninteractive items remain plain text, and
hidden noninteractive ancestors remain named disabled menu rows. Region,
overflow-trigger and current-page descriptions are localizable through
`breadcrumbLabel`, `overflowLabel` and `currentPageLabel`.

Tab reaches each visible link and the compact horizontal ellipsis. Enter or
Space opens its menu; arrows, Home/End and typeahead navigate hidden ancestors.
Enter activates a row once. Escape or selection closes the menu and restores
the trigger's focus through the existing menu primitive. Widening the trail
removes the overflow and disposes an open menu without reporting navigation.
Use a `WidgetsApp`/Navigator or another Overlay host, as for other Carbon menus.

RTL reverses the logical trail, slash drawing and menu anchoring. Separators
are decorative and excluded from announcements. Extremely small constraints
reduce label and separator space without producing layout overflows; no layout
can show meaningful label text when its available width is zero.

`CarbonLink` retains callback-based navigation. Flutter 3.47.6 renders such
links as anchors without an href, which has no implicit browser link role.
A small web adapter supplies the role, disabled state and traversal policy
while preserving the engine's actions. It introduces no destination or native
navigation. `maxLines` and `overflow` are optional link-label constraints;
their defaults preserve existing link rendering.

The gallery exposes long/narrow trails, direction, trailing slash and link
size controls and shows the last navigation action. Widget, native browser,
Linux golden and release-gallery checks cover these independently.
