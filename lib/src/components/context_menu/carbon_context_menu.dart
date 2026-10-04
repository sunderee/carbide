// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   react/src/components/ContextMenu/useContextMenu.tsx
//   styling is CarbonMenu's.
//
// ContextMenu opens a CarbonMenu on secondary click, long press or scoped
// keyboard invocation, clamped to the overlay. The menu owns roving focus, Escape,
// type-ahead, and item-activation close; an outside tap dismisses it.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../utils/native_control_focus.dart';
import '../../utils/overlay_focus_repair.dart';
import '../menu/carbon_menu.dart';

/// Opens a [CarbonMenu] on secondary click, long press or a context-menu key.
///
/// When a descendant of [child] has focus, Shift+F10 or the Context Menu key
/// opens the menu below that descendant, aligned to its logical start edge.
/// The child must provide a focusable target, such as a button or [Focus];
/// this wrapper adds no traversal stop. Pointer gestures use the pointer's
/// position. Both paths clamp the menu to the nearest overlay's bounds.
///
/// Focus enters the first enabled item, or the menu scope when no item is
/// enabled. Escape, outside dismissal, activation and disabling [enabled]
/// restore the previous focus if that target remains attached and focusable.
/// A consumer's subsequent focus request takes precedence. Tab dismisses and
/// continues traversal from the originating target.
///
/// ```dart
/// CarbonContextMenu(
///   items: <Widget>[
///     CarbonMenuItem(label: 'Cut', onPressed: _cut),
///     CarbonMenuItem(label: 'Copy', onPressed: _copy),
///   ],
///   child: const Focus(child: Text('Context-menu target')),
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

  /// The region that responds to pointer gestures and scoped keyboard opening.
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
  final FocusNode _region = FocusNode(
    debugLabel: 'Carbon context-menu region',
    skipTraversal: true,
    canRequestFocus: false,
  );
  final FocusScopeNode _scope = FocusScopeNode(
    debugLabel: 'Carbon context menu',
  );
  final OverlayFocusRepair _repair = OverlayFocusRepair();
  FocusNode? _origin;
  bool Function()? _restoreNativeFocus;
  Offset _position = Offset.zero;
  bool _alignRight = false;

  @override
  void didUpdateWidget(CarbonContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _overlay.isShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.enabled) _close();
      });
    }
  }

  @override
  void dispose() {
    _restoreOrigin();
    _origin = null;
    _restoreNativeFocus = null;
    _repair.dispose();
    _scope.dispose();
    _region.dispose();
    super.dispose();
  }

  void _open(Offset globalPosition, {bool alignRight = false}) {
    if (!mounted || !widget.enabled || _overlay.isShowing) return;
    _repair.cancel();
    _scope.descendantsAreTraversable = true;
    _origin = FocusManager.instance.primaryFocus;
    _restoreNativeFocus = captureNativeControlFocus();
    _position = globalPosition;
    _alignRight = alignRight;
    _overlay.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !widget.enabled ||
          !_overlay.isShowing ||
          _scope.context == null ||
          _scope.hasFocus) {
        return;
      }
      final FocusNode? current = FocusManager.instance.primaryFocus;
      if (current != _origin && current != FocusManager.instance.rootScope) {
        return;
      }
      final FocusNode? first = ReadingOrderTraversalPolicy()
          .sortDescendants(_scope.traversalDescendants, _scope)
          .firstOrNull;
      (first ?? _scope).requestFocus();
    });
  }

  void _close() {
    if (!mounted || !_overlay.isShowing) return;
    final FocusNode? origin = _restoreOrigin();
    final bool Function()? native = _restoreNativeFocus;
    _origin = null;
    _restoreNativeFocus = null;
    _overlay.hide();
    _repair.schedule(
      origin,
      native,
      isCurrent: () => mounted && !_overlay.isShowing,
    );
  }

  FocusNode? _restoreOrigin() {
    final FocusNode? origin = _origin;
    final FocusNode? current = FocusManager.instance.primaryFocus;
    if (origin?.context == null ||
        origin!.parent == null ||
        !origin.canRequestFocus ||
        origin is FocusScopeNode ||
        (!_scope.hasFocus &&
            current != FocusManager.instance.rootScope &&
            current != origin)) {
      return null;
    }
    origin.requestFocus();
    return origin;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!mounted ||
        !widget.enabled ||
        !_region.hasFocus ||
        _overlay.isShowing ||
        event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    final bool invoke =
        event.logicalKey == LogicalKeyboardKey.contextMenu &&
            !keyboard.isShiftPressed ||
        event.logicalKey == LogicalKeyboardKey.f10 && keyboard.isShiftPressed;
    final FocusNode? target = FocusManager.instance.primaryFocus;
    if (!invoke || target?.context == null || target is FocusScopeNode) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final Rect bounds = target!.rect;
    _open(rtl ? bounds.bottomRight : bounds.bottomLeft, alignRight: rtl);
    return KeyEventResult.handled;
  }

  KeyEventResult _onMenuKey(FocusNode node, KeyEvent event) {
    if (!mounted || !_overlay.isShowing || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      final FocusNode? origin = _origin;
      // Overlay removal is deferred. Exclude its rows from the traversal
      // performed during this event, before the portal has unmounted them.
      _scope.descendantsAreTraversable = false;
      _close();
      final bool backwards = HardwareKeyboard.instance.isShiftPressed;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final FocusNode? current = FocusManager.instance.primaryFocus;
        if (!mounted ||
            _overlay.isShowing ||
            origin?.context == null ||
            origin!.parent == null ||
            !origin.canRequestFocus ||
            (current != origin && current != FocusManager.instance.rootScope)) {
          return;
        }
        backwards ? origin.previousFocus() : origin.nextFocus();
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Focus(
        focusNode: _region,
        includeSemantics: false,
        onKeyEvent: _onKey,
        child: OverlayPortal(
          controller: _overlay,
          overlayChildBuilder: _buildOverlay,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The child owns its accessible focus target. Keep this pointer
            // wrapper's semantics stable when invocation is disabled.
            excludeFromSemantics: true,
            onSecondaryTapDown: widget.enabled
                ? (TapDownDetails d) => _open(d.globalPosition)
                : null,
            onLongPressStart: widget.enabled
                ? (LongPressStartDetails d) => _open(d.globalPosition)
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final Offset position = overlay.globalToLocal(_position);
    return Stack(
      children: <Widget>[
        // A full-screen backdrop so a tap anywhere outside the menu closes it.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _close,
            onSecondaryTap: _close,
          ),
        ),
        CustomSingleChildLayout(
          delegate: _PointerMenuLayout(position, alignRight: _alignRight),
          child: FocusScope(
            node: _scope,
            onKeyEvent: _onMenuKey,
            child: CarbonMenu(
              autofocus: false,
              size: widget.size,
              onClose: _close,
              children: widget.items,
            ),
          ),
        ),
      ],
    );
  }
}

/// Positions the menu at its pointer or focused-child anchor within the overlay.
class _PointerMenuLayout extends SingleChildLayoutDelegate {
  const _PointerMenuLayout(this.target, {required this.alignRight});

  final Offset target;
  final bool alignRight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final double maxX = (size.width - childSize.width).clamp(0, size.width);
    final double maxY = (size.height - childSize.height).clamp(0, size.height);
    final double x = alignRight ? target.dx - childSize.width : target.dx;
    return Offset(x.clamp(0, maxX), target.dy.clamp(0, maxY));
  }

  @override
  bool shouldRelayout(_PointerMenuLayout oldDelegate) =>
      target != oldDelegate.target || alignRight != oldDelegate.alignRight;
}
