// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'catalog.dart';
import 'gallery_controller.dart';
import 'registry.dart';

/// The persistent UI Shell — header, side navigation and content region — that
/// frames every page. [activeSlug] highlights the current entry (`null` on the
/// overview route).
class GalleryShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final GalleryController controller = GalleryScope.of(context);

    return ColoredBox(
      color: theme.background,
      child: Column(
        children: <Widget>[
          CarbonHeader(
            menuButton: CarbonHeaderMenuButton(
              label: 'Toggle navigation',
              isOpen: controller.navExpanded,
              onPressed: controller.toggleNav,
            ),
            name: GestureDetector(
              onTap: () => context.go('/'),
              child: const CarbonHeaderName(prefix: 'Carbide', name: 'Gallery'),
            ),
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
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _Nav(activeSlug: activeSlug, expanded: controller.navExpanded),
                Expanded(
                  child: CarbonShellContent(
                    // Give untinted text (page/section headings) a sensible,
                    // theme-aware colour so it stays legible on every theme.
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: theme.textPrimary),
                      child: SafeArea(top: false, child: child),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        CarbonSideNavLink(
          label: 'Overview',
          icon: CarbonIcons.dashboard,
          current: activeSlug == null,
          onPressed: () => context.go('/'),
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
