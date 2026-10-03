// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/radio-button/_radio-button.scss
//   react/src/components/{RadioButton,RadioButtonGroup}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';
import '../../utils/control_state.dart';
import '../form/carbon_form.dart';

/// Whether a radio's label sits before or after the circle.
enum CarbonRadioLabelPosition {
  /// Label after the circle (the default).
  right,

  /// Label before the circle.
  left,
}

/// A single Carbon radio button (the circle + label).
///
/// An 18px circle (1px `icon-primary` border) with a 9px `icon-primary` dot
/// when [selected]; label `body-compact-01`. Usually built by
/// [CarbonRadioButtonGroup], which manages single-selection and arrow-key
/// roving; use this directly only for a standalone radio.
///
/// A null callback or [disabled] disables focus and editing. [readOnly]
/// retains focus and the announced value while preventing activation. Its
/// [readOnlyHint] announces non-editability and can be localized.
class CarbonRadioButton extends StatelessWidget {
  /// Creates a radio button.
  const CarbonRadioButton({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.labelPosition = CarbonRadioLabelPosition.right,
    this.invalid = false,
    this.disabled = false,
    this.readOnly = false,
    this.readOnlyHint = CarbonControlState.defaultReadOnlyHint,
    this.focusNode,
    this.autofocus = false,
  });

  /// The label beside the circle.
  final String label;

  /// Whether this radio is the selected one in its group.
  final bool selected;

  /// Called when this radio is chosen; null disables it.
  final VoidCallback? onSelected;

  /// Which side the label sits on.
  final CarbonRadioLabelPosition labelPosition;

  /// Renders the invalid (error-border) treatment.
  final bool invalid;

  /// Renders read-only.
  final bool readOnly;

  /// Disables focus and editing, independently of callback availability.
  final bool disabled;

  /// Localizable read-only announcement; ignored when disabled.
  final String readOnlyHint;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// The circle diameter (`18px`).
  static const double circleSize = 18;

  /// The selected dot diameter (`scale(0.5)` of the circle).
  static const double dotSize = 9;

  /// The gap between the circle and the label (`margin-inline-end: 10px`).
  static const double labelGap = 10;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonControlState state = CarbonControlState.resolve(
      hasCallback: onSelected != null,
      disabled: disabled,
      readOnly: readOnly,
    );
    final bool enabled = state.canActivate;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: state.canActivate,
      hint: state.semanticsHint(readOnlyHint),
      label: label,
      child: CarbonInteraction(
        enabled: state.canFocus,
        readOnly: state.isReadOnly,
        onPressed: enabled ? onSelected : null,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool focused = states.contains(WidgetState.focused);
          final bool disabled = state.isDisabled;
          final Color ringColor = disabled
              ? theme.iconDisabled
              : state.isReadOnly
              ? theme.iconDisabled
              : invalid
              ? theme.supportError
              : theme.iconPrimary;
          final Color dotColor = disabled
              ? theme.textDisabled
              : state.isReadOnly
              ? theme.iconPrimary
              : ringColor;

          final Widget circle = _RadioCircle(
            selected: selected,
            ringColor: ringColor,
            dotColor: dotColor,
            focusColor: theme.focus,
            focused: focused,
          );
          final Widget text = ExcludeSemantics(
            child: Text(
              label,
              style: CarbonTypeStyles.bodyCompact01.copyWith(
                color: disabled ? theme.textDisabled : theme.textPrimary,
              ),
            ),
          );

          // An empty label (e.g. a data-table row selector) renders just the
          // circle, with no trailing gap/text to skew its centering.
          if (label.isEmpty) {
            return circle;
          }

          final bool labelFirst =
              labelPosition == CarbonRadioLabelPosition.left;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (labelFirst) ...<Widget>[
                text,
                const SizedBox(width: labelGap),
                circle,
              ] else ...<Widget>[circle, const SizedBox(width: labelGap), text],
            ],
          );
        },
      ),
    );
  }
}

/// The 18px circle with its optional dot and outer focus ring.
class _RadioCircle extends StatelessWidget {
  const _RadioCircle({
    required this.selected,
    required this.ringColor,
    required this.dotColor,
    required this.focusColor,
    required this.focused,
  });

  final bool selected;
  final Color ringColor;
  final Color dotColor;
  final Color focusColor;
  final bool focused;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: CarbonRadioButton.circleSize,
    child: CustomPaint(
      foregroundPainter: focused ? _RadioFocusRing(focusColor) : null,
      painter: _RadioPainter(
        selected: selected,
        ringColor: ringColor,
        dotColor: dotColor,
      ),
    ),
  );
}

/// Paints the 1px circle border and the selected dot.
class _RadioPainter extends CustomPainter {
  const _RadioPainter({
    required this.selected,
    required this.ringColor,
    required this.dotColor,
  });

  final bool selected;
  final Color ringColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.width / 2 - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ringColor,
    );
    if (selected) {
      canvas.drawCircle(
        center,
        CarbonRadioButton.dotSize / 2,
        Paint()..color = dotColor,
      );
    }
  }

  @override
  bool shouldRepaint(_RadioPainter old) =>
      selected != old.selected ||
      ringColor != old.ringColor ||
      dotColor != old.dotColor;
}

/// The 2px `focus` ring 1.5px outside the circle (`outline-offset: 1.5px`).
class _RadioFocusRing extends CustomPainter {
  const _RadioFocusRing(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      // circle radius (9) + 1.5 offset + 1 half-stroke.
      size.width / 2 + 2.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RadioFocusRing old) => color != old.color;
}

/// A single-select group of radio buttons (`<fieldset>` + `<legend>`).
///
/// Selection is driven by [value] / [onChanged]. Lays out [orientation]
/// horizontal (a row) or vertical (a column with `spacing-03` gaps); arrow
/// keys move and select among the enabled options (roving focus). Read-only
/// groups permit arrow-key inspection without changing the selection.
class CarbonRadioButtonGroup<T> extends StatefulWidget {
  /// Creates a radio group.
  const CarbonRadioButtonGroup({
    super.key,
    required this.legend,
    this.aiLabel,
    required this.options,
    required this.value,
    this.onChanged,
    this.orientation = Axis.horizontal,
    this.labelPosition = CarbonRadioLabelPosition.right,
    this.disabled = false,
    this.readOnly = false,
    this.readOnlyHint = CarbonControlState.defaultReadOnlyHint,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.helperText,
  });

  /// The group legend.
  final String legend;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered
  /// inline after the group legend per upstream's `decorator` prop.
  final Widget? aiLabel;

  /// The options as (value, label) pairs.
  final List<(T value, String label)> options;

  /// The currently selected value.
  final T? value;

  /// Called with the chosen value; null disables the group.
  final ValueChanged<T>? onChanged;

  /// The layout axis.
  final Axis orientation;

  /// Which side the labels sit on.
  final CarbonRadioLabelPosition labelPosition;

  /// Renders the group read-only.
  final bool readOnly;

  /// Disables focus and editing, independently of callback availability.
  final bool disabled;

  /// Localizable read-only announcement; ignored when disabled.
  final String readOnlyHint;

  /// Whether the group is invalid.
  final bool invalid;

  /// The error message shown when [invalid].
  final String? invalidText;

  /// Whether the group is in a warning state.
  final bool warn;

  /// The warning message shown when [warn].
  final String? warnText;

  /// Optional helper text (hidden when invalid/warn).
  final String? helperText;

  @override
  State<CarbonRadioButtonGroup<T>> createState() =>
      _CarbonRadioButtonGroupState<T>();
}

class _CarbonRadioButtonGroupState<T> extends State<CarbonRadioButtonGroup<T>> {
  late List<FocusNode> _nodes;

  CarbonControlState get _state => CarbonControlState.resolve(
    hasCallback: widget.onChanged != null,
    disabled: widget.disabled,
    readOnly: widget.readOnly,
  );

  @override
  void initState() {
    super.initState();
    _nodes = List<FocusNode>.generate(
      widget.options.length,
      (_) => FocusNode(),
    );
  }

  @override
  void didUpdateWidget(CarbonRadioButtonGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.length != widget.options.length) {
      for (final FocusNode node in _nodes) {
        node.dispose();
      }
      _nodes = List<FocusNode>.generate(
        widget.options.length,
        (_) => FocusNode(),
      );
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _move(int from, int delta) {
    if (!_state.canFocus) return;
    // The group enables uniformly, so just wrap to the adjacent option,
    // move focus there, and select it only while editable.
    final int count = widget.options.length;
    final int next = (from + delta + count) % count;
    if (_state.canActivate) widget.onChanged?.call(widget.options[next].$1);
    _nodes[next].requestFocus();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent || !_state.canFocus) {
      return KeyEventResult.ignored;
    }
    // Horizontal arrows follow the visual direction (mirrored under RTL,
    // like slider and menu); the vertical orientation stays logical.
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey nextKey = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final LogicalKeyboardKey previousKey = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    final bool forward = widget.orientation == Axis.horizontal
        ? event.logicalKey == nextKey
        : event.logicalKey == LogicalKeyboardKey.arrowDown;
    final bool backward = widget.orientation == Axis.horizontal
        ? event.logicalKey == previousKey
        : event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (forward) {
      _move(index, 1);
      return KeyEventResult.handled;
    }
    if (backward) {
      _move(index, -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> radios = <Widget>[
      for (int i = 0; i < widget.options.length; i++)
        Focus(
          onKeyEvent: (FocusNode _, KeyEvent event) => _onKey(i, event),
          canRequestFocus: false,
          includeSemantics: false,
          child: CarbonRadioButton(
            label: widget.options[i].$2,
            selected: widget.value == widget.options[i].$1,
            labelPosition: widget.labelPosition,
            invalid: widget.invalid,
            readOnly: widget.readOnly,
            disabled: widget.disabled,
            readOnlyHint: widget.readOnlyHint,
            focusNode: _nodes[i],
            onSelected: widget.onChanged != null
                ? () => widget.onChanged!(widget.options[i].$1)
                : null,
          ),
        ),
    ];

    final Widget layout = widget.orientation == Axis.horizontal
        ? Wrap(spacing: CarbonSpacing.spacing05, children: radios)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < radios.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    top: i == 0 ? 0 : CarbonSpacing.spacing03,
                  ),
                  child: radios[i],
                ),
            ],
          );

    final Widget? message = widget.invalid && widget.invalidText != null
        ? CarbonFieldRequirement(widget.invalidText!)
        : widget.warn && widget.warnText != null
        ? CarbonFieldRequirement(
            widget.warnText!,
            status: CarbonFieldStatus.warning,
          )
        : widget.helperText != null
        ? CarbonHelperText(widget.helperText!)
        : null;

    return CarbonFormGroup(
      legend: widget.legend,
      aiLabel: widget.aiLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[layout, ?message],
      ),
    );
  }
}
