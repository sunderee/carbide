// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../foundations/typography.dart';

/// A bounded option viewport whose keyboard target need not already be mounted.
///
/// Rows have one line and a known minimum height. Measuring that line with the
/// actual scaler yields the fixed extent used by both the sliver and reveal
/// calculation, including fluid rows and enlarged text. Data remains separate
/// from this widget builder so typeahead can search the entire source.
class CarbonLazyOptionMenu extends StatefulWidget {
  /// Creates a lazy viewport with its own scroll position.
  const CarbonLazyOptionMenu({
    required this.itemCount,
    required this.itemBuilder,
    required this.activeIndex,
    required this.minimumRowHeight,
    required this.maximumHeight,
    this.verticalPadding = 4,
    super.key,
  });

  /// The number of logical options in the current data/filter source.
  final int itemCount;

  /// Builds only a mounted row in the viewport window.
  final IndexedWidgetBuilder itemBuilder;

  /// The logical highlight to reveal, or a negative index for no highlight.
  final int activeIndex;

  /// The ordinary Carbon row height, before accounting for enlarged text.
  final double minimumRowHeight;

  /// The ordinary popup fold, bounded further by the hosting overlay.
  final double maximumHeight;

  /// The row's total vertical inset around its text line.
  final double verticalPadding;

  @override
  State<CarbonLazyOptionMenu> createState() => _CarbonLazyOptionMenuState();
}

class _CarbonLazyOptionMenuState extends State<CarbonLazyOptionMenu> {
  final ScrollController _scroll = ScrollController();
  double _extent = 0;
  bool _revealPending = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _reveal() {
    if (_revealPending) return;
    _revealPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealPending = false;
      if (!mounted || !_scroll.hasClients) return;
      final ScrollPosition position = _scroll.position;
      if (widget.activeIndex < 0 || widget.activeIndex >= widget.itemCount) {
        if (position.pixels > position.maxScrollExtent) {
          _scroll.jumpTo(position.maxScrollExtent);
        }
        return;
      }
      final double start = widget.activeIndex * _extent;
      final double end = start + _extent;
      final double offset = start < position.pixels
          ? start
          : end > position.pixels + position.viewportDimension
          ? end - position.viewportDimension
          : position.pixels;
      final double bounded = offset.clamp(0, position.maxScrollExtent);
      if (bounded != position.pixels) _scroll.jumpTo(bounded);
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextPainter line = TextPainter(
      text: const TextSpan(text: 'Hg', style: CarbonTypeStyles.bodyCompact01),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    _extent = math.max(
      widget.minimumRowHeight,
      line.height + widget.verticalPadding,
    );
    line.dispose();
    _reveal();
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maximumHeight),
      child: ListView.custom(
        controller: _scroll,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        scrollCacheExtent: const ScrollCacheExtent.pixels(0),
        itemExtent: _extent,
        // Logical option semantics are owned by the existing per-row scope;
        // offscreen options are neither built nor claimed as mounted nodes.
        childrenDelegate: SliverChildBuilderDelegate(
          widget.itemBuilder,
          childCount: widget.itemCount,
          addSemanticIndexes: false,
        ),
      ),
    );
  }
}
