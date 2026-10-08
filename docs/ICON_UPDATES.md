# Updating icons when Carbon changes

Icons change upstream over time. Carbide detects exactly what changed with a
**lockfile**, not changelog reading: `tool/carbon_icons.lock.json` records the
Carbon submodule commit the data was generated from, a content hash per icon
asset, and the deprecation list. CI refuses to merge a submodule bump whose
lockfile was not regenerated (the drift guard compares the recorded commit to
the gitlink — no submodule checkout needed).

## The workflow

1. **Bump the submodule** (its own commit, as usual):

   ```sh
   git submodule update --remote --merge -- documentation/carbon
   ```

2. **Regenerate tokens, data, references, and the lockfiles** (icons and pictograms
   share the workflow and the drift guard):

   ```sh
   python3 tool/generate_carbon_colors.py
   python3 tool/generate_carbon_type.py
   python3 tool/generate_carbon_fluid_type.py
   python3 tool/generate_carbon_layout.py
   python3 tool/generate_carbon_themes.py
   python3 tool/test_carbon_generation.py
   python3 tool/generate_carbon_icons.py        # data + lockfile + diff report
   python3 tool/generate_icon_references.py     # upstream rasters (needs rsvg-convert)
   python3 tool/generate_carbon_pictograms.py
   python3 tool/generate_pictogram_references.py
   dart format lib test
   ```

   Carbon 11.118 uses DTCG JSON for colors and themes. The generators read
   those authoritative files directly, preserve palette aliases and the
   ported theme subset, and resolve per-theme opacity and token references.
   `test_carbon_generation.py` runs without a submodule checkout in CI.
   Re-capture Storybook references with `tool/fidelity/capture.sh` after a bump.
   Regenerate text goldens through the Linux workflow in `CONTRIBUTING.md`.

   The generator prints a categorized **diff report** against the previous
   lockfile: `added` / `modified` / `removed` / `newlyDeprecated` /
   `undeprecated`, per asset (`<name>_<size>`). If the bump didn't touch the
   icons package, it prints `icon diff: no changes` and only the lockfile's
   recorded commit moves.

3. **Review with the tests**:

   - `flutter test test/icons/` — the structural locks (icon/asset counts)
     will fail if counts moved; update them **consciously** to the new
     numbers from the generator's summary line.
   - The **fidelity sweep** verifies every added/modified asset against its
     fresh upstream raster automatically. A failure means our pipeline can't
     reproduce a new upstream construct — fix `tool/carbon_svg.py`, don't
     loosen the gate.
   - **Removed** icons fail compilation wherever referenced; delete their
     Dart symbols (the generator already dropped them). For published
     releases, prefer a deprecation cycle before removal.

4. **Commit everything together** — submodule bump, regenerated data,
   references, lockfile, and any count updates — so the drift guard passes
   and the PR diff *is* the icon update review.

## Guarantees

- **No silent drift**: CI fails any PR where the pinned submodule and the
  lockfile disagree (`tool/check_icons_lock.py`).
- **No unverified artwork**: every asset in the repo is compared against its
  upstream raster on every PR (`test/icons/icon_fidelity_sweep_test.dart`).
- **Deterministic generation**: two runs from the same submodule produce
  byte-identical output (after `dart format`).
