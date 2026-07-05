// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/tile/_tile.scss
//   react/src/components/Tile/Tile.tsx (Tile, ClickableTile, SelectableTile)
// RadioTile (single-select) is deferred with the radio-button visuals
// (Tier B forms); ExpandableTile is tracked as its own follow-up issue.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';

/// Shared tile geometry per `_tile.scss`.
abstract final class CarbonTileSpec {
  /// Minimum tile height (4rem).
  static const double minHeight = 64;

  /// Minimum tile width (8rem).
  static const double minWidth = 128;

  /// Tile padding (the density `padding-inline`).
  static const double padding = 16;
}

/// A static Carbon tile: a contextual surface for grouped content.
///
/// Fills the ambient layer token, so tiles nested in a [CarbonLayer] pick
/// the next layer step automatically. Content defaults to `body-compact-01`
/// in `textPrimary`.
class CarbonTile extends StatelessWidget {
  /// Creates a static tile.
  const CarbonTile({super.key, required this.child, this.aiLabel});

  /// The tile content.
  final Widget child;

  /// An optional AI presence decorator (a `CarbonAILabel`), anchored to the
  /// tile's top end per upstream's `decorator` prop (`_tile.scss`
  /// inset-block-start/inset-inline-end $spacing-05).
  final Widget? aiLabel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Widget tile = Container(
      constraints: const BoxConstraints(
        minHeight: CarbonTileSpec.minHeight,
        minWidth: CarbonTileSpec.minWidth,
      ),
      padding: const EdgeInsets.all(CarbonTileSpec.padding),
      color: CarbonLayer.of(context).layer,
      child: DefaultTextStyle(
        style: CarbonTypeStyles.bodyCompact01.copyWith(
          color: theme.textPrimary,
        ),
        child: child,
      ),
    );
    if (aiLabel == null) {
      return tile;
    }
    return Stack(
      // Pass the incoming constraints through so the tile still fills a
      // tight parent (a bare Stack would loosen them).
      fit: StackFit.passthrough,
      children: <Widget>[
        tile,
        PositionedDirectional(
          top: CarbonTileSpec.padding,
          end: CarbonTileSpec.padding,
          child: aiLabel!,
        ),
      ],
    );
  }
}

/// A clickable Carbon tile: a single interactive region.
///
/// Hover fills the contextual `layerHover` token, keyboard focus shows the
/// 2px inset focus outline, and the optional [icon] renders 20px at the
/// bottom-right in `iconInteractive` (`iconDisabled` when disabled). The
/// background transitions at `moderate-01` × standard-productive.
class CarbonClickableTile extends StatelessWidget {
  /// Creates a clickable tile.
  const CarbonClickableTile({
    super.key,
    required this.child,
    this.onPressed,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.aiLabel,
  });

  /// The tile content.
  final Widget child;

  /// An optional AI presence decorator (a `CarbonAILabel`), anchored to
  /// the tile's top end per upstream's `decorator` prop.
  final Widget? aiLabel;

  /// Called on activation; null renders the disabled state.
  final VoidCallback? onPressed;

  /// Optional decorative 20px icon at the bottom-right (e.g. arrow-right).
  final CarbonIconData? icon;

  /// An optional focus node to control focus externally.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = onPressed != null;

    return Semantics(
      button: true,
      enabled: enabled,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          final bool focused = states.contains(WidgetState.focused);
          final Color text = enabled ? theme.textPrimary : theme.textDisabled;
          final CarbonIconData? cornerIcon = icon;

          return CarbonFocusRing(
            visible: focused,
            child: AnimatedContainer(
              duration: CarbonDuration.moderate01,
              curve: CarbonEasing.standardProductive,
              constraints: const BoxConstraints(
                minHeight: CarbonTileSpec.minHeight,
                minWidth: CarbonTileSpec.minWidth,
              ),
              color: hovered && enabled ? layer.layerHover : layer.layer,
              padding: const EdgeInsets.all(CarbonTileSpec.padding),
              child: Stack(
                // The corner icon is inset 12px from the tile edge, which
                // places it inside the 16px padding and therefore 4px outside
                // the Stack's content box. Don't clip it (the default
                // `Clip.hardEdge` would cut the overflowing 4px).
                clipBehavior: Clip.none,
                children: <Widget>[
                  DefaultTextStyle(
                    style: CarbonTypeStyles.bodyCompact01.copyWith(color: text),
                    child: child,
                  ),
                  if (cornerIcon != null)
                    PositionedDirectional(
                      // 12px insets from the tile edge; the Stack sits
                      // inside the 16px padding.
                      end: 12 - CarbonTileSpec.padding,
                      bottom: 12 - CarbonTileSpec.padding,
                      child: CarbonIcon(
                        cornerIcon,
                        size: 20,
                        color: enabled
                            ? theme.iconInteractive
                            : theme.iconDisabled,
                      ),
                    ),
                  // The AI label anchors to the tile's top end, 16px in
                  // (the Stack sits inside the 16px padding).
                  if (aiLabel != null)
                    PositionedDirectional(top: 0, end: 0, child: aiLabel!),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A multi-selectable Carbon tile with checkbox semantics.
///
/// Shows a 16px checkmark at the top-right — `checkbox` outline in
/// `iconSecondary` while hovered/focused, `checkbox--checked--filled` in
/// `iconPrimary` when selected — fading at `fast-02` × standard-productive.
/// Selection draws a 1px `layerSelectedInverse` border
/// (`layerSelectedDisabled` when disabled). Single-select tiles (upstream
/// `RadioTile`) arrive with the radio-button visuals.
class CarbonSelectableTile extends StatelessWidget {
  /// Creates a selectable tile.
  const CarbonSelectableTile({
    super.key,
    required this.child,
    required this.selected,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.aiLabel,
  });

  /// The tile content.
  final Widget child;

  /// An optional AI presence decorator (a `CarbonAILabel`), sharing the
  /// tile's top-end corner with the checkmark per upstream's `decorator`
  /// prop: the label anchors at `$spacing-08` from the tile end, beside
  /// the 16px icon slot (`_tile.scss` `--tile--selectable` AI selectors).
  final Widget? aiLabel;

  /// Whether the tile is selected.
  final bool selected;

  /// Called with the toggled value; null renders the disabled state.
  final ValueChanged<bool>? onChanged;

  /// An optional focus node to control focus externally.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// The checkmark icon edge (1rem) and its inset (density padding).
  static const double checkmarkSize = 16;

  /// The selectable tile's end padding reserves the icon container
  /// (2 × 16 + 16).
  static const double endPadding = 48;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = onChanged != null;

    return Semantics(
      checked: selected,
      enabled: enabled,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: enabled ? () => onChanged!(!selected) : null,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          final bool focused = states.contains(WidgetState.focused);

          final Color border;
          if (selected) {
            border = enabled
                ? theme.layerSelectedInverse
                : theme.layerSelectedDisabled;
          } else {
            border = const Color(0x00000000);
          }
          final bool checkmarkVisible =
              selected || ((hovered || focused) && enabled);

          return CarbonFocusRing(
            visible: focused,
            child: AnimatedContainer(
              duration: CarbonDuration.moderate01,
              curve: CarbonEasing.standardProductive,
              constraints: const BoxConstraints(
                minHeight: CarbonTileSpec.minHeight,
                minWidth: CarbonTileSpec.minWidth,
              ),
              decoration: BoxDecoration(
                color: hovered && enabled ? layer.layerHover : layer.layer,
                border: Border.all(color: border),
              ),
              padding: const EdgeInsetsDirectional.only(
                start: CarbonTileSpec.padding,
                top: CarbonTileSpec.padding,
                bottom: CarbonTileSpec.padding,
                end: endPadding,
              ),
              child: Stack(
                // The checkmark and AI decorator sit in the reserved end
                // padding, outside the Stack's content box, so they must
                // not be clipped.
                clipBehavior: Clip.none,
                children: <Widget>[
                  DefaultTextStyle(
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: enabled ? theme.textPrimary : theme.textDisabled,
                    ),
                    child: child,
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: CarbonTileSpec.padding - endPadding,
                    child: AnimatedOpacity(
                      duration: CarbonDuration.fast02,
                      curve: CarbonEasing.standardProductive,
                      opacity: checkmarkVisible ? 1 : 0,
                      child: CarbonIcon(
                        selected
                            ? CarbonIcons.checkboxCheckedFilled
                            : CarbonIcons.checkbox,
                        color: selected
                            ? theme.iconPrimary
                            : theme.iconSecondary,
                      ),
                    ),
                  ),
                  if (aiLabel != null)
                    PositionedDirectional(
                      top: 0,
                      end: CarbonSpacing.spacing08 - endPadding,
                      child: aiLabel!,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
