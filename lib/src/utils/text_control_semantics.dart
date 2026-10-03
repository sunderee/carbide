// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

import 'control_state.dart';

/// Shares the editing and inspection policy of native text-based controls.
///
/// Read-only editors retain selection and focus semantics. Disabled editors
/// expose their value through the parent while excluding the editor's
/// unconditional focusable flag and blocking descendant focus.
class CarbonTextControlSemantics extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // EditableText forwards Escape to an ancestor DismissIntent when no
    // selection toolbar is open. A standalone base-widgets form need not have
    // a dismiss action; preserve any enclosing dialog's action when present.
    final Widget editor = Actions.maybeFind<DismissIntent>(context) == null
        ? Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: DoNothingAction(consumesKey: false),
            },
            child: child,
          )
        : child;
    return MergeSemantics(
      child: Semantics(
        textField: true,
        label: label,
        enabled: !state.isDisabled,
        readOnly: !state.canActivate,
        hint: state.semanticsHint(readOnlyHint),
        focusable: state.canFocus,
        focused: state.canFocus ? focusNode.hasFocus : null,
        value: state.isDisabled ? value : null,
        onFocus: state.canFocus ? focusNode.requestFocus : null,
        child: ExcludeFocus(
          excluding: state.isDisabled,
          child: ExcludeSemantics(excluding: state.isDisabled, child: editor),
        ),
      ),
    );
  }
}
