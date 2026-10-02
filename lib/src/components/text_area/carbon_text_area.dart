// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/text-area/_text-area.scss
//   styles/scss/components/fluid-text-area/_fluid-text-area.scss
//   react/src/components/TextArea/TextArea.tsx

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/native_text_composition.dart';
import '../../utils/owned_listenable.dart';
import '../form/carbon_form.dart';
import 'text_area_limit.dart';

/// The unit used by the text-area input limit and counter.
enum CarbonCounterMode {
  /// Counts user-perceived characters (Unicode grapheme clusters).
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
       ),
       assert(
         maxCount == null || maxCount >= 0,
         'maxCount must be non-negative',
       );

  /// The field label.
  final String labelText;

  /// A caller-owned controller, rebound when this property changes.
  ///
  /// Removing it creates an internal controller seeded with its text, selection,
  /// and composing range. Caller-owned controllers are never disposed here.
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

  /// Limits committed user input, even when [enableCounter] is false.
  ///
  /// Must be non-negative, or null for unlimited input. Required when
  /// [enableCounter] is true. [CarbonCounterMode.character] counts Unicode
  /// grapheme clusters: emoji, flags, ZWJ sequences and combining accents each
  /// count as one user-perceived character. [CarbonCounterMode.word] counts
  /// whitespace-separated words. Pasted content is truncated to fit while
  /// preserving surrounding text and whole graphemes/words.
  ///
  /// Active IME composition may temporarily exceed the limit; it is enforced
  /// when composition commits. The counter always reflects the actual text.
  /// Initial and programmatic controller values are not rewritten, including
  /// when this limit decreases. The next committed user edit enforces the new
  /// limit, truncating the whole value if surrounding text alone exceeds it.
  final int? maxCount;

  /// The unit used by both [maxCount] and the optional counter.
  ///
  /// Character capacity is exposed as semantic max/current lengths. Word
  /// capacity is announced in the field hint instead of a character limit.
  final CarbonCounterMode counterMode;

  /// An optional AI presence decorator (a `CarbonAILabel`), anchored to the
  /// area's top end per upstream's `decorator` prop; adds the AI aura.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// A caller-owned focus node, rebound when this property changes.
  ///
  /// Current focus transfers to the replacement when it can request focus.
  /// Removing it creates an internal node. Caller-owned nodes are never disposed
  /// here.
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

  late final OwnedTextEditingController _controllerOwner;
  late final OwnedFocusNode _focusOwner;
  late final TextAreaLimitFormatter _limit;
  late final NativeTextComposition _nativeComposition;
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();

  TextEditingController get _controller => _controllerOwner.value;
  FocusNode get _focus => _focusOwner.value;

  @override
  void initState() {
    super.initState();
    _controllerOwner = OwnedTextEditingController(
      external: widget.controller,
      initialText: widget.initialValue,
      onChanged: _onChange,
    );
    _focusOwner = OwnedFocusNode(
      external: widget.focusNode,
      onChanged: _onFocusChange,
    );
    _nativeComposition = NativeTextComposition(
      isFocused: () => _focus.hasFocus,
      onCommit: _commitComposition,
    );
    _limit = TextAreaLimitFormatter(
      maxCount: widget.maxCount,
      words: widget.counterMode == CarbonCounterMode.word,
      resolveComposition: _nativeComposition.resolve,
    );
  }

  @override
  void didUpdateWidget(CarbonTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    _limit
      ..maxCount = widget.maxCount
      ..words = widget.counterMode == CarbonCounterMode.word;
    _controllerOwner.update(widget.controller);
    _focusOwner.update(widget.focusNode);
  }

  @override
  void dispose() {
    _nativeComposition.dispose();
    _controllerOwner.dispose();
    _focusOwner.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChange() {
    _onChange();
    if (!_focus.hasFocus && !_controller.value.composing.isCollapsed) {
      final String composingText = _controller.text;
      // EditableText may clear composing metadata while closing its input
      // connection. Finish the known composition after that focus transition.
      scheduleMicrotask(() {
        if (mounted && !_focus.hasFocus) {
          _commitComposition(composingText);
        }
      });
    }
  }

  void _commitComposition([String? expectedText]) {
    if (mounted &&
        !widget.disabled &&
        !widget.readOnly &&
        (expectedText == null || expectedText == _controller.text)) {
      _editableKey.currentState?.userUpdateTextEditingValue(
        _limit.commit(_controller.value),
        SelectionChangedCause.keyboard,
      );
    }
  }

  int get _count => countTextAreaText(
    _controller.text,
    words: widget.counterMode == CarbonCounterMode.word,
  );

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
        enabled: !widget.disabled,
        maxValueLength: widget.counterMode == CarbonCounterMode.character
            ? widget.maxCount
            : null,
        currentValueLength: _controller.text.characters.length,
        hint:
            widget.counterMode == CarbonCounterMode.word &&
                widget.maxCount != null
            ? '$_count of ${widget.maxCount} words'
            : null,
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
              key: _editableKey,
              controller: _controller,
              focusNode: _focus,
              selectAllOnFocus: _focusOwner.selectAllOnFocus,
              readOnly: !enabled,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              inputFormatters: <TextInputFormatter>[_limit],
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
    // Keep the editor's ancestors stable when focus or validation changes;
    // replacing this wrapper would remount EditableText and close its input.
    box = CarbonFocusRing(
      visible: _focus.hasFocus,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: invalid && !_focus.hasFocus
              ? Border.all(color: theme.supportError, width: 2)
              : null,
        ),
        child: box,
      ),
    );

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
