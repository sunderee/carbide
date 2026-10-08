// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/ui-shell/header/_header.scss
//   react/src/components/UIShell/{Header,HeaderName,HeaderNavigation,
//     HeaderMenuItem,HeaderMenu,HeaderMenuButton,HeaderGlobalBar,
//     HeaderGlobalAction,SkipToContent}.tsx
//
// The UI Shell header: the top app bar. It uses the contextual `background`
// tokens, so wrapping it in the Gray 100 theme yields the classic dark shell.
// Dropdown nav menus and global-action panels reuse Menu (#92) / Popover (#90).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import 'carbon_side_nav.dart';
import '../menu/carbon_menu.dart';
import '../popover/carbon_popover.dart';

double _shellViewportWidth(BuildContext context, double available) {
  final double viewport = MediaQuery.maybeSizeOf(context)?.width ?? 0;
  if (viewport > 0) return viewport;
  final view = View.maybeOf(context);
  return view == null
      ? available
      : view.physicalSize.width / view.devicePixelRatio;
}

/// Header navigation rendered in the side nav below [CarbonBreakpoint.lg].
///
/// Compose the corresponding [CarbonSideNavLink] and [CarbonSideNavMenu]
/// entries here, at the start of [CarbonSideNav.items]. The header's
/// [CarbonHeader.navigation] is visible on the complementary wide viewport.
class CarbonHeaderSideNavItems extends StatelessWidget {
  /// Creates responsive primary navigation for a side nav.
  const CarbonHeaderSideNavItems({
    required this.items,
    super.key,
    this.hasDivider = false,
  });

  /// Primary links and menus, using the same destinations as the header.
  final List<Widget> items;

  /// Whether to separate primary navigation from the remaining side nav.
  final bool hasDivider;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      if (_shellViewportWidth(context, constraints.maxWidth) >=
              CarbonBreakpoint.lg.width ||
          items.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing07),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
            if (hasDivider)
              PositionedDirectional(
                start: CarbonSpacing.spacing05,
                end: CarbonSpacing.spacing05,
                bottom: -CarbonSpacing.spacing05,
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 1,
                    child: ColoredBox(
                      color: CarbonTheme.of(context).borderSubtle00,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// The UI Shell header bar, with a 48px minimum height.
///
/// ```dart
/// CarbonHeader(
///   name: const CarbonHeaderName(prefix: 'IBM', name: 'Carbide'),
///   navigation: <Widget>[
///     CarbonHeaderMenuItem(label: 'Catalog', onPressed: _catalog),
///   ],
///   globalActions: <Widget>[
///     CarbonHeaderGlobalAction(
///       icon: CarbonIcons.notification,
///       label: 'Notifications',
///       onPressed: _notifications,
///     ),
///   ],
/// )
/// ```
class CarbonHeader extends StatelessWidget {
  /// Creates a header.
  const CarbonHeader({
    required this.name,
    super.key,
    this.menuButton,
    this.navigation = const <Widget>[],
    this.globalActions = const <Widget>[],
  });

  /// The product name (typically a [CarbonHeaderName]).
  final Widget name;

  /// An optional leading menu (hamburger) button.
  final Widget? menuButton;

  /// The header navigation items.
  final List<Widget> navigation;

  /// The trailing global-action buttons.
  final List<Widget> globalActions;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Main header',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.background,
          border: Border(bottom: BorderSide(color: theme.borderSubtle00)),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool wide =
                _shellViewportWidth(context, constraints.maxWidth) >=
                CarbonBreakpoint.lg.width;
            final double reserved =
                (globalActions.length + (menuButton == null ? 0 : 1)) * 48;
            final double nameWidth = (constraints.maxWidth - reserved).clamp(
              0.0,
              double.infinity,
            );
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: <Widget>[
                  ?menuButton,
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: nameWidth),
                    child: name,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: wide
                          ? <Widget>[
                              for (final Widget item in navigation)
                                Flexible(child: item),
                            ]
                          : const <Widget>[],
                    ),
                  ),
                  ...globalActions,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The product name shown at the start of a [CarbonHeader].
///
/// When [onPressed] is set the name behaves like upstream's `HeaderName`
/// anchor: it is reachable with Tab and activated with Enter or Space
/// (`UI-shell-header/accessibility.mdx`: every header element can be
/// reached by the Tab key).
class CarbonHeaderName extends StatefulWidget {
  /// Creates a header name.
  const CarbonHeaderName({
    required this.name,
    super.key,
    this.prefix,
    this.onPressed,
  });

  /// The product name (bold).
  final String name;

  /// An optional lighter prefix (for example a company name).
  final String? prefix;

  /// Called when the name is activated (typically navigates home).
  final VoidCallback? onPressed;

  @override
  State<CarbonHeaderName> createState() => _CarbonHeaderNameState();
}

class _CarbonHeaderNameState extends State<CarbonHeaderName> {
  bool _focused = false;
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

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
    final bool interactive = widget.onPressed != null;
    final String label = widget.prefix != null
        ? '${widget.prefix} ${widget.name}'
        : widget.name;
    final Widget visual = ExcludeSemantics(
      child: MouseRegion(
        cursor: interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Focus(
            focusNode: _focus,
            includeSemantics: false,
            canRequestFocus: interactive,
            onKeyEvent: _onKey,
            onFocusChange: (bool f) => setState(() => _focused = f),
            child: CarbonFocusRing(
              visible: _focused,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CarbonSpacing.spacing05,
                  vertical: CarbonSpacing.spacing04,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.prefix != null) ...<Widget>[
                      Flexible(
                        child: Text(
                          widget.prefix!,
                          style: CarbonTypeStyles.bodyCompact01.copyWith(
                            color: theme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: CarbonSpacing.spacing02),
                    ],
                    Flexible(
                      child: Text(
                        widget.name,
                        style: CarbonTypeStyles.bodyCompact01.copyWith(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!interactive) return Semantics(label: label, child: visual);
    return CarbonControlSemantics(
      focusNode: _focus,
      button: true,
      state: CarbonControlState.interactive,
      label: label,
      readOnlyHint: '',
      onActivate: widget.onPressed,
      builder: (_) => visual,
    );
  }
}

/// A header navigation link, underlined when [selected].
class CarbonHeaderMenuItem extends StatefulWidget {
  /// Creates a header menu item.
  const CarbonHeaderMenuItem({
    required this.label,
    super.key,
    this.selected = false,
    this.onPressed,
  });

  /// The link label.
  final String label;

  /// Whether this item is the current page.
  final bool selected;

  /// The navigation action.
  final VoidCallback? onPressed;

  @override
  State<CarbonHeaderMenuItem> createState() => _CarbonHeaderMenuItemState();
}

class _CarbonHeaderMenuItemState extends State<CarbonHeaderMenuItem> {
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _hovered
                        ? theme.backgroundHover
                        : const Color(0x00000000),
                    // A 2px selected underline (`border-interactive`).
                    border: Border(
                      bottom: BorderSide(
                        color: widget.selected
                            ? theme.borderInteractive
                            : const Color(0x00000000),
                        width: 2,
                      ),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CarbonSpacing.spacing05,
                        vertical: CarbonSpacing.spacing04,
                      ),
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CarbonTypeStyles.bodyCompact01.copyWith(
                            color: theme.textPrimary,
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

/// A header navigation dropdown: a label that opens a [CarbonMenu] of items.
class CarbonHeaderMenu extends StatefulWidget {
  /// Creates a header dropdown menu.
  const CarbonHeaderMenu({
    required this.label,
    required this.items,
    super.key,
    this.selected = false,
  });

  /// The trigger label.
  final String label;

  /// The menu items (typically [CarbonMenuItem]s).
  final List<Widget> items;

  /// Whether this menu is the current section.
  final bool selected;

  @override
  State<CarbonHeaderMenu> createState() => _CarbonHeaderMenuState();
}

class _CarbonHeaderMenuState extends State<CarbonHeaderMenu> {
  bool _open = false;
  final Object _group = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return CarbonPopover(
      open: _open,
      align: CarbonPopoverAlignment.bottomStart,
      caret: false,
      tapRegionGroupId: _group,
      onRequestClose: () => setState(() => _open = false),
      content: CarbonMenu(
        onClose: () => setState(() => _open = false),
        children: widget.items,
      ),
      child: TapRegion(
        groupId: _group,
        child: CarbonHeaderMenuItem(
          label: widget.label,
          selected: widget.selected || _open,
          onPressed: () => setState(() => _open = !_open),
        ),
      ),
    );
  }
}

/// A trailing icon button in the header's global bar.
class CarbonHeaderGlobalAction extends StatefulWidget {
  /// Creates a global action.
  const CarbonHeaderGlobalAction({
    required this.icon,
    required this.label,
    super.key,
    this.isActive = false,
    this.onPressed,
  });

  /// The action icon.
  final CarbonIconData icon;

  /// The accessible label.
  final String label;

  /// Whether the action is toggled on (its panel is open).
  final bool isActive;

  /// The action.
  final VoidCallback? onPressed;

  @override
  State<CarbonHeaderGlobalAction> createState() =>
      _CarbonHeaderGlobalActionState();
}

class _CarbonHeaderGlobalActionState extends State<CarbonHeaderGlobalAction> {
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
    final Color background = widget.isActive
        ? theme.backgroundActive
        : _hovered
        ? theme.backgroundHover
        : const Color(0x00000000);

    return CarbonControlSemantics(
      selected: widget.isActive,
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
                child: ColoredBox(
                  color: background,
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: CarbonIcon(widget.icon, color: theme.iconPrimary),
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

/// The leading hamburger button that toggles the SideNav.
class CarbonHeaderMenuButton extends StatelessWidget {
  /// Creates a header menu (hamburger) button.
  const CarbonHeaderMenuButton({
    required this.label,
    super.key,
    this.isOpen = false,
    this.onPressed,
  });

  /// The accessible label.
  final String label;

  /// Whether the SideNav is open (swaps to a close icon).
  final bool isOpen;

  /// The toggle action.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CarbonHeaderGlobalAction(
      icon: isOpen ? CarbonIcons.close : CarbonIcons.menu,
      label: label,
      isActive: isOpen,
      onPressed: onPressed,
    );
  }
}

/// A skip-to-content link, visible only when focused (a11y aid).
class CarbonSkipToContent extends StatefulWidget {
  /// Creates a skip-to-content link.
  const CarbonSkipToContent({
    required this.onPressed,
    super.key,
    this.label = 'Skip to main content',
  });

  /// Called when the link is activated.
  final VoidCallback onPressed;

  /// The link label.
  final String label;

  @override
  State<CarbonSkipToContent> createState() => _CarbonSkipToContentState();
}

class _CarbonSkipToContentState extends State<CarbonSkipToContent> {
  bool _focused = false;
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return CarbonControlSemantics(
      button: true,
      focusNode: _focus,
      state: CarbonControlState.interactive,
      label: widget.label,
      readOnlyHint: '',
      onActivate: widget.onPressed,
      builder: (_) => ExcludeSemantics(
        child: Focus(
          focusNode: _focus,
          includeSemantics: false,
          onKeyEvent: _onKey,
          onFocusChange: (bool f) => setState(() => _focused = f),
          child: Offstage(
            offstage: !_focused,
            child: CarbonFocusRing(
              visible: _focused,
              child: ColoredBox(
                color: theme.background,
                child: Padding(
                  padding: const EdgeInsets.all(CarbonSpacing.spacing04),
                  child: Text(
                    widget.label,
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: theme.focus,
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
