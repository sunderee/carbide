// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Builds a widget from the current set of interaction [states].
typedef CarbonInteractionBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
);

/// The reusable interactive base for Carbon components.
///
/// Tracks hover, focus, pressed, and disabled as [WidgetState]s and exposes
/// them to [builder], so a component only has to map states to styling — for
/// example with [WidgetStateProperty]. Handles pointer and keyboard activation
/// (Space/Enter), focus, hover, disabled and read-only states.
///
/// Following Carbon, the focus state reflects the *focus highlight* — it is set
/// for keyboard focus, not for a tap that merely moves focus — so components can
/// show a focus ring only when appropriate.
class CarbonInteraction extends StatefulWidget {
  /// Creates an interactive region driven by [builder].
  const CarbonInteraction({
    super.key,
    this.enabled = true,
    this.readOnly = false,
    this.includeSemantics = true,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.mouseCursor,
    this.statesController,
    required this.builder,
  });

  /// Whether the region responds to input. When false, the `disabled` state is
  /// set and pointer/keyboard input is ignored.
  final bool enabled;

  /// Keeps focus available while preventing activation and hover feedback.
  ///
  /// Unlike a disabled region, a read-only region can show its focus ring.
  final bool readOnly;

  /// Whether to add focus and gesture semantics.
  ///
  /// Disable when a parent supplies the complete control semantics.
  final bool includeSemantics;

  /// Called on tap or keyboard activation while enabled and not read-only.
  final VoidCallback? onPressed;

  /// An optional focus node to control focus externally.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// The cursor for the region; defaults to a click cursor when enabled.
  final MouseCursor? mouseCursor;

  /// An optional external states controller. If omitted, one is created and
  /// owned internally.
  final WidgetStatesController? statesController;

  /// Builds the child from the current interaction states.
  final CarbonInteractionBuilder builder;

  @override
  State<CarbonInteraction> createState() => _CarbonInteractionState();
}

class _CarbonInteractionState extends State<CarbonInteraction> {
  WidgetStatesController? _internalController;

  WidgetStatesController get _states =>
      widget.statesController ??
      (_internalController ??= WidgetStatesController());

  @override
  void initState() {
    super.initState();
    _states.update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void didUpdateWidget(CarbonInteraction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.statesController != oldWidget.statesController) {
      if (oldWidget.statesController == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _states.update(WidgetState.disabled, !widget.enabled);
    }
    if (widget.enabled != oldWidget.enabled ||
        widget.readOnly != oldWidget.readOnly) {
      _states.update(WidgetState.disabled, !widget.enabled);
      if (!_operable) {
        _states
          ..update(WidgetState.pressed, false)
          ..update(WidgetState.hovered, false);
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  bool get _operable => widget.enabled && !widget.readOnly;

  void _activate() {
    if (_operable) {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final bool operable = _operable;
    return FocusableActionDetector(
      enabled: enabled,
      includeFocusSemantics: widget.includeSemantics,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor:
          widget.mouseCursor ??
          (operable ? SystemMouseCursors.click : SystemMouseCursors.basic),
      onShowHoverHighlight: (bool value) =>
          _states.update(WidgetState.hovered, operable && value),
      onShowFocusHighlight: (bool value) =>
          _states.update(WidgetState.focused, value),
      shortcuts: operable
          ? const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            }
          : const <ShortcutActivator, Intent>{},
      actions: operable
          ? <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (ActivateIntent intent) {
                  _activate();
                  return null;
                },
              ),
            }
          : <Type, Action<Intent>>{},
      child: GestureDetector(
        excludeFromSemantics: !widget.includeSemantics,
        behavior: HitTestBehavior.opaque,
        onTap: operable ? _activate : null,
        onTapDown: operable
            ? (TapDownDetails _) => _states.update(WidgetState.pressed, true)
            : null,
        onTapUp: operable
            ? (TapUpDetails _) => _states.update(WidgetState.pressed, false)
            : null,
        onTapCancel: operable
            ? () => _states.update(WidgetState.pressed, false)
            : null,
        child: ListenableBuilder(
          listenable: _states,
          builder: (BuildContext context, Widget? child) =>
              widget.builder(context, _states.value),
        ),
      ),
    );
  }
}
