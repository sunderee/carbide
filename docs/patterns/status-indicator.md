# Status indicators

Communicating the state of a thing — an object, a system, a task — with
the right indicator at the right weight.

> Adapted from the Carbon Design System "Status indicators" pattern
> (Apache-2.0, carbon-design-system/carbon-website; see NOTICE). Guidance
> is rewritten for Carbide's API.

## The variants

| Variant | Carbide API | Reads as | Use for |
|---|---|---|---|
| Icon indicator | `CarbonIconIndicator` | A labelled 16/20px status icon | Statuses that need to be *read*: table cells, detail panes, legends |
| Shape indicator | `CarbonShapeIndicator` | A tiny 12/14px glyph + label | Dense surfaces where a full icon is too loud: trees, side panels, compact tables |
| Badge indicator | `CarbonBadgeIndicator` | A dot or count on another control | Unread/attention counts on icon buttons (header actions) |
| Tag | `CarbonTag` | A colored label | Categorical state ("Beta", "Deprecated") rather than live status |
| Inline loading | `CarbonInlineLoading` | An animated transitional state | States that are *in motion* (sending, provisioning) |

Choose by context, then **standardize**: the same status must use the same
variant, kind, and wording everywhere in a product. A mixed vocabulary
("Failed" here, a red dot there, "Error" elsewhere) is worse than any
single choice.

## Severity levels

Group your statuses into attention tiers and map them consistently:

- **High attention** — needs action now: `failed`, `critical`,
  `cautionMajor`. Red and orange. Place these first in sort orders and
  summaries.
- **Medium attention** — feedback on activity, no action needed:
  `inProgress`, `incomplete`, `pending`, `cautionMinor`.
- **Low attention** — ready/steady/informational: `succeeded`, `normal`,
  `stable`, `draft`, `informative`.

`CarbonIconIndicatorKind` covers: `failed`, `cautionMajor`,
`cautionMinor`, `undefined`, `succeeded`, `normal`, `inProgress`,
`incomplete`, `notStarted`, `pending`, `unknown`, `informative`.
`CarbonShapeIndicatorKind` covers: `failed`, `critical`, `high`,
`medium`, `low`, `cautious`, `undefined`, `stable`, `informative`,
`incomplete`, `draft`.

## Rules

- **Always pair the symbol with a label.** Color and shape alone exclude
  color-blind users; the built-in labels are also what screen readers
  announce. Omit the visible label only where the status is explained
  immediately adjacent (and keep the semantic label).
- Do not invent new status colors; the kinds map to Carbon's support
  palette (red/orange/yellow/green/blue/purple/gray) with meanings users
  already know.
- Statuses that change while the user watches should transition through
  `CarbonInlineLoading` (active → finished/error), not flip icons
  silently.
- In tables, put the indicator in its own column, sorted by severity by
  default, so scanning the column answers "is anything wrong?".

## Example

```dart
// A table cell:
const CarbonIconIndicator(
  kind: CarbonIconIndicatorKind.failed,
  label: 'Failed',
)

// A dense tree row:
const CarbonShapeIndicator(
  kind: CarbonShapeIndicatorKind.critical,
  label: 'Critical',
)

// Unread count on a header action:
const CarbonBadgeIndicator(count: 4)
```

## Related

- [Notifications pattern](notification.md) — status *events* rather than
  status *state*
- [Loading pattern](loading.md) — transitional states
- Gallery: Indicators page
