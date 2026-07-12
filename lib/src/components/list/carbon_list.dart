// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/list/_list.scss
//   react/src/components/{OrderedList,UnorderedList,ListItem}

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// Whether a list numbers its items or bullets them.
enum _ListKind { ordered, unordered }

/// Inherited list context: the nesting depth and the expressive flag, so a
/// list nested inside a [CarbonListItem] picks the nested marker and the
/// inherited type scale automatically.
class _ListScope extends InheritedWidget {
  const _ListScope({
    required this.depth,
    required this.expressive,
    required super.child,
  });

  final int depth;
  final bool expressive;

  static _ListScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ListScope>();

  @override
  bool updateShouldNotify(_ListScope oldWidget) =>
      depth != oldWidget.depth || expressive != oldWidget.expressive;
}

/// One row of a Carbon list.
///
/// Holds arbitrary [child] content (commonly text). To nest, place a
/// [CarbonOrderedList] or [CarbonUnorderedList] inside the child — it reads
/// the list context and switches to the nested marker and indent.
class CarbonListItem extends StatelessWidget {
  /// Creates a list item.
  const CarbonListItem({super.key, required this.child});

  /// The item content.
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// An ordered (numbered) Carbon list.
///
/// Top-level items are numbered `1.`, `2.`, …; nested ordered lists use
/// lower-latin markers (`a.`, `b.`, …), per `_list.scss`.
class CarbonOrderedList extends StatelessWidget {
  /// Creates an ordered list.
  const CarbonOrderedList({
    super.key,
    required this.children,
    this.expressive = false,
  });

  /// The list items.
  final List<CarbonListItem> children;

  /// Uses the `body-02` (expressive) type scale instead of `body-01`.
  final bool expressive;

  @override
  Widget build(BuildContext context) => _CarbonList(
    kind: _ListKind.ordered,
    expressive: expressive,
    children: children,
  );
}

/// An unordered (bulleted) Carbon list.
///
/// Top-level items use an en-dash (`–`) marker; nested unordered lists use a
/// small square (`▪`), per `_list.scss`.
class CarbonUnorderedList extends StatelessWidget {
  /// Creates an unordered list.
  const CarbonUnorderedList({
    super.key,
    required this.children,
    this.expressive = false,
  });

  /// The list items.
  final List<CarbonListItem> children;

  /// Uses the `body-02` (expressive) type scale instead of `body-01`.
  final bool expressive;

  @override
  Widget build(BuildContext context) => _CarbonList(
    kind: _ListKind.unordered,
    expressive: expressive,
    children: children,
  );
}

class _CarbonList extends StatelessWidget {
  const _CarbonList({
    required this.kind,
    required this.expressive,
    required this.children,
  });

  final _ListKind kind;
  final bool expressive;
  final List<CarbonListItem> children;

  /// Marker gutters per `_list.scss` (the absolute marker offsets): ordered
  /// `-24px`, unordered top `-spacing-05`, unordered nested `-spacing-04`.
  static const double orderedGutter = 24;
  static const double unorderedGutter = CarbonSpacing.spacing05;
  static const double unorderedNestedGutter = CarbonSpacing.spacing04;

  /// Nested lists step in by 32px (`margin-inline-start`) less the gutter the
  /// items already reserve, so nested content keeps a steady left edge.
  static const double nestedIndent = 32;

  String _marker(int index, bool nested) {
    switch (kind) {
      case _ListKind.ordered:
        if (nested) {
          // lower-latin: 1 -> a, 2 -> b, …
          return '${String.fromCharCode(0x60 + index + 1)}.';
        }
        return '${index + 1}.';
      case _ListKind.unordered:
        return nested ? '▪' : '–';
    }
  }

  double _gutter(bool nested) {
    switch (kind) {
      case _ListKind.ordered:
        return orderedGutter;
      case _ListKind.unordered:
        return nested ? unorderedNestedGutter : unorderedGutter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final _ListScope? parent = _ListScope.maybeOf(context);
    final bool nested = parent != null;
    final bool effectiveExpressive =
        expressive || (parent?.expressive ?? false);
    final TextStyle style =
        (effectiveExpressive
                ? CarbonTypeStyles.body02
                : CarbonTypeStyles.body01)
            .copyWith(color: theme.textPrimary);
    final double gutter = _gutter(nested);

    final List<Widget> rows = <Widget>[
      for (int i = 0; i < children.length; i++)
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: nested ? nestedIndent - gutter : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: gutter,
                child: Text(_marker(i, nested), style: style),
              ),
              Expanded(
                child: DefaultTextStyle(style: style, child: children[i]),
              ),
            ],
          ),
        ),
    ];

    return _ListScope(
      depth: (parent?.depth ?? -1) + 1,
      expressive: effectiveExpressive,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}
