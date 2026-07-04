// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the GNU
// Affero General Public License v3.0 or later.

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
        selection: CarbonTableSelection.multi,
        selectedRows: _selected,
        onSelectionChanged: (Set<int> s) => setState(() => _selected = s),
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
      code: 'CarbonDataTable(columns: <…>[…], rows: <…>[…], zebra: true);',
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
      description: 'A self-contained calendar in single and range modes.',
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
    return DemoScaffold(
      title: 'File uploader',
      description: 'A drop zone plus selected-file rows.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 360,
        child: CarbonFileUploader(
          labelTitle: 'Upload files',
          labelDescription: 'Max 5 files, 500kb each.',
          items: const <CarbonFileUploaderItem>[
            CarbonFileUploaderItem(
              name: 'report.pdf',
              status: CarbonFileStatus.complete,
            ),
            CarbonFileUploaderItem(name: 'draft.pdf'),
          ],
          child: const CarbonFileUploaderDropContainer(
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
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Tree view',
      description: 'A hierarchical, keyboard-navigable tree.',
      previewAlignment: Alignment.topLeft,
      preview: SizedBox(
        width: 280,
        child: CarbonTreeView(
          label: 'Files',
          selectedId: _selected,
          initiallyExpandedIds: const <Object>{'src'},
          onSelect: (Object id) => setState(() => _selected = id),
          nodes: const <CarbonTreeNode>[
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
          ],
        ),
      ),
      code: 'CarbonTreeView(label: \'Files\', nodes: <CarbonTreeNode>[…]);',
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
