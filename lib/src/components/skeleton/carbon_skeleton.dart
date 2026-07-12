// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/utilities/_skeleton.scss (the skeleton mixin)
//   styles/scss/utilities/_keyframes.scss (@keyframes cds--skeleton)

import 'package:flutter/widgets.dart';

import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// The evaluated shimmer state at one point of the skeleton animation.
///
/// Mirrors the upstream `cds--skeleton` keyframes over a 3000ms cycle: the
/// `skeletonElement` wipe grows from the left, shrinks toward the right,
/// grows back from the right, and shrinks toward the left, while opacity
/// breathes 0.3 → 1 → 0.3. Each keyframe segment eases in-out, exactly like
/// the CSS `ease-in-out` per-segment timing.
@immutable
class CarbonSkeletonPhase {
  /// Creates a single keyframe of the skeleton wipe animation.
  const CarbonSkeletonPhase({
    required this.alignment,
    required this.scaleX,
    required this.opacity,
  });

  /// The transform origin of the wipe.
  final Alignment alignment;

  /// The horizontal scale of the wipe (0–1).
  final double scaleX;

  /// The wipe opacity (0.3–1).
  final double opacity;

  /// Transform keyframes: (stop, originLeft, scaleX). Origins only switch
  /// while the scale is constant, so using the segment end's origin is exact.
  static const List<(double, bool, double)> _transformStops =
      <(double, bool, double)>[
        (0.00, true, 0),
        (0.20, true, 1),
        (0.28, false, 1),
        (0.51, false, 0),
        (0.58, false, 0),
        (0.82, false, 1),
        (0.83, true, 1),
        (0.96, true, 0),
        (1.00, true, 0),
      ];

  /// Opacity keyframes: only keyed at 0%, 20%, and 100% upstream, so the
  /// fade back to 0.3 spans the whole 20%–100% interval.
  static const List<(double, double)> _opacityStops = <(double, double)>[
    (0.00, 0.3),
    (0.20, 1),
    (1.00, 0.3),
  ];

  /// Evaluates the keyframes at cycle position [t] (0–1).
  factory CarbonSkeletonPhase.at(double t) {
    bool originLeft = true;
    double scaleX = 0;
    for (int i = 0; i + 1 < _transformStops.length; i++) {
      final (double start, bool _, double fromScale) = _transformStops[i];
      final (double end, bool toLeft, double toScale) = _transformStops[i + 1];
      if (t <= end || i + 2 == _transformStops.length) {
        final double local = ((t - start) / (end - start)).clamp(0, 1);
        final double eased = Curves.easeInOut.transform(local);
        scaleX = fromScale + (toScale - fromScale) * eased;
        originLeft = toLeft;
        break;
      }
    }
    double opacity = 0.3;
    for (int i = 0; i + 1 < _opacityStops.length; i++) {
      final (double start, double from) = _opacityStops[i];
      final (double end, double to) = _opacityStops[i + 1];
      if (t <= end || i + 2 == _opacityStops.length) {
        final double local = ((t - start) / (end - start)).clamp(0, 1);
        opacity = from + (to - from) * Curves.easeInOut.transform(local);
        break;
      }
    }
    return CarbonSkeletonPhase(
      alignment: originLeft ? Alignment.centerLeft : Alignment.centerRight,
      scaleX: scaleX,
      opacity: opacity,
    );
  }
}

/// The Carbon skeleton shimmer: the base building block of every loading
/// placeholder.
///
/// Draws the theme's `skeletonBackground` with the animated
/// `skeletonElement` wipe over it (3000ms cycle, see [CarbonSkeletonPhase]).
/// When the platform requests reduced motion, the wipe is static and fully
/// covers the box — matching the upstream `animation: none`, which leaves
/// the element overlay in place.
///
/// Skeletons are decorative: the widget excludes itself from the semantics
/// tree.
class CarbonSkeleton extends StatefulWidget {
  /// Creates a skeleton shimmer box.
  const CarbonSkeleton({super.key, this.width, this.height, this.borderRadius});

  /// Fixed width; null fills the parent constraint.
  final double? width;

  /// Fixed height; null fills the parent constraint.
  final double? height;

  /// Optional corner rounding (e.g. the tag skeleton's pill shape).
  final BorderRadius? borderRadius;

  /// The upstream animation cycle duration.
  static const Duration cycle = Duration(milliseconds: 3000);

  @override
  State<CarbonSkeleton> createState() => _CarbonSkeletonState();
}

class _CarbonSkeletonState extends State<CarbonSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CarbonSkeleton.cycle,
  );

  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    Widget box;
    if (_reduced) {
      box = ColoredBox(color: theme.skeletonElement);
    } else {
      box = AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final CarbonSkeletonPhase phase = CarbonSkeletonPhase.at(
            _controller.value,
          );
          return ColoredBox(
            color: theme.skeletonBackground,
            child: Opacity(
              opacity: phase.opacity,
              child: Transform(
                alignment: phase.alignment,
                transform: Matrix4.diagonal3Values(phase.scaleX, 1, 1),
                child: ColoredBox(color: theme.skeletonElement),
              ),
            ),
          );
        },
      );
    }
    final BorderRadius? radius = widget.borderRadius;
    if (radius != null) {
      box = ClipRRect(borderRadius: radius, child: box);
    }
    return ExcludeSemantics(
      child: SizedBox(width: widget.width, height: widget.height, child: box),
    );
  }
}
