// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/ui-shell/{switcher,header-panel,content}
//   react/src/components/UIShell/{Switcher,SwitcherItem,SwitcherDivider,
//     HeaderPanel,Content}.tsx
//
// The UI Shell switcher (a list of product/account links shown in a header
// panel), the sliding HeaderPanel that hosts it, and the main Content region.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';

/// A right-side panel under the header that slides open (0 → 256px), hosting a
/// [CarbonSwitcher] or notification content.
///
/// When the platform requests reduced motion, the slide completes instantly.
class CarbonHeaderPanel extends StatelessWidget {
  /// Creates a header panel.
  const CarbonHeaderPanel({
    required this.open,
    required this.child,
    super.key,
    this.label = 'Header panel',
  });

  /// Whether the panel is open.
  final bool open;

  /// The panel contents.
  final Widget child;

  /// The accessible label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      // Slide per `_header-panel.scss`: width $duration-fast-02
      // motion(exit, productive).
      child: AnimatedContainer(
        duration: carbonDuration(context, CarbonDuration.fast02),
        curve: CarbonEasing.exitProductive,
        width: open ? 256 : 0,
        decoration: BoxDecoration(
          color: layer.layer,
          border: Border(
            left: BorderSide(color: layer.borderSubtle),
            right: BorderSide(color: layer.borderSubtle),
          ),
        ),
        child: ClipRect(
          child: OverflowBox(
            minWidth: 256,
            maxWidth: 256,
            alignment: AlignmentDirectional.topStart,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }
}

/// A list of product/account links shown inside a [CarbonHeaderPanel].
class CarbonSwitcher extends StatelessWidget {
  /// Creates a switcher.
  const CarbonSwitcher({required this.children, super.key});

  /// The switcher items and dividers.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Switcher',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// A single switcher link.
class CarbonSwitcherItem extends StatefulWidget {
  /// Creates a switcher item.
  const CarbonSwitcherItem({
    required this.label,
    super.key,
    this.selected = false,
    this.onPressed,
  });

  /// The link label.
  final String label;

  /// Whether this is the current product/account.
  final bool selected;

  /// The navigation action.
  final VoidCallback? onPressed;

  @override
  State<CarbonSwitcherItem> createState() => _CarbonSwitcherItemState();
}

class _CarbonSwitcherItemState extends State<CarbonSwitcherItem> {
  bool _hovered = false;
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onPressed != null &&
        event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onPressed!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final Color text = widget.selected || _hovered
        ? theme.textPrimary
        : theme.textSecondary;

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onPressed,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: Focus(
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
              child: CarbonFocusRing(
                visible: _focused,
                inset: true,
                child: ColoredBox(
                  color: _hovered && !widget.selected
                      ? layer.layerHover
                      : const Color(0x00000000),
                  child: SizedBox(
                    height: 32,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CarbonSpacing.spacing05,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CarbonTypeStyles.headingCompact01.copyWith(
                            color: text,
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1px divider between switcher sections.
class CarbonSwitcherDivider extends StatelessWidget {
  /// Creates a switcher divider.
  const CarbonSwitcherDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CarbonSpacing.spacing05,
        vertical: CarbonSpacing.spacing03,
      ),
      child: SizedBox(height: 1, child: ColoredBox(color: layer.borderSubtle)),
    );
  }
}

/// The main content region of the UI Shell — a `main` landmark for the page
/// body beside the header and side navigation.
class CarbonShellContent extends StatelessWidget {
  /// Creates a shell content region.
  const CarbonShellContent({
    required this.child,
    super.key,
    this.label = 'Main content',
  });

  /// The page body.
  final Widget child;

  /// The accessible label for the region.
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.all(CarbonSpacing.spacing05),
        child: child,
      ),
    );
  }
}
