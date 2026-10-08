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
// page. Measured collapse preserves the first/current anchors and discloses
// middle crumbs through the existing OverflowMenu primitive.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/interaction.dart';
import '../menu/carbon_menu.dart';
import '../overflow_menu/carbon_overflow_menu.dart';
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

  /// Whether this is the current page, rendered as selected plain text.
  ///
  /// Navigation callbacks are ignored for a current page. Mark the final item
  /// and localize its announcement with [CarbonBreadcrumb.currentPageLabel].
  final bool isCurrentPage;
}

/// A breadcrumb trail of [items] separated by slashes.
///
/// Constrained trails keep their first/last items and disclose hidden middle
/// ancestors through [CarbonOverflowMenu]. Labels remain on one line and
/// retain complete accessible names when ellipsized. An Overlay host is needed
/// to open the menu, as supplied by `WidgetsApp` and Navigator.
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
class CarbonBreadcrumb extends StatefulWidget {
  /// Creates a breadcrumb.
  const CarbonBreadcrumb({
    required this.items,
    super.key,
    this.size = CarbonLinkSize.md,
    this.noTrailingSlash = true,
    this.breadcrumbLabel = 'Breadcrumb',
    this.overflowLabel = 'More breadcrumbs',
    this.currentPageLabel = 'Current page',
  });

  /// The crumbs, in order.
  final List<CarbonBreadcrumbItem> items;

  /// The link size.
  final CarbonLinkSize size;

  /// Whether to omit the slash after the last crumb.
  final bool noTrailingSlash;

  /// The localized accessible name of the breadcrumb region.
  final String breadcrumbLabel;

  /// The localized accessible name of the collapsed-crumb trigger.
  final String overflowLabel;

  /// The localized description appended to the current page's accessible name.
  final String currentPageLabel;

  @override
  State<CarbonBreadcrumb> createState() => _CarbonBreadcrumbState();
}

class _CarbonBreadcrumbState extends State<CarbonBreadcrumb> {
  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  void _fontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    super.dispose();
  }

  double _measure(String label, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final TextStyle plainStyle = CarbonTypeStyles.bodyCompact01.copyWith(
      color: theme.textPrimary,
    );
    final List<double> widths = <double>[
      for (final CarbonBreadcrumbItem item in widget.items)
        _measure(
          item.label,
          item.isCurrentPage || item.onPressed == null
              ? plainStyle
              : widget.size.style,
        ),
    ];
    final double slashWidth = _measure('/', plainStyle);
    final double separatorWidth = slashWidth + 2 * CarbonSpacing.spacing03;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      container: true,
      label: widget.breadcrumbLabel,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (widget.items.isEmpty) return const SizedBox.shrink();
          final int count = widget.items.length;
          double total(List<int> visible, {bool collapsed = false}) =>
              visible.fold<double>(0, (double sum, int i) => sum + widths[i]) +
              (collapsed ? 16 : 0) +
              (visible.length -
                      1 +
                      (collapsed ? 1 : 0) +
                      (widget.noTrailingSlash ? 0 : 1)) *
                  separatorWidth;
          List<int> visible = List<int>.generate(count, (int i) => i);
          final bool collapsed =
              count > 2 && total(visible) > constraints.maxWidth;
          if (collapsed) {
            visible = <int>[0, count - 1];
            // Keep the nearest ancestors of the current page while they fit.
            for (int i = count - 2; i > 1; i--) {
              final List<int> candidate = <int>[0, i, ...visible.skip(1)];
              if (total(candidate, collapsed: true) > constraints.maxWidth) {
                break;
              }
              visible = candidate;
            }
          }
          final List<int> hidden = <int>[
            for (int i = 1; i < count - 1; i++)
              if (!visible.contains(i)) i,
          ];
          final int displayed = visible.length + (collapsed ? 1 : 0);
          final int separators =
              displayed - 1 + (widget.noTrailingSlash ? 0 : 1);
          final double triggerWidth = collapsed
              ? math.min(16, constraints.maxWidth)
              : 0;
          final double actualSeparatorWidth =
              constraints.hasBoundedWidth && separators > 0
              ? math.min(
                  separatorWidth,
                  (constraints.maxWidth - triggerWidth) / (separators * 3),
                )
              : separatorWidth;
          final double available = constraints.hasBoundedWidth
              ? math.max(
                  0,
                  constraints.maxWidth -
                      separators * actualSeparatorWidth -
                      triggerWidth,
                )
              : double.infinity;
          final double labelsWidth = visible.fold<double>(
            0,
            (double sum, int i) => sum + widths[i],
          );
          final double ratio = labelsWidth > available && labelsWidth > 0
              ? available / labelsWidth
              : 1;

          Widget crumb(int i) {
            final CarbonBreadcrumbItem item = widget.items[i];
            final Widget content = item.isCurrentPage || item.onPressed == null
                ? Text(
                    item.label,
                    style: plainStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : CarbonLink(
                    label: item.label,
                    size: widget.size,
                    onPressed: item.onPressed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
            final Widget named = item.isCurrentPage
                ? Semantics(
                    container: true,
                    selected: true,
                    label: '${item.label}, ${widget.currentPageLabel}',
                    excludeSemantics: true,
                    child: content,
                  )
                : content;
            return SizedBox(width: widths[i] * ratio, child: named);
          }

          Widget separator() => ExcludeSemantics(
            child: SizedBox(
              width: actualSeparatorWidth,
              child: Center(
                heightFactor: 1,
                child: Transform.flip(
                  flipX: rtl,
                  child: Text('/', style: plainStyle, maxLines: 1),
                ),
              ),
            ),
          );
          final List<Widget> children = <Widget>[];
          for (int slot = 0; slot < visible.length; slot++) {
            if (slot > 0) children.add(separator());
            if (collapsed && slot == 1) {
              children.add(
                SizedBox(
                  width: triggerWidth,
                  child: CarbonOverflowMenu(
                    key: const ValueKey<String>('carbide-breadcrumb-overflow'),
                    menuAlignment: CarbonMenuAlignment.start,
                    iconDescription: widget.overflowLabel,
                    triggerBuilder:
                        (
                          BuildContext context,
                          bool open,
                          VoidCallback toggle,
                        ) => _BreadcrumbTrigger(
                          label: widget.overflowLabel,
                          open: open,
                          onPressed: toggle,
                        ),
                    items: <Widget>[
                      for (final int i in hidden)
                        CarbonMenuItem(
                          label: widget.items[i].label,
                          disabled:
                              widget.items[i].isCurrentPage ||
                              widget.items[i].onPressed == null,
                          onPressed: widget.items[i].isCurrentPage
                              ? null
                              : widget.items[i].onPressed,
                        ),
                    ],
                  ),
                ),
              );
              children.add(separator());
            }
            children.add(
              KeyedSubtree(
                key: ValueKey<int>(visible[slot]),
                child: crumb(visible[slot]),
              ),
            );
          }
          if (!widget.noTrailingSlash) children.add(separator());
          return Row(mainAxisSize: MainAxisSize.min, children: children);
        },
      ),
    );
  }
}

class _BreadcrumbTrigger extends StatelessWidget {
  const _BreadcrumbTrigger({
    required this.label,
    required this.open,
    required this.onPressed,
  });
  final String label;
  final bool open;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return CarbonControlSemantics(
      button: true,
      label: label,
      expanded: open,
      state: CarbonControlState.interactive,
      readOnlyHint: '',
      onActivate: onPressed,
      builder: (FocusNode focus) => ExcludeSemantics(
        child: CarbonInteraction(
          focusNode: focus,
          includeSemantics: false,
          onPressed: onPressed,
          builder: (BuildContext context, Set<WidgetState> states) =>
              DecoratedBox(
                decoration: BoxDecoration(
                  border:
                      states.contains(WidgetState.focused) ||
                          states.contains(WidgetState.pressed)
                      ? Border.all(color: theme.focus)
                      : null,
                ),
                child: SizedBox(
                  width: 16,
                  height: 18,
                  child: CarbonIcon(
                    CarbonIcons.overflowMenuHorizontal,
                    size: 16,
                    color: states.contains(WidgetState.hovered)
                        ? theme.linkPrimaryHover
                        : theme.linkPrimary,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
