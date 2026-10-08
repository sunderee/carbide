// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/widgets.dart';

/// Internal implementation helper, not exported from carbide.dart.
///
/// Scrolls [child] into view inside the enclosing [Scrollable] whenever
/// [active] flips true — and on first build when already true, so a popup
/// that opens with its highlight below the fold reveals it immediately.
///
/// The reveal is the minimal movement that makes the child fully visible
/// (nothing moves when it already is), matching how browsers keep the
/// keyboard-highlighted option of a native list box in view (#279). The
/// jump is instant, like the browser behavior it mirrors. Without an
/// enclosing [Scrollable] this is inert.
class ScrollIntoView extends StatefulWidget {
  /// Creates a scroll-into-view region driven by [active].
  const ScrollIntoView({required this.active, required this.child, super.key});

  /// Whether the child must be kept visible (typically "is highlighted").
  final bool active;

  /// The widget to reveal.
  final Widget child;

  @override
  State<ScrollIntoView> createState() => _ScrollIntoViewState();
}

class _ScrollIntoViewState extends State<ScrollIntoView> {
  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _reveal();
    }
  }

  @override
  void didUpdateWidget(ScrollIntoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _reveal();
    }
  }

  void _reveal() {
    // Post-frame: the flag flips during a rebuild (the consumer's key
    // handler set state), and moving a scroll position mid-build is not
    // safe. The paired policies scroll the minimal distance — the first
    // only if the child sits past the viewport end, the second only if it
    // sits before the start — the same idiom the framework's focus
    // traversal uses.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
