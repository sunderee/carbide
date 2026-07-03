// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the GNU
// Affero General Public License v3.0 or later.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import '../demo_scaffold.dart';
import '../knobs.dart';
import '../registry.dart';

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
  String _value = 'cyan';
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Dropdown',
      description: 'A single-select on the list-box chrome.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: CarbonDropdown<String>(
          titleText: 'Favourite colour',
          selectedItem: _value,
          onChanged: (String v) => setState(() => _value = v),
          items: const <CarbonDropdownItem<String>>[
            CarbonDropdownItem<String>(value: 'cyan', label: 'Cyan'),
            CarbonDropdownItem<String>(value: 'magenta', label: 'Magenta'),
            CarbonDropdownItem<String>(value: 'teal', label: 'Teal'),
          ],
        ),
      ),
      code: 'CarbonDropdown<String>(titleText: \'…\', items: <…>[…]);',
    );
  }
}

class _ComboBoxPage extends StatefulWidget {
  const _ComboBoxPage();
  @override
  State<_ComboBoxPage> createState() => _ComboBoxPageState();
}

class _ComboBoxPageState extends State<_ComboBoxPage> {
  String? _value;
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Combo box',
      description: 'A filterable single-select.',
      previewAlignment: Alignment.topCenter,
      preview: SizedBox(
        width: 320,
        child: CarbonComboBox<String>(
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
      code: 'CarbonComboBox<String>(titleText: \'Country\', items: <…>[…]);',
    );
  }
}

class _MultiSelectPage extends StatefulWidget {
  const _MultiSelectPage();
  @override
  State<_MultiSelectPage> createState() => _MultiSelectPageState();
}

class _MultiSelectPageState extends State<_MultiSelectPage> {
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
          titleText: 'Permissions',
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
      code: 'CarbonMultiSelect<String>(titleText: \'…\', items: <…>[…]);',
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
      code: 'CarbonTooltip(label: \'…\', child: CarbonButton(...));',
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
      code: 'CarbonToggletip(content: Text(\'…\'));',
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
      code: 'CarbonOverflowMenu(items: <Widget>[CarbonMenuItem(...)]);',
    );
  }
}

class _TabsPage extends StatelessWidget {
  const _TabsPage();
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
    return DemoScaffold(
      title: 'Tabs',
      description: 'Line tabs switching between panels.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 480,
        child: CarbonTabs(
          tabs: const <CarbonTab>[
            CarbonTab(label: 'Overview'),
            CarbonTab(label: 'Specs'),
            CarbonTab(label: 'Reviews'),
          ],
          panels: <Widget>[
            panel('Overview content.'),
            panel('Technical specifications.'),
            panel('Customer reviews.'),
          ],
        ),
      ),
      code: 'CarbonTabs(tabs: <CarbonTab>[…], panels: <Widget>[…]);',
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
      code: 'CarbonAccordion(children: <CarbonAccordionItem>[…]);',
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
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Content switcher',
      description: 'A segmented control for mutually exclusive views.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 360,
        child: CarbonContentSwitcher(
          selectedIndex: _index,
          onChanged: (int i) => setState(() => _index = i),
          switches: const <CarbonSwitch>[
            CarbonSwitch(text: 'Day'),
            CarbonSwitch(text: 'Week'),
            CarbonSwitch(text: 'Month'),
          ],
        ),
      ),
      code: 'CarbonContentSwitcher(switches: <CarbonSwitch>[…]);',
    );
  }
}

class _BreadcrumbPage extends StatelessWidget {
  const _BreadcrumbPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Breadcrumb',
      description: 'A trail of ancestor pages.',
      previewAlignment: Alignment.topLeft,
      preview: CarbonBreadcrumb(
        items: <CarbonBreadcrumbItem>[
          CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
          CarbonBreadcrumbItem(label: 'Components', onPressed: () {}),
          const CarbonBreadcrumbItem(label: 'Breadcrumb', isCurrentPage: true),
        ],
      ),
      code: 'CarbonBreadcrumb(items: <CarbonBreadcrumbItem>[…]);',
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
      code: 'CarbonPagination(page: 1, pageSize: 10, totalItems: 248);',
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
      code:
          "CarbonModal(open: true, title: '…', "
          '${_fullWidth ? 'isFullWidth: true, ' : ''}'
          "child: …);",
    );
  }
}

class _NotificationPage extends StatelessWidget {
  const _NotificationPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Notification',
      description: 'Inline, toast and actionable notifications.',
      previewAlignment: Alignment.topLeft,
      preview: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final CarbonNotificationKind kind
              in CarbonNotificationKind.values)
            Padding(
              padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing05),
              child: CarbonInlineNotification(
                kind: kind,
                title: '${kind.name[0].toUpperCase()}${kind.name.substring(1)}',
                subtitle: 'An inline ${kind.name} notification.',
                onClose: () {},
              ),
            ),
        ],
      ),
      code:
          'CarbonInlineNotification(kind: CarbonNotificationKind.success, …);',
    );
  }
}

class _ProgressIndicatorPage extends StatelessWidget {
  const _ProgressIndicatorPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Progress indicator',
      description: 'Steps through a multi-stage flow.',
      previewAlignment: Alignment.topLeft,
      preview: const SizedBox(
        width: 560,
        child: CarbonProgressIndicator(
          currentIndex: 1,
          steps: <CarbonProgressStep>[
            CarbonProgressStep(label: 'Account'),
            CarbonProgressStep(label: 'Profile'),
            CarbonProgressStep(label: 'Confirm'),
          ],
        ),
      ),
      code: 'CarbonProgressIndicator(currentIndex: 1, steps: <…>[…]);',
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
      code: 'CarbonStructuredList(headers: <String>[…], rows: <…>[…]);',
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
      code: "CarbonAILabel(content: Text('…'));",
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
      code: "CarbonContainedList(label: Text('…'), children: <…>[…]);",
    );
  }
}

class _ContextMenuPage extends StatelessWidget {
  const _ContextMenuPage();
  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    return DemoScaffold(
      title: 'Context menu',
      description: 'Right-click (or long-press) the area to open a menu.',
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
        child: Container(
          width: 280,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.layer01,
            border: Border.all(color: t.borderSubtle00),
          ),
          child: Text(
            'Right-click here',
            style: CarbonTypeStyles.body01.copyWith(color: t.textSecondary),
          ),
        ),
      ),
      code: 'CarbonContextMenu(items: <…>[…], child: …);',
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
      code: 'CarbonPaginationNav(totalItems: 12, page: 0, onChange: …);',
    );
  }
}
