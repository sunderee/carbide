// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import '../../foundations/fluid_text_style.dart';
import '../../foundations/fluid_typography.dart';
import '../../foundations/fonts.dart';
import 'carbon_text.dart';

/// The width used to select a fluid typography breakpoint.
enum CarbonFluidTextWidthSource {
  /// The logical viewport width from [MediaQuery].
  viewport,

  /// The enclosing maximum width, falling back to the viewport if unbounded.
  constraints,
}

/// Text that automatically selects a Carbon fluid type style.
///
/// By default, [widthSource] uses the [MediaQuery] viewport width, matching
/// Carbon's viewport breakpoints even inside a narrow column. Choose
/// [CarbonFluidTextWidthSource.constraints] to size against the enclosing
/// maximum width instead; unbounded horizontal constraints fall back to the
/// viewport. Changes to the chosen width rebuild the resolved style.
///
/// Fluid styles select the generated breakpoint cascade, without continuous
/// interpolation between steps. User text scaling applies on top of the
/// selected base size. Built-in Plex families select Carbide's bundled fonts,
/// including the serif quotation styles; custom font families are preserved.
///
/// ```dart
/// const CarbonFluidText(
///   'A responsive title',
///   style: CarbonFluidTypeStyles.expressiveHeading05,
/// );
/// const CarbonFluidText(
///   'A quotation in a narrow column',
///   style: CarbonFluidTypeStyles.quotation01,
///   widthSource: CarbonFluidTextWidthSource.constraints,
/// );
/// ```
class CarbonFluidText extends StatelessWidget {
  /// Creates text that resolves [style] against [widthSource].
  const CarbonFluidText(
    this.data, {
    super.key,
    this.style = CarbonFluidTypeStyles.expressiveParagraph01,
    this.widthSource = CarbonFluidTextWidthSource.viewport,
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

  /// The responsive style; defaults to `expressiveParagraph01`.
  final CarbonFluidTextStyle style;

  /// The width used to select a breakpoint; defaults to the viewport.
  final CarbonFluidTextWidthSource widthSource;

  /// Overrides the style's color, falling back to the theme's text color.
  final Color? color;

  /// How the text is aligned horizontally.
  final TextAlign? textAlign;

  /// An optional maximum number of lines, truncated per [overflow].
  final int? maxLines;

  /// How visual overflow is handled.
  final TextOverflow? overflow;

  /// Whether the text should break at soft line breaks.
  final bool? softWrap;

  /// An alternative accessibility label, read instead of [data].
  final String? semanticsLabel;

  /// Overrides the ambient [Directionality] for this text.
  final TextDirection? textDirection;

  Widget _resolve(double width) {
    TextStyle resolved = style.resolve(width);
    if (resolved.fontFamily == CarbonFontFamily.sans ||
        resolved.fontFamily == CarbonFontFamily.mono ||
        resolved.fontFamily == CarbonFontFamily.serif) {
      resolved = resolved.copyWith(
        fontFamily: 'packages/carbide/${resolved.fontFamily}',
      );
    }
    return CarbonText(
      data,
      style: resolved,
      color: color,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
      textDirection: textDirection,
    );
  }

  @override
  Widget build(BuildContext context) => switch (widthSource) {
    CarbonFluidTextWidthSource.viewport => _resolve(
      MediaQuery.sizeOf(context).width,
    ),
    CarbonFluidTextWidthSource.constraints => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => _resolve(
        constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width,
      ),
    ),
  };
}
