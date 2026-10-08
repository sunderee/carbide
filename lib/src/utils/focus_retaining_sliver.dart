// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A viewport that keeps semantics for its explicitly retained focused rows.
/// Removing a focused web editor's semantics removes its native input and can
/// reset its editing connection even when its Flutter state is kept alive.
/// Paint clipping remains intact; offscreen retained nodes are marked hidden.
class CarbonFocusRetainingViewport extends Viewport {
  /// Creates a viewport with no speculative widget cache.
  CarbonFocusRetainingViewport({
    required super.offset,
    required super.slivers,
    super.key,
  }) : super(scrollCacheExtent: const ScrollCacheExtent.pixels(0));
  @override
  RenderViewport createRenderObject(BuildContext context) => _RetainingViewport(
    offset: offset,
    axisDirection: axisDirection,
    crossAxisDirection: Viewport.getDefaultCrossAxisDirection(
      context,
      axisDirection,
    ),
  );
}

class _RetainingViewport extends RenderViewport {
  _RetainingViewport({
    required super.offset,
    required super.axisDirection,
    required super.crossAxisDirection,
  }) : super(scrollCacheExtent: const ScrollCacheExtent.pixels(0));
  @override
  Rect? describeSemanticsClip(RenderSliver? child) {
    if (child is! _RetainedSemantics) return super.describeSemanticsClip(child);
    // A null clip falls back to the paint clip in Flutter. Explicitly extend
    // the semantics region to the retained rows; paint still clips them.
    Rect clip = super.describeSemanticsClip(child) ?? semanticBounds;
    child.visitChildren((node) {
      if (node is RenderBox) {
        clip = clip.expandToInclude(
          MatrixUtils.transformRect(
            node.getTransformTo(this),
            node.semanticBounds,
          ),
        );
      }
    });
    return clip;
  }
}

/// A variable-height sliver preserving its kept-alive rows' semantics.
class CarbonFocusRetainingSliverList extends SliverList {
  /// Creates a list keyed by the caller's stable-ID delegate.
  const CarbonFocusRetainingSliverList({required super.delegate, super.key});
  @override
  RenderSliverList createRenderObject(BuildContext context) =>
      _RetainingList(childManager: context as SliverMultiBoxAdaptorElement);
}

class _RetainingList extends RenderSliverList with _RetainedSemantics {
  _RetainingList({required super.childManager});
}

/// A fixed-height sliver preserving its kept-alive rows' semantics.
class CarbonFocusRetainingFixedSliverList extends SliverFixedExtentList {
  /// Creates a list with an actual scaled row extent.
  const CarbonFocusRetainingFixedSliverList({
    required super.delegate,
    required super.itemExtent,
    super.key,
  });
  @override
  RenderSliverFixedExtentList createRenderObject(BuildContext context) =>
      _RetainingFixedList(
        childManager: context as SliverMultiBoxAdaptorElement,
        itemExtent: itemExtent,
      );
}

class _RetainingFixedList extends RenderSliverFixedExtentList
    with _RetainedSemantics {
  _RetainingFixedList({required super.childManager, required super.itemExtent});
}

mixin _RetainedSemantics on RenderSliverMultiBoxAdaptor {
  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) =>
      visitChildren(visitor);
  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final data = child.parentData! as SliverMultiBoxAdaptorParentData;
    if (data.keptAlive && data.layoutOffset != null) {
      // The superclass zeros transforms for unpainted cached children.
      // Their known layout offsets still locate a valid semantics subtree.
      applyPaintTransformForBoxChild(child, transform);
    } else if (data.keptAlive) {
      // Reordering invalidates a cached row's layout offset. Keep its existing
      // semantics owner until the next visible layout establishes its position.
      transform.translateByDouble(
        0,
        -constraints.scrollOffset -
            constraints.viewportMainAxisExtent -
            child.size.height -
            1,
        0,
        1,
      );
    } else {
      super.applyPaintTransform(child, transform);
    }
  }
}
