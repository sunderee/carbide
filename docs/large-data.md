# Large tables and trees

`CarbonDataTable` and `CarbonTreeView` retain their eager rendering mode by
default. Use it for small datasets and wherever a parent measures intrinsic
height or width. Carbide's supported performance envelope for eager views is
up to **100 rendered records with ordinary cells/nodes**. This is a guidance
ceiling, not an input assertion or a guarantee for complex cell widgets. Above
it, paginate the data or opt into a bounded virtual view; profile the actual
application and target devices.

## Virtual views

Both components accept `virtualized: true`, `viewportHeight` (default 320px),
and an optional caller-owned `scrollController`. The viewport mounts its visible
window and retains a row while one of its descendants has focus. A focused
editor therefore keeps its widget state when scrolled away and back. Other rows
can recycle; put durable drafts in the data model or caller-owned controllers.
The viewport does not support intrinsic measurement.

Tables require a unique, non-null `CarbonTableRow.id` for every row and the
ID-based selection/expansion APIs. The same IDs key sliver reconciliation after
sorting. With `stickyHeader: true`, the header remains outside the scrolling
body and `viewportHeight` bounds the body; otherwise the header scrolls inside
the viewport. The existing `stickyHeaderHeight` continues to bound eager sticky
tables. Expanded detail and arbitrary-height cells use a variable-height sliver.
A long direct jump may refine the estimated end as new rows/details are measured;
normal scrolling uses the corrected extent. Use pagination for repeated random
access to distant, highly variable rows.

```dart
CarbonDataTable(
  columns: const [CarbonTableColumn(title: 'Name')],
  rows: [
    for (final record in records)
      CarbonTableRow(id: record.id, cells: [Text(record.name)]),
  ],
  virtualized: true,
  viewportHeight: 320,
  stickyHeader: true,
  selectedRowIds: selectedIds,
  onSelectedRowIdsChanged: updateSelection,
)
```

Trees preserve stable node IDs, expansion, selection and keyboard navigation.
Home/End and arrow navigation reveal logical targets even when their widgets
have never mounted. The fixed row extent uses the actual scaled Plex line
height and the Carbon minimum; text scaling is not clamped. Visited focus-node
identities remain available until their data IDs are removed. The tree's data
index/visible-node flattening and the table's ID index remain proportional to
the supplied model count; virtualization bounds widget mounting, not the data
itself. Only mounted rows contribute visible accessibility nodes.

```dart
CarbonTreeView(
  nodes: nodes,
  label: 'Files',
  virtualized: true,
  viewportHeight: 320,
  expandedIds: expandedIds,
  onExpansionChanged: updateExpansion,
)
```

Provide enough horizontal space for table columns and the batch-actions bar.
In a narrow host, wrap the table in a horizontal scroll view with an explicit
content width. `viewportHeight` controls vertical rendering and scrolling.

## Measurements

Before implementation, the opt-in
[`data_rendering_benchmark.dart`](../test/benchmarks/data_rendering_benchmark.dart)
ran three fresh native debug/JIT processes for every case with Flutter 3.47.6 /
Dart 3.13.5 on this macOS host. Tables had two columns, a sticky 320px body,
expansion enabled and all details closed; trees were flat with a 320px fold.
All models were allocated before the baseline and five rows warmed the
component. No other local builds, tests or browser runs ran concurrently.

| Eager view | Records | Build spans median | Layout spans median | Retained heap delta | Mounted elements |
|---|---:|---:|---:|---:|---:|
| Table | 100 | 126.55ms | 40.04ms | 16.14MB | 6,571 |
| Table | 1,000 | 741.69ms | 281.76ms | 154.59MB | 65,071 |
| Table | 10,000 | 24,477.36ms | 1,724.20ms | 1,522.15MB | 650,071 |
| Tree | 100 | 49.65ms | 21.85ms | 5.39MB | 2,140 |
| Tree | 1,000 | 307.17ms | 122.52ms | 48.36MB | 21,040 |
| Tree | 10,000 | 3,165.33ms | 777.31ms | 473.44MB | 210,040 |

The same three-process protocol with `DATA_VIRTUALIZED=true` gave:

| Virtual view | Records | Build spans median | Layout spans median | Retained heap delta | Mounted elements |
|---|---:|---:|---:|---:|---:|
| Table | 100 | 28.47ms | 36.75ms | 1.71MB | 595 |
| Table | 1,000 | 24.62ms | 35.27ms | 1.74MB | 595 |
| Table | 10,000 | 46.15ms | 37.79ms | 2.21MB | 595 |
| Tree | 100 | 13.52ms | 18.43ms | 1.17MB | 341 |
| Tree | 1,000 | 29.52ms | 35.94ms | 1.36MB | 341 |
| Tree | 10,000 | 30.81ms | 12.72ms | 3.75MB | 341 |

Sliver builders run during layout. Timeline build/layout spans can overlap and
include nested work; their medians are not additive. Wall pump medians for the
10,000-record virtual views were 72.54ms (table) and 43.94ms (tree), compared to
27,665.77ms and 4,434.89ms for their eager counterparts. Small-case timing
variation remains visible in these fresh-process measurements.

MB means decimal megabytes. VM timeline `BUILD`/`LAYOUT` spans measure the first
full mount. Two GC requests and a finalizer gap precede snapshots; heap deltas
estimate retained isolate/framework allocation and do not isolate exact widget
ownership. Whole-process RSS also includes native allocations, heap capacity,
JIT code and allocator retention: eager 10,000-record median growth was 2.14GB
for the table and 760.09MB for the tree. These are debug/JIT measurements,
not release frame-time or browser-memory claims. Leak-test creation-stack
instrumentation is paused only in the measurement harness; ordinary component
regressions continue to check leaks. See the
[benchmark instructions](../test/benchmarks/README.md) for reproduction.
