// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

enum PickerKind {
  dropdown,
  select,
  combo,
  multi,
  filteredMulti,
  search,
  expandableSearch,
  date,
  range;

  bool get hasPopup => this != search && this != expandableSearch;
}

class PickerFixture extends StatefulWidget {
  const PickerFixture({
    required this.kind,
    this.readOnly = true,
    this.disabled = false,
    this.callback = true,
    this.fluid = false,
    super.key,
  });
  final PickerKind kind;
  final bool readOnly;
  final bool disabled;
  final bool callback;
  final bool fluid;
  @override
  State<PickerFixture> createState() => PickerFixtureState();
}

class PickerFixtureState extends State<PickerFixture> {
  late bool readOnly = widget.readOnly;
  late bool disabled = widget.disabled;
  late bool callback = widget.callback;
  int changes = 0;
  int clears = 0;
  int inputs = 0;
  String chosen = 'b';
  Set<String> selected = <String>{'b'};
  final TextEditingController query = TextEditingController(
    text: 'Retained query',
  );
  final FocusNode focus = FocusNode();
  final DateTime date = DateTime(2026, 1, 2);
  String get announcedValue => switch (widget.kind) {
    PickerKind.search || PickerKind.expandableSearch => 'Retained query',
    PickerKind.date || PickerKind.range => '01/02/2026',
    _ => 'Beta',
  };
  void configure({
    bool? readOnly,
    bool? disabled,
    bool? callback,
    Set<String>? selected,
  }) => setState(() {
    if (readOnly != null) this.readOnly = readOnly;
    if (disabled != null) this.disabled = disabled;
    if (callback != null) this.callback = callback;
    if (selected != null) this.selected = selected;
  });
  @override
  void dispose() {
    query.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.kind) {
    PickerKind.dropdown => CarbonDropdown<String>(
      titleText: 'Field',
      selectedItem: chosen,
      focusNode: focus,
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      onChanged: callback ? (_) => changes++ : null,
      items: const <CarbonDropdownItem<String>>[
        CarbonDropdownItem(value: 'a', label: 'Alpha'),
        CarbonDropdownItem(value: 'b', label: 'Beta'),
      ],
    ),
    PickerKind.select => CarbonSelect<String>(
      labelText: 'Field',
      value: chosen,
      focusNode: focus,
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      onChanged: callback ? (_) => changes++ : null,
      items: const <CarbonSelectItem<String>>[
        CarbonSelectItem(value: 'a', label: 'Alpha'),
        CarbonSelectItem(value: 'b', label: 'Beta'),
      ],
    ),
    PickerKind.combo => CarbonComboBox<String>(
      titleText: 'Field',
      selectedItem: chosen,
      focusNode: focus,
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      onChanged: callback ? (_) => changes++ : null,
      onInputChange: (_) => inputs++,
      items: const <CarbonComboBoxItem<String>>[
        CarbonComboBoxItem(value: 'a', label: 'Alpha'),
        CarbonComboBoxItem(value: 'b', label: 'Beta'),
      ],
    ),
    PickerKind.multi || PickerKind.filteredMulti => CarbonMultiSelect<String>(
      titleText: 'Field',
      label: 'Choose options',
      selectedValues: selected,
      focusNode: focus,
      filterable: widget.kind == PickerKind.filteredMulti,
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      onChanged: callback ? (_) => changes++ : null,
      items: const <CarbonMultiSelectItem<String>>[
        CarbonMultiSelectItem(value: 'a', label: 'Alpha'),
        CarbonMultiSelectItem(value: 'b', label: 'Beta'),
      ],
    ),
    PickerKind.search => CarbonSearch(
      labelText: 'Field',
      controller: query,
      focusNode: focus,
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      onChanged: callback ? (_) => changes++ : null,
      onClear: () => clears++,
    ),
    PickerKind.expandableSearch => CarbonExpandableSearch(
      labelText: 'Field',
      controller: query,
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      onChanged: (_) => changes++,
      onClear: () => clears++,
    ),
    PickerKind.date => CarbonDatePicker(
      labelText: 'Field',
      value: date,
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      fluid: widget.fluid,
      onChanged: (_) => changes++,
    ),
    PickerKind.range => CarbonDateRangePicker(
      startLabelText: 'Field',
      endLabelText: 'Field end',
      value: CarbonDateRange(date, DateTime(2026, 1, 5)),
      readOnly: readOnly,
      readOnlyHint: 'Nur lesen',
      disabled: disabled,
      fluid: widget.fluid,
      onChanged: (_) => changes++,
    ),
  };
}
