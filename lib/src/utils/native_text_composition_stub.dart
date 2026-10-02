// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

/// Leaves platform-supplied composition unchanged outside the browser.
class NativeTextComposition {
  /// Creates a composition observer with the same interface as the web bridge.
  NativeTextComposition({
    required bool Function() isFocused,
    required ValueChanged<String> onCommit,
  });

  /// Retains the editing value delivered by the native input client.
  TextEditingValue resolve(TextEditingValue value) => value;

  /// Releases browser listeners, if any.
  void dispose() {}
}
