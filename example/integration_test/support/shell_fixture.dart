// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.
import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/gallery_controller.dart';
import 'package:carbide_gallery/src/gallery_shell.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void main() {
  final Map<String, String> query = Uri.base.queryParameters;
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    ShellFixtureApp(
      themeIndex: int.tryParse(query['theme'] ?? '') ?? 0,
      direction: query['rtl'] == 'true' ? TextDirection.rtl : TextDirection.ltr,
      scale: double.tryParse(query['scale'] ?? '') ?? 1,
    ),
  );
}

/// The actual gallery shell with controlled environment and local destinations.
class ShellFixtureApp extends StatefulWidget {
  /// Creates the persistent shell contract app.
  const ShellFixtureApp({
    super.key,
    this.themeIndex = 0,
    this.direction = TextDirection.ltr,
    this.scale = 1,
    this.width,
  });

  /// Initial theme index in the gallery's four built-in themes.
  final int themeIndex;

  /// Direction used throughout the shell.
  final TextDirection direction;

  /// Text scaling applied below the app's platform MediaQuery.
  final double scale;

  /// Optional constrained viewport for native contracts.
  final double? width;
  @override
  State<ShellFixtureApp> createState() => ShellFixtureAppState();
}

/// An independent router/controller, retaining the real shell implementation.
class ShellFixtureAppState extends State<ShellFixtureApp> {
  final GalleryController _controller = GalleryController();
  double? _width;

  /// Changes the viewport without replacing the routed page.
  void resize(double width) => setState(() => _width = width);
  late final GoRouter _router = GoRouter(
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) =>
            GalleryShell(
              activeSlug: state.pathParameters['slug'],
              child: child,
            ),
        routes: <RouteBase>[
          GoRoute(path: '/', builder: (_, _) => const ShellFixturePage()),
          GoRoute(
            path: '/components/:slug',
            builder: (_, _) => const ShellFixturePage(detail: true),
          ),
        ],
      ),
    ],
  );

  /// Navigates to a local detail route without external effects.
  void detail() => _router.go('/components/button');
  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _controller.selectTheme(widget.themeIndex);
  }

  @override
  void dispose() {
    _router.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GalleryScope(
    controller: _controller,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => CarbonTheme(
        data: _controller.theme.data,
        child: WidgetsApp.router(
          routerConfig: _router,
          color: _controller.theme.data.background,
          builder: (BuildContext context, Widget? child) => Directionality(
            textDirection: widget.direction,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: _width == null ? null : Size(_width!, 900),
                textScaler: TextScaler.linear(widget.scale),
              ),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: _width,
                  child: TapRegionSurface(child: child!),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Stateful content whose draft must survive shell breakpoint changes.
class ShellFixturePage extends StatefulWidget {
  /// Creates local home or detail content.
  const ShellFixturePage({super.key, this.detail = false});

  /// Whether this is the local detail destination.
  final bool detail;
  @override
  State<ShellFixturePage> createState() => ShellFixturePageState();
}

/// Owned editor state and observed pointer/keyboard actions.
class ShellFixturePageState extends State<ShellFixturePage> {
  /// Editor controller, used to verify resize retains the page state.
  final TextEditingController editor = TextEditingController();

  /// Observed content/panel activations.
  int actions = 0;
  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          headingLevel: 1,
          child: Text(widget.detail ? 'Detail workspace' : 'Shell workspace'),
        ),
        const SizedBox(height: 16),
        CarbonTextInput(labelText: 'Editor', controller: editor),
        const SizedBox(height: 16),
        CarbonButton(
          label: 'Increment',
          onPressed: () => setState(() => actions++),
        ),
        Text('Actions: $actions'),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: CarbonHeaderPanel(
            open: true,
            child: CarbonSwitcher(
              children: <Widget>[
                CarbonSwitcherItem(
                  label: 'Cloud',
                  onPressed: () => setState(() => actions++),
                ),
                CarbonSwitcherItem(
                  label: 'Console',
                  selected: true,
                  onPressed: () => setState(() => actions++),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
