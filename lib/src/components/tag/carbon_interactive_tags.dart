// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/tag/{_tag,_mixins}.scss
//   react/src/components/Tag/{DismissibleTag,SelectableTag,OperationalTag}.tsx

import 'package:flutter/widgets.dart';

import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';
import 'carbon_tag.dart';

/// The interactive-tag focus indicator: a 2px `focus` ring offset 1px
/// outside the pill (`outline: 2px solid $focus; outline-offset: 1px`).
class _OuterFocusRing extends Decoration {
  const _OuterFocusRing({required this.color});

  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _OuterFocusRingPainter(color);
}

class _OuterFocusRingPainter extends BoxPainter {
  _OuterFocusRingPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect bounds = (offset & configuration.size!).inflate(2);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bounds,
        const Radius.circular(CarbonTag.radius + 2),
      ),
      paint,
    );
  }
}

/// A tag with a dismiss ("filter") button.
///
/// The pill itself is not interactive; only the circular close button is.
/// Its hover fill uses the tag type's hover token, and keyboard focus shows
/// the 1px inset ring (`focusInverse` on high-contrast tags), per spec.
class CarbonDismissibleTag extends StatelessWidget {
  /// Creates a dismissible tag.
  const CarbonDismissibleTag({
    super.key,
    required this.label,
    this.onClose,
    this.type = CarbonTagType.gray,
    this.size = CarbonTagSize.md,
    this.icon,
    this.dismissLabel = 'Dismiss',
  });

  /// The tag text.
  final String label;

  /// Called when the close button activates; null disables the tag.
  final VoidCallback? onClose;

  /// The color type.
  final CarbonTagType type;

  /// The size.
  final CarbonTagSize size;

  /// Optional 16px leading icon.
  final CarbonIconData? icon;

  /// The accessible label of the close button.
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonTagColors colors = CarbonTagColors.resolve(theme, type);
    final bool disabled = onClose == null;
    final Color background = disabled
        ? CarbonLayer.of(context).layer
        : colors.background;
    final Color text = disabled ? theme.textDisabled : colors.text;
    final Color focusRing = type == CarbonTagType.highContrast
        ? theme.focusInverse
        : theme.focus;

    return TagSurface(
      size: size,
      background: background,
      text: text,
      outline: disabled ? null : colors.outline,
      icon: icon,
      label: label,
      endPadding: 0,
      trailing: Padding(
        padding: EdgeInsetsDirectional.only(
          start: size == CarbonTagSize.sm ? 5 : 2,
        ),
        child: Semantics(
          button: true,
          enabled: !disabled,
          label: '$dismissLabel $label',
          child: CarbonInteraction(
            enabled: !disabled,
            onPressed: onClose,
            builder: (BuildContext context, Set<WidgetState> states) {
              final bool hovered = states.contains(WidgetState.hovered);
              final bool focused = states.contains(WidgetState.focused);
              return Container(
                width: size.height,
                height: size.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hovered && !disabled
                      ? colors.hover
                      : const Color(0x00000000),
                  border: focused ? Border.all(color: focusRing) : null,
                ),
                child: Center(
                  child: CarbonIcon(
                    CarbonIcons.close,
                    color: disabled ? theme.iconDisabled : text,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A toggleable tag (`SelectableTag`).
///
/// Uncolored by design: it draws on the layer-contextual `layer` tokens with
/// a `borderInverse` outline, fills `layerSelectedInverse` when selected,
/// and shows the outer 2px focus ring on keyboard focus.
class CarbonSelectableTag extends StatelessWidget {
  /// Creates a selectable tag.
  const CarbonSelectableTag({
    super.key,
    required this.label,
    required this.selected,
    this.onChanged,
    this.size = CarbonTagSize.md,
    this.icon,
  });

  /// The tag text.
  final String label;

  /// Whether the tag is selected.
  final bool selected;

  /// Called with the toggled value; null disables the tag.
  final ValueChanged<bool>? onChanged;

  /// The size.
  final CarbonTagSize size;

  /// Optional 16px leading icon.
  final CarbonIconData? icon;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool disabled = onChanged == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      label: label,
      child: CarbonInteraction(
        enabled: !disabled,
        onPressed: disabled ? null : () => onChanged!(!selected),
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          final bool focused = states.contains(WidgetState.focused);

          final Color background;
          final Color text;
          final Color border;
          if (disabled) {
            background = layer.layer;
            text = theme.textDisabled;
            border = theme.borderDisabled;
          } else if (selected) {
            background = theme.layerSelectedInverse;
            text = theme.textInverse;
            border = theme.layerSelectedInverse;
          } else {
            background = hovered ? layer.layerHover : layer.layer;
            text = theme.textPrimary;
            border = theme.borderInverse;
          }

          return Container(
            foregroundDecoration: focused
                ? _OuterFocusRing(color: theme.focus)
                : null,
            child: ExcludeSemantics(
              child: TagSurface(
                size: size,
                background: background,
                text: text,
                border: border,
                icon: icon,
                label: label,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A clickable tag (`OperationalTag`) that triggers an action, e.g. viewing
/// a filtered list. Colored like read-only tags but with a 1px border in the
/// type's border token and a hover fill.
class CarbonOperationalTag extends StatelessWidget {
  /// Creates an operational tag.
  const CarbonOperationalTag({
    super.key,
    required this.label,
    this.focusNode,
    this.onPressed,
    this.type = CarbonTagType.gray,
    this.size = CarbonTagSize.md,
    this.icon,
  });

  /// The tag text.
  final String label;

  /// An optional caller-owned focus node for the tag action.
  final FocusNode? focusNode;

  /// Called on activation; null disables the tag.
  final VoidCallback? onPressed;

  /// The color type.
  final CarbonTagType type;

  /// The size.
  final CarbonTagSize size;

  /// Optional 16px leading icon.
  final CarbonIconData? icon;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final CarbonTagColors colors = CarbonTagColors.resolve(theme, type);
    final bool disabled = onPressed == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: CarbonInteraction(
        focusNode: focusNode,
        enabled: !disabled,
        onPressed: onPressed,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          final bool focused = states.contains(WidgetState.focused);

          final Color background;
          final Color text;
          final Color border;
          if (disabled) {
            background = layer.layer;
            text = theme.textDisabled;
            border = theme.borderDisabled;
          } else {
            background = hovered ? colors.hover : colors.background;
            text = colors.text;
            border = colors.border;
          }

          return Container(
            foregroundDecoration: focused
                ? _OuterFocusRing(color: theme.focus)
                : null,
            child: ExcludeSemantics(
              child: TagSurface(
                size: size,
                background: background,
                text: text,
                border: border,
                icon: icon,
                label: label,
              ),
            ),
          );
        },
      ),
    );
  }
}
