// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/slider/_slider.scss
//   react/src/components/Slider/Slider.tsx

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../form/carbon_form.dart';

/// A Carbon slider.
///
/// A 2px `borderSubtle` track with a `layerSelectedInverse` filled portion and
/// a 14px thumb. Drag the thumb, click the track to jump, or use the arrow
/// keys (Home/End jump to the bounds, Page keys take a larger step); values
/// snap to [step] within [min]/[max]. Provide [upperValue] + [onUpperChanged]
/// for a two-handle range. The min/max range labels use [formatLabel].
class CarbonSlider extends StatefulWidget {
  /// Creates a slider.
  const CarbonSlider({
    super.key,
    this.labelText,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.step = 1,
    this.upperValue,
    this.onUpperChanged,
    this.formatLabel,
    this.hideTextInput = false,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.invalidText,
  }) : assert(max > min, 'max must exceed min'),
       assert(
         (upperValue == null) == (onUpperChanged == null),
         'two-handle needs both upperValue and onUpperChanged',
       );

  /// The optional top label.
  final String? labelText;

  /// The (lower) value.
  final num value;

  /// The minimum.
  final num min;

  /// The maximum.
  final num max;

  /// Called with the new (lower) value; null disables the slider.
  final ValueChanged<num>? onChanged;

  /// The step the value snaps to.
  final num step;

  /// The upper value for a two-handle range.
  final num? upperValue;

  /// Called with the new upper value (two-handle).
  final ValueChanged<num>? onUpperChanged;

  /// Formats the min/max range labels (and the thumb value).
  final String Function(num value)? formatLabel;

  /// Hides the paired value text input (single-handle only).
  final bool hideTextInput;

  /// Whether disabled.
  final bool disabled;

  /// Whether read-only.
  final bool readOnly;

  /// Whether invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// The thumb diameter.
  static const double thumbSize = 14;

  /// The track thickness.
  static const double trackHeight = 2;

  bool get _twoHandle => upperValue != null;

  @override
  State<CarbonSlider> createState() => _CarbonSliderState();
}

class _CarbonSliderState extends State<CarbonSlider> {
  final FocusNode _lower = FocusNode();
  final FocusNode _upper = FocusNode();
  final GlobalKey _trackKey = GlobalKey();
  bool _draggingUpper = false;

  @override
  void dispose() {
    _lower.dispose();
    _upper.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onChanged != null && !widget.readOnly;

  String _format(num v) =>
      widget.formatLabel?.call(v) ??
      (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

  num _snap(num raw) {
    final num clamped = raw.clamp(widget.min, widget.max);
    final num steps = ((clamped - widget.min) / widget.step).round();
    return (widget.min + steps * widget.step).clamp(widget.min, widget.max);
  }

  double _fraction(num v) =>
      ((v - widget.min) / (widget.max - widget.min)).clamp(0, 1).toDouble();

  void _setLower(num v) {
    final num snapped = _snap(v);
    if (widget._twoHandle && snapped > widget.upperValue!) {
      return;
    }
    widget.onChanged?.call(snapped);
  }

  void _setUpper(num v) {
    final num snapped = _snap(v);
    if (snapped < widget.value) {
      return;
    }
    widget.onUpperChanged?.call(snapped);
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  num _valueAt(double dx, double width) {
    final double forward = _rtl ? width - dx : dx;
    return _snap(widget.min + (forward / width) * (widget.max - widget.min));
  }

  void _onTrackPointer(
    Offset localPosition,
    double width, {
    required bool start,
  }) {
    if (!_enabled) {
      return;
    }
    final num tapped = _valueAt(localPosition.dx, width);
    if (widget._twoHandle) {
      if (start) {
        // Pick the nearer thumb.
        final num distLower = (tapped - widget.value).abs();
        final num distUpper = (tapped - widget.upperValue!).abs();
        _draggingUpper = distUpper < distLower;
        (_draggingUpper ? _upper : _lower).requestFocus();
      }
      if (_draggingUpper) {
        _setUpper(tapped);
      } else {
        _setLower(tapped);
      }
    } else {
      _lower.requestFocus();
      _setLower(tapped);
    }
  }

  KeyEventResult _onThumbKey(
    FocusNode node,
    KeyEvent event, {
    required bool upper,
  }) {
    if (event is! KeyDownEvent || !_enabled) {
      return KeyEventResult.ignored;
    }
    final num current = upper ? widget.upperValue! : widget.value;
    final void Function(num) setter = upper ? _setUpper : _setLower;
    final num big = widget.step * 10;
    // Horizontal arrows follow the visual direction: the increase key is
    // Right in LTR and Left in RTL (the track mirrors).
    final LogicalKeyboardKey increaseKey = _rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final LogicalKeyboardKey decreaseKey = _rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (event.logicalKey == increaseKey) {
      setter(current + widget.step);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == decreaseKey) {
      setter(current - widget.step);
      return KeyEventResult.handled;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        setter(current + widget.step);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        setter(current - widget.step);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageUp:
        setter(current + big);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageDown:
        setter(current - big);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        setter(widget.min);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        setter(widget.max);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final TextStyle labelStyle = CarbonTypeStyles.bodyCompact01.copyWith(
      color: widget.disabled ? theme.textDisabled : theme.textPrimary,
    );

    final Widget track = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        // Mirror the geometry in RTL: min sits at the physical right and
        // the fill grows leftward.
        double xOf(num v) {
          final double fraction = _fraction(v);
          return (_rtl ? 1 - fraction : fraction) * width;
        }

        final double lowerX = xOf(widget.value);
        final double upperX = widget._twoHandle
            ? xOf(widget.upperValue!)
            : lowerX;
        final double fillLeft = widget._twoHandle
            ? math.min(lowerX, upperX)
            : (_rtl ? lowerX : 0);
        final double fillRight = widget._twoHandle
            ? math.max(lowerX, upperX)
            : (_rtl ? width : lowerX);

        return GestureDetector(
          key: _trackKey,
          behavior: HitTestBehavior.opaque,
          onPanDown: (DragDownDetails d) =>
              _onTrackPointer(d.localPosition, width, start: true),
          onPanUpdate: (DragUpdateDetails d) =>
              _onTrackPointer(d.localPosition, width, start: false),
          child: SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                // The unfilled track.
                Container(
                  height: CarbonSlider.trackHeight,
                  color: widget.disabled
                      ? theme.borderDisabled
                      : theme.borderSubtle01,
                ),
                // The filled portion.
                Positioned(
                  left: fillLeft,
                  width: (fillRight - fillLeft).clamp(0, width),
                  child: Container(
                    height: CarbonSlider.trackHeight,
                    color: widget.disabled
                        ? theme.borderDisabled
                        : theme.layerSelectedInverse,
                  ),
                ),
                _thumb(theme, lowerX, _lower, upper: false),
                if (widget._twoHandle)
                  _thumb(theme, upperX, _upper, upper: true),
              ],
            ),
          ),
        );
      },
    );

    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: Text(_format(widget.min), style: labelStyle),
        ),
        Expanded(child: track),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: Text(_format(widget.max), style: labelStyle),
        ),
        if (!widget.hideTextInput && !widget._twoHandle)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: SizedBox(
              width: 64,
              child: _ValueInput(
                value: widget.value,
                enabled: _enabled,
                invalid: widget.invalid,
                onSubmitted: _setLower,
              ),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.labelText != null)
          CarbonFormLabel(widget.labelText!, disabled: widget.disabled),
        row,
        if (widget.invalid && widget.invalidText != null)
          CarbonFieldRequirement(widget.invalidText!),
      ],
    );
  }

  Widget _thumb(
    CarbonThemeData theme,
    double x,
    FocusNode node, {
    required bool upper,
  }) {
    return Positioned(
      left: x - CarbonSlider.thumbSize / 2,
      child: Focus(
        focusNode: node,
        onKeyEvent: (FocusNode n, KeyEvent e) =>
            _onThumbKey(n, e, upper: upper),
        child: Builder(
          builder: (BuildContext context) {
            final bool focused = node.hasFocus;
            return Semantics(
              slider: true,
              value: _format(upper ? widget.upperValue! : widget.value),
              enabled: _enabled,
              child: AnimatedScale(
                scale: focused ? 1.4286 : 1,
                duration: const Duration(milliseconds: 70),
                child: Container(
                  width: CarbonSlider.thumbSize,
                  height: CarbonSlider.thumbSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.disabled
                        ? theme.borderDisabled
                        : theme.layerSelectedInverse,
                    border: focused
                        ? Border.all(color: theme.focus, width: 2)
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The small numeric value box paired with a single-handle slider.
class _ValueInput extends StatefulWidget {
  const _ValueInput({
    required this.value,
    required this.enabled,
    required this.invalid,
    required this.onSubmitted,
  });

  final num value;
  final bool enabled;
  final bool invalid;
  final ValueChanged<num> onSubmitted;

  @override
  State<_ValueInput> createState() => _ValueInputState();
}

class _ValueInputState extends State<_ValueInput> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value.toString(),
  );
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onBlur);
  }

  @override
  void didUpdateWidget(_ValueInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focus.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onBlur);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onBlur() {
    if (!_focus.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final num? parsed = num.tryParse(_controller.text);
    if (parsed != null) {
      widget.onSubmitted(parsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return CarbonField(
      size: CarbonFieldSize.md,
      status: widget.invalid
          ? CarbonFieldStatus.invalid
          : CarbonFieldStatus.none,
      disabled: !widget.enabled,
      focused: _focus.hasFocus,
      child: EditableText(
        controller: _controller,
        focusNode: _focus,
        readOnly: !widget.enabled,
        onSubmitted: (_) => _commit(),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        style: CarbonTypeStyles.bodyCompact01.copyWith(
          color: widget.enabled ? theme.textPrimary : theme.textDisabled,
        ),
        cursorColor: theme.focus,
        backgroundCursorColor: theme.textPlaceholder,
        selectionColor: theme.focus.withValues(alpha: 0.2),
        cursorWidth: 1,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }
}
