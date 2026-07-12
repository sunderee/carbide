// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/progress-indicator/_progress-indicator.scss
//   react/src/components/ProgressIndicator/ProgressIndicator.tsx
//
// ProgressIndicator: a sequence of steps (complete / current / incomplete /
// invalid / disabled) with connecting lines, horizontal or vertical, with an
// optional interactive (clickable) mode.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';

/// A single step in a [CarbonProgressIndicator].
class CarbonProgressStep {
  /// Creates a progress step.
  const CarbonProgressStep({
    required this.label,
    this.secondaryLabel,
    this.invalid = false,
    this.disabled = false,
  });

  /// The step label.
  final String label;

  /// An optional secondary label beneath the label.
  final String? secondaryLabel;

  /// Whether the step is in an error state.
  final bool invalid;

  /// Whether the step is disabled.
  final bool disabled;
}

enum _StepState { complete, current, incomplete, invalid, disabled }

/// A stepper showing progress through a sequence of [steps].
///
/// ```dart
/// CarbonProgressIndicator(
///   currentIndex: 1,
///   steps: const <CarbonProgressStep>[
///     CarbonProgressStep(label: 'Account'),
///     CarbonProgressStep(label: 'Details'),
///     CarbonProgressStep(label: 'Review'),
///   ],
/// )
/// ```
class CarbonProgressIndicator extends StatelessWidget {
  /// Creates a progress indicator.
  const CarbonProgressIndicator({
    required this.steps,
    required this.currentIndex,
    super.key,
    this.vertical = false,
    this.interactive = false,
    this.onStepSelected,
  });

  /// The steps.
  final List<CarbonProgressStep> steps;

  /// The index of the current step.
  final int currentIndex;

  /// Whether the steps stack vertically.
  final bool vertical;

  /// Whether steps are clickable.
  final bool interactive;

  /// Called with the index of a tapped step (when [interactive]).
  final ValueChanged<int>? onStepSelected;

  _StepState _stateOf(int index) {
    final CarbonProgressStep step = steps[index];
    if (step.disabled) return _StepState.disabled;
    if (step.invalid) return _StepState.invalid;
    if (index < currentIndex) return _StepState.complete;
    if (index == currentIndex) return _StepState.current;
    return _StepState.incomplete;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      for (int i = 0; i < steps.length; i++)
        _Step(
          step: steps[i],
          state: _stateOf(i),
          vertical: vertical,
          isLast: i == steps.length - 1,
          // The line after a complete step is filled.
          lineComplete: i < currentIndex,
          onTap: interactive && !steps[i].disabled && onStepSelected != null
              ? () => onStepSelected!(i)
              : null,
        ),
    ];

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            )
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _Step extends StatefulWidget {
  const _Step({
    required this.step,
    required this.state,
    required this.vertical,
    required this.isLast,
    required this.lineComplete,
    required this.onTap,
  });

  final CarbonProgressStep step;
  final _StepState state;
  final bool vertical;
  final bool isLast;
  final bool lineComplete;
  final VoidCallback? onTap;

  @override
  State<_Step> createState() => _StepWidgetState();
}

class _StepWidgetState extends State<_Step> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Color lineColor = widget.lineComplete
        ? theme.interactive
        : theme.borderSubtle00;

    final Color labelColor = widget.state == _StepState.disabled
        ? theme.textDisabled
        : widget.state == _StepState.invalid
        ? theme.supportError
        : theme.textPrimary;

    final Widget glyph = _StepGlyph(state: widget.state);

    final Widget label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          widget.step.label,
          style: CarbonTypeStyles.bodyCompact01.copyWith(color: labelColor),
        ),
        if (widget.step.secondaryLabel != null)
          Text(
            widget.step.secondaryLabel!,
            style: CarbonTypeStyles.label01.copyWith(
              color: theme.textSecondary,
            ),
          ),
      ],
    );

    final Widget content = widget.vertical
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                children: <Widget>[
                  glyph,
                  if (!widget.isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SizedBox(
                        width: 1,
                        height: 24,
                        child: ColoredBox(color: lineColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: CarbonSpacing.spacing03),
              Padding(padding: const EdgeInsets.only(top: 1), child: label),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      glyph,
                      const SizedBox(width: CarbonSpacing.spacing03),
                      if (!widget.isLast)
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: SizedBox(
                            width: 64,
                            height: 1,
                            child: ColoredBox(color: lineColor),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: CarbonSpacing.spacing03),
                  label,
                ],
              ),
            ],
          );

    Widget step = content;
    if (widget.onTap != null) {
      step = Focus(
        onFocusChange: (bool f) => setState(() => _focused = f),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: CarbonFocusRing(visible: _focused, inset: true, child: step),
        ),
      );
    }

    return Semantics(
      label: widget.step.label,
      button: widget.onTap != null,
      selected: widget.state == _StepState.current,
      enabled: widget.state != _StepState.disabled,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            end: widget.vertical || widget.isLast ? 0 : CarbonSpacing.spacing05,
            bottom: widget.vertical && !widget.isLast
                ? CarbonSpacing.spacing03
                : 0,
          ),
          child: step,
        ),
      ),
    );
  }
}

/// The 16px step glyph for a given [state].
class _StepGlyph extends StatelessWidget {
  const _StepGlyph({required this.state});

  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    switch (state) {
      case _StepState.complete:
        return CarbonIcon(
          CarbonIcons.checkmarkOutline,
          color: theme.interactive,
        );
      case _StepState.invalid:
        return CarbonIcon(CarbonIcons.warning, color: theme.supportError);
      case _StepState.current:
        return SizedBox.square(
          dimension: 16,
          child: CustomPaint(painter: _CirclePainter(theme.interactive, true)),
        );
      case _StepState.incomplete:
        return SizedBox.square(
          dimension: 16,
          child: CustomPaint(
            painter: _CirclePainter(theme.borderSubtle00, false),
          ),
        );
      case _StepState.disabled:
        return SizedBox.square(
          dimension: 16,
          child: CustomPaint(
            painter: _CirclePainter(theme.textDisabled, false),
          ),
        );
    }
  }
}

/// Paints a 16px step circle: an outline ring, plus a filled centre when
/// [filled] (the current step).
class _CirclePainter extends CustomPainter {
  const _CirclePainter(this.color, this.filled);

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.width / 2 - 1;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (filled) {
      canvas.drawCircle(
        center,
        radius - 3,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.color != color || old.filled != filled;
}
