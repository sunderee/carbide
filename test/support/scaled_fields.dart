// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// Actual field/menu compositions for closed/open scaling regressions and
/// browser validation. Small chrome, descenders and fluid label/value stacks
/// expose constraints that default medium, empty fields do not.
Map<String, WidgetBuilder> scaledFieldSpecimens({
  CarbonFieldSize size = CarbonFieldSize.sm,
  bool fluid = false,
}) => <String, WidgetBuilder>{
  'search': (_) => CarbonSearch(
    labelText: 'Search',
    initialValue: 'gypy',
    size: size,
    fluid: fluid,
  ),
  'combo box': (_) => CarbonComboBox<int>(
    titleText: 'City',
    placeholder: 'gypy',
    size: size,
    fluid: fluid,
    items: <CarbonComboBoxItem<int>>[
      for (int n = 0; n < 10; n++)
        CarbonComboBoxItem<int>(value: n, label: 'gypy $n'),
    ],
    onChanged: (int? _) {},
  ),
  'multi select': (_) => CarbonMultiSelect<int>(
    titleText: 'Cities',
    label: 'gypy',
    size: size,
    fluid: fluid,
    selectedValues: const <int>{0, 1},
    items: <CarbonMultiSelectItem<int>>[
      for (int n = 0; n < 10; n++)
        CarbonMultiSelectItem<int>(value: n, label: 'gypy $n'),
    ],
    onChanged: (Set<int> _) {},
  ),
  'filterable multi select': (_) => CarbonMultiSelect<int>(
    titleText: 'Cities',
    label: 'gypy',
    filterable: true,
    fluid: fluid,
    size: size,
    selectedValues: const <int>{0, 1},
    items: <CarbonMultiSelectItem<int>>[
      for (int n = 0; n < 10; n++)
        CarbonMultiSelectItem<int>(value: n, label: 'gypy $n'),
    ],
    onChanged: (Set<int> _) {},
  ),
  'dropdown': (_) => CarbonDropdown<int>(
    titleText: 'City',
    selectedItem: 0,
    size: size,
    fluid: fluid,
    items: <CarbonDropdownItem<int>>[
      for (int n = 0; n < 10; n++)
        CarbonDropdownItem<int>(value: n, label: 'gypy $n'),
    ],
    onChanged: (int _) {},
  ),
  'select': (_) => CarbonSelect<int>(
    labelText: 'City',
    value: 0,
    size: size,
    fluid: fluid,
    items: <CarbonSelectItem<int>>[
      for (int n = 0; n < 10; n++)
        CarbonSelectItem<int>(value: n, label: 'gypy $n'),
    ],
    onChanged: (int? _) {},
  ),
  'number input': (_) => CarbonNumberInput(
    labelText: 'Quantity',
    value: 3,
    size: size,
    fluid: fluid,
    min: 0,
    max: 10,
    onChanged: (num? _) {},
  ),
  'time picker': (_) => CarbonTimePicker(
    labelText: 'Time',
    initialValue: '12:00',
    size: size,
    fluid: fluid,
    children: <Widget>[
      CarbonTimePickerSelect<String>(
        labelText: 'Period',
        width: 128,
        value: 'AM',
        size: size,
        fluid: fluid,
        items: const <CarbonSelectItem<String>>[
          CarbonSelectItem<String>(value: 'AM', label: 'AM'),
          CarbonSelectItem<String>(value: 'PM', label: 'PM'),
        ],
        onChanged: (String? _) {},
      ),
    ],
  ),
  'list box': (_) => CarbonListBox(
    size: size,
    fluid: fluid,
    fluidLabel: fluid ? 'City' : null,
    child: const Text('gypy'),
  ),
  'menu': (_) => CarbonMenu(
    size: CarbonMenuSize.sm,
    autofocus: false,
    children: <Widget>[
      CarbonMenuItem(label: 'gypy document', onPressed: () {}),
      CarbonMenuItem(label: 'Close document', onPressed: () {}),
    ],
  ),
};
