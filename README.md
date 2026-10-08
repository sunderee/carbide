# Carbide

**An unofficial Flutter port of the IBM Carbon Design System.**

Carbide brings the [IBM Carbon Design System][carbon] to Flutter, built
**on Flutter's base widgets and SDK rendering libraries** — no Material, no
Cupertino in library code. Tokens and component behavior are ported from
Carbon's pinned reference sources.

[**▶ Explore the live gallery**](https://sunderee.github.io/carbide/) —
cataloged families and compositions in four themes, with live controls and compiled clipboard examples.

<!-- carbide-readme:coverage:start -->
The checked catalog contains **67 routes**. The public barrel exposes **279 declarations**, including **170 widget classes** across **63 source families**. These counts include composition and inherited-scope types, not separate independent controls. The [API-to-gallery policy](docs/testing/gallery-coverage.md) records live references and reasoned composition/nonvisual exemptions.
<!-- carbide-readme:coverage:end -->

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

<!-- carbide-readme:catalog:start -->
| Gallery category | Pages | Public widget declarations mapped |
| --- | --- | --- |
| Foundations | [Color tokens](https://sunderee.github.io/carbide/#/components/colors), [Typography](https://sunderee.github.io/carbide/#/components/typography), [Fluid typography](https://sunderee.github.io/carbide/#/components/fluid-type), [Spacing](https://sunderee.github.io/carbide/#/components/spacing), [Icons](https://sunderee.github.io/carbide/#/components/icons), [Pictograms](https://sunderee.github.io/carbide/#/components/pictograms), [Motion](https://sunderee.github.io/carbide/#/components/motion) | 5 |
| Foundational | [Button](https://sunderee.github.io/carbide/#/components/button), [Copy button](https://sunderee.github.io/carbide/#/components/copy-button), [Code snippet](https://sunderee.github.io/carbide/#/components/code-snippet), [Icon button](https://sunderee.github.io/carbide/#/components/icon-button), [Indicators](https://sunderee.github.io/carbide/#/components/indicators), [Aspect ratio](https://sunderee.github.io/carbide/#/components/aspect-ratio), [Grid](https://sunderee.github.io/carbide/#/components/grid), [Skeletons](https://sunderee.github.io/carbide/#/components/skeletons), [Tag](https://sunderee.github.io/carbide/#/components/tag), [Link](https://sunderee.github.io/carbide/#/components/link), [Tile](https://sunderee.github.io/carbide/#/components/tile), [Loading](https://sunderee.github.io/carbide/#/components/loading), [Progress bar](https://sunderee.github.io/carbide/#/components/progress-bar), [List](https://sunderee.github.io/carbide/#/components/list), [Stack](https://sunderee.github.io/carbide/#/components/stack), [Heading](https://sunderee.github.io/carbide/#/components/heading) | 61 |
| Forms | [Text input](https://sunderee.github.io/carbide/#/components/text-input), [Text area](https://sunderee.github.io/carbide/#/components/text-area), [Number input](https://sunderee.github.io/carbide/#/components/number-input), [Select](https://sunderee.github.io/carbide/#/components/select), [Search](https://sunderee.github.io/carbide/#/components/search), [Checkbox](https://sunderee.github.io/carbide/#/components/checkbox), [Radio button](https://sunderee.github.io/carbide/#/components/radio), [Toggle](https://sunderee.github.io/carbide/#/components/toggle), [Slider](https://sunderee.github.io/carbide/#/components/slider) | 13 |
| Composite | [AI label](https://sunderee.github.io/carbide/#/components/ai-label), [Chat button](https://sunderee.github.io/carbide/#/components/chat-button), [Contained list](https://sunderee.github.io/carbide/#/components/contained-list), [Context menu](https://sunderee.github.io/carbide/#/components/context-menu), [Pagination nav](https://sunderee.github.io/carbide/#/components/pagination-nav), [Dropdown](https://sunderee.github.io/carbide/#/components/dropdown), [Combo box](https://sunderee.github.io/carbide/#/components/combo-box), [Multi-select](https://sunderee.github.io/carbide/#/components/multi-select), [Tooltip](https://sunderee.github.io/carbide/#/components/tooltip), [Toggletip](https://sunderee.github.io/carbide/#/components/toggletip), [Overflow menu](https://sunderee.github.io/carbide/#/components/overflow-menu), [Tabs](https://sunderee.github.io/carbide/#/components/tabs), [Accordion](https://sunderee.github.io/carbide/#/components/accordion), [Content switcher](https://sunderee.github.io/carbide/#/components/content-switcher), [Breadcrumb](https://sunderee.github.io/carbide/#/components/breadcrumb), [Pagination](https://sunderee.github.io/carbide/#/components/pagination), [Modal](https://sunderee.github.io/carbide/#/components/modal), [Dialog](https://sunderee.github.io/carbide/#/components/dialog), [Notification](https://sunderee.github.io/carbide/#/components/notification), [Progress indicator](https://sunderee.github.io/carbide/#/components/progress-indicator), [Structured list](https://sunderee.github.io/carbide/#/components/structured-list) | 42 |
| Complex & data | [Data table](https://sunderee.github.io/carbide/#/components/data-table), [Date picker](https://sunderee.github.io/carbide/#/components/date-picker), [Time picker](https://sunderee.github.io/carbide/#/components/time-picker), [File uploader](https://sunderee.github.io/carbide/#/components/file-uploader), [Tree view](https://sunderee.github.io/carbide/#/components/tree-view), [Page header](https://sunderee.github.io/carbide/#/components/page-header) | 12 |
| Compositions | [Form](https://sunderee.github.io/carbide/#/components/form), [Button set](https://sunderee.github.io/carbide/#/components/button-set), [Menu](https://sunderee.github.io/carbide/#/components/menu), [Popover](https://sunderee.github.io/carbide/#/components/popover), [Table toolbar](https://sunderee.github.io/carbide/#/components/table-toolbar), [UI shell](https://sunderee.github.io/carbide/#/components/ui-shell), [Layers and breakpoints](https://sunderee.github.io/carbide/#/components/layers-and-breakpoints), [Fluid pickers](https://sunderee.github.io/carbide/#/components/fluid-pickers) | 41 |

A widget can map to several categories; these per-category counts are not additive. Mappings include composed variants rather than implying a dedicated page for each declaration. Component pages provide clipboard copy/expand controls and source-derived functional examples; CI compiles their actual displayed code and reviewed Button configurations.
<!-- carbide-readme:catalog:end -->

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
- **Checked contracts.** State, focus, semantics, lifetime and scaling tests
  accompany component changes. Public API documentation, inventories and
  generated artifacts are checked in CI.

<!-- carbide-readme:fidelity:start -->
**33 curated default stories** compare selected families with committed upstream Carbon Storybook images. Their 24×24 luminance-grid scores, control dimensions, token colors and state contracts detect reviewed drift; they do not establish pixel identity or all-variant coverage. Other family specimens use Linux golden regression baselines and behavior/accessibility tests. The [parity matrix](docs/carbon-parity.md) records these distinct tiers and implementation boundaries.
<!-- carbide-readme:fidelity:end -->

## Principles

1. **No Material or Cupertino.** No `package:flutter/material.dart` or
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
