// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'catalog.dart';
import 'gallery_controller.dart';
import 'gallery_shell.dart';
import 'pages/overview_page.dart';
import 'registry.dart';

/// The root of the Carbide gallery. Owns the [GalleryController], the router,
/// and the animated theme — all with no Material in sight.
class GalleryApp extends StatefulWidget {
  /// Creates the gallery app root.
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  final GalleryController _controller = GalleryController();
  late final GoRouter _router = _buildRouter();

  GoRouter _buildRouter() {
    return GoRouter(
      routes: <RouteBase>[
        ShellRoute(
          builder: (BuildContext context, GoRouterState state, Widget child) {
            final String? slug = state.pathParameters['slug'];
            return GalleryShell(activeSlug: slug, child: child);
          },
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              builder: (BuildContext context, GoRouterState state) =>
                  const OverviewPage(),
            ),
            GoRoute(
              path: '/components/:slug',
              builder: (BuildContext context, GoRouterState state) {
                final String slug = state.pathParameters['slug'] ?? '';
                final GalleryEntry? entry = entryForSlug(kCatalog, slug);
                return entry?.builder() ?? const _NotFound();
              },
            ),
          ],
        ),
      ],
      errorBuilder: (BuildContext context, GoRouterState state) =>
          const GalleryShell(activeSlug: null, child: _NotFound()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GalleryScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          return AnimatedCarbonTheme(
            data: _controller.theme.data,
            duration: CarbonDuration.fast02,
            curve: CarbonEasing.standardProductive,
            child: WidgetsApp.router(
              routerConfig: _router,
              title: 'Carbide Gallery',
              color: _controller.theme.data.background,
              debugShowCheckedModeBanner: false,
              builder: (BuildContext context, Widget? child) {
                // A TapRegionSurface lets Carbide popovers/menus/modals close
                // on an outside tap; it must sit above the router's Overlay.
                return TapRegionSurface(
                  child: child ?? const SizedBox.shrink(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Center(
      child: Text(
        'Page not found',
        style: CarbonTypeStyles.productiveHeading04.copyWith(
          color: theme.textPrimary,
        ),
      ),
    );
  }
}
