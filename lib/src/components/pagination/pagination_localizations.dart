// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart' show immutable;

import '../list_box/list_box_semantics.dart'
    show CarbonListBoxActiveOptionFormatter, carbonListBoxActiveOptionLabel;

/// Formats an item range, including the total result count.
typedef CarbonPaginationRangeFormatter = String Function(
  int start,
  int end,
  int total,
);

/// Formats a number displayed in a page or page-size control.
typedef CarbonPaginationNumberFormatter = String Function(int value);

/// Injectable pagination labels and formatting, following the date-picker's
/// delegate approach. Consumers can adapt their own formatting backend without
/// adding a dependency to Carbide. Direction comes from ambient directionality.
@immutable
class CarbonPaginationLocalizations {
  /// Creates labels and optional complete-phrase formatters.
  const CarbonPaginationLocalizations({
    this.locale = const Locale('en', 'US'),
    this.paginationLabel = 'Pagination',
    this.itemsPerPageLabel = 'Items per page:',
    this.pageLabel = 'Page',
    this.previousPageLabel = 'Previous page',
    this.nextPageLabel = 'Next page',
    this.rangeFormatter,
    this.pageCountFormatter,
    this.numberFormatter,
    this.activeOptionFormatter = carbonListBoxActiveOptionLabel,
  });

  /// The existing English defaults.
  static const CarbonPaginationLocalizations enUS =
      CarbonPaginationLocalizations();

  /// The locale used to shape pagination text.
  final Locale locale;

  /// The accessible container name.
  final String paginationLabel;

  /// The visible and accessible page-size label.
  final String itemsPerPageLabel;

  /// The accessible page-choice label.
  final String pageLabel;

  /// The accessible previous-page action name.
  final String previousPageLabel;

  /// The accessible next-page action name.
  final String nextPageLabel;

  /// Optional complete item-range phrase, including zero-result cases.
  final CarbonPaginationRangeFormatter? rangeFormatter;

  /// Optional complete page-count phrase, supporting localized plural forms.
  final CarbonPaginationNumberFormatter? pageCountFormatter;

  /// Optional page/page-size numbers, supporting localized numbering systems.
  final CarbonPaginationNumberFormatter? numberFormatter;

  /// Formats the complete active-option announcement for either selector.
  final CarbonListBoxActiveOptionFormatter activeOptionFormatter;

  /// Formats one control value.
  String formatNumber(int value) => numberFormatter?.call(value) ?? '$value';

  /// Formats the range without assuming the caller's grammar or plural rules.
  String formatRange(int start, int end, int total) =>
      rangeFormatter?.call(start, end, total) ??
      '${formatNumber(start)}–${formatNumber(end)} of '
          '${formatNumber(total)} items';

  /// Formats the total page count.
  String formatPageCount(int total) =>
      pageCountFormatter?.call(total) ??
      'of ${formatNumber(total)} ${total == 1 ? 'page' : 'pages'}';
}
