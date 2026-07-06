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
- no `Text` renders below one scaled line box
  (`expectNoClippedTextAtScale` in `test/support/legibility.dart`).

Goldens stay at scale 1.0 (a scaled golden doubles maintenance for little
signal beyond what the sweep asserts), with one exception: a single 1.3×
text-input canary golden pins the grown-chrome rendering so a regression in
the growth behavior itself is visible as pixels. `expectThemeGoldens`
accepts a `mediaQuery` override for cases like it.

New components join the sweep by adding a specimen to
`test/support/specimens.dart` — the sweep, the RTL crash guard, and the
leak sweep all draw from that registry.
