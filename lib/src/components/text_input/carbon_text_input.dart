// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/text-input/_text-input.scss
//   styles/scss/components/fluid-text-input/_fluid-text-input.scss
//   react/src/components/{TextInput,PasswordInput}
//
// Built on `EditableText` (Flutter's base text editor) — no Material — with
// the Carbon field chrome from CarbonField (#66).

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../form/carbon_form.dart';

/// A Carbon text input.
///
/// ```dart
/// CarbonTextInput(labelText: 'Email', placeholder: 'you@example.com');
/// ```
///
/// Renders the [CarbonField] chrome (sized `field` background, `border-strong`
/// bottom border, focus ring, status icon) around an `EditableText`. Supports
/// the full state matrix — disabled, read-only, invalid, warning — plus the
/// [inline] (label beside the field) and [fluid] (label inside the field)
/// layouts.
class CarbonTextInput extends StatefulWidget {
  /// Creates a text input.
  const CarbonTextInput({
    super.key,
    required this.labelText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.placeholder,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.hideLabel = false,
    this.inline = false,
    this.fluid = false,
    this.obscureText = false,
    this.keyboardType,
    this.trailing,
    this.aiLabel,
    this.aiRevert = false,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         controller == null || initialValue == null,
         'provide controller or initialValue, not both',
       ),
       assert(!(inline && fluid), 'inline and fluid are mutually exclusive');

  /// The field label.
  final String labelText;

  /// An external controller; one is created if omitted.
  final TextEditingController? controller;

  /// The initial text when no [controller] is given.
  final String? initialValue;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Placeholder shown when the field is empty.
  final String? placeholder;

  /// Helper text beneath the field (hidden when invalid/warn).
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether the field is disabled.
  final bool disabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Whether the field is invalid.
  final bool invalid;

  /// The error message shown when [invalid].
  final String? invalidText;

  /// Whether the field is in a warning state.
  final bool warn;

  /// The warning message shown when [warn].
  final String? warnText;

  /// Visually hides the label (still announced).
  final bool hideLabel;

  /// Lays the label beside the field instead of above.
  final bool inline;

  /// Uses the fluid treatment (label inside the field).
  final bool fluid;

  /// Obscures the text (used by [CarbonPasswordInput]).
  final bool obscureText;

  /// The keyboard type.
  final TextInputType? keyboardType;

  /// An optional trailing widget inside the field (e.g. a toggle button).
  final Widget? trailing;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in
  /// the field per upstream's `decorator` prop; adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// An optional external focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// The fluid field height (`4rem`).
  static const double fluidHeight = 64;

  @override
  State<CarbonTextInput> createState() => _CarbonTextInputState();
}

class _CarbonTextInputState extends State<CarbonTextInput> {
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

    // The accessible label is merged onto the editable itself (the textField
    // node), so a trailing button (e.g. the password toggle) stays a
    // separate, discoverable node.
    final Widget editable = MergeSemantics(
      child: Semantics(
        label: widget.labelText,
        child: _Editable(
          controller: _controller,
          focusNode: _focus,
          placeholder: widget.placeholder,
          enabled: enabled,
          readOnly: widget.readOnly,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          color: widget.disabled ? theme.textDisabled : theme.textPrimary,
          placeholderColor: theme.textPlaceholder,
          cursorColor: theme.focus,
          selectionColor: theme.focus.withValues(alpha: 0.2),
        ),
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

    if (widget.fluid) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _FluidField(
            label: widget.labelText,
            status: _status,
            disabled: widget.disabled,
            focused: _focus.hasFocus,
            editable: editable,
          ),
          ?message,
        ],
      );
    }

    final Widget field = CarbonField(
      size: widget.size,
      status: _status,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      focused: _focus.hasFocus,
      trailing: widget.trailing,
      aiLabel: widget.aiLabel,
      aiRevert: widget.aiRevert,
      child: editable,
    );

    final Widget? label = widget.hideLabel
        ? null
        : CarbonFormLabel(widget.labelText, disabled: widget.disabled);

    final Widget core = widget.inline
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (label != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: CarbonSpacing.spacing05,
                    top: CarbonSpacing.spacing03,
                  ),
                  child: ExcludeSemantics(child: label),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[field, ?message],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (label != null) ExcludeSemantics(child: label),
              field,
              ?message,
            ],
          );

    return core;
  }
}

/// `EditableText` with Carbon defaults and a placeholder overlay.
class _Editable extends StatelessWidget {
  const _Editable({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.enabled,
    required this.readOnly,
    required this.obscureText,
    required this.keyboardType,
    required this.autofocus,
    required this.onChanged,
    required this.color,
    required this.placeholderColor,
    required this.cursorColor,
    required this.selectionColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final Color color;
  final Color placeholderColor;
  final Color cursorColor;
  final Color selectionColor;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = CarbonTypeStyles.bodyCompact01.copyWith(
      color: color,
    );
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        if (placeholder != null && controller.text.isEmpty)
          ExcludeSemantics(
            child: IgnorePointer(
              child: Text(
                placeholder!,
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
          obscureText: obscureText,
          autofocus: autofocus,
          keyboardType: keyboardType,
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

/// The fluid field box: label inside, editable below, bottom border, focus
/// ring and status icon (`fluid-text-input/_fluid-text-input.scss`).
class _FluidField extends StatelessWidget {
  const _FluidField({
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
    final Color border = disabled
        ? const Color(0x00000000)
        : theme.borderStrong01;

    final Widget? statusIcon = invalid
        ? CarbonIcon(
            CarbonIcons.errorFilled,
            size: 16,
            color: theme.supportError,
          )
        : status == CarbonFieldStatus.warning
        ? CarbonIcon(
            CarbonIcons.warningAltFilled,
            size: 16,
            color: theme.supportWarning,
          )
        : null;

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: layer.field,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: SizedBox(
        height: CarbonTextInput.fluidHeight,
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              top: 13,
              start: CarbonSpacing.spacing05,
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: CarbonTypeStyles.label01.copyWith(
                    color: disabled ? theme.textDisabled : theme.textSecondary,
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 31,
              start: CarbonSpacing.spacing05,
              end: statusIcon == null
                  ? CarbonSpacing.spacing05
                  : CarbonSpacing.spacing09,
              child: editable,
            ),
            if (statusIcon != null)
              PositionedDirectional(
                top: 31,
                end: CarbonSpacing.spacing05,
                child: statusIcon,
              ),
          ],
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

/// A password input: a [CarbonTextInput] that obscures its text with a
/// show/hide toggle (`View` / `ViewOff`).
class CarbonPasswordInput extends StatefulWidget {
  /// Creates a password input.
  const CarbonPasswordInput({
    super.key,
    required this.labelText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.placeholder,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.showPasswordLabel = 'Show password',
    this.hidePasswordLabel = 'Hide password',
    this.aiLabel,
    this.aiRevert = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The field label.
  final String labelText;

  /// An external controller.
  final TextEditingController? controller;

  /// The initial text.
  final String? initialValue;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Placeholder shown when empty.
  final String? placeholder;

  /// Helper text.
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether disabled.
  final bool disabled;

  /// Whether read-only.
  final bool readOnly;

  /// Whether invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Whether in warning.
  final bool warn;

  /// The warning message.
  final String? warnText;

  /// The toggle's accessible label when the password is hidden.
  final String showPasswordLabel;

  /// The toggle's accessible label when the password is shown.
  final String hidePasswordLabel;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in
  /// the field per upstream's `decorator` prop; adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// An optional focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<CarbonPasswordInput> createState() => _CarbonPasswordInputState();
}

class _CarbonPasswordInputState extends State<CarbonPasswordInput> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Widget toggle = Semantics(
      button: true,
      label: _obscured ? widget.showPasswordLabel : widget.hidePasswordLabel,
      child: GestureDetector(
        onTap: widget.disabled
            ? null
            : () => setState(() => _obscured = !_obscured),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: CarbonSpacing.spacing03,
            end: CarbonField.paddingInline,
          ),
          child: CarbonIcon(
            _obscured ? CarbonIcons.view : CarbonIcons.viewOff,
            size: 16,
            color: widget.disabled ? theme.iconDisabled : theme.iconPrimary,
          ),
        ),
      ),
    );

    return CarbonTextInput(
      labelText: widget.labelText,
      controller: widget.controller,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      placeholder: widget.placeholder,
      helperText: widget.helperText,
      size: widget.size,
      disabled: widget.disabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
      invalidText: widget.invalidText,
      warn: widget.warn,
      warnText: widget.warnText,
      obscureText: _obscured,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      trailing: toggle,
      aiLabel: widget.aiLabel,
      aiRevert: widget.aiRevert,
    );
  }
}
