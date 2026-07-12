// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/structured-list/_structured-list.scss
//   react/src/components/StructuredList/StructuredList.tsx
//
// StructuredList: a lightweight table-like list with a header row and body
// rows, plus an optional single-select (radio) variant.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';

/// A row in a [CarbonStructuredList].
class CarbonStructuredListRow {
  /// Creates a structured-list row.
  const CarbonStructuredListRow({required this.cells});

  /// The cell contents, one per column.
  final List<Widget> cells;
}

/// A lightweight table-like list with a header and body rows.
///
/// When [selectable], rows act as a single-select radio group with a trailing
/// checkmark on the selected row.
///
/// ```dart
/// CarbonStructuredList(
///   headers: const <String>['Name', 'Type'],
///   rows: const <CarbonStructuredListRow>[
///     CarbonStructuredListRow(cells: <Widget>[Text('Load'), Text('Routine')]),
///   ],
/// )
/// ```
class CarbonStructuredList extends StatefulWidget {
  /// Creates a structured list.
  const CarbonStructuredList({
    required this.headers,
    required this.rows,
    super.key,
    this.selectable = false,
    this.selectedIndex,
    this.onSelected,
  });

  /// The column headers.
  final List<String> headers;

  /// The body rows.
  final List<CarbonStructuredListRow> rows;

  /// Whether rows are single-selectable.
  final bool selectable;

  /// The selected row (controlled); null lets the widget manage it.
  final int? selectedIndex;

  /// Called with the selected row index.
  final ValueChanged<int>? onSelected;

  @override
  State<CarbonStructuredList> createState() => _CarbonStructuredListState();
}

class _CarbonStructuredListState extends State<CarbonStructuredList> {
  int? _selected;

  int? get _current => widget.selectedIndex ?? _selected;

  void _select(int index) {
    widget.onSelected?.call(index);
    if (widget.selectedIndex == null) setState(() => _selected = index);
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Header row.
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: theme.borderStrong01)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CarbonSpacing.spacing05,
                  vertical: CarbonSpacing.spacing03,
                ),
                child: Row(
                  children: <Widget>[
                    for (final String header in widget.headers)
                      Expanded(
                        child: Text(
                          header,
                          style: CarbonTypeStyles.label01.copyWith(
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    if (widget.selectable) const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
          ),
          for (int i = 0; i < widget.rows.length; i++)
            _Row(
              row: widget.rows[i],
              selectable: widget.selectable,
              selected: i == _current,
              onTap: widget.selectable ? () => _select(i) : null,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.row,
    required this.selectable,
    required this.selected,
    required this.onTap,
  });

  final CarbonStructuredListRow row;
  final bool selectable;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;
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
    final CarbonLayerTokens layer = CarbonLayer.of(context);

    final Color background = widget.selected
        ? layer.layerSelected
        : _hovered && widget.selectable
        ? layer.layerHover
        : const Color(0x00000000);

    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: layer.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CarbonSpacing.spacing05,
          vertical: CarbonSpacing.spacing05,
        ),
        child: DefaultTextStyle.merge(
          style: CarbonTypeStyles.bodyCompact01.copyWith(
            color: theme.textPrimary,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final Widget cell in widget.row.cells) Expanded(child: cell),
              if (widget.selectable)
                SizedBox(
                  width: 24,
                  child: widget.selected
                      ? CarbonIcon(
                          CarbonIcons.checkmarkFilled,
                          color: theme.iconPrimary,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) return content;

    // Merge the row's cell text into a single radio node.
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        checked: widget.selected,
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Focus(
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
              child: CarbonFocusRing(
                visible: _focused,
                inset: true,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
