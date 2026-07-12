// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';

/// Text styled with a Carbon type style and the theme's text color.
///
/// Renders [data] in [style] (a named style from [CarbonTypeStyles];
/// `body01` by default), colored by the first of: [color], the style's own
/// color, or the active theme's `textPrimary` token. That keeps text legible
/// on every theme without callers having to resolve a color:
///
/// ```dart
/// const CarbonText('Sign in');
/// const CarbonText('Page title', style: CarbonTypeStyles.heading04);
/// CarbonText('Hint', color: CarbonTheme.of(context).textHelper);
/// ```
///
/// Fluid (responsive) styles are resolved per viewport width, not fixed, so
/// they are deliberately not accepted here; resolve a `CarbonFluidTextStyle`
/// with `resolve(width)` and pass the result as [style], or use the dedicated
/// fluid text widget once it lands with the component layer.
class CarbonText extends StatelessWidget {
  /// Creates Carbon-styled text.
  const CarbonText(
    this.data, {
    super.key,
    this.style = CarbonTypeStyles.body01,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.textDirection,
  });

  /// The text to display.
  final String data;

  /// The Carbon type style to apply; defaults to `body01`.
  final TextStyle style;

  /// Overrides the text color. When null, falls back to the style's color,
  /// then to the theme's `textPrimary` token.
  final Color? color;

  /// How the text is aligned horizontally.
  final TextAlign? textAlign;

  /// An optional maximum number of lines, truncated per [overflow].
  final int? maxLines;

  /// How visual overflow is handled.
  final TextOverflow? overflow;

  /// Whether the text should break at soft line breaks.
  final bool? softWrap;

  /// An alternative label for accessibility, read instead of [data].
  final String? semanticsLabel;

  /// Overrides the ambient [Directionality] for this run of text, like
  /// upstream `unstable_Text`'s per-element `dir`. Null inherits.
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final Color resolved =
        color ?? style.color ?? CarbonTheme.of(context).textPrimary;
    return Text(
      data,
      style: style.copyWith(color: resolved),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
      textDirection: textDirection,
    );
  }
}
