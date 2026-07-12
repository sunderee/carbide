// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec source (Apache-2.0 Carbon Design System; see NOTICE):
//   react/src/components/Heading/index.tsx
//
// Upstream renders semantic h1–h6 elements with no visual style of their
// own (products bring their type choices). Carbide adds a documented
// default mapping onto the v11 fixed heading styles — h1 → heading-06 down
// to h6 → heading-01 — overridable per heading.

import 'package:flutter/widgets.dart';

import '../../foundations/typography.dart';
import '../../theme/carbon_theme.dart';

/// Raises the ambient heading level for its subtree.
///
/// The same inherited-level pattern as `CarbonLayer`, applied to document
/// structure: root content is level 1; each [CarbonSection] increments the
/// level (clamped at 6, like HTML's h6), and [CarbonHeading] renders at the
/// ambient level. An explicit [level] overrides the hierarchy.
///
/// ```dart
/// CarbonHeading('Page title'),          // h1
/// CarbonSection(
///   child: Column(children: [
///     CarbonHeading('Section title'),   // h2
///     CarbonSection(
///       child: CarbonHeading('Sub'),    // h3
///     ),
///   ]),
/// ),
/// ```
class CarbonSection extends StatelessWidget {
  /// Creates a section one heading level below its parent.
  const CarbonSection({super.key, this.level, required this.child})
    : assert(
        level == null || (level >= 1 && level <= 6),
        'heading levels span 1–6',
      );

  /// Overrides the section's heading level instead of incrementing.
  final int? level;

  /// The section content.
  final Widget child;

  /// The ambient heading level at [context]; 1 outside any section.
  static int levelOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_CarbonHeadingScope>()
          ?.level ??
      1;

  @override
  Widget build(BuildContext context) {
    final int next = level ?? (levelOf(context) + 1);
    return _CarbonHeadingScope(level: next > 6 ? 6 : next, child: child);
  }
}

class _CarbonHeadingScope extends InheritedWidget {
  const _CarbonHeadingScope({required this.level, required super.child});

  final int level;

  @override
  bool updateShouldNotify(_CarbonHeadingScope oldWidget) =>
      level != oldWidget.level;
}

/// A heading at the ambient [CarbonSection] level.
///
/// Exposed to assistive technology as a header with its level. The visual
/// style defaults to the Carbide level mapping ([styleForLevel]); pass
/// [style] to override it without changing the semantic level.
class CarbonHeading extends StatelessWidget {
  /// Creates a heading.
  const CarbonHeading(this.text, {super.key, this.style, this.textDirection});

  /// The heading text.
  final String text;

  /// Overrides the visual style; the semantic level is unaffected.
  final TextStyle? style;

  /// Overrides the ambient [Directionality] for this heading, like
  /// upstream `unstable_Text`'s per-element `dir`. Null inherits.
  final TextDirection? textDirection;

  /// Carbide's default level → type-style mapping (h1 largest): heading-06
  /// down to heading-01. Upstream ships unstyled h-elements; this mapping
  /// is Carbide's documented default.
  static TextStyle styleForLevel(int level) => switch (level) {
    1 => CarbonTypeStyles.heading06,
    2 => CarbonTypeStyles.heading05,
    3 => CarbonTypeStyles.heading04,
    4 => CarbonTypeStyles.heading03,
    5 => CarbonTypeStyles.heading02,
    _ => CarbonTypeStyles.heading01,
  };

  @override
  Widget build(BuildContext context) {
    final int level = CarbonSection.levelOf(context);
    return Semantics(
      header: true,
      headingLevel: level,
      child: Text(
        text,
        textDirection: textDirection,
        style: (style ?? styleForLevel(level)).copyWith(
          color: CarbonTheme.of(context).textPrimary,
        ),
      ),
    );
  }
}
