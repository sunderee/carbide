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
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/native_shell_content_focus.dart';

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
          border: BorderDirectional(
            start: BorderSide(color: layer.borderSubtle),
            end: BorderSide(color: layer.borderSubtle),
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
  final FocusNode _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

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

    return CarbonControlSemantics(
      selected: widget.selected,
      button: true,
      focusNode: _focus,
      state: CarbonControlState.resolve(hasCallback: widget.onPressed != null),
      label: widget.label,
      readOnlyHint: '',
      onActivate: widget.onPressed,
      builder: (_) => ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            child: Focus(
              focusNode: _focus,
              includeSemantics: false,
              canRequestFocus: widget.onPressed != null,
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
              child: CarbonFocusRing(
                visible: _focused,
                inset: true,
                child: ColoredBox(
                  color: _hovered && !widget.selected
                      ? layer.layerHover
                      : const Color(0x00000000),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CarbonSpacing.spacing05,
                        vertical: 6,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        heightFactor: 1,
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
class CarbonShellContent extends StatefulWidget {
  /// Creates a shell content region.
  const CarbonShellContent({
    required this.child,
    super.key,
    this.label = 'Main content',
    this.focusNode,
  });

  /// The page body.
  final Widget child;

  /// The accessible label for the region.
  final String label;

  /// A borrowed skip-link destination. The caller owns and disposes it.
  ///
  /// Set `skipTraversal: true` for a destination reached programmatically
  /// without adding a native Tab stop. Its focus/traversal policy is preserved.
  final FocusNode? focusNode;

  @override
  State<CarbonShellContent> createState() => _CarbonShellContentState();
}

class _CarbonShellContentState extends State<CarbonShellContent> {
  static int _nextIdentifier = 0;
  final String _identifier = 'carbide-shell-content-${_nextIdentifier++}';
  final FocusNode _fallback = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );
  FocusNode get _focus => widget.focusNode ?? _fallback;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(CarbonShellContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _fallback).removeListener(_changed);
      _focus.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _fallback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          syncNativeShellContentFocus(
            _identifier,
            focusable: _focus.canRequestFocus,
            traversable: !_focus.skipTraversal,
          );
        }
      });
    }
    return Semantics(
      role: SemanticsRole.main,
      identifier: _identifier,
      container: true,
      explicitChildNodes: true,
      label: widget.label,
      focusable: _focus.canRequestFocus,
      focused: _focus.canRequestFocus ? _focus.hasPrimaryFocus : null,
      onFocus: _focus.canRequestFocus ? _focus.requestFocus : null,
      child: Focus.withExternalFocusNode(
        focusNode: _focus,
        includeSemantics: false,
        child: Padding(
          padding: const EdgeInsets.all(CarbonSpacing.spacing05),
          child: widget.child,
        ),
      ),
    );
  }
}
