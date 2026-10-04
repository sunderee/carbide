// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show SemanticsHitTestBehavior;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart' show SemanticsBinding;
import 'package:flutter/widgets.dart';

import '../../utils/native_control_focus.dart';
import '../../utils/overlay_focus_repair.dart';

/// Formats a keyboard-highlighted option without implying selection.
///
/// [position] is one-based in the visible options, including disabled rows.
/// [count] is the number of visible options. Supply a translated complete
/// phrase to a picker's `activeOptionFormatter` to localize its announcement.
typedef CarbonListBoxActiveOptionFormatter = String Function(
  String label,
  int position,
  int count,
);

/// The default English keyboard-highlight announcement.
///
/// For example, `carbonListBoxActiveOptionLabel('Email', 2, 3)` returns
/// `Active option: Email, 2 of 3`. This describes navigation, not commitment.
String carbonListBoxActiveOptionLabel(String label, int position, int count) =>
    'Active option: $label, $position of $count';

/// Shares active-option announcements across editable and non-editable pickers.
///
/// Flutter has no active-descendant relationship. Keep keyboard focus on the
/// trigger for every picker so combo/filter text entry, selection and composing
/// ranges survive navigation. Announce the active option through its hint and
/// a polite live region; the editor/trigger value remains the current text or
/// committed selection. A hint alone is not re-read reliably by all platforms.
/// Neither the live region nor highlighted option takes keyboard focus.
class CarbonListBoxSemantics extends StatefulWidget {
  /// Creates the picker semantics scope and its persistent announcement node.
  const CarbonListBoxSemantics({
    required this.expanded,
    required this.activeIndex,
    required this.optionLabels,
    required this.focusNode,
    required this.builder,
    this.formatActiveOption = carbonListBoxActiveOptionLabel,
    super.key,
  });

  /// Whether options are open and available for interaction.
  final bool expanded;

  /// The visual keyboard highlight, or a negative index when none is eligible.
  final int activeIndex;

  /// Visible labels, with null for disabled options that cannot be active.
  final List<String?> optionLabels;

  /// The trigger's borrowed keyboard focus, retained during option interaction.
  final FocusNode focusNode;

  /// Builds the picker under its shared semantics scope.
  final WidgetBuilder builder;

  /// The localizable complete active-option announcement.
  final CarbonListBoxActiveOptionFormatter formatActiveOption;

  /// The active-option hint for a trigger or an active option in this scope.
  static String? activeHintOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ListBoxSemanticsScope>()
      ?.activeHint;

  @override
  State<CarbonListBoxSemantics> createState() => _CarbonListBoxSemanticsState();
}

class _CarbonListBoxSemanticsState extends State<CarbonListBoxSemantics> {
  final OverlayFocusRepair _pointerRepair = OverlayFocusRepair();

  @override
  void didUpdateWidget(CarbonListBoxSemantics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode ||
        !widget.focusNode.canRequestFocus) {
      _pointerRepair.cancel();
    }
  }

  @override
  void dispose() {
    _pointerRepair.dispose();
    super.dispose();
  }

  EditableTextState? _editor() {
    EditableTextState? result;
    void visit(Element element) {
      if (element is StatefulElement && element.state is EditableTextState) {
        final editor = element.state as EditableTextState;
        if (editor.widget.focusNode == widget.focusNode) result = editor;
        return;
      }
      element.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  void _retainFocus() {
    if (!mounted || !widget.expanded) return;
    final FocusNode target = widget.focusNode;
    final FocusScopeNode? parkingScope = target.enclosingScope;
    final bool Function()? ownsNative =
        kIsWeb &&
            !SemanticsBinding.instance.semanticsEnabled &&
            _editor() != null
        ? captureNativeFocusOwnership()
        : null;
    target.requestFocus();
    // Named semantics editors have their own connection/focus repair. Only
    // the ordinary editing host needs this additional pointer repair.
    // Pointer default actions may close the ordinary web text connection after
    // this request. Repair only this interaction, after those actions, through
    // the current editor's public API. Other controls and windows take priority.
    _pointerRepair.schedule(
      target,
      ownsNative == null
          ? null
          : () {
              if (!ownsNative()) return false;
              // Preserve an editor whose framework connection survived the
              // pointer action; reattach only after ownership was parked.
              if (target.hasPrimaryFocus) return true;
              final EditableTextState? editor = _editor();
              if (editor == null) return false;
              editor.requestKeyboard();
              return true;
            },
      isCurrent: () => mounted && widget.focusNode == target,
      parkingScope: parkingScope,
    );
    // Named semantics editors also need their focused metadata refreshed.
    setState(() {});
  }

  void _settleFocus() {
    if (!mounted || !widget.focusNode.hasPrimaryFocus) return;
    final FocusNode target = widget.focusNode;
    // Browser click defaults can blur a named editor after pointer-up. Rebuild
    // its guarded semantics repair after that final default action, yielding
    // to selection callbacks that choose a different control or remove us.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.focusNode == target && target.hasPrimaryFocus) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    final String? label =
        widget.expanded &&
            widget.activeIndex >= 0 &&
            widget.activeIndex < widget.optionLabels.length
        ? widget.optionLabels[widget.activeIndex]
        : null;
    final String? hint = label == null
        ? null
        : widget.formatActiveOption(
            label,
            widget.activeIndex + 1,
            widget.optionLabels.length,
          );
    return _ListBoxSemanticsScope(
      activeHint: hint,
      focusNode: widget.focusNode,
      retainFocus: _retainFocus,
      settleFocus: _settleFocus,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Builder(builder: widget.builder),
          // Keep this node attached even while closed. Adding/removing an
          // implicit web semantics ancestor can blur the native editor. The
          // small non-interactive region leaves the field's hit target intact.
          Positioned(
            top: 0,
            left: 0,
            width: 1,
            height: 1,
            child: IgnorePointer(
              child: Semantics(
                container: true,
                liveRegion: true,
                label: hint ?? '',
                hitTestBehavior: SemanticsHitTestBehavior.transparent,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListBoxSemanticsScope extends InheritedWidget {
  const _ListBoxSemanticsScope({
    required this.activeHint,
    required this.focusNode,
    required this.retainFocus,
    required this.settleFocus,
    required super.child,
  });

  final String? activeHint;
  final FocusNode focusNode;
  final VoidCallback retainFocus;
  final VoidCallback settleFocus;

  @override
  bool updateShouldNotify(_ListBoxSemanticsScope oldWidget) =>
      activeHint != oldWidget.activeHint || focusNode != oldWidget.focusNode;
}

/// One option node, with separate selection, availability and active hint.
///
/// Descendant labels, checkboxes and gesture semantics are excluded. The row's
/// painted controls still handle pointer input; this node owns accessibility
/// activation and reads the latest callback after a live row update.
class CarbonListBoxOptionSemantics extends StatefulWidget {
  /// Creates a single named, actionable option.
  const CarbonListBoxOptionSemantics({
    required this.label,
    required this.selected,
    required this.active,
    required this.disabled,
    required this.onActivate,
    required this.child,
    this.multiple = false,
    super.key,
  });

  /// The option's accessible name.
  final String label;

  /// Whether the caller has committed this option.
  final bool selected;

  /// Whether this option is under the keyboard highlight.
  final bool active;

  /// Whether this option is unavailable for selection.
  final bool disabled;

  /// Whether selection is also exposed as a checkbox state.
  final bool multiple;

  /// Selects or toggles this option through the owning picker.
  final VoidCallback onActivate;

  /// The visual option row.
  final Widget child;

  @override
  State<CarbonListBoxOptionSemantics> createState() =>
      _CarbonListBoxOptionSemanticsState();
}

class _CarbonListBoxOptionSemanticsState
    extends State<CarbonListBoxOptionSemantics> {
  void _activate() {
    if (!mounted || widget.disabled) return;
    final _ListBoxSemanticsScope? scope = context
        .getInheritedWidgetOfExactType<_ListBoxSemanticsScope>();
    widget.onActivate();
    // Native semantics activation can bypass Flutter pointer-up. Settle after
    // its browser click default as well, while respecting a newer focus owner.
    scope?.settleFocus();
  }

  void _pointerDown(PointerDownEvent event) {
    if (!mounted) return;
    context
        .getInheritedWidgetOfExactType<_ListBoxSemanticsScope>()
        ?.retainFocus();
  }

  void _pointerUp(PointerUpEvent event) {
    if (!mounted) return;
    context
        .getInheritedWidgetOfExactType<_ListBoxSemanticsScope>()
        ?.settleFocus();
  }

  @override
  Widget build(BuildContext context) => TextFieldTapRegion(
    // An option is part of its editable picker, not an outside tap. A unique
    // borrowed focus node keeps separate editors' tap regions independent.
    groupId: context
        .dependOnInheritedWidgetOfExactType<_ListBoxSemanticsScope>()
        ?.focusNode,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _pointerDown,
      onPointerUp: _pointerUp,
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: widget.label,
        button: !widget.multiple,
        selected: widget.selected,
        checked: widget.multiple ? widget.selected : null,
        enabled: !widget.disabled,
        hint: widget.active && !widget.disabled
            ? CarbonListBoxSemantics.activeHintOf(context)
            : null,
        onTap: widget.disabled ? null : _activate,
        child: widget.child,
      ),
    ),
  );
}
