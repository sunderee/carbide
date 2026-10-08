# Lazy picker options

Dropdown, select, combo box and multi-select accept `itemBuilder` and
`itemCount` together, alongside their existing eager `items` API. Omit `items`
when using the builder. This builder reads **option data**, rather than a
widget, so disabled skipping, typeahead, selection and filter search can inspect
options that have never mounted.

```dart
CarbonDropdown<int>(
  titleText: 'Account',
  itemCount: accounts.length,
  itemBuilder: (index) => CarbonDropdownItem<int>(
    value: accounts[index].id,
    label: accounts[index].name,
    disabled: accounts[index].archived,
  ),
  selectedItem: selectedAccount,
  onChanged: selectAccount,
)
```

Use the corresponding `CarbonSelectItem`, `CarbonComboBoxItem` or
`CarbonMultiSelectItem` for the other controls. Select's builder supplies flat
items; its existing eager API continues supporting groups and group headings.
A zero count represents an empty source. Incomplete builder/count pairs,
negative counts and supplying both APIs are rejected by constructor assertions.

Builders must be pure and inexpensive, with stable option values. They can
return fresh model objects: value reconciliation does not depend on object
identity. Reading selected values, filtering or typeahead may scan metadata
across the source; these operations do not mount offscreen widgets. Filtering
retains matching indices and reuses that index map until the query or widget
configuration changes, while reading the latest option metadata by index.

The lazy menu mounts only its viewport window, with no offscreen cache. The
ordinary Carbon popup fold remains the maximum height; viewport collisions,
resize and ancestor scale can bound it further. Single-line row extents use the
actual text scaler and include the row divider, content padding and checkbox
label inset. Keyboard reveal computes an offset from the logical highlight,
so it can reach a row that has never mounted. Native editor focus stays on the
trigger throughout navigation and filtering.

Only mounted visible options contribute option nodes. The trigger's active
hint and live region describe the logical position and current source/filter
count, including disabled entries, while the committed value stays separate.
Non-filterable multi-select also supports the same label-prefix typeahead as
dropdown/select. Editable combo/multi-select search through their query text.

Existing `items` callers retain eager rendering, intrinsic row measurement,
groups and their normal goldens. The 1,000-row eager regression remains in the
scroll suite. Lazy regressions separately verify a bounded mounted window,
never-mounted reveal, disabled skipping, fresh-model preselection, scaled
line boxes, RTL, source shrink and native semantics.
