// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec source (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/button/_button.scss (.cds--btn-set rules)

import 'package:flutter/widgets.dart';

import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import 'carbon_button.dart';

/// A Carbon button set: adjacent equal-width buttons with a 1px separator.
///
/// Per spec, buttons in a set stretch to equal widths capped at 196px and
/// touch edge to edge; a 1px `buttonSeparator` line divides them (using the
/// disabled separator colors when the following button is disabled). Order
/// follows Carbon guidance: secondary action(s) first, primary last.
///
/// Upstream paints the separator as a box-shadow overlay; Carbide inserts a
/// 1px spacer instead so a focused button's ring is never painted over —
/// visually identical at the junction.
class CarbonButtonSet extends StatelessWidget {
  /// Creates a button set.
  const CarbonButtonSet({
    super.key,
    required this.children,
    this.stacked = false,
  });

  /// The buttons, in Carbon order (secondary first, primary last).
  final List<CarbonButton> children;

  /// Lay buttons out vertically (the upstream `stacked` modifier).
  final bool stacked;

  /// Maximum width of each button inside a set, per spec ("196px from
  /// design kit").
  static const double maxButtonWidth = 196;

  Color _separatorColor(CarbonThemeData theme, CarbonButton next) {
    if (next.onPressed != null) {
      return theme.buttonSeparator;
    }
    return stacked ? theme.layerSelectedDisabled : theme.iconOnColorDisabled;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);

    if (stacked) {
      final List<Widget> laidOut = <Widget>[];
      for (int i = 0; i < children.length; i++) {
        if (i > 0) {
          laidOut.add(
            SizedBox(
              height: 1,
              child: ColoredBox(color: _separatorColor(theme, children[i])),
            ),
          );
        }
        laidOut.add(SizedBox(width: maxButtonWidth, child: children[i]));
      }
      return Column(mainAxisSize: MainAxisSize.min, children: laidOut);
    }

    // Like the upstream flex container (`inline-size: 100%` capped at
    // 196px), buttons share the available width equally up to the cap; the
    // set therefore needs bounded width (e.g. a modal footer).
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double separators = (children.length - 1).toDouble();
        final double share =
            (constraints.maxWidth - separators) / children.length;
        final double width = share < maxButtonWidth ? share : maxButtonWidth;
        final List<Widget> laidOut = <Widget>[];
        for (int i = 0; i < children.length; i++) {
          if (i > 0) {
            laidOut.add(
              SizedBox(
                width: 1,
                child: ColoredBox(color: _separatorColor(theme, children[i])),
              ),
            );
          }
          laidOut.add(SizedBox(width: width, child: children[i]));
        }
        return IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: laidOut,
          ),
        );
      },
    );
  }
}
