// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/{overflow-menu,menu-button,combo-button}
//   react/src/components/{OverflowMenu,MenuButton,ComboButton}
//
// Three triggers over the Menu primitive (#92): an icon (OverflowMenu), a
// labelled button (MenuButton) and a split action button (ComboButton). The
// menu owns roving/type-ahead/Escape; these widgets own the trigger and the
// overlay anchoring.
//
// The Menu-based architecture is upstream's `enable-v12-overflowmenu`
// flagged behavior, adopted deliberately — the unflagged v10-style
// OverflowMenu is what Carbon v12 removes (ADR 0002).

import 'package:flutter/widgets.dart';

import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../button/carbon_button.dart';
import '../menu/carbon_menu.dart';

/// Which trigger edge the menu aligns to.
enum CarbonMenuAlignment {
  /// The menu's start edge aligns with the trigger's start edge.
  start,

  /// The menu's end edge aligns with the trigger's end edge.
  end,
}

/// An icon button (⋮) that opens a [CarbonMenu] of actions.
///
/// ```dart
/// CarbonOverflowMenu(
///   items: <Widget>[
///     CarbonMenuItem(label: 'Edit', onPressed: _edit),
///     CarbonMenuItem(label: 'Delete', kind: CarbonMenuItemKind.danger,
///         onPressed: _delete),
///   ],
/// )
/// ```
class CarbonOverflowMenu extends StatelessWidget {
  /// Creates an overflow menu.
  const CarbonOverflowMenu({
    required this.items,
    super.key,
    this.size = CarbonMenuSize.sm,
    this.buttonSize = CarbonButtonSize.sm,
    this.menuAlignment = CarbonMenuAlignment.end,
    this.iconDescription = 'Options',
  });

  /// The menu rows.
  final List<Widget> items;

  /// The menu row height.
  final CarbonMenuSize size;

  /// The icon-button size.
  final CarbonButtonSize buttonSize;

  /// Which edge the menu aligns to.
  final CarbonMenuAlignment menuAlignment;

  /// The accessible label for the trigger.
  final String iconDescription;

  @override
  Widget build(BuildContext context) {
    return _AnchoredMenu(
      items: items,
      menuSize: size,
      menuAlignment: menuAlignment,
      triggerBuilder: (BuildContext context, bool open, VoidCallback toggle) =>
          CarbonButton.iconOnly(
            icon: CarbonIcons.overflowMenuVertical,
            iconDescription: iconDescription,
            kind: CarbonButtonKind.ghost,
            size: buttonSize,
            isSelected: open,
            onPressed: toggle,
          ),
    );
  }
}

/// A labelled button with a chevron that opens a [CarbonMenu].
class CarbonMenuButton extends StatelessWidget {
  /// Creates a menu button.
  const CarbonMenuButton({
    required this.label,
    required this.items,
    super.key,
    this.kind = CarbonButtonKind.primary,
    this.size = CarbonButtonSize.lg,
    this.menuSize = CarbonMenuSize.sm,
    this.menuAlignment = CarbonMenuAlignment.start,
  });

  /// The button label.
  final String label;

  /// The menu rows.
  final List<Widget> items;

  /// The button kind.
  final CarbonButtonKind kind;

  /// The button size.
  final CarbonButtonSize size;

  /// The menu row height.
  final CarbonMenuSize menuSize;

  /// Which edge the menu aligns to.
  final CarbonMenuAlignment menuAlignment;

  @override
  Widget build(BuildContext context) {
    return _AnchoredMenu(
      items: items,
      menuSize: menuSize,
      menuAlignment: menuAlignment,
      triggerBuilder: (BuildContext context, bool open, VoidCallback toggle) =>
          CarbonButton(
            label: label,
            icon: CarbonIcons.chevronDown,
            kind: kind,
            size: size,
            onPressed: toggle,
          ),
    );
  }
}

/// A split button: a primary action plus a chevron opening a [CarbonMenu] of
/// secondary actions.
class CarbonComboButton extends StatelessWidget {
  /// Creates a combo button.
  const CarbonComboButton({
    required this.label,
    required this.onPressed,
    required this.items,
    super.key,
    this.kind = CarbonButtonKind.primary,
    this.size = CarbonButtonSize.lg,
    this.menuSize = CarbonMenuSize.sm,
    this.menuAlignment = CarbonMenuAlignment.end,
    this.menuLabel = 'Additional actions',
  });

  /// The primary action label.
  final String label;

  /// The primary action.
  final VoidCallback? onPressed;

  /// The secondary menu rows.
  final List<Widget> items;

  /// The button kind.
  final CarbonButtonKind kind;

  /// The button size.
  final CarbonButtonSize size;

  /// The menu row height.
  final CarbonMenuSize menuSize;

  /// Which edge the menu aligns to.
  final CarbonMenuAlignment menuAlignment;

  /// The accessible label for the chevron trigger.
  final String menuLabel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarbonButton(
            label: label,
            kind: kind,
            size: size,
            onPressed: onPressed,
          ),
          // A 1px divider separates the two halves of the split button.
          SizedBox(width: 1, child: ColoredBox(color: theme.borderSubtle00)),
          _AnchoredMenu(
            items: items,
            menuSize: menuSize,
            menuAlignment: menuAlignment,
            triggerBuilder:
                (BuildContext context, bool open, VoidCallback toggle) =>
                    CarbonButton.iconOnly(
                      icon: CarbonIcons.chevronDown,
                      iconDescription: menuLabel,
                      kind: kind,
                      size: size,
                      // isSelected only applies to ghost buttons.
                      isSelected: kind == CarbonButtonKind.ghost && open,
                      onPressed: toggle,
                    ),
          ),
        ],
      ),
    );
  }
}

/// Shared anchoring: a trigger that opens a [CarbonMenu] in an overlay beneath
/// it, dismissing on outside tap or the menu's own close.
class _AnchoredMenu extends StatefulWidget {
  const _AnchoredMenu({
    required this.items,
    required this.menuSize,
    required this.menuAlignment,
    required this.triggerBuilder,
  });

  final List<Widget> items;
  final CarbonMenuSize menuSize;
  final CarbonMenuAlignment menuAlignment;
  final Widget Function(BuildContext context, bool open, VoidCallback toggle)
  triggerBuilder;

  @override
  State<_AnchoredMenu> createState() => _AnchoredMenuState();
}

class _AnchoredMenuState extends State<_AnchoredMenu> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final Object _group = UniqueKey();

  void _toggle() {
    _overlay.isShowing ? _close() : _open();
  }

  void _open() {
    _overlay.show();
    setState(() {});
  }

  void _close() {
    _overlay.hide();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: _group,
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _overlay,
          overlayChildBuilder: _buildMenu,
          child: widget.triggerBuilder(context, _overlay.isShowing, _toggle),
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final bool end = widget.menuAlignment == CarbonMenuAlignment.end;
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: end ? Alignment.bottomRight : Alignment.bottomLeft,
        followerAnchor: end ? Alignment.topRight : Alignment.topLeft,
        showWhenUnlinked: false,
        child: TapRegion(
          groupId: _group,
          onTapOutside: (_) => _close(),
          child: CarbonMenu(
            size: widget.menuSize,
            onClose: _close,
            children: widget.items,
          ),
        ),
      ),
    );
  }
}
