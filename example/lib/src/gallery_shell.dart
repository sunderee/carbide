// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'catalog.dart';
import 'gallery_controller.dart';
import 'registry.dart';

/// The persistent UI Shell — header, side navigation and content region — that
/// frames every page. [activeSlug] highlights the current entry (`null` on the
/// overview route).
class GalleryShell extends StatefulWidget {
  /// Creates the gallery shell.
  const GalleryShell({
    required this.activeSlug,
    required this.child,
    super.key,
  });

  /// The slug of the page currently shown, or null for the overview.
  final String? activeSlug;

  /// The page body.
  final Widget child;

  @override
  State<GalleryShell> createState() => _GalleryShellState();
}

class _GalleryShellState extends State<GalleryShell> {
  bool _mobileOpen = false;
  FocusNode? _menuReturnFocus;
  final FocusNode _entryFocus = FocusNode(skipTraversal: true);
  final FocusNode _contentFocus = FocusNode(
    debugLabel: 'Gallery main content',
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    // The nested router initially focuses its page scope. Start at the shell
    // so the first Tab can reach the skip link before entering that scope.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _contentFocus.dispose();
    _entryFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GalleryShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSlug != widget.activeSlug) _mobileOpen = false;
  }

  void _closeMobile() {
    setState(() => _mobileOpen = false);
    _menuReturnFocus?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final GalleryController controller = GalleryScope.of(context);
    final bool narrow =
        MediaQuery.sizeOf(context).width < CarbonBreakpoint.lg.width;

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        focusNode: _entryFocus,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: (_, KeyEvent event) {
          if (narrow &&
              _mobileOpen &&
              event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            _closeMobile();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: ColoredBox(
          color: theme.background,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Column(
                children: <Widget>[
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: CarbonHeader(
                      menuButton: CarbonHeaderMenuButton(
                        label: 'Toggle navigation',
                        isOpen: narrow ? _mobileOpen : controller.navExpanded,
                        onPressed: narrow
                            ? () {
                                if (_mobileOpen) {
                                  _closeMobile();
                                  return;
                                }
                                _menuReturnFocus =
                                    FocusManager.instance.primaryFocus;
                                setState(() => _mobileOpen = true);
                              }
                            : controller.toggleNav,
                      ),
                      name: CarbonHeaderName(
                        prefix: 'Carbide',
                        name: 'Gallery',
                        onPressed: () => context.go('/'),
                      ),
                      navigation: <Widget>[
                        CarbonHeaderMenuItem(
                          label: 'Overview',
                          selected: widget.activeSlug == null,
                          onPressed: () => context.go('/'),
                        ),
                      ],
                      globalActions: <Widget>[
                        CarbonHeaderGlobalAction(
                          icon: controller.isDark
                              ? CarbonIcons.light
                              : CarbonIcons.asleep,
                          label: 'Switch theme (${controller.theme.label})',
                          onPressed: controller.cycleTheme,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            if (!narrow)
                              FocusTraversalOrder(
                                order: const NumericFocusOrder(2),
                                child: _Nav(
                                  activeSlug: widget.activeSlug,
                                  expanded: controller.navExpanded,
                                ),
                              ),
                            Expanded(
                              key: const ValueKey<String>('gallery-main-slot'),
                              child: FocusTraversalOrder(
                                order: const NumericFocusOrder(3),
                                child: CarbonShellContent(
                                  focusNode: _contentFocus,
                                  // Give untinted text (page/section headings) a sensible,
                                  // theme-aware colour so it stays legible on every theme.
                                  child: DefaultTextStyle.merge(
                                    style: TextStyle(color: theme.textPrimary),
                                    child: SafeArea(
                                      top: false,
                                      child: widget.child,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (narrow && _mobileOpen)
                          Positioned.fill(
                            child: ExcludeSemantics(
                              child: GestureDetector(
                                excludeFromSemantics: true,
                                behavior: HitTestBehavior.opaque,
                                onTap: _closeMobile,
                                child: ColoredBox(color: theme.overlay),
                              ),
                            ),
                          ),
                        if (narrow && _mobileOpen)
                          PositionedDirectional(
                            start: 0,
                            top: 0,
                            bottom: 0,
                            child: FocusTraversalOrder(
                              order: const NumericFocusOrder(2),
                              child: _Nav(
                                activeSlug: widget.activeSlug,
                                expanded: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              PositionedDirectional(
                start: 0,
                top: 0,
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(0),
                  child: CarbonSkipToContent(
                    onPressed: _contentFocus.requestFocus,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.activeSlug, required this.expanded});

  final String? activeSlug;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return CarbonSideNav(
      expanded: expanded,
      // A collapsed nav is a rail: it hover/focus-expands over the content.
      rail: !expanded,
      items: <Widget>[
        CarbonHeaderSideNavItems(
          items: <Widget>[
            CarbonSideNavLink(
              label: 'Overview',
              icon: CarbonIcons.dashboard,
              current: activeSlug == null,
              onPressed: () => context.go('/'),
            ),
          ],
        ),
        const CarbonSideNavDivider(),
        for (final GalleryCategory category in kCatalog)
          CarbonSideNavMenu(
            label: category.title,
            icon: category.icon,
            initiallyExpanded: category.entries.any(
              (GalleryEntry e) => e.slug == activeSlug,
            ),
            children: <Widget>[
              for (final GalleryEntry entry in category.entries)
                CarbonSideNavMenuItem(
                  label: entry.title,
                  current: entry.slug == activeSlug,
                  onPressed: () => context.go(entry.path),
                ),
            ],
          ),
      ],
    );
  }
}
