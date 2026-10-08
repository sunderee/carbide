// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/data-table/{_data-table,_vars,_mixins}.scss
//   react/src/components/DataTable/{DataTable,Table,TableContainer,TableHead,
//     TableHeader,TableBody,TableRow,TableCell}.tsx
//
// The core DataTable: a semantic, token-driven table that the sort / selection
// / expansion / toolbar features build on. No Material DataTable — equal-flex
// columns shared between the header and body rows.

import 'dart:async';
import 'dart:ui' show SemanticsRole;

import 'package:flutter/rendering.dart'
    show PipelineOwner, RenderProxyBox, SemanticsConfiguration;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/keep_focused_row.dart';
import '../../utils/focus_retaining_sliver.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/focus_ring.dart';
import '../../utils/native_control_focus.dart';
import '../button/carbon_button.dart';
import '../checkbox/carbon_checkbox.dart';
import '../radio_button/carbon_radio_button.dart';

/// The row height of a [CarbonDataTable] (`_data-table.scss` size variants).
enum CarbonTableSize {
  /// Extra small — 24px rows.
  xs(24),

  /// Small — 32px rows.
  sm(32),

  /// Medium — 40px rows.
  md(40),

  /// Large — 48px rows (the default).
  lg(48),

  /// Extra large — 64px rows.
  xl(64);

  const CarbonTableSize(this.height);

  /// The row height in logical pixels.
  final double height;
}

/// The sort state of a [CarbonDataTable] column.
enum CarbonSortDirection {
  /// Not sorted.
  none,

  /// Ascending.
  ascending,

  /// Descending.
  descending,
}

/// Formats the complete sort-state announcement for a table header.
///
/// Return a localized phrase for every [direction], including unsorted columns.
/// The column title remains the button's separate accessible name.
typedef CarbonTableSortDirectionFormatter = String Function(
  CarbonSortDirection direction,
);

/// Describes a table column's sort state in English.
String carbonTableSortDirectionLabel(CarbonSortDirection direction) =>
    switch (direction) {
      CarbonSortDirection.none => 'Not sorted',
      CarbonSortDirection.ascending => 'Sorted ascending',
      CarbonSortDirection.descending => 'Sorted descending',
    };

/// A column definition for a [CarbonDataTable].
class CarbonTableColumn {
  /// Creates a table column.
  const CarbonTableColumn({
    required this.title,
    this.flex = 1,
    this.sortable = false,
    this.aiLabel,
  });

  /// The header label.
  final String title;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered after
  /// the header label per the upstream `column-ai-label-sort` story.
  final Widget? aiLabel;

  /// The column's share of the available width.
  final int flex;

  /// Whether the column header sorts the table when activated.
  final bool sortable;
}

/// A row of cells for a [CarbonDataTable].
class CarbonTableRow {
  /// Creates a table row.
  const CarbonTableRow({
    required this.cells,
    this.id,
    this.label,
    this.expandedContent,
  });

  /// Stable record identity, required by the ID-based selection/expansion APIs.
  ///
  /// IDs must be unique within the current data. Legacy index-based tables
  /// may omit them; those rows use positional widget keys.
  final Object? id;

  /// A human-readable record name for selection and expansion controls.
  ///
  /// Defaults to [id], or the one-based position for legacy rows without IDs.
  final String? label;

  /// The cell contents, one per column.
  final List<Widget> cells;

  /// Detail content revealed below the row when expanded (requires the table's
  /// `expandable` flag).
  final Widget? expandedContent;
}

/// How a [CarbonDataTable]'s rows may be selected.
enum CarbonTableSelection {
  /// Rows are not selectable.
  none,

  /// One row at a time (radio).
  single,

  /// Any number of rows (checkbox + select-all).
  multi,
}

/// An action shown in a [CarbonDataTable]'s batch-actions bar.
class CarbonTableBatchAction {
  /// Creates a batch action.
  const CarbonTableBatchAction({required this.label, this.onPressed});

  /// The action label.
  final String label;

  /// The action.
  final VoidCallback? onPressed;
}

/// A Carbon data table.
///
/// Use stable [CarbonTableRow.id] values with [selectedRowIds] and
/// [onSelectedRowIdsChanged], or [expandedRowIds] and [onExpansionChanged].
/// Selection, expansion and row widget state then follow records through
/// sorting, filtering and paging. Absent IDs are retained and ignored while
/// absent; counts include only the current data.
///
/// Sortable columns expose one button named by the column title. Its semantics
/// value describes [sortDirection], using [sortDirectionFormatter] for
/// localization. A null [onSort] disables those buttons. Non-sortable column
/// titles remain static headers; any AI label keeps its own action.
///
/// The table's accessible name defaults to [title]; provide [semanticsLabel]
/// when a different or localized name is needed. Headers and keyed data rows
/// expose the platform's table, row and cell roles in the current visual order.
/// Sticky tables retain scrolling actions on the table node. Expanded details
/// and batch actions occupy separate full-width semantic rows; Flutter does
/// not expose column spans for those rows.
///
/// The deprecated index APIs remain functional for at least one minor release.
/// To migrate, add an ID to every row and replace `selectedRows` /
/// `onSelectionChanged` with `selectedRowIds` / `onSelectedRowIdsChanged`, and
/// `expandedRows` / `onExpandedChanged` with `expandedRowIds` /
/// `onExpansionChanged`. Selection and expansion can migrate independently.
///
/// When the platform requests reduced motion, the row hover fill, row
/// expansion, and batch-actions bar transitions complete instantly.
///
/// ```dart
/// CarbonDataTable(
///   title: 'Routines',
///   columns: const <CarbonTableColumn>[
///     CarbonTableColumn(title: 'Name'),
///     CarbonTableColumn(title: 'Status'),
///   ],
///   rows: const <CarbonTableRow>[
///     CarbonTableRow(id: 'load', label: 'Load', cells: <Widget>[Text('Load'), Text('Running')]),
///   ],
///   selection: CarbonTableSelection.multi,
///   selectedRowIds: _selectedIds,
///   onSelectedRowIdsChanged: (Set<Object> ids) => setState(() => _selectedIds = ids),
/// )
/// ```
class CarbonDataTable extends StatelessWidget {
  /// Creates a data table.
  const CarbonDataTable({
    required this.columns,
    required this.rows,
    super.key,
    this.size = CarbonTableSize.lg,
    this.zebra = false,
    this.stickyHeader = false,
    this.virtualized = false,
    this.viewportHeight = 320,
    this.scrollController,
    this.stickyHeaderHeight = 320,
    this.title,
    this.description,
    this.semanticsLabel,
    this.aiLabel,
    this.sortColumnIndex,
    this.sortDirection = CarbonSortDirection.none,
    this.sortDirectionFormatter = carbonTableSortDirectionLabel,
    this.onSort,
    this.selection = CarbonTableSelection.none,
    Set<int>? selectedRows,
    this.selectedRowIds,
    this.onSelectedRowIdsChanged,
    this.onSelectionChanged,
    this.batchActions,
    this.batchCancelLabel = 'Cancel',
    this.expandable = false,
    Set<int>? expandedRows,
    this.expandedRowIds,
    this.onExpansionChanged,
    this.onExpandedChanged,
  }) : assert(viewportHeight > 0 && viewportHeight < double.infinity),
       assert(
         !virtualized ||
             (selectedRows == null &&
                 onSelectionChanged == null &&
                 expandedRows == null &&
                 onExpandedChanged == null),
         'Virtualized tables use stable ID selection and expansion APIs.',
       ),
       selectedRows = selectedRows ?? const <int>{},
       expandedRows = expandedRows ?? const <int>{},
       assert(
         (selectedRowIds == null && onSelectedRowIdsChanged == null) ||
             (selectedRows == null && onSelectionChanged == null),
         'Use selectedRowIds/onSelectedRowIdsChanged or selectedRows/onSelectionChanged, not both.',
       ),
       assert(
         (expandedRowIds == null && onExpansionChanged == null) ||
             (expandedRows == null && onExpandedChanged == null),
         'Use expandedRowIds/onExpansionChanged or expandedRows/onExpandedChanged, not both.',
       );

  /// The columns.
  final List<CarbonTableColumn> columns;

  /// The body rows.
  final List<CarbonTableRow> rows;

  /// The row height.
  final CarbonTableSize size;

  /// Whether even rows are tinted (`useZebraStyles`).
  final bool zebra;

  /// Builds only the viewport's rows in a bounded sliver. Every row requires
  /// a unique stable ID. Eager rendering remains the default for intrinsic
  /// layouts. Data models remain caller-owned; only row widgets are recycled.
  final bool virtualized;

  /// The virtual viewport height. With [stickyHeader], this bounds the body;
  /// otherwise it includes the scrolling header. Must be positive and finite.
  final double viewportHeight;

  /// Optional externally owned body/virtual viewport scroll controller.
  final ScrollController? scrollController;

  /// Whether the header stays fixed while the body scrolls.
  final bool stickyHeader;

  /// The body's max height when [stickyHeader].
  final double stickyHeaderHeight;

  /// An optional table title.
  final String? title;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered after
  /// the table title per the upstream `ai-label-with-*` stories.
  final Widget? aiLabel;

  /// An optional table description.
  final String? description;

  /// The table's accessible name.
  ///
  /// Defaults to [title], or `Data table` when no title is provided. Supply a
  /// localized name when the visible title does not identify the table.
  final String? semanticsLabel;

  /// The index of the currently sorted column, or null.
  final int? sortColumnIndex;

  /// The sort direction of [sortColumnIndex].
  final CarbonSortDirection sortDirection;

  /// The localizable sort-state value of each sortable header button.
  ///
  /// Defaults to [carbonTableSortDirectionLabel]. Flutter has no `aria-sort`
  /// property; the complete phrase is exposed as the button's semantics value.
  final CarbonTableSortDirectionFormatter sortDirectionFormatter;

  /// Called with a sortable column's index when its header is activated; the
  /// consumer cycles none → ascending → descending → none.
  final ValueChanged<int>? onSort;

  /// How rows may be selected.
  final CarbonTableSelection selection;

  /// The currently selected row indices (legacy positional selection).
  ///
  /// Out-of-range indices are ignored for rendering and counts. This API stays
  /// functional during migration; sorting or paging changes their meaning.
  @Deprecated('Use selectedRowIds with stable CarbonTableRow.id values.')
  final Set<int> selectedRows;

  /// Controlled selected record IDs.
  ///
  /// Absent IDs are ignored for rendering, header state and batch counts, but
  /// retained in multi-selection proposals so paging back restores selection.
  /// Select-all adds/removes only current rows; Cancel clears the full set.
  /// Single selection replaces the full set with the chosen ID.
  final Set<Object>? selectedRowIds;

  /// Called with a copied ID selection after a user action.
  ///
  /// Programmatic data/selection changes do not notify or mutate caller sets.
  /// Do not supply the legacy selection API at the same time.
  final ValueChanged<Set<Object>>? onSelectedRowIdsChanged;

  /// Called with the new selection when a row (or select-all) toggles.
  @Deprecated('Use onSelectedRowIdsChanged with selectedRowIds.')
  final ValueChanged<Set<int>>? onSelectionChanged;

  /// Actions shown in the batch-actions bar (multi-select).
  final List<CarbonTableBatchAction>? batchActions;

  /// The label of the batch-actions Cancel control.
  final String batchCancelLabel;

  /// Whether rows can expand to reveal [CarbonTableRow.expandedContent].
  final bool expandable;

  /// The currently expanded row indices (legacy positional expansion).
  @Deprecated('Use expandedRowIds with stable CarbonTableRow.id values.')
  final Set<int> expandedRows;

  /// Controlled expanded record IDs.
  ///
  /// Absent IDs remain in the caller's set and are ignored until their rows
  /// return. Expansion therefore follows records through sorting and paging.
  final Set<Object>? expandedRowIds;

  /// Called with a copied ID expansion set after a user toggle.
  ///
  /// Programmatic data/expansion changes do not notify. Do not supply the
  /// legacy expansion API at the same time.
  final ValueChanged<Set<Object>>? onExpansionChanged;

  /// Called with the new set when a row expands or collapses.
  @Deprecated('Use onExpansionChanged with expandedRowIds.')
  final ValueChanged<Set<int>>? onExpandedChanged;

  @override
  StatelessElement createElement() {
    _validateTable(this);
    return super.createElement();
  }

  @override
  Widget build(BuildContext context) {
    _validateTable(this);
    return _TableBody(table: this);
  }
}

void _validateTable(CarbonDataTable table) {
  final bool requiresIds =
      table.virtualized ||
      table.selectedRowIds != null ||
      table.onSelectedRowIdsChanged != null ||
      table.expandedRowIds != null ||
      table.onExpansionChanged != null;
  final Set<Object> ids = <Object>{};
  for (final CarbonTableRow row in table.rows) {
    assert(
      !requiresIds || row.id != null,
      'Every row needs an id when using ID-based selection or expansion.',
    );
    assert(
      row.id == null || ids.add(row.id!),
      'Table row ids must be unique: ${row.id}',
    );
  }
}

class _TableBody extends StatefulWidget {
  const _TableBody({required this.table});
  final CarbonDataTable table;
  @override
  State<_TableBody> createState() => _TableBodyState();
}

class _TableBodyState extends State<_TableBody> {
  final ScrollController _ownedScroll = ScrollController();
  ScrollController get _bodyScroll =>
      widget.table.scrollController ?? _ownedScroll;

  @override
  void dispose() {
    _ownedScroll.dispose();
    super.dispose();
  }

  List<CarbonTableColumn> get columns => widget.table.columns;
  List<CarbonTableRow> get rows => widget.table.rows;
  CarbonTableSize get size => widget.table.size;
  bool get zebra => widget.table.zebra;
  bool get stickyHeader => widget.table.stickyHeader;
  double get stickyHeaderHeight => widget.table.stickyHeaderHeight;
  String? get title => widget.table.title;
  String? get description => widget.table.description;
  Widget? get aiLabel => widget.table.aiLabel;
  int? get sortColumnIndex => widget.table.sortColumnIndex;
  CarbonSortDirection get sortDirection => widget.table.sortDirection;
  ValueChanged<int>? get onSort => widget.table.onSort;
  CarbonTableSelection get selection => widget.table.selection;
  Set<int> get selectedRows => widget.table.selectedRows;
  ValueChanged<Set<int>>? get onSelectionChanged =>
      widget.table.onSelectionChanged;
  List<CarbonTableBatchAction>? get batchActions => widget.table.batchActions;
  String get batchCancelLabel => widget.table.batchCancelLabel;
  bool get expandable => widget.table.expandable;
  Set<int> get expandedRows => widget.table.expandedRows;
  ValueChanged<Set<int>>? get onExpandedChanged =>
      widget.table.onExpandedChanged;

  bool get _selectable => selection != CarbonTableSelection.none;
  bool get _idSelection =>
      widget.table.selectedRowIds != null ||
      widget.table.onSelectedRowIdsChanged != null;
  bool get _idExpansion =>
      widget.table.expandedRowIds != null ||
      widget.table.onExpansionChanged != null;
  bool get _selectionEnabled => _idSelection
      ? widget.table.onSelectedRowIdsChanged != null
      : onSelectionChanged != null;
  bool get _allSelectionEnabled => _selectionEnabled && rows.isNotEmpty;
  bool get _expansionEnabled => _idExpansion
      ? widget.table.onExpansionChanged != null
      : onExpandedChanged != null;
  Set<Object> get _selectedIds =>
      widget.table.selectedRowIds ?? const <Object>{};
  Set<Object> get _expandedIds =>
      widget.table.expandedRowIds ?? const <Object>{};
  Set<Object> get _presentIds => <Object>{
    for (final CarbonTableRow row in rows)
      if (row.id != null) row.id!,
  };
  Set<int> get _presentIndices => <int>{
    for (int i = 0; i < rows.length; i++) i,
  };
  int get _selectedCount => _idSelection
      ? _selectedIds.intersection(_presentIds).length
      : selectedRows.intersection(_presentIndices).length;
  bool _selected(int index) => _idSelection
      ? _selectedIds.contains(rows[index].id)
      : selectedRows.contains(index);
  bool _expanded(int index) => _idExpansion
      ? _expandedIds.contains(rows[index].id)
      : expandedRows.contains(index);
  String _rowName(int index) =>
      rows[index].label ?? rows[index].id?.toString() ?? '${index + 1}';
  Key _rowKey(String part, int index) => ValueKey<(String, bool, Object)>((
    part,
    rows[index].id != null,
    rows[index].id ?? index,
  ));

  int _currentIndex(CarbonTableRow row, int index) {
    if (!mounted) return -1;
    if (row.id != null) {
      return rows.indexWhere((current) => current.id == row.id);
    }
    return index < rows.length && identical(rows[index], row) ? index : -1;
  }

  void _toggleExpanded(CarbonTableRow row, int index) {
    index = _currentIndex(row, index);
    if (index < 0 ||
        !expandable ||
        !_expansionEnabled ||
        rows[index].expandedContent == null) {
      return;
    }
    if (_idExpansion) {
      final Set<Object> next = <Object>{..._expandedIds};
      final Object id = rows[index].id!;
      if (!next.add(id)) next.remove(id);
      widget.table.onExpansionChanged!(next);
    } else {
      final Set<int> next = <int>{...expandedRows};
      if (!next.add(index)) next.remove(index);
      onExpandedChanged!(next);
    }
  }

  void _toggleRow(CarbonTableRow row, int index) {
    index = _currentIndex(row, index);
    if (index < 0 || !_selectable || !_selectionEnabled) return;
    if (_idSelection) {
      final Set<Object> next = selection == CarbonTableSelection.single
          ? <Object>{}
          : <Object>{..._selectedIds};
      final Object id = rows[index].id!;
      if (!next.add(id)) next.remove(id);
      widget.table.onSelectedRowIdsChanged!(next);
    } else {
      final Set<int> next = selection == CarbonTableSelection.single
          ? <int>{}
          : <int>{...selectedRows};
      if (!next.add(index)) next.remove(index);
      onSelectionChanged!(next);
    }
  }

  void _toggleAll() {
    if (!mounted ||
        selection != CarbonTableSelection.multi ||
        !_selectionEnabled ||
        rows.isEmpty) {
      return;
    }
    final bool all = _selectedCount == rows.length;
    if (_idSelection) {
      final Set<Object> next = <Object>{..._selectedIds};
      all ? next.removeAll(_presentIds) : next.addAll(_presentIds);
      widget.table.onSelectedRowIdsChanged!(next);
    } else {
      final Set<int> next = <int>{...selectedRows};
      all ? next.removeAll(_presentIndices) : next.addAll(_presentIndices);
      onSelectionChanged!(next);
    }
  }

  void _cancelSelection() {
    if (!mounted ||
        selection != CarbonTableSelection.multi ||
        !_selectionEnabled ||
        _selectedCount == 0) {
      return;
    }
    if (_idSelection) {
      widget.table.onSelectedRowIdsChanged!(<Object>{});
    } else {
      onSelectionChanged!(<int>{});
    }
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);

    // The leading select-all cell (multi only): checked when all rows are
    // selected, indeterminate on a partial selection.
    final bool allSelected = rows.isNotEmpty && _selectedCount == rows.length;
    final bool partlySelected = _selectedCount > 0 && !allSelected;
    final Widget? selectAll = selection == CarbonTableSelection.multi
        ? MergeSemantics(
            child: Semantics(
              label: 'Select all rows',
              checked: partlySelected ? null : allSelected,
              mixed: partlySelected,
              // Flutter 3.47's web SemanticCheckable maps mixed to aria-checked
              // false. Keep the native flag and announce the state in the same
              // node's value until the engine preserves mixed in the DOM.
              value: kIsWeb && partlySelected ? 'Partially selected' : null,
              enabled: _allSelectionEnabled,
              onTap: _allSelectionEnabled ? _toggleAll : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _allSelectionEnabled ? _toggleAll : null,
                child: SizedBox(
                  width: CarbonSpacing.spacing09,
                  height: size.height,
                  child: Center(
                    child: CarbonCheckbox(
                      label: '',
                      value: allSelected,
                      indeterminate: partlySelected,
                      onChanged: _allSelectionEnabled
                          ? (_) => _toggleAll()
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          )
        : null;

    // A leading row of fixed-width control cells: an expand chevron and/or a
    // selector. Header and body share the same column layout.
    Widget? leadingRow({required int? rowIndex}) {
      if (!expandable && !_selectable) return null;
      final CarbonTableRow? row = rowIndex == null ? null : rows[rowIndex];
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (expandable)
            _LeadingCell(
              header: rowIndex == null,
              semanticsOrder: 0,
              child: rowIndex != null && rows[rowIndex].expandedContent != null
                  ? _ExpandChevron(
                      expanded: _expanded(rowIndex),
                      label: 'Expand row ${_rowName(rowIndex)}',
                      onTap: _expansionEnabled
                          ? () => _toggleExpanded(row!, rowIndex)
                          : null,
                    )
                  : const SizedBox.shrink(),
            ),
          if (_selectable)
            _LeadingCell(
              header: rowIndex == null,
              semanticsOrder: 1,
              child: rowIndex == null
                  ? (selectAll ?? const SizedBox.shrink())
                  : _RowSelector(
                      height: size.height,
                      multi: selection == CarbonTableSelection.multi,
                      selected: _selected(rowIndex),
                      label: 'Select row ${_rowName(rowIndex)}',
                      onChanged: _selectionEnabled
                          ? () => _toggleRow(row!, rowIndex)
                          : null,
                    ),
            ),
        ],
      );
    }

    final Widget header = _HeaderRow(
      columns: columns,
      size: size,
      sortColumnIndex: sortColumnIndex,
      sortDirection: sortDirection,
      sortDirectionFormatter: widget.table.sortDirectionFormatter,
      onSort: onSort,
      leading: leadingRow(rowIndex: null),
    );

    List<Widget> rowChildren(int i) => <Widget>[
      _BodyRow(
        key: _rowKey('body', i),
        row: rows[i],
        semanticsOrder: i * 2 + 1,
        columns: columns,
        size: size,
        // Zebra tints even rows (`tr:nth-child(even)`); rows are 1-based in
        // CSS, so the 0-based odd index is the even child.
        tinted: zebra && i.isOdd,
        isLast: i == rows.length - 1 && !_expanded(i),
        selected: _selected(i),
        expanded: _expanded(i),
        leading: leadingRow(rowIndex: i),
      ),
      if (expandable && rows[i].expandedContent != null)
        _ExpandedDetail(
          key: _rowKey('detail', i),
          expanded: _expanded(i),
          semanticsOrder: i * 2 + 2,
          isLast: i == rows.length - 1,
          child: rows[i].expandedContent!,
        ),
    ];
    final List<Widget> bodyRows = widget.table.virtualized
        ? const <Widget>[]
        : <Widget>[for (int i = 0; i < rows.length; i++) ...rowChildren(i)];

    final Widget headerArea = selection == CarbonTableSelection.multi
        ? _BatchHeader(
            size: size,
            header: header,
            selectedCount: _selectedCount,
            actions: batchActions ?? const <CarbonTableBatchAction>[],
            cancelLabel: batchCancelLabel,
            onCancel: _selectionEnabled ? _cancelSelection : null,
          )
        : header;

    final Map<Object, int> indices = widget.table.virtualized
        ? <Object, int>{for (int i = 0; i < rows.length; i++) rows[i].id!: i}
        : const <Object, int>{};
    final Widget body = widget.table.virtualized
        ? SizedBox(
            height: widget.table.viewportHeight,
            child: Scrollable(
              controller: _bodyScroll,
              excludeFromSemantics: true,
              viewportBuilder: (_, offset) => CarbonFocusRetainingViewport(
                offset: offset,
                slivers: <Widget>[
                  if (!stickyHeader) SliverToBoxAdapter(child: headerArea),
                  CarbonFocusRetainingSliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => CarbonKeepFocusedRow(
                        key: ValueKey<Object>(rows[i].id!),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rowChildren(i),
                        ),
                      ),
                      childCount: rows.length,
                      addSemanticIndexes: false,
                      findChildIndexCallback: (key) =>
                          key is ValueKey<Object> ? indices[key.value] : null,
                    ),
                  ),
                ],
              ),
            ),
          )
        : stickyHeader
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: stickyHeaderHeight),
            child: Scrollable(
              controller: _bodyScroll,
              excludeFromSemantics: true,
              viewportBuilder: (_, offset) => ShrinkWrappingViewport(
                axisDirection: AxisDirection.down,
                offset: offset,
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: bodyRows,
                    ),
                  ),
                ],
              ),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: bodyRows,
          );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: layer.layer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title != null || description != null)
              Semantics(
                container: true,
                explicitChildNodes: true,
                sortKey: const OrdinalSortKey(0),
                child: Padding(
                  // TableContainer header: spacing-05 top, spacing-06 bottom.
                  padding: const EdgeInsets.fromLTRB(
                    CarbonSpacing.spacing05,
                    CarbonSpacing.spacing05,
                    CarbonSpacing.spacing05,
                    CarbonSpacing.spacing06,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (title != null)
                        Semantics(
                          container: true,
                          header: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                title!,
                                style: CarbonTypeStyles.heading03.copyWith(
                                  color: theme.textPrimary,
                                ),
                              ),
                              // The AI label flows after the table title.
                              if (aiLabel != null) ...<Widget>[
                                const SizedBox(width: CarbonSpacing.spacing03),
                                aiLabel!,
                              ],
                            ],
                          ),
                        ),
                      if (description != null)
                        Semantics(
                          container: true,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: CarbonSpacing.spacing02,
                            ),
                            child: Text(
                              description!,
                              style: CarbonTypeStyles.bodyCompact01.copyWith(
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            _TableScrollSemantics(
              label: widget.table.semanticsLabel ?? title ?? 'Data table',
              textDirection: Directionality.of(context),
              controller: stickyHeader || widget.table.virtualized
                  ? _bodyScroll
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (!widget.table.virtualized || stickyHeader) headerArea,
                  body,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The header row: `layer-accent` background, `heading-compact-01` cells.
/// Sortable columns render as a sort button cycling through the directions.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.columns,
    required this.size,
    required this.sortColumnIndex,
    required this.sortDirection,
    required this.sortDirectionFormatter,
    required this.onSort,
    required this.leading,
  });

  final List<CarbonTableColumn> columns;
  final CarbonTableSize size;
  final int? sortColumnIndex;
  final CarbonSortDirection sortDirection;
  final CarbonTableSortDirectionFormatter sortDirectionFormatter;
  final ValueChanged<int>? onSort;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.row,
      sortKey: const OrdinalSortKey(0),
      child: ColoredBox(
        color: layer.layerAccent,
        // Row height is a minimum: cells grow the band under text scaling
        // instead of clipping (docs/text-scaling.md).
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: size.height),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ?leading,
                for (int i = 0; i < columns.length; i++)
                  Expanded(
                    flex: columns[i].flex,
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      role: SemanticsRole.columnHeader,
                      label: columns[i].sortable ? null : columns[i].title,
                      sortKey: OrdinalSortKey(i.toDouble() + 2),
                      child: _HeaderCell(
                        column: columns[i],
                        direction: sortColumnIndex == i
                            ? sortDirection
                            : CarbonSortDirection.none,
                        onSort: columns[i].sortable && onSort != null
                            ? () => onSort!(i)
                            : null,
                        sortDirectionFormatter: sortDirectionFormatter,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single header cell — plain text, or a sort button with a sort glyph.
class _HeaderCell extends StatefulWidget {
  const _HeaderCell({
    required this.column,
    required this.direction,
    required this.onSort,
    required this.sortDirectionFormatter,
  });

  final CarbonTableColumn column;
  final CarbonSortDirection direction;
  final VoidCallback? onSort;
  final CarbonTableSortDirectionFormatter sortDirectionFormatter;

  @override
  State<_HeaderCell> createState() => _HeaderCellState();
}

class _HeaderCellState extends State<_HeaderCell> {
  bool _hovered = false;
  bool _focused = false;
  final FocusNode _focus = FocusNode(debugLabel: 'Carbon table sort');

  bool get _interactive => widget.column.sortable && widget.onSort != null;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _activate() {
    if (!mounted || !_interactive) return;
    _focus.requestFocus();
    widget.onSort!();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_interactive &&
        node.hasPrimaryFocus &&
        event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _activate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool active = widget.direction != CarbonSortDirection.none;

    Widget label = IgnorePointer(
      child: ExcludeSemantics(
        child: Text(
          widget.column.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CarbonTypeStyles.headingCompact01.copyWith(
            color: theme.textPrimary,
          ),
        ),
      ),
    );
    // The AI label flows after the header label (column-ai-label-sort).
    if (widget.column.aiLabel != null) {
      label = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(child: label),
          const SizedBox(width: CarbonSpacing.spacing03),
          widget.column.aiLabel!,
        ],
      );
    }

    if (!widget.column.sortable) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CarbonSpacing.spacing05,
        ),
        child: Align(alignment: AlignmentDirectional.centerStart, child: label),
      );
    }

    // The sort glyph: ArrowsVertical when inactive (shown only on hover/focus),
    // ArrowUp / ArrowDown when ascending / descending.
    final Widget glyph = active
        ? CarbonIcon(
            widget.direction == CarbonSortDirection.ascending
                ? CarbonIcons.arrowUp
                : CarbonIcons.arrowDown,
            size: 16,
            color: theme.iconPrimary,
          )
        : Opacity(
            opacity: _hovered || _focused ? 1 : 0,
            child: CarbonIcon(
              CarbonIcons.arrowsVertical,
              size: 16,
              color: theme.iconPrimary,
            ),
          );

    return Focus(
      focusNode: _focus,
      includeSemantics: false,
      canRequestFocus: _interactive,
      onKeyEvent: _onKey,
      onFocusChange: (focused) {
        if (mounted) setState(() => _focused = focused);
      },
      child: MouseRegion(
        cursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = _interactive),
        onExit: (_) => setState(() => _hovered = false),
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: <Widget>[
            Positioned.fill(
              child: CarbonControlSemantics(
                state: CarbonControlState.resolve(hasCallback: _interactive),
                label: widget.column.title,
                value: widget.sortDirectionFormatter(widget.direction),
                readOnlyHint: '',
                button: true,
                focusNode: _focus,
                onActivate: _activate,
                builder: (_) => ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _interactive ? _activate : null,
                    child: CarbonFocusRing(
                      visible: _focused && _interactive,
                      inset: true,
                      child: ColoredBox(
                        // Active / hovered sortable headers tint slightly.
                        color: _interactive && (active || _hovered)
                            ? layer.layerHover
                            : const Color(0x00000000),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CarbonSpacing.spacing05,
              ),
              child: Row(
                children: <Widget>[
                  Flexible(child: label),
                  if (_interactive) ...<Widget>[
                    const SizedBox(width: CarbonSpacing.spacing03),
                    IgnorePointer(child: ExcludeSemantics(child: glyph)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A body row with hover, optional zebra tint and a bottom divider.
class _BodyRow extends StatefulWidget {
  const _BodyRow({
    super.key,
    required this.row,
    required this.semanticsOrder,
    required this.columns,
    required this.size,
    required this.tinted,
    required this.isLast,
    required this.selected,
    required this.expanded,
    required this.leading,
  });

  final CarbonTableRow row;
  final int semanticsOrder;
  final List<CarbonTableColumn> columns;
  final CarbonTableSize size;
  final bool tinted;
  final bool isLast;
  final bool selected;
  final bool expanded;
  final Widget? leading;

  @override
  State<_BodyRow> createState() => _BodyRowState();
}

class _BodyRowState extends State<_BodyRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);

    final Color background = widget.selected
        ? (_hovered ? layer.layerSelectedHover : layer.layerSelected)
        : _hovered || widget.expanded
        ? layer.layerHover
        : widget.tinted
        ? layer.layerAccent
        : layer.layer;
    final Color textColor = _hovered || widget.selected
        ? theme.textPrimary
        : theme.textSecondary;

    final Widget content = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // Row fill per `_data-table.scss` `tbody tr`: background-color
      // $duration-fast-01 motion(entrance, productive).
      child: AnimatedContainer(
        duration: carbonDuration(context, CarbonDuration.fast01),
        curve: CarbonEasing.entranceProductive,
        decoration: BoxDecoration(
          color: background,
          // 1px border-subtle row divider (suppressed on the last row when the
          // table footer/border takes over).
          border: Border(
            bottom: BorderSide(
              color: widget.isLast
                  ? const Color(0x00000000)
                  : layer.borderSubtle,
            ),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.size.height),
          child: DefaultTextStyle.merge(
            style: CarbonTypeStyles.bodyCompact01.copyWith(color: textColor),
            child: Row(
              children: <Widget>[
                ?widget.leading,
                for (int i = 0; i < widget.columns.length; i++)
                  Expanded(
                    flex: widget.columns[i].flex,
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      role: SemanticsRole.cell,
                      sortKey: OrdinalSortKey(i.toDouble() + 2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CarbonSpacing.spacing05,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: i < widget.row.cells.length
                              ? widget.row.cells[i]
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Keep the wrapper in place when selection changes, preserving cell and
    // selector state/focus. Selected rows paint the 3px interactive marker.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.row,
      sortKey: OrdinalSortKey(widget.semanticsOrder.toDouble()),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              color: widget.selected
                  ? theme.borderInteractive
                  : const Color(0x00000000),
              width: 3,
            ),
          ),
        ),
        child: content,
      ),
    );
  }
}

/// A fixed-width leading cell holding an expand chevron or a selector.
class _LeadingCell extends StatelessWidget {
  const _LeadingCell({
    required this.child,
    required this.header,
    required this.semanticsOrder,
  });

  final Widget child;
  final bool header;
  final double semanticsOrder;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    role: header ? SemanticsRole.columnHeader : SemanticsRole.cell,
    sortKey: OrdinalSortKey(semanticsOrder),
    child: SizedBox(
      width: CarbonSpacing.spacing09,
      child: Align(child: child),
    ),
  );
}

int _nextTableControlId = 0;

/// The per-row expand toggle — a chevron that rotates a quarter turn when open.
class _ExpandChevron extends StatefulWidget {
  const _ExpandChevron({
    required this.expanded,
    required this.label,
    required this.onTap,
  });

  final bool expanded;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_ExpandChevron> createState() => _ExpandChevronState();
}

class _ExpandChevronState extends State<_ExpandChevron> {
  bool _focused = false;
  final FocusNode _focusNode = FocusNode(debugLabel: 'table-expand');
  Timer? _nativeFocusTimer;
  late final String _semanticsIdentifier =
      'carbon-table-control-${_nextTableControlId++}';

  @override
  void dispose() {
    _nativeFocusTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _requestFocus() {
    if (mounted && widget.onTap != null) _focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onTap != null &&
        event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onTap!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _focusNode.hasPrimaryFocus && widget.onTap != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nativeFocusTimer?.cancel();
        // The engine may blur a moved semantics element after the frame. Let
        // that focus update finish before reconciling the two focus trees.
        _nativeFocusTimer = Timer(Duration.zero, () {
          if (!mounted || widget.onTap == null) return;
          final FocusNode? current = FocusManager.instance.primaryFocus;
          if (current != _focusNode &&
              current != FocusManager.instance.rootScope) {
            return;
          }
          if (restoreNativeControlFocus(_semanticsIdentifier)) {
            _focusNode.requestFocus();
          }
        });
      });
    }
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Semantics(
      identifier: _semanticsIdentifier,
      button: true,
      enabled: widget.onTap != null,
      focusable: widget.onTap != null,
      focused: widget.onTap != null && _focused,
      onFocus: widget.onTap != null ? _requestFocus : null,
      expanded: widget.expanded,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Focus(
              focusNode: _focusNode,
              includeSemantics: false,
              canRequestFocus: widget.onTap != null,
              onKeyEvent: _onKey,
              onFocusChange: (bool f) {
                if (!f &&
                    FocusManager.instance.primaryFocus !=
                        FocusManager.instance.rootScope) {
                  _nativeFocusTimer?.cancel();
                }
                setState(() => _focused = f);
              },
              child: CarbonFocusRing(
                visible: _focused,
                inset: true,
                child: SizedBox.square(
                  dimension: 24,
                  // Chevron per `_data-table-expandable.scss`
                  // `__expand__svg`: transform $duration-moderate-01
                  // motion(standard, productive).
                  child: AnimatedRotation(
                    turns: widget.expanded ? 0.25 : 0,
                    duration: carbonDuration(
                      context,
                      CarbonDuration.moderate01,
                    ),
                    curve: CarbonEasing.standardProductive,
                    child: CarbonIcon(
                      CarbonIcons.chevronRight,
                      color: theme.iconPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The full-width detail row revealed below an expanded row.
class _ExpandedDetail extends StatelessWidget {
  const _ExpandedDetail({
    super.key,
    required this.expanded,
    required this.semanticsOrder,
    required this.isLast,
    required this.child,
  });

  final bool expanded;
  final int semanticsOrder;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    // Detail fold per `_data-table-expandable.scss` `tr[data-child-row]`:
    // height $duration-moderate-01 motion(standard, productive).
    return ExcludeSemantics(
      excluding: !expanded,
      child: ExcludeFocus(
        excluding: !expanded,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          role: SemanticsRole.row,
          sortKey: OrdinalSortKey(semanticsOrder.toDouble()),
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            role: SemanticsRole.cell,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: expanded ? 1 : 0),
              duration: carbonDuration(context, CarbonDuration.moderate01),
              curve: CarbonEasing.standardProductive,
              builder: (BuildContext context, double t, Widget? child) =>
                  ClipRect(
                    child: Align(
                      alignment: AlignmentDirectional.topStart,
                      heightFactor: t,
                      child: child,
                    ),
                  ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: layer.layerHover,
                  border: Border(
                    bottom: BorderSide(
                      color: isLast
                          ? const Color(0x00000000)
                          : layer.borderSubtle,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(CarbonSpacing.spacing05),
                  child: DefaultTextStyle.merge(
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: theme.textPrimary,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The leading per-row selector — a checkbox (multi) or radio (single).
class _RowSelector extends StatefulWidget {
  const _RowSelector({
    required this.height,
    required this.multi,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final double height;
  final bool multi;
  final bool selected;
  final String label;
  final VoidCallback? onChanged;

  @override
  State<_RowSelector> createState() => _RowSelectorState();
}

class _RowSelectorState extends State<_RowSelector> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'table-select');
  Timer? _nativeFocusTimer;
  late final String _semanticsIdentifier =
      'carbon-table-control-${_nextTableControlId++}';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (!_focusNode.hasPrimaryFocus &&
        FocusManager.instance.primaryFocus != FocusManager.instance.rootScope) {
      _nativeFocusTimer?.cancel();
    }
    if (mounted) setState(() {});
  }

  void _requestFocus() {
    if (mounted && widget.onChanged != null) _focusNode.requestFocus();
  }

  void _activate() {
    if (!mounted || widget.onChanged == null) return;
    _focusNode.requestFocus();
    widget.onChanged!();
  }

  @override
  void dispose() {
    _nativeFocusTimer?.cancel();
    _focusNode.removeListener(_focusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _focusNode.hasPrimaryFocus && widget.onChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nativeFocusTimer?.cancel();
        // The engine may blur a moved semantics element after the frame. Let
        // that focus update finish before reconciling the two focus trees.
        _nativeFocusTimer = Timer(Duration.zero, () {
          if (!mounted || widget.onChanged == null) return;
          final FocusNode? current = FocusManager.instance.primaryFocus;
          if (current != _focusNode &&
              current != FocusManager.instance.rootScope) {
            return;
          }
          if (restoreNativeControlFocus(_semanticsIdentifier)) {
            _focusNode.requestFocus();
          }
        });
      });
    }
    final bool enabled = widget.onChanged != null;
    return MergeSemantics(
      // Replace the engine's checkable role when the selection mode changes.
      key: ValueKey<bool>(widget.multi),
      child: Semantics(
        identifier: _semanticsIdentifier,
        label: widget.label,
        checked: widget.selected,
        inMutuallyExclusiveGroup: !widget.multi,
        enabled: enabled,
        focusable: enabled,
        focused: enabled && _focusNode.hasPrimaryFocus,
        onFocus: enabled ? _requestFocus : null,
        onTap: enabled ? _activate : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _activate : null,
          child: SizedBox(
            width: CarbonSpacing.spacing09,
            height: widget.height,
            child: Center(
              child: widget.multi
                  ? CarbonCheckbox(
                      label: '',
                      focusNode: _focusNode,
                      value: widget.selected,
                      onChanged: enabled ? (_) => _activate() : null,
                    )
                  : CarbonRadioButton(
                      label: '',
                      focusNode: _focusNode,
                      selected: widget.selected,
                      onSelected: enabled ? _activate : null,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The header area for a multi-select table: the normal header with the
/// batch-actions bar sliding over it when rows are selected.
class _BatchHeader extends StatelessWidget {
  const _BatchHeader({
    required this.size,
    required this.header,
    required this.selectedCount,
    required this.actions,
    required this.cancelLabel,
    required this.onCancel,
  });

  final CarbonTableSize size;
  final Widget header;
  final int selectedCount;
  final List<CarbonTableBatchAction> actions;
  final String cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool active = selectedCount > 0;

    final Widget bar = Container(
      color: theme.backgroundBrand,
      padding: const EdgeInsetsDirectional.only(start: CarbonSpacing.spacing05),
      child: Row(
        children: <Widget>[
          Text(
            '$selectedCount item${selectedCount == 1 ? '' : 's'} selected',
            style: CarbonTypeStyles.bodyCompact01.copyWith(
              color: theme.textOnColor,
            ),
          ),
          const Spacer(),
          // Batch buttons size to their content (a bare CarbonButton would
          // expand to its 320px max under the bar's loose constraints).
          for (final CarbonTableBatchAction action in actions)
            IntrinsicWidth(
              child: CarbonButton(
                label: action.label,
                size: CarbonButtonSize.lg,
                onPressed: action.onPressed,
              ),
            ),
          IntrinsicWidth(
            child: CarbonButton(
              label: cancelLabel,
              size: CarbonButtonSize.lg,
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );

    // Both children lay out at their natural (min-height-backed) size and
    // the band takes the taller of the two, so text scaling can grow the
    // bar without the header capping it. Clip explicitly: Stack only clips
    // layout overflow, whereas AnimatedSlide creates paint overflow.
    return ClipRect(
      child: Stack(
        children: <Widget>[
          header,
          // Slide the bar down over the header when a selection exists
          // (`_data-table-action.scss` `--batch-actions`: transform
          // $duration-fast-02 motion(standard, productive)).
          AnimatedSlide(
            offset: active ? Offset.zero : const Offset(0, -1),
            duration: carbonDuration(context, CarbonDuration.fast02),
            curve: CarbonEasing.standardProductive,
            child: ExcludeSemantics(
              excluding: !active,
              child: IgnorePointer(
                ignoring: !active,
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  role: SemanticsRole.row,
                  sortKey: const OrdinalSortKey(0.5),
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    role: SemanticsRole.cell,
                    child: bar,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A scrolling table must expose its rows directly: Flutter has no row-group
// role, and Scrollable's usual semantics boundary would interrupt that
// relationship. Keep the viewport's public scrolling contract on the table
// node instead. Row semantics boundaries remain stable through sort/selection.
class _TableScrollSemantics extends SingleChildRenderObjectWidget {
  const _TableScrollSemantics({
    required this.controller,
    required this.label,
    required this.textDirection,
    required super.child,
  });

  final ScrollController? controller;
  final String label;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTableScrollSemantics(controller, label, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderTableScrollSemantics renderObject,
  ) {
    renderObject
      ..controller = controller
      ..label = label
      ..textDirection = textDirection;
  }
}

class _RenderTableScrollSemantics extends RenderProxyBox {
  _RenderTableScrollSemantics(
    this._controller,
    this._label,
    this._textDirection,
  );

  String _label;
  TextDirection _textDirection;

  set label(String next) {
    if (next == _label) return;
    _label = next;
    markNeedsSemanticsUpdate();
  }

  set textDirection(TextDirection next) {
    if (next == _textDirection) return;
    _textDirection = next;
    markNeedsSemanticsUpdate();
  }

  ScrollController? _controller;
  ScrollMetrics? _lastMetrics;

  set controller(ScrollController? next) {
    if (_controller == next) return;
    if (attached) _controller?.removeListener(markNeedsSemanticsUpdate);
    _controller = next;
    if (attached) _controller?.addListener(markNeedsSemanticsUpdate);
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller?.addListener(markNeedsSemanticsUpdate);
  }

  @override
  void detach() {
    _controller?.removeListener(markNeedsSemanticsUpdate);
    super.detach();
  }

  @override
  void performLayout() {
    super.performLayout();
    final ScrollMetrics? metrics = _position;
    if (metrics?.maxScrollExtent != _lastMetrics?.maxScrollExtent ||
        metrics?.viewportDimension != _lastMetrics?.viewportDimension) {
      _lastMetrics = metrics?.copyWith();
      markNeedsSemanticsUpdate();
    }
  }

  ScrollPosition? get _position =>
      _controller != null &&
          _controller!.hasClients &&
          _controller!.position.hasContentDimensions
      ? _controller!.position
      : null;

  void _scrollTo(double offset) {
    if (!attached) return;
    final ScrollPosition? position = _position;
    if (position == null) return;
    position.jumpTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..explicitChildNodes = true
      ..role = SemanticsRole.table
      ..label = _label
      ..textDirection = _textDirection
      ..sortKey = const OrdinalSortKey(1);
    final ScrollPosition? position = _position;
    if (position == null) return;
    config
      ..hasImplicitScrolling = position.physics.allowImplicitScrolling
      ..scrollPosition = position.pixels
      ..scrollExtentMin = position.minScrollExtent
      ..scrollExtentMax = position.maxScrollExtent;
    if (position.pixels > position.minScrollExtent) {
      config.onScrollUp = () =>
          _scrollTo(position.pixels - position.viewportDimension * 0.8);
    }
    if (position.pixels < position.maxScrollExtent) {
      config.onScrollDown = () =>
          _scrollTo(position.pixels + position.viewportDimension * 0.8);
    }
    if (position.maxScrollExtent > position.minScrollExtent) {
      config.onScrollToOffset = (offset) => _scrollTo(offset.dy);
    }
  }
}
