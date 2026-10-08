// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// Full title retained in semantics even when visually ellipsized.
const String pageHeaderTitle =
    'Quarterly report with a deliberately long title';

void main() {
  final Map<String, String> query = Uri.base.queryParameters;
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    pageHeaderHost(
      const PageHeaderFixture(),
      direction: query['rtl'] == 'true' ? TextDirection.rtl : TextDirection.ltr,
      scale: double.tryParse(query['scale'] ?? '') ?? 1,
      theme: switch (query['theme']) {
        'g10' => CarbonThemeData.gray10,
        'g90' => CarbonThemeData.gray90,
        'g100' => CarbonThemeData.gray100,
        _ => CarbonThemeData.white,
      },
    ),
  );
}

/// An independent native semantics, focus and overlay host.
Widget pageHeaderHost(
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

/// Mutable hierarchy and observed actions, without replacing the page header.
class PageHeaderFixture extends StatefulWidget {
  /// Creates the heading fixture.
  const PageHeaderFixture({super.key});
  @override
  State<PageHeaderFixture> createState() => PageHeaderFixtureState();
}

/// Heading updates and an independently focused editor for native contracts.
class PageHeaderFixtureState extends State<PageHeaderFixture> {
  /// Caller-owned editor focus; heading updates must preserve it.
  final FocusNode editorFocus = FocusNode();
  int _level = 1;

  /// Observed page-action invocations.
  int actions = 0;

  /// Applies a hierarchy change without invoking an action.
  void setHeadingLevel(int level) => setState(() => _level = level);

  @override
  void dispose() {
    editorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Page heading validation'),
        Text('Actions: $actions'),
        const SizedBox(height: 16),
        SizedBox(
          width: 320,
          child: CarbonPageHeader(
            title: pageHeaderTitle,
            headingLevel: _level,
            subtitle: 'Finance',
            body: 'Revenue and spend.',
            pageActions: CarbonButton(
              label: 'Edit report',
              onPressed: () => setState(() => actions++),
            ),
          ),
        ),
        const SizedBox(height: 16),
        CarbonTextInput(labelText: 'Keep editing', focusNode: editorFocus),
        const SizedBox(height: 16),
        CarbonButton(
          label: 'Next heading level',
          onPressed: () => setHeadingLevel(_level % 6 + 1),
        ),
        Text('Level: $_level'),
      ],
    ),
  );
}
