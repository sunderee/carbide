# Filtering

How to let users trim a large data set down to the items that matter, by
switching predefined attributes on and off.

> Adapted from the Carbon Design System "Filtering" pattern (Apache-2.0,
> carbon-design-system/carbon-website; see NOTICE). Guidance is rewritten
> for Carbide's API.

## The pieces

| Role | Carbide API |
|---|---|
| Single selection | `CarbonDropdown` (set `inline: true` for compact placement), `CarbonRadioButtonGroup`, `CarbonSelect` |
| Multiselection | `CarbonMultiSelect` (add `filterable: true` for long lists), `CarbonCheckbox` sets |
| Filters inside a menu | `CarbonMenuItemSelectable`, `CarbonMenuItemRadioGroup` |
| Applied-filter summary | `CarbonDismissibleTag` (one per filter), `CarbonTag` (count badge) |
| Batch apply / reset | `CarbonButton` (primary "Apply filters", ghost "Clear filters") |
| Filtering a table | `CarbonDataTable` with `CarbonTableToolbar` |

## Choosing a selection method

Match the control to how users think about narrowing the data:

- *Single selection* — only one attribute can be active at a time.
  Behaves like a radio button: use `CarbonRadioButtonGroup`, or a
  `CarbonDropdown` when space is tight (`inline: true` sits it next to
  the content it filters).
- *Multiselection* — several attributes may combine. Behaves like a
  checkbox set: use `CarbonMultiSelect` in a toolbar, or a standalone
  column of `CarbonCheckbox`es in a filter panel.
- *Multiple categories* — a category is one topic ("size") with its own
  filter choices (small, medium, large). Lay categories out vertically at
  the start of the page or horizontally above the data. Never bury a
  multi-category filter set inside one menu or dropdown.

## Instant vs. batch updates

- *Instant* — refetch as each selection is made. Right when users pick
  from a single category or usually make one selection. Wire the query
  directly to `onChanged`.
- *Batch* — collect selections, then apply them all with an "Apply
  filters" `CarbonButton`. Right when users combine several categories,
  or when a refetch is slow enough that per-click updates would make them
  wait repeatedly.

## Filter states

Start each category either *all unselected* (users want a narrow slice)
or *all selected* (users want to exclude a few items); categories may
differ. When filters live in a collapsed surface — a `CarbonMenu`,
dropdown, or side panel — the closed state must show that filters are
active: render a `CarbonTag` with the applied count next to the trigger,
and offer a clear action that works without reopening the container.

## Resetting filters

Give every category a one-click reset, and — when several categories are
active — a "Clear all filters" action that returns everything to its
default state. Rendering each applied filter as a `CarbonDismissibleTag`
row above the results gives users both at once: dismiss one tag to drop
one filter, or press the ghost clear button to drop them all.

## Example

```dart
Row(
  children: <Widget>[
    for (final String size in _appliedSizes)
      CarbonDismissibleTag(
        label: size,
        onClose: () => _removeSize(size),
      ),
    CarbonMultiSelect<String>(
      titleText: 'Size',
      label: 'Filter by size',
      hideLabel: true,
      items: _sizeItems,
      selectedValues: _appliedSizes,
      onChanged: _applySizes,
    ),
    CarbonButton(
      label: 'Clear filters',
      kind: CarbonButtonKind.ghost,
      onPressed: _appliedSizes.isEmpty ? null : _clearAll,
    ),
  ],
)
```

## Related

- [Search pattern](search.md) — keyword narrowing instead of attributes
- [Notifications pattern](notification.md) — reporting fetch failures
- Gallery: Dropdown, Multi select, Checkbox, Data table pages
