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

import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../utils/focus_ring.dart';
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
  const CarbonTableRow({required this.cells, this.expandedContent});

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
///     CarbonTableRow(cells: <Widget>[Text('Load'), Text('Running')]),
///   ],
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
    this.stickyHeaderHeight = 320,
    this.title,
    this.description,
    this.aiLabel,
    this.sortColumnIndex,
    this.sortDirection = CarbonSortDirection.none,
    this.onSort,
    this.selection = CarbonTableSelection.none,
    this.selectedRows = const <int>{},
    this.onSelectionChanged,
    this.batchActions,
    this.batchCancelLabel = 'Cancel',
    this.expandable = false,
    this.expandedRows = const <int>{},
    this.onExpandedChanged,
  });

  /// The columns.
  final List<CarbonTableColumn> columns;

  /// The body rows.
  final List<CarbonTableRow> rows;

  /// The row height.
  final CarbonTableSize size;

  /// Whether even rows are tinted (`useZebraStyles`).
  final bool zebra;

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

  /// The index of the currently sorted column, or null.
  final int? sortColumnIndex;

  /// The sort direction of [sortColumnIndex].
  final CarbonSortDirection sortDirection;

  /// Called with a sortable column's index when its header is activated; the
  /// consumer cycles none → ascending → descending → none.
  final ValueChanged<int>? onSort;

  /// How rows may be selected.
  final CarbonTableSelection selection;

  /// The currently selected row indices.
  final Set<int> selectedRows;

  /// Called with the new selection when a row (or select-all) toggles.
  final ValueChanged<Set<int>>? onSelectionChanged;

  /// Actions shown in the batch-actions bar (multi-select).
  final List<CarbonTableBatchAction>? batchActions;

  /// The label of the batch-actions Cancel control.
  final String batchCancelLabel;

  /// Whether rows can expand to reveal [CarbonTableRow.expandedContent].
  final bool expandable;

  /// The currently expanded row indices.
  final Set<int> expandedRows;

  /// Called with the new set when a row expands or collapses.
  final ValueChanged<Set<int>>? onExpandedChanged;

  bool get _selectable => selection != CarbonTableSelection.none;

  void _toggleExpanded(int index) {
    final Set<int> next = Set<int>.of(expandedRows);
    next.contains(index) ? next.remove(index) : next.add(index);
    onExpandedChanged?.call(next);
  }

  void _toggleRow(int index) {
    final Set<int> next = Set<int>.of(selectedRows);
    if (selection == CarbonTableSelection.single) {
      next
        ..clear()
        ..add(index);
    } else {
      next.contains(index) ? next.remove(index) : next.add(index);
    }
    onSelectionChanged?.call(next);
  }

  void _toggleAll() {
    final bool all = selectedRows.length == rows.length && rows.isNotEmpty;
    onSelectionChanged?.call(
      all ? <int>{} : <int>{for (int i = 0; i < rows.length; i++) i},
    );
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);

    // The leading select-all cell (multi only): checked when all rows are
    // selected, indeterminate on a partial selection.
    final bool allSelected =
        rows.isNotEmpty && selectedRows.length == rows.length;
    final bool partlySelected = selectedRows.isNotEmpty && !allSelected;
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
              enabled: onSelectionChanged != null,
              onTap: onSelectionChanged != null ? _toggleAll : null,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSelectionChanged != null ? _toggleAll : null,
                child: SizedBox(
                  width: CarbonSpacing.spacing09,
                  height: size.height,
                  child: Center(
                    child: CarbonCheckbox(
                      label: '',
                      value: allSelected,
                      indeterminate: partlySelected,
                      onChanged: onSelectionChanged != null
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
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (expandable)
            _LeadingCell(
              child: rowIndex != null && rows[rowIndex].expandedContent != null
                  ? _ExpandChevron(
                      expanded: expandedRows.contains(rowIndex),
                      label: 'Expand row ${rowIndex + 1}',
                      onTap: onExpandedChanged != null
                          ? () => _toggleExpanded(rowIndex)
                          : null,
                    )
                  : const SizedBox.shrink(),
            ),
          if (_selectable)
            _LeadingCell(
              child: rowIndex == null
                  ? (selectAll ?? const SizedBox.shrink())
                  : _RowSelector(
                      height: size.height,
                      multi: selection == CarbonTableSelection.multi,
                      selected: selectedRows.contains(rowIndex),
                      label: 'Select row ${rowIndex + 1}',
                      onChanged: onSelectionChanged != null
                          ? () => _toggleRow(rowIndex)
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
      onSort: onSort,
      leading: leadingRow(rowIndex: null),
    );

    final List<Widget> bodyRows = <Widget>[
      for (int i = 0; i < rows.length; i++) ...<Widget>[
        _BodyRow(
          row: rows[i],
          columns: columns,
          size: size,
          // Zebra tints even rows (`tr:nth-child(even)`); rows are 1-based in
          // CSS, so the 0-based odd index is the even child.
          tinted: zebra && i.isOdd,
          isLast: i == rows.length - 1 && !expandedRows.contains(i),
          selected: selectedRows.contains(i),
          expanded: expandedRows.contains(i),
          leading: leadingRow(rowIndex: i),
        ),
        if (expandable && rows[i].expandedContent != null)
          _ExpandedDetail(
            expanded: expandedRows.contains(i),
            isLast: i == rows.length - 1,
            child: rows[i].expandedContent!,
          ),
      ],
    ];

    final Widget headerArea = selection == CarbonTableSelection.multi
        ? _BatchHeader(
            size: size,
            header: header,
            selectedCount: selectedRows.length,
            actions: batchActions ?? const <CarbonTableBatchAction>[],
            cancelLabel: batchCancelLabel,
            onCancel: () => onSelectionChanged?.call(<int>{}),
          )
        : header;

    final Widget body = stickyHeader
        ? ConstrainedBox(
            constraints: BoxConstraints(maxHeight: stickyHeaderHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: bodyRows,
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
              Padding(
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
                      Row(
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
                    if (description != null)
                      Padding(
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
                  ],
                ),
              ),
            headerArea,
            body,
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
    required this.onSort,
    required this.leading,
  });

  final List<CarbonTableColumn> columns;
  final CarbonTableSize size;
  final int? sortColumnIndex;
  final CarbonSortDirection sortDirection;
  final ValueChanged<int>? onSort;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return ColoredBox(
      color: layer.layerAccent,
      // Row height is a minimum: cells grow the band under text scaling
      // instead of clipping (docs/text-scaling.md).
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height),
        child: Row(
          children: <Widget>[
            ?leading,
            for (int i = 0; i < columns.length; i++)
              Expanded(
                flex: columns[i].flex,
                child: _HeaderCell(
                  column: columns[i],
                  direction: sortColumnIndex == i
                      ? sortDirection
                      : CarbonSortDirection.none,
                  onSort: columns[i].sortable && onSort != null
                      ? () => onSort!(i)
                      : null,
                ),
              ),
          ],
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
  });

  final CarbonTableColumn column;
  final CarbonSortDirection direction;
  final VoidCallback? onSort;

  @override
  State<_HeaderCell> createState() => _HeaderCellState();
}

class _HeaderCellState extends State<_HeaderCell> {
  bool _hovered = false;
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onSort != null &&
        event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onSort!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool active = widget.direction != CarbonSortDirection.none;

    Widget label = Text(
      widget.column.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: CarbonTypeStyles.headingCompact01.copyWith(
        color: theme.textPrimary,
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

    if (widget.onSort == null) {
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

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSort,
        child: Focus(
          onKeyEvent: _onKey,
          onFocusChange: (bool f) => setState(() => _focused = f),
          child: CarbonFocusRing(
            visible: _focused,
            inset: true,
            child: ColoredBox(
              // Active / hovered sortable headers tint slightly.
              color: active || _hovered
                  ? layer.layerHover
                  : const Color(0x00000000),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CarbonSpacing.spacing05,
                ),
                child: Row(
                  children: <Widget>[
                    Flexible(child: label),
                    const SizedBox(width: CarbonSpacing.spacing03),
                    glyph,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A body row with hover, optional zebra tint and a bottom divider.
class _BodyRow extends StatefulWidget {
  const _BodyRow({
    required this.row,
    required this.columns,
    required this.size,
    required this.tinted,
    required this.isLast,
    required this.selected,
    required this.expanded,
    required this.leading,
  });

  final CarbonTableRow row;
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

    Widget content = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // Row fill per `_data-table.scss` `tbody tr`: background-color
      // $duration-fast-01 motion(entrance, productive).
      child: AnimatedContainer(
        duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
            ? Duration.zero
            : CarbonDuration.fast01,
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
              ],
            ),
          ),
        ),
      ),
    );

    // Selected rows carry a 3px border-interactive marker on the start edge.
    if (widget.selected) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(color: theme.borderInteractive, width: 3),
          ),
        ),
        child: content,
      );
    }
    return content;
  }
}

/// A fixed-width leading cell holding an expand chevron or a selector.
class _LeadingCell extends StatelessWidget {
  const _LeadingCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: CarbonSpacing.spacing09,
    child: Align(child: child),
  );
}

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
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Semantics(
      button: true,
      expanded: widget.expanded,
      label: widget.label,
      onTap: widget.onTap,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Focus(
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
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
                    duration:
                        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                        ? Duration.zero
                        : CarbonDuration.moderate01,
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
    required this.expanded,
    required this.isLast,
    required this.child,
  });

  final bool expanded;
  final bool isLast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    // Detail fold per `_data-table-expandable.scss` `tr[data-child-row]`:
    // height $duration-moderate-01 motion(standard, productive).
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: expanded ? 1 : 0),
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : CarbonDuration.moderate01,
      curve: CarbonEasing.standardProductive,
      builder: (BuildContext context, double t, Widget? child) => ClipRect(
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
              color: isLast ? const Color(0x00000000) : layer.borderSubtle,
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
    );
  }
}

/// The leading per-row selector — a checkbox (multi) or radio (single).
class _RowSelector extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MergeSemantics(
      // Web checkable roles retain their initial checkbox/radio kind. Replace
      // the node when selection mode changes so the role follows the control.
      key: ValueKey<bool>(multi),
      child: Semantics(
        label: label,
        checked: selected,
        inMutuallyExclusiveGroup: !multi,
        enabled: onChanged != null,
        onTap: onChanged,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged,
          child: SizedBox(
            width: CarbonSpacing.spacing09,
            height: height,
            child: Center(
              child: multi
                  ? CarbonCheckbox(
                      label: '',
                      value: selected,
                      onChanged: onChanged != null ? (_) => onChanged!() : null,
                    )
                  : CarbonRadioButton(
                      label: '',
                      selected: selected,
                      onSelected: onChanged,
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
  final VoidCallback onCancel;

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
            duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                ? Duration.zero
                : CarbonDuration.fast02,
            curve: CarbonEasing.standardProductive,
            child: ExcludeSemantics(
              excluding: !active,
              child: IgnorePointer(ignoring: !active, child: bar),
            ),
          ),
        ],
      ),
    );
  }
}
