# Carbide gallery

The gallery app for [Carbide](../README.md) demonstrates cataloged families and
compositions across all four Carbon themes. Component pages provide live
controls and generated, compiled examples with clipboard copy and expansion.
The [coverage policy](../docs/testing/gallery-coverage.md) records explicit
composition/nonvisual exemptions rather than claiming a page for every API.

It is deployed to the web here:
**<https://sunderee.github.io/carbide/>**

## Run it locally

```sh
cd example
flutter pub get
flutter run            # any device
flutter run -d chrome  # in the browser
```

## What's inside

- `lib/src/catalog.dart` — the tier grouping shown in the side navigation.
- `lib/src/pages/` — one page per component, built on the shared `DemoScaffold`
  (heading, live preview, interactive controls, code snippet).
- `test/` — smoke tests plus the screenshot and contact-sheet generators used
  for visual review (see `screenshots_test.dart` and `contact_sheet_test.dart`).

The gallery is an integration surface: CI renders every registered route and
checks displayed examples, while component and native contracts validate the
specific interactions. A default demo alone does not prove all-variant parity.
