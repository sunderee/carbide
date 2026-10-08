# ADR 0002: Carbon v12 feature-flag posture

- **Status:** accepted
- **Date:** 2026-07-04
- **Issue:** #220

## Context

Carbon gates its next-major behavior changes behind `@carbon/feature-flags`.
The registry (`documentation/carbon/packages/feature-flags/feature-flags.yml`
@ v11.111.0) lists sixteen flags; only `enable-v11-release` is enabled by
default. Everything Carbide has ported so far — every SCSS citation, every
golden — locks the **default (flags-off) v11 rendering**. A port that never
looks at the flags re-diverges the day Carbon v12 flips them; a port that
adopts them piecemeal without a policy stops being comparable to any single
upstream configuration.

This ADR records, per flag, whether Carbide's behavior follows the v11
default or the flagged (v12) behavior, and the general rule for flags that
appear in future submodule bumps.

Two things make the Flutter context different from the React one, and they
drive most of the decisions:

- Several flags exist to fix **web/DOM mechanics** (sentinel nodes, CSS
  custom properties, floating-ui inline styles, the native `<dialog>`
  element). Flutter has no DOM; Carbide implements the *outcome* natively,
  so the flag's old-vs-new distinction has no analogue.
- Several flags exist to fix **React API legacy** (uncontrolled component
  state). Carbide was written controlled-first in the Flutter idiom, so the
  flagged API shape is the one we already have.

## Decision

### The general rule

1. **Carbide tracks the v11 default (flags off) for visual behavior.** The
   fidelity bar — SCSS-cited spec locks and four-theme goldens — is only
   meaningful against one upstream configuration, and that configuration is
   the released default.
2. A flagged behavior is adopted early only when at least one of these
   holds:
   - the flag fixes a web-only mechanism and Carbide's native
     implementation already produces the flagged outcome;
   - the flag is an API-shape change (not visual) whose target matches the
     Flutter idiom Carbide already uses;
   - tracking the v11 default would fracture Carbide's own cross-component
     consistency;
   - upstream has deprecated the unflagged path, so the flagged one is the
     only future.
3. **Every deliberate adoption is documented in the component file header,
   naming the flag** and citing this ADR.
4. Deferred visual flags are adopted **together, as one migration, when
   Carbon v12 flips the defaults** — with regenerated goldens and updated
   spec locks in the same change. The per-flag table below is the seed of
   that migration checklist.
5. The flag registry is re-read at every knowledge-base (submodule) bump;
   new flags get a row in this ADR (amended or superseded) before any
   component work that touches them.

### Per-flag decisions (registry @ v11.111.0)

The v11.118.0 source review for #331 also records `enable-v12-release` below.
It remains disabled upstream. Its new button-radius fallback and other visual
changes follow the same deferred migration policy; Carbide does not expose a
v12 radius mode or a public border-radius token family yet.

| Flag | Decision |
|---|---|
| `enable-v11-release` | Baseline (enabled upstream) |
| `enable-v12-release` | Defer the next-major visual defaults, including button radius, to the coordinated v12 migration |
| `enable-css-custom-properties` | N/A — web mechanics |
| `enable-css-grid` | N/A — web mechanics |
| `enable-v12-overflowmenu` | **Adopted** (already) |
| `enable-treeview-controllable` | **Adopted** (already, by API shape) |
| `enable-v12-toggle-reduced-label-spacing` | **Adopted** (already, consistency) |
| `enable-presence` | **Adopted** (already, by construction) |
| `enable-focus-wrap-without-sentinels` | N/A — outcome is native |
| `enable-dialog-element` | N/A — web platform primitive |
| `enable-v12-dynamic-floating-styles` | N/A — positioning is native |
| `enable-tile-contrast` | Defer to v12 |
| `enable-v12-tile-default-icons` | Defer to v12 |
| `enable-v12-tile-radio-icons` | Defer to v12 |
| `enable-v12-structured-list-visible-icons` | Defer to v12 |
| `enable-enhanced-file-uploader` | Defer to v12 (largely moot) |
| `enable-experimental-tile-contrast`, `enable-experimental-focus-wrap-without-sentinels` | Deprecated aliases — follow their replacements |

#### Baseline

- **`enable-v11-release`** — the only flag enabled by default; it *is* the
  v11 behavior set Carbide ports. Nothing to do.

#### Adopted now (already true in Carbide)

- **`enable-v12-overflowmenu`** — upstream re-implements OverflowMenu on
  the Menu subcomponents. `CarbonOverflowMenu` has been a trigger over the
  Carbide Menu primitive since it landed (#92): roving focus, type-ahead,
  and Escape live in the menu engine, exactly the flagged architecture.
  The legacy v10-style OverflowMenu is what v12 deletes; porting it would
  have been porting a dead end. Header updated to name the flag.
- **`enable-treeview-controllable`** — upstream's flag makes TreeView
  `selected`/`active` genuinely controllable (`useControllableState`,
  `TreeView.tsx:107-121` @ v11.111.0) instead of initial-value-only, and
  adds `onActivate`. `CarbonTreeView` was written controlled-first
  (`selectedId` + `onSelect`), which is the flagged shape in the Flutter
  idiom. The remaining surface the flagged API exposes that Carbide does
  not — `multiselect` and the separate active-vs-selected distinction — is
  tracked as follow-up parity work (see Consequences), not a flag matter.
  Header updated to name the flag.
- **`enable-v12-toggle-reduced-label-spacing`** — the flag reduces the gap
  between the toggle's top label and the control from `$spacing-05` (16px)
  to `$spacing-03` (8px) (`_toggle.scss:35-40`). Carbide's `CarbonToggle`
  stacks its label with the shared `CarbonFormLabel`, which carries the
  8px form-label margin used by every other labelled control. Reverting
  the toggle alone to 16px would break Carbide's cross-component label
  rhythm to preserve a spacing upstream itself considers wrong (hence the
  flag). We keep 8px — the flagged value. Header updated to name the flag.
- **`enable-presence`** — upstream's flag makes overlays mount on open and
  unmount on close instead of rendering hidden
  (`Modal/ModalPresence.tsx`, `ComposedModal/ComposedModalPresence.tsx`).
  Carbide overlays (`CarbonModal`, `CarbonDialog`, popovers, menus) are
  built on `OverlayPortal` show/hide: closed content is not in the tree at
  all. That is the flagged semantics by construction, and it is already
  stated in the component doc comments ("Controlled via [open]"). One
  nuance: presence also coordinates exit transitions before unmount. #339
  implements this for Modal and Dialog with moderate-02 expressive exit motion,
  retaining focus, semantics and modal background locking until removal.
  Reduced motion removes immediately; reopening cancels pending removal.

#### N/A — the mechanism doesn't exist in Flutter

- **`enable-css-custom-properties`**, **`enable-css-grid`** — CSS
  implementation strategy. Carbide themes are `InheritedWidget` data and
  `CarbonGrid` is a widget; there is no analogous choice to make.
- **`enable-focus-wrap-without-sentinels`** — removes the DOM sentinel
  nodes React uses to wrap focus. Flutter focus traps (`FocusScope` with
  descendant traversal, as in `CarbonModal`/`CarbonDialog`) never had
  sentinels; the flagged outcome is the only possible implementation.
- **`enable-dialog-element`** — swaps the markup to the native `<dialog>`
  element. Web platform primitive; Carbide's `CarbonDialog` implements the
  equivalent semantics (modal scrim, focus trap and restore, Escape on
  modal dialogs) directly.
- **`enable-v12-dynamic-floating-styles`** — moves Popover/Tooltip
  positioning from static CSS classes to floating-ui inline styles.
  Carbide computes popover geometry in the layout system already; the
  auto-alignment behaviors the flag enables are represented by our
  alignment logic, not by a styling mode.

#### Defer to v12 (visual deltas; adopt as one migration when defaults flip)

- **`enable-tile-contrast`** — clickable/selectable tiles gain a 1px
  `$border-tile` border (`$border-disabled` when disabled), and the
  selection checkmark becomes always-visible (`_tile.scss:79-86, 126-133,
  164-171, 239-246`). Pure rendering change; adopting early would break
  every tile golden against the released default. Migration note: Carbide
  has no `borderTile` token yet — the theme generator grows it when this
  lands.
- **`enable-v12-tile-default-icons`** — clickable tiles render a default
  `ArrowRight` icon (an `Error` icon when disabled) if the caller provides
  none (`Tile.tsx:268-276`). `CarbonClickableTile` already exposes the
  caller-provided `icon` slot, so this is a *defaults* change only; the
  v11 default (no icon unless given) stands until v12.
- **`enable-v12-tile-radio-icons`** — `RadioTile` renders
  `RadioButton`/`RadioButtonChecked` icons instead of `CheckmarkFilled`
  (`RadioTile.tsx:154-165`). `CarbonRadioTile` renders `checkmarkFilled`,
  the v11 default; the icon swap is a one-line migration at v12.
- **`enable-v12-structured-list-visible-icons`** — the selection icon
  column stops being transparent-until-selected and the checked icon fills
  `$icon-primary` (`_structured-list.scss:202-225`).
  `CarbonStructuredList` renders the checkmark only on the selected row —
  visually identical to the v11 default. Defer.
- **`enable-enhanced-file-uploader`** — richer DOM event payloads
  (`onChange` also firing for deletions/clear, file data on
  `event.target`, a `getCurrentFiles` handle; `FileUploader.tsx:125-166`).
  Largely moot: `CarbonFileUploader` is app-driven — the caller owns the
  file list and receives typed per-item callbacks, so there is no DOM
  event shape to enrich. Re-evaluate the callback surface when the v12
  API stabilizes; nothing to adopt today.

## Consequences

- Component headers now name the flag they deliberately track:
  `carbon_overflow_menu.dart`, `carbon_toggle.dart`,
  `carbon_tree_view.dart`. Overlay mount semantics were already documented
  in the modal/dialog doc comments; those files are left untouched here to
  avoid churn against in-flight PRs.
- The **#216 deferred item is unblocked**: Selectable/Radio tile AI
  decorator slots proceed against the v11 rendering (checkmark visible on
  hover/selection for SelectableTile, `checkmarkFilled` for RadioTile).
- The v12 migration checklist is the "Defer to v12" list above, plus:
  regenerate all tile/structured-list goldens, add the `borderTile` token,
  and swap the RadioTile icon pair.
- Follow-up filed for the TreeView API surface the controllable flag
  exposes beyond Carbide's current single-select (`multiselect`,
  active-vs-selected split).
- No implementation issues are needed for the adopted flags — all four
  were adopted before this ADR existed; this document and the header
  updates make that intentional rather than incidental.
