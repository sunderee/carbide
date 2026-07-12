// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/contained-list/_contained-list.scss
//   react/src/components/ContainedList/ContainedList.tsx
//   react/src/components/ContainedList/ContainedListItem/ContainedListItem.tsx
//
// ContainedList is a titled list of items separated by hairline rules. Items
// may carry a leading icon, a trailing action, and an onPressed handler that
// makes the row a layer-contextual clickable button.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';

/// The row height of a [CarbonContainedList].
enum CarbonContainedListSize {
  /// 32px rows.
  sm(32),

  /// 40px rows — the default.
  md(40),

  /// 48px rows.
  lg(48),

  /// 64px rows.
  xl(64);

  const CarbonContainedListSize(this.height);

  /// The row height in logical pixels.
  final double height;
}

/// How a [CarbonContainedList] presents its header.
enum CarbonContainedListKind {
  /// For lists shown directly on a page (a `layerBackground` header).
  onPage,

  /// For lists shown inside a disclosure or popover (a compact `layer` header).
  disclosed,
}

/// A titled list of [CarbonContainedListItem]s separated by hairline rules.
///
/// ```dart
/// CarbonContainedList(
///   label: 'Recent',
///   children: <Widget>[
///     CarbonContainedListItem(child: const Text('One')),
///     CarbonContainedListItem(child: const Text('Two'), onPressed: _open),
///   ],
/// )
/// ```
class CarbonContainedList extends StatelessWidget {
  /// Creates a contained list.
  const CarbonContainedList({
    required this.children,
    super.key,
    this.label,
    this.action,
    this.kind = CarbonContainedListKind.onPage,
    this.size = CarbonContainedListSize.md,
    this.isInset = false,
  });

  /// The list items, typically [CarbonContainedListItem]s.
  final List<Widget> children;

  /// An optional heading shown above the list.
  final Widget? label;

  /// An optional action shown at the end of the header.
  final Widget? action;

  /// The header presentation.
  final CarbonContainedListKind kind;

  /// The row height applied to every item.
  final CarbonContainedListSize size;

  /// Whether the dividing rules are inset by the item padding.
  final bool isInset;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool disclosed = kind == CarbonContainedListKind.disclosed;

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(
          Padding(
            padding: isInset
                ? const EdgeInsetsDirectional.symmetric(
                    horizontal: CarbonSpacing.spacing05,
                  )
                : EdgeInsets.zero,
            child: ColoredBox(
              color: layer.borderSubtle,
              child: const SizedBox(height: 1, width: double.infinity),
            ),
          ),
        );
      }
    }

    return _ContainedListScope(
      size: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (label != null)
            DecoratedBox(
              decoration: BoxDecoration(
                color: disclosed ? layer.layer : layer.layerBackground,
                border: Border(bottom: BorderSide(color: layer.borderSubtle)),
              ),
              child: SizedBox(
                height: disclosed ? CarbonSpacing.spacing07 : size.height,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: CarbonSpacing.spacing05,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: DefaultTextStyle.merge(
                            style: CarbonTypeStyles.headingCompact01.copyWith(
                              color: theme.textPrimary,
                            ),
                            child: label!,
                          ),
                        ),
                      ),
                      ?action,
                    ],
                  ),
                ),
              ),
            ),
          ...rows,
        ],
      ),
    );
  }
}

/// A single row in a [CarbonContainedList].
///
/// Supplying [onPressed] turns the row into a layer-contextual clickable button.
class CarbonContainedListItem extends StatelessWidget {
  /// Creates a contained-list item.
  const CarbonContainedListItem({
    required this.child,
    super.key,
    this.onPressed,
    this.disabled = false,
    this.icon,
    this.action,
  });

  /// The item content (must not itself be interactive — use [action]).
  final Widget child;

  /// Makes the row a clickable button when non-null.
  final VoidCallback? onPressed;

  /// Whether the row is disabled.
  final bool disabled;

  /// An optional leading icon.
  final CarbonIconData? icon;

  /// An optional trailing action (e.g. an icon button).
  final Widget? action;

  bool get _clickable => onPressed != null && !disabled;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonContainedListSize size = _ContainedListScope.of(context).size;
    final Color textColor = disabled ? theme.textDisabled : theme.textPrimary;

    Widget content = Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          CarbonIcon(
            icon!,
            color: disabled ? theme.iconDisabled : theme.iconPrimary,
          ),
          const SizedBox(width: CarbonSpacing.spacing04),
        ],
        Expanded(
          child: DefaultTextStyle.merge(
            style: CarbonTypeStyles.body01.copyWith(color: textColor),
            child: child,
          ),
        ),
      ],
    );

    // padding-block centres a single line to exactly the row height
    // ((height - 1lh) / 2); min-height keeps the floor, so taller content grows.
    const TextStyle bodyStyle = CarbonTypeStyles.body01;
    final double lineHeight =
        (bodyStyle.fontSize ?? 14) * (bodyStyle.height ?? 1.0);
    final double padBlock = ((size.height - lineHeight) / 2).clamp(
      0,
      double.infinity,
    );
    content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: size.height),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: CarbonSpacing.spacing05,
          end: CarbonSpacing.spacing05,
          top: padBlock,
          bottom: padBlock,
        ),
        child: content,
      ),
    );

    final Widget body = _clickable
        ? _ClickableRow(onPressed: onPressed!, child: content)
        : content;

    if (action == null) {
      return body;
    }
    // The action sits at the trailing edge, centred against the row.
    return Row(
      children: <Widget>[
        Expanded(child: body),
        action!,
      ],
    );
  }
}

/// The clickable content button: hover/active fill the contextual layer tokens.
class _ClickableRow extends StatelessWidget {
  const _ClickableRow({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return Semantics(
      button: true,
      child: CarbonInteraction(
        onPressed: onPressed,
        builder: (BuildContext context, Set<WidgetState> states) {
          final Color color = states.contains(WidgetState.pressed)
              ? layer.layerActive
              : states.contains(WidgetState.hovered)
              ? layer.layerHover
              : const Color(0x00000000);
          return CarbonFocusRing(
            visible: states.contains(WidgetState.focused),
            child: AnimatedContainer(
              duration: CarbonDuration.moderate01,
              curve: CarbonEasing.standardProductive,
              decoration: BoxDecoration(color: color),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Propagates the list [size] to descendant [CarbonContainedListItem]s.
class _ContainedListScope extends InheritedWidget {
  const _ContainedListScope({required this.size, required super.child});

  final CarbonContainedListSize size;

  static _ContainedListScope of(BuildContext context) {
    final _ContainedListScope? scope = context
        .dependOnInheritedWidgetOfExactType<_ContainedListScope>();
    return scope ??
        const _ContainedListScope(
          size: CarbonContainedListSize.md,
          child: SizedBox.shrink(),
        );
  }

  @override
  bool updateShouldNotify(_ContainedListScope oldWidget) =>
      size != oldWidget.size;
}
