// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/popover/_popover.scss
//   react/src/components/Popover
//
// Carbon's Popover is a floating surface anchored to a trigger. With no
// Material we build it on OverlayPortal + CompositedTransformTarget/Follower,
// the same anchoring pattern proven in Select (#70).
//
// RTL policy (#221): the primary alignment words are PHYSICAL sides —
// `left*`/`right*` name the screen side the surface floats on in every
// direction, matching upstream's physical `align="left-end"` prop values.
// Only the `Start`/`End` cross-axis suffixes are LOGICAL: they resolve
// against the ambient Directionality (surface anchors and caret inset
// mirror together). Callers who want a direction-relative side pick
// left/right themselves from Directionality.of(context).

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// Where a [CarbonPopover] sits relative to its trigger.
///
/// The primary word (top/bottom/left/right) is the side of the trigger the
/// surface floats on; the `Start`/`End` suffix shifts it along the cross axis
/// so its near edge lines up with the trigger's start or end edge. The plain
/// values centre the surface on the trigger.
enum CarbonPopoverAlignment {
  /// Above the trigger, centred.
  top,

  /// Above the trigger, left/start edges aligned.
  topStart,

  /// Above the trigger, right/end edges aligned.
  topEnd,

  /// Below the trigger, centred.
  bottom,

  /// Below the trigger, left/start edges aligned.
  bottomStart,

  /// Below the trigger, right/end edges aligned.
  bottomEnd,

  /// Left of the trigger, centred.
  left,

  /// Left of the trigger, top edges aligned.
  leftStart,

  /// Left of the trigger, bottom edges aligned.
  leftEnd,

  /// Right of the trigger, centred.
  right,

  /// Right of the trigger, top edges aligned.
  rightStart,

  /// Right of the trigger, bottom edges aligned.
  rightEnd,
}

extension on CarbonPopoverAlignment {
  /// Whether the surface floats above/below (vertical) or beside (horizontal).
  bool get isVertical =>
      this == CarbonPopoverAlignment.top ||
      this == CarbonPopoverAlignment.topStart ||
      this == CarbonPopoverAlignment.topEnd ||
      this == CarbonPopoverAlignment.bottom ||
      this == CarbonPopoverAlignment.bottomStart ||
      this == CarbonPopoverAlignment.bottomEnd;

  /// The opposite primary side, used by [CarbonPopover.autoAlign] when the
  /// preferred side would overflow the viewport.
  CarbonPopoverAlignment get flipped => switch (this) {
    CarbonPopoverAlignment.top => CarbonPopoverAlignment.bottom,
    CarbonPopoverAlignment.topStart => CarbonPopoverAlignment.bottomStart,
    CarbonPopoverAlignment.topEnd => CarbonPopoverAlignment.bottomEnd,
    CarbonPopoverAlignment.bottom => CarbonPopoverAlignment.top,
    CarbonPopoverAlignment.bottomStart => CarbonPopoverAlignment.topStart,
    CarbonPopoverAlignment.bottomEnd => CarbonPopoverAlignment.topEnd,
    CarbonPopoverAlignment.left => CarbonPopoverAlignment.right,
    CarbonPopoverAlignment.leftStart => CarbonPopoverAlignment.rightStart,
    CarbonPopoverAlignment.leftEnd => CarbonPopoverAlignment.rightEnd,
    CarbonPopoverAlignment.right => CarbonPopoverAlignment.left,
    CarbonPopoverAlignment.rightStart => CarbonPopoverAlignment.leftStart,
    CarbonPopoverAlignment.rightEnd => CarbonPopoverAlignment.leftEnd,
  };
}

/// A floating surface anchored to a trigger.
///
/// [CarbonPopover] is the shared positioning primitive several Tier C overlays
/// build on (for example Toggletip). It is fully controlled: pass [open] and
/// respond to [onRequestClose], which fires on an outside tap or the Escape
/// key.
///
/// The surface shows and hides instantly — Carbon defines no popover motion
/// (`_popover.scss` has no transition), so reduced motion needs no special
/// handling.
///
/// ```dart
/// CarbonPopover(
///   open: _open,
///   align: CarbonPopoverAlignment.bottom,
///   onRequestClose: () => setState(() => _open = false),
///   content: const Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Helpful detail'),
///   ),
///   child: CarbonButton(
///     label: 'Details',
///     onPressed: () => setState(() => _open = !_open),
///   ),
/// )
/// ```
class CarbonPopover extends StatefulWidget {
  /// Creates a popover anchored to [child].
  const CarbonPopover({
    required this.open,
    required this.content,
    required this.child,
    this.align = CarbonPopoverAlignment.bottom,
    this.caret = true,
    this.dropShadow = true,
    this.border = false,
    this.highContrast = false,
    this.autoAlign = false,
    this.onRequestClose,
    this.tapRegionGroupId,
    this.surfaceColor,
    this.surfaceBorderColor,
    super.key,
  });

  /// Whether the floating [content] is shown.
  final bool open;

  /// The floating surface contents.
  final Widget content;

  /// The trigger the surface is anchored to.
  final Widget child;

  /// Which side of the trigger the surface floats on.
  final CarbonPopoverAlignment align;

  /// Whether to draw the caret (arrow) pointing at the trigger.
  ///
  /// A caret also introduces a 10px gap between the trigger and the surface.
  final bool caret;

  /// Whether to cast the drop shadow.
  final bool dropShadow;

  /// Whether to outline the surface (and caret) with a 1px subtle border.
  final bool border;

  /// Whether to use the inverse high-contrast palette.
  final bool highContrast;

  /// Whether to flip to the opposite side when the preferred side would
  /// overflow the viewport.
  final bool autoAlign;

  /// Called when the user requests dismissal (outside tap or Escape).
  final VoidCallback? onRequestClose;

  /// An optional `TapRegion` group the surface joins, so taps on a trigger in
  /// the same group are not treated as outside taps.
  final Object? tapRegionGroupId;

  /// Overrides the surface (and caret) fill. Defaults to the contextual `layer`
  /// token, or `backgroundInverse` when [highContrast]. Used for themed
  /// callouts such as the AI Label popover.
  final Color? surfaceColor;

  /// Overrides the surface (and caret) border, forcing the border on. Defaults
  /// to the contextual `borderSubtle` token when [border] is set.
  final Color? surfaceBorderColor;

  @override
  State<CarbonPopover> createState() => _CarbonPopoverState();
}

class _CarbonPopoverState extends State<CarbonPopover> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final GlobalKey _triggerKey = GlobalKey();

  // The resolved alignment after any autoAlign flip.
  late CarbonPopoverAlignment _resolved = widget.align;

  @override
  void initState() {
    super.initState();
    // Safe in initState: the child OverlayPortal is not mounted yet, so the
    // controller only records the intent rather than mutating live state.
    if (widget.open) _overlay.show();
  }

  @override
  void didUpdateWidget(CarbonPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.align != oldWidget.align) _resolved = widget.align;
    if (widget.open != oldWidget.open) {
      if (widget.open) _resolved = widget.align;
      _syncOverlay();
    }
  }

  /// Brings the overlay in line with [CarbonPopover.open].
  ///
  /// `OverlayPortalController.show`/`hide` must not run during the build phase,
  /// so when called mid-build (from `didUpdateWidget`) the work is deferred to
  /// the next post-frame callback.
  void _syncOverlay() {
    void apply() {
      if (!mounted || widget.open == _overlay.isShowing) return;
      if (widget.open) {
        _overlay.show();
        if (widget.autoAlign) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFlip());
        }
      } else {
        _overlay.hide();
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  /// The gap between trigger and surface: present only with a caret.
  double get _gap => widget.caret ? 10 : 0;

  /// Flips [_resolved] to the opposite side when the surface overflows the
  /// viewport on its preferred side.
  void _maybeFlip() {
    if (!mounted || !_overlay.isShowing) return;
    final RenderBox? surface =
        _surfaceKey.currentContext?.findRenderObject() as RenderBox?;
    if (surface == null || !surface.hasSize) return;
    final Offset topLeft = surface.localToGlobal(Offset.zero);
    final Size size = surface.size;
    final Size screen = MediaQuery.sizeOf(context);
    final bool overflows = switch (_resolved) {
      _ when _resolved.isVertical && _isTopSide(_resolved) => topLeft.dy < 0,
      _ when _resolved.isVertical => topLeft.dy + size.height > screen.height,
      _ when _isLeftSide(_resolved) => topLeft.dx < 0,
      _ => topLeft.dx + size.width > screen.width,
    };
    if (overflows) setState(() => _resolved = _resolved.flipped);
  }

  static bool _isTopSide(CarbonPopoverAlignment a) =>
      a == CarbonPopoverAlignment.top ||
      a == CarbonPopoverAlignment.topStart ||
      a == CarbonPopoverAlignment.topEnd;

  static bool _isLeftSide(CarbonPopoverAlignment a) =>
      a == CarbonPopoverAlignment.left ||
      a == CarbonPopoverAlignment.leftStart ||
      a == CarbonPopoverAlignment.leftEnd;

  final GlobalKey _surfaceKey = GlobalKey();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _overlay.isShowing) {
      widget.onRequestClose?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _onKey,
      canRequestFocus: false,
      child: CompositedTransformTarget(
        link: _link,
        child: OverlayPortal(
          controller: _overlay,
          overlayChildBuilder: _buildSurface,
          child: KeyedSubtree(key: _triggerKey, child: widget.child),
        ),
      ),
    );
  }

  Widget _buildSurface(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final TextDirection dir = Directionality.of(context);

    final Color background =
        widget.surfaceColor ??
        (widget.highContrast ? theme.backgroundInverse : layer.layer);
    final Color textColor = widget.highContrast
        ? theme.textInverse
        : theme.textPrimary;
    final bool hasBorder = widget.border || widget.surfaceBorderColor != null;

    final _Anchors anchors = _anchorsFor(_resolved, dir, _gap);

    Widget surface = DefaultTextStyle.merge(
      style: TextStyle(color: textColor),
      child: _Surface(
        align: _resolved,
        caret: widget.caret,
        border: hasBorder,
        dropShadow: widget.dropShadow,
        background: background,
        borderColor: widget.surfaceBorderColor ?? layer.borderSubtle,
        triggerSize: _triggerSize,
        textDirection: dir,
        child: widget.content,
      ),
    );

    surface = TapRegion(
      groupId: widget.tapRegionGroupId,
      onTapOutside: (_) {
        if (_overlay.isShowing) widget.onRequestClose?.call();
      },
      child: KeyedSubtree(key: _surfaceKey, child: surface),
    );

    // Pinning left/top (with width/height null) marks the child positioned, so
    // the theatre hands it loose constraints and the surface shrink-wraps its
    // content; a non-positioned overlay child is forced to the overlay's full
    // size. The FollowerLayer overrides this origin with the leader's position.
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: anchors.target,
        followerAnchor: anchors.follower,
        offset: anchors.offset,
        showWhenUnlinked: false,
        child: surface,
      ),
    );
  }

  Size? get _triggerSize {
    final RenderBox? box =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    return box != null && box.hasSize ? box.size : null;
  }

  static _Anchors _anchorsFor(
    CarbonPopoverAlignment align,
    TextDirection dir,
    double gap,
  ) {
    // Resolve directional "start"/"end" to physical left/right for the
    // horizontal cross axis (top/bottom placements).
    final bool ltr = dir == TextDirection.ltr;
    Alignment startX(Alignment l, Alignment r) => ltr ? l : r;
    Alignment endX(Alignment l, Alignment r) => ltr ? r : l;

    return switch (align) {
      // Bottom: surface below, top edge meets trigger bottom edge.
      CarbonPopoverAlignment.bottom => _Anchors(
        Alignment.bottomCenter,
        Alignment.topCenter,
        Offset(0, gap),
      ),
      CarbonPopoverAlignment.bottomStart => _Anchors(
        startX(Alignment.bottomLeft, Alignment.bottomRight),
        startX(Alignment.topLeft, Alignment.topRight),
        Offset(0, gap),
      ),
      CarbonPopoverAlignment.bottomEnd => _Anchors(
        endX(Alignment.bottomLeft, Alignment.bottomRight),
        endX(Alignment.topLeft, Alignment.topRight),
        Offset(0, gap),
      ),
      // Top: surface above, bottom edge meets trigger top edge.
      CarbonPopoverAlignment.top => _Anchors(
        Alignment.topCenter,
        Alignment.bottomCenter,
        Offset(0, -gap),
      ),
      CarbonPopoverAlignment.topStart => _Anchors(
        startX(Alignment.topLeft, Alignment.topRight),
        startX(Alignment.bottomLeft, Alignment.bottomRight),
        Offset(0, -gap),
      ),
      CarbonPopoverAlignment.topEnd => _Anchors(
        endX(Alignment.topLeft, Alignment.topRight),
        endX(Alignment.bottomLeft, Alignment.bottomRight),
        Offset(0, -gap),
      ),
      // Right: surface to the right, left edge meets trigger right edge.
      CarbonPopoverAlignment.right => _Anchors(
        Alignment.centerRight,
        Alignment.centerLeft,
        Offset(gap, 0),
      ),
      CarbonPopoverAlignment.rightStart => _Anchors(
        Alignment.topRight,
        Alignment.topLeft,
        Offset(gap, 0),
      ),
      CarbonPopoverAlignment.rightEnd => _Anchors(
        Alignment.bottomRight,
        Alignment.bottomLeft,
        Offset(gap, 0),
      ),
      // Left: surface to the left, right edge meets trigger left edge.
      CarbonPopoverAlignment.left => _Anchors(
        Alignment.centerLeft,
        Alignment.centerRight,
        Offset(-gap, 0),
      ),
      CarbonPopoverAlignment.leftStart => _Anchors(
        Alignment.topLeft,
        Alignment.topRight,
        Offset(-gap, 0),
      ),
      CarbonPopoverAlignment.leftEnd => _Anchors(
        Alignment.bottomLeft,
        Alignment.bottomRight,
        Offset(-gap, 0),
      ),
    };
  }
}

/// The resolved anchor pair and offset handed to [CompositedTransformFollower].
class _Anchors {
  const _Anchors(this.target, this.follower, this.offset);
  final Alignment target;
  final Alignment follower;
  final Offset offset;
}

/// The popover content box with its optional caret and chrome.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.align,
    required this.caret,
    required this.border,
    required this.dropShadow,
    required this.background,
    required this.borderColor,
    required this.triggerSize,
    required this.textDirection,
    required this.child,
  });

  final CarbonPopoverAlignment align;
  final bool caret;
  final bool border;
  final bool dropShadow;
  final Color background;
  final Color borderColor;
  final Size? triggerSize;
  final TextDirection textDirection;
  final Widget child;

  // Caret dimensions (_popover.scss: $popover-caret-width 12px / height 6px).
  static const double _caretMain = 6;
  static const double _caretCross = 12;

  @override
  Widget build(BuildContext context) {
    final Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        // _popover.scss: $popover-border-radius 2px.
        borderRadius: BorderRadius.circular(2),
        border: border ? Border.all(color: borderColor) : null,
        boxShadow: dropShadow
            // _popover.scss: drop-shadow(0 $spacing-01 $spacing-01
            // rgba(0, 0, 0, 0.2)); spacing-01 = 2px.
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                  blurRadius: 2,
                ),
              ]
            : null,
      ),
      // _popover.scss: max-inline-size 23rem (368px).
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 368),
        child: child,
      ),
    );

    if (!caret) return box;

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[box, _caret(context)],
    );
  }

  Widget _caret(BuildContext context) {
    final _CaretDirection direction = _caretDirection;
    final bool vertical = align.isVertical;
    final Widget paint = CustomPaint(
      size: vertical
          ? const Size(_caretCross, _caretMain)
          : const Size(_caretMain, _caretCross),
      painter: _CaretPainter(
        direction: direction,
        color: background,
        borderColor: border ? borderColor : null,
      ),
    );

    // The cross-axis inset that lines the caret up with the trigger centre on
    // the Start/End variants; null centres it (also the fallback for one frame
    // until the trigger size is known).
    final double? inset = _edgeInset;

    // Main-axis placement: pull the caret just outside the box on its side.
    final double? top = switch (direction) {
      _CaretDirection.up => -_caretMain,
      _CaretDirection.down => null,
      _ when _isStart => inset,
      _ => null,
    };
    final double? bottom = switch (direction) {
      _CaretDirection.down => -_caretMain,
      _CaretDirection.up => null,
      _ when _isEnd => inset,
      _ => null,
    };
    // The horizontal cross axis is logical: Start insets from the left in
    // LTR and from the right in RTL, mirroring the surface anchors.
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final double? left = switch (direction) {
      _CaretDirection.left => -_caretMain,
      _CaretDirection.right => null,
      _ when (rtl ? _isEnd : _isStart) => inset,
      _ => null,
    };
    final double? right = switch (direction) {
      _CaretDirection.right => -_caretMain,
      _CaretDirection.left => null,
      _ when (rtl ? _isStart : _isEnd) => inset,
      _ => null,
    };

    // Centre across the cross axis when no inset applies by stretching the
    // Positioned along that axis and aligning the fixed-size caret.
    if (inset == null) {
      return vertical
          ? Positioned(
              top: top,
              bottom: bottom,
              left: 0,
              right: 0,
              child: Align(child: paint),
            )
          : Positioned(
              left: left,
              right: right,
              top: 0,
              bottom: 0,
              child: Align(child: paint),
            );
    }
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: paint,
    );
  }

  bool get _isStart =>
      align == CarbonPopoverAlignment.bottomStart ||
      align == CarbonPopoverAlignment.topStart ||
      align == CarbonPopoverAlignment.leftStart ||
      align == CarbonPopoverAlignment.rightStart;

  bool get _isEnd =>
      align == CarbonPopoverAlignment.bottomEnd ||
      align == CarbonPopoverAlignment.topEnd ||
      align == CarbonPopoverAlignment.leftEnd ||
      align == CarbonPopoverAlignment.rightEnd;

  /// The distance from the aligned edge to the caret so it points at the
  /// trigger centre, or null when centred / not yet measurable.
  double? get _edgeInset {
    if (!_isStart && !_isEnd) return null;
    final Size? t = triggerSize;
    if (t == null) return null;
    final double extent = align.isVertical ? t.width : t.height;
    return (extent / 2) - (_caretCross / 2);
  }

  _CaretDirection get _caretDirection => switch (align) {
    CarbonPopoverAlignment.bottom ||
    CarbonPopoverAlignment.bottomStart ||
    CarbonPopoverAlignment.bottomEnd => _CaretDirection.up,
    CarbonPopoverAlignment.top ||
    CarbonPopoverAlignment.topStart ||
    CarbonPopoverAlignment.topEnd => _CaretDirection.down,
    CarbonPopoverAlignment.right ||
    CarbonPopoverAlignment.rightStart ||
    CarbonPopoverAlignment.rightEnd => _CaretDirection.left,
    CarbonPopoverAlignment.left ||
    CarbonPopoverAlignment.leftStart ||
    CarbonPopoverAlignment.leftEnd => _CaretDirection.right,
  };
}

/// The direction a caret's apex points.
enum _CaretDirection { up, down, left, right }

/// Paints a filled triangle pointing in [direction], optionally backed by a
/// 1px border triangle.
class _CaretPainter extends CustomPainter {
  const _CaretPainter({
    required this.direction,
    required this.color,
    this.borderColor,
  });

  final _CaretDirection direction;
  final Color color;
  final Color? borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _trianglePath(size);
    if (borderColor != null) {
      // Inflate the apex by 1px to read as a hairline border behind the fill.
      canvas.save();
      final Offset c = Offset(size.width / 2, size.height / 2);
      canvas.translate(c.dx, c.dy);
      canvas.scale(
        (size.width + 2) / size.width,
        (size.height + 2) / size.height,
      );
      canvas.translate(-c.dx, -c.dy);
      canvas.drawPath(path, Paint()..color = borderColor!);
      canvas.restore();
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  Path _trianglePath(Size size) {
    final double w = size.width;
    final double h = size.height;
    return switch (direction) {
      _CaretDirection.up =>
        Path()
          ..moveTo(0, h)
          ..lineTo(w, h)
          ..lineTo(w / 2, 0)
          ..close(),
      _CaretDirection.down =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w / 2, h)
          ..close(),
      _CaretDirection.left =>
        Path()
          ..moveTo(w, 0)
          ..lineTo(w, h)
          ..lineTo(0, h / 2)
          ..close(),
      _CaretDirection.right =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(0, h)
          ..lineTo(w, h / 2)
          ..close(),
    };
  }

  @override
  bool shouldRepaint(_CaretPainter old) =>
      old.direction != direction ||
      old.color != color ||
      old.borderColor != borderColor;
}
