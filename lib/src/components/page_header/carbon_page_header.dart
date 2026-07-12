// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/page-header/_page-header.scss
//   react/src/components/PageHeader/PageHeader.tsx
//
// A page-level header band: an optional breadcrumb row, a title (with optional
// icon and a trailing page-action area), a subtitle and body, optional tags,
// and an optional tabs row. Background `layer-01`, 1px `border-subtle-01`
// bottom rule. Reuses Breadcrumb (#102) and a Tabs (#99) slot.
//
// API posture (#222): this simpler constructor API is intentional. Upstream's
// composable preview PageHeader (BreadcrumbBar/Content/HeroImage/TabBar) was
// deprecated in @carbon/react at v11.111.0 and moved to @carbon/ibm-products
// (carbon-design-system/carbon#21926), which is outside Carbide's porting
// scope. The SCSS above remains in core and stays our citation. Re-evaluate
// only if a PageHeader re-stabilizes inside Carbon core (checked at each
// knowledge-base bump, per ADR 0002's cadence). The upstream-web behaviors
// not ported — responsive page-action collapse, "+N" tag overflow, the
// truncated-title tooltip, the hero-image slot (callers compose
// CarbonAspectRatio) — are catalogued in the #222 gap table. No
// sticky/condensed collapse-on-scroll exists upstream in core either.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../breadcrumb/carbon_breadcrumb.dart';

/// A page-level header band with a title, optional breadcrumb, description and
/// tabs.
///
/// ```dart
/// CarbonPageHeader(
///   breadcrumbs: <CarbonBreadcrumbItem>[
///     CarbonBreadcrumbItem(label: 'Home', onPressed: _home),
///     CarbonBreadcrumbItem(label: 'Reports', isCurrentPage: true),
///   ],
///   title: 'Quarterly report',
///   subtitle: 'Finance',
///   body: 'A summary of revenue and spend for the quarter.',
///   pageActions: CarbonButton(label: 'Edit', onPressed: _edit),
/// )
/// ```
class CarbonPageHeader extends StatelessWidget {
  /// Creates a page header.
  const CarbonPageHeader({
    required this.title,
    super.key,
    this.icon,
    this.subtitle,
    this.body,
    this.breadcrumbs,
    this.breadcrumbBorder = false,
    this.breadcrumbActions,
    this.pageActions,
    this.tags = const <Widget>[],
    this.tabs,
  });

  /// The page title (`productive-heading-04`).
  final String title;

  /// An optional leading title icon.
  final CarbonIconData? icon;

  /// An optional subtitle above nothing/below the title
  /// (`productive-heading-03`).
  final String? subtitle;

  /// An optional descriptive body (`body-01`).
  final String? body;

  /// The breadcrumb trail; omitted hides the breadcrumb bar.
  final List<CarbonBreadcrumbItem>? breadcrumbs;

  /// Whether the breadcrumb bar shows its 1px bottom rule.
  final bool breadcrumbBorder;

  /// Trailing content of the breadcrumb bar (e.g. icon actions).
  final Widget? breadcrumbActions;

  /// Trailing content of the title row (e.g. a primary button or menu).
  final Widget? pageActions;

  /// Tags rendered after the body.
  final List<Widget> tags;

  /// An optional tabs row (typically a [CarbonTabs]); rendered flush to the
  /// content gutter.
  final Widget? tabs;

  /// The breadcrumb bar height (`block-size: 2.5rem`).
  static const double breadcrumbBarHeight = 40;

  /// The horizontal content gutter.
  static const double gutter = CarbonSpacing.spacing05;

  /// The body/title max width (`max-inline-size: 40rem`).
  static const double maxTextWidth = 640;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Page header',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: layer.layer,
          border: Border(bottom: BorderSide(color: theme.borderSubtle01)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (breadcrumbs != null) _BreadcrumbBar(this),
            _Content(this),
            if (tabs != null)
              Padding(
                // `margin-inline-start: -spacing-05` pulls the tab list to the
                // page gutter; here the content has +gutter padding, so we
                // simply align the tabs to the gutter's start.
                padding: const EdgeInsetsDirectional.only(start: gutter),
                child: tabs,
              ),
          ],
        ),
      ),
    );
  }
}

/// The breadcrumb bar: the trail on the start, optional actions on the end.
class _BreadcrumbBar extends StatelessWidget {
  const _BreadcrumbBar(this.header);

  final CarbonPageHeader header;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Container(
      height: CarbonPageHeader.breadcrumbBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: CarbonPageHeader.gutter),
      decoration: header.breadcrumbBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.borderSubtle01)),
            )
          : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: CarbonBreadcrumb(items: header.breadcrumbs!),
            ),
          ),
          if (header.breadcrumbActions != null) ?header.breadcrumbActions,
        ],
      ),
    );
  }
}

/// The content block: title row (icon + title + page actions), subtitle, body
/// and tags. Vertical padding `spacing-06`.
class _Content extends StatelessWidget {
  const _Content(this.header);

  final CarbonPageHeader header;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool hasFollowing =
        header.subtitle != null ||
        header.body != null ||
        header.tags.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CarbonPageHeader.gutter,
        vertical: CarbonSpacing.spacing06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Title row; `margin-block-end: 1rem` when more content follows.
          Padding(
            padding: EdgeInsets.only(bottom: hasFollowing ? 16 : 0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (header.icon != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: CarbonSpacing.spacing05,
                        top: 4,
                      ),
                      child: CarbonIcon(
                        header.icon!,
                        size: 20,
                        color: theme.iconPrimary,
                      ),
                    ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: CarbonPageHeader.maxTextWidth,
                      ),
                      child: Text(
                        header.title,
                        maxLines: header.pageActions != null ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: CarbonTypeStyles.productiveHeading04.copyWith(
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (header.pageActions != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: CarbonSpacing.spacing05,
                      ),
                      // Actions size to their content: a bare CarbonButton
                      // would expand toward its 320px max under the row's
                      // loose constraints (same guard as the data-table
                      // batch bar).
                      child: IntrinsicWidth(child: header.pageActions),
                    ),
                ],
              ),
            ),
          ),
          if (header.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing03),
              child: Text(
                header.subtitle!,
                style: CarbonTypeStyles.productiveHeading03.copyWith(
                  color: theme.textPrimary,
                ),
              ),
            ),
          if (header.body != null)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CarbonPageHeader.maxTextWidth,
              ),
              child: Text(
                header.body!,
                style: CarbonTypeStyles.body01.copyWith(
                  color: theme.textPrimary,
                ),
              ),
            ),
          if (header.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: CarbonSpacing.spacing05),
              child: Wrap(
                spacing: CarbonSpacing.spacing03,
                runSpacing: CarbonSpacing.spacing03,
                children: header.tags,
              ),
            ),
        ],
      ),
    );
  }
}
