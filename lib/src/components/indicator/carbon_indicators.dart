// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/{badge,icon,shape}-indicator/
//   react/src/components/{BadgeIndicator,IconIndicator,ShapeIndicator}
//   themes/src/component-tokens/status/tokens.ts
//
// The indicator family: a notification badge, an icon status indicator, and a
// shape status indicator (colour-blind-safe). Icon/Shape convey status by
// shape *and* an always-present label, not colour alone.

import 'package:flutter/widgets.dart';

import '../../foundations/colors.dart';
import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// Carbon's status colour palette (component-tokens/status). Light themes use
/// the 60/50/70 steps; dark themes step down for contrast.
enum _Status {
  red,
  orange,
  yellow,
  purple,
  green,
  blue,
  gray;

  Color resolve(CarbonThemeData theme) {
    final bool light = theme.brightness == Brightness.light;
    return switch (this) {
      _Status.red => light ? CarbonColors.red60 : CarbonColors.red50,
      _Status.orange => CarbonColors.orange40,
      _Status.yellow => CarbonColors.yellow30,
      _Status.purple => light ? CarbonColors.purple60 : CarbonColors.purple50,
      _Status.green => light ? CarbonColors.green50 : CarbonColors.green40,
      _Status.blue => light ? CarbonColors.blue70 : CarbonColors.blue50,
      _Status.gray => light ? CarbonColors.gray60 : CarbonColors.gray50,
    };
  }
}

/// A small notification badge: a dot, or a count (capped at `999+`).
class CarbonBadgeIndicator extends StatelessWidget {
  /// Creates a badge indicator. With no [count] it renders a dot.
  const CarbonBadgeIndicator({super.key, this.count});

  /// The number to show; when null, a dot is shown instead.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    if (count == null) {
      // A bare dot (min-size $spacing-03).
      return Semantics(
        label: 'New',
        child: Container(
          width: CarbonSpacing.spacing03,
          height: CarbonSpacing.spacing03,
          decoration: BoxDecoration(
            color: theme.supportError,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    final String display = count! > 999 ? '999+' : '$count';
    return Semantics(
      label: display,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: CarbonSpacing.spacing03,
          minWidth: CarbonSpacing.spacing05,
          maxHeight: CarbonSpacing.spacing05,
        ),
        padding: const EdgeInsets.fromLTRB(
          CarbonSpacing.spacing02,
          0,
          CarbonSpacing.spacing02,
          CarbonSpacing.spacing01,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.supportError,
          borderRadius: BorderRadius.circular(100),
        ),
        child: ExcludeSemantics(
          child: Text(
            display,
            style: CarbonTypeStyles.label01.copyWith(color: theme.textOnColor),
          ),
        ),
      ),
    );
  }
}

/// The kind of a [CarbonIconIndicator]: an icon and a status colour.
enum CarbonIconIndicatorKind {
  /// A failure.
  failed(CarbonIcons.errorFilled, _Status.red),

  /// A major caution.
  cautionMajor(CarbonIcons.warningAltInvertedFilled, _Status.orange),

  /// A minor caution.
  cautionMinor(CarbonIcons.warningAltFilled, _Status.yellow),

  /// An undefined state.
  undefined(CarbonIcons.undefinedFilled, _Status.purple),

  /// Succeeded.
  succeeded(CarbonIcons.checkmarkFilled, _Status.green),

  /// Normal / acknowledged.
  normal(CarbonIcons.checkmarkOutline, _Status.blue),

  /// In progress.
  inProgress(CarbonIcons.inProgress, _Status.blue),

  /// Incomplete.
  incomplete(CarbonIcons.incomplete, _Status.blue),

  /// Not started.
  notStarted(CarbonIcons.circleDash, _Status.gray),

  /// Pending.
  pending(CarbonIcons.pendingFilled, _Status.gray),

  /// Unknown.
  unknown(CarbonIcons.unknownFilled, _Status.gray),

  /// Informative.
  informative(CarbonIcons.warningSquareFilled, _Status.blue);

  const CarbonIconIndicatorKind(this.icon, this._status);

  /// The icon shown for this kind.
  final CarbonIconData icon;

  /// The status colour group for this kind.
  final _Status _status;
}

/// A status indicator: a coloured status icon followed by a [label].
class CarbonIconIndicator extends StatelessWidget {
  /// Creates an icon indicator.
  const CarbonIconIndicator({
    required this.kind,
    required this.label,
    super.key,
    this.size = 16,
  }) : assert(size == 16 || size == 20, 'size must be 16 or 20');

  /// The status kind.
  final CarbonIconIndicatorKind kind;

  /// The status text (always present, so status does not rely on colour).
  final String label;

  /// The icon size: 16 (default) or 20.
  final double size;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CarbonIcon(kind.icon, size: size, color: kind._status.resolve(theme)),
        const SizedBox(width: CarbonSpacing.spacing03),
        Text(
          label,
          style:
              (size == 20
                      ? CarbonTypeStyles.bodyCompact02
                      : CarbonTypeStyles.bodyCompact01)
                  .copyWith(color: theme.textPrimary),
        ),
      ],
    );
  }
}

/// The kind of a [CarbonShapeIndicator]: a colour-blind-safe shape + status.
enum CarbonShapeIndicatorKind {
  /// Failed.
  failed(CarbonIcons.critical, _Status.red),

  /// Critical severity.
  critical(CarbonIcons.criticalSeverity, _Status.red),

  /// High severity.
  high(CarbonIcons.caution, _Status.red),

  /// Medium severity.
  medium(CarbonIcons.diamondFill, _Status.orange),

  /// Low severity.
  low(CarbonIcons.lowSeverity, _Status.yellow),

  /// Cautious.
  cautious(CarbonIcons.caution, _Status.yellow),

  /// Undefined.
  undefined(CarbonIcons.diamondFill, _Status.purple),

  /// Stable.
  stable(CarbonIcons.circleFill, _Status.green),

  /// Informative.
  informative(CarbonIcons.lowSeverity, _Status.blue),

  /// Incomplete.
  incomplete(CarbonIcons.incomplete, _Status.blue),

  /// Draft.
  draft(CarbonIcons.circleStroke, _Status.gray);

  const CarbonShapeIndicatorKind(this.shape, this._status);

  /// The shape icon shown for this kind.
  final CarbonIconData shape;

  /// The status colour group for this kind.
  final _Status _status;
}

/// A colour-blind-safe status indicator: a distinct shape followed by [label].
class CarbonShapeIndicator extends StatelessWidget {
  /// Creates a shape indicator.
  const CarbonShapeIndicator({
    required this.kind,
    required this.label,
    super.key,
    this.textSize = 12,
  }) : assert(textSize == 12 || textSize == 14, 'textSize must be 12 or 14');

  /// The status kind.
  final CarbonShapeIndicatorKind kind;

  /// The status text (always present alongside the shape).
  final String label;

  /// The label text size: 12 (default) or 14.
  final double textSize;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        CarbonIcon(kind.shape, size: 16, color: kind._status.resolve(theme)),
        const SizedBox(width: CarbonSpacing.spacing03),
        Text(
          label,
          style:
              (textSize == 14
                      ? CarbonTypeStyles.bodyCompact01
                      : CarbonTypeStyles.helperText01)
                  .copyWith(color: theme.textPrimary),
        ),
      ],
    );
  }
}
