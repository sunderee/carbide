// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
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

  @override
  State<CarbonTooltip> createState() => _CarbonTooltipState();
}

class _CarbonTooltipState extends State<CarbonTooltip> {
  late bool _open = widget.defaultOpen;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _show({int delayMs = 0}) => _schedule(true, delayMs);

  void _hide({int delayMs = 0}) => _schedule(false, delayMs);

  void _schedule(bool open, int delayMs) {
    _timer?.cancel();
    if (delayMs == 0) {
      if (mounted && _open != open) setState(() => _open = open);
      return;
    }
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _open != open) setState(() => _open = open);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _open) {
      _hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.label,
      child: MouseRegion(
        onEnter: (_) => _show(delayMs: widget.enterDelayMs),
        onExit: (_) => _hide(delayMs: widget.leaveDelayMs),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          onFocusChange: (bool focused) => focused ? _show() : _hide(),
          child: CarbonPopover(
            open: _open,
            align: widget.align,
            highContrast: true,
            onRequestClose: _hide,
            content: _TooltipContent(label: widget.label),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// The tooltip bubble body: padded inverse text (`_tooltip.scss`).
class _TooltipContent extends StatelessWidget {
  const _TooltipContent({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // max-inline-size: 288px.
      constraints: const BoxConstraints(maxWidth: 288),
      child: Padding(
        // padding: $spacing-05 both axes.
        padding: const EdgeInsets.all(CarbonSpacing.spacing05),
        child: Text(label, style: CarbonTypeStyles.body01),
      ),
    );
  }
}
