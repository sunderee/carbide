# Locale glyph fixtures

These SIL OFL fixtures provide real Arabic and Japanese glyphs to localized
VM/golden tests. Flutter's test font registry otherwise falls back to missing-
glyph boxes for these scripts. They are not runtime assets and `test/` is
excluded from the published package.

`tool/generate_locale_test_fonts.py` subsets IBM Plex Sans Arabic and IBM Plex
Sans JP Regular at commit `763c36ef9117782905ae010056dfbe8fd2653a25`, preserves
copyright/license records, and renames the derived fonts to `Carbide Test
Arabic` and `Carbide Test Japanese`. `manifest.json` records source paths,
source/output SHA-256 hashes, code points and the FontTools version. `OFL.txt`
contains the upstream license. No original font family name is reused.

Regenerate from the repository root with Python and `fonttools==4.66.1`:

```sh
python3 tool/generate_locale_test_fonts.py
```

Only localized date tests load these faces from disk and specify them as font
fallbacks. Web widget tests retain their established behavioral-only font
policy; release browser validation waits for the engine's real fallback fonts.
