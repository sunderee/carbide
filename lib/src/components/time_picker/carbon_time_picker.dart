// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/time-picker/_time-picker.scss
//   react/src/components/{TimePicker/TimePicker,
//     TimePickerSelect/TimePickerSelect}.tsx
//
// A compact `hh:mm` text field (code-02, 4.875rem wide; 6.175rem when invalid)
// followed by one or more inline selects (AM/PM, timezone). Reuses CarbonField
// (#66) for the field chrome and CarbonSelect (#70) for the dropdowns.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../utils/focus_ring.dart';
import '../../utils/native_text_composition.dart';
import '../../utils/native_text_value.dart';
import '../../utils/owned_listenable.dart';
import '../../theme/carbon_layer.dart';
import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../form/carbon_form.dart';
import '../select/carbon_select.dart';
import 'time_format.dart';

/// A compact time field followed by inline [CarbonTimePickerSelect]s.
///
/// Omitting [format] retains permissive free-text typing. Supplying a format
/// enables draft/Enter/Done/group-blur commits: valid times optionally
/// normalize, empty drafts clear the time, and invalid drafts retain their
/// text with [invalidText]. Active composition does not commit. A twelve-hour
/// format supplies its own coordinated period selector; [children] can supply
/// other controls such as a timezone selector.
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
    this._placeholder,
    this.format,
    this.normalizeOnCommit = true,
    this.onCommitted,
    this.initialPeriod = CarbonTimePeriod.am,
    this.onPeriodChanged,
    this.periodLabel = 'AM/PM',
    this.amLabel = 'AM',
    this.pmLabel = 'PM',
    this.periodWidth = CarbonTimePickerSelect.defaultWidth,
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

  /// A caller-owned controller, rebound when this property changes.
  ///
  /// Removing it creates an internal controller seeded with its text, selection,
  /// and composing range. Caller-owned controllers are never disposed here.
  final TextEditingController? controller;

  /// The initial text, used only when [controller] is null.
  final String? initialValue;

  /// Called when text changes in permissive mode, or successfully commits
  /// when [format] is supplied. Typing in formatted mode remains a draft.
  final ValueChanged<String>? onChanged;

  final String? _placeholder;

  /// The explicit empty hint, the format's pattern hint, or `hh:mm`.
  String get placeholder => _placeholder ?? format?.placeholder ?? 'hh:mm';

  /// An optional parser/formatter that enables validation on commit.
  ///
  /// Without it, arbitrary text and immediate [onChanged] callbacks retain
  /// their original behavior. With it, Enter, Done and leaving the entire
  /// input/select focus group commit drafts. Invalid drafts remain visible
  /// through the existing [invalidText] chrome and do not report a success.
  final CarbonTimeFormat? format;

  /// Whether valid formatted commits replace text with canonical output.
  ///
  /// Applies only when [format] is supplied. False still parses and validates.
  final bool normalizeOnCommit;

  /// Reports canonical times on successful formatted commits, once per edit.
  ///
  /// Empty drafts commit null; invalid drafts and repeated unchanged commits
  /// do not call this. [onChanged] reports the corresponding displayed text.
  final ValueChanged<CarbonTimeValue?>? onCommitted;

  /// The initial period of the built-in twelve-hour selector.
  ///
  /// Used on first construction and when changing the format's hour cycle.
  final CarbonTimePeriod initialPeriod;

  /// Reports changes to the built-in twelve-hour selector.
  ///
  /// Changing the period also commits a valid pending time with that period.
  final ValueChanged<CarbonTimePeriod>? onPeriodChanged;

  /// The accessible label of the built-in twelve-hour selector.
  final String periodLabel;

  /// The localized label for the morning period.
  final String amLabel;

  /// The localized label for the afternoon/evening period.
  final String pmLabel;

  /// The built-in selector's base width at 1× text scale.
  ///
  /// It follows user text scaling so its fluid label remains readable. Increase
  /// this value for longer localized period labels.
  final double periodWidth;

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
  /// hosted in a [CarbonFluidForm]. The built-in period selector follows this
  /// flag; pass `fluid` to independently supplied selects otherwise.
  final bool fluid;

  /// A caller-owned focus node, rebound when this property changes.
  ///
  /// Current focus transfers to the replacement when it can request focus.
  /// Removing it creates an internal node. Caller-owned nodes are never disposed
  /// here.
  final FocusNode? focusNode;

  /// Independently controlled trailing selects, such as a timezone selector.
  ///
  /// In formatted twelve-hour mode the picker already supplies its period
  /// selector; remove a manually supplied AM/PM child when opting into it.
  final List<Widget> children;

  /// The `code-02` input width (`4.875rem`).
  static const double fieldWidth = 78;

  /// The widened input width when invalid (`6.175rem`).
  static const double fieldWidthError = 98.8;

  @override
  State<CarbonTimePicker> createState() => _CarbonTimePickerState();
}

class _CarbonTimePickerState extends State<CarbonTimePicker> {
  static int _nextSemanticId = 0;
  final String _semanticId = 'carbide-time-${_nextSemanticId++}';

  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  late final OwnedTextEditingController _controllerOwner;
  late final OwnedFocusNode _focusOwner;
  late final NativeTextComposition _nativeComposition;
  late final TextInputFormatter _compositionFormatter;
  late CarbonTimePeriod _period;
  CarbonTimeValue? _committed;
  bool _dirty = false;
  bool _parseInvalid = false;
  bool _componentFocused = false;
  bool _updatingText = false;
  String _observedText = '';

  TextEditingController get _controller => _controllerOwner.value;
  FocusNode get _focus => _focusOwner.value;

  @override
  void initState() {
    super.initState();
    _period = widget.initialPeriod;
    _controllerOwner = OwnedTextEditingController(
      external: widget.controller,
      initialText: widget.initialValue,
      onChanged: _onControllerChange,
    );
    _focusOwner = OwnedFocusNode(
      external: widget.focusNode,
      onChanged: _onChange,
    );
    _observedText = _controller.text;
    _committed = widget.format?.tryParse(_controller.text, period: _period);
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
      (_, TextEditingValue value) => _nativeComposition.resolve(value),
    );
    if (kIsWeb) {
      WidgetsBinding.instance.addSemanticsEnabledListener(_onChange);
    }
  }

  @override
  void didUpdateWidget(CarbonTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controllerOwner.update(widget.controller)) {
      _observedText = _controller.text;
      _dirty = false;
      _parseInvalid = false;
      _committed = widget.format?.tryParse(_controller.text, period: _period);
    }
    _focusOwner.update(widget.focusNode);
    if (widget.format?.hourCycle != oldWidget.format?.hourCycle) {
      _period = widget.initialPeriod;
    }
    if (widget.format != oldWidget.format) {
      _parseInvalid = false;
      _committed = widget.format?.tryParse(_controller.text, period: _period);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      WidgetsBinding.instance.removeSemanticsEnabledListener(_onChange);
    }
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

  void _onControllerChange() {
    if (!_updatingText && _controller.text != _observedText) {
      _dirty = true;
      _parseInvalid = false;
    }
    _observedText = _controller.text;
    _onChange();
  }

  bool get _invalid => widget.invalid || _parseInvalid;

  CarbonFieldStatus get _status => _invalid
      ? CarbonFieldStatus.invalid
      : widget.warn
      ? CarbonFieldStatus.warning
      : CarbonFieldStatus.none;

  bool get _composing =>
      _controller.value.composing.isValid &&
      !_controller.value.composing.isCollapsed;

  void _commitDraft() {
    final CarbonTimeFormat? format = widget.format;
    if (format == null || widget.disabled || widget.readOnly || _composing) {
      return;
    }
    final String draft = _controller.text;
    final bool empty = draft.trim().isEmpty;
    final CarbonTimeValue? value = empty
        ? null
        : format.tryParse(draft, period: _period);
    if (!empty && value == null) {
      setState(() => _parseInvalid = true);
      return;
    }
    final String output = widget.normalizeOnCommit
        ? value == null
              ? ''
              : format.format(value)
        : draft;
    final bool notify = _dirty || value != _committed || output != draft;
    _dirty = false;
    _committed = value;
    _updatingText = true;
    try {
      if (_controller.text != output) {
        _controller.value = TextEditingValue(
          text: output,
          selection: TextSelection.collapsed(offset: output.length),
        );
      }
    } finally {
      _updatingText = false;
    }
    setState(() => _parseInvalid = false);
    if (notify) {
      widget.onChanged?.call(output);
      widget.onCommitted?.call(value);
    }
  }

  void _onPeriodChanged(CarbonTimePeriod period) {
    if (period == _period || widget.disabled || widget.readOnly) return;
    setState(() {
      _period = period;
      _dirty = true;
    });
    widget.onPeriodChanged?.call(period);
    _commitDraft();
  }

  void _onComponentFocusChange(bool focused) {
    if (_componentFocused && !focused && mounted) _commitDraft();
    _componentFocused = focused;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.format == null ||
        event is! KeyDownEvent ||
        widget.disabled ||
        widget.readOnly ||
        _composing) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _commitDraft();
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
    final bool enabled = !widget.disabled && !widget.readOnly;

    final Widget editable = MergeSemantics(
      child: Semantics(
        label: widget.labelText,
        identifier: _semanticId,
        enabled: !widget.disabled,
        textField: true,
        child: Focus(
          canRequestFocus: false,
          includeSemantics: false,
          onKeyEvent: _onKey,
          child: _TimeEditable(
            groupId: this,
            controller: _controller,
            focusNode: _focus,
            selectAllOnFocus: _focusOwner.selectAllOnFocus,
            placeholder: widget.placeholder,
            enabled: enabled,
            readOnly: widget.readOnly,
            onChanged: widget.format == null ? widget.onChanged : null,
            onEditingComplete: widget.format == null ? null : _commitDraft,
            compositionFormatter: _compositionFormatter,
            color: widget.disabled ? theme.textDisabled : theme.textPrimary,
            placeholderColor: theme.textPlaceholder,
            cursorColor: theme.focus,
            selectionColor: theme.focus.withValues(alpha: 0.2),
          ),
        ),
      ),
    );

    final Widget field = SizedBox(
      width: _invalid
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

    final Widget? message = _invalid && widget.invalidText != null
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
      child: TextFieldTapRegion(
        groupId: this,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!widget.hideLabel && !_fluid)
              ExcludeSemantics(
                child: CarbonFormLabel(
                  widget.labelText,
                  disabled: widget.disabled,
                ),
              ),
            // The row aligns the field and selects to their bottom edge so the
            // sizes line up (`align-items: flex-end`).
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                field,
                if (widget.format?.hourCycle == CarbonTimeHourCycle.twelveHour)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: CarbonSpacing.spacing01,
                    ),
                    child: CarbonTimePickerSelect<CarbonTimePeriod>(
                      labelText: widget.periodLabel,
                      value: _period,
                      size: widget.size,
                      fluid: _fluid,
                      width:
                          widget.periodWidth *
                          MediaQuery.textScalerOf(context).scale(12) /
                          12,
                      disabled: widget.disabled || widget.readOnly,
                      onChanged: _onPeriodChanged,
                      items: <CarbonSelectEntry<CarbonTimePeriod>>[
                        CarbonSelectItem<CarbonTimePeriod>(
                          value: CarbonTimePeriod.am,
                          label: widget.amLabel,
                        ),
                        CarbonSelectItem<CarbonTimePeriod>(
                          value: CarbonTimePeriod.pm,
                          label: widget.pmLabel,
                        ),
                      ],
                    ),
                  ),
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
        ),
      ),
    );
  }
}

/// `EditableText` in `code-02` with a placeholder overlay, for the time field.
class _TimeEditable extends StatelessWidget {
  const _TimeEditable({
    required this.groupId,
    required this.controller,
    required this.focusNode,
    required this.selectAllOnFocus,
    required this.placeholder,
    required this.enabled,
    required this.readOnly,
    required this.onChanged,
    required this.onEditingComplete,
    required this.compositionFormatter,
    required this.color,
    required this.placeholderColor,
    required this.cursorColor,
    required this.selectionColor,
  });

  final Object groupId;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool? selectAllOnFocus;
  final String placeholder;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final TextInputFormatter compositionFormatter;
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
          groupId: groupId,
          controller: controller,
          focusNode: focusNode,
          selectAllOnFocus: selectAllOnFocus,
          readOnly: readOnly || !enabled,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          inputFormatters: <TextInputFormatter>[compositionFormatter],
          textInputAction: TextInputAction.done,
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
    this.fluid = false,
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

  /// Whether to use the fluid field treatment outside [CarbonFluidForm].
  final bool fluid;

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
        fluid: fluid,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
    // Keep the editor's ancestors stable when focus or validation changes;
    // replacing this wrapper would remount EditableText and close its input.
    box = CarbonFocusRing(
      visible: focused,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: invalid && !focused
              ? Border.all(color: theme.supportError, width: 2)
              : null,
        ),
        child: box,
      ),
    );
    return box;
  }
}
