# Overflow content

How to handle text and controls that exceed their space: truncate with a
tooltip, collapse into an overflow menu, or reveal with "Show more".

> Adapted from the Carbon Design System "Overflow content" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Truncated text | `CarbonText` with `maxLines: 1` and `overflow: TextOverflow.ellipsis` |
| Full value on hover/focus | `CarbonTooltip` wrapping the truncated text |
| Collapsed controls | `CarbonOverflowMenu` with `CarbonMenuItem` rows |
| "Show more" reveal | built into `CarbonCodeSnippet` (`showMoreText`); elsewhere a ghost `CarbonButton` toggling the content |

## Truncation

Shorten static text or links that exceed their container with an
ellipsis. A truncated string must hide at least three characters and
keep at least four visible. Except at the end of a paragraph, every
truncated string needs a `CarbonTooltip` carrying the full value, since
the ellipsis alone gives no way to read what was cut.

Good candidates: breadcrumb labels, long URLs, description paragraphs,
long user- or platform-generated names. Never truncate page headers,
titles, field labels, error or validation text, or notifications —
those must always be fully readable.

```dart
CarbonTooltip(
  label: deviceName,
  child: CarbonText(
    deviceName,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  ),
)
```

### Variations

Carbon defines three truncation positions; Flutter's `TextOverflow`
only produces the last one, so the first two need string preprocessing:

- *End-line* (`12345...`) — the continuation is elsewhere or the string
  is simply long. Use `overflow: TextOverflow.ellipsis`.
- *Front-line* (`...56789`) — the distinctive part is the ending (serial
  numbers, file paths). Carbide has no helper; shorten the string
  yourself and prepend the ellipsis, keeping the full value in the
  tooltip.
- *Mid-line* (`1234...5678`) — strings share middles but differ at both
  ends. Same approach: build the shortened string manually.

## Ellipsis as a control

An ellipsis button that *does* something — collapsing a set of actions
or hidden items — is not truncation. Use `CarbonOverflowMenu`, which
renders the standard `⋮` icon button and opens a `CarbonMenu`:

```dart
CarbonOverflowMenu(
  iconDescription: 'More actions',
  items: <Widget>[
    CarbonMenuItem(label: 'Rename', onPressed: _rename),
    CarbonMenuItem(
      label: 'Delete',
      kind: CarbonMenuItemKind.danger,
      onPressed: _delete,
    ),
  ],
)
```

Gap: upstream collapses long breadcrumbs into an ellipsis with an
overflow menu; `CarbonBreadcrumb` does not implement that collapse yet
(tracked as a follow-up). Until it lands, keep trails short or compose
a `CarbonOverflowMenu` between the first and last crumbs yourself.

## "Show more"

When a significant block overflows, prefer an explicit "Show more"
button over inner scrolling, gradients, or fades — it is visible and
actionable. Pair it with "Show less" to re-collapse, or label it "Load
more" when fetching further content (see the
[loading pattern](loading.md)).

`CarbonCodeSnippet` ships this behavior: multi-line snippets collapse
past `maxCollapsedRows` and expose the `showMoreText`/`showLessText`
toggle. For other content, toggle a height-constrained container with a
ghost `CarbonButton`; there is no generic show-more wrapper in Carbide.

## Related

- [Global header pattern](global-header.md) — collapsing navigation
- [Text toolbar pattern](text-toolbar.md) — overflow menus for controls
- Gallery: Tooltip, Overflow menu, Code snippet pages
