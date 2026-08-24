# Changelog

# 0.4.2

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
