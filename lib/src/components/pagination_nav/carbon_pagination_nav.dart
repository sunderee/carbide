// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/pagination-nav/_pagination-nav.scss
//   react/src/components/PaginationNav/PaginationNav.tsx
//
// PaginationNav is page-number navigation (‹ 1 2 … N ›), distinct from the
// item-range Pagination. When the pages exceed `itemsShown` the middle
// collapses into overflow menus of the hidden pages (Carbon's calculateCuts).

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../foundations/fonts.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';
import '../button/carbon_button.dart';
import '../menu/carbon_menu.dart';
import '../overflow_menu/carbon_overflow_menu.dart';
import '../tooltip/carbon_tooltip.dart';

/// The button height of a [CarbonPaginationNav].
enum CarbonPaginationNavSize {
  /// 32px.
  sm(32, CarbonButtonSize.sm),

  /// 40px.
  md(40, CarbonButtonSize.md),

  /// 48px — the default.
  lg(48, CarbonButtonSize.lg);

  const CarbonPaginationNavSize(this.height, this.buttonSize);

  /// The button edge length in logical pixels.
  final double height;

  /// The matching direction-button size.
  final CarbonButtonSize buttonSize;
}

/// The number of hidden pages on each side of the visible window.
typedef _Cuts = ({int front, int back});

/// Page-number navigation with previous/next arrows and overflow truncation.
///
/// Controlled: [page] is the 0-based current page and [onChange] reports the
/// requested page. When more than [itemsShown] pages exist, the middle
/// collapses into overflow menus.
///
/// ```dart
/// CarbonPaginationNav(
///   totalItems: 20,
///   page: _page,
///   onChange: (int p) => setState(() => _page = p),
/// )
/// ```
class CarbonPaginationNav extends StatelessWidget {
  /// Creates a pagination nav.
  const CarbonPaginationNav({
    required this.totalItems,
    required this.page,
    required this.onChange,
    super.key,
    this.itemsShown = 10,
    this.loop = false,
    this.size = CarbonPaginationNavSize.lg,
    this.disableOverflow = false,
  }) : assert(totalItems > 0, 'totalItems must be positive'),
       assert(
         page >= 0 && page < totalItems,
         'page must be within 0..totalItems-1',
       );

  /// The total number of pages.
  final int totalItems;

  /// The current page (0-based).
  final int page;

  /// Called with the requested page index.
  final ValueChanged<int> onChange;

  /// The number of page buttons to show before collapsing.
  final int itemsShown;

  /// Whether the arrows wrap around at the first/last page.
  final bool loop;

  /// The button size.
  final CarbonPaginationNavSize size;

  /// Whether to render overflow as a static ellipsis instead of a menu.
  final bool disableOverflow;

  /// Port of Carbon's `calculateCuts`: how many pages to hide front/back.
  static _Cuts _calculateCuts(int page, int total, int displayed) {
    if (displayed >= total) {
      return (front: 0, back: 0);
    }
    final int split = (displayed / 2).ceil() - 1;
    int front = page + 1 - split;
    int back = total - page - (displayed - split) + 1;
    if (front <= 1) {
      if (front <= 0) {
        back -= front.abs() + 1;
      }
      front = 0;
    }
    if (back <= 1) {
      if (back <= 0) {
        front -= back.abs() + 1;
      }
      back = 0;
    }
    return (front: front, back: back);
  }

  void _go(int index) {
    if (index >= 0 && index < totalItems && index != page) {
      onChange(index);
    } else if (loop) {
      onChange((index + totalItems) % totalItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int displayed = math.max(itemsShown >= 4 ? itemsShown : 5, 4);
    final _Cuts cuts = _calculateCuts(page, totalItems, displayed);
    final int startOffset = (displayed <= 4 && page > 1) ? 0 : 1;

    // The prev/next carets point along the reading direction
    // (`[dir='rtl'] svg { rotate(0.5turn) }` upstream).
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final List<Widget> items = <Widget>[
      _arrow(
        icon: rtl ? CarbonIcons.caretRight : CarbonIcons.caretLeft,
        label: 'Previous page',
        onPressed: (loop || page > 0) ? () => _go(page - 1) : null,
      ),
    ];

    if (displayed >= 5 || (displayed <= 4 && page <= 1)) {
      items.add(_page(0));
    }
    if (cuts.front > 0) {
      items.add(_overflow(startOffset, cuts.front));
    }
    final int midEnd = totalItems - cuts.back - 1;
    for (int i = startOffset + cuts.front; i < midEnd; i++) {
      items.add(_page(i));
    }
    if (cuts.back > 0) {
      items.add(_overflow(totalItems - cuts.back - 1, cuts.back));
    }
    if (totalItems > 1) {
      items.add(_page(totalItems - 1));
    }

    items.add(
      _arrow(
        icon: rtl ? CarbonIcons.caretLeft : CarbonIcons.caretRight,
        label: 'Next page',
        onPressed: (loop || page < totalItems - 1) ? () => _go(page + 1) : null,
      ),
    );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Page ${page + 1} of $totalItems',
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }

  Widget _arrow({
    required CarbonIconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) => CarbonTooltip(
    label: label,
    child: CarbonButton.iconOnly(
      icon: icon,
      iconDescription: label,
      kind: CarbonButtonKind.ghost,
      size: size.buttonSize,
      onPressed: onPressed,
    ),
  );

  Widget _page(int index) => _PageButton(
    number: index + 1,
    active: index == page,
    height: size.height,
    onPressed: () => _go(index),
  );

  Widget _overflow(int fromIndex, int count) {
    if (disableOverflow) {
      return _EllipsisButton(height: size.height);
    }
    return SizedBox(
      width: size.height,
      height: size.height,
      child: Center(
        child: CarbonOverflowMenu(
          iconDescription: 'More pages',
          buttonSize: size.buttonSize,
          items: <Widget>[
            for (int j = 0; j < count; j++)
              CarbonMenuItem(
                label: '${fromIndex + j + 1}',
                onPressed: () => _go(fromIndex + j),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single page-number button.
class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.number,
    required this.active,
    required this.height,
    required this.onPressed,
  });

  final int number;
  final bool active;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Semantics(
      button: true,
      selected: active,
      child: ExcludeSemantics(
        child: CarbonInteraction(
          onPressed: onPressed,
          builder: (BuildContext context, Set<WidgetState> states) {
            final Color background = states.contains(WidgetState.hovered)
                ? theme.backgroundHover
                : const Color(0x00000000);
            return CarbonFocusRing(
              visible: states.contains(WidgetState.focused),
              child: Container(
                height: height,
                constraints: BoxConstraints(minWidth: height),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  border: active
                      ? Border(
                          bottom: BorderSide(
                            color: theme.borderInteractive,
                            width: 2,
                          ),
                        )
                      : null,
                ),
                child: Text(
                  '$number',
                  semanticsLabel: 'Page $number',
                  style: TextStyle(
                    fontFamily: CarbonFontFamily.sans,
                    fontSize: 14,
                    height: 1,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: theme.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A static overflow ellipsis (when overflow menus are disabled).
class _EllipsisButton extends StatelessWidget {
  const _EllipsisButton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return SizedBox(
      width: height,
      height: height,
      child: Center(
        child: Text(
          '…',
          style: TextStyle(
            fontFamily: CarbonFontFamily.sans,
            fontSize: 14,
            color: theme.textPrimary,
          ),
        ),
      ),
    );
  }
}
