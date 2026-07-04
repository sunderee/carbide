// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
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
class CarbonRadioButton extends StatelessWidget {
  /// Creates a radio button.
  const CarbonRadioButton({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.labelPosition = CarbonRadioLabelPosition.right,
    this.invalid = false,
    this.readOnly = false,
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
    final bool enabled = onSelected != null && !readOnly;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: onSelected != null,
      label: label,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: enabled ? onSelected : null,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool focused = states.contains(WidgetState.focused);
          final bool disabled = onSelected == null;
          final Color ringColor = disabled
              ? theme.iconDisabled
              : invalid
              ? theme.supportError
              : theme.iconPrimary;
          final Color dotColor = disabled ? theme.textDisabled : ringColor;

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
/// keys move and select among the enabled options (roving focus).
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
    this.readOnly = false,
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
    // The group enables uniformly, so just wrap to the adjacent option,
    // select it, and move focus there (roving selection).
    final int count = widget.options.length;
    final int next = (from + delta + count) % count;
    widget.onChanged?.call(widget.options[next].$1);
    _nodes[next].requestFocus();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final bool forward = widget.orientation == Axis.horizontal
        ? event.logicalKey == LogicalKeyboardKey.arrowRight
        : event.logicalKey == LogicalKeyboardKey.arrowDown;
    final bool backward = widget.orientation == Axis.horizontal
        ? event.logicalKey == LogicalKeyboardKey.arrowLeft
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
    final bool enabled = widget.onChanged != null && !widget.readOnly;
    final List<Widget> radios = <Widget>[
      for (int i = 0; i < widget.options.length; i++)
        Focus(
          onKeyEvent: (FocusNode _, KeyEvent event) => _onKey(i, event),
          child: CarbonRadioButton(
            label: widget.options[i].$2,
            selected: widget.value == widget.options[i].$1,
            labelPosition: widget.labelPosition,
            invalid: widget.invalid,
            readOnly: widget.readOnly,
            focusNode: _nodes[i],
            onSelected: enabled
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
