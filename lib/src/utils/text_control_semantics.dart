// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart' show OrdinalSortKey;
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
  OrdinalSortKey _editorOrder = const OrdinalSortKey(0);
  int _generation = 0;
  FocusScopeNode? _parkingScope;

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
      final bool policyChanged =
          widget.state.canActivate != oldWidget.state.canActivate;
      final bool parked =
          _parkingScope != null &&
          FocusManager.instance.primaryFocus == _parkingScope;
      final bool replacing =
          kIsWeb &&
          policyChanged &&
          widget.focusNode.hasPrimaryFocus &&
          captureTextControlFocus(
                _identifier,
                readOnly: !widget.state.canActivate,
                allowSharedEditor: true,
              ) !=
              null;
      if (policyChanged) {
        // A newer policy can arrive while the previous editor is still parked.
        // Supersede that native snapshot and reconcile the current connection.
        final FocusScopeNode? scope = replacing || parked
            ? widget.focusNode.enclosingScope
            : null;
        _cancelRepair();
        _parkingScope = scope;
      }
      _scheduleRepair();
      if (replacing) {
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
    _parkingScope = null;
    _repair.cancel();
  }

  void _focusChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.focusNode.hasPrimaryFocus) {
      _parkingScope = null;
      _scheduleRepair();
    } else if (FocusManager.instance.primaryFocus !=
            FocusManager.instance.rootScope &&
        (_parkingScope == null ||
            FocusManager.instance.primaryFocus != _parkingScope)) {
      _cancelRepair();
    }
  }

  void _requestFocus() {
    if (mounted && widget.state.canFocus) widget.focusNode.requestFocus();
  }

  void _scheduleRepair() {
    final bool parked =
        _parkingScope != null &&
        FocusManager.instance.primaryFocus == _parkingScope;
    if (!kIsWeb ||
        !widget.state.canFocus ||
        (!widget.focusNode.hasPrimaryFocus && !parked)) {
      return;
    }
    final bool Function()? restore = captureTextControlFocus(
      _identifier,
      readOnly: !widget.state.canActivate,
      // Reattach the ordinary web editor only for a policy replacement.
      // Routine owner/value updates must preserve its current connection.
      allowSharedEditor: _parkingScope != null,
    );
    if (restore == null) return;
    // A popup DOM move can park focus at this view's scope, just as an editor
    // replacement does. Capture that scope while ownership is still known;
    // a later control or a different scope cancels the guarded repair.
    if (widget.focusNode.hasPrimaryFocus) {
      _parkingScope ??= widget.focusNode.enclosingScope;
    }
    final int generation = ++_generation;
    final FocusScopeNode? parkingScope = _parkingScope;
    bool isCurrent() =>
        mounted && generation == _generation && widget.state.canFocus;
    _repair.schedule(
      widget.focusNode,
      () {
        if (!restore()) return false;
        _requestKeyboard();
        _refreshEditorSemantics();
        return true;
      },
      isCurrent: isCurrent,
      parkingScope: parkingScope,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isCurrent()) return;
      final FocusNode? current = FocusManager.instance.primaryFocus;
      if (current != widget.focusNode &&
          current != FocusManager.instance.rootScope &&
          (parkingScope == null || current != parkingScope)) {
        return;
      }
      // A native blur detaches Flutter's web editing strategy even when the
      // framework connection stays attached. A subsequent focused semantics
      // update reactivates it. The revision changes metadata without replacing
      // the editor node or its accessible name, value and selection.
      _refreshEditorSemantics();
    });
  }

  void _refreshEditorSemantics() {
    // Flutter 3.47.6 omits identifier from its semantics dirty comparison.
    // Refresh the ordinal so the focused native role is sent again. This field
    // is the region's only child; its traversal position stays fixed.
    setState(() {
      _revision++;
      _editorOrder = OrdinalSortKey(_revision.toDouble());
    });
  }

  void _requestKeyboard() {
    // A native blur can detach the engine strategy without a framework focus
    // change. Ask the current editor to attach through its public API before
    // refreshing the focused text-field semantics.
    void visit(Element element) {
      if (element is StatefulElement && element.state is EditableTextState) {
        final EditableTextState editor = element.state as EditableTextState;
        if (editor.widget.focusNode == widget.focusNode) {
          editor.requestKeyboard();
        }
        return;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
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
    // The outer region remains discoverable while its merged text-field role
    // moves with popup semantics. Replacing both on a web policy change
    // reconnects the current editor; the caller's value and focus node persist.
    return Semantics(
      key: kIsWeb ? ValueKey<bool>(widget.state.canActivate) : null,
      identifier: '$_identifier-region',
      container: true,
      child: MergeSemantics(
        child: Semantics(
          identifier: '$_identifier-editor-$_revision',
          sortKey: _editorOrder,
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
              child: editor,
            ),
          ),
        ),
      ),
    );
  }
}
