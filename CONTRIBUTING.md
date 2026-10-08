# Contributing to Carbide

Thanks for your interest. Carbide aims for a faithful, well-tested Carbon port,
so contributions are held to a deliberately high bar.

## License

Carbide is licensed under the [Apache License, Version 2.0](LICENSE). By
opening a pull request you agree your contribution is licensed under those
terms.

## Ground rules

- **Base widgets only.** Do not import `package:flutter/material.dart` or
  `package:flutter/cupertino.dart` in `lib/`. Build from
  `package:flutter/widgets.dart`.
- **Fidelity to Carbon.** Port values and behaviour from the upstream sources in
  `documentation/` (tokens from `documentation/carbon/packages`, design guidance
  from `documentation/carbon-website`). Cite the source in the PR.
- **Tests are not optional.** See the definition of done below.
- **Strict analyzer.** `dart analyze` must report zero issues. Format with
  `dart format`.

## Workflow

1. Pick or open an issue; one component / token group per branch.
2. Branch from `master` (e.g. `feat/button`, `tokens/motion`).
3. Implement, document public APIs with `///`, and add tests.
4. Run the checks below locally.
5. Open a PR linked to the issue. CI must be green.

## Local checks

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

### Coverage

CI runs the package suite with `flutter test --coverage` and gates on a
**90% line floor** via `dart run tool/coverage_gate.dart --floor 90`, which
also appends the percentage to the workflow job summary and uploads
`coverage/lcov.info` as an artifact. Run the same two commands locally to
reproduce the gate.

What the number means:

- The generated icon/pictogram registries
  (`lib/src/{icons,pictograms}/generated/`) are excluded from the
  denominator. Today they are const-only and emit no executable lines
  anyway; the exclusion keeps the number honest if codegen ever changes.
- Const-only foundations (`colors`, `typography`, `fluid_typography`,
  `fonts`) are invisible to lcov for the same reason — they are covered by
  value-equality tests but do not appear in the report.
- The floor is a **total**, not per-file. The gate prints every file under
  the floor as an informational tail; keep new components out of it.

### CI

Every PR runs on the **latest Flutter stable** (`channel: stable` in
`.github/workflows/ci.yaml`; other workflows use the same setup):

- **Format, analyze, test** — plus the coverage gate (above), the icon
  lockfile drift guard, and the dartdoc reference gate. Ubuntu only, so
  golden comparison is strict and authoritative.
- **Gallery — analyze & test** — the example app's suite + contact sheet.
- **Motion policy source guard** — `python3 tool/test_motion_policy.py` and
  `python3 tool/check_motion_policy.py` enforce duration resolution and the
  documented loading/indeterminate-progress exceptions. See
  [loading accessibility](docs/patterns/loading.md#accessibility).
- **Publish rehearsal** (`publish-rehearsal.yaml`) — on PRs touching
  packaging inputs (`pubspec.yaml`, README, LICENSE, NOTICE, …): a strict
  `dart pub publish --dry-run` that tolerates exactly the known
  `documentation/` submodule warning and nothing else, so packaging errors
  are caught before a release tag.

Off-PR cadence: **OS matrix** (`os-matrix.yaml`, weekly + on demand via
`gh workflow run os-matrix.yaml`) runs the full package suite on macOS and
Windows (text goldens get the lenient off-Linux bound), the dart:io-free
suites on the web platform (`--platform chrome`, goldens skipped), and the
gallery's `integration_test/` contracts driven in a real browser — the same
configuration the deployed gallery ships. Native web contracts run in six
parallel groups (gallery, lifecycle, data, controls, pickers, preferences),
each preserving its debug/release modes and limited to 15 minutes. A failing
group does not cancel the others, so the full matrix remains visible.

### Accessibility gates

Two machine-checked gates back the DoD's accessibility bullet (#226):

- **Token-pair contrast** (`test/theme/contrast_test.dart`): every
  (foreground, background) token pairing components render is swept per
  theme against WCAG 2.1 — ≥4.5:1 for text, ≥3:1 for meaningful non-text.
  Upstream-inherited exceptions (placeholder text is 40%-alpha by
  definition; the dark themes' `layer03` pairings) live in an allowlist
  that cites `documentation/carbon/packages/themes/src`; an entry whose
  pair starts passing again fails the sweep until removed. New tokens or
  new pairings belong in the sweep, not around it.
- **Guideline matchers**: each interactive component's test file calls
  `expectA11y(tester)` from `test/support/a11y.dart`, running Flutter's
  `androidTapTargetGuideline` (48×48dp) and `labeledTapTargetGuideline`.
  Carbon deliberately ships sub-48dp densities (fields are 40px, menu
  items 32px, tags 24px); where that makes the tap-target guideline
  unattainable at the default size, the test keeps the label check and
  carries a comment citing the SCSS size — never silently omit the gate.
  Composite components (modal, menu, data table, form, UI shell) also
  assert reading order via
  `tester.semantics.simulatedAccessibilityTraversal()`.

### Text scaling

Spec heights are **minimums**: chrome grows with text under
`MediaQuery.textScaler` instead of clipping, and no component clamps the
user's scale (policy + rationale in [docs/text-scaling.md](docs/text-scaling.md)).
The sweep in `test/scaling/` renders every specimen from
`test/support/specimens.dart` at 1.3× and 2.0× and fails on overflow or a
text squeezed below one scaled line box. New components add a specimen to
the registry; use fixed heights only as `minHeight` constraints.

### Reduced motion

Every animated component honors `MediaQueryData.disableAnimations`
(#235): decorative motion — entrances, folds, fades, hover fills, theme
crossfades — collapses to `Duration.zero`
(`MediaQuery.maybeDisableAnimationsOf(context) ?? false`, the toggle
pattern), while essential motion (the loading spinner, the indeterminate
progress sweep) keeps running because it communicates ongoing work; each
widget's doc states its decision. Tests pump with
`MediaQueryData(disableAnimations: true)` and assert the end state on the
next frame. Every animated component also carries a **motion-token
spec-lock** asserting its duration/curve equal the `CarbonDuration` /
`CarbonEasing` constants its SCSS cites — motion drift is invisible in
static goldens by construction.

### Leak testing

`LeakTesting.enable()` runs in `test/flutter_test_config.dart`, so **every
`testWidgets` case doubles as a leak test** (#234): an undisposed
`FocusNode`/controller or an overlay entry that outlives its trigger fails
the test that pumped it. Rules:

- Prefer fixing over ignoring; the only global ignores are
  `createdByTestHelpers` and the `Image` class (golden capture allocates
  `ui.Image`s inside the framework; nothing in `lib/` allocates one).
  Any new allowlist entry carries a justification comment.
- Test hosts that build an `Overlay` must create entries via
  `managedOverlayEntry` (`test/support/overlay_entries.dart`) — the
  entry's creator owns disposal, and a bare `OverlayEntry` in a host
  leaks by construction.
- `test/leaks/overlay_lifetime_test.dart` drives every popup component
  through open, close, and tear-down-while-open.

### Golden tests

The bundled IBM Plex fonts are loaded automatically for every test by
`test/flutter_test_config.dart`, so golden output uses real glyphs. Snapshot a
widget on all four themes at once with `expectThemeGoldens` from
`test/support/golden.dart`; baselines are written next to the test under
`goldens/<name>.<variant>.png`.

Generate or update baselines with `flutter test --update-goldens` and review the
images. A small tolerance (0.5%) absorbs sub-pixel anti-aliasing differences
between machines. Vector geometry renders identically across platforms, but
**glyph rasterization does not** (macOS CoreText vs Linux FreeType differ by
~8–9% of pixels on the same text), so text goldens are **Linux-authoritative**:

- Pass `containsText: true` to `expectThemeGoldens` for any snapshot that
  renders glyphs. The golden is named `<name>.text.<variant>.png`; the
  comparator checks it strictly (0.5%) on Linux and leniently (15%) elsewhere,
  so local macOS runs still catch gross errors without false failures.
- Generate text goldens with the **“Regenerate goldens” workflow**
  (`gh workflow run regenerate-goldens.yml --ref <branch>`), which runs
  `--update-goldens` on Linux and commits the result back to the branch. The
  bot commit does not retrigger CI; pull and push (or open the PR) afterwards.
- When the loose off-Linux path saves a text comparison, the comparator
  prints a loud `LOOSE text-golden tolerance applied` notice — treat a
  local off-Linux pass of a text golden as non-authoritative by definition.
- **Small-surface goldens** should pass `strict: true`
  (`<name>.strict.…png`, 0.05% bound): the default 0.5% is whole feature
  rows of pixels on a 32×32 tile.
- **DPR canaries** (`test/harness/dpr_canaries_test.dart`) render the
  hairline-heavy primitives through a 1.5× scale
  (`devicePixelRatio: 1.5`), pinning fractional-DPR anti-aliasing that
  1.0-DPR goldens cannot see. **Narrow-width goldens**
  (`test/harness/responsive_width_test.dart`) pin the 320px wrap/collapse
  behavior of the responsive components. Add to both when a new component
  is hairline-heavy or responsive.

### RTL goldens

`expectThemeGoldens` also takes a `directions` axis. The default `{ltr}`
keeps the golden count flat; pass `{ltr, rtl}` (or `{rtl}` alone) to
re-snapshot every theme under `Directionality(rtl)` as
`goldens/<name>[.text].<variant>.rtl.png`. Add `.rtl` goldens only for
components with direction-sensitive geometry — mirrored fills (slider,
progress bar), side accents (side nav, data table selection, tab
dividers), or overlay sides (submenus, overflow menus); direction-neutral
components stay LTR-only. The repo-wide RTL smoke canvas lives in
`test/rtl/carbon_rtl_test.dart` alongside the crash-guard sweep. Carbon
icons do not mirror — only layout does — except the handful upstream
itself flips (pagination carets, the submenu indicator).

### Icon fidelity sweep

Every icon asset is verified on every PR against committed rasterizations of
the **upstream SVGs** (`test/icons/references/`, produced by `rsvg-convert` at
2× scale — external ground truth, not our own renderer). The sweep
(`test/icons/icon_fidelity_sweep_test.dart`) renders each asset through the
production parser/painter and gates on **blurred-coverage mismatch ≤ 0.5%**
(ADR 0001). On failure, our renders are written to `test/icons/failures/` for
side-by-side comparison with the reference; fix the data (or regenerate after
a deliberate upstream bump) rather than loosening the gate.

When bumping the Carbon submodule, follow [docs/ICON_UPDATES.md](docs/ICON_UPDATES.md):
regenerate data + references, review the lockfile diff report, and commit it
all together — CI's drift guard rejects a bump without regeneration.

## Definition of done

A token group or component is done only when it has:

- All variants, sizes, and interaction states Carbon specifies.
- Correct rendering under all four themes (White, Gray 10, Gray 90, Gray 100).
- Accessibility: `Semantics`, focus traversal, keyboard handling.
- **State-matrix widget tests**, **golden tests**, and **semantics tests**.
- `///` documentation on public APIs with at least one example.
- Public symbols exported from `lib/carbide.dart`.

## Commit messages

Use clear, imperative messages (Conventional Commits encouraged:
`feat(button): …`, `tokens(motion): …`, `test: …`, `docs: …`).

## Releasing

Carbide publishes to [pub.dev](https://pub.dev/packages/carbide) automatically
from CI. The repository is a **trusted publisher** (pub.dev's OIDC flow), so
there are no long-lived credentials — a release is just a tag.

1. On `master`, bump `version` in `pubspec.yaml` and add a matching section to
   the top of `CHANGELOG.md`.
2. Commit (`chore(release): vX.Y.Z`) and merge to `master`.
3. Tag the release commit and push the tag:

   ```sh
   git tag vX.Y.Z      # must match the version in pubspec.yaml
   git push origin vX.Y.Z
   ```

The [`Publish to pub.dev`](.github/workflows/publish.yaml) workflow triggers on
any `vX.Y.Z` tag: it first re-runs the format/analyze/test gate, then publishes
with the OIDC token (`dart-lang/setup-dart` sets up the credential, Flutter
provides the SDK, and `dart pub publish --force` does the upload). The tag
pattern is also enforced on the pub.dev trusted-publisher side.

We deliberately do **not** use pub.dev's reusable publish workflow: it checks
out with `submodules: false` and runs a strict dry-run that fails on the
expected "the `documentation/` submodules are excluded from the package"
warning. `--force` publishes through that warning (it is not an error).
The gap that leaves — a real packaging error surfacing only at tag time — is
covered by the **Publish rehearsal** workflow, which runs the strict dry-run
on every PR that touches packaging inputs and fails on anything beyond the
known submodule warning.

**One-time setup (required for the action to work).** Automated publishing only
works once `carbide` is registered as a trusted publisher: on pub.dev →
*Admin → Automated publishing*, enable GitHub Actions for repository
`sunderee/carbide` with tag pattern `v[0-9]+.[0-9]+.[0-9]+*`. Until that
is configured, `dart pub publish` falls back to interactive auth and the action
hangs.

### Publishing manually

The OIDC action is the normal path, but you can always publish by hand from a
clean checkout — useful for the very first release of a new package (pub.dev
can only configure a trusted publisher for a package that already exists):

```sh
dart pub publish        # authenticates via your pub.dev account in a browser
```
