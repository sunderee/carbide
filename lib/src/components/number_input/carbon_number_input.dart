// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/number-input/_number-input.scss
//   styles/scss/components/fluid-number-input/_fluid-number-input.scss
//   react/src/components/NumberInput/NumberInput.tsx

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';
import '../form/carbon_form.dart';

/// A Carbon number input: a numeric field with increment/decrement steppers.
///
/// The value is clamped to [min]/[max] and stepped by [step]; the `Add` /
/// `Subtract` steppers disable at the bounds, and Up/Down arrows step too.
/// When [allowEmpty] is false an empty field coerces to [min] (or 0). Reuses
/// the field chrome from [CarbonField] with a [fluid] variant.
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
  });

  /// The field label.
  final String labelText;

  /// The current value; null is an empty field.
  final num? value;

  /// Called with the new value (null when cleared and [allowEmpty]).
  final ValueChanged<num?>? onChanged;

  /// The minimum allowed value.
  final num? min;

  /// The maximum allowed value.
  final num? max;

  /// The step applied by the steppers and arrow keys.
  final num step;

  /// Whether an empty value is allowed.
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

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<CarbonNumberInput> createState() => _CarbonNumberInputState();
}

class _CarbonNumberInputState extends State<CarbonNumberInput> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  late final TextEditingController _controller = TextEditingController(
    text: widget.value?.toString() ?? '',
  );
  FocusNode? _internalFocus;
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(CarbonNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        widget.value?.toString() != _controller.text) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _controller.removeListener(_rebuild);
    _internalFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  num? get _current => num.tryParse(_controller.text);

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
    _controller.text = v?.toString() ?? '';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    widget.onChanged?.call(v);
  }

  void _step(int direction) {
    final num base = _current ?? widget.min ?? 0;
    _commit(_clamp(base + widget.step * direction));
  }

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      widget.onChanged?.call(widget.allowEmpty ? null : (widget.min ?? 0));
      return;
    }
    final num? parsed = num.tryParse(text);
    if (parsed != null) {
      widget.onChanged?.call(parsed);
    }
  }

  bool get _canIncrement {
    if (widget.max == null) {
      return true;
    }
    return (_current ?? widget.min ?? 0) < widget.max!;
  }

  bool get _canDecrement {
    if (widget.min == null) {
      return true;
    }
    return (_current ?? widget.min ?? 0) > widget.min!;
  }

  CarbonFieldStatus get _status => widget.invalid
      ? CarbonFieldStatus.invalid
      : widget.warn
      ? CarbonFieldStatus.warning
      : CarbonFieldStatus.none;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.disabled || widget.readOnly) {
      return KeyEventResult.ignored;
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
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled && !widget.readOnly;

    final Widget editable = MergeSemantics(
      child: Semantics(
        label: widget.labelText,
        value: _controller.text,
        child: Focus(
          onKeyEvent: _onKey,
          child: EditableText(
            controller: _controller,
            focusNode: _focus,
            readOnly: !enabled,
            autofocus: widget.autofocus,
            onChanged: _onTextChanged,
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
        if (!_fluid && !widget.hideLabel)
          ExcludeSemantics(
            child: CarbonFormLabel(widget.labelText, disabled: widget.disabled),
          ),
        field,
        ?message,
      ],
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

  /// The fluid field height (`4rem`).
  static const double fluidHeight = 64;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool invalid = status == CarbonFieldStatus.invalid;
    final bool fluid = fluidLabel != null;
    // The AI treatment: aura gradient + ai-border-strong bottom border.
    final bool ai = aiLabel != null && !aiRevert && !readOnly;
    final Color border = disabled
        ? const Color(0x00000000)
        : readOnly
        ? layer.borderSubtle
        : ai
        ? theme.aiBorderStrong
        : theme.borderStrong01;

    final Widget content = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: CarbonField.paddingInline,
      ),
      child: fluid
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
            )
          : Align(alignment: AlignmentDirectional.centerStart, child: editable),
    );

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0x00000000) : layer.field,
        gradient: ai ? CarbonField.aiFieldGradient(theme) : null,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SizedBox(
        height: fluid ? fluidHeight : size.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: content),
            if (invalid)
              Align(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CarbonIcon(
                    CarbonIcons.errorFilled,
                    size: 16,
                    color: theme.supportError,
                  ),
                ),
              ),
            // The AI label sits before the steppers (inset-inline-end
            // $spacing-12 upstream, clearing the two stepper buttons).
            if (aiLabel != null)
              Align(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: CarbonSpacing.spacing03,
                  ),
                  child: aiLabel,
                ),
              ),
            ?steppers,
          ],
        ),
      ),
    );
    if (focused) {
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
    return box;
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
