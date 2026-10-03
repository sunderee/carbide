// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

/// Native platforms consume the slider's Flutter semantics directly.
String? syncNativeRangeSemantics(
  String identifier, {
  String? nodeId,
  required String label,
  required String valueText,
  required num value,
  required num min,
  required num max,
  required bool enabled,
  required bool focusable,
  required bool readOnly,
}) => nodeId;
