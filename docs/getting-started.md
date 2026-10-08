# Getting started

This guide takes you from an empty Flutter app to a Carbide screen.

## 1. Add the dependency

```sh
flutter pub add carbide
```

Carbide bundles the IBM Plex font families (Sans, Mono and Serif) used by Carbon, so
there is no font setup to do.

## 2. Import the library

A single barrel exports everything — tokens, themes, and components:

```dart
import 'package:carbide/carbide.dart';
```

Carbide uses Flutter base widgets and SDK rendering/services libraries, and never imports Material or
Cupertino. You will typically pair it with `import
'package:flutter/widgets.dart';` for `StatelessWidget`, `runApp`, and friends.

## 3. Provide a theme

Carbide reads styling from the nearest `CarbonTheme`, an `InheritedWidget` that
carries a `CarbonThemeData`. Place one above the part of the tree that uses
Carbide — at the root of the app is the common case.

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
```

`CarbonTheme` is just an `InheritedWidget`, so it composes with whatever app
shell you already use — drop it inside an existing `MaterialApp` or `WidgetsApp`
if you are adding Carbide to part of a larger app.

## 4. Build with components and tokens

Components style themselves from the active theme. Read tokens directly with
`CarbonTheme.of(context)` when you need them for your own widgets:

```dart
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

A `null` `onPressed` renders the disabled state — the same convention Flutter's
own buttons follow.

## Next steps

- [Theming & layers](theming-and-layers.md) — the four themes,
  `AnimatedCarbonTheme`, and `CarbonLayer`.
- [Live gallery](https://sunderee.github.io/carbide/) — cataloged component
  families and compositions with live controls and compiled, copyable examples.
- [API reference](https://pub.dev/documentation/carbide/latest/) — the published
  package API. Run `dart doc` for the current checkout, which may be newer.
