// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

// Browser-only implementation, selected by native_range_semantics.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

/// Completes the native role/label for Flutter's adjustable semantics.
///
/// Flutter 3.47.6 puts a slider's label on the parent of its native range input,
/// which does not give that input an accessible name. Without adjustment
/// actions it renders a generic node instead, losing the slider role and value
/// for disabled/read-only controls. Preserve the engine's input and surrogate
/// range behavior when it exists; expose a static slider when it does not.
/// [identifier] must have no CSS selector metacharacters.
String? syncNativeRangeSemantics(
  String identifier, {
  String? nodeId,
  required String label,
  required String valueText,
  required num value,
  required num min,
  required num max,
  required bool enabled,
  required bool focusable,
  required bool readOnly,
}) {
  // Changing engine roles can remove the identifier attribute without
  // restoring it (the unchanged identifier is no longer marked dirty).
  final _Element? host =
      _document.querySelector('[flt-semantics-identifier="$identifier"]') ??
      (nodeId == null ? null : _document.getElementById(nodeId));
  if (host == null) {
    return nodeId;
  }
  host.setAttribute('flt-semantics-identifier', identifier);
  final _Element? input = host.querySelector('input[type="range"]');
  if (input != null) {
    // The engine owns range input events, disabled gesture mode and focus.
    input.setAttribute('aria-label', label);
    input.setAttribute('aria-disabled', (!enabled).toString());
    input.setAttribute('aria-readonly', readOnly.toString());
    // Keep the native input's surrogate min/max/value for its events, while
    // announcing the component's real numeric range and formatted value.
    input.setAttribute('aria-valuenow', value.toString());
    input.setAttribute('aria-valuetext', valueText);
    input.setAttribute('aria-valuemin', min.toString());
    input.setAttribute('aria-valuemax', max.toString());
    for (final String name in <String>[
      'role',
      'aria-valuenow',
      'aria-valuetext',
      'aria-valuemin',
      'aria-valuemax',
      'aria-readonly',
      'aria-disabled',
    ]) {
      host.removeAttribute(name);
    }
  } else {
    host
      ..setAttribute('role', 'slider')
      ..setAttribute('aria-label', label)
      ..setAttribute('aria-valuenow', value.toString())
      ..setAttribute('aria-valuetext', valueText)
      ..setAttribute('aria-valuemin', min.toString())
      ..setAttribute('aria-valuemax', max.toString())
      ..setAttribute('aria-disabled', (!enabled).toString())
      ..setAttribute('aria-readonly', readOnly.toString())
      ..setAttribute('tabindex', focusable ? '0' : '-1');
  }
  return host.id;
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _Element? getElementById(String id);
}

extension type _Element(JSObject _) implements JSObject {
  external String get id;
  external _Element? querySelector(String selector);
  external void setAttribute(String name, String value);
  external void removeAttribute(String name);
}
