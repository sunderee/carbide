// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import '../foundations/motion.dart';
import 'carbon_theme_data.dart';

/// Provides a [CarbonThemeData] to its descendants.
///
/// Wrap a subtree — usually the whole app — in a `CarbonTheme` so widgets below
/// can read the active theme with [CarbonTheme.of]. Use [AnimatedCarbonTheme]
/// to transition between themes smoothly.
///
/// Token lookup automatically derives [CarbonThemeData.highContrast] when the
/// nearest [MediaQuery] requests high contrast. Readers rebuild when that
/// preference changes, including overrides below this theme.
///
/// ```dart
/// CarbonTheme(
///   data: CarbonThemeData.gray100,
///   child: const MyApp(),
/// );
/// ```
class CarbonTheme extends InheritedWidget {
  /// Creates a theme that exposes [data] to [child] and its descendants.
  const CarbonTheme({super.key, required this.data, required super.child});

  /// The base tokens supplied by the application.
  ///
  /// Descendants should use [of] to receive the high-contrast adaptation.
  final CarbonThemeData data;

  /// The [CarbonThemeData] from the nearest enclosing [CarbonTheme].
  ///
  /// Asserts that a [CarbonTheme] is present; use [maybeOf] when it might not
  /// be. The caller depends on the theme and the nearest high-contrast
  /// preference and rebuilds when either changes.
  static CarbonThemeData of(BuildContext context) {
    final CarbonThemeData? data = maybeOf(context);
    assert(
      data != null,
      'No CarbonTheme found in context. Wrap your app in a CarbonTheme '
      '(or AnimatedCarbonTheme).',
    );
    return data!;
  }

  /// The adapted data from the nearest [CarbonTheme], or null if none.
  ///
  /// High contrast is disabled when no [MediaQuery] is present. The caller
  /// depends only on that media property, rather than all media properties.
  static CarbonThemeData? maybeOf(BuildContext context) {
    final data = context
        .dependOnInheritedWidgetOfExactType<CarbonTheme>()
        ?.data;
    if (data == null) return null;
    return (MediaQuery.maybeHighContrastOf(context) ?? false)
        ? CarbonThemeData.highContrast(data)
        : data;
  }

  @override
  bool updateShouldNotify(CarbonTheme oldWidget) => data != oldWidget.data;
}

/// A [CarbonTheme] that animates token changes over [duration].
///
/// Swapping [data] interpolates every token via [CarbonThemeData.lerp], so a
/// theme switch (for example light to dark) transitions smoothly rather than
/// snapping. The crossfade is decorative: when the platform requests reduced
/// motion or high contrast, the new theme applies instantly. High contrast
/// avoids intermediate surface colors weakening otherwise-visible boundaries.
class AnimatedCarbonTheme extends ImplicitlyAnimatedWidget {
  /// Creates an animated theme around [child].
  const AnimatedCarbonTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve,
    required super.duration,
    super.onEnd,
  });

  /// The target theme to animate towards.
  final CarbonThemeData data;

  /// The subtree that receives the animated theme.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedCarbonTheme> createState() =>
      _AnimatedCarbonThemeState();
}

class _AnimatedCarbonThemeState
    extends AnimatedWidgetBaseState<AnimatedCarbonTheme> {
  _CarbonThemeDataTween? _data;

  void _syncDuration() {
    // Intermediate colors can weaken contrast even when both endpoints pass.
    controller.duration = (MediaQuery.maybeHighContrastOf(context) ?? false)
        ? Duration.zero
        : carbonDuration(context, widget.duration);
    if (controller.duration == Duration.zero && controller.isAnimating) {
      // A crossfade already in flight was started with the pre-clamp
      // duration; jump it to its end state.
      controller.value = controller.upperBound;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDuration();
  }

  @override
  void didUpdateWidget(AnimatedCarbonTheme oldWidget) {
    // The base class resets the controller duration from widget.duration;
    // re-clamp it afterwards.
    super.didUpdateWidget(oldWidget);
    _syncDuration();
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (dynamic value) => _CarbonThemeDataTween(begin: value as CarbonThemeData),
    ) as _CarbonThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) {
    return CarbonTheme(data: _data!.evaluate(animation), child: widget.child);
  }
}

class _CarbonThemeDataTween extends Tween<CarbonThemeData> {
  // `end` is assigned by the animation framework after construction.
  _CarbonThemeDataTween({super.begin});

  @override
  CarbonThemeData lerp(double t) => CarbonThemeData.lerp(begin!, end!, t);
}
