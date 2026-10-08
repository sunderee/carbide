// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/pagination/_pagination.scss
//   react/src/components/Pagination/Pagination.tsx
//
// Pagination: a footer bar with an items-per-page select, a range readout, a
// page select and prev/next arrows. Reuses Select (#70). (PaginationNav — the
// numbered variant — is a follow-up.)

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'pagination_localizations.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../button/carbon_button.dart';
import '../form/carbon_form.dart' show CarbonFieldSize;
import '../select/carbon_select.dart';
import '../list_box/list_box_semantics.dart'
    show CarbonListBoxActiveOptionFormatter;

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
    this.localizations = CarbonPaginationLocalizations.enUS,
    String? itemsPerPageText,
    String? backwardText,
    String? forwardText,
    // Keep the public parameter names while storing nullable delegate overrides.
    // ignore: prefer_initializing_formals
  }) : _itemsPerPageText = itemsPerPageText,
       // ignore: prefer_initializing_formals
       _backwardText = backwardText,
       // ignore: prefer_initializing_formals
       _forwardText = forwardText,
       assert(pageSize > 0, 'pageSize must be positive.'),
       assert(page >= 1, 'page is one-based.'),
       assert(totalItems >= 0, 'totalItems must be non-negative.');

  /// The current page (1-based). Values beyond the current result set are
  /// clamped for display and navigation, including during a filter shrink.
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
  String get itemsPerPageText =>
      _itemsPerPageText ?? localizations.itemsPerPageLabel;
  final String? _itemsPerPageText;

  /// The accessible label for the previous-page button.
  String get backwardText => _backwardText ?? localizations.previousPageLabel;
  final String? _backwardText;

  /// The accessible label for the next-page button.
  String get forwardText => _forwardText ?? localizations.nextPageLabel;
  final String? _forwardText;

  /// Labels and complete-phrase formatters, with legacy text overrides taking
  /// precedence when supplied.
  final CarbonPaginationLocalizations localizations;

  int get _totalPages => totalItems == 0 ? 1 : (totalItems - 1) ~/ pageSize + 1;
  int get _currentPage => page.clamp(1, _totalPages);

  List<int> get _pageChoices {
    final int total = _totalPages;
    final int current = _currentPage;
    final int first = current > 2 ? current - 2 : 1;
    final int last = current <= total - 2 ? current + 2 : total;
    return <int>{
      1,
      for (int offset = 0; offset <= last - first; offset++) first + offset,
      total,
    }.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    // List inspection is deferred so the public constructor remains const.
    // Recheck on build as callers can replace their size configuration.
    assert(pageSizes.isNotEmpty, 'pageSizes must not be empty.');
    assert(pageSizes.every((size) => size > 0), 'pageSizes must be positive.');
    assert(
      pageSizes.toSet().length == pageSizes.length,
      'pageSizes must be unique.',
    );
    return _PaginationBody(configuration: this);
  }
}

class _PaginationBody extends StatefulWidget {
  const _PaginationBody({required this.configuration});
  final CarbonPagination configuration;
  @override
  State<_PaginationBody> createState() => _PaginationBodyState();
}

class _PaginationBodyState extends State<_PaginationBody> {
  final GlobalKey _sizeKey = GlobalKey();
  final GlobalKey _pageKey = GlobalKey();
  final GlobalKey _previousKey = GlobalKey();
  final GlobalKey _nextKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final CarbonPagination config = widget.configuration;
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final CarbonPaginationLocalizations labels = config.localizations;
    final int page = config._currentPage;
    final int totalPages = config._totalPages;
    final int start = config.totalItems == 0
        ? 0
        : (page - 1) * config.pageSize + 1;
    // Avoid multiplying the last page by a potentially enormous page size.
    final int end = config.totalItems == 0
        ? 0
        : start - 1 + math.min(config.pageSize, config.totalItems - start + 1);
    final String range = labels.formatRange(start, end, config.totalItems);
    final String pageCount = labels.formatPageCount(totalPages);
    final TextStyle text = CarbonTypeStyles.bodyCompact01.copyWith(
      color: theme.textPrimary,
      locale: labels.locale,
    );
    double textWidth(String value) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: value, style: text),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final double width = painter.width;
      painter.dispose();
      return width;
    }

    double selectWidth(int value) =>
        math.max(112, textWidth(labels.formatNumber(value)) + 56);
    final double sizeWidth = selectWidth(config.pageSize);
    final double pageWidth = selectWidth(page);
    final double requiredWidth =
        textWidth(config.itemsPerPageText) +
        textWidth(range) +
        textWidth(pageCount) +
        sizeWidth +
        pageWidth +
        96 +
        80 +
        4;
    final Widget sizeSelect = _IntSelect(
      key: _sizeKey,
      label: config.itemsPerPageText,
      value: config.pageSize,
      options: <int>[
        ...config.pageSizes,
        if (!config.pageSizes.contains(config.pageSize)) config.pageSize,
      ],
      maximumWidth: sizeWidth,
      formatNumber: labels.formatNumber,
      activeOptionFormatter: labels.activeOptionFormatter,
      onChanged: config.onPageSizeChanged,
    );
    final Widget pageSelect = _IntSelect(
      key: _pageKey,
      label: labels.pageLabel,
      value: page,
      options: config._pageChoices,
      maximumWidth: pageWidth,
      formatNumber: labels.formatNumber,
      activeOptionFormatter: labels.activeOptionFormatter,
      onChanged: config.onPageChanged,
    );
    final Widget previous = CarbonButton.iconOnly(
      key: _previousKey,
      icon: Directionality.of(context) == TextDirection.rtl
          ? CarbonIcons.chevronRight
          : CarbonIcons.chevronLeft,
      iconDescription: config.backwardText,
      kind: CarbonButtonKind.ghost,
      size: CarbonButtonSize.lg,
      onPressed: page > 1 && config.onPageChanged != null
          ? () => config.onPageChanged!(page - 1)
          : null,
    );
    final Widget next = CarbonButton.iconOnly(
      key: _nextKey,
      icon: Directionality.of(context) == TextDirection.rtl
          ? CarbonIcons.chevronLeft
          : CarbonIcons.chevronRight,
      iconDescription: config.forwardText,
      kind: CarbonButtonKind.ghost,
      size: CarbonButtonSize.lg,
      onPressed: page < totalPages && config.onPageChanged != null
          ? () => config.onPageChanged!(page + 1)
          : null,
    );
    Widget divider() =>
        SizedBox(width: 1, child: ColoredBox(color: layer.borderSubtle));
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: labels.paginationLabel,
      localeForSubtree: labels.locale,
      child: DefaultTextStyle.merge(
        style: text,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: CarbonFieldSize.lg.height),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: layer.borderSubtle)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedWidth ||
                    constraints.maxWidth >=
                        math.max(CarbonBreakpoint.md.width, requiredWidth)) {
                  return SizedBox(
                    width: constraints.hasBoundedWidth ? null : requiredWidth,
                    child: Row(
                      children: <Widget>[
                        const SizedBox(width: CarbonSpacing.spacing05),
                        Text(config.itemsPerPageText),
                        const SizedBox(width: CarbonSpacing.spacing05),
                        sizeSelect,
                        divider(),
                        const SizedBox(width: CarbonSpacing.spacing05),
                        Text(range),
                        const Spacer(),
                        divider(),
                        const SizedBox(width: CarbonSpacing.spacing05),
                        pageSelect,
                        const SizedBox(width: CarbonSpacing.spacing05),
                        Text(pageCount),
                        divider(),
                        previous,
                        divider(),
                        next,
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(config.itemsPerPageText),
                          sizeSelect,
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(range),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[pageSelect, Text(pageCount)],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[previous, divider(), next],
                        ),
                      ),
                    ],
                  ),
                );
              },
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
    required this.maximumWidth,
    required this.formatNumber,
    required this.activeOptionFormatter,
    super.key,
  });

  final String label;
  final int value;
  final List<int> options;
  final ValueChanged<int>? onChanged;
  final double maximumWidth;
  final CarbonPaginationNumberFormatter formatNumber;
  final CarbonListBoxActiveOptionFormatter activeOptionFormatter;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: maximumWidth,
        maxWidth: maximumWidth,
      ),
      child: CarbonSelect<int>(
        labelText: label,
        hideLabel: true,
        activeOptionFormatter: activeOptionFormatter,
        size: CarbonFieldSize.sm,
        value: value,
        onChanged: onChanged,
        items: <CarbonSelectEntry<int>>[
          for (final int option in options)
            CarbonSelectItem<int>(value: option, label: formatNumber(option)),
        ],
      ),
    );
  }
}
