// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

const List<String> typeaheadLabels = <String>[
  'Start',
  'Écarté',
  'Éditer',
  'Über',
  'Данные',
  '東京',
  '𐐨eseret',
  '١ item',
  'ßort',
  'Export',
  'Xray',
];

void main() {
  final parameters = Uri.base.queryParameters;
  final theme = switch (parameters['theme']) {
    'g10' => CarbonThemeData.gray10,
    'g90' => CarbonThemeData.gray90,
    'g100' => CarbonThemeData.gray100,
    _ => CarbonThemeData.white,
  };
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    typeaheadHost(
      TypeaheadFixture(family: parameters['family'] ?? 'menu'),
      theme: theme,
      direction: parameters['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
    ),
  );
}

Widget typeaheadHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
}) {
  final data = theme ?? CarbonThemeData.white;
  return WidgetsApp(
    color: data.background,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => Directionality(
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

class TypeaheadFixture extends StatefulWidget {
  const TypeaheadFixture({required this.family, super.key});
  final String family;
  @override
  State<TypeaheadFixture> createState() => TypeaheadFixtureState();
}

class TypeaheadFixtureState extends State<TypeaheadFixture> {
  final FocusNode trigger = FocusNode(debugLabel: 'Typeahead trigger');
  String? chosen;
  int changes = 0;
  void _choose(String value) => setState(() {
    chosen = value;
    changes++;
  });
  @override
  void dispose() {
    trigger.dispose();
    super.dispose();
  }

  List<Widget> get _menuItems => <Widget>[
    for (final String label in typeaheadLabels)
      CarbonMenuItem(
        label: label,
        disabled: label == 'Écarté',
        onPressed: () => _choose(label),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final Widget control = switch (widget.family) {
      'select' => CarbonSelect<String>(
        labelText: 'Choose action',
        value: chosen,
        focusNode: trigger,
        onChanged: (String? value) => _choose(value!),
        items: <CarbonSelectItem<String>>[
          for (final String label in typeaheadLabels)
            CarbonSelectItem<String>(
              value: label,
              label: label,
              disabled: label == 'Écarté',
            ),
        ],
      ),
      'dropdown' => CarbonDropdown<String>(
        titleText: 'Choose action',
        selectedItem: chosen,
        focusNode: trigger,
        onChanged: _choose,
        items: <CarbonDropdownItem<String>>[
          for (final String label in typeaheadLabels)
            CarbonDropdownItem<String>(
              value: label,
              label: label,
              disabled: label == 'Écarté',
            ),
        ],
      ),
      'overflow' => CarbonOverflowMenu(
        iconDescription: 'Open actions',
        items: _menuItems,
      ),
      _ => CarbonMenu(children: _menuItems),
    };
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(headingLevel: 1, child: Text('Unicode ${widget.family}')),
            const SizedBox(height: 16),
            Text('Chosen: ${chosen ?? 'none'}; changes: $changes'),
            const SizedBox(height: 24),
            SizedBox(width: 320, child: control),
          ],
        ),
      ),
    );
  }
}
