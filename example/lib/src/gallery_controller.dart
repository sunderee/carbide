// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// A named Carbon theme the gallery can switch between.
class GalleryTheme {
  /// Creates a named theme entry pairing a [label] with its [data].
  const GalleryTheme(this.label, this.data);

  /// The display name shown in the theme switcher.
  final String label;

  /// The token set applied when this theme is active.
  final CarbonThemeData data;
}

/// The four built-in Carbon themes, in the order the switcher cycles them.
final List<GalleryTheme> kGalleryThemes = <GalleryTheme>[
  GalleryTheme('White', CarbonThemeData.white),
  GalleryTheme('Gray 10', CarbonThemeData.gray10),
  GalleryTheme('Gray 90', CarbonThemeData.gray90),
  GalleryTheme('Gray 100', CarbonThemeData.gray100),
];

/// Holds the gallery's mutable UI state: the active theme and whether the side
/// navigation is expanded.
class GalleryController extends ChangeNotifier {
  int _themeIndex = 0;
  bool _navExpanded = true;

  /// The active theme.
  GalleryTheme get theme => kGalleryThemes[_themeIndex];

  /// Whether the active theme is one of the two dark themes.
  bool get isDark => _themeIndex >= 2;

  /// Whether the side navigation is expanded (vs. collapsed to its rail).
  bool get navExpanded => _navExpanded;

  /// Advances to the next theme, wrapping around.
  void cycleTheme() {
    _themeIndex = (_themeIndex + 1) % kGalleryThemes.length;
    notifyListeners();
  }

  /// Selects a theme by index.
  void selectTheme(int index) {
    if (index != _themeIndex && index >= 0 && index < kGalleryThemes.length) {
      _themeIndex = index;
      notifyListeners();
    }
  }

  /// Toggles the side navigation between expanded and the rail.
  void toggleNav() {
    _navExpanded = !_navExpanded;
    notifyListeners();
  }
}

/// Exposes the [GalleryController] to the widget subtree.
class GalleryScope extends InheritedNotifier<GalleryController> {
  /// Creates a scope exposing [controller] to the [child] subtree.
  const GalleryScope({
    required GalleryController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The nearest controller; throws if there is none.
  static GalleryController of(BuildContext context) {
    final GalleryScope? scope = context
        .dependOnInheritedWidgetOfExactType<GalleryScope>();
    assert(scope != null, 'No GalleryScope found in context');
    return scope!.notifier!;
  }
}
