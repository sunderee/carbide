// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/list-box/_list-box.scss
//   react/src/components/ListBox/{ListBox,ListBoxField,ListBoxMenu,
//     ListBoxMenuItem,ListBoxMenuIcon,ListBoxSelection}
//
// ListBox is the shared, presentational chrome behind Dropdown, ComboBox and
// MultiSelect — the field trigger surface, the popup menu, its option rows,
// the chevron, and the clear / count selection controls. Like Carbon's
// ListBox, it carries no selection state of its own: each consumer drives
// `expanded`, `isHighlighted`, `isSelected`, etc. (Carbon does this with a
// Downshift hook per consumer.)

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
import '../../utils/menu_shadow.dart';
import '../../utils/scroll_into_view.dart';
import '../form/carbon_form.dart' show CarbonField, CarbonFieldSize;

/// The field trigger surface for a list-box control.
///
/// Renders the value (or placeholder) [child], an optional [selection] control
/// (clear button or count), and the rotating chevron. State — open/closed,
/// validation, focus — is supplied by the consumer; this widget only paints the
/// chrome (background, hover, bottom border, focus ring) to `_list-box.scss`.
class CarbonListBox extends StatefulWidget {
  /// Creates a list-box field surface.
  const CarbonListBox({
    required this.child,
    this.size = CarbonFieldSize.md,
    this.expanded = false,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.warn = false,
    this.focused = false,
    this.selection,
    this.onTap,
    this.includeSemantics = true,
    this.aiLabel,
    this.aiRevert = false,
    this.fluid = false,
    this.fluidLabel,
    super.key,
  }) : assert(!(invalid && warn), 'A field cannot be both invalid and warn.'),
       assert(
         !fluid || fluidLabel != null,
         'fluid list boxes render their label inside the field.',
       );

  /// The value or placeholder shown in the field.
  final Widget child;

  /// The minimum field height: sm/md/lg = 32/40/48. Text scaling can grow it.
  final CarbonFieldSize size;

  /// Whether the menu is open (rotates the chevron and softens the border).
  final bool expanded;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered before
  /// the menu chevron per upstream's `decorator` prop (`_list-box.scss`
  /// inset-inline-end calc($spacing-08 + 9px)); adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// The fluid treatment (`_fluid-list-box.scss`): a 64px field with the
  /// label rendered inside above the value.
  final bool fluid;

  /// The label shown inside a [fluid] field.
  final String? fluidLabel;

  /// Whether the control is disabled.
  final bool disabled;

  /// Paints a transparent, non-editable field without hover or tap feedback.
  final bool readOnly;

  /// Whether the control is in an error state.
  final bool invalid;

  /// Whether the control is in a warning state.
  final bool warn;

  /// Whether the field owns keyboard focus (draws the focus ring).
  final bool focused;

  /// An optional clear button or selection count, shown before the chevron.
  final Widget? selection;

  /// Called when the field is tapped.
  final VoidCallback? onTap;

  /// Whether the field gesture contributes a tap semantics action.
  ///
  /// Consumers that own named trigger semantics set this to false.
  final bool includeSemantics;

  @override
  State<CarbonListBox> createState() => _CarbonListBoxState();
}

class _CarbonListBoxState extends State<CarbonListBox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled && !widget.readOnly;

    // _list-box.scss: background $field, hover $field-hover; disabled keeps
    // $field (no hover).
    final Color background = widget.readOnly && !widget.disabled
        ? const Color(0x00000000)
        : enabled && _hovered
        ? layer.fieldHover
        : layer.field;
    final Color textColor = widget.disabled
        ? theme.textDisabled
        : theme.textPrimary;

    // The AI treatment: aura gradient + ai-border-strong bottom border.
    final bool ai =
        widget.aiLabel != null && !widget.aiRevert && !widget.readOnly;

    // bottom border: 1px $border-strong, $border-subtle when expanded,
    // transparent when disabled (_list-box.scss).
    final Color borderColor = widget.disabled
        ? const Color(0x00000000)
        : widget.readOnly || widget.expanded
        ? layer.borderSubtle
        : ai
        ? theme.aiBorderStrong
        : theme.borderStrong01;

    // invalid draws a 2px support-error ring on all sides (shared field
    // treatment); warning keeps the bottom border and adds its icon.
    final Border border = widget.invalid && enabled
        ? Border.all(color: theme.supportError, width: 2)
        : Border(bottom: BorderSide(color: borderColor));

    final List<Widget> trailing = <Widget>[
      if (widget.invalid)
        CarbonIcon(CarbonIcons.errorFilled, color: theme.supportError)
      else if (widget.warn)
        CarbonIcon(CarbonIcons.warningAltFilled, color: theme.supportWarning),
      if (widget.selection != null) widget.selection!,
      // The AI label sits before the menu chevron (`_list-box.scss`
      // inset-inline-end calc($spacing-08 + 9px)).
      ?widget.aiLabel,
      CarbonListBoxMenuIcon(
        open: widget.expanded,
        disabled: widget.disabled || widget.readOnly,
        small: widget.fluid,
      ),
    ];

    return MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : widget.readOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: !widget.includeSemantics,
        onTap: enabled ? widget.onTap : null,
        child: CarbonFocusRing(
          visible: widget.focused,
          inset: true,
          child: AnimatedContainer(
            duration: carbonDuration(context, CarbonDuration.fast01),
            curve: CarbonEasing.standardProductive,
            constraints: BoxConstraints(
              minHeight: widget.fluid ? 64 : widget.size.height,
            ),
            decoration: BoxDecoration(
              color: background,
              gradient: ai ? CarbonField.aiFieldGradient(theme) : null,
              border: border,
            ),
            // Preserve a clear inset focus band when text determines height.
            padding: const EdgeInsetsDirectional.only(
              start: CarbonSpacing.spacing05,
              end: CarbonSpacing.spacing04,
              top: CarbonSpacing.spacing01,
              bottom: CarbonSpacing.spacing01,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    // Fluid stacks the label-01 label above the value
                    // (`_fluid-list-box.scss` label at 13px / field padded
                    // 33px — rendered with the house centered-column fluid
                    // treatment shared with Select and Text Input).
                    child: widget.fluid
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ExcludeSemantics(
                                child: Text(
                                  widget.fluidLabel!,
                                  style: CarbonTypeStyles.label01.copyWith(
                                    color: widget.disabled
                                        ? theme.textDisabled
                                        : theme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              widget.child,
                            ],
                          )
                        : widget.child,
                  ),
                ),
                for (final Widget w in trailing) ...<Widget>[
                  const SizedBox(width: CarbonSpacing.spacing03),
                  w,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The chevron at the end of a [CarbonListBox] field, rotating 180° when open.
class CarbonListBoxMenuIcon extends StatelessWidget {
  /// Creates the menu chevron.
  const CarbonListBoxMenuIcon({
    required this.open,
    this.disabled = false,
    this.small = false,
    super.key,
  });

  /// Whether the menu is open (rotates the chevron).
  final bool open;

  /// Whether the host control is disabled (greys the icon).
  final bool disabled;

  /// The 16px fluid variant (`_fluid-list-box.scss` menu-icon 1rem).
  final bool small;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    // _list-box.scss: 24x24 box, transform rotate(180deg) when open,
    // transition transform fast-01; fluid shrinks the box to 16px.
    return SizedBox.square(
      dimension: small ? 16 : 24,
      child: Center(
        child: AnimatedRotation(
          turns: open ? 0.5 : 0,
          duration: carbonDuration(context, CarbonDuration.fast01),
          curve: CarbonEasing.standardProductive,
          child: CarbonIcon(
            CarbonIcons.chevronDown,
            color: disabled ? theme.iconDisabled : theme.iconPrimary,
          ),
        ),
      ),
    );
  }
}

/// The popup list of options under a [CarbonListBox].
///
/// Consumers render this inside an `OverlayPortal` anchored to the field. It
/// shows at most 5.5 rows (`max-block-size` per size) before scrolling.
class CarbonListBoxMenu extends StatelessWidget {
  /// Creates a list-box menu wrapping [children] option rows.
  const CarbonListBoxMenu({
    required this.children,
    this.size = CarbonFieldSize.md,
    this.fluidRows = false,
    super.key,
  });

  /// The option rows (typically [CarbonListBoxMenuItem]s).
  final List<Widget> children;

  /// The host field size, which sets the visible-row cap.
  final CarbonFieldSize size;

  /// Whether rows render at the 64px fluid height (`_fluid-list-box.scss`;
  /// the condensed fluid variant keeps standard rows).
  final bool fluidRows;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final CarbonThemeData theme = CarbonTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: layer.layer,
        boxShadow: <BoxShadow>[carbonMenuShadow(theme.shadow)],
      ),
      child: ConstrainedBox(
        // _list-box.scss: 5.5 rows of the item height (40 -> 220, etc.).
        constraints: BoxConstraints(
          maxHeight: (fluidRows ? 64 : size.height) * 5.5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A single option row inside a [CarbonListBoxMenu].
///
/// [isHighlighted] marks the keyboard-roved row (focus ring + emphasised
/// text); [isActive] marks the currently selected value. A top divider
/// separates rows, suppressed on the first row and around the highlighted row,
/// matching `_list-box.scss`.
class CarbonListBoxMenuItem extends StatefulWidget {
  /// Creates a list-box option row.
  const CarbonListBoxMenuItem({
    required this.child,
    this.size = CarbonFieldSize.md,
    this.fluid = false,
    this.isHighlighted = false,
    this.isActive = false,
    this.isFirst = false,
    this.disabled = false,
    this.onTap,
    super.key,
  });

  /// The row contents (typically the option label, plus a trailing checkmark
  /// the consumer adds for the selected value).
  final Widget child;

  /// The host field size, which sets the row height.
  final CarbonFieldSize size;

  /// Whether the row renders at the 64px fluid height.
  final bool fluid;

  /// Whether this row is keyboard-highlighted.
  final bool isHighlighted;

  /// Whether this row is the selected value.
  final bool isActive;

  /// Whether this is the first row (suppresses its top divider).
  final bool isFirst;

  /// Whether the row is disabled.
  final bool disabled;

  /// Called when the row is tapped.
  final VoidCallback? onTap;

  @override
  State<CarbonListBoxMenuItem> createState() => _CarbonListBoxMenuItemState();
}

class _CarbonListBoxMenuItemState extends State<CarbonListBoxMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled;
    final bool emphasised =
        enabled && (widget.isActive || widget.isHighlighted || _hovered);

    // _list-box.scss: active -> $layer-selected; hover/highlighted ->
    // $layer-hover; otherwise transparent.
    final Color background = !enabled
        ? const Color(0x00000000)
        : widget.isActive
        ? layer.layerSelected
        : widget.isHighlighted || _hovered
        ? layer.layerHover
        : const Color(0x00000000);

    final Color textColor = widget.disabled
        ? theme.textDisabled
        : emphasised
        ? theme.textPrimary
        : theme.textSecondary;

    // 1px $border-subtle top divider, transparent on the first row and around
    // the highlighted row.
    final bool showDivider =
        !widget.isFirst && !widget.isHighlighted && !_hovered;
    final Color dividerColor = showDivider
        ? layer.borderSubtle
        : const Color(0x00000000);

    // The keyboard-roved row keeps itself inside the 5.5-row fold (#279).
    return CarbonScrollIntoView(
      active: widget.isHighlighted,
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.disabled ? null : widget.onTap,
          child: CarbonFocusRing(
            visible: widget.isHighlighted,
            inset: true,
            child: ColoredBox(
              color: background,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: widget.fluid ? 64 : widget.size.height,
                ),
                // The divider sits inside a spacing-05 inset
                // (`margin: 0 16px`).
                margin: const EdgeInsetsDirectional.symmetric(
                  horizontal: CarbonSpacing.spacing05,
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: dividerColor)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: CarbonSpacing.spacing01,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    heightFactor: 1,
                    child: DefaultTextStyle.merge(
                      style: CarbonTypeStyles.bodyCompact01.copyWith(
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The clear (X) control inside a [CarbonListBox] field.
class CarbonListBoxSelection extends StatelessWidget {
  /// Creates a clear control.
  const CarbonListBoxSelection({
    required this.onClear,
    this.disabled = false,
    this.semanticLabel = 'Clear selection',
    super.key,
  });

  /// Called when the control is tapped.
  final VoidCallback onClear;

  /// Whether the host control is disabled.
  final bool disabled;

  /// The accessible label for the clear control.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : onClear,
      child: SizedBox.square(
        // _list-box.scss: 24x24 selection button.
        dimension: 24,
        child: Center(
          child: CarbonIcon(
            CarbonIcons.close,
            color: disabled ? theme.iconDisabled : theme.iconPrimary,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}

/// The multi-select count badge (a pill showing how many items are selected
/// with an inline clear control).
class CarbonListBoxSelectionCount extends StatelessWidget {
  /// Creates a selection-count badge.
  const CarbonListBoxSelectionCount({
    required this.count,
    required this.onClear,
    this.disabled = false,
    this.readOnly = false,
    super.key,
  });

  /// The number of selected items.
  final int count;

  /// Called when the inline clear control is tapped.
  final VoidCallback onClear;

  /// Whether the host control is disabled.
  final bool disabled;

  /// Keeps the count visible while hiding its editing affordance.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    // disabled: tag-theme($text-disabled, $layer).
    final Color background = disabled ? layer.layer : theme.backgroundInverse;
    final Color foreground = disabled ? theme.textDisabled : theme.textInverse;
    final Color iconColor = disabled ? theme.iconDisabled : theme.iconInverse;

    // The SCSS pill is `block-size: 24px` with `padding: 8px` but
    // `line-height: 0` + `align-items: center`, so the label and the 20px
    // close icon overflow the padding box and stay vertically centered. A
    // Flutter `Container(height: 24, padding-block: 8)` instead *clamps* the
    // child to 8px and clips the count glyph to an illegible sliver. Reproduce
    // the CSS result faithfully: minimum 24px height, horizontal-only padding,
    // and a centered row that lets the content use the full height.
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: EdgeInsetsDirectional.only(start: 8, end: readOnly ? 8 : 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$count',
            style: CarbonTypeStyles.label01.copyWith(color: foreground),
          ),
          if (!readOnly) ...<Widget>[
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: disabled ? null : onClear,
              // `> svg { padding: 2px; block-size: 20px }` — a 16px glyph in a
              // 20px box.
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: CarbonIcon(
                  CarbonIcons.close,
                  size: 16,
                  color: iconColor,
                  semanticLabel: 'Clear all selected items',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
