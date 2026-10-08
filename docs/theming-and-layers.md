# Theming & layers

Carbide styling is entirely token-driven. A `CarbonThemeData` resolves Carbon's
semantic tokens (background, text, layer, field, border, support, …) onto the
raw palette for one theme; components read those tokens through `CarbonTheme`.

## The four themes

Carbon defines four themes, two light and two dark. Each is a named constructor
on `CarbonThemeData`:

| Theme      | Brightness | Constructor               |
| ---------- | ---------- | ------------------------- |
| White      | light      | `CarbonThemeData.white`   |
| Gray 10    | light      | `CarbonThemeData.gray10`  |
| Gray 90    | dark       | `CarbonThemeData.gray90`  |
| Gray 100   | dark       | `CarbonThemeData.gray100` |

All four expose the same token names, so a component written against the tokens
looks correct in every theme without change.

```dart
CarbonTheme(
  data: CarbonThemeData.gray100,
  child: const MyApp(),
);
```

### Reading tokens

```dart
final theme = CarbonTheme.of(context);
final bg = theme.background;      // page background
final text = theme.textPrimary;   // primary text color
```

Use `CarbonTheme.maybeOf(context)` when a theme may be absent. The full token
set is documented on `CarbonThemeData` in the API reference.

## Token coverage contract

This contract follows the pinned Carbon **v11.118.0** source. “Complete” means
the family's token values are available and tested; component behaviors and
CSS helpers have separate parity requirements. A missing token outside a
complete family is a documented boundary rather than an implicit promise.

| Upstream family | Coverage | Public surface and boundary |
| --- | --- | --- |
| Color palette, including hover swatches and palette aliases | Complete | Generated `CarbonColors`; 246 named colors. |
| Background, layer and layer-accent, field, border | Complete | Generated `CarbonThemeData`, including every contextual layer level. |
| Text, link, icon, support and focus | Complete | Generated semantic colors, including inverse and disabled values. |
| Interactive, highlight, overlay, shadow, skeleton, toggle | Complete | Generated `CarbonThemeData`; alpha values remain floating point. |
| Button | Complete | All 15 component color tokens. |
| Tag | Complete | All 40 component color tokens, including borders and warm/cool gray. |
| Notification | Complete | All 10 component color tokens. |
| AI aura, border, overlay, popover and skeleton | Complete | All 21 theme tokens used by the shipped AI decorators. |
| Status indicators | Complete | All 10 DTCG tokens, including accessibility background and optional outlines. |
| Content switcher | Complete | All three low-contrast component tokens. The low-contrast widget variant is [separate follow-up work](https://github.com/sunderee/carbide/issues/384); token availability does not imply variant support. |
| Chat | Partial | Six chat-button tokens are generated. The 15 avatar, bubble, header, prompt and shell tokens await chat components that consume them. |
| Syntax highlighting | Out of scope | The 88 syntax tokens are not exposed. Code snippets currently render plain text; highlighted-code support needs its own scope. |
| Font families | Partial | Sans, mono and serif descriptors are available. `sansCondensed` and `sansHebrew` need their own font bundling and typography scope. Bundled fonts cover the weights used by ported styles rather than the entire Plex catalog. |
| Font weights and type scale | Complete | The three Carbon weights and all 23 scale steps. |
| Fixed typography | Complete | 25 fixed styles, including `expressiveHeading01`/`02`, plus 11 named aliases. |
| Responsive typography | Complete | 13 base/breakpoint cascades and 11 fluid aliases in `CarbonFluidTypeStyles`. `resolve` selects cascade steps; continuous CSS interpolation is not implied. |
| Fixed spacing, container sizes, control sizes and icon sizes | Complete | `CarbonSpacing`, `CarbonContainerSize`, `CarbonSize`, `CarbonIconSize`; values have upstream locks. |
| Fluid spacing | Complete | Four generated viewport tokens in `CarbonFluidSpacing`; resolve against a finite viewport width. |
| Grid breakpoints, margins and gutter values | Complete | `CarbonBreakpoint` and grid geometry constants. Grid behaviors, including the narrow column hang, are tracked separately. |
| Border radius | Out of scope | No public radius-token family or configurable v12 radius mode. Existing component-specific radii follow their cited v11 SCSS. |
| Deprecated `layout-01`–`layout-07` aliases | Out of scope | Use the supported spacing scale instead of adding deprecated layout names. |
| Motion durations and easing values | Complete | Six duration tokens and six productive/expressive curves. Upstream surface-dependent motion helpers and CSS transition mixins are separate APIs. |
| Legacy v10 theme aliases | Out of scope | The package exposes current v11 semantic names rather than a second deprecated theme API. |

Theme colors come from `themes/src/dtcg/themes.json` and its five component
files (`button`, `tag`, `notification`, `status`, `content-switcher`). Fixed and
responsive type generators read `type/src/styles.ts`; the fluid-spacing
generator reads `layout/src/dtcg/layout.json`. Each emits value locks alongside
its Dart data. New token families are generated from the reference source,
with source-format regression fixtures that also run without the submodules.

### Component token overrides

Indicators read the generated status tokens, so custom theme colors are applied
to the icon or shape while the caller's status label remains readable:

```dart
final custom = CarbonThemeData.gray100.copyWith(
  statusBlue: CarbonColors.cyan40,
  statusGreen: CarbonColors.teal40,
);
```

`statusOrangeOutline` and `statusYellowOutline` are `null` on the built-in dark
themes because Carbon does not define those outlines there. The existing
`copyWith` convention remains: a null argument retains its current value. Pass
a transparent color to suppress a light outline. Theme interpolation preserves
exact endpoints, including an absent outline, and blends colors in between.

New status/content-switcher constructor parameters are optional. Existing raw
custom-theme declarations remain valid; omitted component colors use generated
light/dark defaults based on `brightness`. Built-in themes supply all their
values explicitly. Custom themes must still verify their own contrast pairs.

### Viewport spacing

```dart
final viewportWidth = MediaQuery.sizeOf(context).width;
final gap = CarbonFluidSpacing.spacing02.resolve(viewportWidth); // 2vw
```

The four values represent 0, 2, 5 and 10 percent of viewport width. They do not
measure a parent column. Negative, infinite or NaN widths are rejected; finite
large widths resolve without overflowing an intermediate multiplication.

## Increased-contrast accessibility

`CarbonTheme.of(context)` and `maybeOf` read the nearest
`MediaQuery.highContrast` preference and return
`CarbonThemeData.highContrast(base)` when it is enabled. Readers rebuild when
the preference changes; disabling it restores the original base instance.
This also respects a local `MediaQuery` below the theme. With no media query,
the supplied theme is used as-is. `CarbonTheme.data` remains the supplied base;
application widgets should read tokens through `of`.

The decision for #317 is a derived theme at the common lookup point. This keeps
the four upstream theme definitions intact and applies the same policy to all
components and layer levels. A separate extension would require each component
to decide whether to consult it. Derivation is cached by base instance and is
idempotent, so repeated lookup does not allocate a new token set.

The adaptation uses opaque black or white boundaries and focus indicators,
including selected and disabled tile outlines. Inverse surfaces receive the
opposite ink, and inset focus rings retain two contrasting strokes. Inactive
labels and icons become opaque; dark disabled-button fills become darker so
those labels remain readable. Secondary text, helpers and placeholders become
opaque too, including the dark third layer where upstream secondary inks fall
below the text floor. Backgrounds, contextual layer surfaces, brand colors,
enabled control fills and validation colors retain their base values.

The contrast sweep covers the derived themes without the upstream exceptions:
normal text pairs meet 4.5:1 and meaningful boundaries and focus indicators meet
3:1. It also checks inactive labels at 4.5:1 as an explicit Carbide policy,
although WCAG exempts inactive controls. Disabled semantics, activation and
focus traversal remain those of the component. Color alone does not make a
control enabled. See [WCAG non-text contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).

`AnimatedCarbonTheme` applies theme changes instantly under increased contrast,
including a transition already in progress, so intermediate color mixtures do
not weaken the checked endpoint boundaries. Platform support follows Flutter's
`MediaQuery.highContrast`; Flutter web maps the browser's `forced-colors: active`
preference to this property. Browser or OS settings that do not set the property
do not enable the adaptation. This is a token policy, rather than an attempt to
copy a system-defined forced-color palette.

Applications can explicitly enable the adaptation independently of the OS:

```dart
CarbonTheme(
  data: CarbonThemeData.highContrast(CarbonThemeData.gray100),
  child: const MyApp(),
);
```

Custom themes preserve their surfaces and brand choices, and must keep those
surfaces consistent with their declared brightness and verify their own
contrast pairs. The sweep covers the built-in themes and the documented pairs;
it does not guarantee arbitrary consumer colors or every status-color pairing.

Carbon's similarly named `CarbonPopover.highContrast` and
`CarbonTagType.highContrast` select inverse surfaces. They are independent of
the OS preference. Tooltips and copy-button feedback deliberately use that
inverse popover variant; their tokens still receive the theme adaptation.

## Animating theme changes

`AnimatedCarbonTheme` is an implicitly-animated `CarbonTheme`: when its `data`
changes it lerps every token to the new theme over the given `duration`, so a
light↔dark switch crossfades instead of snapping.

```dart
AnimatedCarbonTheme(
  data: isDark ? CarbonThemeData.gray100 : CarbonThemeData.white,
  duration: const Duration(milliseconds: 150),
  curve: Curves.easeInOut,
  child: const MyApp(),
);
```

Drive `isDark` from whatever state you keep (a `ValueNotifier`, a
`ChangeNotifier`, etc.) and rebuild — the animation is automatic.

## Layers

Carbon's contextual layering model keeps stacked surfaces — a card on the page,
a card inside that card, a modal over content — visually distinct. Each layer
re-points the contextual tokens (`layer`, `field`, the subtle borders, and their
hover/active/selected variants) one step further from the page background.

Wrap a subtree in `CarbonLayer` to move it up one layer:

```dart
CarbonLayer(
  child: MyCard(),
);
```

Layers are numbered `CarbonLayer.minLevel` (0, the implicit level of root
content) through `CarbonLayer.maxLevel` (2) — Carbon's layer-01 through
layer-03. Nesting beyond the maximum simply stays at the top layer.

- **Increment (default):** `CarbonLayer(child: …)` steps one level up from the
  ancestor.
- **Explicit level:** `CarbonLayer(level: 2, child: …)` pins a specific level.
- **Paint the background:** `CarbonLayer(withBackground: true, child: …)` fills
  the layer's `layerBackground` token behind the child, matching the upstream
  `withBackground` behavior.

### Reading the active layer

Inside a `CarbonLayer`, resolve the layer-aware tokens with `CarbonLayer.of`:

```dart
final tokens = CarbonLayer.of(context);
return ColoredBox(color: tokens.layer, child: ...);
```

`CarbonLayer.levelOf(context)` returns just the current level (without resolving
tokens), which is `minLevel` when there is no `CarbonLayer` ancestor.

## See also

- [Getting started](getting-started.md)
- [Architecture](ARCHITECTURE.md) — how foundations, theme, and components layer
  up internally.
