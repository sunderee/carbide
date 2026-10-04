// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final query = Uri.base.queryParameters;
  runApp(
    staticSemanticsHost(
      const StaticSemanticsFixture(),
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

Widget staticSemanticsHost(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  CarbonThemeData? theme,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (_, _, _) => child,
  ),
  builder: (_, navigator) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: CarbonTheme(
        data: theme ?? CarbonThemeData.white,
        child: navigator!,
      ),
    ),
  ),
);

class StaticSemanticsFixture extends StatefulWidget {
  const StaticSemanticsFixture({super.key});
  @override
  State<StaticSemanticsFixture> createState() => StaticSemanticsFixtureState();
}

class StaticSemanticsFixtureState extends State<StaticSemanticsFixture> {
  int copies = 0;
  int activations = 0;
  void copied() => setState(() => copies++);

  @override
  Widget build(BuildContext context) {
    final theme = CarbonTheme.of(context);
    return ColoredBox(
      color: theme.background,
      child: DefaultTextStyle(
        style: CarbonTypeStyles.body01.copyWith(color: theme.textPrimary),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Copies: $copies; activations: $activations'),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 12,
                  children: [
                    CarbonTag(label: 'Active', icon: CarbonIcons.checkmark),
                    CarbonTag(
                      label: 'A deliberately long complete status label',
                      disabled: true,
                    ),
                    ExcludeSemantics(child: CarbonTag(label: 'Decorative')),
                  ],
                ),
                const SizedBox(height: 16),
                const CarbonOrderedList(
                  children: [
                    CarbonListItem(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Parent'),
                          CarbonOrderedList(
                            children: [
                              CarbonListItem(child: Text('Nested Alpha')),
                              CarbonListItem(child: Text('Nested Beta')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    CarbonListItem(child: Text('Sibling')),
                  ],
                ),
                CarbonUnorderedList(
                  children: [
                    const CarbonListItem(child: Text('Plain bullet')),
                    CarbonListItem(
                      child: CarbonButton(
                        label: 'Open record',
                        onPressed: () => setState(() => activations++),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final type in CarbonCodeSnippetType.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(
                      role: SemanticsRole.region,
                      container: true,
                      explicitChildNodes: true,
                      label: 'Code example ${type.name}',
                      child: CarbonCodeSnippet(
                        code: switch (type) {
                          CarbonCodeSnippetType.inline => 'npm install carbide',
                          CarbonCodeSnippetType.single =>
                            'flutter pub add carbide',
                          CarbonCodeSnippetType.multi =>
                            'first();\nsecond();\nthird();',
                        },
                        type: type,
                        copyLabel: 'Copy ${type.name}',
                        feedbackTimeout: const Duration(milliseconds: 100),
                        maxCollapsedRows: 1,
                        onCopy: copied,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
