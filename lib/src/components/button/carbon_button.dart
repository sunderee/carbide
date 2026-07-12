// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/button/{_button,_mixins,_vars}.scss
//   react/src/components/Button/{Button,ButtonBase}.tsx
// Once-deferred features that now live elsewhere: `CarbonButtonSkeleton` is
// in the skeleton library (#47) and the tooltip-wrapped icon button is
// `CarbonIconButton` (#188). Expressive mode and link semantics (upstream
// `isExpressive` / `href`) are implemented here (#213).

import 'package:flutter/widgets.dart';

import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';

/// The Carbon button kinds.
enum CarbonButtonKind {
  /// Principal call to action.
  primary,

  /// Secondary action.
  secondary,

  /// Less prominent action; outlined.
  tertiary,

  /// The least prominent action; appears on hover.
  ghost,

  /// Destructive primary action.
  danger,

  /// Destructive tertiary action.
  dangerTertiary,

  /// Destructive ghost action.
  dangerGhost,
}

/// The Carbon button sizes and their fixed heights.
enum CarbonButtonSize {
  /// 24px.
  xs(24),

  /// 32px.
  sm(32),

  /// 40px.
  md(40),

  /// 48px — Carbon's default ("lg" production button).
  lg(48),

  /// 64px; label and icon pin to the top.
  xl(64),

  /// 80px; label and icon pin to the top.
  xxl(80);

  const CarbonButtonSize(this.height);

  /// The fixed button height in logical pixels.
  final double height;
}

/// A Carbon button.
///
/// ```dart
/// CarbonButton(label: 'Submit', onPressed: submit);
/// CarbonButton(
///   label: 'Delete',
///   kind: CarbonButtonKind.danger,
///   icon: CarbonIcons.trashCan,
///   onPressed: remove,
/// );
/// CarbonButton.iconOnly(
///   icon: CarbonIcons.add,
///   iconDescription: 'Add item',
///   onPressed: add,
/// );
/// ```
///
/// A null [onPressed] renders the disabled state. Geometry follows the
/// upstream spec exactly: fixed height per [size], max width 320, 1px border,
/// text and icon vertically centered up to [CarbonButtonSize.lg] and pinned
/// to the top above it. When the platform requests reduced motion, the
/// hover/press fill transition completes instantly.
class CarbonButton extends StatelessWidget {
  /// Creates a Carbon button with a text [label] and an optional trailing
  /// [icon].
  const CarbonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = CarbonButtonKind.primary,
    this.size = CarbonButtonSize.lg,
    this.icon,
    this.isSelected = false,
    this.isExpressive = false,
    this.link = false,
    this.focusNode,
    this.autofocus = false,
  }) : iconOnly = false,
       assert(
         !isSelected || kind == CarbonButtonKind.ghost,
         'isSelected only applies to ghost buttons',
       );

  /// Creates a square icon-only Carbon button.
  ///
  /// [iconDescription] labels the button for assistive technology (the
  /// upstream `iconDescription`). The tooltip-wrapped `IconButton` arrives
  /// with the Tooltip component.
  const CarbonButton.iconOnly({
    super.key,
    required CarbonIconData this.icon,
    required String iconDescription,
    this.onPressed,
    this.kind = CarbonButtonKind.primary,
    this.size = CarbonButtonSize.lg,
    this.isSelected = false,
    this.isExpressive = false,
    this.link = false,
    this.focusNode,
    this.autofocus = false,
  }) : label = iconDescription,
       iconOnly = true,
       assert(
         !isSelected || kind == CarbonButtonKind.ghost,
         'isSelected only applies to ghost buttons',
       );

  /// The button text; for icon-only buttons, the accessible description.
  final String label;

  /// Called on activation; null renders the disabled state.
  final VoidCallback? onPressed;

  /// The visual kind.
  final CarbonButtonKind kind;

  /// The size; defaults to Carbon's 48px production button.
  final CarbonButtonSize size;

  /// Optional 16px icon (trailing for labeled buttons).
  final CarbonIconData? icon;

  /// Whether this button renders without a visible label.
  final bool iconOnly;

  /// Selected state (ghost icon-only buttons).
  final bool isSelected;

  /// Whether to use Carbon's expressive treatment: the `body-compact-02`
  /// label (16px/22px line), the expressive block-padding formula, and
  /// 20px icons. Geometry per size is otherwise unchanged.
  ///
  /// Source: `_button.scss` `.cds--btn--expressive` and
  /// `_mixins.scss` `--temp-expressive-1lh`.
  final bool isExpressive;

  /// Whether the button carries link semantics instead of button semantics.
  ///
  /// This is upstream's `href` mode, where an enabled `Button` renders as an
  /// `<a>` element (`ButtonBase.tsx`): the visuals are identical and only
  /// the accessibility role changes. Navigation stays the caller's job via
  /// [onPressed]. A disabled link renders with button semantics, matching
  /// upstream's `href && !disabled` branch.
  final bool link;

  /// An optional focus node to control focus externally.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// Carbon's button label type style (`body-compact-01`).
  static const TextStyle labelStyle = CarbonTypeStyles.bodyCompact01;

  /// The expressive label type style (`body-compact-02`).
  static const TextStyle expressiveLabelStyle = CarbonTypeStyles.bodyCompact02;

  /// The maximum button width per spec.
  static const double maxWidth = 320;

  static const double _border = 1;
  static const double _iconSize = 16;
  static const double _expressiveIconSize = 20;

  /// Vertical padding per spec: centers the label line (18px, or 22px in
  /// expressive mode) up to lg and caps at the lg value computed from the
  /// default line (top alignment) above; −1px border compensation.
  /// Source: `_mixins.scss` `--temp-padding-block-max` / `padding-block` and
  /// `_button.scss` `.cds--btn--expressive` (the cap stays `--temp-1lh`
  /// based in both modes).
  static double _paddingBlock(CarbonButtonSize size, bool expressive) {
    final TextStyle style = expressive ? expressiveLabelStyle : labelStyle;
    final double line = style.fontSize! * style.height!;
    final double centered = (size.height - line) / 2 - _border;
    final double defaultLine =
        labelStyle.fontSize! * CarbonButton.labelStyle.height!;
    final double max = (CarbonButtonSize.lg.height - defaultLine) / 2 - _border;
    return centered < max ? centered : max;
  }

  /// Icon top inset per spec (`.cds--btn__icon`): centered up to lg, capped
  /// above; xs/sm/md drop the 1px optical margin.
  static double _iconTop(CarbonButtonSize size) {
    final double centered = (size.height - _iconSize) / 2 - _border;
    final double max =
        (CarbonButtonSize.lg.height -
                CarbonTypeStyles.bodyCompact01.fontSize! *
                    CarbonTypeStyles.bodyCompact01.height!) /
            2 -
        _border;
    final double top = centered < max ? centered : max;
    final bool opticalMargin =
        size == CarbonButtonSize.lg ||
        size == CarbonButtonSize.xl ||
        size == CarbonButtonSize.xxl;
    return top + (opticalMargin ? 1 : 0);
  }

  bool get _isGhostLike =>
      kind == CarbonButtonKind.ghost || kind == CarbonButtonKind.dangerGhost;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool enabled = onPressed != null;
    // Upstream renders an anchor only while enabled (`href && !disabled`),
    // so a disabled link keeps button semantics.
    final bool asLink = link && enabled;
    return Semantics(
      button: !asLink,
      link: asLink,
      enabled: enabled,
      label: iconOnly ? label : null,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final _ButtonStyle style = _ButtonStyle.resolve(
            theme: theme,
            kind: kind,
            states: states,
            iconOnly: iconOnly,
            isSelected: isSelected,
          );
          return _ButtonSurface(
            style: style,
            size: size,
            iconOnly: iconOnly,
            ghostLike: _isGhostLike,
            expressive: isExpressive,
            label: label,
            icon: icon,
            theme: theme,
          );
        },
      ),
    );
  }
}

class _ButtonSurface extends StatelessWidget {
  const _ButtonSurface({
    required this.style,
    required this.size,
    required this.iconOnly,
    required this.ghostLike,
    required this.expressive,
    required this.label,
    required this.icon,
    required this.theme,
  });

  final _ButtonStyle style;
  final CarbonButtonSize size;
  final bool iconOnly;
  final bool ghostLike;
  final bool expressive;
  final String label;
  final CarbonIconData? icon;
  final CarbonThemeData theme;

  // Horizontal paddings per spec (`_mixins.scss` padding-inline, with the
  // density padding-inline of 16): start 16−1; end 16×3+16−1 for standard
  // kinds, 16−1 for ghost kinds.
  static const double _padStart = 15;
  static const double _padEndStandard = 63;
  static const double _padEndGhost = 15;

  @override
  Widget build(BuildContext context) {
    final double padBlock = CarbonButton._paddingBlock(size, expressive);
    final CarbonIconData? iconData = icon;
    // Expressive buttons render 20px icons; the icon inset formula stays
    // 16px based in both modes (`.cds--btn--expressive .cds--btn__icon`
    // overrides only the icon size).
    final double iconSize = expressive
        ? CarbonButton._expressiveIconSize
        : CarbonButton._iconSize;
    final TextStyle labelStyle = expressive
        ? CarbonButton.expressiveLabelStyle
        : CarbonButton.labelStyle;

    Widget content;
    if (iconOnly) {
      content = Center(
        child: CarbonIcon(iconData!, size: iconSize, color: style.icon),
      );
    } else {
      final Widget text = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: labelStyle.copyWith(color: style.text),
      );
      // The xs variant overrides padding-block-start to a flat 1.5px
      // (`_button.scss` .cds--btn--xs rule) — a replacement, not an
      // addition. The class is dropped in expressive mode
      // (`ButtonBase.tsx`: `size === 'xs' && !isExpressive`).
      final double padTop = size == CarbonButtonSize.xs && !expressive
          ? 1.5
          : padBlock;
      if (ghostLike) {
        // Ghost icons flow inline after the label with an 8px gap.
        content = Padding(
          padding: EdgeInsetsDirectional.only(
            start: _padStart,
            end: _padEndGhost,
            top: padTop,
            bottom: padBlock,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(child: text),
              if (iconData != null) ...<Widget>[
                const SizedBox(width: 8),
                CarbonIcon(iconData, size: iconSize, color: style.icon),
              ],
            ],
          ),
        );
      } else {
        content = Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: _padStart,
                end: _padEndStandard,
                top: padTop,
                bottom: padBlock,
              ),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: 1,
                child: text,
              ),
            ),
            if (iconData != null)
              PositionedDirectional(
                end: _padStart,
                top: CarbonButton._iconTop(size),
                child: CarbonIcon(iconData, size: iconSize, color: style.icon),
              ),
          ],
        );
      }
    }

    // Fill per `button/_mixins.scss`: background / box-shadow /
    // border-color / outline $duration-fast-01 motion(entrance, productive).
    return AnimatedContainer(
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : CarbonDuration.fast01,
      curve: CarbonEasing.entranceProductive,
      // The spec height is a minimum, not a ceiling: under text scaling
      // the label's line box may exceed the fixed chrome, and the button
      // grows downward instead of clipping (docs/text-scaling.md). At
      // 1.0x the content always fits, so this renders identically to the
      // previous fixed height.
      height: iconOnly ? size.height : null,
      width: iconOnly ? size.height : null,
      constraints: iconOnly
          ? const BoxConstraints(maxWidth: CarbonButton.maxWidth)
          : BoxConstraints(
              minHeight: size.height,
              maxWidth: CarbonButton.maxWidth,
            ),
      foregroundDecoration: style.focusRing
          ? _focusRingDecoration(theme, style)
          : null,
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(width: CarbonButton._border, color: style.border),
      ),
      child: content,
    );
  }

  /// The focus visual per `_mixins.scss`: the 1px border turns `focus`
  /// colored, plus `inset 0 0 0 1px focus` and `inset 0 0 0 2px background`
  /// shadows — net: 2px focus ring at the edge, then a 2px background ring.
  /// Ghost icon-only uses only the single 1px inset (`_button.scss`).
  Decoration _focusRingDecoration(CarbonThemeData theme, _ButtonStyle style) {
    if (style.ghostIconOnlyFocus) {
      return _InsetRingsDecoration(
        rings: <(double, double, Color)>[(0, 1, theme.focus)],
      );
    }
    return _InsetRingsDecoration(
      rings: <(double, double, Color)>[
        (0, 2, theme.focus),
        (2, 2, theme.background),
      ],
    );
  }
}

/// Paints concentric inset rings (the Carbon button focus shadows).
class _InsetRingsDecoration extends Decoration {
  const _InsetRingsDecoration({required this.rings});

  /// (inset from edge, stroke width, color), outermost first.
  final List<(double, double, Color)> rings;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _InsetRingsPainter(rings);
}

class _InsetRingsPainter extends BoxPainter {
  _InsetRingsPainter(this.rings);

  final List<(double, double, Color)> rings;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size size = configuration.size!;
    for (final (double inset, double width, Color color) in rings) {
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color;
      canvas.drawRect((offset & size).deflate(inset + width / 2), paint);
    }
  }
}

/// Resolved colors for one kind × state.
class _ButtonStyle {
  const _ButtonStyle({
    required this.background,
    required this.border,
    required this.text,
    required this.icon,
    required this.focusRing,
    this.ghostIconOnlyFocus = false,
  });

  final Color background;
  final Color border;
  final Color text;
  final Color icon;
  final bool focusRing;
  final bool ghostIconOnlyFocus;

  static const Color _transparent = Color(0x00000000);

  /// The kind × state token matrix, transcribed from `_button.scss` (the
  /// `button-theme(...)` calls plus per-kind hover/focus/active/disabled
  /// overrides) and `_mixins.scss` (base disabled, focus shadows).
  static _ButtonStyle resolve({
    required CarbonThemeData theme,
    required CarbonButtonKind kind,
    required Set<WidgetState> states,
    required bool iconOnly,
    required bool isSelected,
  }) {
    final bool disabled = states.contains(WidgetState.disabled);
    final bool pressed = states.contains(WidgetState.pressed);
    final bool focused = states.contains(WidgetState.focused);
    final bool hovered = states.contains(WidgetState.hovered);

    if (disabled) {
      final bool transparentKinds =
          kind == CarbonButtonKind.tertiary ||
          kind == CarbonButtonKind.ghost ||
          kind == CarbonButtonKind.dangerTertiary ||
          kind == CarbonButtonKind.dangerGhost;
      if (transparentKinds) {
        final bool keepBorder =
            kind == CarbonButtonKind.tertiary ||
            kind == CarbonButtonKind.dangerTertiary;
        final Color iconColor = kind == CarbonButtonKind.ghost && iconOnly
            ? theme.iconOnColorDisabled
            : theme.textDisabled;
        return _ButtonStyle(
          background: _transparent,
          border: keepBorder ? theme.buttonDisabled : _transparent,
          text: theme.textDisabled,
          icon: iconColor,
          focusRing: false,
        );
      }
      return _ButtonStyle(
        background: theme.buttonDisabled,
        border: theme.buttonDisabled,
        text: theme.textOnColorDisabled,
        icon: theme.textOnColorDisabled,
        focusRing: false,
      );
    }

    Color background;
    Color border;
    Color text;
    Color? icon;
    bool ghostIconOnlyFocus = false;

    switch (kind) {
      case CarbonButtonKind.primary:
        background = pressed
            ? theme.buttonPrimaryActive
            : hovered
            ? theme.buttonPrimaryHover
            : theme.buttonPrimary;
        border = _transparent;
        text = theme.textOnColor;
      case CarbonButtonKind.secondary:
        background = pressed
            ? theme.buttonSecondaryActive
            : hovered
            ? theme.buttonSecondaryHover
            : theme.buttonSecondary;
        border = _transparent;
        text = theme.textOnColor;
      case CarbonButtonKind.tertiary:
        if (pressed) {
          background = theme.buttonTertiaryActive;
          border = _transparent;
          text = theme.textInverse;
        } else if (focused) {
          background = theme.buttonTertiary;
          border = theme.buttonTertiary;
          text = theme.textInverse;
        } else if (hovered) {
          background = theme.buttonTertiaryHover;
          border = theme.buttonTertiary;
          text = theme.textInverse;
        } else {
          background = _transparent;
          border = theme.buttonTertiary;
          text = theme.buttonTertiary;
        }
      case CarbonButtonKind.ghost:
        if (iconOnly && isSelected && !pressed && !hovered) {
          background = theme.backgroundSelected;
        } else if (pressed) {
          background = theme.backgroundActive;
        } else if (iconOnly && focused) {
          background = theme.backgroundActive;
          ghostIconOnlyFocus = true;
        } else if (hovered) {
          background = theme.backgroundHover;
        } else {
          background = _transparent;
        }
        border = _transparent;
        text = pressed || hovered ? theme.linkPrimaryHover : theme.linkPrimary;
        icon = theme.iconPrimary;
      case CarbonButtonKind.danger:
        background = pressed
            ? theme.buttonDangerActive
            : hovered
            ? theme.buttonDangerHover
            : theme.buttonDangerPrimary;
        border = _transparent;
        text = theme.textOnColor;
      case CarbonButtonKind.dangerTertiary:
        if (pressed) {
          background = theme.buttonDangerActive;
          border = theme.buttonDangerActive;
          text = theme.textOnColor;
        } else if (focused) {
          background = theme.buttonDangerPrimary;
          border = theme.buttonDangerSecondary;
          text = theme.textOnColor;
        } else if (hovered) {
          background = theme.buttonDangerHover;
          border = theme.buttonDangerHover;
          text = theme.textOnColor;
        } else {
          background = _transparent;
          border = theme.buttonDangerSecondary;
          text = theme.buttonDangerSecondary;
        }
      case CarbonButtonKind.dangerGhost:
        background = pressed
            ? theme.buttonDangerActive
            : hovered
            ? theme.buttonDangerHover
            : _transparent;
        border = _transparent;
        text = pressed || hovered
            ? theme.textOnColor
            : theme.buttonDangerSecondary;
    }

    return _ButtonStyle(
      background: background,
      border: focused && !ghostIconOnlyFocus ? theme.focus : border,
      text: text,
      icon: icon ?? text,
      focusRing: focused,
      ghostIconOnlyFocus: ghostIconOnlyFocus,
    );
  }
}
