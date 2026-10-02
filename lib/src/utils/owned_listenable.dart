// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

/// Owns an internal notifier or borrows a caller's notifier, with one listener.
///
/// This utility is internal to Carbide. The effective [value] is stored rather
/// than resolved from a widget getter, so updates detach the actual old object.
/// [create] receives the outgoing value when borrowing ends, allowing its state
/// to seed the replacement. Only objects created here are disposed here.
class OwnedListenable<T extends ChangeNotifier> {
  /// Resolves the initial notifier and subscribes [onChanged], if supplied.
  OwnedListenable({
    T? external,
    required T Function(T? previous) create,
    this.onChanged,
  }) : _create = create,
       _ownsValue = external == null,
       _value = external ?? create(null) {
    _listen();
  }

  final T Function(T? previous) _create;

  /// The listener attached to the effective notifier.
  final VoidCallback? onChanged;
  bool _ownsValue;
  bool _disposed = false;
  T _value;

  /// The notifier currently bound to the component.
  T get value => _value;

  /// Rebinds to [external], returning whether the effective object changed.
  ///
  /// A null external value retains an existing internal object. Rebinding an
  /// unchanged object leaves its listener and ownership untouched.
  bool update(T? external) {
    assert(!_disposed, 'cannot rebind a disposed owner');
    if ((external == null && _ownsValue) || identical(external, _value)) {
      return false;
    }
    final T previous = _value;
    _unlisten();
    if (_ownsValue) previous.dispose();
    _value = external ?? _create(previous);
    _ownsValue = external == null;
    _listen();
    return true;
  }

  /// Detaches the listener and disposes the effective object if internally owned.
  void dispose() {
    assert(!_disposed, 'cannot dispose an owner twice');
    _disposed = true;
    _unlisten();
    if (_ownsValue) _value.dispose();
  }

  void _listen() {
    if (onChanged != null) _value.addListener(_notifyChanged);
  }

  void _unlisten() {
    if (onChanged != null) _value.removeListener(_notifyChanged);
  }

  void _notifyChanged() => onChanged?.call();
}

/// Binds text controllers while preserving the full outgoing editing value.
class OwnedTextEditingController
    extends OwnedListenable<TextEditingController> {
  /// Creates an internal controller from [initialText] when none is supplied.
  ///
  /// Switching from external to internal copies text, selection, and composing
  /// range. [initialText] is used only on the initial internal creation.
  OwnedTextEditingController({
    super.external,
    String? initialText,
    super.onChanged,
  }) : super(
         create: (TextEditingController? previous) =>
             TextEditingController.fromValue(
               previous?.value ?? TextEditingValue(text: initialText ?? ''),
             ),
       );
}

/// Binds focus nodes and transfers an outgoing focus request to the new node.
class OwnedFocusNode extends OwnedListenable<FocusNode> {
  /// Creates an internal focus node when [external] is omitted.
  OwnedFocusNode({super.external, VoidCallback? onChanged})
    : super(onChanged: onChanged ?? _noop, create: (_) => FocusNode());

  bool _transferringFocus = false;

  /// Suppresses automatic selection during a focused handoff.
  ///
  /// Pass this to EditableText.selectAllOnFocus. A handoff continues editing;
  /// ordinary focus retains Flutter's platform default through the null value.
  bool? get selectAllOnFocus => _transferringFocus ? false : null;

  @override
  bool update(FocusNode? external) {
    final bool wasFocused = value.hasFocus;
    final bool changed = super.update(external);
    if (changed) {
      _transferringFocus = wasFocused && value.canRequestFocus;
    }
    if (changed && _transferringFocus) {
      // FocusNode queues a request until attachment when the replacement is
      // new. The field's Focus/EditableText still enforces disabled policy.
      value.requestFocus();
    }
    return changed;
  }

  @override
  void _notifyChanged() {
    if (value.hasFocus) _transferringFocus = false;
    super._notifyChanged();
  }

  static void _noop() {}
}
