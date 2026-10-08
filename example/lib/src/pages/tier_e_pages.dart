// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../demo_scaffold.dart';
import '../examples/source_literals.dart';
import '../knobs.dart';
import '../registry.dart';

part 'tier_e_pages.examples.g.dart';

/// Compositions that combine the public building blocks into useful recipes.
final GalleryCategory tierECategory = GalleryCategory(
  title: 'Compositions',
  icon: CarbonIcons.categories,
  entries: <GalleryEntry>[
    GalleryEntry(slug: 'form', title: 'Form', builder: () => const _FormPage()),
    GalleryEntry(
      slug: 'button-set',
      title: 'Button set',
      builder: () => const _ButtonSetPage(),
    ),
    GalleryEntry(slug: 'menu', title: 'Menu', builder: () => const _MenuPage()),
    GalleryEntry(
      slug: 'popover',
      title: 'Popover',
      builder: () => const _PopoverPage(),
    ),
    GalleryEntry(
      slug: 'table-toolbar',
      title: 'Table toolbar',
      builder: () => const _TableToolbarPage(),
    ),
    GalleryEntry(
      slug: 'ui-shell',
      title: 'UI shell',
      builder: () => const _UIShellPage(),
    ),
    GalleryEntry(
      slug: 'layers-and-breakpoints',
      title: 'Layers and breakpoints',
      builder: () => const _LayersPage(),
    ),
    GalleryEntry(
      slug: 'fluid-pickers',
      title: 'Fluid pickers',
      builder: () => const _FluidPickersPage(),
    ),
  ],
);

class _FormPage extends StatefulWidget {
  const _FormPage();
  @override
  State<_FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<_FormPage> {
  bool _fluid = false;
  bool _disabled = false;
  bool _readOnly = false;
  bool _updates = true;
  int _saved = 0;
  final TextEditingController _name = TextEditingController(text: 'Alex');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget fields = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        CarbonTextInput(
          labelText: 'Your name',
          controller: _name,
          disabled: _disabled,
          readOnly: _readOnly,
        ),
        const SizedBox(height: 16),
        CarbonFormGroup(
          legend: 'Communication preferences',
          child: CarbonCheckbox(
            label: 'Receive product updates',
            value: _updates,
            onChanged: _disabled || _readOnly
                ? null
                : (bool value) => setState(() => _updates = value),
          ),
        ),
        const SizedBox(height: 16),
        const CarbonFormItem(
          children: <Widget>[
            CarbonFormLabel('Account ID'),
            CarbonField(readOnly: true, child: CarbonText('customer-1042')),
            CarbonHelperText('A display field supplied by the application.'),
          ],
        ),
        const SizedBox(height: 16),
        CarbonButton(
          label: 'Save preferences',
          onPressed: _disabled || _readOnly
              ? null
              : () => setState(() => _saved++),
        ),
        CarbonText('Saved: $_saved'),
      ],
    );
    return DemoScaffold(
      title: 'Form',
      description: 'FormGroup supplies the legend; Field supplies presentational chrome. FluidForm scopes the editable controls.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 420,
        child: _fluid ? CarbonFluidForm(child: fields) : fields,
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Fluid form',
          value: _fluid,
          onChanged: (bool v) => setState(() => _fluid = v),
        ),
        boolKnob(
          label: 'Disabled',
          value: _disabled,
          onChanged: (bool v) => setState(() => _disabled = v),
        ),
        boolKnob(
          label: 'Read only',
          value: _readOnly,
          onChanged: (bool v) => setState(() => _readOnly = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _ButtonSetPage extends StatefulWidget {
  const _ButtonSetPage();
  @override
  State<_ButtonSetPage> createState() => _ButtonSetPageState();
}

class _ButtonSetPageState extends State<_ButtonSetPage> {
  bool _stacked = false;
  int _saved = 0;
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Button set',
    description: 'Related secondary and primary actions share their layout.',
    preview: SizedBox(
      width: 392,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarbonButtonSet(
            stacked: _stacked,
            children: <CarbonButton>[
              CarbonButton(
                label: 'Reset',
                kind: CarbonButtonKind.secondary,
                onPressed: () => setState(() => _saved = 0),
              ),
              CarbonButton(
                label: 'Save',
                onPressed: () => setState(() => _saved++),
              ),
            ],
          ),
          CarbonText('Saved: $_saved'),
        ],
      ),
    ),
    controls: <Widget>[
      boolKnob(
        label: 'Stacked',
        value: _stacked,
        onChanged: (bool v) => setState(() => _stacked = v),
      ),
    ],
    code: exampleSource,
  );
}

class _MenuPage extends StatefulWidget {
  const _MenuPage();
  @override
  State<_MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<_MenuPage> {
  bool _selected = false;
  String _density = 'comfortable';
  String _action = 'None';
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Menu',
    description: 'Standalone menu actions, selectable items, and radio choices. Arrow keys move within the menu.',
    previewAlignment: Alignment.topLeft,
    preview: SizedBox(
      width: 288,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CarbonMenu(
            autofocus: false,
            border: true,
            children: <Widget>[
              CarbonMenuItem(
                label: 'Open report',
                icon: CarbonIcons.document,
                onPressed: () => setState(() => _action = 'Opened report'),
              ),
              CarbonMenuItemSelectable(
                label: 'Show archived',
                selected: _selected,
                onChanged: (bool v) => setState(() => _selected = v),
              ),
              const CarbonMenuItemDivider(),
              CarbonMenuItemRadioGroup(
                label: 'Density',
                value: _density,
                options: const <(String, String)>[
                  ('comfortable', 'Comfortable'),
                  ('compact', 'Compact'),
                ],
                onChanged: (String v) => setState(() => _density = v),
              ),
              const CarbonMenuItem(label: 'Delete report', disabled: true),
            ],
          ),
          CarbonText('Action: $_action'),
        ],
      ),
    ),
    code: exampleSource,
  );
}

class _PopoverPage extends StatefulWidget {
  const _PopoverPage();
  @override
  State<_PopoverPage> createState() => _PopoverPageState();
}

class _PopoverPageState extends State<_PopoverPage> {
  bool _open = false;
  bool _contrast = false;
  int _applied = 0;
  final FocusNode _triggerFocus = FocusNode();

  @override
  void dispose() {
    _triggerFocus.dispose();
    super.dispose();
  }

  void _close() {
    setState(() => _open = false);
    _triggerFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Popover',
    description: 'The application owns open state. Auto-alignment keeps the surface within the viewport; Escape and outside presses dismiss it.',
    preview: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CarbonPopover(
          open: _open,
          autoAlign: true,
          highContrast: _contrast,
          onRequestClose: _close,
          content: SizedBox(
            width: 192,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonText(
                  'Apply these report settings?',
                  color: _contrast ? CarbonTheme.of(context).textInverse : null,
                ),
                const SizedBox(height: 8),
                CarbonButton(
                  label: 'Apply settings',
                  onPressed: () {
                    setState(() => _applied++);
                    _close();
                  },
                ),
              ],
            ),
          ),
          child: CarbonButton(
            label: 'Report settings',
            focusNode: _triggerFocus,
            onPressed: () {
              _triggerFocus.requestFocus();
              setState(() => _open = !_open);
            },
          ),
        ),
        CarbonText('Applied: $_applied'),
      ],
    ),
    controls: <Widget>[
      boolKnob(
        label: 'High contrast',
        value: _contrast,
        onChanged: (bool v) => setState(() => _contrast = v),
      ),
    ],
    code: exampleSource,
  );
}

class _TableToolbarPage extends StatefulWidget {
  const _TableToolbarPage();
  @override
  State<_TableToolbarPage> createState() => _TableToolbarPageState();
}

class _TableToolbarPageState extends State<_TableToolbarPage> {
  String _query = '';
  int _added = 0;
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Table toolbar',
    description: 'Search, overflow actions, and a primary action can be used independently of DataTable.',
    previewAlignment: Alignment.topLeft,
    preview: SizedBox(
      width: 640,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CarbonTableToolbar(
            searchPlaceholder: 'Search reports',
            onSearchChanged: (String v) => setState(() => _query = v),
            onSearchCleared: () => setState(() => _query = ''),
            overflowItems: <Widget>[
              CarbonMenuItem(
                label: 'Reset reports',
                onPressed: () => setState(() => _added = 0),
              ),
            ],
            actions: <Widget>[
              CarbonButton(
                label: 'Add',
                onPressed: () => setState(() => _added++),
              ),
            ],
          ),
          CarbonText('Search: $_query'),
          CarbonText('Added: $_added'),
        ],
      ),
    ),
    code: exampleSource,
  );
}

class _UIShellPage extends StatefulWidget {
  const _UIShellPage();
  @override
  State<_UIShellPage> createState() => _UIShellPageState();
}

class _UIShellPageState extends State<_UIShellPage> {
  bool _open = false;
  String _page = 'Overview';
  final FocusNode _contentFocus = FocusNode(skipTraversal: true);
  @override
  void dispose() {
    _contentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'UI shell',
    description: 'A contained shell recipe. Below 672px navigation overlays content. Tab reveals the skip link; Enter focuses main content; Escape closes navigation.',
    previewAlignment: Alignment.topLeft,
    preview: SizedBox(
      width: 900,
      height: 360,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool narrow = constraints.maxWidth < CarbonBreakpoint.md.width;
          final Widget nav = CarbonSideNav(
            expanded: _open,
            items: <Widget>[
              for (final String label in <String>['Overview', 'Reports'])
                CarbonSideNavLink(
                  label: label,
                  current: _page == label,
                  onPressed: () => setState(() {
                    _page = label;
                    if (narrow) _open = false;
                  }),
                ),
            ],
          );
          final Widget body = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CarbonText(_page, style: CarbonTypeStyles.heading03),
                const CarbonText('Choose a section using navigation.'),
                CarbonButton(label: 'Refresh section', onPressed: () {}),
              ],
            ),
          );
          // A live recipe inside the gallery's main landmark must not create
          // a second main landmark. A standalone copied shell uses the real
          // CarbonShellContent landmark and its native skip-link destination.
          final Widget content =
              context.findAncestorWidgetOfExactType<CarbonShellContent>() ==
                  null
              ? CarbonShellContent(
                  label: 'Example main content',
                  focusNode: _contentFocus,
                  child: body,
                )
              : Focus.withExternalFocusNode(
                  focusNode: _contentFocus,
                  child: Semantics(
                    container: true,
                    label: 'Example content',
                    child: body,
                  ),
                );
          return Focus(
            canRequestFocus: false,
            includeSemantics: false,
            onKeyEvent: (FocusNode node, KeyEvent event) {
              if (_open &&
                  event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                setState(() => _open = false);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Stack(
                children: <Widget>[
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: Column(
                      children: <Widget>[
                        CarbonHeader(
                          name: const CarbonHeaderName(name: 'Reports'),
                          menuButton: CarbonHeaderMenuButton(
                            label: 'Example navigation',
                            isOpen: _open,
                            onPressed: () => setState(() => _open = !_open),
                          ),
                        ),
                        Expanded(
                          child: narrow
                              ? Stack(
                                  children: <Widget>[
                                    Positioned.fill(child: content),
                                    if (_open)
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: 0,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: constraints.maxWidth,
                                          ),
                                          child: nav,
                                        ),
                                      ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    nav,
                                    Expanded(child: content),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(0),
                    child: CarbonSkipToContent(
                      label: 'Skip to example content',
                      onPressed: () => _contentFocus.requestFocus(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    code: exampleSource,
  );
}

class _LayersPage extends StatefulWidget {
  const _LayersPage();
  @override
  State<_LayersPage> createState() => _LayersPageState();
}

class _LayersPageState extends State<_LayersPage> {
  int _width = 672;
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Layers and breakpoints',
    description: 'Nested layer tokens follow the theme. The measured layout width selects the breakpoint; the requested width is capped by the gallery viewport.',
    previewAlignment: Alignment.topLeft,
    preview: SizedBox(
      width: _width.toDouble(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final CarbonBreakpoint breakpoint = CarbonBreakpoint.of(
            constraints.maxWidth,
          );
          Widget layer(BuildContext context, String label, Widget? child) =>
              ColoredBox(
                color: CarbonLayer.of(context).layer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CarbonText(
                        '$label: level ${CarbonLayer.levelOf(context)}',
                      ),
                      CarbonTextInput(labelText: '$label field'),
                      ?child,
                    ],
                  ),
                ),
              );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonText(
                '${constraints.maxWidth.round()}px → ${breakpoint.name}, ${breakpoint.columns} columns',
              ),
              CarbonLayer(
                level: 0,
                child: Builder(
                  builder: (BuildContext context) => layer(
                    context,
                    'Root',
                    CarbonLayer(
                      child: Builder(
                        builder: (BuildContext context) => layer(
                          context,
                          'Nested',
                          CarbonLayer(
                            child: Builder(
                              builder: (BuildContext context) =>
                                  layer(context, 'Deep', null),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
    controls: <Widget>[
      choiceKnob<int>(
        label: 'Requested width',
        value: _width,
        options: <int>[320, 672, 1056, 1312, 1584],
        labelOf: (int v) => '${v}px',
        onChanged: (int v) => setState(() => _width = v),
      ),
    ],
    code: exampleSource,
  );
}

class _FluidPickersPage extends StatefulWidget {
  const _FluidPickersPage();
  @override
  State<_FluidPickersPage> createState() => _FluidPickersPageState();
}

class _FluidPickersPageState extends State<_FluidPickersPage> {
  String _region = 'emea';
  String? _team;
  Set<String> _selected = <String>{};
  bool _fluid = true;
  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'Fluid pickers',
    description: 'The same picker APIs provide fluid variants. ComboBox and filterable MultiSelect retain keyboard search and controlled values.',
    previewAlignment: Alignment.topLeft,
    preview: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarbonDropdown<String>(
            titleText: 'Region',
            fluid: _fluid,
            selectedItem: _region,
            onChanged: (String v) => setState(() => _region = v),
            items: const <CarbonDropdownItem<String>>[
              CarbonDropdownItem<String>(value: 'emea', label: 'EMEA'),
              CarbonDropdownItem<String>(value: 'americas', label: 'Americas'),
            ],
          ),
          const SizedBox(height: 16),
          CarbonComboBox<String>(
            titleText: 'Team',
            fluid: _fluid,
            selectedItem: _team,
            onChanged: (String? v) => setState(() => _team = v),
            items: const <CarbonComboBoxItem<String>>[
              CarbonComboBoxItem<String>(value: 'platform', label: 'Platform'),
              CarbonComboBoxItem<String>(value: 'security', label: 'Security'),
            ],
          ),
          const SizedBox(height: 16),
          CarbonMultiSelect<String>(
            titleText: 'Services',
            label: 'Select services',
            fluid: _fluid,
            filterable: true,
            selectedValues: _selected,
            onChanged: (Set<String> v) => setState(() => _selected = v),
            items: const <CarbonMultiSelectItem<String>>[
              CarbonMultiSelectItem<String>(value: 'compute', label: 'Compute'),
              CarbonMultiSelectItem<String>(value: 'storage', label: 'Storage'),
            ],
          ),
        ],
      ),
    ),
    controls: <Widget>[
      boolKnob(
        label: 'Fluid pickers',
        value: _fluid,
        onChanged: (bool v) => setState(() => _fluid = v),
      ),
    ],
    code: exampleSource,
  );
}
