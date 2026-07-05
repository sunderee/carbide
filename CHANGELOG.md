# Changelog

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
  modes) with an AI-tinted callout; adds the `ai-*` theme token group.
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
