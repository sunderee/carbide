// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

// Browser-only implementation, selected by native_text_value.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

/// Synchronizes read-only state and the inactive native input's value.
///
/// Flutter 3.47.6's SemanticTextField applies editing state while focused, but
/// does not copy semantic value updates into an inactive HTML input. Thus a
/// step committed while a button owns focus can leave the native value stale.
/// The active editable input remains under the engine's control, preserving selection,
/// composition and user edits that have not reached the framework yet.
/// The semantics strategy also omits the native readOnly property when no
/// editable input connection is open. Set it even for a focused read-only
/// field so browser typing cannot change its accessible value.
///
/// [identifier] must be a generated identifier with no CSS selector metacharacters.
void syncNativeTextValue(
  String identifier,
  String text, {
  required bool readOnly,
}) {
  final _Element? input = _document.querySelector(
    '[flt-semantics-identifier="$identifier"] input',
  );
  if (input == null) {
    return;
  }
  input.readOnly = readOnly;
  if ((readOnly || !identical(input.getRootNode().activeElement, input)) &&
      input.value != text) {
    input.value = text;
  }
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _Element? get activeElement;
}

extension type _Element(JSObject _) implements JSObject {
  external String get value;
  external set value(String value);
  external set readOnly(bool value);
  external _Document getRootNode();
}
