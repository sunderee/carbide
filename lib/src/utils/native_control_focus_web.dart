// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

// Browser-only implementation, selected by native_control_focus.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

/// Reconciles a control's native focus after a semantics DOM move.
///
/// Flutter 3.47.6 can report the view unfocused while reparenting a focused
/// semantics element, parking framework focus at the root. Its focus manager
/// also caches focus requests. Run after the update, only for the control that
/// held primary focus before it. Respect another active element and an inactive
/// document; no listeners or element references are retained.
///
/// [identifier] must be generated without CSS selector metacharacters.
bool restoreNativeControlFocus(String identifier) {
  if (!_document.hasFocus()) return false;
  final _Element? element = _document.querySelector(
    '[flt-semantics-identifier="$identifier"]',
  );
  if (element == null) return false;
  final _Element? active = element.getRootNode().activeElement;
  if (active == element) return true;
  if (active != null &&
      active.tagName != 'BODY' &&
      active.tagName != 'FLUTTER-VIEW') {
    return false;
  }
  element.focus(_FocusOptions(preventScroll: true));
  return element.getRootNode().activeElement == element;
}

/// Captures the current native control for guarded repair after a DOM move.
///
/// The returned callback must be released on close or disposal. It respects a
/// different active control, an inactive document and a detached captured node.
bool Function()? captureNativeControlFocus() {
  if (!_document.hasFocus()) return null;
  final _Element? element = _document.activeElement;
  if (element == null ||
      element.tagName == 'BODY' ||
      element.tagName == 'FLUTTER-VIEW') {
    return null;
  }
  return () {
    if (!_document.hasFocus() || !element.isConnected) return false;
    final _Element? active = element.getRootNode().activeElement;
    if (active == element) return true;
    if (active != null &&
        active.tagName != 'BODY' &&
        active.tagName != 'FLUTTER-VIEW') {
      return false;
    }
    element.focus(_FocusOptions(preventScroll: true));
    return element.getRootNode().activeElement == element;
  };
}

/// Captures a guarded native request for a newly focused read-only control.
///
/// The caller confirms framework ownership before invoking the callback after
/// semantics updates. A different native target chosen since capture wins.
/// No DOM listeners or long-lived element references are retained.
bool Function()? captureReadOnlyControlFocus(String identifier) =>
    _captureControlFocus(identifier);

/// Captures guarded focus for an editor reparented by overlay semantics.
///
/// Targets the native input inside the named region. Framework ownership is
/// checked by the caller; another native control or an inactive document wins.
bool Function()? captureTextControlFocus(
  String identifier, {
  required bool readOnly,
}) => _captureControlFocus(identifier, text: true, readOnly: readOnly);

bool Function()? _captureControlFocus(
  String identifier, {
  bool text = false,
  bool readOnly = false,
}) {
  if (!_document.hasFocus()) return null;
  final _Element? previous = _document.activeElement;
  return () {
    if (!_document.hasFocus()) return false;
    final _Element? region = _document.querySelector(
      text
          ? '[flt-semantics-identifier^="$identifier-"]'
          : '[flt-semantics-identifier="$identifier"]',
    );
    final _Element? target = text
        ? region?.querySelector('input,textarea')
        : region;
    if (target == null || !target.isConnected) return false;
    final _Element? active = target.getRootNode().activeElement;
    if (active == target) {
      if (text) target.readOnly = readOnly;
      return true;
    }
    if (active != previous &&
        active != null &&
        active.tagName != 'BODY' &&
        active.tagName != 'FLUTTER-VIEW') {
      return false;
    }
    target.focus(_FocusOptions(preventScroll: true));
    if (text) target.readOnly = readOnly;
    return target.getRootNode().activeElement == target;
  };
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _Element? get activeElement;
  external bool hasFocus();
}

extension type _Element(JSObject _) implements JSObject {
  external set readOnly(bool value);
  external _Element? querySelector(String selector);
  external String get tagName;
  external bool get isConnected;
  external _Document getRootNode();
  external void focus(_FocusOptions options);
}

extension type _FocusOptions._(JSObject _) implements JSObject {
  external factory _FocusOptions({bool preventScroll});
}
