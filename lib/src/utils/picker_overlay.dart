// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show SemanticsHitTestBehavior;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Controls a picker's options independently of its web semantics anchor.
class CarbonPickerOverlayController extends ChangeNotifier {
  bool _isShowing = false;

  /// Whether the options are visible.
  bool get isShowing => _isShowing;

  /// Shows the options, bringing the portal to the front.
  void show() {
    _isShowing = true;
    notifyListeners();
  }

  /// Hides the options.
  void hide() {
    if (!_isShowing) return;
    _isShowing = false;
    notifyListeners();
  }
}

/// Keeps a web picker's native editor stationary when its options appear.
///
/// Flutter 3.47.6 creates an implicit semantics ancestor when the first portal
/// child appears. Moving that ancestor blurs descendant native editors. The
/// web portal therefore keeps an empty, transparent semantics anchor attached
/// from the first frame. Closing removes the options without removing that
/// anchor. The empty anchor has no label, action or focus state, and passes
/// pointer input through to the content below it.
class CarbonPickerOverlay extends StatefulWidget {
  /// Creates the trigger and its lifetime-owned popup anchor.
  const CarbonPickerOverlay({
    required this.controller,
    required this.overlayChildBuilder,
    required this.child,
    super.key,
  });

  /// The caller-owned popup visibility controller.
  final CarbonPickerOverlayController controller;

  /// Builds the visible options in the surrounding overlay.
  final WidgetBuilder overlayChildBuilder;

  /// The picker trigger.
  final Widget child;

  @override
  State<CarbonPickerOverlay> createState() => _CarbonPickerOverlayState();
}

class _CarbonPickerOverlayState extends State<CarbonPickerOverlay> {
  OverlayPortalController _portal = OverlayPortalController();
  bool _anchored = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_visibilityChanged);
    if (widget.controller.isShowing) _portal.show();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool anchored = kIsWeb && Overlay.maybeOf(context) != null;
    if (anchored == _anchored) return;
    _anchored = anchored;
    // Closed pickers can also be rendered without an Overlay (for example in
    // a static specimen). Prime only where a popup can actually be hosted.
    // A fresh controller is not attached yet, so showing it is safe during
    // dependency changes, including entering or leaving an overlay.
    _portal = OverlayPortalController();
    if (_anchored || widget.controller.isShowing) _portal.show();
  }

  @override
  void didUpdateWidget(CarbonPickerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_visibilityChanged);
      widget.controller.addListener(_visibilityChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _visibilityChanged();
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_visibilityChanged);
    super.dispose();
  }

  void _visibilityChanged() {
    if (widget.controller.isShowing) {
      _portal.show();
    } else if (!_anchored) {
      _portal.hide();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: OverlayPortal(
      key: ObjectKey(_portal),
      controller: _portal,
      overlayChildBuilder: (BuildContext context) {
        if (!_anchored) return widget.overlayChildBuilder(context);
        return Positioned.fill(
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            hitTestBehavior: SemanticsHitTestBehavior.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (widget.controller.isShowing)
                  widget.overlayChildBuilder(context),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    ),
  );
}
