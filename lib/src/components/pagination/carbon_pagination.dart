// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/pagination/_pagination.scss
//   react/src/components/Pagination/Pagination.tsx
//
// Pagination: a footer bar with an items-per-page select, a range readout, a
// page select and prev/next arrows. Reuses Select (#70). (PaginationNav — the
// numbered variant — is a follow-up.)

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../button/carbon_button.dart';
import '../form/carbon_form.dart' show CarbonFieldSize;
import '../select/carbon_select.dart';

/// A pagination footer bar.
///
/// Shows an items-per-page select, the visible range out of [totalItems], a
/// page select and prev/next arrows (disabled at the ends).
///
/// ```dart
/// CarbonPagination(
///   page: _page,
///   pageSize: _pageSize,
///   totalItems: 100,
///   onPageChanged: (int p) => setState(() => _page = p),
///   onPageSizeChanged: (int s) => setState(() => _pageSize = s),
/// )
/// ```
class CarbonPagination extends StatelessWidget {
  /// Creates a pagination bar.
  const CarbonPagination({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    super.key,
    this.pageSizes = const <int>[10, 20, 30, 40, 50],
    this.onPageChanged,
    this.onPageSizeChanged,
    this.itemsPerPageText = 'Items per page:',
    this.backwardText = 'Previous page',
    this.forwardText = 'Next page',
  });

  /// The current page (1-based).
  final int page;

  /// The current page size.
  final int pageSize;

  /// The total number of items.
  final int totalItems;

  /// The selectable page sizes.
  final List<int> pageSizes;

  /// Called when the page changes.
  final ValueChanged<int>? onPageChanged;

  /// Called when the page size changes.
  final ValueChanged<int>? onPageSizeChanged;

  /// The label before the items-per-page select.
  final String itemsPerPageText;

  /// The accessible label for the previous-page button.
  final String backwardText;

  /// The accessible label for the next-page button.
  final String forwardText;

  int get _totalPages =>
      totalItems == 0 ? 1 : ((totalItems + pageSize - 1) ~/ pageSize);

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final int start = totalItems == 0 ? 0 : (page - 1) * pageSize + 1;
    final int end = (page * pageSize).clamp(0, totalItems);
    final int totalPages = _totalPages;

    final TextStyle text = CarbonTypeStyles.bodyCompact01.copyWith(
      color: theme.textPrimary,
    );

    Widget divider() =>
        SizedBox(width: 1, child: ColoredBox(color: layer.borderSubtle));

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Pagination',
      child: DefaultTextStyle.merge(
        style: text,
        child: SizedBox(
          height: CarbonFieldSize.lg.height,
          child: DecoratedBox(
            // border-block-start: 1px solid border-subtle.
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: layer.borderSubtle)),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: CarbonSpacing.spacing05),
                Text(itemsPerPageText),
                const SizedBox(width: CarbonSpacing.spacing05),
                _IntSelect(
                  label: itemsPerPageText,
                  value: pageSize,
                  options: pageSizes,
                  onChanged: onPageSizeChanged,
                ),
                divider(),
                const SizedBox(width: CarbonSpacing.spacing05),
                Text('$start–$end of $totalItems items'),
                const Spacer(),
                divider(),
                const SizedBox(width: CarbonSpacing.spacing05),
                _IntSelect(
                  label: 'Page',
                  value: page,
                  options: <int>[for (int p = 1; p <= totalPages; p++) p],
                  onChanged: onPageChanged,
                ),
                const SizedBox(width: CarbonSpacing.spacing05),
                Text('of $totalPages pages'),
                divider(),
                CarbonButton.iconOnly(
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? CarbonIcons.chevronRight
                      : CarbonIcons.chevronLeft,
                  iconDescription: backwardText,
                  kind: CarbonButtonKind.ghost,
                  size: CarbonButtonSize.lg,
                  onPressed: page > 1 && onPageChanged != null
                      ? () => onPageChanged!(page - 1)
                      : null,
                ),
                divider(),
                CarbonButton.iconOnly(
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? CarbonIcons.chevronLeft
                      : CarbonIcons.chevronRight,
                  iconDescription: forwardText,
                  kind: CarbonButtonKind.ghost,
                  size: CarbonButtonSize.lg,
                  onPressed: page < totalPages && onPageChanged != null
                      ? () => onPageChanged!(page + 1)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact, label-hidden integer select used by the pagination bar.
class _IntSelect extends StatelessWidget {
  const _IntSelect({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 80, maxWidth: 112),
      child: CarbonSelect<int>(
        labelText: label,
        hideLabel: true,
        size: CarbonFieldSize.sm,
        value: value,
        onChanged: onChanged,
        items: <CarbonSelectEntry<int>>[
          for (final int option in options)
            CarbonSelectItem<int>(value: option, label: '$option'),
        ],
      ),
    );
  }
}
