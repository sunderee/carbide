// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   react/src/components/ContextMenu/useContextMenu.tsx
//   styling is CarbonMenu's.
//
// ContextMenu opens a CarbonMenu at the pointer on secondary (right) click or
// long-press, clamped to stay on screen. The menu owns roving focus, Escape,
// type-ahead, and item-activation close; an outside tap dismisses it.

import 'package:flutter/widgets.dart';

import '../menu/carbon_menu.dart';

/// Opens a [CarbonMenu] at the pointer when [child] is right-clicked or
/// long-pressed.
///
/// ```dart
/// CarbonContextMenu(
///   items: <Widget>[
///     CarbonMenuItem(label: 'Cut', onPressed: _cut),
///     CarbonMenuItem(label: 'Copy', onPressed: _copy),
///   ],
///   child: const Text('Right-click me'),
/// )
/// ```
class CarbonContextMenu extends StatefulWidget {
  /// Creates a context menu around [child].
  const CarbonContextMenu({
    required this.child,
    required this.items,
    super.key,
    this.enabled = true,
    this.size = CarbonMenuSize.sm,
  });

  /// The region that responds to secondary-click / long-press.
  final Widget child;

  /// The menu contents (typically [CarbonMenuItem]s).
  final List<Widget> items;

  /// Whether the context menu can be opened.
  final bool enabled;

  /// The size of the opened menu.
  final CarbonMenuSize size;

  @override
  State<CarbonContextMenu> createState() => _CarbonContextMenuState();
}

class _CarbonContextMenuState extends State<CarbonContextMenu> {
  final OverlayPortalController _overlay = OverlayPortalController();
  Offset _position = Offset.zero;

  void _open(Offset globalPosition) {
    if (!widget.enabled) return;
    setState(() => _position = globalPosition);
    _overlay.show();
  }

  void _close() {
    if (_overlay.isShowing) _overlay.hide();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: _buildOverlay,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onSecondaryTapDown: widget.enabled
            ? (TapDownDetails d) => _open(d.globalPosition)
            : null,
        onLongPressStart: widget.enabled
            ? (LongPressStartDetails d) => _open(d.globalPosition)
            : null,
        child: widget.child,
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: <Widget>[
        // A full-screen backdrop so a tap anywhere outside the menu closes it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            onSecondaryTap: _close,
          ),
        ),
        CustomSingleChildLayout(
          delegate: _PointerMenuLayout(_position),
          child: CarbonMenu(
            size: widget.size,
            onClose: _close,
            children: widget.items,
          ),
        ),
      ],
    );
  }
}

/// Positions the menu at the pointer, clamped so it stays within the viewport.
class _PointerMenuLayout extends SingleChildLayoutDelegate {
  const _PointerMenuLayout(this.target);

  final Offset target;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = (size.width - childSize.width).clamp(0, size.width);
    final double maxY = (size.height - childSize.height).clamp(0, size.height);
    return Offset(target.dx.clamp(0, maxX), target.dy.clamp(0, maxY));
  }

  @override
  bool shouldRelayout(_PointerMenuLayout oldDelegate) =>
      target != oldDelegate.target;
}
