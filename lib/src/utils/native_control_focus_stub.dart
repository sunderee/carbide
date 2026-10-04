// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// Native semantics focus is managed by Flutter on non-web platforms.
bool restoreNativeControlFocus(String identifier) => false;

/// No native DOM exists outside the browser.
bool Function()? captureNativeControlFocus() => null;

/// Native read-only focus is managed by Flutter on non-web platforms.
bool Function()? captureReadOnlyControlFocus(String identifier) => null;

/// Native editor focus is managed by Flutter on non-web platforms.
bool Function()? captureTextControlFocus(
  String identifier, {
  required bool readOnly,
  bool allowSharedEditor = false,
}) => null;
