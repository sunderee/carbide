// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/data-table/action/_data-table-action.scss
//   react/src/components/DataTable/{TableToolbar,TableToolbarContent,
//     TableToolbarSearch,TableToolbarMenu,TableToolbarAction}.tsx
//
// The DataTable toolbar: an expandable search, an optional settings overflow
// menu and primary action buttons, placed above a CarbonDataTable. Composes
// the existing Search (#71), OverflowMenu (#97) and Button.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../theme/carbon_layer.dart';
import '../form/carbon_form.dart' show CarbonFieldSize;
import '../overflow_menu/carbon_overflow_menu.dart';
import '../search/carbon_search.dart';

/// A toolbar shown above a [CarbonDataTable].
///
/// ```dart
/// CarbonTableToolbar(
///   onSearchChanged: (String q) => setState(() => _query = q),
///   overflowItems: <Widget>[
///     CarbonMenuItem(label: 'Settings', onPressed: _settings),
///   ],
///   actions: <Widget>[
///     CarbonButton(label: 'Add', onPressed: _add),
///   ],
/// )
/// ```
class CarbonTableToolbar extends StatelessWidget {
  /// Creates a table toolbar.
  const CarbonTableToolbar({
    super.key,
    this.onSearchChanged,
    this.onSearchCleared,
    this.searchPlaceholder = 'Search',
    this.overflowItems,
    this.actions,
    this.size = CarbonFieldSize.lg,
  });

  /// Enables the expandable search; called with the query as the user types.
  final ValueChanged<String>? onSearchChanged;

  /// Called when the search is cleared.
  final VoidCallback? onSearchCleared;

  /// The search placeholder.
  final String searchPlaceholder;

  /// Items for the settings overflow menu; null hides the menu.
  final List<Widget>? overflowItems;

  /// Trailing action widgets (typically buttons).
  final List<Widget>? actions;

  /// The toolbar height.
  final CarbonFieldSize size;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return ColoredBox(
      color: layer.layer,
      child: SizedBox(
        height: size.height,
        child: Row(
          children: <Widget>[
            Expanded(
              child: onSearchChanged != null
                  ? CarbonExpandableSearch(
                      placeholder: searchPlaceholder,
                      size: size,
                      onChanged: onSearchChanged,
                      onClear: onSearchCleared,
                    )
                  : const SizedBox.shrink(),
            ),
            if (overflowItems != null && overflowItems!.isNotEmpty)
              CarbonOverflowMenu(
                items: overflowItems!,
                iconDescription: 'Table settings',
              ),
            if (actions != null)
              for (final Widget action in actions!)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: CarbonSpacing.spacing01,
                  ),
                  child: IntrinsicWidth(child: action),
                ),
          ],
        ),
      ),
    );
  }
}
