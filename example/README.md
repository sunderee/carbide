# Carbide gallery

The gallery app for [Carbide](../README.md) — a browsable showcase of every
component across all four Carbon themes, with live controls and copyable code
for each one.

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

This gallery doubles as the project's integration surface: if a component can be
demoed here, it works.
