// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import 'carbon_theme_data.dart';

/// Provides a [CarbonThemeData] to its descendants.
///
/// Wrap a subtree — usually the whole app — in a `CarbonTheme` so widgets below
/// can read the active theme with [CarbonTheme.of]. Use [AnimatedCarbonTheme]
/// to transition between themes smoothly.
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

  /// The theme tokens provided to descendants.
  final CarbonThemeData data;

  /// The [CarbonThemeData] from the nearest enclosing [CarbonTheme].
  ///
  /// Asserts that a [CarbonTheme] is present; use [maybeOf] when it might not
  /// be. The caller depends on the theme and rebuilds when it changes.
  static CarbonThemeData of(BuildContext context) {
    final CarbonThemeData? data = maybeOf(context);
    assert(
      data != null,
      'No CarbonTheme found in context. Wrap your app in a CarbonTheme '
      '(or AnimatedCarbonTheme).',
    );
    return data!;
  }

  /// The [CarbonThemeData] from the nearest [CarbonTheme], or null if none.
  static CarbonThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CarbonTheme>()?.data;

  @override
  bool updateShouldNotify(CarbonTheme oldWidget) => data != oldWidget.data;
}

/// A [CarbonTheme] that animates token changes over [duration].
///
/// Swapping [data] interpolates every token via [CarbonThemeData.lerp], so a
/// theme switch (for example light to dark) transitions smoothly rather than
/// snapping. The crossfade is decorative: when the platform requests reduced
/// motion, the new theme applies instantly.
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
    // The theme crossfade is decorative, so it collapses to zero when the
    // platform requests reduced motion.
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    controller.duration = reducedMotion ? Duration.zero : widget.duration;
    if (reducedMotion && controller.isAnimating) {
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
    _data =
        visitor(
              _data,
              widget.data,
              (dynamic value) =>
                  _CarbonThemeDataTween(begin: value as CarbonThemeData),
            )
            as _CarbonThemeDataTween?;
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
