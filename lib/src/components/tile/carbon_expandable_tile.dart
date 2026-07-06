// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/tile/_tile.scss (expandable + chevron rules)
//   react/src/components/Tile/Tile.tsx (ExpandableTile)

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';
import 'carbon_tile.dart';

/// An expandable Carbon tile: above-the-fold content always shown, with
/// below-the-fold content revealed on expansion.
///
/// Controlled via [expanded] + [onExpandedChanged] (like the rest of the tile
/// family). Two modes:
///
/// * Default — the whole tile toggles; hover fills the contextual
///   `layerHover`.
/// * [interactive] — only the bottom-right chevron button toggles, leaving
///   the tile content interactive; the tile itself does not change on hover.
///
/// The height animates at `moderate-01`; the below-the-fold content fades and
/// the chevron rotates 180° at `fast-02`, matching `_tile.scss`. Layer
/// contextual like the rest of the family. When the platform requests
/// reduced motion, the fold and chevron snap instantly.
class CarbonExpandableTile extends StatelessWidget {
  /// Creates an expandable tile.
  const CarbonExpandableTile({
    super.key,
    required this.aboveTheFold,
    required this.belowTheFold,
    required this.expanded,
    this.onExpandedChanged,
    this.interactive = false,
    this.expandLabel = 'Expand',
    this.collapseLabel = 'Collapse',
    this.focusNode,
    this.autofocus = false,
    this.aiLabel,
  });

  /// Always-visible content.
  final Widget aboveTheFold;

  /// Content revealed when [expanded].
  final Widget belowTheFold;

  /// Whether the tile is expanded.
  final bool expanded;

  /// Called with the toggled value; null renders a static (non-toggling)
  /// tile.
  final ValueChanged<bool>? onExpandedChanged;

  /// Chevron-only toggle mode: the tile body stays interactive.
  final bool interactive;

  /// The accessible label when collapsed (the action expands).
  final String expandLabel;

  /// The accessible label when expanded (the action collapses).
  final String collapseLabel;

  /// An optional focus node for the toggle.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// The chevron container edge: `padding-inline * 2 + 1rem`.
  static const double chevronContainerSize = 48;

  void _toggle() => onExpandedChanged?.call(!expanded);

  /// An optional AI presence decorator (a `CarbonAILabel`), anchored to
  /// the tile's top end per upstream's `decorator` prop.
  final Widget? aiLabel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = onExpandedChanged != null;
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    // Chevron per `_tile.scss` `__chevron svg`: transform $duration-fast-02
    // motion(standard, productive).
    final Widget chevron = AnimatedRotation(
      // 180° when expanded.
      turns: expanded ? 0.5 : 0,
      duration: reducedMotion ? Duration.zero : CarbonDuration.fast02,
      curve: CarbonEasing.standardProductive,
      child: CarbonIcon(CarbonIcons.chevronDown, color: theme.iconPrimary),
    );

    // Fold per `_tile.scss` `--tile--expandable`: max-height
    // $duration-moderate-01 motion(standard, productive).
    final Widget fold = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: expanded ? 1 : 0),
      duration: reducedMotion ? Duration.zero : CarbonDuration.moderate01,
      curve: CarbonEasing.standardProductive,
      builder: (BuildContext context, double t, Widget? child) => ClipRect(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: t,
          child: Opacity(opacity: t, child: child),
        ),
      ),
      child: belowTheFold,
    );

    final Widget content = DefaultTextStyle(
      style: CarbonTypeStyles.bodyCompact01.copyWith(color: theme.textPrimary),
      child: Padding(
        padding: const EdgeInsets.all(CarbonTileSpec.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Leave room for the chevron beside the above-the-fold row.
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end:
                    CarbonExpandableTile.chevronContainerSize -
                    CarbonTileSpec.padding,
              ),
              child: aboveTheFold,
            ),
            fold,
          ],
        ),
      ),
    );

    if (interactive) {
      // Only the chevron toggles; the tile body stays interactive and its
      // background does not react to hover.
      return ColoredBox(
        color: layer.layer,
        child: Stack(
          children: <Widget>[
            content,
            PositionedDirectional(
              bottom: 0,
              end: 0,
              child: Semantics(
                button: true,
                enabled: enabled,
                expanded: expanded,
                label: expanded ? collapseLabel : expandLabel,
                child: CarbonInteraction(
                  enabled: enabled,
                  onPressed: enabled ? _toggle : null,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  builder: (BuildContext context, Set<WidgetState> states) {
                    final bool hovered = states.contains(WidgetState.hovered);
                    final bool focused = states.contains(WidgetState.focused);
                    return CarbonFocusRing(
                      visible: focused,
                      child: ColoredBox(
                        color: hovered && enabled
                            ? layer.layerHover
                            : layer.layer,
                        child: SizedBox.square(
                          dimension: CarbonExpandableTile.chevronContainerSize,
                          child: Center(child: chevron),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Whole-tile toggle: tapping anywhere expands/collapses.
    return Semantics(
      button: true,
      enabled: enabled,
      expanded: expanded,
      label: expanded ? collapseLabel : expandLabel,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: enabled ? _toggle : null,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          final bool focused = states.contains(WidgetState.focused);
          return CarbonFocusRing(
            visible: focused,
            child: ColoredBox(
              color: hovered && enabled ? layer.layerHover : layer.layer,
              child: Stack(
                children: <Widget>[
                  content,
                  PositionedDirectional(
                    bottom: 0,
                    end: 0,
                    child: SizedBox.square(
                      dimension: CarbonExpandableTile.chevronContainerSize,
                      child: Center(child: chevron),
                    ),
                  ),
                  // The AI label anchors to the tile's top end
                  // (`_tile.scss` $spacing-05 insets).
                  if (aiLabel != null)
                    PositionedDirectional(
                      top: CarbonSpacing.spacing05,
                      end: CarbonSpacing.spacing05,
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
