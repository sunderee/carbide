// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:flutter/widgets.dart';

/// An invisible portal owner with nonempty semantics bounds.
/// Flutter drops a zero-sized OverlayPortal's semantics in compact layouts
/// even while its overlay is visible. A one-pixel owner keeps the dialog's
/// traversal separate from adjacent controls. Use only while it is present.
class CarbonOverlaySemanticsAnchor extends StatelessWidget {
  /// Creates a non-painting semantics anchor.
  const CarbonOverlaySemanticsAnchor({this.modal = true, super.key});

  /// Whether previously painted page semantics are blocked.
  final bool modal;
  @override
  Widget build(BuildContext context) => BlockSemantics(
    blocking: modal,
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      child: const SizedBox(width: 1, height: 1),
    ),
  );
}
