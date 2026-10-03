// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import '../demo_scaffold.dart';
import '../knobs.dart';
import '../registry.dart';

/// Tier D — complex and data-dense components.
final GalleryCategory tierDCategory = GalleryCategory(
  title: 'Complex & data',
  icon: CarbonIcons.dataTable,
  entries: <GalleryEntry>[
    GalleryEntry(
      slug: 'data-table',
      title: 'Data table',
      builder: () => const _DataTablePage(),
    ),
    GalleryEntry(
      slug: 'date-picker',
      title: 'Date picker',
      builder: () => const _DatePickerPage(),
    ),
    GalleryEntry(
      slug: 'time-picker',
      title: 'Time picker',
      builder: () => const _TimePickerPage(),
    ),
    GalleryEntry(
      slug: 'file-uploader',
      title: 'File uploader',
      builder: () => const _FileUploaderPage(),
    ),
    GalleryEntry(
      slug: 'tree-view',
      title: 'Tree view',
      builder: () => const _TreeViewPage(),
    ),
    GalleryEntry(
      slug: 'page-header',
      title: 'Page header',
      builder: () => const _PageHeaderPage(),
    ),
  ],
);

class _DataTablePage extends StatefulWidget {
  const _DataTablePage();
  @override
  State<_DataTablePage> createState() => _DataTablePageState();
}

class _DataTablePageState extends State<_DataTablePage> {
  int? _sortColumn;
  CarbonSortDirection _sortDir = CarbonSortDirection.none;
  Set<int> _selected = <int>{};
  bool _multi = true;
  bool _selectionEnabled = true;

  static const List<List<String>> _data = <List<String>>[
    <String>['Load balancer 1', 'HTTP', 'Active'],
    <String>['Load balancer 2', 'HTTP', 'Disabled'],
    <String>['Load balancer 3', 'HTTPS', 'Active'],
  ];

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData t = CarbonTheme.of(context);
    Widget cell(String s) => Text(
      s,
      style: CarbonTypeStyles.bodyCompact01.copyWith(color: t.textPrimary),
    );
    return DemoScaffold(
      title: 'Data table',
      description: 'Sortable, selectable rows with a zebra option.',
      previewAlignment: Alignment.topLeft,
      preview: CarbonDataTable(
        title: 'Load balancers',
        description: 'A list of your edge load balancers.',
        zebra: true,
        selection: _multi
            ? CarbonTableSelection.multi
            : CarbonTableSelection.single,
        selectedRows: _selected,
        onSelectionChanged: _selectionEnabled
            ? (Set<int> s) => setState(() => _selected = s)
            : null,
        sortColumnIndex: _sortColumn,
        sortDirection: _sortDir,
        onSort: (int col) => setState(() {
          if (_sortColumn != col) {
            _sortColumn = col;
            _sortDir = CarbonSortDirection.ascending;
          } else {
            _sortDir = switch (_sortDir) {
              CarbonSortDirection.none => CarbonSortDirection.ascending,
              CarbonSortDirection.ascending => CarbonSortDirection.descending,
              CarbonSortDirection.descending => CarbonSortDirection.none,
            };
          }
        }),
        columns: const <CarbonTableColumn>[
          CarbonTableColumn(title: 'Name', sortable: true),
          CarbonTableColumn(title: 'Protocol', sortable: true),
          CarbonTableColumn(title: 'Status'),
        ],
        rows: <CarbonTableRow>[
          for (final List<String> row in _data)
            CarbonTableRow(
              cells: <Widget>[cell(row[0]), cell(row[1]), cell(row[2])],
            ),
        ],
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Multi-select',
          value: _multi,
          onChanged: (bool value) => setState(() {
            _multi = value;
            _selected = <int>{};
          }),
        ),
        boolKnob(
          label: 'Selection enabled',
          value: _selectionEnabled,
          onChanged: (bool value) => setState(() => _selectionEnabled = value),
        ),
      ],
      code:
          'CarbonDataTable(columns: <…>[…], rows: <…>[…], selection: CarbonTableSelection.${_multi ? 'multi' : 'single'}, onSelectionChanged: ${_selectionEnabled ? '(rows) { … }' : 'null'});',
    );
  }
}

class _DatePickerPage extends StatefulWidget {
  const _DatePickerPage();
  @override
  State<_DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<_DatePickerPage> {
  DateTime? _value = DateTime(2026, 6, 16);
  CarbonDateRange? _range = CarbonDateRange(
    DateTime(2026, 6, 10),
    DateTime(2026, 6, 19),
  );
  bool _rangeMode = false;
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Date picker',
      description:
          'A calendar in single and range modes. A range is committed after '
          'both dates are picked; dismissing the calendar discards the draft.',
      previewAlignment: Alignment.topCenter,
      preview: _rangeMode
          ? CarbonDateRangePicker(
              value: _range,
              onChanged: (CarbonDateRange r) => setState(() => _range = r),
            )
          : SizedBox(
              width: 288,
              child: CarbonDatePicker(
                labelText: 'Appointment date',
                value: _value,
                onChanged: (DateTime d) => setState(() => _value = d),
              ),
            ),
      controls: <Widget>[
        boolKnob(
          label: 'Range',
          value: _rangeMode,
          onChanged: (bool v) => setState(() => _rangeMode = v),
        ),
      ],
      code: _rangeMode
          ? 'CarbonDateRangePicker(value: _range, onChanged: …);'
          : 'CarbonDatePicker(labelText: \'…\', onChanged: …);',
    );
  }
}

class _TimePickerPage extends StatelessWidget {
  const _TimePickerPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Time picker',
      description: 'A compact time field with AM/PM and timezone selects.',
      previewAlignment: Alignment.topCenter,
      preview: CarbonTimePicker(
        labelText: 'Start time',
        initialValue: '09:30',
        children: <Widget>[
          CarbonTimePickerSelect<String>(
            labelText: 'AM/PM',
            value: 'AM',
            items: const <CarbonSelectItem<String>>[
              CarbonSelectItem<String>(value: 'AM', label: 'AM'),
              CarbonSelectItem<String>(value: 'PM', label: 'PM'),
            ],
            onChanged: (_) {},
          ),
        ],
      ),
      code: 'CarbonTimePicker(labelText: \'Start time\', children: <…>[…]);',
    );
  }
}

class _FileUploaderPage extends StatelessWidget {
  const _FileUploaderPage();
  @override
  Widget build(BuildContext context) {
    return const DemoScaffold(
      title: 'File uploader',
      description: 'A drop zone plus selected-file rows.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 360,
        child: CarbonFileUploader(
          labelTitle: 'Upload files',
          labelDescription: 'Max 5 files, 500kb each.',
          items: <CarbonFileUploaderItem>[
            CarbonFileUploaderItem(
              name: 'report.pdf',
              status: CarbonFileStatus.complete,
            ),
            CarbonFileUploaderItem(name: 'draft.pdf'),
          ],
          child: CarbonFileUploaderDropContainer(
            label: 'Drag and drop files here or click to upload',
          ),
        ),
      ),
      code: 'CarbonFileUploader(labelTitle: \'…\', items: <…>[…]);',
    );
  }
}

class _TreeViewPage extends StatefulWidget {
  const _TreeViewPage();
  @override
  State<_TreeViewPage> createState() => _TreeViewPageState();
}

class _TreeViewPageState extends State<_TreeViewPage> {
  Object? _selected = 'main';
  Set<Object> _expanded = <Object>{'src'};
  Set<Object> _multiSelected = <Object>{'main', 'app'};
  Object? _active = 'app';

  static const List<CarbonTreeNode> _nodes = <CarbonTreeNode>[
    CarbonTreeNode(
      id: 'src',
      label: 'src',
      icon: CarbonIcons.folder,
      children: <CarbonTreeNode>[
        CarbonTreeNode(id: 'main', label: 'main.dart'),
        CarbonTreeNode(id: 'app', label: 'app.dart'),
      ],
    ),
    CarbonTreeNode(id: 'readme', label: 'README.md'),
  ];

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Tree view',
      description:
          'A hierarchical, keyboard-navigable tree; multiselect toggles '
          'with Ctrl/Cmd-click and extends with Ctrl+Shift+Home/End.',
      previewAlignment: Alignment.topLeft,
      preview: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 280,
            child: CarbonTreeView(
              label: 'Files',
              selectedId: _selected,
              expandedIds: _expanded,
              onExpansionChanged: (Set<Object> ids) =>
                  setState(() => _expanded = ids),
              onSelect: (Object id) => setState(() => _selected = id),
              nodes: _nodes,
            ),
          ),
          const SizedBox(height: CarbonSpacing.spacing06),
          SizedBox(
            width: 280,
            child: CarbonTreeView(
              label: 'Files (multiselect)',
              multiselect: true,
              selectedIds: _multiSelected,
              activeId: _active,
              initiallyExpandedIds: const <Object>{'src'},
              onSelectionChanged: (Set<Object> ids) =>
                  setState(() => _multiSelected = ids),
              onActivate: (Object id) => setState(() => _active = id),
              nodes: _nodes,
            ),
          ),
        ],
      ),
      code:
          'CarbonTreeView(label: \'Files\', multiselect: true, '
          'selectedIds: {…}, nodes: <CarbonTreeNode>[…]);',
    );
  }
}

class _PageHeaderPage extends StatelessWidget {
  const _PageHeaderPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Page header',
      description: 'A page-level header band with breadcrumb and actions.',
      previewAlignment: Alignment.topLeft,
      preview: CarbonPageHeader(
        title: 'Quarterly report',
        subtitle: 'Finance',
        body: 'A summary of revenue and spend for the quarter.',
        breadcrumbs: <CarbonBreadcrumbItem>[
          CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
          CarbonBreadcrumbItem(label: 'Finance', onPressed: () {}),
        ],
        pageActions: CarbonButton(
          label: 'Edit',
          kind: CarbonButtonKind.tertiary,
          onPressed: () {},
        ),
      ),
      code: 'CarbonPageHeader(title: \'…\', breadcrumbs: <…>[…]);',
    );
  }
}
