# Carbide

**An unofficial Flutter port of the IBM Carbon Design System.**

Carbide brings the [IBM Carbon Design System][carbon] to Flutter, built
**on Flutter's base widgets and SDK rendering libraries** — no Material, no
Cupertino in library code. Tokens and component behavior are ported from
Carbon's pinned reference sources.

[**▶ Explore the live gallery**](https://sunderee.github.io/carbide/) —
every component, every theme, with live controls and copyable code.

![The Carbide gallery overview](https://raw.githubusercontent.com/sunderee/carbide/master/docs/images/overview.png)

## Install

```sh
flutter pub add carbide
```

Carbide bundles the IBM Plex fonts, so no extra font setup is required.

## Quick start

Carbide has no app-level widget of its own: drop a `CarbonTheme` above your
widget tree and build with `Carbon*` components. Components read the active
theme's tokens through `CarbonTheme.of(context)`.

```dart
import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CarbonTheme(
      data: CarbonThemeData.white,
      child: WidgetsApp(
        color: CarbonColors.blue60,
        builder: (context, _) => const Home(),
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CarbonTheme.of(context);
    return ColoredBox(
      color: theme.background,
      child: Center(
        child: CarbonButton(
          label: 'Submit',
          onPressed: () {},
        ),
      ),
    );
  }
}
```

You can equally place `CarbonTheme` inside an existing `MaterialApp` or
`WidgetsApp` — it is just an `InheritedWidget`.

## Theming

Carbon ships **four themes** — White, Gray 10 (light) and Gray 90, Gray 100
(dark) — each mapping the same set of semantic tokens onto the palette. Select
one with a named constructor on `CarbonThemeData`:

```dart
CarbonTheme(data: CarbonThemeData.white,   child: ...);
CarbonTheme(data: CarbonThemeData.gray10,  child: ...);
CarbonTheme(data: CarbonThemeData.gray90,  child: ...);
CarbonTheme(data: CarbonThemeData.gray100, child: ...);
```

Use **`AnimatedCarbonTheme`** to crossfade tokens when the theme changes,
exactly like Flutter's implicit animations:

```dart
AnimatedCarbonTheme(
  data: isDark ? CarbonThemeData.gray100 : CarbonThemeData.white,
  duration: const Duration(milliseconds: 150),
  child: ...,
);
```

**`CarbonLayer`** implements Carbon's contextual layering model: wrapping a
subtree steps its `layer`, `field`, and border tokens up one level so nested
surfaces (cards on cards, modals over content) stay distinguishable.

```dart
CarbonLayer(
  child: MyCard(), // its descendants now read the next layer's tokens
);
```

See the [theming & layers guide](docs/theming-and-layers.md) for the full token
set and the layering rules.

![A component demo on the Gray 90 theme](https://raw.githubusercontent.com/sunderee/carbide/master/docs/images/button_dark.png)

## Component catalog

The [checked Carbon parity matrix](docs/carbon-parity.md) distinguishes present,
consolidated, partial, deferred and platform-specific APIs, with a fidelity tier
and explicit boundaries. React `Fluid*` names map to the existing picker/field
APIs and `CarbonFluidForm`; React providers and CSS subgrid are separate
platform/architecture decisions. The matrix does not promise full variant parity.

Components are organized in tiers, mirroring the gallery's navigation.

**Foundations** — color tokens, typography, spacing/layout, icons, motion.

**Tier A · Foundational** — Button, Tag, Link, Tile, Loading, Progress bar,
List, Stack, Heading.

**Tier B · Forms** — Text input, Text area, Number input, Select, Search,
Checkbox, Radio button, Toggle, Slider.

**Tier C · Composite** — Dropdown, Combo box, Multi-select, Tooltip, Toggletip,
Overflow menu, Tabs, Accordion, Content switcher, Breadcrumb, Pagination, Modal,
Notification, Progress indicator, Structured list.

**Tier D · Complex & data** — Data table, Date picker, Time picker, File
uploader, Tree view, Page header, and the UI Shell (header, side nav, switcher).

![The Carbon data table on the White theme](https://raw.githubusercontent.com/sunderee/carbide/master/docs/images/data_table.png)

## Accessibility & testing

The [checked platform support matrix](docs/platform-support.md) distinguishes
platform targets, PR gates, scheduled host/browser canaries and native-device
evidence, including fonts, golden authority, input, target sizes, contrast and
localization boundaries.

See the [semantics policy](docs/accessibility.md) for static tags, nested lists,
code snippets and application-supplied context.

- **Accessible by construction.** Components expose Carbon's semantics — roles,
  labels, focus order, and a custom-painted focus ring — and target WCAG AA
  contrast.
- **Platform preferences.** Decorative motion follows reduced motion, and
  [increased contrast](docs/theming-and-layers.md#increased-contrast-accessibility)
  strengthens boundaries, focus indicators and inactive labels centrally.
- **Tested to a high bar.** Nothing ships without tests: each token group and
  component lands with state-matrix widget tests, golden tests against the
  Carbon spec, and semantics/accessibility tests. Every public API is
  documented (enforced in CI), and 33 curated default stories are rendered beside committed Carbon
  Storybook references. Their 24×24 luminance-grid comparisons are a coarse
  drift gate, strengthened by control-size, token-colour and state assertions.
  They do not establish pixel identity or cover every component variant.

## Principles

1. **Base widgets only.** No `package:flutter/material.dart` or
   `package:flutter/cupertino.dart` in `lib/`. Theming, state, and styling are
   built from scratch on the widgets layer.
2. **Token-driven.** Components consume design tokens (color, type, layout,
   motion) resolved per theme — White, Gray 10, Gray 90, Gray 100 — exactly as
   Carbon defines them.
3. **Tested to a high bar.** See above.
4. **Strict Dart.** The analyzer is configured to fail on a large set of lints
   (see `analysis_options.yaml`). No shortcuts.

## Documentation

- [Getting started](docs/getting-started.md)
- [Theming & layers](docs/theming-and-layers.md)
- [Architecture](docs/ARCHITECTURE.md)
- Patterns: [Forms](docs/patterns/forms.md) ·
  [Page headers](docs/patterns/page-header.md) ·
  [Progress indicators](docs/patterns/progress-indicator.md) ·
  [Loading](docs/patterns/loading.md) ·
  [Notifications](docs/patterns/notification.md) ·
  [Status indicators](docs/patterns/status-indicator.md)
- [Contributing](CONTRIBUTING.md)

## Licensing

Carbide is licensed under the **[Apache License, Version 2.0](LICENSE)** —
the same license as the IBM Carbon Design System. You may use it freely in
open-source and proprietary applications under those terms.

Design tokens are derived from Carbon and the project bundles the SIL OFL 1.1
licensed IBM Plex fonts; see [`NOTICE`](NOTICE) for attribution.

## Trademark

Carbide is **not affiliated with, endorsed by, or sponsored by IBM**. "IBM",
"Carbon", and "IBM Plex" are trademarks of International Business Machines
Corporation, used here only to identify the upstream design system.

[carbon]: https://carbondesignsystem.com
