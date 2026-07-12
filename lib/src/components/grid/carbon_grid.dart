// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   packages/grid/scss/_config.scss, _css-grid.scss, _breakpoint.scss
//   react/src/components/Grid/{Grid,Column}.tsx
//
// The Carbon 2x Grid: a responsive 16-column (8 at md, 4 at sm) layout.
//
// Spike outcome (Flutter has no CSS-grid engine): resolve the active
// CarbonBreakpoint from the laid-out width, derive one column "unit" from the
// content width, and place CarbonColumns in a Wrap with the gutter as spacing
// so full rows auto-wrap. Per-breakpoint spans cascade from smaller
// breakpoints like CSS; offsets add empty leading tracks. The legacy flexbox
// FlexGrid is intentionally not ported — the CSS grid supersedes it.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';

/// The gutter behaviour of a [CarbonGrid].
enum CarbonGridMode {
  /// 32px gutters (16px of padding on each column edge).
  wide,

  /// 32px gutters, but the first/last columns hang into the margin.
  narrow,

  /// 1px gutters, for dense data layouts.
  condensed;

  /// The gutter width in logical pixels.
  double get gutter => this == CarbonGridMode.condensed ? 1 : 32;
}

/// A responsive 2x Grid.
///
/// Lay out [CarbonColumn]s inside a grid; each column spans a number of the
/// grid's columns (16 at `lg`+, 8 at `md`, 4 at `sm`). The grid must be given a
/// bounded width (e.g. a page body).
///
/// ```dart
/// CarbonGrid(
///   children: <Widget>[
///     CarbonColumn(sm: 4, md: 4, lg: 8, child: main),
///     CarbonColumn(sm: 4, md: 4, lg: 8, child: aside),
///   ],
/// )
/// ```
class CarbonGrid extends StatelessWidget {
  /// Creates a grid.
  const CarbonGrid({
    required this.children,
    super.key,
    this.mode = CarbonGridMode.wide,
    this.fullWidth = false,
    this.rowSpacing = 0,
  });

  /// The grid columns, typically [CarbonColumn]s.
  final List<Widget> children;

  /// The gutter behaviour.
  final CarbonGridMode mode;

  /// Whether to drop the responsive edge margin and fill the available width.
  final bool fullWidth;

  /// Vertical spacing between wrapped rows.
  final double rowSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final CarbonBreakpoint breakpoint = CarbonBreakpoint.of(width);
        final int totalColumns = breakpoint.columns;
        final double gutter = mode.gutter;
        final double margin = fullWidth ? 0 : breakpoint.margin;
        final double contentWidth = width - 2 * margin;
        // One column track. Reserve 1px of slack so floating-point sums never
        // push a full row over the available width and wrap prematurely.
        final double unit =
            ((contentWidth - (totalColumns - 1) * gutter - 1) / totalColumns)
                .clamp(0, double.infinity);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: margin),
          child: _CarbonGridScope(
            breakpoint: breakpoint,
            totalColumns: totalColumns,
            unit: unit,
            gutter: gutter,
            child: Wrap(
              spacing: gutter,
              runSpacing: rowSpacing,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// A column within a [CarbonGrid].
///
/// Provide a span (number of grid columns) per breakpoint; unset breakpoints
/// cascade up from the nearest smaller one (CSS behaviour), falling back to
/// [span] or, if none, the full grid width. [offset] inserts empty leading
/// tracks.
class CarbonColumn extends StatelessWidget {
  /// Creates a grid column.
  const CarbonColumn({
    required this.child,
    super.key,
    this.span,
    this.sm,
    this.md,
    this.lg,
    this.xlg,
    this.max,
    this.offset = 0,
  });

  /// The default span used when no breakpoint-specific span applies.
  final int? span;

  /// The span at the `sm` breakpoint.
  final int? sm;

  /// The span at the `md` breakpoint.
  final int? md;

  /// The span at the `lg` breakpoint.
  final int? lg;

  /// The span at the `xlg` breakpoint.
  final int? xlg;

  /// The span at the `max` breakpoint.
  final int? max;

  /// The number of empty leading tracks before this column.
  final int offset;

  /// The column content.
  final Widget child;

  /// Resolves the span at [breakpoint], cascading up from smaller breakpoints.
  int _resolveSpan(CarbonBreakpoint breakpoint, int totalColumns) {
    final List<int?> byBreakpoint = <int?>[sm, md, lg, xlg, max];
    final int index = CarbonBreakpoint.values.indexOf(breakpoint);
    for (int i = index; i >= 0; i--) {
      if (byBreakpoint[i] != null) {
        return byBreakpoint[i]!;
      }
    }
    return span ?? totalColumns;
  }

  @override
  Widget build(BuildContext context) {
    final _CarbonGridScope scope = _CarbonGridScope.of(context);
    final int resolved = _resolveSpan(
      scope.breakpoint,
      scope.totalColumns,
    ).clamp(1, scope.totalColumns);
    final int tracks = resolved + offset;
    final double width = tracks * scope.unit + (tracks - 1) * scope.gutter;
    final double leading = offset > 0
        ? offset * scope.unit + offset * scope.gutter
        : 0;

    return SizedBox(
      width: width.clamp(0, double.infinity),
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: leading),
        child: child,
      ),
    );
  }
}

/// Propagates the resolved grid metrics to descendant [CarbonColumn]s.
class _CarbonGridScope extends InheritedWidget {
  const _CarbonGridScope({
    required this.breakpoint,
    required this.totalColumns,
    required this.unit,
    required this.gutter,
    required super.child,
  });

  final CarbonBreakpoint breakpoint;
  final int totalColumns;
  final double unit;
  final double gutter;

  static _CarbonGridScope of(BuildContext context) {
    final _CarbonGridScope? scope = context
        .dependOnInheritedWidgetOfExactType<_CarbonGridScope>();
    assert(scope != null, 'CarbonColumn must be placed inside a CarbonGrid');
    return scope!;
  }

  @override
  bool updateShouldNotify(_CarbonGridScope oldWidget) =>
      breakpoint != oldWidget.breakpoint ||
      totalColumns != oldWidget.totalColumns ||
      unit != oldWidget.unit ||
      gutter != oldWidget.gutter;
}
