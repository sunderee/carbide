# Search

How to choose between basic, active, and focused search, and wire each
to Carbide's search field.

> Adapted from the Carbon Design System "Search" pattern (Apache-2.0,
> carbon-design-system/carbon-website; see NOTICE). Guidance is rewritten
> for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Search field | `CarbonSearch` (magnifier icon, clear button, no visible label) |
| Collapsed-to-icon search | `CarbonExpandableSearch` |
| Search inside a data table | `CarbonTableToolbar.onSearchChanged` |
| Type-ahead over a fixed option list | `CarbonComboBox` |
| Scope filter | `CarbonDropdown` beside the field |
| Search in flight | `CarbonInlineLoading`, `CarbonProgressBar` |
| Results paging | `CarbonPagination`, `CarbonPaginationNav` |

## Anatomy

A search is the magnifier icon, useful placeholder text ("Search for
networks or devices"), and the entry field — `CarbonSearch` renders all
three plus a clear button once text is entered. Do not add a visible
label; users recognize search fields, and `CarbonSearch.labelText` keeps
an accessible (visually hidden) name for screen readers. An optional
scope `CarbonDropdown` sits before the field; always include an "All"
choice and select it by default. Carbide has no fused scoped-search
composite, so place the dropdown and field side by side in a `Row`.

## Choosing a type

- *Basic search* — the query runs only on submit and routes to a
  distinct results page. Use when searching is expensive or slow, or
  when users are unfamiliar with the data and benefit from a full
  results page. Trigger it from the field's `onSubmitted` equivalent in
  your handler (run the search on Enter via a `Focus`/`Shortcuts`
  wrapper or a trailing button; `CarbonSearch` itself only reports
  `onChanged`/`onClear` — submit handling is yours).
- *Active search* — the query runs after every character and results
  update in place. Best for small data sets (a page, a catalog, a
  table) where feedback per keystroke is cheap. Wire `onChanged`
  straight into your filter; show everything until typing starts.
- *Focused search* — active results scoped to the user's immediate
  context, with a trailing "See all results" row that widens into a
  basic search. Ideal inside one tool of a larger suite.

Carbide has no results-panel or suggestion-menu component for recent
searches and type-ahead under a free-form field; compose one from
`CarbonLayer` + `CarbonContainedList`, or use `CarbonComboBox` when the
suggestions are a fixed option list it can filter for you.

## Best practices

- *Avoid dead ends.* On "No results", say so and suggest a follow-up:
  check spelling, broaden the scope, browse a related area.
- *Show progress.* If a search takes more than a moment, show
  `CarbonInlineLoading`; for long, resource-heavy searches use
  `CarbonProgressBar` so users can gauge the wait.
- *Count results.* Always display the number of matches — including
  zero — and per-scope counts if you offer a scope filter.
- *Localize.* In right-to-left locales the row order mirrors
  automatically when you use directional layout; the magnifier icon
  itself is understood everywhere.

## Example

An active search filtering an on-page catalog:

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    CarbonSearch(
      placeholder: 'Search for devices',
      onChanged: (String query) =>
          setState(() => _visible = _filter(_devices, query)),
      onClear: () => setState(() => _visible = _devices),
    ),
    CarbonText('${_visible.length} results'),
    for (final Device device in _visible) DeviceTile(device: device),
  ],
)
```

## Accessibility

`Tab` reaches the field; typing and clearing are standard text-editing
interactions, and the clear button is a labelled tap target
(`closeButtonLabel`). If you add a scope dropdown or a suggestion list,
they must be keyboard-reachable too: `CarbonDropdown` and
`CarbonComboBox` already implement arrow-key cycling, Enter to select,
and Escape to dismiss. After a filter or facet changes the results,
keep focus where it was so keyboard users are not thrown back to the
top.

## Related

- [Filtering pattern](filtering.md) — narrowing by attributes
- [Global header pattern](global-header.md) — global search placement
- Gallery: Search, Combo box, Data table, Pagination pages
