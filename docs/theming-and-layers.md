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
