// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import '../demo_scaffold.dart';
import '../examples/source_literals.dart';
import '../knobs.dart';
import '../registry.dart';

part 'tier_c_pages.examples.g.dart';

/// Tier C — composite components.
final GalleryCategory tierCCategory = GalleryCategory(
  title: 'Composite',
  icon: CarbonIcons.categories,
  entries: <GalleryEntry>[
    GalleryEntry(
      slug: 'ai-label',
      title: 'AI label',
      builder: () => const _AILabelPage(),
    ),
    GalleryEntry(
      slug: 'chat-button',
      title: 'Chat button',
      builder: () => const _ChatButtonPage(),
    ),
    GalleryEntry(
      slug: 'contained-list',
      title: 'Contained list',
      builder: () => const _ContainedListPage(),
    ),
    GalleryEntry(
      slug: 'context-menu',
      title: 'Context menu',
      builder: () => const _ContextMenuPage(),
    ),
    GalleryEntry(
      slug: 'pagination-nav',
      title: 'Pagination nav',
      builder: () => const _PaginationNavPage(),
    ),
    GalleryEntry(
      slug: 'dropdown',
      title: 'Dropdown',
      builder: () => const _DropdownPage(),
    ),
    GalleryEntry(
      slug: 'combo-box',
      title: 'Combo box',
      builder: () => const _ComboBoxPage(),
    ),
    GalleryEntry(
      slug: 'multi-select',
      title: 'Multi-select',
      builder: () => const _MultiSelectPage(),
    ),
    GalleryEntry(
      slug: 'tooltip',
      title: 'Tooltip',
      builder: () => const _TooltipPage(),
    ),
    GalleryEntry(
      slug: 'toggletip',
      title: 'Toggletip',
      builder: () => const _ToggletipPage(),
    ),
    GalleryEntry(
      slug: 'overflow-menu',
      title: 'Overflow menu',
      builder: () => const _OverflowMenuPage(),
    ),
    GalleryEntry(slug: 'tabs', title: 'Tabs', builder: () => const _TabsPage()),
    GalleryEntry(
      slug: 'accordion',
      title: 'Accordion',
      builder: () => const _AccordionPage(),
    ),
    GalleryEntry(
      slug: 'content-switcher',
      title: 'Content switcher',
      builder: () => const _ContentSwitcherPage(),
    ),
    GalleryEntry(
      slug: 'breadcrumb',
      title: 'Breadcrumb',
      builder: () => const _BreadcrumbPage(),
    ),
    GalleryEntry(
      slug: 'pagination',
      title: 'Pagination',
      builder: () => const _PaginationPage(),
    ),
    GalleryEntry(
      slug: 'modal',
      title: 'Modal',
      builder: () => const _ModalPage(),
    ),
    GalleryEntry(
      slug: 'dialog',
      title: 'Dialog',
      builder: () => const _DialogPage(),
    ),
    GalleryEntry(
      slug: 'notification',
      title: 'Notification',
      builder: () => const _NotificationPage(),
    ),
    GalleryEntry(
      slug: 'progress-indicator',
      title: 'Progress indicator',
      builder: () => const _ProgressIndicatorPage(),
    ),
    GalleryEntry(
      slug: 'structured-list',
      title: 'Structured list',
      builder: () => const _StructuredListPage(),
    ),
  ],
);

class _DropdownPage extends StatefulWidget {
  const _DropdownPage();
  @override
  State<_DropdownPage> createState() => _DropdownPageState();
}

class _DropdownPageState extends State<_DropdownPage> {
  bool _readOnly = false;
  bool _disabled = false;
  String _value = 'cyan';
  bool _ai = false;
  bool _fluid = false;
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Dropdown',
      description: 'A single-select on the list-box chrome.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: CarbonDropdown<String>(
          readOnly: _readOnly,
          disabled: _disabled,
          titleText: 'Favourite colour',
          selectedItem: _value,
          onChanged: (String v) => setState(() => _value = v),
          aiLabel: _ai
              ? const CarbonAILabel(size: CarbonAILabelSize.mini)
              : null,
          fluid: _fluid,
          items: const <CarbonDropdownItem<String>>[
            CarbonDropdownItem<String>(value: 'cyan', label: 'Cyan'),
            CarbonDropdownItem<String>(value: 'magenta', label: 'Magenta'),
            CarbonDropdownItem<String>(value: 'teal', label: 'Teal'),
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

        boolKnob(
          label: 'AI label',
          value: _ai,
          onChanged: (bool v) => setState(() => _ai = v),
        ),
        boolKnob(
          label: 'Fluid',
          value: _fluid,
          onChanged: (bool v) => setState(() => _fluid = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _ComboBoxPage extends StatefulWidget {
  const _ComboBoxPage();
  @override
  State<_ComboBoxPage> createState() => _ComboBoxPageState();
}

class _ComboBoxPageState extends State<_ComboBoxPage> {
  bool _readOnly = false;
  bool _disabled = false;
  String? _value = 'ee';
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Combo box',
      description: 'A filterable single-select.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: CarbonComboBox<String>(
          readOnly: _readOnly,
          disabled: _disabled,
          titleText: 'Country',
          selectedItem: _value,
          onChanged: (String? v) => setState(() => _value = v),
          items: const <CarbonComboBoxItem<String>>[
            CarbonComboBoxItem<String>(value: 'ee', label: 'Estonia'),
            CarbonComboBoxItem<String>(value: 'fi', label: 'Finland'),
            CarbonComboBoxItem<String>(value: 'se', label: 'Sweden'),
            CarbonComboBoxItem<String>(value: 'no', label: 'Norway'),
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
      code: exampleSource,
    );
  }
}

class _MultiSelectPage extends StatefulWidget {
  const _MultiSelectPage();
  @override
  State<_MultiSelectPage> createState() => _MultiSelectPageState();
}

class _MultiSelectPageState extends State<_MultiSelectPage> {
  bool _readOnly = false;
  bool _disabled = false;
  bool _filterable = false;
  Set<String> _selected = <String>{'read'};
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Multi-select',
      description: 'Pick several values, with an optional filter.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: CarbonMultiSelect<String>(
          readOnly: _readOnly,
          disabled: _disabled,
          titleText: 'Permissions',
          filterable: _filterable,
          label: 'Choose permissions',
          selectedValues: _selected,
          onChanged: (Set<String> v) => setState(() => _selected = v),
          items: const <CarbonMultiSelectItem<String>>[
            CarbonMultiSelectItem<String>(value: 'read', label: 'Read'),
            CarbonMultiSelectItem<String>(value: 'write', label: 'Write'),
            CarbonMultiSelectItem<String>(value: 'admin', label: 'Admin'),
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

        boolKnob(
          label: 'Filterable',
          value: _filterable,
          onChanged: (bool value) => setState(() => _filterable = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _TooltipPage extends StatelessWidget {
  const _TooltipPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Tooltip',
      description: 'Hover or focus to reveal contextual help.',
      preview: CarbonTooltip(
        label: 'Carbide is an unofficial Carbon port.',
        child: CarbonButton(label: 'Hover me', onPressed: () {}),
      ),
      code: exampleSource,
    );
  }
}

class _ToggletipPage extends StatelessWidget {
  const _ToggletipPage();
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return DemoScaffold(
      title: 'Toggletip',
      description: 'Click to reveal interactive content.',
      preview: CarbonToggletip(
        content: Text(
          'Toggletips hold interactive content and stay open until dismissed.',
          style: CarbonTypeStyles.body01.copyWith(color: t.textPrimary),
        ),
      ),
      code: exampleSource,
    );
  }
}

class _OverflowMenuPage extends StatelessWidget {
  const _OverflowMenuPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Overflow menu',
      description: 'A trigger that opens an action menu.',
      preview: CarbonOverflowMenu(
        items: <Widget>[
          CarbonMenuItem(
            label: 'Edit',
            icon: CarbonIcons.edit,
            onPressed: () {},
          ),
          CarbonMenuItem(
            label: 'Duplicate',
            icon: CarbonIcons.copy,
            onPressed: () {},
          ),
          const CarbonMenuItemDivider(),
          CarbonMenuItem(
            label: 'Delete',
            icon: CarbonIcons.trashCan,
            kind: CarbonMenuItemKind.danger,
            onPressed: () {},
          ),
        ],
      ),
      code: exampleSource,
    );
  }
}

class _TabsPage extends StatefulWidget {
  const _TabsPage();
  @override
  State<_TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<_TabsPage> {
  bool _vertical = false;
  bool _many = false;
  bool _manual = false;
  CarbonTabVariant _variant = CarbonTabVariant.line;
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    Widget panel(String s) => Padding(
      padding: const EdgeInsets.only(top: CarbonSpacing.spacing05),
      child: Text(
        s,
        style: CarbonTypeStyles.body01.copyWith(color: t.textPrimary),
      ),
    );
    final List<CarbonTab> tabs = _many
        ? <CarbonTab>[
            for (int i = 0; i < 18; i++)
              CarbonTab(label: 'Category ${i + 1}', disabled: i == 2),
          ]
        : const <CarbonTab>[
            CarbonTab(label: 'Overview'),
            CarbonTab(label: 'Specs'),
            CarbonTab(label: 'Reviews'),
          ];
    final List<Widget> panels = _many
        ? <Widget>[
            for (int i = 0; i < 18; i++) panel('Category ${i + 1} content.'),
          ]
        : <Widget>[
            panel('Overview content.'),
            panel('Technical specifications.'),
            panel('Customer reviews.'),
          ];
    final CarbonTabActivationMode activation = _manual
        ? CarbonTabActivationMode.manual
        : CarbonTabActivationMode.automatic;
    return DemoScaffold(
      title: 'Tabs',
      description:
          'Overflowing tabs stay reachable. Manual activation moves focus '
          'with arrows and selects with Enter or Space.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: _many && !_vertical ? 320 : 480,
        child: _vertical
            ? SizedBox(
                height: 260,
                child: CarbonTabsVertical(
                  tabs: tabs,
                  panels: panels,
                  activation: activation,
                ),
              )
            : CarbonTabs(
                tabs: tabs,
                panels: panels,
                activation: activation,
                variant: _variant,
              ),
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Many tabs',
          value: _many,
          onChanged: (bool many) => setState(() => _many = many),
        ),
        boolKnob(
          label: 'Manual activation',
          value: _manual,
          onChanged: (bool manual) => setState(() => _manual = manual),
        ),
        choiceKnob<CarbonTabVariant>(
          label: 'Style',
          value: _variant,
          options: CarbonTabVariant.values,
          labelOf: (CarbonTabVariant v) => v.name,
          onChanged: (CarbonTabVariant variant) =>
              setState(() => _variant = variant),
        ),
        boolKnob(
          label: 'Vertical',
          value: _vertical,
          onChanged: (bool v) => setState(() => _vertical = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _AccordionPage extends StatelessWidget {
  const _AccordionPage();
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    Widget body(String s) =>
        Text(s, style: CarbonTypeStyles.body01.copyWith(color: t.textPrimary));
    return DemoScaffold(
      title: 'Accordion',
      description: 'Vertically stacked, expandable sections.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 480,
        child: CarbonAccordion(
          children: <CarbonAccordionItem>[
            CarbonAccordionItem(
              title: 'Shipping',
              initiallyOpen: true,
              child: body('Free standard shipping on orders over €50.'),
            ),
            CarbonAccordionItem(
              title: 'Returns',
              child: body('30-day returns.'),
            ),
            CarbonAccordionItem(
              title: 'Warranty',
              child: body('Two-year warranty.'),
            ),
          ],
        ),
      ),
      code: exampleSource,
    );
  }
}

class _ContentSwitcherPage extends StatefulWidget {
  const _ContentSwitcherPage();
  @override
  State<_ContentSwitcherPage> createState() => _ContentSwitcherPageState();
}

class _ContentSwitcherPageState extends State<_ContentSwitcherPage> {
  int _index = 0;
  bool _iconOnly = false;
  bool _disabled = false;
  double _width = 360;
  double _textScale = 1;
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Content switcher',
      description: 'Equal text segments keep readable label space and scroll in narrow layouts. Arrow keys, Home and End reveal the chosen view; icon-only views retain intrinsic sizing.',
      previewAlignment: Alignment.topLeft,
      preview: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_textScale)),
        child: SizedBox(
          width: _iconOnly ? null : _width,
          child: CarbonContentSwitcher(
            selectedIndex: _index,
            onChanged: (int i) => setState(() => _index = i),
            switches: _iconOnly
                ? <CarbonSwitch>[
                    const CarbonSwitch(
                      icon: CarbonIcons.list,
                      semanticLabel: 'List view',
                    ),
                    const CarbonSwitch(
                      icon: CarbonIcons.grid,
                      semanticLabel: 'Grid view',
                    ),
                    CarbonSwitch(
                      icon: CarbonIcons.archive,
                      semanticLabel: 'Archived view',
                      disabled: _disabled,
                    ),
                  ]
                : <CarbonSwitch>[
                    const CarbonSwitch(text: 'Day'),
                    const CarbonSwitch(text: 'Week'),
                    CarbonSwitch(text: 'Month', disabled: _disabled),
                  ],
          ),
        ),
      ),
      controls: <Widget>[
        choiceKnob<double>(
          label: 'Control width',
          value: _width,
          options: const <double>[160, 320, 360],
          labelOf: (double value) => '${value.toInt()}px',
          onChanged: (double value) => setState(() => _width = value),
        ),
        choiceKnob<double>(
          label: 'Text scale',
          value: _textScale,
          options: const <double>[1, 1.3, 2],
          labelOf: (double value) => '$value×',
          onChanged: (double value) => setState(() => _textScale = value),
        ),
        boolKnob(
          label: 'Icon only',
          value: _iconOnly,
          onChanged: (bool value) => setState(() => _iconOnly = value),
        ),
        boolKnob(
          label: 'Disable last segment',
          value: _disabled,
          onChanged: (bool value) => setState(() => _disabled = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _BreadcrumbPage extends StatefulWidget {
  const _BreadcrumbPage();
  @override
  State<_BreadcrumbPage> createState() => _BreadcrumbPageState();
}

class _BreadcrumbPageState extends State<_BreadcrumbPage> {
  bool _many = false;
  bool _narrow = false;
  bool _rtl = false;
  bool _trailing = false;
  String _opened = 'none';
  CarbonLinkSize _size = CarbonLinkSize.md;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final List<String> labels = _many
        ? <String>[
            'Home',
            'Organization',
            'Projects',
            'Research',
            'Reports',
            'Quarter',
            'Breadcrumb',
          ]
        : <String>['Home', 'Components', 'Breadcrumb'];
    final List<CarbonBreadcrumbItem> items = <CarbonBreadcrumbItem>[
      for (int i = 0; i < labels.length; i++)
        CarbonBreadcrumbItem(
          label: labels[i],
          isCurrentPage: i == labels.length - 1,
          onPressed: () => setState(() => _opened = labels[i]),
        ),
    ];
    return DemoScaffold(
      title: 'Breadcrumb',
      description: 'A measured trail that keeps the first and current page visible and discloses hidden ancestors through a keyboard-accessible menu.',
      previewAlignment: Alignment.topLeft,
      preview: Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: SizedBox(
          width: _narrow ? 320 : 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonBreadcrumb(
                items: items,
                size: _size,
                noTrailingSlash: !_trailing,
              ),
              const SizedBox(height: CarbonSpacing.spacing05),
              Text(
                'Opened: $_opened',
                style: CarbonTypeStyles.body01.copyWith(
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Many crumbs',
          value: _many,
          onChanged: (bool value) => setState(() => _many = value),
        ),
        boolKnob(
          label: 'Narrow trail',
          value: _narrow,
          onChanged: (bool value) => setState(() => _narrow = value),
        ),
        boolKnob(
          label: 'RTL trail',
          value: _rtl,
          onChanged: (bool value) => setState(() => _rtl = value),
        ),
        boolKnob(
          label: 'Trailing slash',
          value: _trailing,
          onChanged: (bool value) => setState(() => _trailing = value),
        ),
        choiceKnob<CarbonLinkSize>(
          label: 'Size',
          value: _size,
          options: CarbonLinkSize.values,
          labelOf: (CarbonLinkSize value) => value.name,
          onChanged: (CarbonLinkSize value) => setState(() => _size = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _PaginationPage extends StatefulWidget {
  const _PaginationPage();
  @override
  State<_PaginationPage> createState() => _PaginationPageState();
}

class _PaginationPageState extends State<_PaginationPage> {
  int _page = 1;
  int _pageSize = 10;
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Pagination',
      description: 'Page through a large result set.',
      previewAlignment: Alignment.topLeft,
      preview: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1040,
          child: CarbonPagination(
            page: _page,
            pageSize: _pageSize,
            totalItems: 248,
            onPageChanged: (int p) => setState(() => _page = p),
            onPageSizeChanged: (int s) => setState(() {
              _pageSize = s;
              _page = 1;
            }),
          ),
        ),
      ),
      code: exampleSource,
    );
  }
}

class _ModalPage extends StatefulWidget {
  const _ModalPage();
  @override
  State<_ModalPage> createState() => _ModalPageState();
}

class _ModalPageState extends State<_ModalPage> {
  bool _open = false;
  bool _fullWidth = false;
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return DemoScaffold(
      title: 'Modal',
      description: 'A focus-trapping dialog.',
      preview: Stack(
        children: <Widget>[
          CarbonButton(
            label: 'Open modal',
            onPressed: () => setState(() => _open = true),
          ),
          CarbonModal(
            open: _open,
            title: _fullWidth ? 'Members' : 'Delete service?',
            onClose: () => setState(() => _open = false),
            danger: !_fullWidth,
            isFullWidth: _fullWidth,
            primaryButton: CarbonModalAction(
              label: _fullWidth ? 'Add member' : 'Delete',
              onPressed: () => setState(() => _open = false),
            ),
            secondaryButton: CarbonModalAction(
              label: 'Cancel',
              onPressed: () => setState(() => _open = false),
            ),
            child: _fullWidth
                ? const CarbonDataTable(
                    columns: <CarbonTableColumn>[
                      CarbonTableColumn(title: 'Name'),
                      CarbonTableColumn(title: 'Role'),
                    ],
                    rows: <CarbonTableRow>[
                      CarbonTableRow(
                        cells: <Widget>[Text('Ada'), Text('Admin')],
                      ),
                      CarbonTableRow(
                        cells: <Widget>[Text('Grace'), Text('Editor')],
                      ),
                    ],
                  )
                : Text(
                    'This action cannot be undone.',
                    style: CarbonTypeStyles.body01.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
          ),
        ],
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Full width',
          value: _fullWidth,
          onChanged: (bool v) => setState(() => _fullWidth = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _DialogPage extends StatefulWidget {
  const _DialogPage();
  @override
  State<_DialogPage> createState() => _DialogPageState();
}

class _DialogPageState extends State<_DialogPage> {
  bool _open = false;
  bool _modal = true;
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Dialog',
      description: 'The composable dialog, modal or non-modal.',
      preview: Stack(
        children: <Widget>[
          CarbonButton(
            label: 'Open dialog',
            onPressed: () => setState(() => _open = true),
          ),
          CarbonDialog(
            open: _open,
            modal: _modal,
            onRequestClose: () => setState(() => _open = false),
            children: <Widget>[
              CarbonDialogHeader(
                controls: CarbonDialogControls(
                  children: <Widget>[
                    CarbonDialogCloseButton(
                      onPressed: () => setState(() => _open = false),
                    ),
                  ],
                ),
                children: const <Widget>[
                  CarbonDialogSubtitle('Account'),
                  CarbonDialogTitle('Update billing details'),
                ],
              ),
              const CarbonDialogBody(
                child: Text(
                  'Changing the billing contact updates every invoice '
                  'issued after the change.',
                ),
              ),
              CarbonDialogFooter(
                children: <Widget>[
                  CarbonButton(
                    label: 'Cancel',
                    kind: CarbonButtonKind.secondary,
                    size: CarbonButtonSize.xl,
                    onPressed: () => setState(() => _open = false),
                  ),
                  CarbonButton(
                    label: 'Save',
                    size: CarbonButtonSize.xl,
                    onPressed: () => setState(() => _open = false),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Modal',
          value: _modal,
          onChanged: (bool v) => setState(() => _modal = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _NotificationPage extends StatefulWidget {
  const _NotificationPage();

  @override
  State<_NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<_NotificationPage> {
  bool _narrow = false;
  bool _rtl = false;
  bool _scaled = false;
  bool _lowContrast = false;
  int _actions = 0;
  int _closes = 0;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Notification',
      description: 'Inline, toast, actionable and callout notifications.',
      previewAlignment: Alignment.topLeft,
      controls: <Widget>[
        boolKnob(
          label: 'Narrow notifications',
          value: _narrow,
          onChanged: (bool value) => setState(() => _narrow = value),
        ),
        boolKnob(
          label: 'RTL notifications',
          value: _rtl,
          onChanged: (bool value) => setState(() => _rtl = value),
        ),
        boolKnob(
          label: 'Scale notification text',
          value: _scaled,
          onChanged: (bool value) => setState(() => _scaled = value),
        ),
        boolKnob(
          label: 'Low contrast',
          value: _lowContrast,
          onChanged: (bool value) => setState(() => _lowContrast = value),
        ),
      ],
      preview: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_scaled ? 2 : 1)),
        child: Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: SizedBox(
            width: _narrow ? 320 : 760,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Actions: $_actions; closes: $_closes'),
                const SizedBox(height: 16),
                for (final CarbonNotificationKind kind
                    in CarbonNotificationKind.values)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: CarbonSpacing.spacing05,
                    ),
                    child: CarbonInlineNotification(
                      kind: kind,
                      title:
                          '${kind.name[0].toUpperCase()}${kind.name.substring(1)}',
                      subtitle: 'An inline ${kind.name} notification.',
                      lowContrast: _lowContrast,
                      onClose: () => setState(() => _closes++),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: CarbonSpacing.spacing05,
                  ),
                  child: CarbonActionableNotification(
                    kind: CarbonNotificationKind.warning,
                    title: 'Connection lost',
                    subtitle: 'Supporting detail for the optional action.',
                    actionLabel: 'Retry operation',
                    lowContrast: _lowContrast,
                    onAction: () => setState(() => _actions++),
                    onClose: () => setState(() => _closes++),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: CarbonSpacing.spacing05,
                  ),
                  child: CarbonToastNotification(
                    kind: CarbonNotificationKind.success,
                    title: 'Changes saved',
                    subtitle: 'Your changes are available.',
                    caption: 'Just now',
                    lowContrast: _lowContrast,
                    onClose: () => setState(() => _closes++),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: CarbonSpacing.spacing05,
                  ),
                  child: CarbonCallout(
                    title: 'Callout',
                    subtitle: 'A static, non-dismissible callout.',
                    actionLabel: 'Review',
                    lowContrast: _lowContrast,
                    onAction: () => setState(() => _actions++),
                  ),
                ),
                const CarbonCallout(
                  kind: CarbonNotificationKind.warning,
                  title: 'Callout',
                  subtitle: 'A low-contrast warning callout.',
                  lowContrast: true,
                ),
              ],
            ),
          ),
        ),
      ),
      code: exampleSource,
    );
  }
}

class _ProgressIndicatorPage extends StatefulWidget {
  const _ProgressIndicatorPage();

  @override
  State<_ProgressIndicatorPage> createState() => _ProgressIndicatorPageState();
}

class _ProgressIndicatorPageState extends State<_ProgressIndicatorPage> {
  int _currentIndex = 1;
  bool _vertical = false;
  bool _interactive = true;
  bool _narrow = false;
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Progress indicator',
      description: 'Fixed Carbon step spacing; narrow horizontal flows scroll. Select an enabled step with pointer, Enter or Space.',
      previewAlignment: Alignment.topLeft,
      preview: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_scale)),
        child: SizedBox(
          width: _narrow ? 160 : 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonProgressIndicator(
                currentIndex: _currentIndex,
                vertical: _vertical,
                interactive: _interactive,
                onStepSelected: (int index) =>
                    setState(() => _currentIndex = index),
                steps: const <CarbonProgressStep>[
                  CarbonProgressStep(label: 'Account'),
                  CarbonProgressStep(
                    label: 'Profile',
                    secondaryLabel: 'Optional',
                  ),
                  CarbonProgressStep(
                    label: 'Confirm with a deliberately long name',
                  ),
                  CarbonProgressStep(label: 'Problem', invalid: true),
                  CarbonProgressStep(label: 'Locked', disabled: true),
                ],
              ),
              Text(
                'Current step: ${_currentIndex + 1}',
                style: CarbonTypeStyles.body01.copyWith(
                  color: CarbonTheme.of(context).textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Narrow flow',
          value: _narrow,
          onChanged: (bool value) => setState(() => _narrow = value),
        ),
        choiceKnob<double>(
          label: 'Text scale',
          value: _scale,
          options: const <double>[1, 1.3, 2],
          labelOf: (double value) => '$value×',
          onChanged: (double value) => setState(() => _scale = value),
        ),
        boolKnob(
          label: 'Vertical',
          value: _vertical,
          onChanged: (bool value) => setState(() => _vertical = value),
        ),
        boolKnob(
          label: 'Interactive',
          value: _interactive,
          onChanged: (bool value) => setState(() => _interactive = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _StructuredListPage extends StatelessWidget {
  const _StructuredListPage();
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    Widget cell(String s) => Text(
      s,
      style: CarbonTypeStyles.bodyCompact01.copyWith(color: t.textPrimary),
    );
    return DemoScaffold(
      title: 'Structured list',
      description: 'A simple, read-only data list.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 520,
        child: CarbonStructuredList(
          headers: const <String>['Name', 'Type', 'Status'],
          rows: <CarbonStructuredListRow>[
            CarbonStructuredListRow(
              cells: <Widget>[
                cell('api-gateway'),
                cell('Service'),
                cell('Running'),
              ],
            ),
            CarbonStructuredListRow(
              cells: <Widget>[cell('worker-01'), cell('Job'), cell('Idle')],
            ),
          ],
        ),
      ),
      code: exampleSource,
    );
  }
}

class _AILabelPage extends StatefulWidget {
  const _AILabelPage();
  @override
  State<_AILabelPage> createState() => _AILabelPageState();
}

class _AILabelPageState extends State<_AILabelPage> {
  CarbonAILabelSize _size = CarbonAILabelSize.sm;
  bool _inline = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return DemoScaffold(
      title: 'AI label',
      description: 'Marks AI-generated content; opens an explanatory callout.',
      preview: CarbonAILabel(
        size: _size,
        inline: _inline,
        textLabel: _inline ? 'Generated' : null,
        content: Text(
          'This content was generated by AI.',
          style: CarbonTypeStyles.body01.copyWith(color: t.textPrimary),
        ),
      ),
      controls: <Widget>[
        choiceKnob<CarbonAILabelSize>(
          label: 'Size',
          value: _size,
          options: CarbonAILabelSize.values,
          labelOf: (CarbonAILabelSize size) => size.name,
          onChanged: (CarbonAILabelSize size) => setState(() => _size = size),
        ),
        boolKnob(
          label: 'Inline',
          value: _inline,
          onChanged: (bool value) => setState(() => _inline = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _ChatButtonPage extends StatefulWidget {
  const _ChatButtonPage();
  @override
  State<_ChatButtonPage> createState() => _ChatButtonPageState();
}

class _ChatButtonPageState extends State<_ChatButtonPage> {
  static const List<CarbonButtonKind> _kinds = <CarbonButtonKind>[
    CarbonButtonKind.primary,
    CarbonButtonKind.secondary,
    CarbonButtonKind.tertiary,
    CarbonButtonKind.ghost,
  ];

  CarbonButtonKind _kind = CarbonButtonKind.primary;
  CarbonChatButtonSize _size = CarbonChatButtonSize.lg;
  bool _quickAction = false;
  bool _selected = false;
  bool _icon = false;
  bool _disabled = false;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Chat button',
      description: 'The AI chat pill button, with a quick-action mode.',
      preview: CarbonChatButton(
        label: _quickAction ? 'Summarize the chat' : 'Ask a question',
        kind: _kind,
        size: _size,
        quickAction: _quickAction,
        isSelected: _quickAction && _selected,
        icon: _icon ? CarbonIcons.send : null,
        onPressed: _disabled ? null : () {},
      ),
      controls: <Widget>[
        choiceKnob<CarbonButtonKind>(
          label: 'Kind',
          value: _kind,
          options: _kinds,
          labelOf: (CarbonButtonKind kind) => kind.name,
          onChanged: (CarbonButtonKind kind) => setState(() => _kind = kind),
        ),
        choiceKnob<CarbonChatButtonSize>(
          label: 'Size',
          value: _size,
          options: CarbonChatButtonSize.values,
          labelOf: (CarbonChatButtonSize size) => size.name,
          onChanged: (CarbonChatButtonSize size) =>
              setState(() => _size = size),
        ),
        boolKnob(
          label: 'Quick action',
          value: _quickAction,
          onChanged: (bool value) => setState(() => _quickAction = value),
        ),
        boolKnob(
          label: 'Selected',
          value: _selected,
          onChanged: (bool value) => setState(() => _selected = value),
        ),
        boolKnob(
          label: 'Icon',
          value: _icon,
          onChanged: (bool value) => setState(() => _icon = value),
        ),
        boolKnob(
          label: 'Disabled',
          value: _disabled,
          onChanged: (bool value) => setState(() => _disabled = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _ContainedListPage extends StatefulWidget {
  const _ContainedListPage();
  @override
  State<_ContainedListPage> createState() => _ContainedListPageState();
}

class _ContainedListPageState extends State<_ContainedListPage> {
  CarbonContainedListSize _size = CarbonContainedListSize.md;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Contained list',
      description: 'A titled list of rows; items can be clickable.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: CarbonContainedList(
          label: const Text('Recent files'),
          size: _size,
          children: <Widget>[
            const CarbonContainedListItem(
              icon: CarbonIcons.document,
              child: Text('report.pdf'),
            ),
            CarbonContainedListItem(
              icon: CarbonIcons.document,
              onPressed: () {},
              child: const Text('notes.txt'),
            ),
            const CarbonContainedListItem(
              icon: CarbonIcons.document,
              child: Text('archive.zip'),
            ),
          ],
        ),
      ),
      controls: <Widget>[
        choiceKnob<CarbonContainedListSize>(
          label: 'Size',
          value: _size,
          options: CarbonContainedListSize.values,
          labelOf: (CarbonContainedListSize s) => s.name,
          onChanged: (CarbonContainedListSize s) => setState(() => _size = s),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _ContextMenuPage extends StatefulWidget {
  const _ContextMenuPage();

  @override
  State<_ContextMenuPage> createState() => _ContextMenuPageState();
}

class _ContextMenuPageState extends State<_ContextMenuPage> {
  bool _focusVisible = false;
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return DemoScaffold(
      title: 'Context menu',
      description:
          'Focus the target and press Shift+F10 or the Context Menu '
          'key. Secondary click and long press also open the menu.',
      preview: CarbonContextMenu(
        items: <Widget>[
          CarbonMenuItem(label: 'Cut', icon: CarbonIcons.cut, onPressed: () {}),
          CarbonMenuItem(
            label: 'Copy',
            icon: CarbonIcons.copy,
            onPressed: () {},
          ),
          CarbonMenuItem(
            label: 'Paste',
            icon: CarbonIcons.paste,
            onPressed: () {},
          ),
        ],
        child: FocusableActionDetector(
          onShowFocusHighlight: (bool visible) =>
              setState(() => _focusVisible = visible),
          child: Semantics(
            hint: 'Press Shift+F10 or the Context Menu key for actions',
            child: CarbonFocusRing(
              visible: _focusVisible,
              inset: true,
              child: Container(
                width: 280,
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.layer01,
                  border: Border.all(color: t.borderSubtle00),
                ),
                child: Text(
                  'Context menu target',
                  style: CarbonTypeStyles.body01.copyWith(
                    color: t.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      code: exampleSource,
    );
  }
}

class _PaginationNavPage extends StatefulWidget {
  const _PaginationNavPage();
  @override
  State<_PaginationNavPage> createState() => _PaginationNavPageState();
}

class _PaginationNavPageState extends State<_PaginationNavPage> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Pagination nav',
      description: 'Page-number navigation with overflow truncation.',
      preview: CarbonPaginationNav(
        totalItems: 12,
        page: _page,
        itemsShown: 7,
        onChange: (int p) => setState(() => _page = p),
      ),
      code: exampleSource,
    );
  }
}
