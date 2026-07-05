// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/tile/_tile.scss (radio-tile / is-selected rules)
//   react/src/components/{RadioTile,TileGroup}
//
// Completes the deferral from the tile family (#46): single-select tiles. In
// the default (v11) treatment a RadioTile shows the CheckmarkFilled indicator
// — the same chrome as CarbonSelectableTile, but with radio single-selection.

import 'package:flutter/services.dart';
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
import '../form/carbon_form.dart';
import 'carbon_tile.dart';

/// A single-select tile with radio semantics.
///
/// Mirrors [CarbonSelectableTile]'s chrome — contextual `layer` fill,
/// `layerSelectedInverse` selection border, the 16px indicator at the
/// top-right — but uses the `CheckmarkFilled` indicator and single-select
/// (radio) behaviour. Normally built by [CarbonTileGroup]; use directly only
/// for a standalone tile.
class CarbonRadioTile extends StatelessWidget {
  /// Creates a radio tile.
  const CarbonRadioTile({
    super.key,
    required this.child,
    required this.selected,
    this.onSelected,
    this.focusNode,
    this.autofocus = false,
    this.aiLabel,
  });

  /// The tile content.
  final Widget child;

  /// An optional AI presence decorator (a `CarbonAILabel`), anchored to
  /// the tile's top end per upstream's `decorator` prop. At rest it sits
  /// in the corner (`$spacing-05`); when [selected] it slides inward to
  /// `$spacing-08`, making room for the checkmark indicator, at `fast-02`
  /// × standard-productive (`_tile.scss` `--tile--radio` AI selectors).
  final Widget? aiLabel;

  /// Whether this tile is the selected one in its group.
  final bool selected;

  /// Called when this tile is chosen; null disables it.
  final VoidCallback? onSelected;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// End padding reserving the indicator container (matches SelectableTile).
  static const double endPadding = 48;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = onSelected != null;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: onSelected,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          final bool focused = states.contains(WidgetState.focused);

          final Color border = selected
              ? (enabled
                    ? theme.layerSelectedInverse
                    : theme.layerSelectedDisabled)
              : const Color(0x00000000);
          final bool indicatorVisible =
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
                // The indicator and AI decorator sit in the reserved end
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
                      opacity: indicatorVisible ? 1 : 0,
                      child: CarbonIcon(
                        CarbonIcons.checkmarkFilled,
                        color: selected
                            ? theme.iconPrimary
                            : theme.iconSecondary,
                      ),
                    ),
                  ),
                  if (aiLabel != null)
                    AnimatedPositionedDirectional(
                      duration: CarbonDuration.fast02,
                      curve: CarbonEasing.standardProductive,
                      top: 0,
                      end:
                          (selected
                              ? CarbonSpacing.spacing08
                              : CarbonSpacing.spacing05) -
                          endPadding,
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

/// A single-select group of [CarbonRadioTile]s (`<fieldset>` + `<legend>`).
///
/// Selection is driven by [value] / [onChanged]; tiles stack vertically with
/// `spacing-03` gaps, and arrow keys (up/down) rove selection with wrap.
class CarbonTileGroup<T> extends StatefulWidget {
  /// Creates a tile group.
  const CarbonTileGroup({
    super.key,
    required this.legend,
    required this.options,
    required this.value,
    this.onChanged,
  });

  /// The group legend.
  final String legend;

  /// The options as (value, tile content) pairs.
  final List<(T value, Widget content)> options;

  /// The selected value.
  final T? value;

  /// Called with the chosen value; null disables the group.
  final ValueChanged<T>? onChanged;

  @override
  State<CarbonTileGroup<T>> createState() => _CarbonTileGroupState<T>();
}

class _CarbonTileGroupState<T> extends State<CarbonTileGroup<T>> {
  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _nodes = List<FocusNode>.generate(
      widget.options.length,
      (_) => FocusNode(),
    );
  }

  @override
  void didUpdateWidget(CarbonTileGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.length != widget.options.length) {
      for (final FocusNode node in _nodes) {
        node.dispose();
      }
      _nodes = List<FocusNode>.generate(
        widget.options.length,
        (_) => FocusNode(),
      );
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _move(int from, int delta) {
    final int count = widget.options.length;
    final int next = (from + delta + count) % count;
    widget.onChanged?.call(widget.options[next].$1);
    _nodes[next].requestFocus();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _move(index, 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _move(index, -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onChanged != null;
    return CarbonFormGroup(
      legend: widget.legend,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < widget.options.length; i++)
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : CarbonSpacing.spacing02,
              ),
              child: Focus(
                onKeyEvent: (FocusNode _, KeyEvent event) => _onKey(i, event),
                child: CarbonRadioTile(
                  selected: widget.value == widget.options[i].$1,
                  focusNode: _nodes[i],
                  onSelected: enabled
                      ? () => widget.onChanged!(widget.options[i].$1)
                      : null,
                  child: widget.options[i].$2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
