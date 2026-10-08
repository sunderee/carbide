// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
// Fixture compositions mirror the pinned Carbon v11.118.0 stories, not a
// generic specimen. See stories.json for source, environment and limitations.
import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

void _noop() {}

final Map<String, Widget Function()>
fidelityBuilders = <String, Widget Function()>{
  'button': () => const IntrinsicWidth(
    child: CarbonButton(label: 'Button', onPressed: _noop),
  ),
  'tag': () => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: <Widget>[
      for (final CarbonTagType type in <CarbonTagType>[
        CarbonTagType.red,
        CarbonTagType.magenta,
        CarbonTagType.purple,
        CarbonTagType.blue,
        CarbonTagType.cyan,
        CarbonTagType.teal,
        CarbonTagType.green,
        CarbonTagType.gray,
        CarbonTagType.coolGray,
        CarbonTagType.warmGray,
        CarbonTagType.highContrast,
        CarbonTagType.outline,
      ])
        CarbonTag(
          label: type == CarbonTagType.red
              ? 'Tag content with a long text description'
              : 'Tag content',
          type: type,
        ),
    ],
  ),
  'checkbox': () => CarbonCheckboxGroup(
    legend: 'Group label',
    helperText: 'Helper text goes here',
    children: <Widget>[
      for (int i = 0; i < 2; i++)
        CarbonCheckbox(
          label: 'Checkbox label',
          value: false,
          onChanged: (_) {},
        ),
    ],
  ),
  'toggle': () =>
      CarbonToggle(labelText: 'Label', toggled: true, onToggled: (_) {}),
  'text-input': () => const SizedBox(
    width: 300,
    child: CarbonTextInput(
      labelText: 'Label text',
      placeholder: 'Placeholder text',
      helperText: 'Helper text',
    ),
  ),
  'tree-view': () => const SizedBox(
    width: 320,
    child: CarbonTreeView(
      label: 'Tree View',
      initiallyExpandedIds: <Object>{'5', '5-3', '5-5', '7', '8'},
      nodes: fidelityTreeNodes,
    ),
  ),
  'data-table': () => CarbonDataTable(
    columns: const <CarbonTableColumn>[
      CarbonTableColumn(title: 'Name'),
      CarbonTableColumn(title: 'Rule'),
      CarbonTableColumn(title: 'Status'),
      CarbonTableColumn(title: 'Other'),
      CarbonTableColumn(title: 'Example'),
    ],
    rows: <CarbonTableRow>[
      for (int i = 1; i <= 7; i++)
        CarbonTableRow(
          cells: <Widget>[
            Text('Load Balancer $i'),
            Text(i == 2 ? 'DNS delegation' : 'Round robin'),
            Text(
              i == 1
                  ? 'Starting'
                  : i == 2
                  ? 'Active'
                  : 'Disabled',
            ),
            const Text('Test'),
            const Text('22'),
          ],
        ),
    ],
  ),
  'notification': () => const SizedBox(
    width: 736,
    child: CarbonInlineNotification(
      kind: CarbonNotificationKind.error,
      title: 'Notification title',
      subtitle: 'Subtitle text goes here',
    ),
  ),
  'dropdown': () => SizedBox(
    width: 400,
    child: CarbonDropdown<int>(
      titleText: 'Label',
      label: 'Choose an option',
      helperText: 'Helper text',
      onChanged: (int _) {},
      items: const <CarbonDropdownItem<int>>[
        CarbonDropdownItem<int>(value: 0, label: 'Option 1'),
        CarbonDropdownItem<int>(value: 1, label: 'Option 2'),
      ],
    ),
  ),
  'tabs': () => SizedBox(
    width: 1196,
    child: CarbonTabs(
      tabs: const <CarbonTab>[
        CarbonTab(label: 'Dashboard'),
        CarbonTab(label: 'Monitoring'),
        CarbonTab(label: 'Activity'),
        CarbonTab(label: 'Settings'),
      ],
      panels: const <Widget>[
        Text('Tab Panel 1'),
        Text('Tab Panel 2'),
        Text('Tab Panel 3'),
        Text('Tab Panel 4'),
      ],
    ),
  ),
  'accordion': () => const SizedBox(
    width: 1196,
    child: CarbonAccordion(
      children: <Widget>[
        CarbonAccordionItem(title: 'Choose your plan', child: Text('Body')),
        CarbonAccordionItem(title: 'Add team members', child: Text('Body')),
        CarbonAccordionItem(title: 'Set payment details', child: Text('Body')),
        CarbonAccordionItem(
          title: 'Review and confirm (title can be a node)',
          child: Text('Body'),
        ),
      ],
    ),
  ),
  'multiselect': () => SizedBox(
    width: 300,
    child: CarbonMultiSelect<int>(
      titleText: 'Label',
      label: 'This is a label',
      helperText: 'This is helper text',
      onChanged: (Set<int> _) {},
      items: const <CarbonMultiSelectItem<int>>[
        CarbonMultiSelectItem<int>(value: 0, label: 'Option 1'),
        CarbonMultiSelectItem<int>(value: 1, label: 'Option 2'),
      ],
    ),
  ),
  'search': () => const SizedBox(
    width: 800,
    child: CarbonSearch(placeholder: 'Placeholder text'),
  ),
  'number-input': () => CarbonNumberInput(
    labelText: 'NumberInput label',
    helperText: 'Optional helper text.',
    value: 50,
    min: 0,
    max: 100,
    onChanged: (num? _) {},
  ),
  'select': () => SizedBox(
    width: 400,
    child: CarbonSelect<String>(
      labelText: 'Deployment region',
      helperText: 'Select the region where your resources will be hosted.',
      value: '',
      onChanged: (String? _) {},
      items: const <CarbonSelectItem<String>>[
        CarbonSelectItem(value: '', label: 'Choose a region'),
        CarbonSelectItem(value: 'us-south', label: 'Dallas (us-south)'),
        CarbonSelectItem(value: 'us-east', label: 'Washington, DC (us-east)'),
        CarbonSelectItem(value: 'eu-de', label: 'Frankfurt (eu-de)'),
        CarbonSelectItem(value: 'au-syd', label: 'Sydney (au-syd)'),
      ],
    ),
  ),
  'combo-box': () => SizedBox(
    width: 300,
    child: CarbonComboBox<int>(
      titleText: 'Label',
      helperText: 'Helper text',
      placeholder: 'Filter...',
      onChanged: (int? _) {},
      items: const <CarbonComboBoxItem<int>>[
        CarbonComboBoxItem(value: 0, label: 'Option 1'),
        CarbonComboBoxItem(value: 1, label: 'Option 2'),
      ],
    ),
  ),
  'date-picker': () => SizedBox(
    width: 288,
    child: CarbonDatePicker(
      labelText: 'Date Picker label',
      onChanged: (DateTime? _) {},
    ),
  ),
  'radio-button': () => CarbonRadioButtonGroup<int>(
    legend: 'Radio Button group',
    helperText: 'Helper text',
    value: 1,
    orientation: Axis.horizontal,
    onChanged: (int _) {},
    options: const <(int, String)>[
      (0, 'Radio button label'),
      (1, 'Radio button label'),
      (2, 'Radio button label'),
    ],
  ),
  'slider': () => SizedBox(
    width: 400,
    child: CarbonSlider(
      // @carbon/react v1.118.0 Slider.stories.js: Default sharedArgs.
      labelText: 'Storage allocation',
      value: 50,
      min: 0,
      max: 100,
      formatLabel: (num value) => '$value GB',
      onChanged: (num _) {},
    ),
  ),
  'modal': () => const FidelityModalFixture(),
  'tooltip': () => const SizedBox(
    width: 1280,
    height: 282,
    child: Center(
      child: CarbonTooltip(label: 'Options', child: FidelityTooltipTrigger()),
    ),
  ),
  'progress-bar': () => const CarbonProgressBar(
    label: 'Uploading files',
    value: 75,
    helperText: '75 MB of 100 MB',
  ),
  'progress-indicator': () => const CarbonProgressIndicator(
    currentIndex: 1,
    steps: <CarbonProgressStep>[
      CarbonProgressStep(label: 'First step', secondaryLabel: 'Optional label'),
      CarbonProgressStep(label: 'Second step with tooltip'),
      CarbonProgressStep(label: 'Third step with tooltip'),
      CarbonProgressStep(
        label: 'Fourth step',
        secondaryLabel: 'Example invalid step',
        invalid: true,
      ),
      CarbonProgressStep(label: 'Fifth step'),
    ],
  ),
  'breadcrumb': () => const CarbonBreadcrumb(
    items: <CarbonBreadcrumbItem>[
      CarbonBreadcrumbItem(label: 'Breadcrumb 1', onPressed: _noop),
      CarbonBreadcrumbItem(label: 'Breadcrumb 2', onPressed: _noop),
      CarbonBreadcrumbItem(label: 'Breadcrumb 3', onPressed: _noop),
      CarbonBreadcrumbItem(label: 'Breadcrumb 4', onPressed: _noop),
    ],
  ),
  'pagination': () => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: SizedBox(
      width: 800,
      child: CarbonPagination(
        page: 1,
        pageSize: 10,
        pageSizes: const <int>[10, 20, 30, 40, 50],
        totalItems: 103,
        onPageChanged: (int _) {},
        onPageSizeChanged: (int _) {},
      ),
    ),
  ),
  'code-snippet': () => const SizedBox(
    width: 768,
    child: CarbonCodeSnippet(
      code: 'yarn add carbon-components@latest carbon-components-react@latest @carbon/icons-react@latest carbon-icons@latest',
    ),
  ),
  'content-switcher': () => CarbonContentSwitcher(
    selectedIndex: 0,
    onChanged: (int _) {},
    switches: const <CarbonSwitch>[
      CarbonSwitch(text: 'First section'),
      CarbonSwitch(text: 'Second section'),
      CarbonSwitch(text: 'Third section'),
    ],
  ),
  'structured-list': () => const CarbonStructuredList(
    headers: <String>['Service', 'Status', 'Description'],
    rows: <CarbonStructuredListRow>[
      CarbonStructuredListRow(
        cells: <Widget>[
          Text('API gateway'),
          Text('Online'),
          Text('Routes and secures application traffic across environments.'),
        ],
      ),
      CarbonStructuredListRow(
        cells: <Widget>[
          Text('Data warehouse'),
          Text('Maintenance'),
          Text('Scheduled maintenance begins Friday at 22:00 UTC.'),
        ],
      ),
    ],
  ),
  'tile': () => const CarbonTile(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Default tile'),
        SizedBox(height: 20),
        CarbonLink(label: 'Link', onPressed: _noop),
      ],
    ),
  ),
  'loading': () => const CarbonLoading(withOverlay: false),
  'inline-loading': () => const CarbonInlineLoading(description: 'Loading'),
  'overflow-menu': () => const CarbonOverflowMenu(
    items: <CarbonMenuItem>[
      CarbonMenuItem(label: 'Stop app', onPressed: _noop),
      CarbonMenuItem(label: 'Restart app', onPressed: _noop),
      CarbonMenuItem(label: 'Rename app', onPressed: _noop),
    ],
  ),
  'link': () => const CarbonLink(label: 'Link', onPressed: _noop),
};

const List<CarbonTreeNode> fidelityTreeNodes = <CarbonTreeNode>[
  CarbonTreeNode(
    id: '1',
    label: 'Application development and integration solutions',
  ),
  CarbonTreeNode(id: '2', label: 'Blockchain'),
  CarbonTreeNode(
    id: '3',
    label: 'Business automation',
    children: <CarbonTreeNode>[
      CarbonTreeNode(id: '3-1', label: 'Business process automation'),
      CarbonTreeNode(id: '3-2', label: 'Business process mapping'),
    ],
  ),
  CarbonTreeNode(id: '4', label: 'Business operations'),
  CarbonTreeNode(
    id: '5',
    label: 'Cloud computing',
    children: <CarbonTreeNode>[
      CarbonTreeNode(id: '5-1', label: 'Containers'),
      CarbonTreeNode(id: '5-2', label: 'Databases'),
      CarbonTreeNode(
        id: '5-3',
        label: 'DevOps',
        children: <CarbonTreeNode>[
          CarbonTreeNode(id: '5-4', label: 'Solutions'),
          CarbonTreeNode(
            id: '5-5',
            label: 'Case studies',
            children: <CarbonTreeNode>[
              CarbonTreeNode(id: '5-6', label: 'Resources'),
            ],
          ),
        ],
      ),
    ],
  ),
  CarbonTreeNode(
    id: '6',
    label: 'Data & Analytics',
    children: <CarbonTreeNode>[
      CarbonTreeNode(id: '6-1', label: 'Big data'),
      CarbonTreeNode(id: '6-2', label: 'Business intelligence'),
    ],
  ),
  CarbonTreeNode(
    id: '7',
    label: 'Models',
    disabled: true,
    children: <CarbonTreeNode>[
      CarbonTreeNode(id: '7-1', label: 'Audit'),
      CarbonTreeNode(id: '7-2', label: 'Monthly data'),
      CarbonTreeNode(
        id: '8',
        label: 'Data warehouse',
        children: <CarbonTreeNode>[
          CarbonTreeNode(id: '8-1', label: 'Report samples'),
          CarbonTreeNode(id: '8-2', label: 'Sales performance'),
        ],
      ),
    ],
  ),
];

/// The complete default Modal story, including its launcher and form.
class FidelityModalFixture extends StatefulWidget {
  /// Creates the default open, non-danger, large modal story.
  const FidelityModalFixture({super.key});
  @override
  State<FidelityModalFixture> createState() => _FidelityModalFixtureState();
}

class _FidelityModalFixtureState extends State<FidelityModalFixture> {
  final FocusNode _domain = FocusNode();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _domain.requestFocus();
    });
  }

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      const Positioned(
        left: 42,
        top: 42,
        child: IntrinsicWidth(
          child: CarbonButton(label: 'Launch modal', onPressed: _noop),
        ),
      ),
      CarbonModal(
        open: true,
        title: 'Add a custom domain',
        size: CarbonModalSize.lg,
        onClose: _noop,
        primaryButton: const CarbonModalAction(label: 'Add', onPressed: _noop),
        secondaryButton: const CarbonModalAction(
          label: 'Cancel',
          onPressed: _noop,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Custom domains direct requests for your apps in this Cloud Foundry organization to a URL that you own. A custom domain can be a shared domain, a shared subdomain, or a shared domain and host.',
            ),
            const SizedBox(height: 32),
            CarbonTextInput(
              labelText: 'Domain name',
              placeholder: 'For example, GitHub.com',
              focusNode: _domain,
            ),
            const SizedBox(height: 24),
            CarbonSelect<String>(
              labelText: 'Region',
              value: 'us-south',
              onChanged: (String? _) {},
              items: const <CarbonSelectItem<String>>[
                CarbonSelectItem(value: 'us-south', label: 'US South'),
                CarbonSelectItem(value: 'us-east', label: 'US East'),
              ],
            ),
            const SizedBox(height: 24),
            CarbonComboBox<String>(
              titleText: 'Permissions (Example of Floating UI)',
              onChanged: (String? _) {},
              items: const <CarbonComboBoxItem<String>>[
                CarbonComboBoxItem(value: 'Viewer', label: 'Viewer'),
                CarbonComboBoxItem(value: 'Editor', label: 'Editor'),
                CarbonComboBoxItem(value: 'Manager', label: 'Manager'),
              ],
            ),
            const SizedBox(height: 24),
            CarbonDropdown<String>(
              titleText: 'TLS (Example of Floating UI)',
              label: 'Option 1',
              onChanged: (String _) {},
              items: const <CarbonDropdownItem<String>>[
                CarbonDropdownItem(value: '1.0', label: '1.0'),
                CarbonDropdownItem(value: '1.1', label: '1.1'),
                CarbonDropdownItem(value: '1.2', label: '1.2'),
              ],
            ),
            const SizedBox(height: 24),
            CarbonMultiSelect<String>(
              titleText: 'Mapping domain',
              label: 'Choose options',
              onChanged: (Set<String> _) {},
              items: const <CarbonMultiSelectItem<String>>[
                CarbonMultiSelectItem(value: 'cf', label: 'Cloud Foundry'),
                CarbonMultiSelectItem(value: 'ki', label: 'Kubernetes Ingress'),
                CarbonMultiSelectItem(value: 'vpc', label: 'VPC Load Balancer'),
              ],
            ),
            const SizedBox(height: 24),
            CarbonCheckboxGroup(
              legend: 'Terms of Agreement',
              children: <Widget>[
                CarbonCheckbox(
                  label: 'I confirm domain ownership and accept IBM service terms and applicable charges.',
                  value: false,
                  onChanged: (bool _) {},
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

/// The unpadded 16px button used by the default Tooltip story.
class FidelityTooltipTrigger extends StatelessWidget {
  /// Creates the inert Options action whose tooltip stays open on activation.
  const FidelityTooltipTrigger({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    onTap: _noop,
    child: Focus(
      onKeyEvent: (_, event) =>
          event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.space)
          ? KeyEventResult.handled
          : KeyEventResult.ignored,
      child: GestureDetector(
        onTap: _noop,
        excludeFromSemantics: true,
        child: const CarbonIcon(CarbonIcons.overflowMenuVertical, size: 16),
      ),
    ),
  );
}
