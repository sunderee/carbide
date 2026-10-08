// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

/// Honors caller traversal policy on a programmatic skip-link destination.
///
/// Flutter's web focus manager gives focusable semantics tabindex=0, and can
/// retain that attribute after focus management stops. A skip destination can
/// receive programmatic focus without becoming an extra native Tab stop.
void syncNativeShellContentFocus(
  String identifier, {
  required bool focusable,
  required bool traversable,
}) {
  final _Element? element = _document.querySelector(
    '[flt-semantics-identifier="$identifier"]',
  );
  if (focusable) {
    element?.setAttribute('tabindex', traversable ? '0' : '-1');
  } else {
    element?.removeAttribute('tabindex');
  }
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
}

extension type _Element(JSObject _) implements JSObject {
  external void setAttribute(String name, String value);
  external void removeAttribute(String name);
}
