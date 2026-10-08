// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/tooltip/_tooltip.scss
//   react/src/components/Tooltip/Tooltip.tsx
//
// Tooltip is a small non-interactive label shown on hover and focus of its
// trigger, built on the Popover primitive (#90) in its high-contrast
// (inverse) palette.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../popover/carbon_popover.dart';

/// A small label shown on hover and keyboard focus of [child].
///
/// The bubble uses the inverse palette with a caret and is dismissed on
/// Escape. [enterDelayMs] (default 100) and [leaveDelayMs] (default 300) debounce
/// pointer hover so it does not flicker.
///
/// The bubble shows and hides instantly — Carbon defines no tooltip motion
/// (the delays above are hover debounce, not animation), so reduced motion
/// needs no special handling.
///
/// ```dart
/// CarbonTooltip(
///   label: 'Duplicate',
///   child: CarbonButton.iconOnly(
///     icon: CarbonIcons.copy,
///     iconDescription: 'Duplicate',
///     onPressed: _duplicate,
///   ),
/// )
/// ```
class CarbonTooltip extends StatefulWidget {
  /// Creates a tooltip.
  const CarbonTooltip({
    required this.label,
    required this.child,
    super.key,
    this.align = CarbonPopoverAlignment.top,
    this.enterDelayMs = 100,
    this.leaveDelayMs = 300,
    this.defaultOpen = false,
    this.autoAlign = false,
    this.excludeFromSemantics = false,
    this.scrollable = false,
    this.onOpenChanged,
  });

  /// The tooltip text.
  final String label;

  /// The trigger.
  final Widget child;

  /// Where the bubble sits relative to the trigger.
  final CarbonPopoverAlignment align;

  /// The hover-in debounce before showing, in milliseconds.
  final int enterDelayMs;

  /// The hover-out debounce before hiding, in milliseconds.
  final int leaveDelayMs;

  /// Whether the tooltip starts visible.
  final bool defaultOpen;

  /// Whether the tooltip flips and clamps within the available viewport.
  final bool autoAlign;

  /// Whether to omit the tooltip annotation and bubble from accessibility.
  ///
  /// Use when the trigger already exposes the complete same accessible name,
  /// such as an ellipsized page heading. Pointer and keyboard display remain.
  final bool excludeFromSemantics;

  /// Whether long tooltip text scrolls within the available popup height.
  ///
  /// While open and overflowing, Arrow/Page Up/Down and Home/End scroll the
  /// text without introducing another focus stop. Defaults to plain content.
  final bool scrollable;

  /// Called when visibility changes after the initial [defaultOpen] state.
  ///
  /// A parent can coordinate focus across popup insertion/removal. Hover or
  /// focus events that leave visibility unchanged do not repeat the callback.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<CarbonTooltip> createState() => _CarbonTooltipState();
}

class _CarbonTooltipState extends State<CarbonTooltip> {
  late bool _open = widget.defaultOpen;
  Timer? _timer;
  ScrollController? _scroll;
  bool _triggerHovered = false;
  bool _bubbleHovered = false;
  bool _focused = false;
  bool _observesEscape = false;
  bool _dismissed = false;
  FocusNode? _dismissedOrigin;
  Set<FocusNode> _dismissedAncestors = <FocusNode>{};

  void _dismiss() {
    if (!_dismissed) {
      _dismissed = true;
      _dismissedOrigin = FocusManager.instance.primaryFocus;
      _dismissedAncestors =
          _dismissedOrigin?.ancestors.toSet() ?? <FocusNode>{};
      FocusManager.instance.addListener(_focusMovedAfterDismissal);
    }
    _hide();
  }

  void _clearDismissal() {
    if (!_dismissed) return;
    _dismissed = false;
    FocusManager.instance.removeListener(_focusMovedAfterDismissal);
    _dismissedOrigin = null;
    _dismissedAncestors.clear();
  }

  void _focusMovedAfterDismissal() {
    final FocusNode? current = FocusManager.instance.primaryFocus;
    // Native popup removal can park focus at an ancestor before restoring the
    // same trigger. That repair must not reopen a deliberately dismissed hint.
    if (current != null &&
        current != _dismissedOrigin &&
        !_dismissedAncestors.contains(current)) {
      _clearDismissal();
      if (_focused) _show();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncEscapeObserver();
  }

  // A pointer-only tooltip must dismiss on Escape even while another editor
  // owns focus. Observe only while open; never consume that control's key.
  KeyEventResult _outsideEscape(KeyEvent event) {
    if (mounted &&
        _open &&
        !_focused &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss();
    }
    return KeyEventResult.ignored;
  }

  void _syncEscapeObserver() {
    if (_open == _observesEscape) return;
    _observesEscape = _open;
    if (_open) {
      FocusManager.instance.addEarlyKeyEventHandler(_outsideEscape);
    } else {
      FocusManager.instance.removeEarlyKeyEventHandler(_outsideEscape);
    }
  }

  @override
  void dispose() {
    _clearDismissal();
    if (_observesEscape) {
      FocusManager.instance.removeEarlyKeyEventHandler(_outsideEscape);
    }
    _timer?.cancel();
    _scroll?.dispose();
    super.dispose();
  }

  void _show({int delayMs = 0}) => _schedule(true, delayMs);

  void _hide({int delayMs = 0}) => _schedule(false, delayMs);

  void _schedule(bool open, int delayMs) {
    if (!mounted) return;
    if (open && _dismissed) return;
    _timer?.cancel();
    if (delayMs == 0) {
      if (!open) _bubbleHovered = false;
      if (mounted && _open != open) {
        setState(() => _open = open);
        widget.onOpenChanged?.call(open);
      }
      _syncEscapeObserver();
      return;
    }
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!open) _bubbleHovered = false;
      if (mounted && _open != open) {
        setState(() => _open = open);
        widget.onOpenChanged?.call(open);
      }
      if (mounted) _syncEscapeObserver();
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _open) {
      _dismiss();
      return KeyEventResult.handled;
    }
    if (_open &&
        widget.scrollable &&
        (event is KeyDownEvent || event is KeyRepeatEvent) &&
        (_scroll?.hasClients ?? false)) {
      final ScrollPosition position = _scroll!.position;
      if (position.maxScrollExtent <= 0) return KeyEventResult.ignored;
      final double? target = switch (event.logicalKey) {
        LogicalKeyboardKey.arrowDown => position.pixels + 40,
        LogicalKeyboardKey.arrowUp => position.pixels - 40,
        LogicalKeyboardKey.pageDown =>
          position.pixels + position.viewportDimension,
        LogicalKeyboardKey.pageUp =>
          position.pixels - position.viewportDimension,
        LogicalKeyboardKey.home => 0,
        LogicalKeyboardKey.end => position.maxScrollExtent,
        _ => null,
      };
      if (target != null) {
        _scroll!.jumpTo(target.clamp(0, position.maxScrollExtent));
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    Widget bubble = MouseRegion(
      onEnter: (_) {
        _bubbleHovered = true;
        _show();
      },
      onExit: (_) {
        _bubbleHovered = false;
        if (!_focused && !_triggerHovered) {
          _hide(delayMs: widget.leaveDelayMs);
        }
      },
      child: _TooltipContent(
        label: widget.label,
        scrollController: widget.scrollable
            ? (_scroll ??= ScrollController())
            : null,
      ),
    );
    if (widget.excludeFromSemantics) {
      bubble = ExcludeSemantics(child: bubble);
    }
    final Widget trigger = MouseRegion(
      onEnter: (_) {
        _triggerHovered = true;
        _clearDismissal();
        _show(delayMs: _focused ? 0 : widget.enterDelayMs);
      },
      onExit: (_) {
        _triggerHovered = false;
        if (!_focused && !_bubbleHovered) {
          _hide(delayMs: widget.leaveDelayMs);
        }
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        onFocusChange: (bool focused) {
          _focused = focused;
          if (focused) {
            _show();
          } else if (!_triggerHovered && !_bubbleHovered) {
            _hide();
          }
        },
        child: CarbonPopover(
          open: _open,
          align: widget.align,
          autoAlign: widget.autoAlign,
          highContrast: true,
          onRequestClose: _dismiss,
          content: bubble,
          child: widget.child,
        ),
      ),
    );
    return widget.excludeFromSemantics
        ? trigger
        : Semantics(tooltip: widget.label, child: trigger);
  }
}

/// The tooltip bubble body: padded inverse text (`_tooltip.scss`).
class _TooltipContent extends StatelessWidget {
  const _TooltipContent({required this.label, this.scrollController});

  final String label;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // max-inline-size: 288px.
      constraints: const BoxConstraints(maxWidth: 288),
      child: Padding(
        // padding: $spacing-05 both axes.
        padding: const EdgeInsets.all(CarbonSpacing.spacing05),
        child: scrollController == null
            ? Text(label, style: CarbonTypeStyles.body01)
            : IntrinsicWidth(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(label, style: CarbonTypeStyles.body01),
                ),
              ),
      ),
    );
  }
}
