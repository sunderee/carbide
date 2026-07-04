// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/form/_form.scss
//   styles/scss/components/text-input/_text-input.scss (the canonical field)
//   react/src/components/{Form,FormGroup,FormItem,FormLabel}
//
// The shared scaffolding every Tier B text-style input reuses: the label,
// helper, and requirement (error/warning) text; the FormGroup/FormItem
// wrappers; and CarbonField — the presentational field surface (background,
// bottom border, focus ring, status icon) that Text Input, Number Input,
// Select, Text Area and Search render their editable content inside.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';

/// The Carbon field heights (`$size-*` via the density scale).
enum CarbonFieldSize {
  /// 32px.
  sm(CarbonSize.small),

  /// 40px — the default.
  md(CarbonSize.medium),

  /// 48px.
  lg(CarbonSize.large);

  const CarbonFieldSize(this.height);

  /// The field height in logical pixels.
  final double height;
}

/// The validation state of a field.
enum CarbonFieldStatus {
  /// No validation messaging.
  none,

  /// Invalid: error outline + `ErrorFilled` icon + error requirement text.
  invalid,

  /// Warning: `WarningAltFilled` icon + warning requirement text.
  warning,
}

/// A Carbon form label (`label-01`, `text-secondary`).
///
/// Renders `text-disabled` when [disabled]. Carries the spec's 8px
/// (`spacing-03`) bottom margin so it stacks correctly above its control.
class CarbonFormLabel extends StatelessWidget {
  /// Creates a form label.
  const CarbonFormLabel(this.text, {super.key, this.disabled = false});

  /// The label text.
  final String text;

  /// Renders the disabled color.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing03),
      child: Text(
        text,
        style: CarbonTypeStyles.label01.copyWith(
          color: disabled ? theme.textDisabled : theme.textSecondary,
        ),
      ),
    );
  }
}

/// Helper text shown beneath a field (`helper-text-01`, `text-helper`).
///
/// Carries the spec's 4px (`spacing-02`) top margin. Replaced by
/// [CarbonFieldRequirement] when the field is invalid or in warning.
class CarbonHelperText extends StatelessWidget {
  /// Creates helper text.
  const CarbonHelperText(this.text, {super.key, this.disabled = false});

  /// The helper text.
  final String text;

  /// Renders the disabled color.
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: CarbonSpacing.spacing02),
      child: Text(
        text,
        style: CarbonTypeStyles.helperText01.copyWith(
          color: disabled ? theme.textDisabled : theme.textHelper,
        ),
      ),
    );
  }
}

/// The validation message beneath a field (`cds--form-requirement`).
///
/// `helper-text-01`; the error message renders `text-error`, the warning
/// message `text-primary`, per `_form.scss`. Announced as a live region.
class CarbonFieldRequirement extends StatelessWidget {
  /// Creates a requirement (validation) message.
  const CarbonFieldRequirement(
    this.text, {
    super.key,
    this.status = CarbonFieldStatus.invalid,
  });

  /// The message text.
  final String text;

  /// Whether this is the invalid or warning message.
  final CarbonFieldStatus status;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: CarbonSpacing.spacing02),
      child: Semantics(
        liveRegion: true,
        child: Text(
          text,
          style: CarbonTypeStyles.helperText01.copyWith(
            color: status == CarbonFieldStatus.invalid
                ? theme.textError
                : theme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// The vertical stack of a single form field: label, control, then helper or
/// requirement text (`cds--form-item`).
class CarbonFormItem extends StatelessWidget {
  /// Creates a form item.
  const CarbonFormItem({super.key, required this.children});

  /// The label / control / helper widgets, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}

/// A labelled group of related controls (`<fieldset>` + `<legend>`).
///
/// Used to group checkboxes or radios under one [legend] (`label-01`).
class CarbonFormGroup extends StatelessWidget {
  /// Creates a form group.
  const CarbonFormGroup({
    super.key,
    required this.legend,
    required this.child,
    this.aiLabel,
  });

  /// The group legend text.
  final String legend;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered
  /// inline after the legend (`--checkbox-group--decorator`,
  /// 8px start margin) per upstream's `decorator` prop.
  final Widget? aiLabel;

  /// The grouped controls.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    // A group boundary that keeps the legend a discrete node (an explicit
    // `label` here would duplicate the legend Text in the merged node).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing03),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  legend,
                  style: CarbonTypeStyles.label01.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                // The AI label flows after the legend with an 8px margin
                // (`margin-inline-start: $spacing-03`).
                if (aiLabel != null) ...<Widget>[
                  const SizedBox(width: CarbonSpacing.spacing03),
                  aiLabel!,
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Opts every fluid-capable descendant field into the fluid treatment.
///
/// Upstream's `FluidForm` wraps a form so each input renders its fluid
/// variant; here the scope is an inherited flag the fluid-capable
/// components combine with their own `fluid` parameter.
///
/// ```dart
/// CarbonFluidForm(
///   child: Column(children: <Widget>[
///     CarbonTextInput(labelText: 'Name'),
///     CarbonDropdown<int>(titleText: 'Team', items: teams),
///   ]),
/// )
/// ```
class CarbonFluidForm extends InheritedWidget {
  /// Creates a fluid form scope.
  const CarbonFluidForm({super.key, required super.child});

  /// Whether a [CarbonFluidForm] encloses [context].
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CarbonFluidForm>() != null;

  @override
  bool updateShouldNotify(CarbonFluidForm oldWidget) => false;
}

/// The presentational Carbon field surface (`cds--text-input` chrome).
///
/// Wraps a consumer-supplied [child] (the editable content) with the field
/// box: the contextual `field` background, the `1px border-strong` bottom
/// border, the 2px inset focus ring, and the right-aligned status icon for
/// invalid/warning. Purely presentational — the consumer owns the focus node
/// and passes [focused]; this draws the matching chrome.
///
/// Per `_text-input.scss`:
/// * enabled → `field` bg, `border-strong` bottom border, `text-primary`;
/// * disabled → `field` bg, transparent bottom border, `text-disabled`;
/// * read-only → transparent bg, `border-subtle` bottom border;
/// * invalid → 2px `support-error` outline (focus wins when focused) +
///   `ErrorFilled`;
/// * warning → `WarningAltFilled` (the bottom border stays `border-strong`);
/// * with [aiLabel] → the bottom-anchored AI aura gradient and the
///   `ai-border-strong` bottom border, with the label rendered nearest the
///   end edge (the status icon shifts inward). [aiRevert] suppresses the
///   aura while a revert control shows (`:not(:has(--revert))`).
class CarbonField extends StatelessWidget {
  /// Creates a field surface.
  const CarbonField({
    super.key,
    required this.child,
    this.size = CarbonFieldSize.md,
    this.status = CarbonFieldStatus.none,
    this.disabled = false,
    this.readOnly = false,
    this.focused = false,
    this.trailing,
    this.aiLabel,
    this.aiRevert = false,
    this.fluid = false,
  });

  /// The editable content (e.g. an `EditableText`) or display child.
  final Widget child;

  /// The field height.
  final CarbonFieldSize size;

  /// The validation status.
  final CarbonFieldStatus status;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether the field currently holds focus (drawn by the consumer).
  final bool focused;

  /// An optional trailing control (e.g. the password visibility toggle or
  /// number steppers), laid out after the status icon.
  final Widget? trailing;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered
  /// nearest the end edge with the AI aura gradient behind the field
  /// (upstream's `decorator` prop).
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control
  /// (`--ai-label--revert` drops the gradient upstream).
  final bool aiRevert;

  /// The fluid treatment: the field renders at the 64px fluid height (the
  /// consumer stacks its label inside the [child]).
  final bool fluid;

  /// Horizontal field padding (`layout.density('padding-inline')`).
  static const double paddingInline = 16;

  /// The status-icon size.
  static const double statusIconSize = 16;

  /// The AI aura for a field: `ai-gradient('bottom', 50%)` — aura-start-sm
  /// at the bottom edge blending to aura-end at 50%, transparent above. The
  /// CSS 15% interpolation hint is approximated with a computed stop.
  static Gradient aiFieldGradient(CarbonThemeData theme) => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: <Color>[
      theme.aiAuraStartSm,
      Color.lerp(theme.aiAuraStartSm, theme.aiAuraEnd, 0.5)!,
      theme.aiAuraEnd,
      theme.aiAuraEnd.withValues(alpha: 0),
    ],
    stops: const <double>[0, 0.15, 0.5, 1],
  );

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool invalid = status == CarbonFieldStatus.invalid;
    final bool warning = status == CarbonFieldStatus.warning;

    // The AI treatment: the aura gradient over the field background and
    // the ai-border-strong bottom border, unless a revert control shows.
    final bool ai = aiLabel != null && !aiRevert && !readOnly;

    final Color background = readOnly ? const Color(0x00000000) : layer.field;
    final Color borderColor = disabled
        ? const Color(0x00000000)
        : readOnly
        ? layer.borderSubtle
        : ai
        ? theme.aiBorderStrong
        : theme.borderStrong01;

    final Widget? statusIcon = invalid
        ? CarbonIcon(
            CarbonIcons.errorFilled,
            size: statusIconSize,
            color: theme.supportError,
          )
        : warning
        ? CarbonIcon(
            CarbonIcons.warningAltFilled,
            size: statusIconSize,
            color: theme.supportWarning,
          )
        : null;

    Widget field = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        gradient: ai ? aiFieldGradient(theme) : null,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: SizedBox(
        height: fluid ? 64 : size.height,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: paddingInline),
          child: Row(
            children: <Widget>[
              Expanded(child: child),
              if (statusIcon != null)
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: CarbonSpacing.spacing03,
                    // With an AI label the icon sits flush against it; the
                    // label carries the 16px end inset.
                    end: aiLabel == null ? paddingInline : 0,
                  ),
                  child: statusIcon,
                ),
              // The AI label renders 16px from the end edge
              // (`inset-inline-end: $spacing-05`), or just before a
              // trailing control (the select chevron / password toggle:
              // `inset-inline-end: $spacing-08 + 8px` in _select.scss).
              if (aiLabel != null) ...<Widget>[
                aiLabel!,
                SizedBox(
                  width: trailing == null
                      ? paddingInline
                      : CarbonSpacing.spacing03,
                ),
              ],
              ?trailing,
              if (aiLabel == null && statusIcon == null && trailing == null)
                const SizedBox(width: paddingInline),
            ],
          ),
        ),
      ),
    );

    // Focus wins over the invalid outline; otherwise invalid shows its own
    // 2px error ring. The CarbonFocusRing paints the 2px inset `focus`
    // outline; the error ring is the same geometry in `support-error`.
    if (focused) {
      field = CarbonFocusRing(visible: true, child: field);
    } else if (invalid) {
      field = _ErrorRing(color: theme.supportError, child: field);
    }
    return field;
  }
}

/// A 2px inset outline in the error color, matching `focus-outline('invalid')`
/// — the same geometry as [CarbonFocusRing] but using `support-error`.
class _ErrorRing extends StatelessWidget {
  const _ErrorRing({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
    child: child,
  );
}
