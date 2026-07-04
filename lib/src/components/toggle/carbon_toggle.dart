// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/toggle/_toggle.scss
//   react/src/components/{Toggle,ToggleSmall}
//
// The 8px gap between the top label and the control is upstream's
// `enable-v12-toggle-reduced-label-spacing` flagged value, adopted
// deliberately: the label is the shared CarbonFormLabel, and the v11
// 16px gap would break the cross-component label rhythm (ADR 0002).

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';
import '../form/carbon_form.dart';

/// The Carbon toggle sizes and their geometry.
enum CarbonToggleSize {
  /// 48×24 track, 18px handle, +24 travel — the default.
  md(48, 24, 18, 24, 12),

  /// 32×16 track, 10px handle, +16 travel; shows a checkmark when on.
  sm(32, 16, 10, 16, 8);

  const CarbonToggleSize(
    this.trackWidth,
    this.trackHeight,
    this.handle,
    this.travel,
    this.radius,
  );

  /// The track width.
  final double trackWidth;

  /// The track height.
  final double trackHeight;

  /// The handle diameter.
  final double handle;

  /// The handle travel distance when toggled on.
  final double travel;

  /// The track corner radius.
  final double radius;

  /// The handle inset from the track edge.
  double get margin => (trackHeight - handle) / 2;
}

/// A Carbon toggle switch.
///
/// A pill track (`toggleOff` → `supportSuccess`) with a sliding `iconOnColor`
/// handle; the [CarbonToggleSize.sm] variant adds a `supportSuccess` checkmark
/// on the handle when on. Shows an optional top [labelText] plus side state
/// labels ([labelA] off / [labelB] on); [hideLabel] replaces the side labels
/// with the top label inline. Slides at `fast-01`, instant under reduced
/// motion. Exposed as a switch to assistive technology.
class CarbonToggle extends StatelessWidget {
  /// Creates a toggle.
  const CarbonToggle({
    super.key,
    required this.labelText,
    required this.toggled,
    this.onToggled,
    this.size = CarbonToggleSize.md,
    this.labelA = 'Off',
    this.labelB = 'On',
    this.hideLabel = false,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The top label (or the inline label when [hideLabel]).
  final String labelText;

  /// Whether the toggle is on.
  final bool toggled;

  /// Called with the new value; null disables the toggle.
  final ValueChanged<bool>? onToggled;

  /// The size variant.
  final CarbonToggleSize size;

  /// The state text shown when off.
  final String labelA;

  /// The state text shown when on.
  final String labelB;

  /// Replaces the side state labels with [labelText] inline (no top label).
  final bool hideLabel;

  /// Renders read-only.
  final bool readOnly;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool enabled = onToggled != null && !readOnly;
    final bool disabled = onToggled == null;
    final bool reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration duration = reduceMotion
        ? Duration.zero
        : CarbonDuration.fast01;

    final String sideText = hideLabel ? labelText : (toggled ? labelB : labelA);

    final Widget switchControl = Semantics(
      toggled: toggled,
      enabled: !disabled,
      label: labelText,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: enabled ? () => onToggled!(!toggled) : null,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final Color track = disabled
              ? theme.buttonDisabled
              : toggled
              ? theme.supportSuccess
              : theme.toggleOff;
          final Color handleColor = disabled
              ? theme.iconOnColorDisabled
              : theme.iconOnColor;
          return _ToggleFocusRing(
            color: theme.focus,
            radius: size.radius,
            visible: states.contains(WidgetState.focused),
            child: AnimatedContainer(
              duration: duration,
              width: size.trackWidth,
              height: size.trackHeight,
              decoration: BoxDecoration(
                color: track,
                borderRadius: BorderRadius.circular(size.radius),
              ),
              child: Stack(
                children: <Widget>[
                  AnimatedPositionedDirectional(
                    duration: duration,
                    top: size.margin,
                    start: toggled ? size.margin + size.travel : size.margin,
                    child: Container(
                      width: size.handle,
                      height: size.handle,
                      decoration: BoxDecoration(
                        color: handleColor,
                        shape: BoxShape.circle,
                      ),
                      child: size == CarbonToggleSize.sm && toggled
                          ? Center(
                              child: CarbonIcon(
                                CarbonIcons.checkmark,
                                size: 6,
                                color: theme.supportSuccess,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    final Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        switchControl,
        const SizedBox(width: CarbonSpacing.spacing03),
        ExcludeSemantics(
          child: Text(
            sideText,
            style: CarbonTypeStyles.bodyShort01.copyWith(
              color: disabled ? theme.textDisabled : theme.textPrimary,
            ),
          ),
        ),
      ],
    );

    if (hideLabel) {
      return row;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(child: CarbonFormLabel(labelText, disabled: disabled)),
        row,
      ],
    );
  }
}

/// The 2px `focus` ring 1px outside the track (`outline-offset: 1px`).
class _ToggleFocusRing extends StatelessWidget {
  const _ToggleFocusRing({
    required this.color,
    required this.radius,
    required this.visible,
    required this.child,
  });

  final Color color;
  final double radius;
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return child;
    }
    return CustomPaint(
      foregroundPainter: _ToggleRingPainter(color, radius),
      child: child,
    );
  }
}

class _ToggleRingPainter extends CustomPainter {
  const _ToggleRingPainter(this.color, this.radius);

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect ring = (Offset.zero & size).inflate(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ring, Radius.circular(radius + 2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ToggleRingPainter old) =>
      color != old.color || radius != old.radius;
}
