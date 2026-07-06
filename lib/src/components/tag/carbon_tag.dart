// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/tag/{_tag,_mixins}.scss
//   react/src/components/Tag/Tag.tsx

import 'package:flutter/widgets.dart';

import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// The Carbon tag sizes and their fixed heights.
enum CarbonTagSize {
  /// 18px.
  sm(18),

  /// 24px — the default.
  md(24),

  /// 32px.
  lg(32);

  const CarbonTagSize(this.height);

  /// The tag height in logical pixels.
  final double height;
}

/// The Carbon tag color types.
enum CarbonTagType {
  /// Red.
  red,

  /// Magenta.
  magenta,

  /// Purple.
  purple,

  /// Blue.
  blue,

  /// Cyan.
  cyan,

  /// Teal.
  teal,

  /// Green.
  green,

  /// Gray — the default.
  gray,

  /// Cool gray.
  coolGray,

  /// Warm gray.
  warmGray,

  /// High contrast (inverse background).
  highContrast,

  /// Outline (page background with an inverse outline).
  outline,
}

/// The resolved colors for one tag type under one theme/layer context.
@immutable
class CarbonTagColors {
  /// Creates a resolved set of tag colors.
  const CarbonTagColors({
    required this.background,
    required this.text,
    required this.hover,
    required this.border,
    this.outline,
  });

  /// The tag fill.
  final Color background;

  /// The label/icon color.
  final Color text;

  /// The hover fill (close-button hover; operational hover).
  final Color hover;

  /// The operational-tag border.
  final Color border;

  /// An inset outline (the `outline` type's 1px inverse ring).
  final Color? outline;

  /// Resolves the color set for [type], mirroring the `tag-theme(...)`
  /// calls per type modifier. The `outline` type reads the layer-agnostic
  /// `background` token; disabled states are resolved by the widgets (they
  /// use the layer-contextual `layer` token).
  static CarbonTagColors resolve(CarbonThemeData theme, CarbonTagType type) {
    switch (type) {
      case CarbonTagType.red:
        return CarbonTagColors(
          background: theme.tagBackgroundRed,
          text: theme.tagColorRed,
          hover: theme.tagHoverRed,
          border: theme.tagBorderRed,
        );
      case CarbonTagType.magenta:
        return CarbonTagColors(
          background: theme.tagBackgroundMagenta,
          text: theme.tagColorMagenta,
          hover: theme.tagHoverMagenta,
          border: theme.tagBorderMagenta,
        );
      case CarbonTagType.purple:
        return CarbonTagColors(
          background: theme.tagBackgroundPurple,
          text: theme.tagColorPurple,
          hover: theme.tagHoverPurple,
          border: theme.tagBorderPurple,
        );
      case CarbonTagType.blue:
        return CarbonTagColors(
          background: theme.tagBackgroundBlue,
          text: theme.tagColorBlue,
          hover: theme.tagHoverBlue,
          border: theme.tagBorderBlue,
        );
      case CarbonTagType.cyan:
        return CarbonTagColors(
          background: theme.tagBackgroundCyan,
          text: theme.tagColorCyan,
          hover: theme.tagHoverCyan,
          border: theme.tagBorderCyan,
        );
      case CarbonTagType.teal:
        return CarbonTagColors(
          background: theme.tagBackgroundTeal,
          text: theme.tagColorTeal,
          hover: theme.tagHoverTeal,
          border: theme.tagBorderTeal,
        );
      case CarbonTagType.green:
        return CarbonTagColors(
          background: theme.tagBackgroundGreen,
          text: theme.tagColorGreen,
          hover: theme.tagHoverGreen,
          border: theme.tagBorderGreen,
        );
      case CarbonTagType.gray:
        return CarbonTagColors(
          background: theme.tagBackgroundGray,
          text: theme.tagColorGray,
          hover: theme.tagHoverGray,
          border: theme.tagBorderGray,
        );
      case CarbonTagType.coolGray:
        return CarbonTagColors(
          background: theme.tagBackgroundCoolGray,
          text: theme.tagColorCoolGray,
          hover: theme.tagHoverCoolGray,
          border: theme.tagBorderCoolGray,
        );
      case CarbonTagType.warmGray:
        return CarbonTagColors(
          background: theme.tagBackgroundWarmGray,
          text: theme.tagColorWarmGray,
          hover: theme.tagHoverWarmGray,
          border: theme.tagBorderWarmGray,
        );
      case CarbonTagType.highContrast:
        return CarbonTagColors(
          background: theme.backgroundInverse,
          text: theme.textInverse,
          hover: theme.backgroundInverseHover,
          border: theme.backgroundInverse,
        );
      case CarbonTagType.outline:
        return CarbonTagColors(
          background: theme.background,
          text: theme.textPrimary,
          hover: theme.layerHover01,
          border: theme.background,
          outline: theme.backgroundInverse,
        );
    }
  }
}

/// A read-only Carbon tag.
///
/// ```dart
/// const CarbonTag(label: 'Production', type: CarbonTagType.green);
/// ```
///
/// Tags are pill-shaped labels in one of ten colors plus the high-contrast
/// and outline variants. The disabled state uses the layer-contextual
/// `layer` token, so a disabled tag matches its surface inside a
/// [CarbonLayer]. Interactive variants are `CarbonDismissibleTag`,
/// `CarbonSelectableTag`, and `CarbonOperationalTag`.
class CarbonTag extends StatelessWidget {
  /// Creates a read-only tag.
  const CarbonTag({
    super.key,
    required this.label,
    this.type = CarbonTagType.gray,
    this.size = CarbonTagSize.md,
    this.icon,
    this.disabled = false,
    this.aiLabel,
  });

  /// The tag text, truncated with an ellipsis past the 208px max width.
  final String label;

  /// An optional AI presence decorator (a `CarbonAILabel`, typically the
  /// inline variant), rendered after the label per upstream's `decorator`
  /// prop (`--tag--decorator`).
  final Widget? aiLabel;

  /// The color type.
  final CarbonTagType type;

  /// The size; defaults to md (24px).
  final CarbonTagSize size;

  /// Optional 16px leading icon.
  final CarbonIconData? icon;

  /// Renders the disabled (layer + textDisabled) colors.
  final bool disabled;

  /// The tag label type style (`label-01`).
  static const TextStyle labelStyle = CarbonTypeStyles.label01;

  /// Pill radius / max and min widths per spec.
  static const double radius = 16;

  /// The maximum tag width per spec.
  static const double maxWidth = 208;

  /// The minimum tag width per spec ("ensures tag stays pill shaped").
  static const double minWidth = 32;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonTagColors colors = CarbonTagColors.resolve(theme, type);
    final Color background = disabled
        ? CarbonLayer.of(context).layer
        : colors.background;
    final Color text = disabled ? theme.textDisabled : colors.text;
    return TagSurface(
      aiLabel: aiLabel,
      size: size,
      background: background,
      text: text,
      outline: disabled ? null : colors.outline,
      icon: icon,
      label: label,
    );
  }
}

/// The shared pill surface used by every tag variant.
///
/// Geometry per `_tag.scss`: fixed height per size, 16px pill radius, 8px
/// horizontal padding (12px for lg), 32–208px width, label-01 text with
/// ellipsis truncation, optional 16px leading icon with a 4px gap (icon
/// shifts the start padding to 4px; 8px for lg).
class TagSurface extends StatelessWidget {
  /// Creates the tag surface.
  const TagSurface({
    super.key,
    required this.size,
    required this.background,
    required this.text,
    required this.label,
    this.outline,
    this.border,
    this.icon,
    this.trailing,
    this.aiLabel,
    this.endPadding,
  });

  /// The size variant.
  final CarbonTagSize size;

  /// The fill color.
  final Color background;

  /// The label/icon color.
  final Color text;

  /// Optional 1px inset outline color (the `outline` type).
  final Color? outline;

  /// Optional 1px border color (selectable/operational variants).
  final Color? border;

  /// Optional 16px leading icon.
  final CarbonIconData? icon;

  /// The label text.
  final String label;

  /// An optional trailing widget (the dismiss button).
  final Widget? trailing;

  /// An optional AI presence decorator, rendered after the label.
  final Widget? aiLabel;

  /// Overrides the end padding (the dismiss button sits flush).
  final double? endPadding;

  @override
  Widget build(BuildContext context) {
    final bool lg = size == CarbonTagSize.lg;
    final double start = icon != null ? (lg ? 8 : 4) : (lg ? 12 : 8);
    final double end = endPadding ?? (lg ? 12 : 8);
    final CarbonIconData? leading = icon;

    return Container(
      // The spec height is a minimum: under text scaling the pill grows
      // with its label instead of clipping it (docs/text-scaling.md). At
      // 1.0x the label always fits, so this renders identically to the
      // previous fixed height.
      constraints: BoxConstraints(
        minWidth: CarbonTag.minWidth,
        maxWidth: CarbonTag.maxWidth,
        minHeight: size.height,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(CarbonTag.radius),
        border: border == null ? null : Border.all(color: border!),
      ),
      foregroundDecoration: outline == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(CarbonTag.radius),
              border: Border.all(color: outline!),
            ),
      padding: EdgeInsetsDirectional.only(start: start, end: end),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            CarbonIcon(leading, color: text),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CarbonTag.labelStyle.copyWith(color: text),
            ),
          ),
          // The AI label flows after the tag text (`--tag--decorator`).
          if (aiLabel != null) ...<Widget>[const SizedBox(width: 4), aiLabel!],
          ?trailing,
        ],
      ),
    );
  }
}
