// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

void main() {
  final Map<String, String> parameters = Uri.base.queryParameters;
  final CarbonGridMode mode = CarbonGridMode.values.firstWhere(
    (CarbonGridMode mode) => mode.name == (parameters['mode'] ?? 'wide'),
  );
  final CarbonThemeData theme = switch (parameters['theme']) {
    'g10' => CarbonThemeData.gray10,
    'g90' => CarbonThemeData.gray90,
    'g100' => CarbonThemeData.gray100,
    _ => CarbonThemeData.white,
  };
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    gridGuttersHost(
      GridGuttersFixture(
        mode: mode,
        fullWidth: parameters['full'] == 'true',
        nested: parameters['nested'] == 'true',
      ),
      theme: theme,
      direction: parameters['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
    ),
  );
}

/// A real app host for native bounds and responsive viewport contracts.
Widget gridGuttersHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) {
  final CarbonThemeData data = theme ?? CarbonThemeData.white;
  return WidgetsApp(
    color: data.background,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext context, _, _) => Directionality(
        textDirection: direction,
        child: CarbonTheme(
          data: data,
          child: ColoredBox(
            color: data.background,
            child: DefaultTextStyle(
              style: CarbonTypeStyles.body01.copyWith(color: data.textPrimary),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Static geometry fixture whose identifiers expose real native DOM bounds.
class GridGuttersFixture extends StatelessWidget {
  /// Creates a gutter/multi-row fixture, with optional nested narrow content.
  const GridGuttersFixture({
    required this.mode,
    super.key,
    this.fullWidth = false,
    this.nested = false,
    this.gridWidth,
  });

  /// The column gutter policy.
  final CarbonGridMode mode;

  /// Whether to omit the independent responsive outer margin.
  final bool fullWidth;

  /// Whether the first column also contains a full-width nested narrow grid.
  final bool nested;

  /// Optional fixed grid width for integration runs; manual runs use viewport.
  final double? gridWidth;

  Widget _cell(BuildContext context, String id) => Semantics(
    container: true,
    identifier: id,
    label: id,
    child: ExcludeSemantics(
      child: SizedBox(
        height: 48,
        child: ColoredBox(color: CarbonTheme.of(context).layerAccent01),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(headingLevel: 1, child: Text('Grid ${mode.name}')),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double width = gridWidth ?? constraints.maxWidth;
            return SizedBox(
              width: width,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                identifier: 'grid-parent',
                label: 'Grid area',
                child: CarbonGrid(
                  mode: mode,
                  fullWidth: fullWidth,
                  rowSpacing: 8,
                  children: <Widget>[
                    for (int i = 0; i < 6; i++)
                      CarbonColumn(
                        sm: 2,
                        md: 4,
                        lg: 8,
                        child: i == 0 && nested
                            ? Semantics(
                                container: true,
                                identifier: 'grid-cell-0',
                                label: 'Nested area',
                                child: CarbonGrid(
                                  mode: CarbonGridMode.narrow,
                                  fullWidth: true,
                                  children: <Widget>[
                                    CarbonColumn(
                                      child: _cell(context, 'grid-nested-leaf'),
                                    ),
                                  ],
                                ),
                              )
                            : _cell(context, 'grid-cell-$i'),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
