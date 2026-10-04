// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Values are ported verbatim from the Apache-2.0 licensed Carbon Design System
// (@carbon/motion). See the NOTICE file for attribution.

import 'package:flutter/animation.dart' show Cubic;
import 'package:flutter/widgets.dart' show BuildContext, MediaQuery;

/// Resolves a decorative motion [duration] against the platform preference.
///
/// Returns [Duration.zero] when the nearest [MediaQuery] disables animations;
/// otherwise preserves [duration], including when no media query is present.
/// The caller depends on the preference and rebuilds when it changes.
///
/// Use this at the animation site, including for custom durations. APIs that
/// reject zero durations, such as scrolling animations, must use their instant
/// alternative instead. Loading spinners and indeterminate progress retain
/// their essential activity signal and deliberately bypass this resolver.
Duration carbonDuration(BuildContext context, Duration duration) =>
    (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
    ? Duration.zero
    : duration;

/// Carbon motion durations.
abstract final class CarbonDuration {
  /// 70ms — micro-interactions (e.g. button hover).
  static const Duration fast01 = Duration(milliseconds: 70);

  /// 110ms.
  static const Duration fast02 = Duration(milliseconds: 110);

  /// 150ms.
  static const Duration moderate01 = Duration(milliseconds: 150);

  /// 240ms.
  static const Duration moderate02 = Duration(milliseconds: 240);

  /// 400ms.
  static const Duration slow01 = Duration(milliseconds: 400);

  /// 700ms.
  static const Duration slow02 = Duration(milliseconds: 700);
}

/// The kind of motion, which selects an easing curve.
enum CarbonEasingStyle {
  /// For elements that begin and end on screen (e.g. a state change).
  standard,

  /// For elements entering the screen.
  entrance,

  /// For elements leaving the screen.
  exit,
}

/// The expressiveness mode of an easing curve.
enum CarbonEasingMode {
  /// For efficient, frequent actions.
  productive,

  /// For moments of emphasis.
  expressive,
}

/// Carbon motion easing curves, as Flutter [Cubic] curves.
///
/// Pick one directly, or resolve by [CarbonEasingStyle] and [CarbonEasingMode]
/// with [resolve].
abstract final class CarbonEasing {
  /// `standard` × `productive`.
  static const Cubic standardProductive = Cubic(0.2, 0, 0.38, 0.9);

  /// `standard` × `expressive`.
  static const Cubic standardExpressive = Cubic(0.4, 0.14, 0.3, 1);

  /// `entrance` × `productive`.
  static const Cubic entranceProductive = Cubic(0, 0, 0.38, 0.9);

  /// `entrance` × `expressive`.
  static const Cubic entranceExpressive = Cubic(0, 0, 0.3, 1);

  /// `exit` × `productive`.
  static const Cubic exitProductive = Cubic(0.2, 0, 1, 0.9);

  /// `exit` × `expressive`.
  static const Cubic exitExpressive = Cubic(0.4, 0.14, 1, 1);

  /// The easing curve for [style] and [mode], mirroring Carbon's `motion()`.
  static Cubic resolve(CarbonEasingStyle style, CarbonEasingMode mode) =>
      switch ((style, mode)) {
        (CarbonEasingStyle.standard, CarbonEasingMode.productive) =>
          standardProductive,
        (CarbonEasingStyle.standard, CarbonEasingMode.expressive) =>
          standardExpressive,
        (CarbonEasingStyle.entrance, CarbonEasingMode.productive) =>
          entranceProductive,
        (CarbonEasingStyle.entrance, CarbonEasingMode.expressive) =>
          entranceExpressive,
        (CarbonEasingStyle.exit, CarbonEasingMode.productive) => exitProductive,
        (CarbonEasingStyle.exit, CarbonEasingMode.expressive) => exitExpressive,
      };
}
