// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum KeyboardPickerKind { dropdown, select, combo, multi, filteredMulti }

class KeyboardChoice {
  const KeyboardChoice(this.value, this.label, {this.disabled = false});

  final String value;
  final String label;
  final bool disabled;
}

const List<KeyboardChoice> keyboardChoices = <KeyboardChoice>[
  KeyboardChoice('a', 'Alpha'),
  KeyboardChoice('b', 'Beta'),
  KeyboardChoice('c', 'Charlie'),
];

class PickerAncestorIntent extends Intent {
  const PickerAncestorIntent(this.key);

  final LogicalKeyboardKey key;
}

class PickerKeyboardFixture extends StatefulWidget {
  const PickerKeyboardFixture({
    required this.kind,
    this.grouped = false,
    this.provideAncestorShortcuts = true,
    super.key,
  });

  final KeyboardPickerKind kind;
  final bool grouped;
  final bool provideAncestorShortcuts;

  @override
  State<PickerKeyboardFixture> createState() => PickerKeyboardFixtureState();
}

class PickerKeyboardFixtureState extends State<PickerKeyboardFixture> {
  final FocusNode focus = FocusNode(debugLabel: 'Keyboard picker');
  final Map<LogicalKeyboardKey, int> ancestorCalls =
      <LogicalKeyboardKey, int>{};
  List<KeyboardChoice> choices = keyboardChoices;
  String? value = 'b';
  Set<String> selected = <String>{'b'};
  bool readOnly = false;
  bool disabled = false;
  int changes = 0;

  int calls(LogicalKeyboardKey key) => ancestorCalls[key] ?? 0;

  void configure({
    List<KeyboardChoice>? choices,
    String? value,
    bool clearValue = false,
    bool? readOnly,
    bool? disabled,
  }) => setState(() {
    if (choices != null) this.choices = choices;
    if (clearValue || value != null) this.value = value;
    if (readOnly != null) this.readOnly = readOnly;
    if (disabled != null) this.disabled = disabled;
  });

  void _single(String? next) => setState(() {
    changes++;
    value = next;
  });

  void _multiple(Set<String> next) => setState(() {
    changes++;
    selected = next;
  });

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<CarbonSelectItem<String>> selectItems =
        <CarbonSelectItem<String>>[
          for (final KeyboardChoice item in choices)
            CarbonSelectItem(
              value: item.value,
              label: item.label,
              disabled: item.disabled,
            ),
        ];
    final Widget picker = switch (widget.kind) {
      KeyboardPickerKind.dropdown => CarbonDropdown<String>(
        titleText: 'Field',
        items: <CarbonDropdownItem<String>>[
          for (final KeyboardChoice item in choices)
            CarbonDropdownItem(
              value: item.value,
              label: item.label,
              disabled: item.disabled,
            ),
        ],
        selectedItem: value,
        focusNode: focus,
        readOnly: readOnly,
        disabled: disabled,
        onChanged: _single,
      ),
      KeyboardPickerKind.select => CarbonSelect<String>(
        labelText: 'Field',
        items: widget.grouped
            ? <CarbonSelectEntry<String>>[
                CarbonSelectItemGroup(label: 'Group', items: selectItems),
              ]
            : selectItems,
        value: value,
        focusNode: focus,
        readOnly: readOnly,
        disabled: disabled,
        onChanged: _single,
      ),
      KeyboardPickerKind.combo => CarbonComboBox<String>(
        titleText: 'Field',
        items: <CarbonComboBoxItem<String>>[
          for (final KeyboardChoice item in choices)
            CarbonComboBoxItem(
              value: item.value,
              label: item.label,
              disabled: item.disabled,
            ),
        ],
        selectedItem: value,
        focusNode: focus,
        readOnly: readOnly,
        disabled: disabled,
        onChanged: _single,
      ),
      KeyboardPickerKind.multi ||
      KeyboardPickerKind.filteredMulti => CarbonMultiSelect<String>(
        titleText: 'Field',
        label: 'Choose',
        filterable: widget.kind == KeyboardPickerKind.filteredMulti,
        items: <CarbonMultiSelectItem<String>>[
          for (final KeyboardChoice item in choices)
            CarbonMultiSelectItem(
              value: item.value,
              label: item.label,
              disabled: item.disabled,
            ),
        ],
        selectedValues: selected,
        focusNode: focus,
        readOnly: readOnly,
        disabled: disabled,
        onChanged: _multiple,
      ),
    };
    if (!widget.provideAncestorShortcuts) return picker;
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
          LogicalKeyboardKey.enter,
          LogicalKeyboardKey.escape,
          LogicalKeyboardKey.space,
          LogicalKeyboardKey.arrowDown,
          LogicalKeyboardKey.arrowUp,
          LogicalKeyboardKey.f8,
        ])
          SingleActivator(key): PickerAncestorIntent(key),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          PickerAncestorIntent: CallbackAction<PickerAncestorIntent>(
            onInvoke: (intent) {
              ancestorCalls.update(
                intent.key,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
              return null;
            },
          ),
        },
        child: picker,
      ),
    );
  }
}
