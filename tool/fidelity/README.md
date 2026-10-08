# Upstream fidelity pipeline (W3)

Compares Carbide components against **real IBM Carbon** rendering, so divergence
from the source design system is caught — not just divergence from our own past
output (which the golden tests lock in) or from the SCSS spec (which the
spec-lock tests assert).

It has two phases:

## 1. Capture references (manual, needs network)

`capture_references.mjs` drives Playwright over the published Carbon React
Storybook and screenshots each story in [`stories.json`](stories.json), once per
theme (`white` / `g10` / `g90` / `g100`), into
`test/fidelity/references/<component>/<theme>.png`. A `manifest.json` records the
source URL, capture time, and per-story result.

```sh
# Local Playwright (simplest):
tool/fidelity/capture.sh

# Or fully hermetic, version-matched Docker image:
docker run --rm -v "$PWD":/work -w /work/tool/fidelity \
  -e HOME=/work/tool/fidelity -e OUT=/work/test/fidelity/references \
  --user "$(id -u):$(id -g)" \
  mcr.microsoft.com/playwright:v1.61.0-jammy \
  sh -c "npm ci || npm install; node capture_references.mjs"
```

The captured PNGs **are committed** — they are the ground truth the offline test
compares against. Re-run capture (and commit the diff) when you bump the
`documentation/carbon` submodule or add stories.

## 2. Compare (offline, runs in CI)

[`test/fidelity/fidelity_test.dart`](../../test/fidelity/fidelity_test.dart)
renders the Carbide equivalent of each captured story (a builder keyed by the
same `component` slug) and writes a side-by-side
`Carbon | Carbide` image to `test/fidelity/comparisons/<component>_<theme>.png`.
CI uploads those as an artifact on every PR.

**This is a coarse drift gate over 33 curated default stories.** The metric is
mean absolute luminance difference on a 24×24 grid, not SSIM or pixel identity.
Each entry records all four measured Linux scores, their maximum, a stated
margin and a machine-readable rationale. Every rendered control also has a
size budget, and important controls have exact semantic-token colour and state
checks. Additional render tests cover focused/disabled Button chrome and an
invalid text-input border. Those checks protect small controls that the grid can dilute or miss.

The gate guards the reviewed default compositions. It does not compare every
variant or establish complete Carbon parity. Known geometry differences and
limited reference crops remain explicit beside the corresponding baseline.
Other variants rely on the package's state matrices, spec locks, golden tests
and browser contracts until additional upstream stories are promoted.

## Matching fixtures

Each of the 33 entries records its pinned story source, capture viewport, root
bounds and audit finding in `stories.json`. The fixtures share their builders
with anatomy tests, so the comparison cannot silently substitute another
component or lose a selected/disabled state. The 1280×720 capture environment,
Plex typography, full story-root width and decorators are reproduced; reference
images remain unchanged when only a Carbide fixture is corrected.

The existing Modal reference is a 48px story-root crop across the open dialog.
The harness also writes `modal_full_<theme>.png` for complete form review; the
cropped score alone cannot cover its body/footer. Closed Tooltip and Overflow
Menu icons can fall between the grid samples. An exact pixel-range nonblank
check keeps their renders honest; the coarse score needs structural checks for
those small controls. Comparison artifacts are written before drift assertions
so failed cases are available for review.

## Extending coverage

1. Add `{ "component": "<slug>", "storyId": "<storybook-id>" }` to `stories.json`
   (find ids in `https://react.carbondesignsystem.com/index.json`).
2. Re-run `capture.sh` and commit the new references.
3. Add a matching `'<slug>': () => <Carbide widget>` to `_builders` in
   `fidelity_test.dart`.

## The three fidelity tiers (#230)

Not every component carries the same upstream guarantee — the tier is
explicit so nobody mistakes golden-only coverage for an upstream gate:

1. **Pixel-gated (icons + pictograms)** — every asset rendered through the
   production painter is compared against rsvg-rasterized upstream SVGs at
   ≤0.5% blurred-coverage mismatch, with a mutation guard, on every CI
   run. The strongest guarantee in the repo.
2. **Threshold-gated (components in `stories.json`)** — rendered beside a
   committed Carbon Storybook screenshot; the coarse luminance-grid diff
   must stay within the story's committed `threshold`. Measured budgets plus size/colour/state checks detect drift across
   renderers; they do not establish pixel identity. Bootstrap flow: add the story +
   builder with no threshold, run the suite, read the `FIDELITY-SCORE`
   lines, commit `max(per-theme score) + margin` as the threshold, and
   ratchet it down as fidelity improves.
3. **Golden-only (everything else)** — Carbide compared against its own
   past output plus SCSS spec-locks. A systematic spec misreading is
   invisible here; promote components into tier 2 as stories are
   captured.

Reference freshness: `manifest.json` stamps the `@carbon/react` version
the live Storybook ran at capture; the fidelity suite warns when the
submodule pin drifts ≥2 minors ahead. Re-capture on submodule bumps
(the references currently target @carbon/react 1.118.0, matching the
v11.118.0 pin).

## Proving regression rejection

The suite contains permanent tests that render the promoted Button with a red
primary fill or an additional 64px of horizontal spacing, then require the
same colour/size checks to reject it. To see the affected story fail directly:

```sh
flutter test test/fidelity/fidelity_test.dart --plain-name 'fidelity: button' \
  --dart-define=FIDELITY_MUTATION=button-color
flutter test test/fidelity/fidelity_test.dart --plain-name 'fidelity: button' \
  --dart-define=FIDELITY_MUTATION=button-spacing
```

Both commands intentionally fail; normal runs omit the mutation define.
Neither command changes production source or upstream reference images.
