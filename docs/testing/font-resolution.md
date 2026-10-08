# Consumer font resolution

Carbide bundles seven IBM Plex font files: Sans Light/Regular/SemiBold, Mono
Regular/SemiBold and Serif Light/Regular. Flutter registers dependency fonts
under `packages/carbide/` in the consuming application's font manifest.
Built-in fixed and fluid styles supply `package: CarbonFontFamily.package`;
handwritten AI-label and pagination-nav styles do the same.

The family descriptors retain their plain names. For a custom style, use both
the descriptor and its package:

```dart
const TextStyle(
  fontFamily: CarbonFontFamily.mono,
  package: CarbonFontFamily.package,
)
```

Flutter's [`TextStyle` font documentation](https://api.flutter.dev/flutter/painting/TextStyle-class.html)
describes this package namespace. Applications using built-in Carbon styles
need no extra font declaration or initialization. Custom application fonts and
`CarbonFluidText` overrides retain their own family/fallback names.

`example/test/font_dependency_test.dart` compares style names with the actual
consumer `FontManifest.json`. It does not treat the test font loader's extra
in-memory aliases as evidence. The native browser contract
`example/integration_test/font_resolution_test.dart` uses no `FontLoader`:
it compares rendered Sans/Mono/Serif glyph advances with an independent reader
of the bundled TTF `head`, `cmap`, `hhea` and `hmtx` tables. A fallback font can
render nonblank text while failing these measurements.

The VM golden setup registers plain and package-qualified aliases so both
root-package tests and consumer-style names can render Plex. Those goldens are
Linux-authoritative. Chrome widget tests use placeholder fonts; consumer font
resolution is proved separately in the real browser job. Do not infer correct
consumer font registration from a VM golden or a non-zero text rectangle.

Before 0.5.0, most fixed styles used plain family names. VM setup hid the
consumer fallback by registering those aliases. The corrected namespace makes
normal consumers use the intended Plex glyphs; their measured text widths can
change. Recheck constrained layouts when adopting the release. The public
family descriptors remain unchanged.
