// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import '../demo_scaffold.dart';
import '../knobs.dart';
import '../registry.dart';

/// Tier B — form controls.
final GalleryCategory tierBCategory = GalleryCategory(
  title: 'Forms',
  icon: CarbonIcons.edit,
  entries: <GalleryEntry>[
    GalleryEntry(
      slug: 'text-input',
      title: 'Text input',
      builder: () => const _TextInputPage(),
    ),
    GalleryEntry(
      slug: 'text-area',
      title: 'Text area',
      builder: () => const _TextAreaPage(),
    ),
    GalleryEntry(
      slug: 'number-input',
      title: 'Number input',
      builder: () => const _NumberInputPage(),
    ),
    GalleryEntry(
      slug: 'select',
      title: 'Select',
      builder: () => const _SelectPage(),
    ),
    GalleryEntry(
      slug: 'search',
      title: 'Search',
      builder: () => const _SearchPage(),
    ),
    GalleryEntry(
      slug: 'checkbox',
      title: 'Checkbox',
      builder: () => const _CheckboxPage(),
    ),
    GalleryEntry(
      slug: 'radio',
      title: 'Radio button',
      builder: () => const _RadioPage(),
    ),
    GalleryEntry(
      slug: 'toggle',
      title: 'Toggle',
      builder: () => const _TogglePage(),
    ),
    GalleryEntry(
      slug: 'slider',
      title: 'Slider',
      builder: () => const _SliderPage(),
    ),
  ],
);

class _TextInputPage extends StatefulWidget {
  const _TextInputPage();
  @override
  State<_TextInputPage> createState() => _TextInputPageState();
}

class _TextInputPageState extends State<_TextInputPage> {
  bool _invalid = false;
  bool _disabled = false;
  bool _readOnly = false;
  bool _ai = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Text input',
      description: 'Single-line text and password fields with validation and visibility controls.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CarbonTextInput(
              labelText: 'Email address',
              placeholder: 'you@example.com',
              helperText: 'We never share your email.',
              invalid: _invalid,
              invalidText: 'Enter a valid email.',
              disabled: _disabled,
              readOnly: _readOnly,
              aiLabel: _ai
                  ? const CarbonAILabel(size: CarbonAILabelSize.mini)
                  : null,
            ),
            const SizedBox(height: CarbonSpacing.spacing05),
            CarbonPasswordInput(
              labelText: 'Password',
              initialValue: 'demo-password',
              disabled: _disabled,
              readOnly: _readOnly,
            ),
          ],
        ),
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Invalid',
          value: _invalid,
          onChanged: (bool v) => setState(() => _invalid = v),
        ),
        boolKnob(
          label: 'AI label',
          value: _ai,
          onChanged: (bool v) => setState(() => _ai = v),
        ),
        boolKnob(
          label: 'Disabled',
          value: _disabled,
          onChanged: (bool v) => setState(() => _disabled = v),
        ),
        boolKnob(
          label: 'Read only',
          value: _readOnly,
          onChanged: (bool value) => setState(() => _readOnly = value),
        ),
      ],
      code:
          "CarbonTextInput(labelText: 'Email address', placeholder: '…');\n"
          "CarbonPasswordInput(labelText: 'Password');",
    );
  }
}

class _TextAreaPage extends StatelessWidget {
  const _TextAreaPage();
  @override
  Widget build(BuildContext context) {
    return const DemoScaffold(
      title: 'Text area',
      description: 'A multi-line field with an optional character counter.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 360,
        child: CarbonTextArea(
          labelText: 'Notes',
          placeholder: 'Add any additional context…',
          enableCounter: true,
          maxCount: 200,
        ),
      ),
      code: "CarbonTextArea(labelText: 'Notes', rows: 4);",
    );
  }
}

class _NumberInputPage extends StatefulWidget {
  const _NumberInputPage();
  @override
  State<_NumberInputPage> createState() => _NumberInputPageState();
}

class _NumberInputPageState extends State<_NumberInputPage> {
  num _value = 3;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Number input',
      description:
          'Type a draft, then press Enter or leave the field to commit. '
          'Steppers and arrow keys commit within the min/max bounds.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 240,
        child: CarbonNumberInput(
          labelText: 'Quantity',
          value: _value,
          min: 0,
          max: 10,
          onChanged: (num? v) => setState(() => _value = v ?? _value),
        ),
      ),
      code: "CarbonNumberInput(labelText: 'Quantity', min: 0, max: 10);",
    );
  }
}

class _SelectPage extends StatefulWidget {
  const _SelectPage();
  @override
  State<_SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<_SelectPage> {
  bool _readOnly = false;
  bool _disabled = false;
  String _value = 'md';

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Select',
      description: 'A native-style single select on the list-box chrome.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: CarbonSelect<String>(
          readOnly: _readOnly,
          disabled: _disabled,
          labelText: 'Size',
          value: _value,
          onChanged: (String v) => setState(() => _value = v),
          items: const <CarbonSelectItem<String>>[
            CarbonSelectItem<String>(value: 'sm', label: 'Small'),
            CarbonSelectItem<String>(value: 'md', label: 'Medium'),
            CarbonSelectItem<String>(value: 'lg', label: 'Large'),
          ],
        ),
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Read only',
          value: _readOnly,
          onChanged: (bool value) => setState(() => _readOnly = value),
        ),
        boolKnob(
          label: 'Disabled',
          value: _disabled,
          onChanged: (bool value) => setState(() => _disabled = value),
        ),
      ],
      code: "CarbonSelect<String>(labelText: 'Size', items: <…>[…]);",
    );
  }
}

class _SearchPage extends StatefulWidget {
  const _SearchPage();
  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  bool _readOnly = false;
  bool _disabled = false;
  bool _expandable = false;
  final TextEditingController _query = TextEditingController(
    text: 'Carbon components',
  );
  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Search',
    description: 'A search field with a clear affordance.',
    previewAlignment: Alignment.topCenter,
    preview: SizedBox(
      width: 360,
      child: _expandable
          ? CarbonExpandableSearch(
              controller: _query,
              readOnly: _readOnly,
              disabled: _disabled,
            )
          : CarbonSearch(
              controller: _query,
              readOnly: _readOnly,
              disabled: _disabled,
              placeholder: 'Search components',
            ),
    ),
    controls: <Widget>[
      boolKnob(
        label: 'Read only',
        value: _readOnly,
        onChanged: (bool value) => setState(() => _readOnly = value),
      ),
      boolKnob(
        label: 'Disabled',
        value: _disabled,
        onChanged: (bool value) => setState(() => _disabled = value),
      ),

      boolKnob(
        label: 'Expandable',
        value: _expandable,
        onChanged: (bool value) => setState(() => _expandable = value),
      ),
    ],
    code: 'CarbonSearch(readOnly: …, disabled: …);',
  );
}

class _CheckboxPage extends StatefulWidget {
  const _CheckboxPage();
  @override
  State<_CheckboxPage> createState() => _CheckboxPageState();
}

class _CheckboxPageState extends State<_CheckboxPage> {
  bool _a = true;
  bool _b = false;
  bool _ai = false;

  bool _disabled = false;
  bool _readOnly = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Checkbox',
      description: 'Independent boolean choices, with an indeterminate state.',
      previewAlignment: Alignment.topLeft,
      preview: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CarbonCheckbox(
            label: 'Subscribe to updates',
            value: _a,
            disabled: _disabled,
            readOnly: _readOnly,
            onChanged: (bool v) => setState(() => _a = v),
            aiLabel: _ai
                ? const CarbonAILabel(size: CarbonAILabelSize.mini)
                : null,
          ),
          const SizedBox(height: CarbonSpacing.spacing03),
          CarbonCheckbox(
            label: 'Enable analytics',
            value: _b,
            disabled: _disabled,
            readOnly: _readOnly,
            onChanged: (bool v) => setState(() => _b = v),
          ),
          const SizedBox(height: CarbonSpacing.spacing03),
          const CarbonCheckbox(
            label: 'Mixed selection',
            value: false,
            indeterminate: true,
          ),
        ],
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Disabled',
          value: _disabled,
          onChanged: (bool value) => setState(() => _disabled = value),
        ),
        boolKnob(
          label: 'Read only',
          value: _readOnly,
          onChanged: (bool value) => setState(() => _readOnly = value),
        ),

        boolKnob(
          label: 'AI label',
          value: _ai,
          onChanged: (bool v) => setState(() => _ai = v),
        ),
      ],
      code: 'CarbonCheckbox(label: \'…\', value: true, onChanged: …);',
    );
  }
}

class _RadioPage extends StatefulWidget {
  const _RadioPage();
  @override
  State<_RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<_RadioPage> {
  String _value = 'standard';

  bool _disabled = false;
  bool _readOnly = false;

  @override
  Widget build(BuildContext context) {
    Widget radio(String value, String label) => Padding(
      padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing03),
      child: CarbonRadioButton(
        label: label,
        selected: _value == value,
        disabled: _disabled,
        readOnly: _readOnly,
        onSelected: () => setState(() => _value = value),
      ),
    );
    return DemoScaffold(
      title: 'Radio button',
      description: 'A single choice within a group.',
      previewAlignment: Alignment.topLeft,
      preview: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          radio('standard', 'Standard shipping'),
          radio('express', 'Express shipping'),
          radio('overnight', 'Overnight'),
        ],
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Disabled',
          value: _disabled,
          onChanged: (bool value) => setState(() => _disabled = value),
        ),
        boolKnob(
          label: 'Read only',
          value: _readOnly,
          onChanged: (bool value) => setState(() => _readOnly = value),
        ),
      ],
      code: 'CarbonRadioButton(label: \'…\', selected: …, onSelected: …);',
    );
  }
}

class _TogglePage extends StatefulWidget {
  const _TogglePage();
  @override
  State<_TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<_TogglePage> {
  bool _on = true;

  bool _disabled = false;
  bool _readOnly = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Toggle',
      description: 'An instant on/off switch.',
      previewAlignment: Alignment.topLeft,
      preview: CarbonToggle(
        labelText: 'Notifications',
        toggled: _on,
        disabled: _disabled,
        readOnly: _readOnly,
        onToggled: (bool v) => setState(() => _on = v),
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Disabled',
          value: _disabled,
          onChanged: (bool value) => setState(() => _disabled = value),
        ),
        boolKnob(
          label: 'Read only',
          value: _readOnly,
          onChanged: (bool value) => setState(() => _readOnly = value),
        ),
      ],
      code: "CarbonToggle(labelText: 'Notifications', toggled: true);",
    );
  }
}

class _SliderPage extends StatefulWidget {
  const _SliderPage();
  @override
  State<_SliderPage> createState() => _SliderPageState();
}

class _SliderPageState extends State<_SliderPage> {
  num _value = 60;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Slider',
      description:
          'A draggable value with a paired number field. Disabled controls '
          'skip focus; read-only controls allow focus and value inspection.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 360,
        child: CarbonSlider(
          labelText: 'Volume',
          value: _value,
          min: 0,
          max: 100,
          onChanged: (num v) => setState(() => _value = v),
        ),
      ),
      code: "CarbonSlider(labelText: 'Volume', value: 60, min: 0, max: 100);",
    );
  }
}
