// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/number-input/_number-input.scss
//   styles/scss/components/fluid-number-input/_fluid-number-input.scss
//   react/src/components/NumberInput/NumberInput.tsx

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';
import '../../utils/native_text_composition.dart';
import '../../utils/native_text_value.dart';
import '../../utils/owned_listenable.dart';
import '../form/carbon_form.dart';

/// A Carbon number input: a numeric field with increment/decrement steppers.
///
/// The value is clamped to [min]/[max] and stepped by [step]; the `Add` /
/// `Subtract` steppers disable at the bounds, and Up/Down arrows step too.
/// When [allowEmpty] is false an empty field coerces to [min] (or 0). Reuses
/// the field chrome from [CarbonField] with a [fluid] variant.
///
/// Typing changes a draft without calling [onChanged]. Enter, the keyboard's
/// Done action, leaving the input/stepper focus group, and step actions commit
/// the draft. Commit parses finite numbers, clamps them, and normalizes the
/// displayed text before notifying the caller. Invalid or incomplete drafts
/// (`-`, `.`, `1e`) restore the last committed value. Step actions commit and
/// then step the clamped draft, reporting only the final value. Repeated commits
/// without another edit or value change do not repeat the callback.
/// Active IME composition stays a draft; candidate-selection keys do not step
/// or commit it.
class CarbonNumberInput extends StatefulWidget {
  /// Creates a number input.
  const CarbonNumberInput({
    super.key,
    required this.labelText,
    this.value,
    this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.allowEmpty = false,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.hideLabel = false,
    this.hideSteppers = false,
    this.fluid = false,
    this.incrementLabel = 'Increment number',
    this.decrementLabel = 'Decrement number',
    this.aiLabel,
    this.aiRevert = false,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         step > 0 && step < double.infinity,
         'step must be finite and positive',
       ),
       assert(
         min == null ||
             (min > double.negativeInfinity && min < double.infinity),
         'min must be finite',
       ),
       assert(
         max == null ||
             (max > double.negativeInfinity && max < double.infinity),
         'max must be finite',
       ),
       assert(
         min == null || max == null || min <= max,
         'min must not exceed max',
       ),
       assert(
         value == null ||
             (value > double.negativeInfinity && value < double.infinity),
         'value must be finite',
       );

  /// The field label.
  final String labelText;

  /// The committed value; null initially displays an empty field.
  ///
  /// Changing this property replaces a pending draft. Rebuilding with the same
  /// value preserves it. Must be finite when non-null. Bounds apply at commit.
  final num? value;

  /// Called once per committed edit, after the displayed text is normalized.
  ///
  /// Typing alone does not call this. A committed empty draft reports null when
  /// [allowEmpty] is true. Invalid drafts report the restored committed value.
  final ValueChanged<num?>? onChanged;

  /// The finite minimum allowed value; must not exceed [max].
  final num? min;

  /// The finite maximum allowed value; must not be below [min].
  final num? max;

  /// The finite positive step applied by the steppers and arrow keys.
  final num step;

  /// Whether a committed empty or whitespace-only draft is allowed.
  ///
  /// Otherwise commit displays and reports [min], or zero clamped to [max].
  final bool allowEmpty;

  /// Helper text (hidden when invalid/warn).
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

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

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered
  /// before the steppers per upstream's `decorator` prop (inset-inline-end
  /// $spacing-12); adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// Hides the increment/decrement steppers.
  final bool hideSteppers;

  /// Uses the fluid treatment (label inside the field).
  final bool fluid;

  /// The increment stepper's accessible label.
  final String incrementLabel;

  /// The decrement stepper's accessible label.
  final String decrementLabel;

  /// A caller-owned focus node, rebound when this property changes.
  ///
  /// Current focus transfers to the replacement when it can request focus.
  /// Removing it creates an internal node. Caller-owned nodes are never disposed
  /// here.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<CarbonNumberInput> createState() => _CarbonNumberInputState();
}

class _CarbonNumberInputState extends State<CarbonNumberInput> {
  static int _nextSemanticId = 0;
  final String _semanticId = 'carbide-number-${_nextSemanticId++}';

  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  late final OwnedTextEditingController _controllerOwner;
  TextEditingController get _controller => _controllerOwner.value;
  late final OwnedFocusNode _focusOwner;
  FocusNode get _focus => _focusOwner.value;
  late final NativeTextComposition _nativeComposition;
  late final TextInputFormatter _compositionFormatter;
  num? _committed;
  bool _dirty = false;
  bool _componentFocused = false;

  @override
  void initState() {
    super.initState();
    _committed = widget.value;
    _controllerOwner = OwnedTextEditingController(
      initialText: widget.value?.toString(),
      onChanged: _rebuild,
    );
    _focusOwner = OwnedFocusNode(
      external: widget.focusNode,
      onChanged: _rebuild,
    );
    _nativeComposition = NativeTextComposition(
      isFocused: () => _focus.hasFocus,
      onCommit: (String text) {
        if (mounted && _controller.text == text) {
          _controller.value = _controller.value.copyWith(
            composing: TextRange.empty,
          );
        }
      },
    );
    _compositionFormatter = TextInputFormatter.withFunction(
      (TextEditingValue oldValue, TextEditingValue newValue) =>
          _nativeComposition.resolve(newValue),
    );
    if (kIsWeb) {
      WidgetsBinding.instance.addSemanticsEnabledListener(_rebuild);
    }
  }

  @override
  void didUpdateWidget(CarbonNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focusOwner.update(widget.focusNode);
    if (widget.value != oldWidget.value) {
      _committed = widget.value;
      _dirty = false;
      if (widget.value?.toString() != _controller.text) {
        _controller.value = TextEditingValue(
          text: widget.value?.toString() ?? '',
          selection: TextSelection.collapsed(
            offset: widget.value?.toString().length ?? 0,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      WidgetsBinding.instance.removeSemanticsEnabledListener(_rebuild);
    }
    _nativeComposition.dispose();
    _focusOwner.dispose();
    _controllerOwner.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  num? get _draftValue {
    if (_controller.text.trim().isEmpty) {
      return widget.allowEmpty ? null : _clamp(widget.min ?? 0);
    }
    final num? parsed = num.tryParse(_controller.text);
    final num? value = parsed != null && parsed.isFinite ? parsed : _committed;
    return value != null
        ? _clamp(value)
        : widget.allowEmpty
        ? null
        : _clamp(widget.min ?? 0);
  }

  num get _stepBase => _draftValue ?? _clamp(widget.min ?? 0);

  num _clamp(num v) {
    num result = v;
    final num? min = widget.min;
    final num? max = widget.max;
    if (min != null && result < min) {
      result = min;
    }
    if (max != null && result > max) {
      result = max;
    }
    return result;
  }

  void _commit(num? v) {
    final bool notify = _dirty || v != _committed;
    _dirty = false;
    _committed = v;
    final String text = v?.toString() ?? '';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (notify) {
      widget.onChanged?.call(v);
    }
  }

  void _step(int direction) {
    if (!widget.disabled && !widget.readOnly) {
      _commit(_nextStep(direction));
    }
  }

  num _nextStep(int direction) {
    final num base = _stepBase;
    final num next = _clamp(base + widget.step * direction);
    // Floating-point overflow or integer wrap must not reverse a step or
    // expose a non-finite value. Unrepresentable steps stay at the base.
    if (!next.isFinite ||
        (direction > 0 && next < base) ||
        (direction < 0 && next > base)) {
      return base;
    }
    return next;
  }

  void _commitDraft() {
    if (!widget.disabled &&
        !widget.readOnly &&
        !(_focus.hasFocus &&
            _controller.value.composing.isValid &&
            !_controller.value.composing.isCollapsed)) {
      _commit(_draftValue);
    }
  }

  void _onTextChanged(String _) {
    _dirty = true;
  }

  void _onComponentFocusChange(bool focused) {
    if (_componentFocused && !focused && mounted) {
      _commitDraft();
    }
    _componentFocused = focused;
  }

  bool get _canIncrement => _dirty || _nextStep(1) > _stepBase;

  bool get _canDecrement => _dirty || _nextStep(-1) < _stepBase;

  CarbonFieldStatus get _status => widget.invalid
      ? CarbonFieldStatus.invalid
      : widget.warn
      ? CarbonFieldStatus.warning
      : CarbonFieldStatus.none;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.disabled || widget.readOnly) {
      return KeyEventResult.ignored;
    }
    if (_controller.value.composing.isValid &&
        !_controller.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _commitDraft();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp && _canIncrement) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown && _canDecrement) {
      _step(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          syncNativeTextValue(
            _semanticId,
            _controller.text,
            readOnly: widget.readOnly || widget.disabled,
          );
        }
      });
    }
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled && !widget.readOnly;

    final Widget editable = MergeSemantics(
      child: Semantics(
        label: widget.labelText,
        identifier: _semanticId,
        enabled: !widget.disabled,
        child: Focus(
          canRequestFocus: false,
          includeSemantics: false,
          onKeyEvent: _onKey,
          child: EditableText(
            groupId: this,
            controller: _controller,
            focusNode: _focus,
            selectAllOnFocus: _focusOwner.selectAllOnFocus,
            readOnly: !enabled,
            autofocus: widget.autofocus,
            onChanged: _onTextChanged,
            onEditingComplete: _commitDraft,
            inputFormatters: <TextInputFormatter>[_compositionFormatter],
            textInputAction: TextInputAction.done,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            style: CarbonTypeStyles.bodyCompact01.copyWith(
              color: widget.disabled ? theme.textDisabled : theme.textPrimary,
            ),
            cursorColor: theme.focus,
            backgroundCursorColor: theme.textPlaceholder,
            selectionColor: theme.focus.withValues(alpha: 0.2),
            cursorWidth: 1,
            maxLines: 1,
          ),
        ),
      ),
    );

    final Widget? steppers = widget.hideSteppers
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Divider(color: layer.borderSubtle),
              _Stepper(
                icon: CarbonIcons.subtract,
                label: widget.decrementLabel,
                size: widget.size.height,
                onPressed: enabled && _canDecrement ? () => _step(-1) : null,
              ),
              _Divider(color: layer.borderSubtle),
              _Stepper(
                icon: CarbonIcons.add,
                label: widget.incrementLabel,
                size: widget.size.height,
                onPressed: enabled && _canIncrement ? () => _step(1) : null,
              ),
            ],
          );

    final Widget field = _NumberField(
      size: widget.size,
      status: _status,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      focused: _focus.hasFocus,
      editable: editable,
      steppers: steppers,
      aiLabel: widget.aiLabel,
      aiRevert: widget.aiRevert,
      fluidLabel: _fluid && !widget.hideLabel ? widget.labelText : null,
      fluid: _fluid,
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

    return Focus(
      canRequestFocus: false,
      includeSemantics: false,
      onFocusChange: _onComponentFocusChange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!_fluid && !widget.hideLabel)
            ExcludeSemantics(
              child: CarbonFormLabel(
                widget.labelText,
                disabled: widget.disabled,
              ),
            ),
          TextFieldTapRegion(groupId: this, child: field),
          ?message,
        ],
      ),
    );
  }
}

/// The number field box: editable on the start, steppers flush at the end.
/// The [fluidLabel], when set, renders inside the box (a 64px tall field).
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.size,
    required this.status,
    required this.disabled,
    required this.readOnly,
    required this.focused,
    required this.editable,
    required this.steppers,
    required this.aiLabel,
    required this.aiRevert,
    required this.fluidLabel,
    required this.fluid,
  });

  final CarbonFieldSize size;
  final CarbonFieldStatus status;
  final bool disabled;
  final bool readOnly;
  final bool focused;
  final Widget editable;
  final Widget? steppers;
  final Widget? aiLabel;
  final bool aiRevert;
  final String? fluidLabel;
  final bool fluid;

  /// The fluid field height (`4rem`).
  static const double fluidHeight = 64;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final TextScaler scaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    double lineHeight(TextStyle style) =>
        scaler.scale(style.fontSize!) * style.height!;
    final double contentHeight =
        lineHeight(CarbonTypeStyles.bodyCompact01) +
        (fluidLabel == null ? 0 : lineHeight(CarbonTypeStyles.label01) + 2);
    final double height = math.max(
      fluid ? fluidHeight : size.height,
      contentHeight,
    );
    return CarbonField(
      size: size,
      status: status,
      disabled: disabled,
      readOnly: readOnly,
      focused: focused,
      fluid: fluid,
      aiLabel: aiLabel,
      aiRevert: aiRevert,
      trailing: steppers == null
          ? null
          : SizedBox(height: height, child: steppers),
      child: fluidLabel == null
          ? editable
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExcludeSemantics(
                  child: Text(
                    fluidLabel!,
                    style: CarbonTypeStyles.label01.copyWith(
                      color: disabled
                          ? theme.textDisabled
                          : theme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                editable,
              ],
            ),
    );
  }
}

/// A 1px full-height divider between the field and the steppers.
class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 1, child: ColoredBox(color: color));
}

/// One stepper button (square width, stretches to the field height).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.icon,
    required this.label,
    required this.size,
    required this.onPressed,
  });

  final CarbonIconData icon;
  final String label;
  final double size;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: onPressed,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          return CarbonFocusRing(
            visible: states.contains(WidgetState.focused),
            child: ColoredBox(
              color: hovered && enabled
                  ? layer.layerHover
                  : const Color(0x00000000),
              child: SizedBox(
                width: size,
                child: Center(
                  child: CarbonIcon(
                    icon,
                    size: 16,
                    color: enabled ? theme.iconPrimary : theme.iconDisabled,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
