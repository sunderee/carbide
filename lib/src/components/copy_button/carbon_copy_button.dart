// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/copy-button/_copy-button.scss
//   react/src/components/Copy/Copy.tsx
//   react/src/components/CopyButton/CopyButton.tsx
//
// Copy is an icon button that, on activation, shows a transient feedback
// bubble ("Copied!"); CopyButton is the convenience wrapper carrying the Copy
// icon. The button fills the contextual `layer` token, so it adapts inside a
// CarbonLayer. The feedback reuses the inverse Popover surface, like Tooltip.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../popover/carbon_popover.dart';

/// The square edge length of a copy button.
enum CarbonCopySize {
  /// 32px.
  sm(32),

  /// 40px — the default.
  md(40),

  /// 48px.
  lg(48);

  const CarbonCopySize(this.dimension);

  /// The button's edge length in logical pixels.
  final double dimension;
}

/// An icon button that shows a transient feedback bubble when activated.
///
/// [child] is the icon (or any widget) shown in the square button. On tap or
/// Enter/Space the optional [value] is written to the clipboard, [onCopy] is
/// called, and the [feedback] message ("Copied!") is shown for
/// [feedbackTimeout] before fading. When a [label] is given it doubles as the
/// resting tooltip (shown on hover and keyboard focus) and the button's
/// accessible name. Most callers want [CarbonCopyButton] instead.
///
/// ```dart
/// CarbonCopy(
///   value: 'npm i @carbon/react',
///   label: 'Copy install command',
///   child: const CarbonIcon(CarbonIcons.copy),
/// )
/// ```
class CarbonCopy extends StatefulWidget {
  /// Creates a copy button around [child].
  const CarbonCopy({
    required this.child,
    super.key,
    this.onCopy,
    this.value,
    this.feedback = 'Copied!',
    this.feedbackTimeout = const Duration(milliseconds: 2000),
    this.label,
    this.align = CarbonPopoverAlignment.bottom,
    this.size = CarbonCopySize.md,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The button's content, typically a 16px [CarbonIcon].
  final Widget child;

  /// Called on activation, after [value] (if any) is copied.
  final VoidCallback? onCopy;

  /// Text written to the clipboard on activation. When null, copying is left to
  /// [onCopy].
  final String? value;

  /// The message shown in the feedback bubble after activation.
  final String feedback;

  /// How long the feedback bubble stays before fading.
  final Duration feedbackTimeout;

  /// The resting tooltip and accessible name. When null, no resting tooltip is
  /// shown.
  final String? label;

  /// Where the bubble sits relative to the button.
  final CarbonPopoverAlignment align;

  /// The square size of the button.
  final CarbonCopySize size;

  /// Whether the button responds to input.
  final bool enabled;

  /// An optional external focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<CarbonCopy> createState() => _CarbonCopyState();
}

class _CarbonCopyState extends State<CarbonCopy> {
  bool _feedback = false;
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  Timer? _feedbackTimer;
  Timer? _hoverTimer;

  // Mirror Tooltip's hover debounce so the resting tooltip does not flicker.
  static const int _enterDelayMs = 100;
  static const int _leaveDelayMs = 300;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _hoverTimer?.cancel();
    super.dispose();
  }

  bool get _hasLabel => widget.label != null && widget.label!.isNotEmpty;

  bool get _open => _feedback || (_hasLabel && (_hovered || _focused));

  String get _currentLabel =>
      _feedback ? widget.feedback : (widget.label ?? '');

  void _setHovered(bool value) {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(
      Duration(milliseconds: value ? _enterDelayMs : _leaveDelayMs),
      () {
        if (mounted && _hovered != value) setState(() => _hovered = value);
      },
    );
  }

  void _activate() {
    if (!widget.enabled) return;
    final String? value = widget.value;
    if (value != null) {
      unawaited(Clipboard.setData(ClipboardData(text: value)));
    }
    widget.onCopy?.call();
    _feedbackTimer?.cancel();
    setState(() => _feedback = true);
    _feedbackTimer = Timer(widget.feedbackTimeout, () {
      if (mounted) setState(() => _feedback = false);
    });
  }

  void _close() {
    _feedbackTimer?.cancel();
    _hoverTimer?.cancel();
    if (mounted) {
      setState(() {
        _feedback = false;
        _hovered = false;
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _activate();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _open) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = widget.enabled;

    // reset + background-color: $layer; hover $layer-hover; active $layer-active.
    final Color background = enabled && _pressed
        ? layer.layerActive
        : enabled && _hovered
        ? layer.layerHover
        : layer.layer;

    final Widget surface = ColoredBox(
      color: background,
      child: SizedBox.square(
        dimension: widget.size.dimension,
        child: Center(child: widget.child),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: _currentLabel.isEmpty ? null : _currentLabel,
      onTap: enabled ? _activate : null,
      child: ExcludeSemantics(
        child: CarbonPopover(
          open: _open,
          align: widget.align,
          highContrast: true,
          onRequestClose: _close,
          // The button's Semantics carries the label; exclude the bubble's
          // duplicate text (it renders in the overlay, outside the button node).
          content: ExcludeSemantics(child: _CopyFeedback(label: _currentLabel)),
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: enabled ? (_) => _setHovered(true) : null,
            onExit: enabled ? (_) => _setHovered(false) : null,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? _activate : null,
              onTapDown: enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: enabled
                  ? () => setState(() => _pressed = false)
                  : null,
              child: Focus(
                focusNode: widget.focusNode,
                autofocus: widget.autofocus,
                canRequestFocus: enabled,
                onKeyEvent: _onKey,
                onFocusChange: (bool value) => setState(() => _focused = value),
                child: CarbonFocusRing(visible: _focused, child: surface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A copy-to-clipboard icon button.
///
/// Shows a transient [feedback] bubble ("Copied!") on activation. When [value]
/// is given it is written to the clipboard; otherwise wire [onCopy] to perform
/// the copy. [iconDescription] is the resting tooltip and accessible name.
///
/// ```dart
/// CarbonCopyButton(value: 'token-value')
/// ```
class CarbonCopyButton extends StatelessWidget {
  /// Creates a copy button showing the Copy icon.
  const CarbonCopyButton({
    super.key,
    this.onCopy,
    this.value,
    this.feedback = 'Copied!',
    this.feedbackTimeout = const Duration(milliseconds: 2000),
    this.iconDescription = 'Copy to clipboard',
    this.align = CarbonPopoverAlignment.bottom,
    this.size = CarbonCopySize.md,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Called on activation, after [value] (if any) is copied.
  final VoidCallback? onCopy;

  /// Text written to the clipboard on activation.
  final String? value;

  /// The message shown in the feedback bubble after activation.
  final String feedback;

  /// How long the feedback bubble stays before fading.
  final Duration feedbackTimeout;

  /// The resting tooltip and accessible name for the copy action.
  final String iconDescription;

  /// Where the bubble sits relative to the button.
  final CarbonPopoverAlignment align;

  /// The square size of the button.
  final CarbonCopySize size;

  /// Whether the button responds to input.
  final bool enabled;

  /// An optional external focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return CarbonCopy(
      onCopy: onCopy,
      value: value,
      feedback: feedback,
      feedbackTimeout: feedbackTimeout,
      label: iconDescription,
      align: align,
      size: size,
      enabled: enabled,
      focusNode: focusNode,
      autofocus: autofocus,
      // svg fill: $icon-primary; disabled snippet → $icon-disabled.
      child: CarbonIcon(
        CarbonIcons.copy,
        color: enabled ? theme.iconPrimary : theme.iconDisabled,
      ),
    );
  }
}

/// The feedback bubble body: padded inverse text, matching Tooltip.
class _CopyFeedback extends StatelessWidget {
  const _CopyFeedback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // max-inline-size: 288px (tooltip content).
      constraints: const BoxConstraints(maxWidth: 288),
      child: Padding(
        padding: const EdgeInsets.all(CarbonSpacing.spacing05),
        child: Text(label, style: CarbonTypeStyles.body01),
      ),
    );
  }
}
