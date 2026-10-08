# Grid gutters and layout boundaries

`CarbonGrid` lays out responsive `CarbonColumn` slots. Gutters belong inside
each column's allocated tracks, including when a column spans several tracks.
The track allocation excludes the responsive outer margin and reserves one
shared logical pixel to avoid premature `Wrap` rows from floating-point sums.

| Mode | Logical start gutter | Logical end gutter | Gap between visible contents |
| --- | --- | --- | --- |
| `wide` | 16px | 16px | 32px |
| `narrow` | 0px | 16px | 16px |
| `condensed` | 0.5px | 0.5px | 1px |

These values follow pinned Carbon v11.118.0:
[`_config.scss`](https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/grid/scss/_config.scss)
sets the 32px gutter and 1px condensed gutter, while
[`_css-grid.scss`](https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/grid/scss/_css-grid.scss)
gives wide columns two half-gutters and sets narrow's start gutter to zero.
Narrow content moves 16px toward the logical start relative to wide; the end
gutter is retained. Carbide mirrors these logical edges with `Directionality`,
as requested by #322. It does not reproduce Carbon's separate RTL CSS
`margin-inline` variable swap; the native layout uses the same logical policy
in both directions. Current Carbon's base narrow rules do not
use symmetric outer-edge expansion or 32px narrow interior gaps.

Previously Carbide's wide and narrow modes were identical, and wide omitted
the column padding promised by its API documentation. Both now use the
per-column model. Visible wide content therefore receives the missing outer
half-gutters, and columns of different spans share the same proportional track
allocation. `offset` consumes empty logical tracks before the content gutter.

Nested narrow grids do not apply a negative outer offset, so their content
keeps its parent's start edge. Each grid still resolves its own responsive
margin and breakpoint from its available width. Use `fullWidth: true` on a
nested grid to remove that independent margin. For compatibility, Carbide's
`fullWidth` omits responsive edge margins; upstream CSS grid's full-width class
instead removes its maximum-width cap. Carbide does not add a maximum-width
cap implicitly.

This remains a Flutter `Wrap` layout. It supports breakpoint spans, automatic
rows, logical offsets and `rowSpacing`; it does not implement CSS grid named
tracks, explicit cell placement, row spanning or inherited subgrid track
definitions. These boundaries are separate from the gutter correction. The
gallery exposes gutter mode and full width so their geometry can be compared.
