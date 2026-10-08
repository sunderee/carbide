// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:flutter/widgets.dart';

/// Keeps a sliver row mounted only while one of its descendants has focus.
/// Offscreen focused editors retain their state; unrelated rows can recycle.
class CarbonKeepFocusedRow extends StatefulWidget {
  /// Creates a focus-aware row.
  const CarbonKeepFocusedRow({required this.child, super.key});

  /// The row and any expanded detail.
  final Widget child;
  @override
  State<CarbonKeepFocusedRow> createState() => _KeepFocusedRowState();
}

class _KeepFocusedRowState extends State<CarbonKeepFocusedRow>
    with AutomaticKeepAliveClientMixin {
  bool _focused = false;
  @override
  bool get wantKeepAlive => _focused;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Focus(
      canRequestFocus: false,
      includeSemantics: false,
      onFocusChange: (value) {
        _focused = value;
        updateKeepAlive();
      },
      child: widget.child,
    );
  }
}
