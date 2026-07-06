// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/loading/{_loading,_vars,_functions,_animation}.scss
//   react/src/components/Loading/Loading.tsx

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// The Carbon loading spinner.
///
/// An arc of the `interactive` token spinning at 690ms per revolution
/// (linear, per the upstream `spin` animation). The large spinner is 88px
/// with an 81% arc; the [small] variant is 16px with a 48% arc over a
/// `layerAccent` track ring.
///
/// [withOverlay] fills the available space with the theme `overlay` scrim
/// and centers the spinner — place it inside a Stack covering the content
/// it blocks. When [active] is false the spinner freezes (the upstream
/// two-phase wind-down animation is simplified to a stop; recorded).
///
/// The spin is essential motion and deliberately ignores
/// `MediaQueryData.disableAnimations`: per Carbon's motion guidance a
/// loading indicator communicates that the system is still working, so
/// freezing it would read as a hang rather than reduced motion.
class CarbonLoading extends StatefulWidget {
  /// Creates a loading spinner.
  const CarbonLoading({
    super.key,
    this.small = false,
    this.active = true,
    this.withOverlay = false,
    this.description = 'Loading',
  });

  /// Renders the 16px small variant with its track ring.
  final bool small;

  /// Whether the spinner is spinning; false freezes it.
  final bool active;

  /// Whether to fill the available space with the overlay scrim.
  final bool withOverlay;

  /// The accessible live-region label.
  final String description;

  /// Spinner sizes per spec (5.5rem / 1rem).
  static const double largeSize = 88;

  /// The small variant's edge length.
  static const double smallSize = 16;

  /// SVG geometry per spec: 100 viewBox, r=42 circle.
  static const double viewBox = 100;

  /// The circle radius within the viewBox.
  static const double radius = 42;

  /// Stroke widths per spec (10 large, 16 small) in viewBox units.
  static const double largeStrokeWidth = 10;

  /// The small variant's stroke width in viewBox units.
  static const double smallStrokeWidth = 16;

  /// Visible arc fractions per `loading-progress(circumference, p)`.
  static const double largeArcFraction = 0.81;

  /// The small variant's visible arc fraction.
  static const double smallArcFraction = 0.48;

  /// One revolution per the upstream `spin` animation.
  static const Duration rotationCycle = Duration(milliseconds: 690);

  @override
  State<CarbonLoading> createState() => _CarbonLoadingState();
}

class _CarbonLoadingState extends State<CarbonLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CarbonLoading.rotationCycle,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CarbonLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active) {
      _controller.stop();
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
    final bool small = widget.small;
    Widget spinner = Semantics(
      liveRegion: true,
      label: widget.description,
      child: SizedBox.square(
        dimension: small ? CarbonLoading.smallSize : CarbonLoading.largeSize,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) => CustomPaint(
            painter: CarbonLoadingPainter(
              rotation: _controller.value,
              color: theme.interactive,
              trackColor: small ? theme.layerAccent01 : null,
              strokeWidth: small
                  ? CarbonLoading.smallStrokeWidth
                  : CarbonLoading.largeStrokeWidth,
              arcFraction: small
                  ? CarbonLoading.smallArcFraction
                  : CarbonLoading.largeArcFraction,
            ),
          ),
        ),
      ),
    );
    if (widget.withOverlay) {
      spinner = ColoredBox(
        color: theme.overlay,
        child: Center(child: spinner),
      );
    }
    return spinner;
  }
}

/// Paints the Carbon spinner arc (and the small variant's track).
class CarbonLoadingPainter extends CustomPainter {
  /// Creates the spinner painter.
  const CarbonLoadingPainter({
    required this.rotation,
    required this.color,
    required this.strokeWidth,
    required this.arcFraction,
    this.trackColor,
  });

  /// The rotation phase (0–1 of a revolution).
  final double rotation;

  /// The arc color (the `interactive` token).
  final Color color;

  /// Stroke width in viewBox units (scaled to the paint size).
  final double strokeWidth;

  /// The visible fraction of the circumference.
  final double arcFraction;

  /// The full track ring color (small variant only).
  final Color? trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.shortestSide / CarbonLoading.viewBox;
    final double stroke = strokeWidth * scale;
    final Rect circle = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: CarbonLoading.radius * scale,
    );
    final Color? track = trackColor;
    if (track != null) {
      canvas.drawArc(
        circle,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = track,
      );
    }
    canvas.drawArc(
      circle,
      // Start at 12 o'clock plus the rotation phase.
      -math.pi / 2 + rotation * 2 * math.pi,
      arcFraction * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(CarbonLoadingPainter oldDelegate) =>
      rotation != oldDelegate.rotation ||
      color != oldDelegate.color ||
      trackColor != oldDelegate.trackColor ||
      strokeWidth != oldDelegate.strokeWidth ||
      arcFraction != oldDelegate.arcFraction;
}
