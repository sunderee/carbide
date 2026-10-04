// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import 'control_state.dart';
import 'native_control_focus.dart';
import 'overlay_focus_repair.dart';

/// Shares the editing and inspection policy of native text-based controls.
///
/// Read-only editors retain selection and focus semantics. Disabled editors
/// expose their value through the parent while excluding the editor's
/// unconditional focusable flag and blocking descendant focus.
class CarbonTextControlSemantics extends StatefulWidget {
  /// Creates the named text-control region.
  const CarbonTextControlSemantics({
    required this.state,
    required this.label,
    required this.value,
    required this.readOnlyHint,
    required this.focusNode,
    required this.child,
    super.key,
  });

  /// The editing and focus policy.
  final CarbonControlState state;

  /// The accessible field name.
  final String label;

  /// The current editor value, retained in disabled semantics.
  final String value;

  /// The localizable read-only announcement.
  final String readOnlyHint;

  /// The editor's borrowed focus node.
  final FocusNode focusNode;

  /// The editor and any decorative placeholder.
  final Widget child;

  @override
  State<CarbonTextControlSemantics> createState() =>
      _CarbonTextControlSemanticsState();
}

class _CarbonTextControlSemanticsState
    extends State<CarbonTextControlSemantics> {
  static int _nextIdentifier = 0;
  final String _identifier = 'carbide-text-control-${_nextIdentifier++}';
  final OverlayFocusRepair _repair = OverlayFocusRepair();
  int _revision = 0;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_focusChanged);
    _scheduleRepair();
  }

  @override
  void didUpdateWidget(CarbonTextControlSemantics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _cancelRepair();
      oldWidget.focusNode.removeListener(_focusChanged);
      widget.focusNode.addListener(_focusChanged);
    }
    if (!widget.state.canFocus) {
      _cancelRepair();
    } else {
      _scheduleRepair();
      if (kIsWeb &&
          widget.state.canActivate != oldWidget.state.canActivate &&
          widget.focusNode.hasPrimaryFocus) {
        // Replacing the web editor must park focus at its scope rather than
        // walking back to a previously focused control. The scheduled repair
        // restores this node after attachment and yields to a later control.
        widget.focusNode.unfocus(disposition: UnfocusDisposition.scope);
      }
    }
  }

  @override
  void dispose() {
    _cancelRepair();
    widget.focusNode.removeListener(_focusChanged);
    super.dispose();
  }

  void _cancelRepair() {
    _generation++;
    _repair.cancel();
  }

  void _focusChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.focusNode.hasPrimaryFocus) {
      _scheduleRepair();
    } else if (FocusManager.instance.primaryFocus !=
        FocusManager.instance.rootScope) {
      _cancelRepair();
    }
  }

  void _requestFocus() {
    if (mounted && widget.state.canFocus) widget.focusNode.requestFocus();
  }

  void _scheduleRepair() {
    if (!kIsWeb ||
        !widget.state.canFocus ||
        !widget.focusNode.hasPrimaryFocus) {
      return;
    }
    final bool Function()? restore = captureTextControlFocus(
      _identifier,
      readOnly: !widget.state.canActivate,
    );
    if (restore == null) return;
    final int generation = ++_generation;
    bool isCurrent() =>
        mounted && generation == _generation && widget.state.canFocus;
    _repair.schedule(widget.focusNode, restore, isCurrent: isCurrent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isCurrent()) return;
      final FocusNode? current = FocusManager.instance.primaryFocus;
      if (current != widget.focusNode &&
          current != FocusManager.instance.rootScope) {
        return;
      }
      // A native blur detaches Flutter's web editing strategy even when the
      // framework connection stays attached. A subsequent focused semantics
      // update reactivates it. The revision changes metadata without replacing
      // the editor node or its accessible name, value and selection.
      setState(() => _revision++);
    });
  }

  @override
  Widget build(BuildContext context) {
    // EditableText forwards Escape to an ancestor DismissIntent when no
    // selection toolbar is open. A standalone base-widgets form need not have
    // a dismiss action; preserve any enclosing dialog's action when present.
    final Widget editor = Actions.maybeFind<DismissIntent>(context) == null
        ? Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: DoNothingAction(consumesKey: false),
            },
            child: widget.child,
          )
        : widget.child;
    // On the web a blur can detach the native editing strategy before its
    // next semantics update. Reattach on a read-only transition instead of
    // updating that inactive connection. The caller-owned controller and focus
    // node retain the value and selection; the guarded repair restores focus.
    final Widget editable = kIsWeb
        ? KeyedSubtree(
            key: ValueKey<bool>(widget.state.canActivate),
            child: editor,
          )
        : editor;
    return Semantics(
      identifier: '$_identifier-$_revision',
      container: true,
      child: MergeSemantics(
        child: Semantics(
          textField: true,
          label: widget.label,
          enabled: !widget.state.isDisabled,
          readOnly: !widget.state.canActivate,
          hint: widget.state.semanticsHint(widget.readOnlyHint),
          focusable: widget.state.canFocus,
          focused: widget.state.canFocus ? widget.focusNode.hasFocus : null,
          value: widget.state.isDisabled ? widget.value : null,
          onFocus: widget.state.canFocus ? _requestFocus : null,
          child: ExcludeFocus(
            excluding: widget.state.isDisabled,
            child: ExcludeSemantics(
              excluding: widget.state.isDisabled,
              child: editable,
            ),
          ),
        ),
      ),
    );
  }
}
