// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/checkbox/_checkbox.scss
//   react/src/components/{Checkbox,CheckboxGroup}

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';
import '../../utils/control_state.dart';
import '../form/carbon_form.dart';

/// A Carbon checkbox.
///
/// A 16px box (`icon-primary` border, 2px radius) with an `icon-inverse`
/// checkmark when [value] is true or a dash when [indeterminate]; the label
/// is `body-compact-01`, offset 20px from the row start. Keyboard focus draws
/// the 2px `focus` ring 1px outside the box. A null [onChanged] disables it.
///
/// Group several with [CarbonCheckboxGroup] for a shared legend and
/// group-level validation.
///
/// A null callback or [disabled] disables focus and editing. [readOnly]
/// retains focus and the announced value while preventing activation. Its
/// [readOnlyHint] announces non-editability and can be localized.
class CarbonCheckbox extends StatelessWidget {
  /// Creates a checkbox.
  const CarbonCheckbox({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.indeterminate = false,
    this.invalid = false,
    this.disabled = false,
    this.readOnly = false,
    this.readOnlyHint = CarbonControlState.defaultReadOnlyHint,
    this.focusNode,
    this.autofocus = false,
    this.aiLabel,
  });

  /// The label beside the box.
  final String label;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered
  /// inline after the label text per upstream's `decorator` prop
  /// (`--checkbox-wrapper--decorator`, 8px start margin).
  final Widget? aiLabel;

  /// Whether the box is checked. Ignored visually when [indeterminate].
  final bool value;

  /// Called with the toggled value; null disables the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Shows the indeterminate dash instead of a check.
  final bool indeterminate;

  /// Renders the invalid (error-border) treatment.
  final bool invalid;

  /// Renders read-only (non-editable but not greyed).
  final bool readOnly;

  /// Disables focus and editing, independently of callback availability.
  final bool disabled;

  /// Localizable read-only announcement; ignored when disabled.
  final String readOnlyHint;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// The box edge length (`1rem`).
  static const double boxSize = 16;

  /// The label's start offset (`padding-inline-start: 20px`).
  static const double labelOffset = 20;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonControlState state = CarbonControlState.resolve(
      hasCallback: onChanged != null,
      disabled: disabled,
      readOnly: readOnly,
    );
    final bool enabled = state.canActivate;

    return Semantics(
      checked: indeterminate ? null : value,
      mixed: indeterminate,
      enabled: state.canActivate,
      hint: state.semanticsHint(readOnlyHint),
      label: label,
      child: CarbonInteraction(
        enabled: state.canFocus,
        readOnly: state.isReadOnly,
        onPressed: enabled ? () => onChanged!(!value) : null,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool focused = states.contains(WidgetState.focused);
          final bool disabled = state.isDisabled;

          final Color glyph = theme.iconInverse;
          final Color fill = disabled
              ? theme.iconDisabled
              : invalid
              ? theme.supportError
              : theme.iconPrimary;

          final Widget box = _CheckboxBox(
            checked: value,
            indeterminate: indeterminate,
            borderColor: state.isReadOnly ? theme.iconDisabled : fill,
            fillColor: state.isReadOnly ? const Color(0x00000000) : fill,
            glyphColor: state.isReadOnly ? theme.textPrimary : glyph,
            outlined: state.isReadOnly,
            focusColor: theme.focus,
            focused: focused,
          );

          // An empty label (e.g. a data-table row selector) must not reserve a
          // text line: that extra height pins the box to the top and breaks
          // vertical centering. Render the box on its own.
          if (label.isEmpty) {
            return box;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: labelOffset,
                // heightFactor keeps the Align from inflating to fill a
                // bounded parent (a list-box row would otherwise pin the
                // whole checkbox to its top); the box still tops-align to
                // the first label line via the Row's crossAxisAlignment.
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  heightFactor: 1,
                  child: box,
                ),
              ),
              Flexible(
                child: Padding(
                  // padding-block-start: 1px aligns the text to the box.
                  padding: const EdgeInsets.only(top: 1),
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      style: CarbonTypeStyles.bodyCompact01.copyWith(
                        color: disabled
                            ? theme.textDisabled
                            : theme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              // The AI label flows after the label text with an 8px margin.
              if (aiLabel != null) ...<Widget>[
                const SizedBox(width: CarbonSpacing.spacing03),
                aiLabel!,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The 16px box: border/fill, check or dash glyph, and the outer focus ring.
class _CheckboxBox extends StatelessWidget {
  const _CheckboxBox({
    required this.checked,
    required this.indeterminate,
    required this.borderColor,
    required this.fillColor,
    required this.glyphColor,
    required this.focusColor,
    required this.focused,
    required this.outlined,
  });

  final bool checked;
  final bool indeterminate;
  final Color borderColor;
  final Color fillColor;
  final Color glyphColor;
  final Color focusColor;
  final bool focused;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: CarbonCheckbox.boxSize,
    child: CustomPaint(
      foregroundPainter: focused ? _CheckboxFocusRing(focusColor) : null,
      painter: _CheckboxPainter(
        checked: checked,
        indeterminate: indeterminate,
        borderColor: borderColor,
        fillColor: fillColor,
        glyphColor: glyphColor,
        outlined: outlined,
      ),
    ),
  );
}

/// Paints the box (1px border / fill) and the checkmark or dash glyph.
class _CheckboxPainter extends CustomPainter {
  const _CheckboxPainter({
    required this.checked,
    required this.indeterminate,
    required this.borderColor,
    required this.fillColor,
    required this.glyphColor,
    required this.outlined,
  });

  final bool checked;
  final bool indeterminate;
  final Color borderColor;
  final Color fillColor;
  final Color glyphColor;
  final bool outlined;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect box = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    final bool filled = checked || indeterminate;
    if (filled) {
      canvas.drawRRect(box, Paint()..color = fillColor);
    }
    if (!filled || outlined) {
      // 1px border, inset by half the stroke so it stays inside the 16px box.
      final RRect inset = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        inset,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = borderColor,
      );
    }

    if (indeterminate) {
      // A 8px horizontal dash, 2px thick.
      canvas.drawLine(
        Offset(4, size.height / 2),
        Offset(size.width - 4, size.height / 2),
        Paint()
          ..strokeWidth = 2
          ..color = glyphColor,
      );
    } else if (checked) {
      // The check polyline (icon-inverse), 1.5px, rounded joins.
      final Path check = Path()
        ..moveTo(3.5, 8.5)
        ..lineTo(6.5, 11.5)
        ..lineTo(12.5, 4.5);
      canvas.drawPath(
        check,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = glyphColor,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckboxPainter old) =>
      checked != old.checked ||
      indeterminate != old.indeterminate ||
      borderColor != old.borderColor ||
      fillColor != old.fillColor ||
      glyphColor != old.glyphColor ||
      outlined != old.outlined;
}

/// The 2px `focus` ring drawn 1px outside the box (`outline-offset: 1px`).
class _CheckboxFocusRing extends CustomPainter {
  const _CheckboxFocusRing(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Offset 1px + 1px (half the 2px stroke) → centre the stroke 2px out.
    final Rect ring = (Offset.zero & size).inflate(2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(ring, const Radius.circular(2)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_CheckboxFocusRing old) => color != old.color;
}

/// A labelled group of checkboxes with a shared legend and group-level
/// helper / validation messaging (`<fieldset>` + `<legend>`).
class CarbonCheckboxGroup extends StatelessWidget {
  /// Creates a checkbox group.
  const CarbonCheckboxGroup({
    super.key,
    required this.legend,
    required this.children,
    this.helperText,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.aiLabel,
  });

  /// The group legend.
  final String legend;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered
  /// inline after the group legend per upstream's `decorator` prop.
  final Widget? aiLabel;

  /// The checkboxes.
  final List<Widget> children;

  /// Optional helper text (hidden when invalid/warn).
  final String? helperText;

  /// Whether the group is invalid.
  final bool invalid;

  /// The error message shown when [invalid].
  final String? invalidText;

  /// Whether the group is in a warning state.
  final bool warn;

  /// The warning message shown when [warn].
  final String? warnText;

  @override
  Widget build(BuildContext context) {
    final Widget? message = invalid && invalidText != null
        ? CarbonFieldRequirement(invalidText!)
        : warn && warnText != null
        ? CarbonFieldRequirement(warnText!, status: CarbonFieldStatus.warning)
        : helperText != null
        ? CarbonHelperText(helperText!)
        : null;

    return CarbonFormGroup(
      legend: legend,
      aiLabel: aiLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Widget child in children)
            Padding(padding: const EdgeInsets.only(top: 4), child: child),
          ?message,
        ],
      ),
    );
  }
}
