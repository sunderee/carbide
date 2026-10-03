// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// The shared editing, focus and announcement policy for value controls.
///
/// Explicit disabling and a missing callback take precedence over read-only.
/// Read-only controls remain focusable, retain their value and omit editing
/// actions. Their semantics report non-operability with a localizable hint.
enum CarbonControlState {
  /// The value can be changed and the control can receive focus.
  interactive,

  /// The value can be inspected through focus but cannot be changed.
  readOnly,

  /// The control cannot receive focus or change its value.
  disabled;

  /// The default read-only announcement, overridable on each control.
  static const String defaultReadOnlyHint = 'Read only';

  /// Resolves explicit flags and callback availability in one place.
  static CarbonControlState resolve({
    required bool hasCallback,
    bool disabled = false,
    bool readOnly = false,
  }) => disabled || !hasCallback
      ? CarbonControlState.disabled
      : readOnly
      ? CarbonControlState.readOnly
      : CarbonControlState.interactive;

  /// Whether pointer, keyboard and semantics actions may edit the value.
  bool get canActivate => this == interactive;

  /// Whether keyboard or assistive-technology focus may inspect the control.
  bool get canFocus => this != disabled;

  /// Whether the disabled visual treatment applies.
  bool get isDisabled => this == disabled;

  /// Whether the read-only visual treatment applies.
  bool get isReadOnly => this == readOnly;

  /// Announces read-only only when that is the resolved state.
  String semanticsHint(String readOnlyHint) => isReadOnly ? readOnlyHint : '';
}
