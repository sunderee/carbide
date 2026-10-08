// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The preferred side of an anchored surface.
enum CarbonOverlaySide {
  /// Above the trigger.
  top,

  /// Below the trigger.
  bottom,

  /// On the physical left side.
  left,

  /// On the physical right side.
  right,

  /// On the logical start side: left in LTR and right in RTL.
  start,

  /// On the logical end side: right in LTR and left in RTL.
  end,
}

/// Alignment along the surface's cross axis.
enum CarbonOverlayAlignment {
  /// Aligns the near edges (logical horizontally, top vertically).
  start,

  /// Aligns the centres.
  center,

  /// Aligns the far edges (logical horizontally, bottom vertically).
  end,
}

/// A resolved placement in viewport coordinates.
@immutable
class CarbonOverlayGeometry {
  /// Creates a resolved placement.
  const CarbonOverlayGeometry(this.side, this.bounds);

  /// The physical side after direction resolution and collision handling.
  final CarbonOverlaySide side;

  /// The surface's bounds.
  final Rect bounds;
}

/// Whether this subtree is a bounded, anchored overlay surface.
bool isCarbonOverlaySurface(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_OverlaySurface>() != null;

class _OverlaySurface extends InheritedWidget {
  const _OverlaySurface({required super.child});

  @override
  bool updateShouldNotify(_OverlaySurface oldWidget) => false;
}

/// Resolves logical alignment, chooses the roomier side on collision, then
/// clamps the surface inside the viewport. Pinning preserves the requested
/// main-axis side while still keeping its cross axis inside the viewport.
CarbonOverlayGeometry carbonOverlayGeometry({
  required Rect target,
  required Size surface,
  required Rect viewport,
  required TextDirection direction,
  CarbonOverlaySide side = CarbonOverlaySide.bottom,
  CarbonOverlayAlignment alignment = CarbonOverlayAlignment.start,
  double gap = 0,
  bool automatic = true,
  bool clamp = true,
}) {
  final bool rtl = direction == TextDirection.rtl;
  side = switch (side) {
    CarbonOverlaySide.start =>
      rtl ? CarbonOverlaySide.right : CarbonOverlaySide.left,
    CarbonOverlaySide.end =>
      rtl ? CarbonOverlaySide.left : CarbonOverlaySide.right,
    _ => side,
  };
  final bool vertical =
      side == CarbonOverlaySide.top || side == CarbonOverlaySide.bottom;
  double room(CarbonOverlaySide value) => switch (value) {
    CarbonOverlaySide.top => target.top - viewport.top - gap,
    CarbonOverlaySide.bottom => viewport.bottom - target.bottom - gap,
    CarbonOverlaySide.left => target.left - viewport.left - gap,
    _ => viewport.right - target.right - gap,
  };
  final CarbonOverlaySide opposite = switch (side) {
    CarbonOverlaySide.top => CarbonOverlaySide.bottom,
    CarbonOverlaySide.bottom => CarbonOverlaySide.top,
    CarbonOverlaySide.left => CarbonOverlaySide.right,
    _ => CarbonOverlaySide.left,
  };
  if (automatic &&
      room(side) < (vertical ? surface.height : surface.width) &&
      room(opposite) > room(side)) {
    side = opposite;
  }
  final CarbonOverlayAlignment physicalAlignment = vertical && rtl
      ? switch (alignment) {
          CarbonOverlayAlignment.start => CarbonOverlayAlignment.end,
          CarbonOverlayAlignment.end => CarbonOverlayAlignment.start,
          _ => alignment,
        }
      : alignment;
  double cross(double start, double end, double extent) =>
      switch (physicalAlignment) {
        CarbonOverlayAlignment.start => start,
        CarbonOverlayAlignment.center => (start + end - extent) / 2,
        CarbonOverlayAlignment.end => end - extent,
      };
  double x = vertical
      ? cross(target.left, target.right, surface.width)
      : side == CarbonOverlaySide.left
      ? target.left - gap - surface.width
      : target.right + gap;
  double y = vertical
      ? side == CarbonOverlaySide.top
            ? target.top - gap - surface.height
            : target.bottom + gap
      : cross(target.top, target.bottom, surface.height);
  double bounded(double value, double start, double end, double extent) =>
      value.clamp(start, end - extent < start ? start : end - extent);
  if (clamp) {
    if (vertical || automatic) {
      x = bounded(x, viewport.left, viewport.right, surface.width);
    }
    if (!vertical || automatic) {
      y = bounded(y, viewport.top, viewport.bottom, surface.height);
    }
  }
  return CarbonOverlayGeometry(side, Offset(x, y) & surface);
}

/// A shrink-wrapped surface that follows its trigger during composition.
///
/// Placement is recomputed once per composed frame, even when scrolling only
/// changes an ancestor layer. It installs no ancestor scroll listeners and
/// schedules no idle frames. The ordinary follower transform also supplies
/// pointer and semantics coordinates.
class CarbonAnchoredOverlay extends StatelessWidget {
  /// Creates an anchored surface.
  const CarbonAnchoredOverlay({
    required this.link,
    required this.child,
    super.key,
    this.side = CarbonOverlaySide.bottom,
    this.alignment = CarbonOverlayAlignment.start,
    this.gap = 0,
    this.automatic = true,
    this.clamp = true,
    this.onPlacement,
  });

  /// The trigger's composited link.
  final LayerLink link;

  /// The shrink-wrapped popup.
  final Widget child;

  /// The preferred side, with logical start/end available for submenus.
  final CarbonOverlaySide side;

  /// Logical cross-axis alignment for vertical surfaces.
  final CarbonOverlayAlignment alignment;

  /// The distance between the trigger and surface.
  final double gap;

  /// Whether collision handling may change the preferred side.
  final bool automatic;

  /// Whether to keep the cross axis inside the viewport.
  final bool clamp;

  /// Receives the physical side and a local caret target during composition.
  /// Callers that rebuild must defer the mutation until after the frame.
  final void Function(CarbonOverlaySide side, Offset caretTarget)? onPlacement;

  @override
  Widget build(BuildContext context) {
    final OverlayState overlay = Overlay.of(context);
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topLeft,
        child: _Follower(
          link: link,
          side: side,
          alignment: alignment,
          direction: Directionality.of(context),
          gap: gap,
          automatic: automatic,
          clamp: clamp,
          viewport: () {
            final RenderBox box =
                overlay.context.findRenderObject()! as RenderBox;
            return box.localToGlobal(Offset.zero) & box.size;
          },
          onPlacement: onPlacement,
          child: _OverlaySurface(child: child),
        ),
      ),
    );
  }
}

class _Follower extends SingleChildRenderObjectWidget {
  const _Follower({
    required this.link,
    required this.side,
    required this.alignment,
    required this.direction,
    required this.gap,
    required this.automatic,
    required this.clamp,
    required this.viewport,
    required this.onPlacement,
    required super.child,
  });

  final LayerLink link;
  final CarbonOverlaySide side;
  final CarbonOverlayAlignment alignment;
  final TextDirection direction;
  final double gap;
  final bool automatic;
  final bool clamp;
  final Rect Function() viewport;
  final void Function(CarbonOverlaySide, Offset)? onPlacement;

  void _configure(_RenderFollower render) {
    render
      ..link = link
      ..settings = this;
    render.markNeedsPaint();
  }

  @override
  _RenderFollower createRenderObject(BuildContext context) =>
      _RenderFollower(link: link, settings: this);

  @override
  void updateRenderObject(BuildContext context, _RenderFollower renderObject) =>
      _configure(renderObject);
}

class _RenderFollower extends RenderFollowerLayer {
  _RenderFollower({required super.link, required this.settings})
    : super(showWhenUnlinked: false);

  _Follower settings;
  Offset _layoutScale = const Offset(1, 1);
  bool _scaleUpdatePending = false;
  Offset? _pendingScale;

  @override
  void performLayout() {
    final BoxConstraints scaled = constraints.copyWith(
      maxWidth: _layoutScale.dx == 0
          ? constraints.maxWidth
          : constraints.maxWidth / _layoutScale.dx,
      maxHeight: _layoutScale.dy == 0
          ? constraints.maxHeight
          : constraints.maxHeight / _layoutScale.dy,
    );
    child?.layout(scaled, parentUsesSize: true);
    size = constraints.constrain(child?.size ?? Size.zero);
  }

  bool _matchesScale(Offset scale) =>
      (scale.dx - _layoutScale.dx).abs() < 0.000001 &&
      (scale.dy - _layoutScale.dy).abs() < 0.000001;

  void _checkScale(Offset scale) {
    if (!_scaleUpdatePending && _matchesScale(scale)) return;
    _pendingScale = scale;
    if (_scaleUpdatePending) return;
    _scaleUpdatePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaleUpdatePending = false;
      final Offset next = _pendingScale!;
      _pendingScale = null;
      if (!attached || _matchesScale(next)) return;
      _layoutScale = next;
      markNeedsLayout();
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    layer ??= _PlacementLayer(link: link);
    (layer! as _PlacementLayer)
      ..settings = settings
      ..checkScale = _checkScale
      ..surface = size;
    super.paint(context, offset);
  }
}

class _PlacementLayer extends FollowerLayer {
  _PlacementLayer({required super.link});

  late _Follower settings;
  Size surface = Size.zero;
  ValueChanged<Offset>? checkScale;

  @override
  void addToScene(ui.SceneBuilder builder) {
    final LeaderLayer? leader = link.leader;
    final Size? targetSize = link.leaderSize;
    if (leader != null && targetSize != null) {
      // Exclude the root's device-pixel transform: placement uses logical
      // viewport coordinates. Include every remaining ancestor transform and
      // the leader's own offset, including retained scrolling layers.
      final List<ContainerLayer> chain = <ContainerLayer>[leader];
      while (chain.last.parent != null) {
        chain.add(chain.last.parent!);
      }
      final Matrix4 transform = Matrix4.identity();
      for (int i = chain.length - 2; i >= 0; i--) {
        chain[i].applyTransform(i == 0 ? null : chain[i - 1], transform);
      }
      final Offset origin = MatrixUtils.transformPoint(transform, Offset.zero);
      checkScale?.call(
        Offset(
          (MatrixUtils.transformPoint(transform, const Offset(1, 0)) - origin)
              .distance,
          (MatrixUtils.transformPoint(transform, const Offset(0, 1)) - origin)
              .distance,
        ),
      );
      final Rect target = MatrixUtils.transformRect(
        transform,
        Offset.zero & targetSize,
      );
      final Size transformedSurface = MatrixUtils.transformRect(
        transform,
        Offset.zero & surface,
      ).size;
      final bool vertical =
          settings.side == CarbonOverlaySide.top ||
          settings.side == CarbonOverlaySide.bottom;
      final double extent = vertical ? surface.height : surface.width;
      final double transformedExtent = vertical
          ? transformedSurface.height
          : transformedSurface.width;
      final CarbonOverlayGeometry geometry = carbonOverlayGeometry(
        target: target,
        surface: transformedSurface,
        viewport: settings.viewport(),
        direction: settings.direction,
        side: settings.side,
        alignment: settings.alignment,
        gap: settings.gap * (extent == 0 ? 1 : transformedExtent / extent),
        automatic: settings.automatic,
        clamp: settings.clamp,
      );
      final Matrix4 inverse = Matrix4.copy(transform);
      if (inverse.invert() != 0) {
        linkedOffset = MatrixUtils.transformPoint(
          inverse,
          geometry.bounds.topLeft,
        );
        final Offset caretTarget =
            MatrixUtils.transformPoint(inverse, target.center) - linkedOffset!;
        settings.onPlacement?.call(geometry.side, caretTarget);
      }
    }
    super.addToScene(builder);
  }
}
