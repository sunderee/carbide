// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/ui-shell/side-nav/_side-nav.scss
//   react/src/components/UIShell/{SideNav,SideNavItems,SideNavLink,SideNavMenu,
//     SideNavMenuItem,SideNavDivider}.tsx
//
// The UI Shell side navigation: a 256px panel (48px rail when collapsed) of
// links and collapsible menus. Uses the contextual `background` tokens.
// Rail mode (upstream `isRail`) expands 48px → 256px as an overlay above the
// page content — never reflowing it — on pointer enter, focus entering the
// nav, or a click, and collapses on pointer leave, blur, or Escape. The
// expansion animates inline-size over 0.11s cubic-bezier(0.2, 0, 1, 0.9)
// (the hardcoded upstream transition), skipped under reduced motion.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';

/// Shared side-nav state read by its items.
class _SideNavScope extends InheritedWidget {
  const _SideNavScope({required this.expanded, required super.child});

  final bool expanded;

  static bool expandedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SideNavScope>()?.expanded ??
      true;

  @override
  bool updateShouldNotify(_SideNavScope old) => expanded != old.expanded;
}

/// The left navigation panel of the UI Shell.
///
/// When the platform requests reduced motion, the collapse/expand
/// transition completes instantly (in both panel and rail modes).
///
/// ```dart
/// CarbonSideNav(
///   items: <Widget>[
///     CarbonSideNavLink(label: 'Dashboard', icon: CarbonIcons.dashboard,
///         current: true, onPressed: _dashboard),
///     CarbonSideNavMenu(label: 'Reports', children: <Widget>[
///       CarbonSideNavMenuItem(label: 'Daily', onPressed: _daily),
///     ]),
///   ],
/// )
/// ```
class CarbonSideNav extends StatefulWidget {
  /// Creates a side nav.
  const CarbonSideNav({
    required this.items,
    super.key,
    this.expanded = true,
    this.rail = false,
  });

  /// The nav items (links, menus, dividers).
  final List<Widget> items;

  /// Whether the panel is expanded (256px) or a rail (48px, icons only).
  /// Ignored in [rail] mode, where expansion follows hover and focus.
  final bool expanded;

  /// Rail mode (upstream `isRail`): a 48px rail that expands to a 256px
  /// overlay above the page content on pointer enter, focus, or click, and
  /// collapses on pointer leave, blur, or Escape.
  final bool rail;

  @override
  State<CarbonSideNav> createState() => _CarbonSideNavState();
}

class _CarbonSideNavState extends State<CarbonSideNav> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _overlayExpanded = false;
  bool _pointerInside = false;
  bool _focusWithin = false;
  double? _height;

  /// The upstream expansion transition: 0.11s cubic-bezier(0.2, 0, 1, 0.9)
  /// (`_side-nav.scss`, "TODO: sync with motion work" — not a motion token).
  static const Duration _expansion = Duration(milliseconds: 110);
  static const Cubic _expansionCurve = Cubic(0.2, 0, 1, 0.9);

  bool get _want => _pointerInside || _focusWithin;

  bool get _reducedMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  void _pointer(bool inside) {
    _pointerInside = inside;
    _sync();
  }

  void _focus(bool within) {
    _focusWithin = within;
    _sync();
  }

  void _sync() {
    if (_want) {
      if (!_overlay.isShowing) {
        _overlay.show();
        // Mount the overlay at rail width first so the expansion animates.
        setState(() => _overlayExpanded = false);
        if (_reducedMotion) {
          setState(() => _overlayExpanded = true);
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _want) {
              setState(() => _overlayExpanded = true);
            }
          });
        }
      } else if (!_overlayExpanded) {
        // The pointer crossed from the rail onto the overlay (or focus
        // returned) mid-collapse: expand again.
        setState(() => _overlayExpanded = true);
      }
    } else if (_overlay.isShowing) {
      setState(() => _overlayExpanded = false);
      if (_reducedMotion) {
        _overlay.hide();
      }
    }
  }

  KeyEventResult _onEscape(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _overlay.isShowing) {
      FocusManager.instance.primaryFocus?.unfocus();
      _focusWithin = false;
      _pointerInside = false;
      _sync();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _panel({required bool expanded}) => _SideNavScope(
    expanded: expanded,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.items,
      ),
    ),
  );

  Widget _buildOverlay(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    // Pin the flyout to the rail's start edge so the 256px expansion grows
    // into the content area in both directions (follower anchors are
    // physical-only, so resolve start against the ambient direction).
    final Alignment startAnchor =
        Directionality.of(context) == TextDirection.rtl
        ? Alignment.topRight
        : Alignment.topLeft;
    return Positioned(
      top: 0,
      left: 0,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: startAnchor,
        followerAnchor: startAnchor,
        child: MouseRegion(
          onEnter: (_) => _pointer(true),
          onExit: (_) => _pointer(false),
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onFocusChange: _focus,
            onKeyEvent: _onEscape,
            child: AnimatedContainer(
              duration: _reducedMotion ? Duration.zero : _expansion,
              curve: _expansionCurve,
              onEnd: () {
                if (!_overlayExpanded && !_want) {
                  _overlay.hide();
                }
              },
              width: _overlayExpanded ? 256 : 48,
              height: _height,
              color: theme.background,
              // The expanding clip reveals the fixed 256px content, like
              // the upstream overflow-hidden inline-size transition.
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 256,
                  maxWidth: 256,
                  alignment: AlignmentDirectional.topStart,
                  child: _panel(expanded: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);

    if (!widget.rail) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Side navigation',
        // The upstream `.cds--side-nav` inline-size transition: 0.11s
        // cubic-bezier(0.2, 0, 1, 0.9) (`_side-nav.scss`, hardcoded — not a
        // motion token).
        child: AnimatedContainer(
          duration: _reducedMotion ? Duration.zero : _expansion,
          curve: _expansionCurve,
          width: widget.expanded ? 256 : 48,
          color: theme.background,
          child: _panel(expanded: widget.expanded),
        ),
      );
    }

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Side navigation',
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: _buildOverlay,
        child: CompositedTransformTarget(
          link: _link,
          child: MouseRegion(
            onEnter: (_) => _pointer(true),
            onExit: (_) => _pointer(false),
            child: Listener(
              // A click on the rail expands it too (upstream onClick).
              onPointerDown: (_) => _pointer(true),
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                onFocusChange: _focus,
                onKeyEvent: _onEscape,
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    _height = constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : null;
                    return Container(
                      width: 48,
                      color: theme.background,
                      // The rail beneath the overlay would duplicate
                      // every item for assistive technology.
                      child: ExcludeSemantics(
                        excluding: _overlay.isShowing,
                        child: _panel(expanded: false),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The shared row layout for a side-nav link.
class _NavRow extends StatefulWidget {
  const _NavRow({
    required this.label,
    required this.icon,
    required this.current,
    required this.onTap,
    required this.indent,
    required this.trailing,
  });

  final String label;
  final CarbonIconData? icon;
  final bool current;
  final VoidCallback? onTap;
  final double indent;
  final Widget? trailing;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _hovered = false;
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onTap != null &&
        event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onTap!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool expanded = _SideNavScope.expandedOf(context);
    final Color text = widget.current || _hovered
        ? theme.textPrimary
        : theme.textSecondary;
    final Color background = widget.current
        ? theme.layerSelected01
        : _hovered
        ? theme.backgroundHover
        : const Color(0x00000000);

    return Semantics(
      button: true,
      selected: widget.current,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Focus(
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
              child: CarbonFocusRing(
                visible: _focused,
                inset: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: background,
                    // The active 4px border-interactive selection marker.
                    border: BorderDirectional(
                      start: BorderSide(
                        color: widget.current
                            ? theme.borderInteractive
                            : const Color(0x00000000),
                        width: 3,
                      ),
                    ),
                  ),
                  // The 32px row height is a minimum: labels grow the row
                  // under text scaling instead of clipping
                  // (docs/text-scaling.md).
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 32),
                    child: expanded
                        ? Padding(
                            padding: EdgeInsetsDirectional.only(
                              start: CarbonSpacing.spacing05 + widget.indent,
                              end: CarbonSpacing.spacing05,
                            ),
                            child: Row(
                              children: <Widget>[
                                if (widget.icon != null) ...<Widget>[
                                  CarbonIcon(widget.icon!, color: text),
                                  const SizedBox(
                                    width: CarbonSpacing.spacing05,
                                  ),
                                ],
                                Expanded(
                                  child: Text(
                                    widget.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CarbonTypeStyles.headingCompact01
                                        .copyWith(
                                          color: text,
                                          fontWeight: widget.current
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                  ),
                                ),
                                ?widget.trailing,
                              ],
                            ),
                          )
                        // The rail shows just a centred icon.
                        : Center(
                            child: widget.icon != null
                                ? CarbonIcon(widget.icon!, color: text)
                                : const SizedBox.shrink(),
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

/// A side-nav navigation link.
class CarbonSideNavLink extends StatelessWidget {
  /// Creates a side-nav link.
  const CarbonSideNavLink({
    required this.label,
    super.key,
    this.icon,
    this.current = false,
    this.onPressed,
  });

  /// The link label.
  final String label;

  /// An optional leading icon.
  final CarbonIconData? icon;

  /// Whether this link is the current page.
  final bool current;

  /// The navigation action.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _NavRow(
    label: label,
    icon: icon,
    current: current,
    onTap: onPressed,
    indent: 0,
    trailing: null,
  );
}

/// A side-nav sub-item inside a [CarbonSideNavMenu].
class CarbonSideNavMenuItem extends StatelessWidget {
  /// Creates a side-nav menu item.
  const CarbonSideNavMenuItem({
    required this.label,
    super.key,
    this.current = false,
    this.onPressed,
  });

  /// The item label.
  final String label;

  /// Whether this item is the current page.
  final bool current;

  /// The navigation action.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _NavRow(
    label: label,
    icon: null,
    current: current,
    onTap: onPressed,
    indent: CarbonSpacing.spacing06,
    trailing: null,
  );
}

/// A collapsible side-nav menu grouping [children].
///
/// When the platform requests reduced motion, the fold and chevron snap
/// instantly.
class CarbonSideNavMenu extends StatefulWidget {
  /// Creates a side-nav menu.
  const CarbonSideNavMenu({
    required this.label,
    required this.children,
    super.key,
    this.icon,
    this.initiallyExpanded = false,
  });

  /// The group label.
  final String label;

  /// The sub-items (typically [CarbonSideNavMenuItem]s).
  final List<Widget> children;

  /// An optional leading icon.
  final CarbonIconData? icon;

  /// Whether the group starts expanded.
  final bool initiallyExpanded;

  @override
  State<CarbonSideNavMenu> createState() => _CarbonSideNavMenuState();
}

class _CarbonSideNavMenuState extends State<CarbonSideNavMenu> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration fast02 = reducedMotion
        ? Duration.zero
        : CarbonDuration.fast02;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _open,
          child: _NavRow(
            label: widget.label,
            icon: widget.icon,
            current: false,
            onTap: () => setState(() => _open = !_open),
            indent: 0,
            // Chevron per `_side-nav.scss` `__submenu-chevron > svg`:
            // transform $duration-fast-02 (no easing token cited).
            trailing: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: fast02,
              curve: CarbonEasing.standardProductive,
              child: CarbonIcon(
                CarbonIcons.chevronDown,
                size: 16,
                color: theme.iconPrimary,
              ),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: _open ? 1 : 0),
          duration: fast02,
          curve: CarbonEasing.standardProductive,
          builder: (BuildContext context, double t, Widget? child) => ClipRect(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              heightFactor: t,
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}

/// A 1px divider between side-nav sections.
class CarbonSideNavDivider extends StatelessWidget {
  /// Creates a side-nav divider.
  const CarbonSideNavDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CarbonSpacing.spacing05,
        vertical: CarbonSpacing.spacing03,
      ),
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: theme.borderSubtle00),
      ),
    );
  }
}
