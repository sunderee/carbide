// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// A trail with enough ancestor text to guarantee narrow-width collapse.
const List<String> breadcrumbLabels = <String>[
  'Home',
  'Organization',
  'Projects',
  'Research',
  'Reports',
  'Quarter',
  'Here',
];

void main() {
  final Map<String, String> parameters = Uri.base.queryParameters;
  final CarbonThemeData theme = switch (parameters['theme']) {
    'g10' => CarbonThemeData.gray10,
    'g90' => CarbonThemeData.gray90,
    'g100' => CarbonThemeData.gray100,
    _ => CarbonThemeData.white,
  };
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    breadcrumbOverflowHost(
      BreadcrumbOverflowFixture(
        width: double.tryParse(parameters['width'] ?? '') ?? 320,
        noTrailingSlash: parameters['trailing'] != 'true',
        longAnchors: parameters['long'] == 'true',
      ),
      theme: theme,
      direction: parameters['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      scale: double.tryParse(parameters['scale'] ?? '') ?? 1,
    ),
  );
}

/// An independent app host with real overlay and native semantics ownership.
Widget breadcrumbOverflowHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) {
  final CarbonThemeData data = theme ?? CarbonThemeData.white;
  return WidgetsApp(
    color: data.background,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext context, _, _) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: CarbonTheme(
            data: data,
            child: ColoredBox(
              color: data.background,
              child: DefaultTextStyle(
                style: CarbonTypeStyles.body01.copyWith(
                  color: data.textPrimary,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A measurable trail with observed actions and resize controls.
class BreadcrumbOverflowFixture extends StatefulWidget {
  /// Creates a narrow or wide breadcrumb fixture.
  const BreadcrumbOverflowFixture({
    super.key,
    this.width = 320,
    this.noTrailingSlash = true,
    this.longAnchors = false,
  });

  /// The initial available trail width.
  final double width;

  /// Whether to omit the final decorative slash.
  final bool noTrailingSlash;

  /// Whether both retained anchors have deliberately long labels.
  final bool longAnchors;

  @override
  State<BreadcrumbOverflowFixture> createState() =>
      BreadcrumbOverflowFixtureState();
}

/// Mutable width and observed navigation actions for permanent contracts.
class BreadcrumbOverflowFixtureState extends State<BreadcrumbOverflowFixture> {
  late double _width = widget.width;

  /// The number of user navigation callbacks.
  int changes = 0;

  /// The last requested ancestor index, or null before activation.
  int? selected;

  /// Observed activations of the separate callback-link regression.
  int linkChanges = 0;

  bool _linkEnabled = true;
  final FocusNode _linkFocus = FocusNode();

  /// Applies caller-owned focus policy without rebuilding the fixture.
  void linkFocusPolicy({required bool canFocus, required bool skip}) {
    _linkFocus
      ..canRequestFocus = canFocus
      ..skipTraversal = skip;
  }

  @override
  void dispose() {
    _linkFocus.dispose();
    super.dispose();
  }

  /// Changes callback-link operability without recreating its native node.
  void enableLink(bool enabled) => setState(() => _linkEnabled = enabled);

  /// Changes the available width without reporting navigation.
  void resize(double width) => setState(() => _width = width);

  @override
  Widget build(BuildContext context) {
    final List<CarbonBreadcrumbItem> items = <CarbonBreadcrumbItem>[
      for (int i = 0; i < breadcrumbLabels.length; i++)
        CarbonBreadcrumbItem(
          label: widget.longAnchors && i == 0
              ? 'Very long organization home'
              : widget.longAnchors && i == breadcrumbLabels.length - 1
              ? 'Very long current report name'
              : breadcrumbLabels[i],
          isCurrentPage: i == breadcrumbLabels.length - 1,
          onPressed: () => setState(() {
            changes++;
            selected = i;
          }),
        ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(headingLevel: 1, child: const Text('Breadcrumb overflow')),
          const SizedBox(height: 16),
          Text('Changes: $changes; selected: ${selected ?? 'none'}'),
          const SizedBox(height: 24),
          SizedBox(
            width: _width,
            child: CarbonBreadcrumb(
              items: items,
              noTrailingSlash: widget.noTrailingSlash,
            ),
          ),
          const SizedBox(height: 32),
          CarbonButton(label: 'Use wide trail', onPressed: () => resize(1500)),
          const SizedBox(height: 16),
          CarbonButton(label: 'Use narrow trail', onPressed: () => resize(160)),
          const SizedBox(height: 16),
          CarbonLink(
            label: 'Standalone link',
            focusNode: _linkFocus,
            onPressed: _linkEnabled
                ? () => setState(() => linkChanges++)
                : null,
          ),
          Text('Link changes: $linkChanges'),
          const SizedBox(height: 16),
          CarbonButton(
            label: _linkEnabled
                ? 'Disable standalone link'
                : 'Enable standalone link',
            onPressed: () => enableLink(!_linkEnabled),
          ),
        ],
      ),
    );
  }
}
