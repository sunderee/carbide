# Carbide codebase review

Audit date: 2026-08-16

Scope: the root `carbide` package, the `example/` gallery, tests, goldens,
fidelity tooling, generators, documentation, CI, release workflows, and the
checked-in Carbon reference submodules.

This is a prioritized implementation backlog, not a release note. Each finding
is intentionally scoped so another agent can take one item, implement it, add
the listed tests, and stop.

## Executive assessment

Carbide is in unusually good shape for a widgets-only design-system port:

- The package stays free of Material and Cupertino dependencies.
- The analyzer, package tests, gallery tests, API documentation, icon locks,
  and 90% coverage gate pass.
- The audited package run reported 1,684 passing tests, one intentional skip,
  and 97.6% line coverage.
- Colors, fixed and fluid type tokens, motion, the four standard themes,
  layers, icons, and pictograms have strong generated or spec-locked coverage.
- Keyboard, RTL, reduced-motion, text-scaling, leak, DPR, responsive, contrast,
  and golden infrastructure are substantially better than typical Flutter
  component libraries.

The remaining work is not cosmetic. The highest-risk defects are concentrated
in assistive-technology activation, mutable widget lifecycle handling,
controlled-state reconciliation, dynamic data identity, and a fidelity harness
whose public claims are stronger than its actual coverage. There are also
several documented Carbon features that are still placeholders.

No security vulnerability or data-loss path was identified. `P0` below means a
core interaction is inaccessible or a public widget can crash under a simple
invalid-but-plausible configuration.

## How to execute this backlog

1. Work in the order shown in the roadmap.
2. Implement one finding per PR unless a finding explicitly names a shared
   refactor.
3. Preserve the "no Material / no Cupertino" constraint.
4. Cite the upstream Carbon source or accessibility guidance in the PR.
5. Add the acceptance tests listed in the finding.
6. Run the root and gallery checks documented in `CONTRIBUTING.md`.
7. Do not regenerate Linux-authoritative text goldens outside the documented
   workflow.
8. If investigation disproves a `VERIFY` item, update this file with the
   evidence rather than implementing speculative code.

## Status and priority vocabulary

- `CONFIRMED`: directly established from code, an existing TODO/skip, or a
  focused runtime probe.
- `DOCUMENTED GAP`: the implementation itself says the Carbon behavior is not
  ported.
- `COVERAGE GAP`: behavior may be correct, but the repository's stated quality
  policy does not prove it.
- `VERIFY`: evidence is conflicting or framework defaults may already provide
  the behavior. Add a focused test before changing production code.
- `P0`: inaccessible core action or reproducible runtime crash.
- `P1`: significant correctness, accessibility, state, or fidelity defect.
- `P2`: important API, performance, responsive, platform, or assurance gap.
- `P3`: documentation, polish, low-frequency edge case, or strategic
  completeness work.

## Roadmap

### Phase 1 — unblock core interactions

1. `CARBIDE-001` Data-table selectors must expose semantic activation.
2. `CARBIDE-002` Interactive progress steps must support semantics and keyboard
   activation.
3. `CARBIDE-003` Tabs must validate tab/panel/index contracts.

### Phase 2 — repair state and lifecycle correctness

4. `CARBIDE-004` Migrate controller and focus listeners on widget updates.
5. `CARBIDE-005` Fix `CarbonExpandableSearch` controller ownership.
6. `CARBIDE-006` Make `CarbonSlider.disabled` actually disable interaction.
7. `CARBIDE-007` Make date-range cancellation transactional.
8. `CARBIDE-008` Reconcile calendar state with controlled values.
9. `CARBIDE-009` Prune dynamic tree focus nodes and control expansion.
10. `CARBIDE-010` Move data-table state from indices to stable row identity.

### Phase 3 — close accessibility blockers

11. `CARBIDE-011` Repair modal dismiss semantics and close target size.
12. `CARBIDE-012` Verify and lock modal/dialog focus containment.
13. `CARBIDE-013` Complete data-table sort and structure semantics.
14. `CARBIDE-014` Make password visibility keyboard operable.
15. `CARBIDE-015` Require accessible labels for icon-only switch segments.
16. `CARBIDE-016` Align read-only binary-control semantics.
17. `CARBIDE-017` Expose picker/list-box active-option state to assistive tech.

### Phase 4 — Carbon behavior and fidelity

18. `CARBIDE-018` Localize date-picker formatting and calendar labels.
19. `CARBIDE-019` Implement breadcrumb overflow collapse.
20. `CARBIDE-020` Implement horizontal tabs overflow behavior.
21. `CARBIDE-021` Implement the Carbon narrow-grid hang.
22. `CARBIDE-022` Use theme-aware menu and list-box shadows.
23. `CARBIDE-023` Correct modal and tooltip fidelity fixtures.
24. `CARBIDE-024` Ratchet weak fidelity thresholds.

### Phase 5 — scaling, overlays, and performance

25. `CARBIDE-025` Replace fixed field heights with minimum heights.
26. `CARBIDE-026` Add viewport collision handling to anchored menus.
27. `CARBIDE-027` Add scalable data-table and tree rendering modes.
28. `CARBIDE-028` Virtualize large list-box menus.
29. `CARBIDE-029` Make pagination bounded and responsive.
30. `CARBIDE-030` Add modal background scroll locking and exit motion.

### Phase 6 — assurance, docs, gallery, and release

31. `CARBIDE-031` Expand cross-cutting specimens.
32. `CARBIDE-032` Enforce the accessibility test policy consistently.
33. `CARBIDE-033` Complete overlay lifetime coverage.
34. `CARBIDE-034` Make fidelity freshness executable in CI.
35. `CARBIDE-035` Align publish verification with PR CI.
36. `CARBIDE-036` Strengthen web, gallery, and minimum-SDK CI.
37. `CARBIDE-037` Correct README fidelity and gallery claims.
38. `CARBIDE-038` Make gallery code examples actually copyable and testable.
39. `CARBIDE-039` Add missing gallery demonstrations.
40. `CARBIDE-040` Repair stale architecture and ADR documentation.

The remaining P2/P3 findings can proceed after the relevant foundation above.

---

## P0 findings

### CARBIDE-001 — Data-table selection is not activatable by assistive technology

Status: `CONFIRMED`

Evidence:

- `lib/src/components/data_table/carbon_data_table.dart`
- `_RowSelector`
- the select-all block in `CarbonDataTable.build`
- `test/components/data_table/carbon_data_table_test.dart`

Actual:

The outer semantics nodes expose labels and checked state, but do not expose an
`onTap` action. The real checkbox/radio descendants are wrapped in
`ExcludeSemantics`. Screen readers and switch-control users can perceive row
selection but cannot activate it.

Expected:

Each row selector and the select-all selector expose one named, stateful,
activatable semantics node. Activation must call the same controlled callback
as pointer input.

Suggested fix:

- Add `Semantics.onTap` to the outer node, or replace the exclusion pattern with
  a correctly merged child semantics node.
- Keep a single semantics node per selector.
- Preserve `checked`, mixed/select-all state, enabled state, and row labels.

Acceptance:

- A semantics action toggles a row in single- and multi-select modes.
- A semantics action toggles select-all.
- `expectA11y(tester)` runs without suppressing label or action checks.
- Pointer and keyboard behavior remain unchanged.

### CARBIDE-002 — Interactive progress steps are pointer-only

Status: `CONFIRMED`

Evidence:

- `lib/src/components/progress_indicator/carbon_progress_indicator.dart`
- `_StepWidgetState.build`
- `test/components/progress_indicator/carbon_progress_indicator_test.dart`

Actual:

Interactive steps are labeled as buttons, but the outer `Semantics` node has no
tap action. The `GestureDetector` is inside `ExcludeSemantics`, and the step has
no Enter/Space activation path.

Expected:

An interactive step is a real button for pointer, keyboard, and accessibility
APIs.

Suggested fix:

- Move activation into `CarbonInteraction`, or add both `Semantics.onTap` and
  Enter/Space handling to the existing focusable step.
- Expose current, complete, disabled, and selected state without duplicate
  nodes.

Acceptance:

- `SemanticsAction.tap`, Enter, and Space each invoke `onStepSelected` once.
- Disabled steps expose no activation action.
- Focus indication remains keyboard-only.
- The accessibility guideline test no longer passes only because no tap action
  is measurable.

### CARBIDE-003 — Tabs can throw on mismatched panels or stale indices

Status: `CONFIRMED`

Evidence:

- `lib/src/components/tabs/carbon_tabs.dart`
- `_CarbonTabsState.build`
- `_CarbonTabsVerticalState.build`

Actual:

Both variants index `panels[_current]` without requiring
`panels.length == tabs.length` or proving `_current` is in range. A focused
runtime probe with two tabs and one panel produced a `RangeError`.

Expected:

Invalid public configuration fails immediately with a useful assertion in
debug mode and never indexes out of range in production.

Suggested fix:

- Assert equal tab/panel lengths.
- Assert non-empty tabs and a valid controlled `selectedIndex`.
- Reconcile internal selection when tabs are removed.
- Decide and document release behavior: clamp, render no panel, or throw a
  deliberate `ArgumentError` before build.

Acceptance:

- Horizontal and vertical variants have constructor/state-update tests.
- Removing the selected tab cannot cause a `RangeError`.
- Controlled and uncontrolled selection remain synchronized.

---

## P1 findings — lifecycle and correctness

### CARBIDE-004 — Controller and focus listeners do not migrate on widget update

Status: `CONFIRMED`

Affected:

- `CarbonTextInput` and `CarbonPasswordInput`
- `CarbonTextArea`
- `CarbonSearch`
- `CarbonTimePicker`
- focus-node handling in `CarbonNumberInput`, `CarbonSelect`,
  `CarbonDropdown`, `CarbonComboBox`, and `CarbonMultiSelect`

Evidence:

These states resolve the current external-or-internal object in getters, attach
listeners in `initState`, and remove listeners from the object returned at
`dispose`. They do not detach and reattach when the widget supplies a different
controller or focus node.

Actual:

- The old object retains the listener.
- The newly supplied object does not trigger chrome rebuilds.
- `dispose` may remove a listener from the new object while leaving the old
  listener attached.
- Null-to-external and external-to-null transitions can orphan internally owned
  resources.

Expected:

Object identity changes are handled in `didUpdateWidget`; the widget disposes
only resources it created.

Suggested fix:

Create one shared internal ownership pattern and apply it consistently:

- Resolve the old effective object before changing ownership.
- Detach listeners from the old object.
- Dispose an old internal object when it is no longer effective.
- Create an internal object when transitioning from external to null.
- Attach listeners to the new effective object.
- Preserve selection/text and focus when safe.

Acceptance:

- Tests cover internal→external, external→internal, external A→B, and disposal.
- Programmatic edits on the new controller update placeholder/status chrome.
- Focusing the new focus node updates focus rings.
- Editing/focusing the old object after the swap has no effect.
- The global leak tracker passes.

### CARBIDE-005 — `CarbonExpandableSearch` freezes controller ownership at mount

Status: `CONFIRMED`

Evidence:

- `lib/src/components/search/carbon_search.dart`
- `_CarbonExpandableSearchState._controller`

Actual:

A `late final` controller captures `widget.controller` once. Supplying or
replacing an external controller later is ignored. Disposal ownership is
determined using the current widget property, not necessarily the object
originally created.

Expected:

The controller contract matches `CarbonSearch` and remains safe across widget
updates.

Suggested fix:

Use the shared ownership/rebinding implementation from `CARBIDE-004`.

Acceptance:

- A controller can be supplied, removed, or replaced after mount.
- The internal controller is disposed exactly once.
- External controllers are never disposed by Carbide.
- Expanded/collapsed state and focus return still work.

### CARBIDE-006 — `CarbonSlider.disabled` does not disable interaction

Status: `CONFIRMED`

Evidence:

- `lib/src/components/slider/carbon_slider.dart`
- `_enabled`

Actual:

`_enabled` checks only `onChanged != null` and `!readOnly`. With
`disabled: true` and a non-null callback, track taps and thumb keys can still
change the value while disabled colors are displayed.

Expected:

Disabled sliders are inert for pointer, keyboard, value input, and semantics.

Suggested fix:

Include `!widget.disabled` in the shared interaction gate and ensure every
entry point uses that gate.

Acceptance:

- Track tap, drag, arrows, Home/End, and optional value input do nothing when
  disabled.
- Read-only remains focusable or non-focusable according to the documented
  policy, but never mutates.
- Semantics enabled state matches behavior.

### CARBIDE-007 — Date-range editing is not transactional

Status: `CONFIRMED`

Evidence:

- `lib/src/components/date_picker/carbon_date_picker.dart`
- `_CarbonDateRangePickerState._cancel`
- `onRequestClose` in range picker build

Actual:

- Escape cannot restore an initially null range because `_cancel` only reverts
  when `_beforeOpen != null`.
- Tapping outside closes the popover without calling `_cancel`.
- A partially selected start date can remain committed after cancellation.

Expected:

Opening snapshots the committed range. Escape and outside dismissal restore
that snapshot, including null. Completing a valid range commits it.

Suggested fix:

- Model the open session explicitly: snapshot, draft, commit, cancel.
- Route every non-commit dismissal through one cancel path.
- Do not use null as both "no snapshot" and "snapshot was null".

Acceptance:

- Tests cover null, complete, and partial initial ranges.
- Escape and outside tap restore the exact pre-open value.
- Selection completion commits once and returns focus to the opener.

### CARBIDE-008 — Calendar navigation state is stale and can leave valid bounds

Status: `CONFIRMED` for missing reconciliation; bounds behavior needs a focused
test.

Evidence:

- `lib/src/components/date_picker/carbon_date_picker.dart`
- `_CarbonCalendarState.initState`
- `_moveFocus`
- no `didUpdateWidget` in `CarbonCalendar`

Actual:

`_month` and `_focusedDay` are initialized once. Parent-driven `value`, range,
`firstDate`, or `lastDate` changes can leave the visible month and focus anchor
stale. Arrow movement is not visibly clamped in `_moveFocus`.

Expected:

Controlled values re-anchor the calendar, and keyboard focus never lands
outside the selectable range.

Suggested fix:

- Add `didUpdateWidget` reconciliation for value/range and bounds.
- Clamp day and month navigation to `firstDate`/`lastDate`.
- Specify how disabled dates are skipped.

Acceptance:

- Changing a controlled value to another month updates the visible month.
- Shrinking bounds moves focus to the nearest valid day.
- Month arrows disable at limits.
- Focus and selected-day semantics remain distinct.

### CARBIDE-009 — Dynamic tree state leaks focus nodes and cannot be controlled

Status: `CONFIRMED`

Evidence:

- `lib/src/components/tree_view/carbon_tree_view.dart`
- `_focusNodes`
- `_expanded`

Actual:

Focus nodes are added with `putIfAbsent` and disposed only when the entire tree
is disposed. Removed IDs remain in the map. Expansion is seeded from
`initiallyExpandedIds` but cannot be driven by a parent afterward.

Expected:

Focus-node lifetime follows node identity, and expansion can be controlled for
filtering, routing, persistence, and async trees.

Suggested fix:

- Reconcile the full ID set in `didUpdateWidget`; dispose removed nodes.
- If a focused node disappears, move focus to a valid ancestor or neighbor.
- Add optional `expandedIds` and `onExpansionChanged` while preserving an
  uncontrolled mode.

Acceptance:

- Repeatedly replacing a tree does not grow retained focus nodes.
- Controlled expansion updates without remounting.
- Removing a focused node leaves a valid primary focus.

### CARBIDE-010 — Data-table selection and expansion use unstable row indices

Status: `CONFIRMED`

Evidence:

- `lib/src/components/data_table/carbon_data_table.dart`
- `selectedRows`
- `expandedRows`

Actual:

Selection and expansion are keyed by row positions. Sorting, filtering,
pagination, insertion, or deletion can move state to the wrong record.
`selectedRows.length == rows.length` also treats invalid indices as evidence
that all rows are selected.

Expected:

State follows stable row identity.

Suggested fix:

- Add a required or optional stable ID/key to `CarbonTableRow`.
- Add ID-keyed controlled selection and expansion APIs.
- Deprecate index-keyed APIs with a migration path.
- Compute all-selected from valid current IDs.

Acceptance:

- Selection follows rows through reorder/filter operations.
- Removed rows are ignored or pruned.
- Duplicate IDs fail with a clear assertion.
- Existing index users have documented compatibility behavior.

---

## P1 findings — accessibility and interaction

### CARBIDE-011 — Modal dismiss affordances fail the package's own a11y policy

Status: `CONFIRMED`

Evidence:

- `lib/src/components/modal/carbon_modal.dart`
- scrim `GestureDetector`
- modal close button
- `test/components/modal/carbon_modal_test.dart`

Actual:

- The dismissible full-screen scrim has no accessible label or explicit
  exclusion.
- The close button is 40×40 while the Carbon modal close affordance is 48×48.
- Tests suppress the affected guideline path.

Expected:

The scrim is either a named dismiss control or intentionally absent from
semantics, and the close affordance has a 48×48 interactive area.

Suggested fix:

- Choose one scrim policy and document it.
- If exposed, add a localizable dismiss label and `Semantics.onTap`.
- If hidden, preserve close button and Escape as complete alternatives.
- Expand the close hit target without changing icon artwork size.

Acceptance:

- The default modal passes the label and tap-target guidelines.
- Close, Escape, and optional outside dismissal invoke `onClose` once.
- Traversal contains no silent full-screen action.

### CARBIDE-012 — Modal/dialog focus containment is claimed but not proven

Status: `VERIFY`

Evidence:

- `CarbonModal` and modal `CarbonDialog` use `FocusScope(autofocus: true)`.
- Source documentation says focus is trapped.
- No test proves repeated Tab and Shift+Tab cannot reach a focusable behind the
  overlay.
- Focus restoration code exists.
- One focused probe did not reproduce escape, so framework defaults may already
  provide a closed loop.

Expected:

Focus is contained while modal, initial focus follows a documented policy, and
focus returns to the opener after every close path.

Required investigation:

- Add focused tests before changing production code.
- Include first/last controls, an outside control, Tab, Shift+Tab, Escape,
  outside dismissal, and opener disposal.
- Test `CarbonModal`, modal `CarbonDialog`, and non-modal `CarbonDialog`
  separately.

Possible fix if tests fail:

Use an explicit closed-loop traversal policy and block background focus while
open. Guard focus restoration with `canRequestFocus`.

Acceptance:

- The behavior is proven by tests even if no production change is necessary.
- Initial-focus policy is documented for passive, confirmation, and destructive
  dialogs.

### CARBIDE-013 — Data-table sort and structure semantics are incomplete

Status: `CONFIRMED`

Evidence:

- `lib/src/components/data_table/carbon_data_table.dart`
- `_HeaderCell`
- `test/components/data_table/carbon_data_table_sort_test.dart`

Actual:

- Sort activation shrink-wraps the label instead of filling the header row.
- Ascending/descending/none is not announced.
- The `Row`/`Column` implementation has only generic container semantics; table,
  header, row, and cell relationships are weak.

Expected:

The full header cell is an activatable target, the active sort direction is
announced, and assistive technology receives a useful table structure and
name.

Suggested fix:

- Stretch the sort target across the cell height and width.
- Add a localized semantics value/hint for sort direction.
- Add an optional table label.
- Evaluate Flutter `Table` semantics or semantic tags before inventing custom
  platform roles.

Acceptance:

- Sort direction changes are observable in semantics.
- Header tap bounds meet the configured accessibility target.
- Reading order announces title/description, headers, then row values.

### CARBIDE-014 — Password visibility toggle is not keyboard operable

Status: `CONFIRMED`

Evidence:

- `lib/src/components/text_input/carbon_text_input.dart`
- `_CarbonPasswordInputState`

Actual:

The visibility toggle uses `GestureDetector` inside button semantics but is not
a keyboard focus target and has no Enter/Space activation.

Expected:

The trailing visibility control is a named button reachable in traversal order.

Suggested fix:

Use `CarbonInteraction` and preserve show/hide labels.

Acceptance:

- Tab reaches the toggle after the input.
- Enter, Space, semantics tap, and pointer tap each toggle once.
- Disabled input disables the toggle.
- The accessible label changes between show and hide.

### CARBIDE-015 — Icon-only content-switcher segments can be unnamed

Status: `CONFIRMED`

Evidence:

- `lib/src/components/content_switcher/carbon_content_switcher.dart`
- `CarbonSwitch`
- `_SwitchSegmentState`

Actual:

An icon-only segment uses `text` as its semantic label. `text` may be null, so
the button is unnamed.

Expected:

Every switcher segment has a required accessible name.

Suggested fix:

Add `semanticLabel` and assert that either visible text or a semantic label is
present.

Acceptance:

- Icon-only segments cannot be constructed without a name in debug mode.
- The visible icon remains decorative inside the named button.
- A semantics test covers selected, disabled, and icon-only states.

### CARBIDE-016 — Read-only checkbox/radio/toggle semantics contradict behavior

Status: `CONFIRMED`

Evidence:

- `lib/src/components/checkbox/carbon_checkbox.dart`
- `lib/src/components/radio_button/carbon_radio_button.dart`
- `lib/src/components/toggle/carbon_toggle.dart`

Actual:

With a non-null callback and `readOnly: true`, interaction is blocked but
semantics can still report enabled. Styling also uses the callback-null state
instead of one consistent interaction state in some controls.

Expected:

Read-only controls are perceivable and non-editable, with consistent visual and
semantic treatment.

Suggested fix:

Define one `interactive`, `disabled`, and `readOnly` state model for all binary
controls. Do not conflate null callback and read-only in implementation.

Acceptance:

- Read-only variants cannot mutate via pointer, keyboard, or semantics.
- Semantics communicate non-editability consistently.
- Disabled and read-only visuals remain distinct if Carbon specifies distinct
  states.

### CARBIDE-017 — List-box active-option state is not consistently announced

Status: `CONFIRMED` for combo-box row semantics; active-descendant behavior
needs a design decision.

Evidence:

- `CarbonDropdown`, `CarbonSelect`, `CarbonComboBox`, `CarbonMultiSelect`
- combo-box `_menuRow`
- trigger semantics expose committed value, not necessarily highlighted option

Actual:

Keyboard highlight is visual. Combo-box rows do not mirror the option semantics
used by dropdown rows. Assistive technology may not hear the option under the
roving highlight before selection.

Expected:

Open/closed state, active option, selected option, and disabled options are
distinguishable.

Suggested fix:

- Standardize option semantics in the shared list-box layer.
- Expose `expanded` on triggers.
- Update active value/hint when the keyboard highlight moves, without
  pretending it is committed selection.

Acceptance:

- Semantics tests cover open state and ArrowUp/ArrowDown movement before Enter.
- Each option appears once in the semantic tree.
- Combo, dropdown, select, and multi-select use the same policy.

---

## P1/P2 findings — Carbon fidelity and component behavior

### CARBIDE-018 — Date picker is fixed to English, US format, and Sunday-first

Status: `CONFIRMED`

Evidence:

- `_months`
- `_weekdays`
- `_format`
- fixed placeholders in `carbon_date_picker.dart`

Actual:

Month/weekday names and `mm/dd/yyyy` formatting are hardcoded. Week start is not
locale-aware. Calendar navigation chevrons and horizontal day movement do not
have a documented RTL/locale policy.

Expected:

Consumers can provide locale-aware formatting, labels, first day of week, and
parse/format behavior without importing Material.

Suggested fix:

- Prefer injectable formatter/parser and calendar-label delegates to avoid a
  mandatory Material dependency.
- If adding `intl`, justify the dependency and use the latest compatible
  version.
- Add a first-day-of-week setting.
- Define whether arrow keys are logical or physical under RTL and test it.

Acceptance:

- Tests cover at least `en-US`, `de-DE`, `ja-JP`, and an RTL locale.
- Long localized dates do not clip the range fields.
- All calendar navigation labels are localizable.

### CARBIDE-019 — Breadcrumb overflow collapse is missing

Status: `DOCUMENTED GAP`

Evidence:

- `lib/src/components/breadcrumb/carbon_breadcrumb.dart`
- skipped test in
  `test/components/breadcrumb/carbon_breadcrumb_test.dart`

Actual:

Long trails wrap; there is no ellipsis trigger or overflow menu. A keyboard
test is permanently skipped.

Expected:

Middle crumbs collapse into an accessible overflow menu at constrained widths.

Suggested fix:

Port the Carbon overflow algorithm using `CarbonOverflowMenu`, preserve the
first/current crumbs, and expose current-page semantics.

Acceptance:

- Remove the skip.
- Add narrow LTR/RTL goldens.
- Keyboard traversal reaches the overflow trigger and hidden crumbs.
- Current page is announced as current/selected, not a link.

### CARBIDE-020 — Horizontal tabs have no overflow controls

Status: `DOCUMENTED GAP`

Evidence:

- header comment in `lib/src/components/tabs/carbon_tabs.dart`
- horizontal tab strip is a plain `Row`

Actual:

Tabs clip/overflow on narrow widths. The vertical variant has scrolling
infrastructure, but the horizontal variant does not.

Expected:

Overflowing tabs scroll, keep the selected/focused tab visible, and expose
Carbon-style controls or fades.

Suggested fix:

Reuse the vertical scroll state where possible. Add horizontal start/end
controls and RTL-aware behavior.

Acceptance:

- 320px golden and keyboard test with many tabs.
- Home/End and arrows scroll the active tab into view.
- Buttons disable correctly at scroll extents.

### CARBIDE-021 — `CarbonGridMode.narrow` behaves like wide mode

Status: `CONFIRMED`

Evidence:

- `lib/src/components/grid/carbon_grid.dart`
- `CarbonGridMode.narrow`
- upstream `@carbon/grid` column-hang variables

Actual:

Narrow and wide share the same gutter behavior. The documented first/last
column hang is absent.

Expected:

Narrow mode applies the Carbon half-gutter hang at grid edges.

Suggested fix:

Implement and spec-lock the hang. Keep the larger `Wrap`-versus-CSS-grid
limitation documented separately.

Acceptance:

- Geometry tests for wide, narrow, condensed, and full-width modes.
- Nested/multi-row tests prove offsets remain stable.
- LTR and RTL edge behavior is explicit.

### CARBIDE-022 — Floating menu shadows ignore the theme shadow token

Status: `CONFIRMED`

Evidence:

- hardcoded `_menuShadow` in `carbon_menu.dart`
- hardcoded list-box shadow in `carbon_list_box.dart`
- `CarbonThemeData.shadow`
- upstream `box-shadow` mixin uses `$shadow`

Actual:

Menus and list-boxes use approximately 30% black in every theme. Dark Carbon
themes define a stronger shadow.

Expected:

These surfaces use `CarbonTheme.of(context).shadow`.

Suggested fix:

Resolve the shadow in build context. Do not change popover/notification shadows
that intentionally use fixed upstream values.

Acceptance:

- Widget tests assert shadow color in all four themes.
- Dark-theme goldens show the expected elevation without changing geometry.

### CARBIDE-023 — Fidelity fixtures compare the wrong widgets/stories

Status: `CONFIRMED`

Evidence:

- `test/fidelity/fidelity_test.dart`
- modal builder renders `CarbonDialog` against a Modal story
- tooltip builder renders a definition-style text trigger against the default
  Tooltip story

Actual:

The threshold measures fixture mismatch as if it were implementation drift.

Expected:

Each builder reproduces the same component, variant, content, dimensions, and
state as the captured Storybook story.

Suggested fix:

- Use `CarbonModal` for the Modal story.
- Use the default icon-trigger tooltip for the Tooltip story.
- Add a future `CarbonDefinitionTooltip` and separate story rather than mixing
  the patterns.
- Recapture references only when the story itself changes.

Acceptance:

- Side-by-side artifacts show equivalent anatomy.
- Thresholds can be lowered materially after fixture alignment.

### CARBIDE-024 — Fidelity thresholds are too permissive and uneven

Status: `CONFIRMED`

Evidence:

- `tool/fidelity/stories.json`
- button threshold `0.64`
- modal and notification thresholds `0.44`

Actual:

The coarse 24×24 luminance-grid score can accept very large drift. One default
story per component also leaves variants unguarded.

Expected:

The test remains a drift detector, not a false pixel-perfect claim, but obvious
layout and token regressions fail.

Suggested fix:

- First fix fixture mismatches.
- Record measured baseline scores.
- Set each threshold to baseline plus a small documented margin.
- Add structural assertions for dimensions, key token colors, and state where
  image comparison is inherently noisy.

Acceptance:

- A deliberate major visual regression fails every promoted component.
- Threshold rationale is documented beside each entry.
- README accurately describes this as a coarse drift gate.

### CARBIDE-025 — Fixed-height field chrome conflicts with text-scaling policy

Status: `CONFIRMED`

Affected examples:

- fluid text input and search
- list-box trigger
- combo-box and multi-select filter field
- number input
- time picker and some UI-shell/menu rows

Actual:

Several widgets use fixed `height`/`SizedBox` where `docs/text-scaling.md`
requires Carbon heights to be minimums.

Expected:

Chrome grows with scaled text and remains usable at 1.3× and 2.0×.

Suggested fix:

Replace fixed field heights with `ConstrainedBox(minHeight: ...)` and let
content determine final height. Preserve fixed icon artwork sizes.

Acceptance:

- Add missing specimens before refactoring.
- Open and closed states pass at 1.3× and 2.0× without overflow or clipped
  line boxes.
- Goldens change only where growth is expected.

### CARBIDE-026 — Anchored list-box/menu overlays lack automatic collision handling

Status: `CONFIRMED`

Evidence:

- dropdown has a manual top/bottom direction
- combo box, multi-select, select, and anchored menus use fixed anchors
- `CarbonPopover.autoAlign` already contains partial flip logic

Actual:

Popups near viewport edges can extend off-screen unless the caller manually
chooses a direction, and not every component exposes that choice.

Expected:

Popups remain inside the viewport and use logical start/end alignment in RTL.

Suggested fix:

Extract a shared placement policy from `CarbonPopover`, including vertical
flip, horizontal clamp, scroll/resize updates, and a caller override.

Acceptance:

- Geometry tests place each popup at all four viewport corners.
- Resize and ancestor scroll recompute placement.
- RTL start/end tests pass.

### CARBIDE-027 — Data table and tree view have no scalable rendering mode

Status: `CONFIRMED`

Evidence:

- data table builds every row in a `Column`
- tree view flattens and builds every visible node

Actual:

Build/layout/memory scale linearly with all rows/nodes. Sticky scrolling does
not change mounting behavior.

Expected:

Either the API documents a moderate-data ceiling and pagination requirement, or
offers lazy/sliver rendering for large data.

Suggested fix:

- Benchmark first.
- Add optional builder/sliver modes with stable row identity.
- Preserve sticky headers, expanded rows, keyboard focus, and semantics.

Acceptance:

- Benchmarks cover 100, 1,000, and 10,000 records.
- A 1,000-row scroll does not mount every row in virtualized mode.
- Existing eager mode remains available if needed for intrinsic layouts.

### CARBIDE-028 — List-box menus eagerly build every option

Status: `CONFIRMED`

Evidence:

- `test/scroll/popup_scroll_test.dart` intentionally locks 1,000 mounted rows

Actual:

Opening large dropdowns/comboboxes creates every option widget.

Expected:

Large data sources can use lazy option construction without breaking keyboard
scroll-into-view.

Suggested fix:

Add a builder-based API and virtualized menu body. Keep the current item-list
API for small collections.

Acceptance:

- A 1,000-item test proves bounded mounted children.
- Typeahead, disabled-item skipping, and highlighted-option scrolling work.
- Semantics expose the correct visible/active option set.

### CARBIDE-029 — Pagination has invalid-input and scale traps

Status: `CONFIRMED`

Evidence:

- `lib/src/components/pagination/carbon_pagination.dart`
- page lists are generated from `1..totalPages`
- default layout is one non-wrapping row
- constructor validation is incomplete

Actual:

- Non-positive `pageSize` can lead to invalid calculations.
- Huge totals materialize huge page-option lists.
- Narrow/high-scale layouts overflow.
- Hardcoded strings and range formatting are English.

Expected:

Inputs are validated, large page counts remain bounded, and the control adapts
at narrow widths.

Suggested fix:

- Assert positive page/pageSize, non-negative total, positive unique page sizes,
  and valid page range.
- Replace unbounded page select with windowing or numeric input.
- Add a responsive layout.
- Centralize localizable labels and range formatting.

Acceptance:

- Tests cover zero/negative values and shrinking totals.
- 10,000 pages do not create 10,000 menu items.
- 320px and 2.0× text-scale tests pass.

### CARBIDE-030 — Modal/dialog overlays lack complete presence behavior

Status: `DOCUMENTED GAP` for exit motion; scroll locking requires a focused
runtime test.

Evidence:

- close paths hide the overlay immediately
- entrance animation exists
- ADR 0002 records missing presence exit behavior
- no shared background scroll-lock utility exists

Actual:

Close is visually abrupt. Underlying scrollables may continue to react to
wheel/touch while a modal is open.

Expected:

Modal surfaces play Carbon exit motion, honor reduced motion, then unmount.
Background content cannot scroll or interact while modal.

Suggested fix:

- Reverse entrance state, await the exit duration, then hide the portal.
- Add a shared scroll/interactivity lock for modal mode.
- Do not apply modal locking to non-modal dialogs.

Acceptance:

- Intermediate close frames are tested.
- Reduced motion unmounts immediately.
- Wheel/touch events do not change background offset while modal.
- Focus and semantics remain valid during exit.

---

## P2 findings — tests, CI, gallery, and documentation

### CARBIDE-031 — Cross-cutting specimens do not cover the public surface

Status: `COVERAGE GAP`

Evidence:

- `test/support/specimens.dart`
- `test/scaling/carbon_text_scaling_test.dart`
- `test/rtl/carbon_rtl_test.dart`

Missing or thin families include combo box, multi-select, date/time picker,
file uploader, page header, full UI shell, toolbar, modal, tooltip/toggletip,
popover, context menu, copy feedback, form primitives, fluid variants, and
several foundations widgets.

Expected:

Every exported visual family has a stable closed-state specimen and, where
relevant, an open-overlay specimen.

Suggested fix:

Create an inventory-driven registry with explicit state coverage.

Acceptance:

- Every exported component family is represented or has a documented exemption.
- The scaling and RTL sweeps cover open overlay geometry where meaningful.
- New exports fail a registry consistency check until classified.

### CARBIDE-032 — Accessibility policy is not enforced consistently

Status: `COVERAGE GAP`

Evidence:

- `CONTRIBUTING.md` requires `expectA11y` for each interactive component.
- A repository scan found roughly 32 of 75 component test files without the
  shared matcher; some contain good manual semantics tests, but not the common
  guideline sweep.

Expected:

Every interactive family has the common gate or a written exemption. Composite
widgets also prove reading order.

Suggested fix:

- Add missing tests.
- Add a small CI inventory check keyed by component family rather than blindly
  requiring one call in every split test file.

Acceptance:

- The inventory distinguishes non-interactive files and secondary split suites.
- Default, disabled, read-only, and icon-only states are covered where relevant.
- Existing `tapTargets: false` cases link to a specific tracked exception.

### CARBIDE-033 — Overlay lifetime suite covers only a subset of portal owners

Status: `COVERAGE GAP`

Evidence:

`test/leaks/overlay_lifetime_test.dart` covers several overlays but omits
select, combo box, multi-select, raw popover, context menu, header menu,
submenus, copy feedback, date pickers, side-nav rail overlay, and pagination
selects.

Expected:

Every `OverlayPortal` owner is tested for open, close, and disposal while open.

Suggested fix:

Parameterize a portal-owner lifetime harness.

Acceptance:

- Every portal owner is listed.
- Mid-open disposal produces no exception, retained entry, timer, focus node,
  or controller.
- The global leak tracker remains the oracle.

### CARBIDE-034 — Fidelity freshness is skipped in default CI

Status: `CONFIRMED`

Evidence:

- CI intentionally does not check out documentation submodules.
- The fidelity staleness test calls `markTestSkipped` when the Carbon React
  package file is absent.
- Early manifest captures have no version stamp.

Expected:

Reference age is validated without a full submodule checkout.

Suggested fix:

- Record the authoritative Carbon commit and `@carbon/react` version in a
  committed lock/manifest.
- Compare it to the submodule gitlink or a generated pin file in CI.
- Make excessive drift a failure, not only a debug warning.

Acceptance:

- Bumping the Carbon gitlink without refreshing references fails.
- No manifest capture has a null version.
- CI does not require cloning the large reference submodules.

### CARBIDE-035 — Tag publish verification is weaker than PR CI

Status: `CONFIRMED`

Evidence:

- `.github/workflows/ci.yaml`
- `.github/workflows/publish.yaml`

Actual:

Tag publish runs format, analyze, and tests, but omits the coverage gate, icon
lock drift guards, and dartdoc warning gate. Tag pushes do not trigger the main
CI workflow.

Expected:

A release cannot pass checks that the same commit would fail on a PR.

Suggested fix:

Extract a reusable verification workflow or mirror the full PR gate in publish.
Also verify the tag version matches `pubspec.yaml`.

Acceptance:

- Coverage, lockfiles, dartdoc, root tests, and package version are checked
  before OIDC publish.
- A deliberately failing gate prevents publication.

### CARBIDE-036 — Platform, gallery, and minimum-SDK CI leave blind spots

Status: `COVERAGE GAP`

Actual:

- PR CI is Linux-only.
- Web CI runs foundations/theme/utils, not component suites.
- Browser gallery integration is weekly rather than per PR.
- The minimum-SDK job validates the library but not the independent `example/`
  package.
- Deploy can build separately from gallery test success.

Expected:

Cheap, high-value platform smoke runs before merge and deploy.

Suggested fix:

- Run an io-free component subset in Chrome on relevant PRs.
- Run the gallery browser smoke on gallery/router changes.
- Analyze/test `example/` at Flutter 3.44.0.
- Make deploy depend on gallery test/build verification.

Acceptance:

- A broken gallery route fails before deployment.
- Example constraints are proven at their declared floor.
- The support matrix is documented as tested versus best-effort.

### CARBIDE-037 — Public fidelity and gallery claims are inaccurate

Status: `CONFIRMED`

Evidence:

- `README.md`
- `tool/fidelity/stories.json`
- gallery catalog

Actual:

README says every component has live controls, copyable code, and a Storybook
comparison. Fidelity covers 33 curated components, several public families lack
pages, and code blocks are plain text.

Expected:

Claims describe the three-tier fidelity system and actual gallery scope.

Suggested fix:

- State exact curated fidelity coverage or link to the machine-readable list.
- Explain golden-only components.
- Remove "copyable" until `CARBIDE-038` lands.
- Generate the README component table from the gallery/public inventory.

Acceptance:

- Counts in docs match code.
- No absolute "every component" wording remains without an automated invariant.

### CARBIDE-038 — Gallery code blocks are neither copyable nor drift-safe

Status: `CONFIRMED`

Evidence:

- `example/lib/src/demo_scaffold.dart`
- static `code:` strings in gallery pages

Actual:

The code block is plain text. Knobs can change the rendered widget without
changing the snippet.

Expected:

One action copies valid code corresponding to the displayed state.

Suggested fix:

- Render code with `CarbonCodeSnippet` or add `CarbonCopyButton`.
- Generate snippets from the same immutable demo configuration used to build
  the preview.
- Add clipboard tests.

Acceptance:

- Copying a snippet writes the expected text.
- At least one knob-driven page proves preview and snippet stay synchronized.
- Copy control is keyboard and screen-reader accessible.

### CARBIDE-039 — Important public APIs are missing or thin in the gallery

Status: `CONFIRMED`

Missing dedicated or adequate demonstrations include:

- UI Shell composition and skip-to-content
- `CarbonForm`, `CarbonField`, and `CarbonFluidForm`
- `CarbonPasswordInput`
- `CarbonExpandableSearch`
- `CarbonButtonSet`
- standalone `CarbonMenu`
- standalone `CarbonPopover`
- `CarbonTableToolbar`
- full data-table states
- notification variants
- two-handle slider
- filterable/fluid picker variants
- layer nesting and breakpoint behavior

Expected:

Each public family is discoverable, or an explicit inventory marks it as an
internal primitive/composition-only API.

Suggested fix:

Add pages incrementally and generate a coverage report from exports to catalog
entries.

Acceptance:

- `all_pages_test.dart` covers every new page.
- The gallery shell itself demonstrates `CarbonSkipToContent`.
- Narrow and keyboard smoke tests cover the shell.

### CARBIDE-040 — Architecture docs and ADRs contain stale factual claims

Status: `CONFIRMED`

Corrections required:

- `CarbideThemeData` → `CarbonThemeData`.
- Old icon/pictogram counts → 2,715 icons / 1,572 pictograms; distinguish 2,809
  icon artwork assets.
- Remove milestone-era barrel documentation.
- State that IBM Plex Serif is bundled.
- ADR 0002 must not say `borderTile` is absent.
- ADR 0002 must not list TreeView multiselect/active state as pending.
- Clarify implemented AI and partial chat token groups.
- Remove stale comments saying PaginationNav, RadioTile, ExpandableTile, or
  fluid typography are future work where they already exist.
- Replace "API reference once available" with the current pub.dev link.
- Reword "widgets.dart only" as "no Material or Cupertino"; the library
  legitimately uses other Flutter SDK libraries.

Acceptance:

- Repository searches for the stale names/counts return no misleading hits.
- Docs describe intentional omissions separately from unimplemented work.

---

## Additional actionable findings

### CARBIDE-041 — Text-area `maxCount` is display-only

Priority: `P1`
Status: `CONFIRMED`

Actual:

The counter can exceed `maxCount`; input is not constrained.

Expected:

Carbon prevents additional input at the maximum count.

Fix:

Apply a Unicode-safe input limit, define paste behavior, and announce the limit
without truncating composing text incorrectly.

Acceptance:

- Typing and pasting cannot exceed the configured count.
- Counter and controller remain synchronized.
- Add tests for multi-code-unit characters.

### CARBIDE-042 — Number input validation and commit behavior are inconsistent

Priority: `P1`
Status: `CONFIRMED`

Actual:

- Warning text can render without the warning icon used by `CarbonField`.
- Clearing with `allowEmpty: false` reports min/zero while the field stays empty.
- Free typing can display/report values outside min/max.
- No assertion guarantees a positive step.

Expected:

Typing has a documented draft state; blur/commit normalizes, clamps, and updates
display. Warning chrome matches other fields.

Fix:

Refactor `_NumberField` to compose `CarbonField`, add `step > 0`, and centralize
parse/commit/clamp behavior.

Acceptance:

- Tests cover partial, empty, invalid, underflow, overflow, and blur.
- Parent callback and displayed text agree after commit.
- Warning/invalid icon precedence matches other fields.

### CARBIDE-043 — Select-family read-only APIs are incomplete and inconsistent

Priority: `P2`
Status: `DOCUMENTED GAP`

Affected:

`CarbonSelect`, `CarbonComboBox`, `CarbonMultiSelect`, `CarbonSearch`,
`CarbonExpandableSearch`, and date pickers; `CarbonDropdown` already provides a
reference implementation.

Expected:

Read-only state is focusable/perceivable, non-opening/non-editable, and visually
distinct from disabled according to Carbon.

Acceptance:

- Shared API naming and semantics across the family.
- Pattern docs explain disabled versus read-only.
- Pointer, keyboard, and semantics tests prove no mutation.

### CARBIDE-044 — Time picker accepts arbitrary text without parsing policy

Priority: `P2`
Status: `CONFIRMED`

Actual:

`hh:mm` is only a placeholder; any string is accepted.

Expected:

Consumers can opt into parsing, masking, normalization, and validation without
rewriting the field.

Fix:

Add formatter/parser hooks and a documented commit model. Avoid hardcoding a
12/24-hour locale policy.

### CARBIDE-045 — Dropdown keyboard opening differs from Select

Priority: `P2`
Status: `CONFIRMED`

Actual:

Closed `CarbonDropdown` opens on Down/Enter/Space, but not ArrowUp.
`CarbonSelect` supports ArrowUp.

Expected:

The distinction is either intentional and documented or aligned.

Fix:

Add ArrowUp to dropdown if Carbon/native-select parity is desired.

Acceptance:

- Focused test proves the chosen behavior.
- Disabled/read-only states still do not open.

### CARBIDE-046 — Combo box handles Enter when it performs no action

Priority: `P2`
Status: `CONFIRMED`

Actual:

Enter can return `handled` with no open menu/highlight, preventing an ancestor
form/default action.

Expected:

Return `ignored` when the combo box does not consume Enter.

Acceptance:

- Form-level Enter test proves bubbling when closed.
- Highlighted option selection still consumes Enter once.

### CARBIDE-047 — Menu typeahead is ASCII-only

Priority: `P2`
Status: `CONFIRMED`

Evidence:

`RegExp(r'[a-z0-9]')` in `carbon_menu.dart`.

Expected:

Localized labels participate in typeahead.

Fix:

Normalize case/diacritics and accept Unicode letters/numbers using a strategy
supported by Dart without fragile ASCII filtering.

Acceptance:

- Tests include accented Latin and non-Latin labels.

### CARBIDE-048 — Context menu lacks a keyboard invocation path

Priority: `P2`
Status: `CONFIRMED`

Actual:

Only secondary tap and long press open the menu.

Expected:

Desktop/web users can use Shift+F10 or the Context Menu key, or documentation
requires an equivalent visible command.

Acceptance:

- If implemented, keyboard open positions the menu relative to the focused
  target and returns focus on close.

### CARBIDE-049 — Notification semantics and responsive layouts are partial

Priority: `P2`
Status: `DOCUMENTED GAP`

Actual:

- Actionable notification docs claim alert-dialog semantics, but implementation
  exposes a generic live-region container.
- Below-md wrapping and the 352px toast breakpoint are not ported.

Expected:

Semantics match the chosen notification role, and responsive layouts follow
Carbon.

Acceptance:

- Actionable, inline, toast, and callout variants have distinct semantics tests.
- Goldens cover below-md and max breakpoints.

### CARBIDE-050 — Page header misses heading semantics and responsive behaviors

Priority: `P2`
Status: `CONFIRMED` plus `DOCUMENTED GAP`

Actual:

The visual page title is plain text inside a "Page header" container. Responsive
action collapse, tag `+N` overflow, truncated-title tooltip, and hero slot are
not ported.

Expected:

The title is discoverable as the page heading, and supported responsive
behaviors are explicit.

Acceptance:

- Heading semantics test.
- Separate issues/acceptance tests for each documented visual gap.

### CARBIDE-051 — UI Shell composition is not responsive or fully accessible

Priority: `P2`
Status: `DOCUMENTED GAP` for responsive collapse; gallery misuse is confirmed.

Actual:

- Header links do not automatically collapse into side nav.
- Gallery does not include `CarbonSkipToContent`.
- Gallery wraps `CarbonHeaderName` in a pointer-only `GestureDetector` instead
  of using its accessible action API.
- Header/panel fixed heights and physical borders need scaling/RTL review.

Expected:

The canonical gallery demonstrates the recommended accessible shell.

Acceptance:

- Narrow shell test.
- Skip-link focus transfer test.
- Header home action works by keyboard.
- RTL panel border golden.

### CARBIDE-052 — Reduced-motion policy is not consistently applied

Priority: `P2`
Status: `CONFIRMED`

Known candidates:

- Search clear fade
- list-box chevron and animated field
- combo-box field decoration
- slider thumb scale
- contained-list hover fill
- tree-view chevron
- link color transition

Expected:

Decorative motion collapses to zero; essential loading/progress motion keeps
the explicitly documented policy.

Fix:

Audit every `Animated*`, `AnimationController`, raw `Duration`, and timer-driven
visual transition. Add a reusable duration resolver or lintable convention.

Acceptance:

- Every animated component has a reduced-motion test or explicit essential
  motion rationale.

### CARBIDE-053 — OS high-contrast mode is not integrated

Priority: `P2`
Status: `CONFIRMED`

Actual:

No component/theme layer reacts to `MediaQuery.highContrast`. Component
properties called `highContrast` are Carbon variants, not OS adaptation.

Expected:

Enterprise users get strengthened borders/focus or the limitation is plainly
documented.

Fix:

Design a theme-level adaptation before adding ad hoc component branches.

Acceptance:

- High-contrast specimen sweep or explicit support statement.
- Focus indicators and meaningful non-text boundaries remain visible.

### CARBIDE-054 — Theme/token surface is intentionally incomplete but not clearly bounded

Priority: `P2`
Status: `CONFIRMED`

Missing or partial upstream families:

- syntax-highlighting tokens
- most chat shell/bubble/avatar tokens
- status component tokens are manually mapped
- content-switcher low-contrast tokens
- fluid spacing
- fixed expressive-heading aliases

Expected:

The public contract says which Carbon token families are complete, partial, or
out of scope.

Fix:

Prioritize tokens that unblock existing Carbide components:

1. content-switcher low contrast
2. status tokens
3. fluid spacing / expressive aliases
4. chat tokens when chat UI expands
5. syntax tokens when highlighted snippets are scoped

Acceptance:

- Generator and lock tests, not hand-copied constants.
- `CarbonContentSwitcher.lowContrast` gets its own component issue.

### CARBIDE-055 — Add a first-class fluid text widget

Priority: `P2`
Status: `DOCUMENTED GAP`

Actual:

Callers manually resolve `CarbonFluidTextStyle` against a width.

Expected:

`CarbonFluidText` or `CarbonText.fluid` updates automatically at Carbon
breakpoints and preserves semantics/text scaling.

Acceptance:

- Tests at all breakpoints.
- Serif quotation style golden.
- Add to specimen registry and gallery.

### CARBIDE-056 — `CarbonFluidTextStyle` lacks standard value-object APIs

Priority: `P3`
Status: `CONFIRMED`

Expected:

An immutable token object supports equality, stable hashing, and `copyWith`
where useful, consistent with the rest of the theme API.

Acceptance:

- Equality/hash tests, including override-map contents rather than identity.

### CARBIDE-057 — Generated token tests are not independent upstream verification

Priority: `P2`
Status: `CONFIRMED`

Actual:

Some implementation and expected-value tests are emitted by the same parser.
A parser bug can produce matching wrong code and tests.

Expected:

At least one independent drift guard compares generated outputs or parsed
values to the upstream submodule.

Fix:

Add `--check` modes and CI diff checks for colors, themes, type, fluid type,
layout, and motion on submodule-update workflows.

### CARBIDE-058 — Component completeness needs an explicit parity matrix

Priority: `P2`
Status: `CONFIRMED`

True missing/partial surface includes:

- `CarbonDefinitionTooltip`
- table-style inline checkbox/decorator row patterns
- content-switcher low contrast
- breadcrumb overflow
- horizontal tab overflow
- grid column hang/subgrid limitations
- partial page header and responsive UI Shell
- notification responsive variants
- deferred v12 tile/structured-list/file-uploader behavior

Not gaps:

- button kinds consolidated in one enum
- ToggleSmall represented by size
- fluid fields represented by `fluid:` and `CarbonFluidForm`
- React/DOM infrastructure such as prefix providers, hooks, and portals

Expected:

A checked-in matrix records Present, Consolidated, Partial, Deferred,
Out-of-scope, and Fidelity tier.

Acceptance:

- Generated or reviewed on each Carbon submodule bump.
- README links to it instead of implying full parity.

### CARBIDE-059 — File uploader is presentation-only

Priority: `P3`
Status: `CONFIRMED`, likely intentional

Actual:

File picking, drag/drop event integration, and upload transport are all caller
owned. The gallery does not demonstrate a realistic integration.

Expected:

Either provide an optional platform adapter or publish complete web/mobile
recipes, including security and permission considerations.

Acceptance:

- Documentation explicitly states responsibilities.
- Interactive gallery demo uses a fake adapter, not real upload.

### CARBIDE-060 — Static list markers fail after 26 nested ordered items

Priority: `P3`
Status: `CONFIRMED`

Actual:

Character arithmetic produces punctuation after `z`.

Expected:

Lower-Latin numbering continues `aa`, `ab`, and so on, or a documented limit is
enforced.

Acceptance:

- Unit tests around 25, 26, 27, and 52.

### CARBIDE-061 — Static tag/list/code semantics need explicit policy

Priority: `P3`
Status: `VERIFY`

Review:

- Decorative `CarbonTag` may need optional semantic labeling for status use.
- Lists render visual markers but do not expose a strong list/list-item
  structure.
- Code snippets are text in scroll views without a named code-region landmark.

Required action:

Use TalkBack/VoiceOver and Flutter semantics dumps before adding duplicate
labels. Then document when callers should provide semantic labels.

### CARBIDE-062 — Public low-level APIs need stability classification

Priority: `P3`
Status: `CONFIRMED`

Candidates:

- `CarbonIconPainter`
- `CarbonIconData` internals
- `CarbonListBox` primitives
- `CarbonMenu` primitive
- unexported-but-publicly-named `CarbonScrollIntoView`

Expected:

Each is intentionally stable/exported, documented as advanced/experimental, or
kept internal. Avoid accidental semver commitments.

### CARBIDE-063 — Icon path cache is unbounded

Priority: `P3`
Status: `CONFIRMED`

Actual:

The static parsed-path cache grows for every unique shape rendered.

Expected:

Measure before changing. If full icon/pictogram explorers or long-running apps
retain significant memory, cap with an LRU or cache per const artwork.

Acceptance:

- Memory benchmark justifies the chosen policy.

### CARBIDE-064 — Validate gallery and package metadata polish

Priority: `P3`
Status: `CONFIRMED`

Work:

- Replace Flutter boilerplate web description/theme colors/orientation.
- Add pub.dev screenshots.
- Add root `SECURITY.md`.
- Consider CODEOWNERS/dependency automation.
- Ensure deploy path filters include root dependency metadata.
- Clarify that Plex Condensed is not bundled if NOTICE still mentions it.

### CARBIDE-065 — Add a platform support matrix

Priority: `P3`
Status: `CONFIRMED`

Expected:

Document per platform:

- supported versus CI-tested
- authoritative golden platform
- web font/golden limitations
- pointer/keyboard/context-menu behavior
- Android/iOS target-size policy
- OS high-contrast and localization status

### CARBIDE-066 — Decide whether charts belong in scope

Priority: `P3`
Status: `STRATEGIC`

Actual:

Carbide includes tables, lists, trees, progress, icons, and pictograms but no
chart widgets.

Expected:

Do not treat this as a bug. Add an explicit scope statement or a separate
proposal for Carbon Charts rather than silently expanding this package.

---

## Findings intentionally downgraded pending proof

The following claims appeared during review but should not be filed as confirmed
defects without the requested test:

- Modal focus escape: Flutter's default `FocusScope` traversal may already loop.
  Complete `CARBIDE-012`.
- Slider RTL physical positioning: existing directed tests/goldens may already
  prove it; add a min/max geometry assertion before changing layout.
- Date-picker outside-tap focus return: focused probes disagreed. The range
  cancellation defect is confirmed, but single-picker focus behavior needs a
  stable test.
- Generic popover focus movement: `CarbonPopover` is a primitive; make focus
  management opt-in or document consumer responsibility rather than imposing a
  dialog policy.
- Loading under reduced motion: Carbide deliberately treats spinners and
  indeterminate progress as essential motion. Keep the rationale unless Carbon
  or product accessibility policy changes.

## Reviewed areas with no material finding

These areas were explicitly reviewed. They do not need an issue unless their
upstream source or product scope changes.

### Foundations and themes

- Generated Carbon color swatches match the pinned palette and have exhaustive
  value locks.
- Fixed typography and the existing fluid typography token cascade match the
  pinned upstream values.
- `CarbonDuration` and `CarbonEasing` match the core Carbon motion tokens.
- White, Gray 10, Gray 90, and Gray 100 theme presets are exhaustively locked.
- `CarbonLayer` implements the three-level token offset model, including the
  subtle-border offset and `withBackground`.
- `AnimatedCarbonTheme` interpolates theme data and collapses decorative
  animation under reduced motion.
- The contrast sweep documents upstream-inherited exceptions and fails if an
  allowlisted pair starts passing, preventing stale exceptions.

### Icons, pictograms, and assets

- The icon and pictogram registries match the pinned Carbon commit.
- Size-specific icon artwork selection has structural tests.
- Icons are decorative by default and become semantic images only when labeled.
- Pictograms enforce the documented minimum display size.
- The SVG path parser/painter and raster-fidelity sweep provide meaningful
  independent coverage.
- Bundled IBM Plex Sans, Mono, and Serif families cover the weights used by the
  current token set. Italic cuts remain an optional completeness decision, not
  a current component defect.

### Components with strong current behavior

- Buttons, icon buttons, and links have broad state, keyboard, focus, theme,
  text-scale, and golden coverage.
- Tags and interactive tag variants have clear controlled APIs and keyboard
  activation; only small-target policy and static-tag semantics remain in the
  backlog.
- Tile variants have controlled selection/expansion and layer-aware visuals.
- Loading, inline loading, progress bar, and skeletons clearly distinguish
  essential from decorative motion.
- Accordion controlled state, focus treatment, and expanded semantics are
  solid; exclusive-open mode is optional product scope rather than a missing
  Carbon default.
- Radio-group and content-switcher roving keyboard behavior, including current
  RTL handling, is well tested apart from the icon-only label defect.
- Slider two-handle constraints, keyboard mapping, snapping, and RTL behavior
  are well covered once the disabled gate is fixed.
- Date-range selection has a substantial state-machine test suite; the backlog
  targets the uncovered cancel/reconciliation paths rather than replacing it.
- Data-table sort, selection, expansion, zebra, batch header, sticky scrolling,
  and motion behavior are well decomposed and tested for moderate data sizes.
- Tree-view keyboard navigation and controlled selected/active state are strong;
  expansion control, focus pruning, and scale are the remaining architectural
  gaps.
- Popover placement options, caret geometry, RTL start/end policy, and
  TapRegion dismissal have extensive focused tests.
- Tooltip and toggletip hover/focus/dismiss behavior is generally sound;
  generic popover focus remains intentionally caller-controlled.
- Menu and overflow-menu roving focus, Home/End, submenu direction, and Escape
  behavior are strong aside from Unicode typeahead and edge placement.
- UI Shell header, side-nav rail, and switcher primitives have meaningful
  keyboard and motion coverage even though responsive composition is not yet
  automatic.

### Quality and release infrastructure

- Strict analysis and public API documentation are enforced.
- The package coverage result is substantive; generated const registries are
  excluded for a documented reason.
- Linux-authoritative text goldens, strict small-surface goldens, DPR canaries,
  and narrow-width harnesses form a sound visual baseline.
- Global leak tracking is enabled for root widget tests.
- Icon/pictogram lockfile drift is checked on PR CI.
- Publish uses trusted OIDC credentials and has a dry-run rehearsal.
- The gallery builds every registered catalog page in widget tests.

### Intentional non-parity that should not be filed as a bug

- React/DOM infrastructure such as prefix providers, hooks, portals,
  ErrorBoundary, and feature-flag contexts does not map directly to Flutter.
- Separate React button exports are represented by `CarbonButtonKind`.
- ToggleSmall is represented by `CarbonToggleSize.sm`.
- Standalone React `Fluid*` wrappers are represented by `fluid:` plus
  `CarbonFluidForm`; discoverability needs work, but duplicate classes are not
  required.
- FlexGrid/subgrid and full CSS-grid behavior are not present in the current
  `Wrap`-based grid; this is a documented architectural boundary.
- Loading spinners and indeterminate progress intentionally keep essential
  motion when decorative animations are disabled.
- File upload transport and backend concerns are application responsibilities.
- Charts would be a separate Carbon Charts scope decision.

## Upstream version posture

At audit time:

- The checked Carbon React package reported 1.111.0.
- The most recent npm version observed during the audit was 1.114.0.
- The newest fidelity capture batch reported 1.111.1.

Action:

Treat this as routine upstream maintenance, not evidence that generated tokens
are wrong. Refresh the submodule, review feature flags, run all generators in
check mode, recapture fidelity references, and update the parity matrix in one
focused upstream-sync change.

## Baseline verification evidence

The review established the following green baseline before documentation was
added:

- `dart format --set-exit-if-changed .`
- `flutter analyze`
- root package tests with coverage
- 90% coverage gate at 97.6%
- gallery tests
- API documentation generation
- icon and pictogram lockfile consistency
- checked Carbon reference submodules for fidelity/completeness analysis

The baseline passing does not invalidate the findings: several defects are
explicitly bypassed in accessibility tests, rely on untested widget-update
paths, or sit outside the current specimen/fidelity registries.

## Definition of completion

This review can be considered worked down when:

- No `P0` item remains.
- No interactive semantics node is perceptible but inoperable.
- Mutable controllers, focus nodes, controlled indices, ranges, and tree/table
  identities have reconciliation tests.
- The default a11y gate has no unexplained suppression.
- Every exported visual family has a test specimen, gallery classification, and
  fidelity tier.
- README, ADRs, gallery, and CI claims are generated from or checked against
  machine-readable inventories.
- Remaining Carbon differences are explicit product decisions, not stale TODOs
  or skipped tests.
