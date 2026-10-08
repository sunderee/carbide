# Text scaling

What Carbide promises when the user raises the system text scale
(`MediaQuery.textScaler`), and how that promise is enforced.

## The policy

**Component chrome grows with its text.** Every spec height Carbon defines
(buttons 48px, fields 32/40/48px, tags 24px, table rows 24–64px, side-nav
rows 32px, the pagination bar 48px…) is implemented as a **minimum**, not a
ceiling. At scale 1.0 the content always fits inside the spec height, so
components render pixel-identical to the fixed-height interpretation; under
scaling the chrome grows downward instead of clipping glyphs.

This mirrors what Carbon itself does on the web: under browser zoom the
whole layout — chrome included — grows. Flutter's `textScaler` scales only
text, so the chrome must yield explicitly.

Corollaries:

- **No component clamps text scale.** Clamping
  (`MediaQuery.withClampedTextScaling`) would trade the user's legibility
  setting for our geometry, which is backwards. If a future component
  genuinely cannot grow (none today), the clamp must be documented on the
  component and justified here.
- **Widths are the host's contract.** Scaled text also grows horizontally.
  Components ellipsize where Carbon ellipsizes (button labels, tag labels,
  list-box values) and otherwise expect the host to provide width or a
  horizontal scroll — the gallery's pagination page is the reference
  pattern.
- **Icons and spacing tokens do not scale.** Only type scales; 16px icons
  and `$spacing-*` stay fixed, matching Flutter platform convention.

## Enforcement

`test/scaling/carbon_text_scaling_test.dart` pumps every specimen in
`test/support/specimens.dart` at **1.3×** (the most common system
accessibility setting) and **2.0×** (the WCAG 1.4.4 requirement) and
asserts:

- the tree lays out without exceptions (overflow errors throw in tests);
- no `Text` or `EditableText` renders below one scaled line box, using resolved
  inherited styles, real font metrics and the effective scaler
  (`expectNoClippedTextAtScale` in `test/support/legibility.dart`).

Most goldens stay at scale 1.0. A 1.3× text-input canary and the compact field
canvases in `test/scaling/scaled_fields_test.dart` pin the chrome that previously
clipped: small fields at 2×, fluid label/value stacks at 1.3× and 2×, and open
dropdown rows at 2×. Each field canvas covers four themes and both directions.
`expectThemeGoldens` accepts a `mediaQuery` override for these cases.

The field suite also opens dropdown, select, combo-box, multi-select and the
time picker's period select at both scales. It checks complete editable and
option line boxes, popup viewport bounds, Escape dismissal and unscaled icon
artwork. The list-box fold remains bounded and scrollable as rows grow. Viewport
edge collisions and placement after resize are tracked separately in #335.

New components join the sweep by adding a specimen to
`test/support/specimens.dart` — the sweep, the RTL crash guard, and the
leak sweep all draw from that registry.
