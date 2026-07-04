// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/time-picker/_time-picker.scss
//   react/src/components/{TimePicker/TimePicker,
//     TimePickerSelect/TimePickerSelect}.tsx
//
// A compact `hh:mm` text field (code-02, 4.875rem wide; 6.175rem when invalid)
// followed by one or more inline selects (AM/PM, timezone). Reuses CarbonField
// (#66) for the field chrome and CarbonSelect (#70) for the dropdowns.

import 'package:flutter/widgets.dart';

import '../../utils/focus_ring.dart';
import '../../theme/carbon_layer.dart';
import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../form/carbon_form.dart';
import '../select/carbon_select.dart';

/// A compact time field followed by inline [CarbonTimePickerSelect]s.
///
/// ```dart
/// CarbonTimePicker(
///   labelText: 'Time',
///   initialValue: '09:30',
///   onChanged: (String v) => _time = v,
///   children: <Widget>[
///     CarbonTimePickerSelect<String>(
///       labelText: 'AM/PM',
///       value: _period,
///       items: const <CarbonSelectItem<String>>[
///         CarbonSelectItem<String>(value: 'AM', label: 'AM'),
///         CarbonSelectItem<String>(value: 'PM', label: 'PM'),
///       ],
///       onChanged: (String v) => _period = v,
///     ),
///   ],
/// )
/// ```
class CarbonTimePicker extends StatefulWidget {
  /// Creates a time picker.
  const CarbonTimePicker({
    required this.labelText,
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.placeholder = 'hh:mm',
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.helperText,
    this.hideLabel = false,
    this.fluid = false,
    this.focusNode,
    this.children = const <Widget>[],
  });

  /// The field label.
  final String labelText;

  /// An external controller; one is created when omitted.
  final TextEditingController? controller;

  /// The initial text, used only when [controller] is null.
  final String? initialValue;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// The placeholder shown when empty.
  final String placeholder;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether the field is invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Whether the field shows a warning.
  final bool warn;

  /// The warning message.
  final String? warnText;

  /// Helper text shown below the field.
  final String? helperText;

  /// Whether to hide the visible label (still read by screen readers).
  final bool hideLabel;

  /// The fluid treatment (`_fluid-time-picker.scss`): a 64px field with the
  /// label rendered inside above the value. Attached
  /// [CarbonTimePickerSelect]s pick the treatment up automatically when
  /// hosted in a [CarbonFluidForm]; pass `fluid` to them otherwise.
  final bool fluid;

  /// An external focus node for the text field.
  final FocusNode? focusNode;

  /// Trailing selects (typically [CarbonTimePickerSelect]s).
  final List<Widget> children;

  /// The `code-02` input width (`4.875rem`).
  static const double fieldWidth = 78;

  /// The widened input width when invalid (`6.175rem`).
  static const double fieldWidthError = 98.8;

  @override
  State<CarbonTimePicker> createState() => _CarbonTimePickerState();
}

class _CarbonTimePickerState extends State<CarbonTimePicker> {
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

  CarbonFieldStatus get _status => widget.invalid
      ? CarbonFieldStatus.invalid
      : widget.warn
      ? CarbonFieldStatus.warning
      : CarbonFieldStatus.none;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool enabled = !widget.disabled && !widget.readOnly;

    final Widget editable = MergeSemantics(
      child: Semantics(
        label: widget.labelText,
        textField: true,
        child: _TimeEditable(
          controller: _controller,
          focusNode: _focus,
          placeholder: widget.placeholder,
          enabled: enabled,
          readOnly: widget.readOnly,
          onChanged: widget.onChanged,
          color: widget.disabled ? theme.textDisabled : theme.textPrimary,
          placeholderColor: theme.textPlaceholder,
          cursorColor: theme.focus,
          selectionColor: theme.focus.withValues(alpha: 0.2),
        ),
      ),
    );

    final Widget field = SizedBox(
      width: widget.invalid
          ? CarbonTimePicker.fieldWidthError
          : CarbonTimePicker.fieldWidth,
      child: _fluid
          ? _FluidTimeField(
              label: widget.labelText,
              status: _status,
              disabled: widget.disabled,
              focused: _focus.hasFocus,
              editable: editable,
            )
          : CarbonField(
              size: widget.size,
              status: _status,
              disabled: widget.disabled,
              readOnly: widget.readOnly,
              focused: _focus.hasFocus,
              child: editable,
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
        if (!widget.hideLabel && !_fluid)
          ExcludeSemantics(
            child: CarbonFormLabel(widget.labelText, disabled: widget.disabled),
          ),
        // The row aligns the field and selects to their bottom edge so the
        // sizes line up (`align-items: flex-end`).
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            field,
            for (final Widget child in widget.children)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: CarbonSpacing.spacing01,
                ),
                child: child,
              ),
          ],
        ),
        ?message,
      ],
    );
  }
}

/// `EditableText` in `code-02` with a placeholder overlay, for the time field.
class _TimeEditable extends StatelessWidget {
  const _TimeEditable({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.enabled,
    required this.readOnly,
    required this.onChanged,
    required this.color,
    required this.placeholderColor,
    required this.cursorColor,
    required this.selectionColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final Color color;
  final Color placeholderColor;
  final Color cursorColor;
  final Color selectionColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = CarbonTypeStyles.code02.copyWith(color: color);
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        if (controller.text.isEmpty)
          ExcludeSemantics(
            child: IgnorePointer(
              child: Text(
                placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: placeholderColor),
              ),
            ),
          ),
        EditableText(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly || !enabled,
          onChanged: onChanged,
          style: style,
          cursorColor: cursorColor,
          backgroundCursorColor: placeholderColor,
          selectionColor: selectionColor,
          cursorWidth: 1,
          maxLines: 1,
        ),
      ],
    );
  }
}

/// A compact, content-width [CarbonSelect] for use inside a [CarbonTimePicker]
/// (e.g. AM/PM or timezone). Its label is hidden but read by screen readers.
class CarbonTimePickerSelect<T> extends StatelessWidget {
  /// Creates a time-picker select.
  const CarbonTimePickerSelect({
    required this.labelText,
    required this.items,
    super.key,
    this.value,
    this.onChanged,
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.width = defaultWidth,
  });

  /// The accessible label (hidden visually).
  final String labelText;

  /// The options.
  final List<CarbonSelectEntry<T>> items;

  /// The selected value.
  final T? value;

  /// Called when the selection changes.
  final ValueChanged<T>? onChanged;

  /// The field size; match the parent [CarbonTimePicker].
  final CarbonFieldSize size;

  /// Whether the select is disabled.
  final bool disabled;

  /// The select width. Carbon sizes the select to its content (`inline-size:
  /// auto`); Flutter can't derive an intrinsic width through the field's
  /// internal flex, so the width is fixed and tunable for longer options
  /// (e.g. timezones). The default fits short codes like `AM`/`PM`.
  final double width;

  /// The default select width, enough for a short code plus the chevron.
  static const double defaultWidth = 80;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: CarbonSelect<T>(
        labelText: labelText,
        items: items,
        value: value,
        onChanged: onChanged,
        size: size,
        disabled: disabled,
        hideLabel: true,
      ),
    );
  }
}

/// The fluid time field: a 64px box with the label-01 label stacked above
/// the editable (the house fluid treatment shared with Select and Text
/// Input; `_fluid-time-picker.scss`).
class _FluidTimeField extends StatelessWidget {
  const _FluidTimeField({
    required this.label,
    required this.status,
    required this.disabled,
    required this.focused,
    required this.editable,
  });

  final String label;
  final CarbonFieldStatus status;
  final bool disabled;
  final bool focused;
  final Widget editable;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool invalid = status == CarbonFieldStatus.invalid;
    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: layer.field,
        border: Border(
          bottom: BorderSide(
            color: disabled ? const Color(0x00000000) : theme.borderStrong01,
          ),
        ),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ExcludeSemantics(
                child: Text(
                  label,
                  style: CarbonTypeStyles.label01.copyWith(
                    color: disabled ? theme.textDisabled : theme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              editable,
            ],
          ),
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
