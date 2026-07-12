// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import '../theme/carbon_theme.dart';
import '../theme/carbon_theme_data.dart';

/// Carbon's focus indicator: a [thickness]px ring in the theme's `focus` token,
/// drawn inside [child]'s bounds.
///
/// Mirrors Carbon's `focus-outline('outline')` (a 2px inset outline). Set
/// [inset] for the filled-control variant, which adds a 1px inner ring in the
/// `focusInset` token so the indicator stays visible against a filled
/// background (as buttons do).
///
/// The ring is painted over [child] only while [visible] is true, so a
/// component can drive it from its focus state without changing layout.
class CarbonFocusRing extends StatelessWidget {
  /// Creates a focus ring around [child].
  const CarbonFocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.inset = false,
    this.thickness = 2,
    this.color,
    this.insetColor,
  });

  /// Whether the ring is currently shown.
  final bool visible;

  /// The widget the ring is drawn around.
  final Widget child;

  /// Corner radius of the ring; defaults to square corners.
  final BorderRadius borderRadius;

  /// Whether to add the 1px inner `focusInset` ring (for filled controls).
  final bool inset;

  /// Width of the outer ring in logical pixels.
  final double thickness;

  /// Overrides the outer ring color; defaults to the theme's `focus` token.
  final Color? color;

  /// Overrides the inner ring color; defaults to the theme's `focusInset`.
  final Color? insetColor;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return CustomPaint(
      foregroundPainter: visible
          ? _FocusRingPainter(
              color: color ?? theme.focus,
              insetColor: inset ? (insetColor ?? theme.focusInset) : null,
              borderRadius: borderRadius,
              thickness: thickness,
            )
          : null,
      child: child,
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  _FocusRingPainter({
    required this.color,
    required this.insetColor,
    required this.borderRadius,
    required this.thickness,
  });

  final Color color;
  final Color? insetColor;
  final BorderRadius borderRadius;
  final double thickness;

  static const double _insetWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    // Outer ring: stroke centred half its width in, so its outer edge sits on
    // the bounds — Carbon's inset outline (outline-offset: -2px).
    _stroke(canvas, bounds, thickness, color, thickness / 2);
    final Color? inner = insetColor;
    if (inner != null) {
      _stroke(canvas, bounds, _insetWidth, inner, thickness + _insetWidth / 2);
    }
  }

  void _stroke(
    Canvas canvas,
    Rect bounds,
    double strokeWidth,
    Color paintColor,
    double inset,
  ) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = paintColor;
    final Rect rect = bounds.deflate(inset);
    if (borderRadius == BorderRadius.zero) {
      canvas.drawRect(rect, paint);
    } else {
      canvas.drawRRect(_shrink(borderRadius, inset).toRRect(rect), paint);
    }
  }

  BorderRadius _shrink(BorderRadius radius, double by) => BorderRadius.only(
    topLeft: _shrinkRadius(radius.topLeft, by),
    topRight: _shrinkRadius(radius.topRight, by),
    bottomLeft: _shrinkRadius(radius.bottomLeft, by),
    bottomRight: _shrinkRadius(radius.bottomRight, by),
  );

  Radius _shrinkRadius(Radius radius, double by) => Radius.elliptical(
    (radius.x - by).clamp(0, double.infinity),
    (radius.y - by).clamp(0, double.infinity),
  );

  @override
  bool shouldRepaint(_FocusRingPainter oldDelegate) =>
      color != oldDelegate.color ||
      insetColor != oldDelegate.insetColor ||
      borderRadius != oldDelegate.borderRadius ||
      thickness != oldDelegate.thickness;
}
