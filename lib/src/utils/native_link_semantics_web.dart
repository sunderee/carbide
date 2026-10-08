// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

// Browser-only implementation, selected by native_link_semantics.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

/// Gives callback-based anchors their explicit native link role.
///
/// Flutter 3.47.6's SemanticLink creates an anchor without href when navigation
/// belongs to a callback. Such an anchor has no implicit browser link role.
/// Keep its engine actions and focus handling, without inventing a destination.
/// The engine also omits its native disabled announcement. Disabled anchors
/// cannot participate in native Tab traversal, including after a state change.
/// [identifier] must be generated without CSS selector metacharacters.
void syncNativeLinkSemantics(
  String identifier, {
  required bool enabled,
  required bool focusable,
}) {
  final _Element? element = _document.querySelector(
    '[flt-semantics-identifier="$identifier"]',
  );
  element
    ?..setAttribute('role', 'link')
    ..setAttribute('aria-disabled', (!enabled).toString())
    ..setAttribute('tabindex', enabled && focusable ? '0' : '-1');
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
}

extension type _Element(JSObject _) implements JSObject {
  external void setAttribute(String name, String value);
}
