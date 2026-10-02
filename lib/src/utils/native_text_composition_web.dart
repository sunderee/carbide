// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:async';
// Browser-only implementation, selected by native_text_composition.dart.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';

import 'package:flutter/widgets.dart';

/// Restores browser composition omitted by Flutter's accessible input path.
///
/// Flutter 3.47.6's SemanticsTextEditingStrategy overrides addEventHandlers
/// without installing DefaultTextEditingStrategy's composition handlers. This
/// bridge observes the focused editor's native events before the engine handles
/// input, and passes genuine platform-supplied composing ranges through as-is.
class NativeTextComposition {
  /// Observes composition only while this editor owns Flutter focus.
  NativeTextComposition({required this.isFocused, required this.onCommit}) {
    _startListener = _start.toJS;
    _updateListener = _update.toJS;
    _endListener = _end.toJS;
    _document
      ..addEventListener('compositionstart', _startListener, true)
      ..addEventListener('compositionupdate', _updateListener, true)
      ..addEventListener('compositionend', _endListener, true);
  }

  /// Whether this field owns Flutter focus.
  final bool Function() isFocused;

  /// Commits through the editor after a native compositionend event.
  final ValueChanged<String> onCommit;
  late final JSFunction _startListener;
  late final JSFunction _updateListener;
  late final JSFunction _endListener;
  _Element? _target;
  int? _base;
  String? _text;
  bool _disposed = false;

  void _start(_CompositionEvent event) {
    if (isFocused()) {
      _target = event.target;
      _base = _target?.selectionStart;
      _text = null;
    }
  }

  void _update(_CompositionEvent event) {
    if (isFocused() && identical(event.target, _target)) {
      _text = event.data;
    }
  }

  void _end(_CompositionEvent event) {
    if (_target == null || !identical(event.target, _target)) {
      return;
    }
    final String text = _target!.value;
    _target = null;
    _base = null;
    _text = null;
    // Some browsers end composition without another input event. Commit after
    // the browser finishes dispatching, through EditableText's formatting path.
    scheduleMicrotask(() {
      if (!_disposed) {
        onCommit(text);
      }
    });
  }

  /// Supplies a range only when it matches the actual native composing text.
  TextEditingValue resolve(TextEditingValue value) {
    if (value.composing.isValid && !value.composing.isCollapsed) {
      return value;
    }
    final int? base = _base;
    final String? text = _text;
    if (!isFocused() ||
        base == null ||
        base < 0 ||
        text == null ||
        text.isEmpty ||
        base + text.length > value.text.length ||
        value.text.substring(base, base + text.length) != text) {
      return value;
    }
    return value.copyWith(
      composing: TextRange(start: base, end: base + text.length),
    );
  }

  /// Detaches every observer and cancels queued commit work.
  void dispose() {
    _disposed = true;
    _document
      ..removeEventListener('compositionstart', _startListener, true)
      ..removeEventListener('compositionupdate', _updateListener, true)
      ..removeEventListener('compositionend', _endListener, true);
  }
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external void addEventListener(
    String type,
    JSFunction listener,
    bool capture,
  );
  external void removeEventListener(
    String type,
    JSFunction listener,
    bool capture,
  );
}

extension type _CompositionEvent(JSObject _) implements JSObject {
  external String get data;
  external _Element? get target;
}

extension type _Element(JSObject _) implements JSObject {
  external int? get selectionStart;
  external String get value;
}
