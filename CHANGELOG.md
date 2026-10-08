# Changelog

## Unreleased

- Share viewport placement across pickers, popovers and anchored action menus:
  logical alignment, automatic flipping/clamping, bounded popup constraints,
  composition-time scroll/resize updates and side overrides. Preserve explicit
  dropdown directions and keep popover carets pointing toward their triggers
  after clamping (#335).

- Grow small field, fluid list-box, combo-box, filterable multi-select, search,
  selection-count and menu chrome with scaled text. Add missing specimens,
  inherited-font/editor clipping guards and closed/open scaling coverage while
  preserving normal geometry and fixed icon artwork (#334).

- Measure icon/pictogram path-cache retention and parsing costs, document the
  retained process-lifetime cache policy, and verify value keys, winding rules
  and transformed cached renders. Add a reproducible opt-in benchmark (#340).

- Calibrate the 33-story coarse fidelity gate from measured Linux theme scores
  with recorded margins and rationales. Lock actual control sizes, semantic
  token fills and default states, and prove colour/spacing regression rejection
  with permanent render mutations. Describe the gate's scope accurately (#325).

- Audit all 33 upstream fidelity fixtures against their pinned stories. Use the
  complete Modal and icon Tooltip compositions, correct default copy, variants,
  counts, selection and story framing, and emit full modal review artifacts.
  Correct bounded text content-switcher segments to divide the available width,
  preserving intrinsic icon-only and unbounded layouts (#324).

- Make the gallery shell keyboard accessible with skip-to-main and home actions.
  Move primary navigation between header and side nav at Carbon's lg breakpoint,
  retain full-width mobile content, grow scaled shell labels and preserve
  logical panel borders and native control focus (#330).

- Collapse measured breadcrumb trails into an accessible overflow menu while
  keeping first/current anchors on one line. Localize names, preserve current
  page semantics, mirror RTL and restore hidden ancestor keyboard coverage.
  Expose callback links correctly in native web accessibility (#320).

- Make horizontal tabs scroll with logical edge controls and shared vertical
  overflow/reveal logic. Support automatic/manual activation, preserve roving
  focus independently of selection and expose tab/list/panel roles and panel
  controls. Honor reduced motion, including a preference changed mid-scroll;
  correct the unused underline position and narrow overflow goldens (#321).

- Correct grid tracks and per-column gutters. Wide columns receive their
  documented 16px start/end gutters; narrow removes only the logical start
  gutter and condensed uses 0.5px per edge. Match current Carbon's 16px narrow
  interior gaps, preserve offsets and prevent nested negative hangs (#322).

- Add opt-in time format/parser policies with draft/Enter/Done/group-blur
  commits, canonical normalization, standard parse-error chrome and typed
  12/24-hour behavior with coordinated AM/PM. Keep unconfigured free-text
  typing behavior and caller-owned controllers (#326).

- Add injectable date-picker localization with a shared format/parser pattern,
  derived placeholders, translated calendar labels and configurable week start.
  Use logical RTL day navigation and mirrored month chevrons; retain selection
  and drafts when locale changes and grow long localized text (#319).

- Support Unicode menu typeahead, including supplementary letters and combining
  graphemes. Share documented Latin-1 accent folding with Select and Dropdown,
  preserving single-key cycling and their existing prefix-input policy (#327).

- Resolve menu and list-box elevation colors from the active theme, including
  stronger dark-theme shadows and custom overrides, while retaining Carbon's
  existing offset and blur (#323).

- Add `CarbonFluidText` with automatic viewport breakpoint updates, optional
  enclosing-width resolution, user text scaling and the bundled Plex fonts.
  Preserve text layout/accessibility options and showcase the widget in the
  fluid typography gallery, including serif quotations (#332).

- Generate status and low-contrast content-switcher tokens, honor custom status
  colors in indicators, and publish the token coverage contract. Add viewport
  spacing tokens and fixed expressive heading styles; preserve existing custom
  theme constructors and exact nullable-outline interpolation endpoints (#331).

- Give `CarbonFluidTextStyle` value equality and order-independent hashing for
  breakpoint overrides. Add `copyWith` for deriving a base or replacing the
  override map without reconstructing the cascade (#333).

- Expose structural semantics for nested Carbon lists and document the static
  tag/code-snippet accessibility policy (#318).

- Adapt theme lookup to the nearest platform high-contrast preference with
  `CarbonThemeData.highContrast`. Strengthen boundaries, focus indicators and
  inactive labels across layers, preserve the base theme when the preference
  is off, and apply theme changes instantly in high-contrast mode (#317).

- Resolve decorative animation durations through `carbonDuration`, including
  picker decoration, search clearing, link/list hover, slider focus and tree
  expansion. Vertical tabs reveal selection instantly under reduced motion.
  Guard the shared policy in CI; retain loading and indeterminate progress as
  explicit essential-motion exceptions (#316).

- Open context menus with Shift+F10 or the Context Menu key inside a focused
  target region. Anchor to that focused child's logical start edge, enter the
  first enabled item and restore the opener on dismissal. Tab continues normal
  traversal, while consumer focus requests take precedence (#315).

- Give data tables an accessible name and ordered table, row, header and cell
  roles. Sortable headers expose a named button with a localizable sort-state
  value and an activation target that fills the cell. Preserve keyed row focus,
  expansion and sticky scrolling; enable the table tap-target gate (#307).

- Share active-option semantics across dropdown, select, combo-box and
  multi-select. Announce keyboard navigation without changing the committed
  value or editor query, expose expanded state, and allow localization through
  `activeOptionFormatter`. Each option has one accessible activation target;
  multi-select rows toggle once across their full width (#311).

- Align Select and Dropdown opening keys: Up starts at the last enabled
  option, Down at the first, and Enter/Space at an enabled current selection.
  Let picker keys reach ancestor form/dialog handlers when they perform no
  action, including closed combo-box Enter and Escape and menus with no enabled
  highlight. Closed Escape preserves the combo value; filterable multi-select
  leaves Space available for text entry (#313, #314).

- Add a consistent `readOnly` and localizable `readOnlyHint` contract to the
  picker and search family. Keep names, selected values and keyboard focus
  available while preventing popup opening, editing and clearing; close open
  popups and discard date-range drafts when the policy changes. Distinguish
  read-only and disabled styling and announce multi-select item values (#312).
  **Behavior change:** select, dropdown and multi-select treat a null selection
  callback as disabled, taking precedence over `readOnly`.

- Add `CarbonSwitch.semanticLabel` for icon-only segments and accessible names
  that differ from visible text. **Breaking assertion:** icon-only segments
  must now supply a semantic label in debug mode. Icons remain decorative
  inside their named buttons (#309).

- Make password visibility keyboard-focusable after the input, with Enter,
  Space, pointer and accessibility activation, a keyboard focus ring, and
  density-sized targets matching Carbon. Disable visibility activation and
  traversal with the field, including pending events (#308).

- Make checkbox, radio, toggle and slider use a shared interaction policy.
  Read-only binary controls remain focusable, expose their value, announce a
  localizable read-only hint and use Carbon's outlined styling. Add explicit
  disabled flags to binary controls and radio groups; null callbacks still
  disable them. Read-only radio groups allow focus navigation without changing
  selection (#310).

- Exclude modal scrims from accessibility traversal and give the modal close
  button a 48×48 target while preserving its icon. Verify modal/dialog focus
  containment and restoration, choose safe initial focus, ignore disposed
  openers, and support Escape from inside a non-modal dialog (#305, #306).

- Give opened date pickers a separate focus scope so pointer activation moves
  focus into the calendar even when another control is focused. Keep the native
  opener focused after Escape or completion in the gallery, and keep popup
  content separate from the single-picker trigger in accessibility navigation
  (#298, #299).

- Continue nested ordered-list markers after `z` as `aa`, `ab`, … using
  CSS lower-latin numbering. Keep wide markers on one line in the gutter,
  preserving content alignment in expressive/scaled text and RTL (#304).

- Add stable data-table row IDs, accessible record labels, ID-based selection
  (`selectedRowIds` / `onSelectedRowIdsChanged`) and expansion (`expandedRowIds`
  / `onExpansionChanged`). Counts ignore absent IDs; retained IDs restore when
  records return, and row state follows sorting and reordering. Add IDs to rows
  and migrate the deprecated index properties/callbacks; they remain functional
  for at least one minor release (#301).

- Reconcile tree focus resources with dynamic data and recover focus from
  removed, hidden or disabled rows. Add controlled expansion while preserving
  local expansion, surviving node identity, selection and scroll position.
  Expose native row focus and skip disabled rows during keyboard navigation
  (#300).

- Reconcile calendar selection and bounds without interrupting unchanged
  keyboard navigation. Clamp civil-day/month movement, disable chevrons at
  bounds, and expose focused-day semantics separately from selection (#299).
- Keep range-picker edits local until a complete range is committed once.
  Escape, outside dismissal, trigger toggles and disabling discard drafts,
  including sessions that began empty. New external values rebase an open
  session. Outside dismissal restores focus when needed and preserves a newly
  focused control, including for the single picker (#298).
- Gate every slider interaction on its current disabled/read-only policy,
  including both handles, the value input, pending events and accessibility
  actions. Disabled sliders cannot receive focus; read-only sliders remain
  focusable for value inspection. Fix native web slider names and values (#297).
- Treat number-input typing as a draft. Enter, Done, blur, and step actions
  commit a finite, clamped value and normalize the displayed text before
  notifying the caller. Share field chrome for warning/invalid precedence,
  preserve fluid sizing, and require a finite positive step (#303).
- Enforce text-area `maxCount` on committed input and paste, using grapheme or
  word counts. Preserve active IME composition until commit and announce the
  limit through field semantics, including when the counter is hidden (#302).
- Rebind form controllers and focus nodes after widget updates, preserving text,
  selection, composing state and focus where applicable. Dispose only internally
  owned resources, including expandable search (#295, #296).
- Preserve editable state and native browser focus when field chrome changes;
  expose enabled and disabled fields correctly to the web input engine.
- Update Carbon references to v11.117.0 and regenerate tokens, icons, pictograms,
  and Storybook references; adapt generators to upstream DTCG sources.
- Make data-table selectors activatable through assistive technology, preserve
  mixed/disabled state, and hide and clip inactive batch actions (#292).
- Add keyboard and assistive-technology activation to progress steps, with
  announced states and keyboard focus highlighting in both layouts (#293).
- Validate tab/panel contracts and safely reconcile selection in both tab
  layouts, including release builds (#294). Tab constructors are no longer
  const because list-length assertions require runtime evaluation.

# 0.4.2

Change repository links to new owner, and adjust analysis options.

## 0.4.1

Widen the declared Dart and Flutter SDK floors so Carbide can be consumed on
toolchains older than the latest stable release. CI still pins the primary
analyze/test job to Flutter 3.44.6 for reproducible goldens; a separate
**Min supported Flutter** job proves the package still analyzes and passes
its behavioral suite at the pubspec floor (goldens skipped).

### Changed

- **Dart SDK floor** — `>=3.12.2` → `>=3.12.0` (Flutter 3.44.0 toolchain).
- **Flutter SDK floor** — `>=3.44.6` → `>=3.44.0`.
- **CI min-sdk guard** — the floor job now installs Flutter 3.44.0 and asserts
  the `pubspec.yaml` `flutter:` constraint stays in sync.
- **Gallery example constraints** — aligned with the library floor so
  `flutter pub get` resolves cleanly on the min-sdk job.

## 0.4.0

License and distribution release. Carbide is now free to use in any project —
open source or proprietary — under the Apache License 2.0.

### Changed

- **Apache License 2.0** — Carbide is now licensed under the Apache License,
  Version 2.0, matching the IBM Carbon Design System. The previous
  AGPL-3.0-or-later dual-licensing model and paid commercial tier are
  removed.
- Updated `LICENSE`, `NOTICE`, `README`, `CONTRIBUTING`, source-file copyright
  headers, and code-generation tooling to reflect the new license.
- Removed `COMMERCIAL.md`.

## 0.3.0

TreeView controllable-API parity plus the component fixes the M11
accessibility, keyboard, and scroll sweeps surfaced — and the web test
platform unblocked. The suite grows from 1,661 to 1,684 package tests;
Carbon remains pinned at v11.111.0.

### Added

- **TreeView multiselect + active/selected split** (#253) — the rest of
  upstream's `enable-treeview-controllable` surface: `multiselect`
  (Ctrl/Cmd-activation toggles membership, Ctrl+Shift+Home/End extends,
  Ctrl/Cmd+A selects all visible enabled nodes), `selectedIds` +
  `onSelectionChanged` for the controlled selection set, and `activeId` +
  `onActivate` — the 4px marker now follows the *active* node and the
  layer-selected background the *selected* set, per `_treeview.scss`.
  The existing `selectedId`/`onSelect` single-select API is unchanged
  and renders pixel-identically.
- **Popup scroll-into-view** (#279) — the list-box family (dropdown,
  combo box, multi select) and the select popup keep the
  keyboard-highlighted option inside the 5.5-row fold, and reveal a
  preselected value below the fold on open, matching native list boxes.

### Fixed

- **Unlabelled companion semantics nodes** (#268): tabs and accordion no
  longer expose a second `[focus, tap]` node beside the labelled button
  node — their suites now pass the full labelled tap-target sweep.
- **Keyboard gaps from the #231 sweep** (#270): `CarbonHeaderName` is
  Tab-reachable and activates with Enter/Space; `CarbonSearch` clears a
  non-empty query on Escape; `CarbonExpandableSearch` collapses on
  Escape when empty, returning focus to the magnifier button;
  `CarbonDatePicker` (and the range picker) gain a focusable field
  trigger — Enter/Space open the calendar with focus moving into the
  grid, Escape and date-pick restore it; `CarbonSelect` opens on ArrowUp.
- **`flutter test --platform chrome` no longer hangs** (#271): the Plex
  font load never completed on the web test platform, wedging every
  suite in the loading phase. Font loading now no-ops on the web
  (behavioral runs only; goldens stay Linux-authoritative), and the
  os-matrix web job is back on PR self-validation.

### Testing & infrastructure

- Seven skip-marked keyboard/scroll locks re-enabled and extended; new
  multiselect state-matrix tests and goldens; suite 1,661 → 1,684 at
  97.6% coverage.
- Suite-wide leak tracking now also covers the web run (the CanvasKit
  golden-capture allocation is allowlisted like its VM counterpart).

## 0.2.2

Testing-depth release (M11): the suite grows from 1,175 to 1,661 package
tests with new repo-wide gates — 90% coverage floor, WCAG contrast and
tap-target checks, text-scaling and reduced-motion sweeps, suite-wide
leak tracking, and a threshold-gated comparison against real Carbon
rendering for 33 components. Carbon remains pinned at v11.111.0.

### Added

- **AI decorator slots on selectable and radio tiles** — `aiLabel` on
  `CarbonSelectableTile` and `CarbonRadioTile`, sharing the checkmark
  corner per the upstream `decorator` prop (completes the AI decorator
  surface across the tile family).
- **Modal entrance motion** — `CarbonModal` gains the upstream
  fade-and-slide entrance (`moderate-02` × entrance-expressive).
- 13 new pattern docs under `docs/patterns/` (common actions, dialog,
  disabled/read-only states, disclosures, empty states, fluid styles,
  filtering, global header, login, overflow content, search, text
  toolbar) and a text-scaling policy doc.

### Fixed

- **Radio tile indicator was invisible**: the tile's `Stack` clipped the
  `CheckmarkFilled` indicator out of existence (the golden had baked the
  bug in).
- **Page-header actions stretched**: a bare `CarbonButton` in
  `pageActions` expanded toward its 320px max width; actions now size to
  their content.
- **Text no longer clips under system text scaling**: every Carbon spec
  height is a minimum — button, tag pill, the text-field family, select
  option rows, data-table rows and batch bar, side-nav rows, and the
  pagination bar grow with the user's text scale
  (see `docs/text-scaling.md`).
- **Reduced motion is honored catalog-wide**: decorative animation
  completes instantly under `MediaQueryData.disableAnimations`; essential
  motion (loading spinner, indeterminate progress) keeps running.
- **Motion fidelity**: dialog entrance curve (was exit-expressive),
  accordion fold easing, data-table row easing and expand-chevron
  duration, header-panel easing, and the side-nav panel transition now
  match their SCSS citations.
- **RTL roving**: tabs, content switcher, and horizontal radio groups
  mirror Left/Right arrows under `Directionality(rtl)`, like slider and
  menu already did.

### Testing & infrastructure

- Coverage collected and gated in CI at a 90% line floor (currently
  97.3%); Flutter pinned across all workflows with a min-supported-SDK
  job; macOS/Windows/web runs on a weekly cadence; publish dry-run
  rehearsal on packaging PRs.
- Golden harness: 1.5× DPR canaries for hairline primitives, per-golden
  strict tolerance, 320px narrow-width goldens, and a `.rtl` golden axis
  for the direction-sensitive set.
- Accessibility gates: WCAG 2.1 token-pair contrast sweep and
  tap-target/label guideline matchers across the catalog; keyboard and
  focus coverage for the 15 previously untested components.
- Suite-wide leak tracking (zero product leaks found) with overlay
  lifetime tests; scroll/drag suites for the data table, modal, code
  snippet, popups, and tree view.
- Upstream fidelity: 33 components compared against captured Carbon
  Storybook references behind per-story drift thresholds, with reference
  version stamping and a staleness guard.

## 0.2.1

Hotfix release.

### Fixed

- Labeled checkboxes no longer expand to fill bounded rows: multi-select
  menu options rendered with the checkbox pinned to the top of the row
  (most visibly on the 64px fluid rows) instead of vertically centred.

## 0.2.0

Component-parity release (M10): the composable Dialog, the AI chat surface,
AI decorator slots and fluid variants across the form components, and
right-to-left (bidi) support across the library.

### New components

- **Dialog** — the composable dialog family (`CarbonDialog` with header,
  controls, close button, title, subtitle, scrollable body, and footer
  slots): modal and non-modal, focus trap and restore, Escape to dismiss,
  width tiers, and entrance motion.
- **Chat button** — the AI chat pill button (`CarbonChatButton`) in four
  kinds and three sizes, plus the outlined quick-action mode with a
  selected state; adds the six `chatButton*` theme tokens.
- **AI skeletons** — `CarbonAISkeletonText`, `CarbonAISkeletonIcon`, and
  `CarbonAISkeletonPlaceholder` with the AI shimmer sweep.
- **Callout** — the contextual callout notification, plus the
  `info-square` and `warning-alt` notification kinds.
- **Vertical tabs** — `CarbonTabsVertical`, the always-contained vertical
  tab list.

### New component features

- **AI decorator slots** — `aiLabel` / `aiRevert` and the AI field
  gradient across text inputs, text area, number input, search, select,
  dropdown, combo box, multi-select, date and time pickers, checkbox and
  radio groups, form groups, tiles, data table, and the modal (AI scrim,
  aura, and drop shadow).
- **Fluid variants** — the contained field style for dropdown, combo box,
  multi-select, time picker, and the date pickers, with `CarbonFluidForm`
  applying it to a whole subtree; fluid skeletons included.
- **Date picker** — range selection mode (`CarbonDateRangePicker`).
- **Modal** — the full-width variant.
- **Button** — expressive mode and link-style semantics.
- **Side nav** — rail mode expands on hover or focus as an overlay.

### Right-to-left support

Every component now renders correctly under `Directionality(rtl)`:
mirrored slider and progress geometry, logical side accents and dividers,
direction-aware submenus, arrow keys, and pagination carets, and a logical
popover caret. `CarbonText` and `CarbonHeading` gain a `textDirection`
override. RTL smoke goldens and a crash-guard sweep back it in CI.

### Fixed

- The determinate progress-bar fill (including the finished and error
  states) never painted; it now fills from the start edge.

### Docs

- Usage-pattern guides under `docs/patterns/`: forms, loading,
  notifications, and status indicators.
- ADR 0002 records the Carbon v12 feature-flag posture; component headers
  name the flagged behaviors Carbide deliberately tracks.
- The gallery gains Fluid typography (live viewport-width slider) and
  Pictograms foundations pages, plus pages for every new component.

Every component ships with spec-lock, state-matrix, semantics, and
four-theme golden tests.

## 0.1.0

Component parity release — closes the remaining gaps against IBM's official
component list, and adds the 2x Grid and the indicator family.

### New components

- **Copy** & **Copy button** — copy-to-clipboard buttons with a transient
  feedback bubble.
- **AI Label** — the AI explainability marker (sizes, inline, and revert
  modes) with an AI-tinted callout; adds the six `ai-*` theme token group.
- **Code snippet** — inline, single-line, and multi-line (show more / show
  less) variants, plus a skeleton.
- **Contained list** — a titled list whose items can carry a leading icon, a
  trailing action, and an `onPressed` that makes the row a layer-contextual
  clickable button.
- **Icon button** — an icon-only button that shows its label in a tooltip.
- **Context menu** — a right-click / long-press menu positioned at the pointer
  and clamped to the viewport.
- **Pagination nav** — page-number navigation with overflow truncation.
- **Aspect ratio** — Carbon's nine fixed ratios.
- **2x Grid** — a responsive 16-column (8 at md, 4 at sm) layout
  (`CarbonGrid` + `CarbonColumn`) with per-breakpoint spans and offsets.
- **Indicators** — badge, icon, and color-blind-safe shape status indicators.
- **Component skeletons** — loading placeholders for the form, selection, and
  structural components.

### Other

- `CarbonPopover` gains `surfaceColor` / `surfaceBorderColor` overrides for
  themed callouts (used by AI Label).
- The example gallery showcases every new component.

Every component ships with spec-lock, state-matrix, semantics, and four-theme
golden tests.

## 0.0.2

Maintenance release — no API or component changes.

- Refresh the gallery screenshots in the README, regenerated from the current
  build (the previous images were from an earlier, broken render).
- Packaging & tooling: trim the published archive with `.pubignore` and scope
  the `.gitignore` lock/editor rules so they no longer reach into the
  `documentation/` submodules, giving a clean `dart pub publish` run.
- Automated pub.dev publishing on `vX.Y.Z` tags via OIDC trusted publishing.

## 0.0.1

Initial public release of **Carbide** — an unofficial Flutter port of the IBM
Carbon Design System, built strictly on Flutter's base widgets (no Material, no
Cupertino).

### Foundations

- Color tokens and the four Carbon themes (White, Gray 10, Gray 90, Gray 100),
  with `CarbonTheme`, `AnimatedCarbonTheme`, and the `CarbonLayer` contextual
  layering model.
- Typography (bundled IBM Plex Sans, Mono, and Serif), spacing/layout tokens,
  motion tokens, and the Carbon icon and pictogram sets.

### Components

- **Foundational:** Button, Tag, Link, Tile, Loading, Progress bar, List,
  Stack, Heading.
- **Forms:** Text input, Text area, Number input, Select, Search, Checkbox,
  Radio button, Toggle, Slider.
- **Composite:** Dropdown, Combo box, Multi-select, Tooltip, Toggletip,
  Overflow menu, Tabs, Accordion, Content switcher, Breadcrumb, Pagination,
  Modal, Notification, Progress indicator, Structured list.
- **Complex & data:** Data table, Date picker, Time picker, File uploader,
  Tree view, Page header, and the UI Shell (header, side nav, switcher).

Every component ships with state-matrix widget tests, golden tests against the
Carbon spec, and semantics/accessibility tests, and is documented on its public
API.

Supports Android, iOS, web, Windows, macOS, and Linux.
