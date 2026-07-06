// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/progress-bar/_progress-bar.scss
//   react/src/components/ProgressBar/ProgressBar.tsx

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// The progress bar track heights.
enum CarbonProgressBarSize {
  /// 4px track.
  small(4),

  /// 8px track — the default.
  big(8);

  const CarbonProgressBarSize(this.trackHeight);

  /// The track height in logical pixels.
  final double trackHeight;
}

/// How the progress bar arranges its label, track, and helper text.
enum CarbonProgressBarType {
  /// Label above, helper below, full-width track.
  default_,

  /// Label inline to the left of the track.
  inline,

  /// Like [default_] but with the label and helper indented to align with
  /// the track content.
  indented,
}

/// The progress bar status.
enum CarbonProgressBarStatus {
  /// In progress; renders the `interactive` bar (or the indeterminate sweep
  /// when no value is given).
  active,

  /// Complete; full `supportSuccess` bar with a checkmark.
  finished,

  /// Failed; full `supportError` bar with an error icon.
  error,
}

/// A Carbon progress bar.
///
/// ```dart
/// CarbonProgressBar(label: 'Uploading', value: 42);
/// CarbonProgressBar(label: 'Working');           // indeterminate
/// CarbonProgressBar(
///   label: 'Done',
///   status: CarbonProgressBarStatus.finished,
/// );
/// ```
///
/// With [status] active and no [value], the bar is indeterminate — an
/// `interactive` stripe sweeping across the track on the upstream 1400ms
/// linear cycle. A [value] (0–[max]) renders a determinate bar that
/// animates at `fast-02`. The finished/error statuses fill the track and
/// show a 16px status icon by the label. The track reads the contextual
/// `borderSubtle` token.
///
/// Under reduced motion (`MediaQueryData.disableAnimations`) determinate
/// value changes apply instantly, but the indeterminate sweep keeps moving:
/// it is essential motion — per Carbon's motion guidance it communicates
/// that work is still ongoing, and a frozen stripe would read as a stall.
class CarbonProgressBar extends StatefulWidget {
  /// Creates a progress bar.
  const CarbonProgressBar({
    super.key,
    required this.label,
    this.value,
    this.max = 100,
    this.size = CarbonProgressBarSize.big,
    this.type = CarbonProgressBarType.default_,
    this.status = CarbonProgressBarStatus.active,
    this.helperText,
    this.hideLabel = false,
  }) : assert(max > 0, 'max must be positive');

  /// The label describing what is in progress.
  final String label;

  /// The current value (0–[max]); null with an active status is
  /// indeterminate.
  final double? value;

  /// The maximum value.
  final double max;

  /// The track size.
  final CarbonProgressBarSize size;

  /// The label/track/helper arrangement.
  final CarbonProgressBarType type;

  /// The status.
  final CarbonProgressBarStatus status;

  /// Optional helper text below the track.
  final String? helperText;

  /// Visually hides the label (still exposed to assistive technology).
  final bool hideLabel;

  /// The indeterminate sweep duration per spec.
  static const Duration indeterminateCycle = Duration(milliseconds: 1400);

  /// The status-icon edge length and helper/label gaps per spec.
  static const double statusIconSize = 16;

  @override
  State<CarbonProgressBar> createState() => _CarbonProgressBarState();
}

class _CarbonProgressBarState extends State<CarbonProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CarbonProgressBar.indeterminateCycle,
  );

  bool get _indeterminate =>
      widget.status == CarbonProgressBarStatus.active && widget.value == null;

  @override
  void initState() {
    super.initState();
    if (_indeterminate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CarbonProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_indeterminate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!_indeterminate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _barColor(CarbonThemeData theme) => switch (widget.status) {
    CarbonProgressBarStatus.active => theme.interactive,
    CarbonProgressBarStatus.finished => theme.supportSuccess,
    CarbonProgressBarStatus.error => theme.supportError,
  };

  double get _fraction {
    if (widget.status != CarbonProgressBarStatus.active) {
      return 1;
    }
    final double? value = widget.value;
    if (value == null) {
      return 0;
    }
    return (value / widget.max).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool inline = widget.type == CarbonProgressBarType.inline;
    final bool indented = widget.type == CarbonProgressBarType.indented;
    final double indent = indented ? CarbonSpacing.spacing05 : 0;

    final Widget label = _Label(
      label: widget.label,
      hideLabel: widget.hideLabel,
      status: widget.status,
      theme: theme,
    );

    final Widget track = _Track(
      size: widget.size,
      fraction: _fraction,
      indeterminate: _indeterminate,
      controller: _controller,
      barColor: _barColor(theme),
      trackColor: CarbonLayer.of(context).borderSubtle,
    );

    final Widget? helper = widget.helperText == null
        ? null
        : Padding(
            padding: EdgeInsetsDirectional.only(
              top: CarbonSpacing.spacing03,
              start: indent,
            ),
            child: Text(
              widget.helperText!,
              style: CarbonTypeStyles.helperText01.copyWith(
                color: widget.status == CarbonProgressBarStatus.error
                    ? theme.textError
                    : theme.textSecondary,
              ),
            ),
          );

    final Widget core = Semantics(
      container: true,
      label: widget.label,
      value: _indeterminate ? null : '${(_fraction * 100).round()}%',
      child: ExcludeSemantics(
        child: inline
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(child: label),
                  const SizedBox(width: CarbonSpacing.spacing05),
                  Expanded(child: track),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: indent,
                      bottom: CarbonSpacing.spacing03,
                    ),
                    child: label,
                  ),
                  track,
                ],
              ),
      ),
    );

    if (helper == null) {
      return core;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[core, helper],
    );
  }
}

/// The label row: label text plus the optional status icon.
class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.hideLabel,
    required this.status,
    required this.theme,
  });

  final String label;
  final bool hideLabel;
  final CarbonProgressBarStatus status;
  final CarbonThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (hideLabel) {
      return const SizedBox.shrink();
    }
    final Widget text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CarbonTypeStyles.bodyCompact01.copyWith(
          color: theme.textPrimary,
        ),
      ),
    );
    final Widget? icon = switch (status) {
      CarbonProgressBarStatus.active => null,
      CarbonProgressBarStatus.finished => CarbonIcon(
        CarbonIcons.checkmarkFilled,
        color: theme.supportSuccess,
      ),
      CarbonProgressBarStatus.error => CarbonIcon(
        CarbonIcons.errorFilled,
        color: theme.supportError,
      ),
    };
    return Row(
      children: <Widget>[
        text,
        if (icon != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: CarbonSpacing.spacing05,
            ),
            child: icon,
          ),
      ],
    );
  }
}

/// The track and its bar (determinate scale or indeterminate sweep).
class _Track extends StatelessWidget {
  const _Track({
    required this.size,
    required this.fraction,
    required this.indeterminate,
    required this.controller,
    required this.barColor,
    required this.trackColor,
  });

  final CarbonProgressBarSize size;
  final double fraction;
  final bool indeterminate;
  final AnimationController controller;
  final Color barColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48),
      child: SizedBox(
        height: size.trackHeight,
        width: double.infinity,
        child: ColoredBox(
          color: trackColor,
          // The indeterminate sweep deliberately keeps running under
          // reduced motion (essential motion — ongoing work).
          child: indeterminate
              ? AnimatedBuilder(
                  animation: controller,
                  builder: (BuildContext context, Widget? child) => CustomPaint(
                    painter: _IndeterminatePainter(
                      progress: controller.value,
                      color: barColor,
                      // The sweep travels along the reading direction
                      // (`progress-bar-indeterminate-rtl` upstream).
                      reverse: Directionality.of(context) == TextDirection.rtl,
                    ),
                  ),
                )
              // `_progress-bar.scss`: transition: transform
              // $duration-fast-02 motion(standard, productive); instant
              // under reduced motion.
              : TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: fraction),
                  duration: reducedMotion
                      ? Duration.zero
                      : CarbonDuration.fast02,
                  curve: CarbonEasing.standardProductive,
                  builder:
                      (BuildContext context, double width, Widget? child) =>
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: width,
                              heightFactor: 1,
                              child: child,
                            ),
                          ),
                  child: ColoredBox(color: barColor),
                ),
        ),
      ),
    );
  }
}

/// Paints the indeterminate sweep: a 12.5%-wide stripe travelling across the
/// track, matching the upstream `progress-bar-indeterminate` keyframes
/// (background-position-x 25% → −105% over a 200%-wide gradient).
class _IndeterminatePainter extends CustomPainter {
  const _IndeterminatePainter({
    required this.progress,
    required this.color,
    required this.reverse,
  });

  /// The 0–1 cycle position.
  final double progress;

  /// The stripe color.
  final Color color;

  /// Travels right-to-left when set (the RTL reading direction).
  final bool reverse;

  @override
  void paint(Canvas canvas, Size size) {
    // The stripe is 12.5% of the track wide; it travels from just off the
    // leading edge to fully past the trailing edge across one cycle.
    const double stripeFraction = 0.125;
    final double stripeWidth = size.width * stripeFraction;
    final double travel = size.width + stripeWidth;
    final double start = -stripeWidth + progress * travel;
    final double left = reverse ? size.width - start - stripeWidth : start;
    canvas.drawRect(
      Rect.fromLTWH(left, 0, stripeWidth, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_IndeterminatePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      reverse != oldDelegate.reverse;
}
