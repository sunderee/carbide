// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/breadcrumb/_breadcrumb.scss
//   react/src/components/Breadcrumb/{Breadcrumb,BreadcrumbItem}.tsx
//
// Breadcrumb: a row of links separated by '/', the last marked as the current
// page. Links reuse the M5 CarbonLink. (Overflow collapse into an OverflowMenu
// is a follow-up.)

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../link/carbon_link.dart';

/// A single crumb in a [CarbonBreadcrumb].
class CarbonBreadcrumbItem {
  /// Creates a breadcrumb item.
  const CarbonBreadcrumbItem({
    required this.label,
    this.onPressed,
    this.isCurrentPage = false,
  });

  /// The crumb label.
  final String label;

  /// The navigation action; null renders a non-interactive crumb.
  final VoidCallback? onPressed;

  /// Whether this is the current page (rendered as plain `text-primary`).
  final bool isCurrentPage;
}

/// A breadcrumb trail of [items] separated by slashes.
///
/// ```dart
/// CarbonBreadcrumb(
///   items: <CarbonBreadcrumbItem>[
///     CarbonBreadcrumbItem(label: 'Home', onPressed: _goHome),
///     CarbonBreadcrumbItem(label: 'Reports', onPressed: _goReports),
///     const CarbonBreadcrumbItem(label: 'Q3', isCurrentPage: true),
///   ],
/// )
/// ```
class CarbonBreadcrumb extends StatelessWidget {
  /// Creates a breadcrumb.
  const CarbonBreadcrumb({
    required this.items,
    super.key,
    this.size = CarbonLinkSize.md,
    this.noTrailingSlash = true,
  });

  /// The crumbs, in order.
  final List<CarbonBreadcrumbItem> items;

  /// The link size.
  final CarbonLinkSize size;

  /// Whether to omit the slash after the last crumb.
  final bool noTrailingSlash;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final TextStyle separatorStyle = CarbonTypeStyles.bodyCompact01.copyWith(
      color: theme.textPrimary,
    );

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final CarbonBreadcrumbItem item = items[i];
      children.add(
        item.isCurrentPage || item.onPressed == null
            ? Text(
                item.label,
                style: CarbonTypeStyles.bodyCompact01.copyWith(
                  color: theme.textPrimary,
                ),
              )
            : CarbonLink(
                label: item.label,
                size: size,
                onPressed: item.onPressed,
              ),
      );
      final bool last = i == items.length - 1;
      if (!last || !noTrailingSlash) {
        // The slash separator (margin-inline $spacing-03 around it).
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CarbonSpacing.spacing03,
            ),
            child: Text('/', style: separatorStyle),
          ),
        );
      }
    }

    return Semantics(
      container: true,
      label: 'Breadcrumb',
      explicitChildNodes: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}
