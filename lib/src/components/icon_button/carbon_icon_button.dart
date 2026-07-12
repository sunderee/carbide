// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   react/src/components/IconButton/index.tsx
//   styling derives from Button + Tooltip.
//
// IconButton pairs an icon-only CarbonButton with a CarbonTooltip carrying its
// label — the accessible name and the on-hover/focus description in one widget.

import 'package:flutter/widgets.dart';

import '../../icons/carbon_icon_data.dart';
import '../button/carbon_button.dart';
import '../popover/carbon_popover.dart';
import '../tooltip/carbon_tooltip.dart';

/// An icon-only button that shows its [label] in a tooltip on hover and focus.
///
/// The [label] is both the tooltip text and the button's accessible name.
///
/// ```dart
/// CarbonIconButton(
///   icon: CarbonIcons.add,
///   label: 'Add item',
///   onPressed: _add,
/// )
/// ```
class CarbonIconButton extends StatelessWidget {
  /// Creates an icon button.
  const CarbonIconButton({
    required this.icon,
    required this.label,
    super.key,
    this.onPressed,
    this.kind = CarbonButtonKind.primary,
    this.size = CarbonButtonSize.lg,
    this.align = CarbonPopoverAlignment.top,
    this.enterDelayMs = 100,
    this.leaveDelayMs = 100,
    this.isSelected = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// The icon to render.
  final CarbonIconData icon;

  /// The tooltip text and the button's accessible name.
  final String label;

  /// Called when the button is activated; `null` disables the button.
  final VoidCallback? onPressed;

  /// The button kind.
  final CarbonButtonKind kind;

  /// The button size.
  final CarbonButtonSize size;

  /// Where the tooltip sits relative to the button.
  final CarbonPopoverAlignment align;

  /// Hover-in debounce before the tooltip shows, in milliseconds.
  final int enterDelayMs;

  /// Hover-out debounce before the tooltip hides, in milliseconds.
  final int leaveDelayMs;

  /// Whether the button reads as pressed/selected (ghost kind).
  final bool isSelected;

  /// An optional external focus node.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return CarbonTooltip(
      label: label,
      align: align,
      enterDelayMs: enterDelayMs,
      leaveDelayMs: leaveDelayMs,
      child: CarbonButton.iconOnly(
        icon: icon,
        iconDescription: label,
        kind: kind,
        size: size,
        // isSelected is only valid on ghost buttons; ignore it otherwise.
        isSelected: kind == CarbonButtonKind.ghost && isSelected,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
      ),
    );
  }
}
