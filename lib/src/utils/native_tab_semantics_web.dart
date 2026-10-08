// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

// Browser-only implementation, selected by native_tab_semantics.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

/// Completes tab traversal and disabled state after an engine semantics update.
///
/// Flutter 3.47.6 removes its focus listeners when a node stops being focusable
/// but leaves tabindex=0 behind. Its SemanticTab also omits aria-disabled.
/// Retain its tab role, selected state, panel relationship and actions while
/// keeping only the active enabled tab in native keyboard traversal.
/// [identifier] must be generated without CSS selector metacharacters.
void syncNativeTabSemantics(
  String identifier, {
  required bool enabled,
  required bool roving,
}) {
  final _Element? element = _document.querySelector(
    '[flt-semantics-identifier="$identifier"]',
  );
  element
    ?..setAttribute('tabindex', enabled && roving ? '0' : '-1')
    ..setAttribute('aria-disabled', (!enabled).toString());
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
}

extension type _Element(JSObject _) implements JSObject {
  external void setAttribute(String name, String value);
}
