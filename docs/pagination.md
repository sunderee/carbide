# Pagination input and layout policy

Pagination validates positive page sizes, one-based pages and non-negative
result totals at construction. Its public constructor remains const, so the
non-empty, unique, positive `pageSizes` list is validated when the widget builds.
Keep the configured list immutable. A valid current size omitted from that list
is added to the control's choices, so the field still describes its value.

A page beyond the available results is clamped for the readout, page selector
and previous/next callbacks. This tolerates a transient stale page while filters
shrink the result set. Zero results display `0–0`, with effective page one and
both arrows disabled. Range/page-count arithmetic and the bounded option window
avoid overflow even at the maximum integer input.

The page selector contains at most seven choices: nearby pages plus the first
and last page. It never allocates an option for every page in an unbounded
domain. The full total remains visible in the page-count readout.

The desktop row keeps its normal treatment. Below Carbon's 672px medium
breakpoint, or whenever measured labels and controls would exceed available
width, the content reflows with wrapping labels and selectors. Unlike upstream's
mobile rule that hides the selectors, this layout keeps the choices available.
Numbers grow the control width when needed. Global keys preserve selector and
button state/focus when the layout changes, including an open popup.

`CarbonPaginationLocalizations` follows the date-picker delegate pattern: inject
labels, locale, number formatting, complete range/page-count phrases and active
option announcements. Consumers can adapt `intl` or another backend without
adding a package dependency to Carbide. Ambient Directionality controls layout
and arrow direction. Existing `itemsPerPageText`, `backwardText` and `forwardText`
arguments take precedence over delegate labels.

```dart
CarbonPagination(
  page: currentPage,
  pageSize: 20,
  totalItems: results.length,
  localizations: CarbonPaginationLocalizations(
    locale: const Locale('de'),
    paginationLabel: 'Seitennavigation',
    itemsPerPageLabel: 'Ergebnisse pro Seite',
    pageLabel: 'Seite',
    previousPageLabel: 'Zurück',
    nextPageLabel: 'Weiter',
    rangeFormatter: (start, end, total) => '$start–$end von $total Ergebnissen',
    pageCountFormatter: (total) => 'von $total Seiten',
    activeOptionFormatter: (label, position, count) => '$label ($position/$count)',
  ),
  onPageChanged: setPage,
)
```
