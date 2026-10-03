// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Repairs native focus across the current and deferred overlay removal frames.
///
/// The overlay owner cancels repair on reopening and disposes this helper.
class OverlayFocusRepair {
  Timer? _timer;
  int _generation = 0;

  /// Schedules repair while the target and overlay transition remain current.
  void schedule(
    FocusNode? target,
    bool Function()? restoreNativeFocus, {
    required bool Function() isCurrent,
  }) {
    cancel();
    if (target == null || restoreNativeFocus == null) return;
    final int generation = _generation;
    void repair() {
      if (generation != _generation || !isCurrent()) return;
      _timer?.cancel();
      _timer = Timer(Duration.zero, () {
        if (generation != _generation ||
            !isCurrent() ||
            target.context == null ||
            target.parent == null ||
            !target.canRequestFocus) {
          return;
        }
        final FocusNode? current = FocusManager.instance.primaryFocus;
        if (current != target && current != FocusManager.instance.rootScope) {
          return;
        }
        if (restoreNativeFocus()) target.requestFocus();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      repair();
      if (generation == _generation && isCurrent()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => repair());
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Cancels pending work when a different overlay transition begins.
  void cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels pending work when the overlay owner is removed.
  void dispose() => cancel();
}
