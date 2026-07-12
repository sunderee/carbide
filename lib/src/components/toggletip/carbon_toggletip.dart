// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/toggletip/_toggletip.scss
//   react/src/components/Toggletip/Toggletip.tsx
//
// Toggletip is a click-triggered popover (vs Tooltip's hover) holding
// interactive content, built on the Popover primitive (#90).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../popover/carbon_popover.dart';

/// A click-triggered popover holding interactive content.
///
/// Clicking (or Enter/Space on) the trigger toggles a [CarbonPopover] with the
/// [content] and an optional [actions] row. Escape closes it and returns focus
/// to the trigger.
///
/// The popover shows and hides instantly — Carbon defines no toggletip
/// motion, so reduced motion needs no special handling.
///
/// ```dart
/// CarbonToggletip(
///   content: const Text('Additional context about this field.'),
///   actions: <Widget>[
///     CarbonLink(text: 'Learn more', onPressed: _open),
///   ],
/// )
/// ```
class CarbonToggletip extends StatefulWidget {
  /// Creates a toggletip.
  const CarbonToggletip({
    required this.content,
    super.key,
    this.actions,
    this.button,
    this.align = CarbonPopoverAlignment.bottom,
    this.autoAlign = false,
    this.defaultOpen = false,
    this.buttonLabel = 'Show information',
  });

  /// The popover body.
  final Widget content;

  /// An optional row of action widgets, shown beneath [content].
  final List<Widget>? actions;

  /// The trigger; defaults to an information icon button.
  final Widget? button;

  /// Where the popover opens relative to the trigger.
  final CarbonPopoverAlignment align;

  /// Whether the popover flips to stay in view.
  final bool autoAlign;

  /// Whether the popover starts open.
  final bool defaultOpen;

  /// The accessible label for the default icon trigger.
  final String buttonLabel;

  @override
  State<CarbonToggletip> createState() => _CarbonToggletipState();
}

class _CarbonToggletipState extends State<CarbonToggletip> {
  late bool _open = widget.defaultOpen;
  final FocusNode _triggerFocus = FocusNode();
  // Shares a TapRegion group with the popover so tapping the trigger while
  // open is not mistaken for an outside tap (which would close-then-reopen).
  final Object _group = UniqueKey();

  @override
  void dispose() {
    _triggerFocus.dispose();
    super.dispose();
  }

  void _toggle() => setState(() => _open = !_open);

  void _close() {
    setState(() => _open = false);
    _triggerFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return CarbonPopover(
      open: _open,
      align: widget.align,
      autoAlign: widget.autoAlign,
      onRequestClose: _close,
      tapRegionGroupId: _group,
      content: _ToggletipContent(
        content: widget.content,
        actions: widget.actions,
      ),
      child: TapRegion(
        groupId: _group,
        child: _ToggletipButton(
          focusNode: _triggerFocus,
          open: _open,
          label: widget.buttonLabel,
          onTap: _toggle,
          custom: widget.button,
        ),
      ),
    );
  }
}

/// The toggletip trigger: an info icon (or custom widget) that toggles on tap
/// or Enter/Space.
class _ToggletipButton extends StatefulWidget {
  const _ToggletipButton({
    required this.focusNode,
    required this.open,
    required this.label,
    required this.onTap,
    required this.custom,
  });

  final FocusNode focusNode;
  final bool open;
  final String label;
  final VoidCallback onTap;
  final Widget? custom;

  @override
  State<_ToggletipButton> createState() => _ToggletipButtonState();
}

class _ToggletipButtonState extends State<_ToggletipButton> {
  bool _hovered = false;
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Widget child =
        widget.custom ??
        CarbonIcon(
          CarbonIcons.information,
          // icon-secondary at rest, icon-primary on hover/open.
          color: _hovered || widget.open
              ? theme.iconPrimary
              : theme.iconSecondary,
        );

    return Semantics(
      button: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Focus(
              focusNode: widget.focusNode,
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
              child: CarbonFocusRing(
                visible: _focused,
                child: Padding(
                  padding: const EdgeInsets.all(CarbonSpacing.spacing02),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The toggletip popover body: padded content with an optional actions row.
class _ToggletipContent extends StatelessWidget {
  const _ToggletipContent({required this.content, required this.actions});

  final Widget content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      // padding: $spacing-05.
      padding: const EdgeInsets.all(CarbonSpacing.spacing05),
      child: DefaultTextStyle.merge(
        style: CarbonTypeStyles.body01.copyWith(color: theme.textPrimary),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            content,
            if (actions != null && actions!.isNotEmpty) ...<Widget>[
              const SizedBox(height: CarbonSpacing.spacing05),
              Row(
                // toggletip-actions: justify space-between, gap spacing-05.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (int i = 0; i < actions!.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: CarbonSpacing.spacing05),
                    actions![i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
