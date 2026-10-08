// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0; see LICENSE.

import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';
import '../support/specimens.dart';

typedef _Builder = Widget Function(bool disabled, bool readOnly);

final Map<String, _Builder> _fields = <String, _Builder>{
  'text_input': (d, r) =>
      CarbonTextInput(labelText: 'Example', disabled: d, readOnly: r),
  'text_area': (d, r) =>
      CarbonTextArea(labelText: 'Example', disabled: d, readOnly: r),
  'number_input': (d, r) => CarbonNumberInput(
    labelText: 'Example',
    value: 2,
    disabled: d,
    readOnly: r,
    onChanged: (_) {},
  ),
  'search': (d, r) =>
      CarbonSearch(labelText: 'Example', disabled: d, readOnly: r),
  'time_picker': (d, r) =>
      CarbonTimePicker(labelText: 'Example', disabled: d, readOnly: r),
  'select': (d, r) => CarbonSelect<int>(
    labelText: 'Example',
    disabled: d,
    readOnly: r,
    value: 1,
    items: const <CarbonSelectItem<int>>[
      CarbonSelectItem(value: 1, label: 'One'),
    ],
    onChanged: (_) {},
  ),
  'dropdown': (d, r) => CarbonDropdown<int>(
    titleText: 'Example',
    disabled: d,
    readOnly: r,
    selectedItem: 1,
    items: const <CarbonDropdownItem<int>>[
      CarbonDropdownItem(value: 1, label: 'One'),
    ],
    onChanged: (_) {},
  ),
  'combo_box': (d, r) => CarbonComboBox<int>(
    titleText: 'Example',
    disabled: d,
    readOnly: r,
    items: const <CarbonComboBoxItem<int>>[
      CarbonComboBoxItem(value: 1, label: 'One'),
    ],
    onChanged: (_) {},
  ),
  'multi_select': (d, r) => CarbonMultiSelect<int>(
    titleText: 'Example',
    label: 'Choose',
    disabled: d,
    readOnly: r,
    items: const <CarbonMultiSelectItem<int>>[
      CarbonMultiSelectItem(value: 1, label: 'One'),
    ],
    onChanged: (_) {},
  ),
  'date_picker': (d, r) => CarbonDatePicker(
    labelText: 'Example',
    disabled: d,
    readOnly: r,
    onChanged: (_) {},
  ),
  'checkbox': (d, r) => CarbonCheckbox(
    label: 'Example',
    value: true,
    disabled: d,
    readOnly: r,
    onChanged: (_) {},
  ),
  'radio_button': (d, r) => CarbonRadioButtonGroup<int>(
    legend: 'Example',
    value: 1,
    options: const <(int, String)>[(1, 'One'), (2, 'Two')],
    disabled: d,
    readOnly: r,
    onChanged: (_) {},
  ),
  'toggle': (d, r) => CarbonToggle(
    labelText: 'Example',
    toggled: true,
    disabled: d,
    readOnly: r,
    onToggled: (_) {},
  ),
  'slider': (d, r) => CarbonSlider(
    labelText: 'Example',
    value: 2,
    min: 0,
    max: 10,
    disabled: d,
    readOnly: r,
    onChanged: (_) {},
  ),
};

final Map<String, Widget Function(bool)> _controls =
    <String, Widget Function(bool)>{
      'button': (d) =>
          CarbonButton(label: 'Example', onPressed: d ? null : () {}),
      'icon_button': (d) => CarbonIconButton(
        icon: CarbonIcons.add,
        label: 'Example',
        onPressed: d ? null : () {},
      ),
      'button icon-only': (d) => CarbonButton.iconOnly(
        icon: CarbonIcons.add,
        iconDescription: 'Example',
        onPressed: d ? null : () {},
      ),
      'content_switcher': (d) => CarbonContentSwitcher(
        selectedIndex: 0,
        onChanged: (_) {},
        switches: <CarbonSwitch>[
          CarbonSwitch(
            icon: CarbonIcons.list,
            semanticLabel: 'Example',
            disabled: d,
          ),
          CarbonSwitch(
            icon: CarbonIcons.grid,
            semanticLabel: 'Grid view',
            disabled: d,
          ),
        ],
      ),
      'ui_shell': (d) => CarbonHeader(
        name: const CarbonHeaderName(name: 'Carbide'),
        globalActions: <Widget>[
          CarbonHeaderGlobalAction(
            icon: CarbonIcons.settings,
            label: 'Example',
            onPressed: d ? null : () {},
          ),
        ],
      ),
      'list_box': (d) => CarbonListBox(
        disabled: d,
        size: CarbonFieldSize.lg,
        onTap: d ? null : () {},
        child: const Text('Example'),
      ),
      'utils': (d) => Semantics(
        label: 'Example',
        button: true,
        child: CarbonInteraction(
          enabled: !d,
          onPressed: () {},
          builder: (_, _) => const SizedBox(width: 48, height: 48),
        ),
      ),
    };

List<SemanticsData> _data(WidgetTester tester) => <SemanticsData>[
  for (final SemanticsNode node
      in tester.semantics.simulatedAccessibilityTraversal())
    node.getSemanticsData(),
];

void main() {
  for (final entry in _fields.entries) {
    for (final state in <String>['default', 'disabled', 'readOnly']) {
      testWidgets('${entry.key}: $state has guidelines and mutation policy', (
        tester,
      ) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            carbideSpecimenHost(
              child: SizedBox(
                width: 420,
                child: entry.value(state == 'disabled', state == 'readOnly'),
              ),
            ),
          );
          await tester.pump();
          // Default Carbon field densities are 40px; checkbox/radio/toggle
          // visuals are 16/18/24px. These compact upstream sizes retain the
          // label gate. Component lg-density suites retain the 48dp gate.
          // a11y-exception: https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/styles/scss/components/text-input/_text-input.scss
          // a11y-exception: https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/styles/scss/components/checkbox/_checkbox.scss
          // a11y-exception: https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/styles/scss/components/radio-button/_radio-button.scss
          // a11y-exception: https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/styles/scss/components/toggle/_toggle.scss
          await expectA11y(tester, tapTargets: false);
          final bool editable = <String>{
            'text_input',
            'text_area',
            'search',
            'time_picker',
            'number_input',
          }.contains(entry.key);
          // Flutter exposes setText only once an editor is focused. Read-only
          // editors may retain focus for selection, while omitting setText.
          if (editable && state != 'disabled') {
            tester.binding.handleViewFocusChanged(
              ViewFocusEvent(
                viewId: tester.view.viewId,
                state: ViewFocusState.focused,
                direction: ViewFocusDirection.undefined,
              ),
            );
            tester
                .widget<EditableText>(find.byType(EditableText).first)
                .focusNode
                .requestFocus();
            await tester.pump();
          }
          final List<SemanticsData> data = _data(tester);
          expect(data.any((node) => node.label.contains('Example')), isTrue);
          if (editable) {
            final EditableText editor = tester.widget<EditableText>(
              find.byType(EditableText).first,
            );
            expect(editor.readOnly, state != 'default');
            if (state == 'default') {
              await tester.enterText(
                find.byType(EditableText).first,
                'Changed',
              );
              await tester.pump();
              expect(editor.controller.text, 'Changed');
            } else {
              expect(
                data.any((node) => node.hasAction(SemanticsAction.setText)),
                isFalse,
              );
            }
          } else {
            final bool canMutate = data.any(
              (node) => <SemanticsAction>[
                SemanticsAction.tap,
                SemanticsAction.increase,
                SemanticsAction.decrease,
              ].any(node.hasAction),
            );
            expect(
              canMutate,
              state == 'default',
              reason: 'Guidelines alone cannot detect a missing action.',
            );
          }
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          handle.dispose();
        }
      });
    }
  }
  for (final entry in _controls.entries) {
    for (final bool disabled in <bool>[false, true]) {
      testWidgets(
        '${entry.key}: disabled=$disabled exposes activation policy',
        (tester) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              carbideSpecimenHost(
                child: SizedBox(width: 760, child: entry.value(disabled)),
              ),
            );
            await tester.pump();
            await expectA11y(tester);
            final List<SemanticsData> data = _data(tester);
            expect(data.any((node) => node.label.contains('Example')), isTrue);
            expect(
              data.any((node) => node.hasAction(SemanticsAction.tap)),
              !disabled,
            );
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            handle.dispose();
          }
        },
      );
    }
  }
}
