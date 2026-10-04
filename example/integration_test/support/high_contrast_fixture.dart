// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:convert';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import 'high_contrast_specimen.dart';

void main() {
  final params = Uri.base.queryParameters;
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    highContrastHost(
      HighContrastFixture(
        textScale: double.tryParse(params['scale'] ?? '') ?? 1,
      ),
      direction: params['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      theme: switch (params['theme']) {
        'g10' => CarbonThemeData.gray10,
        'g90' => CarbonThemeData.gray90,
        'g100' => CarbonThemeData.gray100,
        _ => CarbonThemeData.white,
      },
    ),
  );
}

Widget highContrastHost(
  Widget child, {
  required CarbonThemeData theme,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: theme.background,
  onGenerateRoute: (_) => PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    pageBuilder: (_, _, _) => Directionality(
      textDirection: direction,
      child: CarbonTheme(
        data: theme,
        child: ColoredBox(color: theme.background, child: child),
      ),
    ),
  ),
);

class HighContrastFixture extends StatefulWidget {
  const HighContrastFixture({super.key, this.textScale = 1});
  final double textScale;

  @override
  State<HighContrastFixture> createState() => HighContrastFixtureState();
}

class HighContrastFixtureState extends State<HighContrastFixture> {
  final specimen = GlobalKey<HighContrastSpecimenState>();
  bool? preferenceOverride;
  int activations = 0;
  int sequence = 0;
  late CarbonThemeData resolved;

  void setPreference(bool? value) => setState(() => preferenceOverride = value);

  Map<String, String> _editorValues() {
    final values = <String, String>{};
    void visit(Element element, String? label) {
      final widget = element.widget;
      if (widget is CarbonTextInput) label = widget.labelText;
      if (widget is EditableText && label != null) {
        values[label] = widget.controller.text;
      }
      element.visitChildren((child) => visit(child, label));
    }

    final context = specimen.currentContext;
    if (context != null) visit(context as Element, null);
    return values;
  }

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      highContrast: preferenceOverride,
      textScaler: TextScaler.linear(widget.textScale),
    ),
    child: Builder(
      builder: (context) {
        resolved = CarbonTheme.of(context);
        final snapshot = jsonEncode({
          'sequence': sequence,
          'highContrast': MediaQuery.highContrastOf(context),
          'boundary': resolved.borderSubtle00.toARGB32(),
          'disabled': resolved.textDisabled.toARGB32(),
          'focus': resolved.focus.toARGB32(),
          'background': resolved.background.toARGB32(),
          'buttonDisabled': resolved.buttonDisabled.toARGB32(),
          'activations': activations,
          'values': _editorValues(),
        });
        return DefaultTextStyle(
          style: CarbonTypeStyles.body01.copyWith(color: resolved.textPrimary),
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Contrast preference: ${MediaQuery.highContrastOf(context) ? 'high' : 'normal'}',
                      ),
                    ),
                    Semantics(
                      identifier: 'contrast-snapshot',
                      label: snapshot,
                      excludeSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          snapshot,
                          style: TextStyle(
                            fontSize: 12,
                            color: resolved.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CarbonButton(
                        label: 'Capture contrast',
                        onPressed: () => setState(() => sequence++),
                      ),
                    ),
                    HighContrastSpecimen(
                      key: specimen,
                      onPressed: () => setState(() => activations++),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
