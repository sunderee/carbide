// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/text-area/_text-area.scss
//   styles/scss/components/fluid-text-area/_fluid-text-area.scss
//   react/src/components/TextArea/TextArea.tsx

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../form/carbon_form.dart';

/// How the character counter is computed.
enum CarbonCounterMode {
  /// Counts characters.
  character,

  /// Counts whitespace-separated words.
  word,
}

/// A Carbon multi-line text area.
///
/// A growing field (min-height 40px, 11px/16px padding) on `field` with a
/// `border-strong` bottom border, per `_text-area.scss`. Supports the full
/// state matrix plus an optional character/word counter ([enableCounter])
/// shown beside the label, and the [fluid] layout (label inside the box).
class CarbonTextArea extends StatefulWidget {
  /// Creates a text area.
  const CarbonTextArea({
    super.key,
    required this.labelText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.placeholder,
    this.helperText,
    this.rows = 4,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.hideLabel = false,
    this.fluid = false,
    this.enableCounter = false,
    this.maxCount,
    this.counterMode = CarbonCounterMode.character,
    this.aiLabel,
    this.aiRevert = false,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         controller == null || initialValue == null,
         'provide controller or initialValue, not both',
       ),
       assert(
         !enableCounter || maxCount != null,
         'enableCounter requires maxCount',
       );

  /// The field label.
  final String labelText;

  /// An external controller.
  final TextEditingController? controller;

  /// The initial text.
  final String? initialValue;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Placeholder shown when empty.
  final String? placeholder;

  /// Helper text (hidden when invalid/warn).
  final String? helperText;

  /// The minimum visible rows.
  final int rows;

  /// Whether disabled.
  final bool disabled;

  /// Whether read-only.
  final bool readOnly;

  /// Whether invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Whether in warning.
  final bool warn;

  /// The warning message.
  final String? warnText;

  /// Visually hides the label.
  final bool hideLabel;

  /// Uses the fluid treatment (label inside the box).
  final bool fluid;

  /// Shows the character/word counter beside the label.
  final bool enableCounter;

  /// The maximum count (required when [enableCounter]).
  final int? maxCount;

  /// Whether the counter counts characters or words.
  final CarbonCounterMode counterMode;

  /// An optional AI presence decorator (a `CarbonAILabel`), anchored to the
  /// area's top end per upstream's `decorator` prop; adds the AI aura.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// The minimum box height (`min-block-size: 40px`).
  static const double minHeight = 40;

  @override
  State<CarbonTextArea> createState() => _CarbonTextAreaState();
}

class _CarbonTextAreaState extends State<CarbonTextArea> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  TextEditingController? _internalController;
  FocusNode? _internalFocus;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.initialValue);
    }
    _controller.addListener(_onChange);
    _focus.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _focus.removeListener(_onChange);
    _internalController?.dispose();
    _internalFocus?.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  int get _count {
    final String text = _controller.text;
    if (widget.counterMode == CarbonCounterMode.word) {
      return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
    }
    return text.characters.length;
  }

  CarbonFieldStatus get _status => widget.invalid
      ? CarbonFieldStatus.invalid
      : widget.warn
      ? CarbonFieldStatus.warning
      : CarbonFieldStatus.none;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled && !widget.readOnly;
    final bool invalid = _status == CarbonFieldStatus.invalid;

    final TextStyle style = CarbonTypeStyles.bodyCompact01.copyWith(
      color: widget.disabled ? theme.textDisabled : theme.textPrimary,
    );
    final Widget editable = MergeSemantics(
      child: Semantics(
        label: widget.labelText,
        child: Stack(
          children: <Widget>[
            if (widget.placeholder != null && _controller.text.isEmpty)
              ExcludeSemantics(
                child: IgnorePointer(
                  child: Text(
                    widget.placeholder!,
                    style: style.copyWith(color: theme.textPlaceholder),
                  ),
                ),
              ),
            EditableText(
              controller: _controller,
              focusNode: _focus,
              readOnly: !enabled,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              style: style,
              cursorColor: theme.focus,
              backgroundCursorColor: theme.textPlaceholder,
              selectionColor: theme.focus.withValues(alpha: 0.2),
              cursorWidth: 1,
              maxLines: null,
              minLines: widget.rows,
            ),
          ],
        ),
      ),
    );

    // The AI treatment: aura gradient + ai-border-strong bottom border.
    final bool ai =
        widget.aiLabel != null && !widget.aiRevert && !widget.readOnly;

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.readOnly ? const Color(0x00000000) : layer.field,
        gradient: ai ? CarbonField.aiFieldGradient(theme) : null,
        border: Border(
          bottom: BorderSide(
            color: widget.disabled
                ? const Color(0x00000000)
                : widget.readOnly
                ? layer.borderSubtle
                : ai
                ? theme.aiBorderStrong
                : theme.borderStrong01,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: CarbonTextArea.minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CarbonField.paddingInline,
            vertical: 11,
          ),
          child: _fluid
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // The label sits inside the box for the fluid treatment.
                    _LabelRow(
                      label: widget.hideLabel ? null : widget.labelText,
                      disabled: widget.disabled,
                      counter: widget.enableCounter
                          ? '$_count/${widget.maxCount}'
                          : null,
                    ),
                    editable,
                  ],
                )
              : editable,
        ),
      ),
    );
    if (widget.aiLabel != null) {
      box = Stack(
        children: <Widget>[
          box,
          // inset-block-start: 12px, inset-inline-end: 16px
          // (`_text-area.scss` --slug/--decorator placement).
          PositionedDirectional(
            top: CarbonSpacing.spacing04,
            end: CarbonSpacing.spacing05,
            child: widget.aiLabel!,
          ),
        ],
      );
    }
    if (_focus.hasFocus) {
      box = CarbonFocusRing(visible: true, child: box);
    } else if (invalid) {
      box = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: theme.supportError, width: 2),
        ),
        child: box,
      );
    }

    final Widget? message = widget.invalid && widget.invalidText != null
        ? CarbonFieldRequirement(widget.invalidText!)
        : widget.warn && widget.warnText != null
        ? CarbonFieldRequirement(
            widget.warnText!,
            status: CarbonFieldStatus.warning,
          )
        : widget.helperText != null
        ? CarbonHelperText(widget.helperText!, disabled: widget.disabled)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!_fluid && (!widget.hideLabel || widget.enableCounter))
          _LabelRow(
            label: widget.hideLabel ? null : widget.labelText,
            disabled: widget.disabled,
            counter: widget.enableCounter ? '$_count/${widget.maxCount}' : null,
          ),
        box,
        ?message,
      ],
    );
  }
}

/// The label row: the label on the start and the optional counter at the end.
class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.label,
    required this.disabled,
    required this.counter,
  });

  final String? label;
  final bool disabled;
  final String? counter;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing03),
      child: Row(
        children: <Widget>[
          if (label != null)
            ExcludeSemantics(
              child: Text(
                label!,
                style: CarbonTypeStyles.label01.copyWith(
                  color: disabled ? theme.textDisabled : theme.textSecondary,
                ),
              ),
            ),
          const Spacer(),
          if (counter != null)
            Text(
              counter!,
              style: CarbonTypeStyles.label01.copyWith(
                color: disabled ? theme.textDisabled : theme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
