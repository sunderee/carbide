# ADR 0001: Icon rendering — generated path data + CustomPainter

- **Status:** accepted
- **Date:** 2026-06-10
- **Issue:** #29 (spike); consumed by #30–#34

## Context

Current counts are checked in [reference facts](../reference-facts.md). The
measurements below describe the original spike, not a portable performance
guarantee or the current registry count.

Carbide must render the full pinned Carbon icon and pictogram registries with
pixel fidelity to the upstream artwork, under these constraints:

- No Material/Cupertino and no new runtime dependencies.
- Carbon ships master artwork at 32×32 with **hand-tuned overrides** for some
  icons at 16/20/24 plus bespoke "glyph" assets — the renderer must preserve
  per-size artwork, not just scale one drawing.
- Icons must be **tree-shakeable**: an unused icon costs zero bytes.
- Fidelity must be provable **against upstream's own artwork**, not against
  our transcription of it.

Source analysis: icon SVGs use only `path`/`rect`/`circle`/`ellipse`/
`polygon`/`polyline`; 650 files carry transforms (mostly no-ops, some real
`rotate(±90/180)`); 14 use `fill-rule: evenodd` via CSS classes; invisible
elements (artboard rects with `fill: none`, zero-opacity inner paths) must be
dropped via CSS-class resolution; bespoke 16px assets have no `viewBox` (only
`width`/`height`).

## Decision

**Each icon is generated as const Dart data — SVG path strings, a fill rule,
and an optional 2D affine matrix — parsed at runtime into `ui.Path` and
painted with a `CustomPainter` scaled from the viewBox.**

- Extraction/normalization happens at **codegen time** (Python, like the
  token generators): CSS classes resolved, invisible elements dropped,
  non-path shapes converted to path data, transforms composed per shape.
- The **runtime parser** handles the full `d` grammar (M/L/H/V/C/S/Q/T/A/Z,
  relative forms, implicit repetition, compact arc flags); SVG arcs map
  directly onto `Path.arcToPoint`.
- Parsed paths are cached per icon/size; parsing measured at **12.5µs per
  icon**, so pre-parsing is unnecessary (see below).

## Empirical validation (the spike)

12 feature-exercising assets (polygons, bespoke 16px artwork, invisible-
element normalization, evenodd, real rotate transforms, watson-health and Q
namespaces, circles, a pictogram) were extracted and rendered via
`PictureRecorder`, then compared pixel-wise against **rsvg-convert
rasterizations of the upstream SVGs** at 16/20/24/32/64px (pictogram:
32/64/128).

Two metrics over the alpha channel (band ±32/255):

- **raw** — per-pixel comparison;
- **coverage** — comparison after a 3×3 box blur of both images. The blur
  forgives sub-pixel edge-sampling differences between renderers while still
  catching real geometry errors (a shape displaced a full pixel survives the
  blur).

Results (`test/spike/icon_fidelity_spike_test.dart` prints the full table):

- **coverage mismatch: 0.000% for every asset at every size.** Geometry is
  exact across all features.
- raw mismatch is 0.000% for pure-polygon icons and up to ~6% only on
  **arc-heavy icons at small sizes** — Skia renders arcs as conics while
  rsvg approximates them with béziers, so curve edge pixels anti-alias
  differently. This is renderer AA, not artwork error; it converges toward
  zero as size grows (e.g. `airport_location`: 3.1% @16 → 0.05% @64).
- Pictograms rendered below native size alias badly (15.6% raw @16px before
  exclusion); pictograms are display assets (48px+) and must not be rendered
  below their native 32 — the pictogram widget will document/enforce this.

**Gate for the fidelity sweep (#32): blurred-coverage mismatch ≤ 0.5%**, with
the raw number reported for diagnostics.

## Alternatives rejected

- **Icon font**: collapses the bespoke per-size artwork into single glyphs,
  risks fill-rule fidelity, requires heavy font tooling, and gains nothing —
  path data is already tree-shakeable per-const.
- **Pre-parsed `Path` command lists**: roughly doubles generated source for
  no benefit given the measured 12.5µs parse cost; a cache bounds repeat
  work.
- **Runtime SVG/XML parsing**: would ship XML + CSS handling in the package
  and move normalization bugs to runtime; normalization belongs in codegen
  where it is tested once.

## Consequences

- #30 ports the spike's extractor (`tool/spike_icon_fidelity.py`) into the
  full pipeline; the spike's Dart parser (`test/spike/support.dart`) moves
  into `lib/` as the production parser with its own unit tests.
- #32 adopts the blurred-coverage metric and the committed-upstream-raster
  corpus exactly as prototyped here.
- The icon widget (#33) selects bespoke artwork per size and scales the 32px
  master otherwise — both paths validated by the spike (`apps_16`/`apps_32`).
