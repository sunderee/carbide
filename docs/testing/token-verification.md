# Checking generated Carbon tokens

Every `generate_carbon_*` script supports `--check`. It reads the pinned Carbon
checkout, prepares its normal output, formats Dart artifacts in a temporary
directory using the package's declared language floor, and compares the result
with the committed files. A difference, missing output or obsolete generated
bucket fails without modifying the repository. Ordinary generation uses the
same deferred output and formatting path, then writes the artifacts.

The checks cover palette colors, semantic themes, fixed/fluid typography, fixed
and fluid layout, grid breakpoints, motion durations/curves, icons and pictograms.
Fixed layout and motion retain the surrounding handwritten API helpers; their
constant declarations must exactly match the upstream token family. Unknown
units, breakpoint expressions, source structures or public-family additions
fail for review.

Run all checks with Flutter's `dart` on `PATH`:

```sh
git submodule update --init documentation/carbon
for family in colors themes type fluid_type layout motion icons pictograms; do
  python3 "tool/generate_carbon_${family}.py" --check
done
python3 tool/check_upstream_colors.py
```

The Carbon reference generation workflow fetches only the Carbon submodule and
runs this on reference/generator/token PR changes. Normal CI also runs the guard
regressions without requiring a reference checkout. Icon/pictogram lock metadata
records the source commit, so changing the Carbon gitlink requires relocking even
when the artwork itself did not change. Reference-image freshness is checked
separately from token generation.

Regeneration consistency cannot establish that a parser is correct: the same
parser can generate matching wrong implementation and test values. The color
check independently reads Carbon's committed JavaScript public-API snapshot,
using no generator, DTCG parser or generated Dart test. It compares all flat color
exports with Dart constants, including aliases and hover colors. Carbon produces
that snapshot through its own build/test pipeline; this comparison catches our
parser mistakes but cannot prove the upstream snapshot itself is current.

Binary golden/reference capture and locale-font fixture tools have separate
reviewed generation workflows. They do not generate the Carbon token families
checked here. Linux remains the golden authority.
