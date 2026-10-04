// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import 'control_state.dart';
import 'native_control_focus.dart';
import 'overlay_focus_repair.dart';

/// Builds a value control with the resolved owned or borrowed focus node.
typedef CarbonControlBuilder = Widget Function(FocusNode focusNode);

/// Shared value semantics and guarded native focus for non-text controls.
///
/// Flutter's web focus manager suppresses focus for `enabled: false`, including
/// read-only controls, and popup updates can move a trigger's native element.
/// Repair only while this focusable control owns framework focus, respecting a
/// later native control or an inactive window.
class CarbonControlSemantics extends StatefulWidget {
  /// Creates the named control region with its editing and value policy.
  const CarbonControlSemantics({
    required this.state,
    required this.label,
    required this.readOnlyHint,
    required this.builder,
    this.focusNode,
    this.onActivate,
    this.button = false,
    this.value,
    this.expanded,
    this.activeOptionHint,
    this.checked,
    this.mixed = false,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    super.key,
  });

  /// The resolved editing and focus policy.
  final CarbonControlState state;

  /// The accessible control name.
  final String label;

  /// The localizable announcement used in read-only mode.
  final String readOnlyHint;

  /// Builds the styled interaction region using the provided focus node.
  final CarbonControlBuilder builder;

  /// A borrowed focus node; a node is owned internally when omitted.
  final FocusNode? focusNode;

  /// The edit action, exposed only while the resolved state permits editing.
  final VoidCallback? onActivate;

  /// Whether this control is a button that opens a value picker.
  final bool button;

  /// The selected value announced by a picker trigger.
  final String? value;

  /// Whether a picker popup is open; omitted for non-picker controls.
  final bool? expanded;

  /// The keyboard-highlight announcement, separate from the selected value.
  final String? activeOptionHint;

  /// The checkbox or radio value; omitted for a switch.
  final bool? checked;

  /// Whether a checkbox exposes its indeterminate state.
  final bool mixed;

  /// The switch value; omitted for a checkbox or radio.
  final bool? toggled;

  /// Whether the control participates in radio selection.
  final bool inMutuallyExclusiveGroup;

  @override
  State<CarbonControlSemantics> createState() => _CarbonControlSemanticsState();
}

class _CarbonControlSemanticsState extends State<CarbonControlSemantics> {
  static int _nextIdentifier = 0;
  final String _identifier = 'carbide-control-${_nextIdentifier++}';
  final OverlayFocusRepair _repair = OverlayFocusRepair();
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode(debugLabel: 'Carbon value control');
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(CarbonControlSemantics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      _repair.cancel();
      _focus.removeListener(_focusChanged);
      if (oldWidget.focusNode == null) _focus.dispose();
      _focus =
          widget.focusNode ?? FocusNode(debugLabel: 'Carbon value control');
      _focus.addListener(_focusChanged);
    }
    if (!widget.state.canFocus) {
      _repair.cancel();
    } else {
      _scheduleRepair();
    }
  }

  @override
  void dispose() {
    _repair.dispose();
    _focus.removeListener(_focusChanged);
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _focusChanged() {
    if (!mounted) return;
    setState(() {});
    if (_focus.hasPrimaryFocus) {
      _scheduleRepair();
    } else if (FocusManager.instance.primaryFocus !=
        FocusManager.instance.rootScope) {
      _repair.cancel();
    }
  }

  void _scheduleRepair() {
    if (!kIsWeb || !widget.state.canFocus || !_focus.hasPrimaryFocus) return;
    _repair.schedule(
      _focus,
      captureReadOnlyControlFocus(_identifier),
      isCurrent: () => mounted && widget.state.canFocus,
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: _identifier,
    label: widget.label,
    button: widget.button,
    value: widget.value,
    expanded: widget.expanded,
    checked: widget.checked,
    mixed: widget.mixed,
    toggled: widget.toggled,
    inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup,
    enabled: widget.state.canActivate,
    hint: widget.state.isReadOnly
        ? widget.readOnlyHint
        : widget.activeOptionHint,
    focusable: widget.state.canFocus,
    focused: widget.state.canFocus ? _focus.hasFocus : null,
    onFocus: widget.state.canFocus ? _focus.requestFocus : null,
    onTap: widget.state.canActivate
        ? () {
            if (mounted && widget.state.canActivate) widget.onActivate?.call();
          }
        : null,
    child: widget.builder(_focus),
  );
}
