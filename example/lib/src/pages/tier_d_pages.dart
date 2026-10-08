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

part 'tier_d_pages.examples.g.dart';

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
  Set<Object> _selected = <Object>{};
  Set<Object> _expanded = <Object>{};
  bool _expandable = false;
  bool _multi = true;
  bool _selectionEnabled = true;
  bool _sticky = false;
  bool _empty = false;
  int _exports = 0;

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
    final List<List<String>> displayed = _empty
        ? <List<String>>[]
        : <List<String>>[
            ..._data,
            if (_sticky)
              for (int i = 4; i <= 20; i++)
                <String>['Load balancer $i', 'HTTPS', 'Active'],
          ];
    if (_sortColumn != null && _sortDir != CarbonSortDirection.none) {
      displayed.sort((a, b) {
        final int comparison = a[_sortColumn!].compareTo(b[_sortColumn!]);
        return _sortDir == CarbonSortDirection.ascending
            ? comparison
            : -comparison;
      });
    }
    return DemoScaffold(
      title: 'Data table',
      description:
          'Selection and expansion follow records when rows are sorted.',
      previewAlignment: Alignment.topLeft,
      preview: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CarbonDataTable(
            title: 'Load balancers',
            description: 'A list of your edge load balancers.',
            zebra: true,
            stickyHeader: _sticky,
            stickyHeaderHeight: 200,
            batchActions: <CarbonTableBatchAction>[
              CarbonTableBatchAction(
                label: 'Export selected',
                onPressed: () => setState(() => _exports++),
              ),
            ],
            selection: _multi
                ? CarbonTableSelection.multi
                : CarbonTableSelection.single,
            selectedRowIds: _selected,
            expandable: _expandable,
            expandedRowIds: _expanded,
            onExpansionChanged: (Set<Object> ids) =>
                setState(() => _expanded = ids),
            onSelectedRowIdsChanged: _selectionEnabled
                ? (Set<Object> s) => setState(() => _selected = s)
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
                  CarbonSortDirection.ascending =>
                    CarbonSortDirection.descending,
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
              for (final List<String> row in displayed)
                CarbonTableRow(
                  id: row[0],
                  label: row[0],
                  expandedContent: CarbonText('Details for ${row[0]}'),
                  cells: <Widget>[cell(row[0]), cell(row[1]), cell(row[2])],
                ),
            ],
          ),
          if (_empty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CarbonText('No load balancers. Add one to get started.'),
            ),
          CarbonText('Exports: $_exports'),
        ],
      ),
      controls: <Widget>[
        boolKnob(
          label: 'Sticky header',
          value: _sticky,
          onChanged: (bool v) => setState(() => _sticky = v),
        ),
        boolKnob(
          label: 'Empty',
          value: _empty,
          onChanged: (bool v) => setState(() => _empty = v),
        ),
        boolKnob(
          label: 'Multi-select',
          value: _multi,
          onChanged: (bool value) => setState(() {
            _multi = value;
            _selected = <Object>{};
          }),
        ),
        boolKnob(
          label: 'Expandable',
          value: _expandable,
          onChanged: (bool value) => setState(() => _expandable = value),
        ),
        boolKnob(
          label: 'Selection enabled',
          value: _selectionEnabled,
          onChanged: (bool value) => setState(() => _selectionEnabled = value),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _DatePickerPage extends StatefulWidget {
  const _DatePickerPage();
  @override
  State<_DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<_DatePickerPage> {
  bool _readOnly = false;
  bool _disabled = false;
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
              readOnly: _readOnly,
              disabled: _disabled,
              value: _range,
              onChanged: (CarbonDateRange r) => setState(() => _range = r),
            )
          : SizedBox(
              width: 288,
              child: CarbonDatePicker(
                readOnly: _readOnly,
                disabled: _disabled,
                labelText: 'Appointment date',
                value: _value,
                onChanged: (DateTime d) => setState(() => _value = d),
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
          label: 'Range',
          value: _rangeMode,
          onChanged: (bool v) => setState(() => _rangeMode = v),
        ),
      ],
      code: exampleSource,
    );
  }
}

class _TimePickerPage extends StatelessWidget {
  const _TimePickerPage();
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Time picker',
      description:
          'A compact time field with coordinated AM/PM. Enter or leaving the '
          'field group validates and normalizes the draft.',
      previewAlignment: Alignment.topCenter,
      preview: const CarbonTimePicker(
        labelText: 'Start time',
        initialValue: '09:30',
        format: CarbonTimeFormat.twelveHour,
        invalidText: 'Enter an hour from 1 to 12 and minutes from 0 to 59.',
      ),
      code: exampleSource,
    );
  }
}

class _FileUploaderPage extends StatefulWidget {
  const _FileUploaderPage();
  @override
  State<_FileUploaderPage> createState() => _FileUploaderPageState();
}

class _FileUploaderPageState extends State<_FileUploaderPage> {
  bool _hasFile = false;
  bool _invalid = false;
  bool _dragOver = false;
  CarbonFileStatus _status = CarbonFileStatus.edit;
  int _progress = 0;

  void _select() => setState(() {
    _hasFile = true;
    _invalid = false;
    _status = CarbonFileStatus.edit;
    _progress = 0;
  });
  void _start() => setState(() {
    _invalid = false;
    _status = CarbonFileStatus.uploading;
    _progress = 0;
  });
  void _advance() => setState(() {
    _progress += 50;
    if (_progress >= 100) _status = CarbonFileStatus.complete;
  });
  void _fail() => setState(() {
    _status = CarbonFileStatus.edit;
    _invalid = true;
  });
  void _remove() => setState(() {
    _hasFile = false;
    _invalid = false;
    _progress = 0;
    _status = CarbonFileStatus.edit;
  });

  String get _stateLabel => !_hasFile
      ? 'No file selected'
      : _invalid
      ? 'Upload failed'
      : switch (_status) {
          CarbonFileStatus.edit => 'Selected (pending upload)',
          CarbonFileStatus.uploading => 'Uploading: $_progress%',
          CarbonFileStatus.complete => 'Upload complete',
        };

  @override
  Widget build(BuildContext context) => DemoScaffold(
    title: 'File uploader',
    description: 'Carbide renders caller-supplied file state. This in-memory adapter simulates selection, progress, failure and removal. No system picker or network upload runs.',
    previewAlignment: Alignment.topLeft,
    preview: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CarbonFileUploader(
            labelTitle: 'Upload a demo report',
            labelDescription: 'Demo data only; application adapters own file access and transport.',
            items: <CarbonFileUploaderItem>[
              if (_hasFile)
                CarbonFileUploaderItem(
                  key: const ValueKey<String>('demo-report'),
                  name: 'demo-report.pdf',
                  status: _status,
                  invalid: _invalid,
                  errorSubject: 'Upload failed',
                  errorBody: 'Simulated failure. Retry or remove this file.',
                  onDelete: _remove,
                ),
            ],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CarbonFileUploaderButton(
                  label: 'Select demo file',
                  onPressed: _select,
                ),
                const SizedBox(height: 16),
                CarbonFileUploaderDropContainer(
                  label: 'Simulate dropping demo-report.pdf',
                  onPressed: _select,
                  dragOver: _dragOver,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: CarbonText(_stateLabel)),
          if (_hasFile && _status == CarbonFileStatus.uploading)
            CarbonProgressBar(
              label: 'Demo upload progress',
              value: _progress.toDouble(),
              max: 100,
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              CarbonButton(
                label: _invalid ? 'Retry upload' : 'Start upload',
                onPressed: _hasFile && _status == CarbonFileStatus.edit
                    ? _start
                    : null,
              ),
              CarbonButton(
                label: 'Advance upload',
                kind: CarbonButtonKind.secondary,
                onPressed: _hasFile && _status == CarbonFileStatus.uploading
                    ? _advance
                    : null,
              ),
              CarbonButton(
                label: 'Simulate failure',
                kind: CarbonButtonKind.dangerTertiary,
                onPressed: _hasFile && _status == CarbonFileStatus.uploading
                    ? _fail
                    : null,
              ),
              CarbonButton(
                label: 'Remove file',
                kind: CarbonButtonKind.ghost,
                onPressed: _hasFile ? _remove : null,
              ),
            ],
          ),
        ],
      ),
    ),
    controls: <Widget>[
      boolKnob(
        label: 'Simulate drag hover',
        value: _dragOver,
        onChanged: (bool v) => setState(() => _dragOver = v),
      ),
    ],
    code: exampleSource,
  );
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
      code: exampleSource,
    );
  }
}

class _PageHeaderPage extends StatefulWidget {
  const _PageHeaderPage();
  @override
  State<_PageHeaderPage> createState() => _PageHeaderPageState();
}

class _PageHeaderPageState extends State<_PageHeaderPage> {
  int _headingLevel = 2;
  int _edits = 0;
  int _downloads = 0;
  int _tagViews = 0;
  int _tagDismissals = 0;
  bool _showDraft = true;
  bool _collapseTags = true;
  bool _longTitle = true;
  String _hero = 'None';
  bool _decorativeHero = false;
  final TextEditingController _heroNote = TextEditingController();

  @override
  void dispose() {
    _heroNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      title: 'Page header',
      description: 'Resize to disclose actions and tags, recover the title, and reflow optional hero content.',
      previewAlignment: Alignment.topLeft,
      controls: <Widget>[
        choiceKnob<String>(
          label: 'Hero content',
          value: _hero,
          options: const <String>['None', 'Image', 'Custom'],
          labelOf: (String value) => value,
          onChanged: (String value) => setState(() => _hero = value),
        ),
        boolKnob(
          label: 'Decorative image',
          value: _decorativeHero,
          onChanged: (bool value) => setState(() => _decorativeHero = value),
        ),
        boolKnob(
          label: 'Long title',
          value: _longTitle,
          onChanged: (bool value) => setState(() => _longTitle = value),
        ),
        boolKnob(
          label: 'Collapse tags',
          value: _collapseTags,
          onChanged: (bool value) => setState(() => _collapseTags = value),
        ),
        choiceKnob<int>(
          label: 'Heading level',
          value: _headingLevel,
          options: const <int>[1, 2, 3, 4, 5, 6],
          labelOf: (int level) => '$level',
          onChanged: (int level) => setState(() => _headingLevel = level),
        ),
      ],
      preview: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Edits: $_edits · Downloads: $_downloads'),
          Text('Tag views: $_tagViews · Dismissals: $_tagDismissals'),
          CarbonPageHeader(
            title: _longTitle
                ? 'Quarterly report with a deliberately long title'
                : 'Report',
            headingLevel: _headingLevel,
            subtitle: 'Finance',
            heroDecorative: _hero == 'Image' && _decorativeHero,
            hero: switch (_hero) {
              'Image' => Image.asset(
                'assets/page_header_hero.jpg',
                fit: BoxFit.cover,
                semanticLabel: 'Manufacturing presentation',
              ),
              'Custom' => ColoredBox(
                color: CarbonTheme.of(context).layer02,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CarbonTextInput(
                      labelText: 'Hero note',
                      controller: _heroNote,
                    ),
                  ),
                ),
              ),
              _ => null,
            },
            body: 'A summary of revenue and spend for the quarter.',
            collapseTags: _collapseTags,
            tags: <Widget>[
              const CarbonTag(
                key: ValueKey<String>('finance'),
                label: 'Finance report',
                type: CarbonTagType.blue,
              ),
              CarbonOperationalTag(
                key: const ValueKey<String>('region'),
                label: 'View regional report',
                onPressed: () => setState(() => _tagViews++),
              ),
              if (_showDraft)
                CarbonDismissibleTag(
                  key: const ValueKey<String>('draft'),
                  label: 'Draft',
                  onClose: () => setState(() {
                    _showDraft = false;
                    _tagDismissals++;
                  }),
                ),
              const CarbonTag(
                key: ValueKey<String>('reviewed'),
                label: 'Reviewed',
                type: CarbonTagType.green,
              ),
            ],
            breadcrumbs: <CarbonBreadcrumbItem>[
              CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
              CarbonBreadcrumbItem(label: 'Finance', onPressed: () {}),
            ],
            actions: <CarbonPageHeaderAction>[
              CarbonPageHeaderAction(
                id: 'edit',
                label: 'Edit report',
                onPressed: () => setState(() => _edits++),
              ),
              CarbonPageHeaderAction(
                id: 'download',
                label: 'Download report',
                kind: CarbonButtonKind.secondary,
                onPressed: () => setState(() => _downloads++),
              ),
              const CarbonPageHeaderAction(
                id: 'archive',
                label: 'Archive report',
                kind: CarbonButtonKind.tertiary,
              ),
            ],
          ),
        ],
      ),
      code: exampleSource,
    );
  }
}
