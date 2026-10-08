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
import '../button/carbon_button.dart';

/// A named action in a [CarbonPageHeader]'s responsive action area.
///
/// The first action has priority. A null [onPressed] disables both its button
/// and its overflow-menu row. Keep [id] stable across rebuilds and reordering.
class CarbonPageHeaderAction {
  /// Creates an action that can be shown as a button or a menu row.
  const CarbonPageHeaderAction({
    required this.id,
    required this.label,
    this.onPressed,
    this.kind = CarbonButtonKind.primary,
    this.icon,
  });

  /// The unique, stable identity of this action within the header.
  final Object id;

  /// The complete visible and accessible action name.
  final String label;

  /// The activation callback; null renders a disabled action.
  final VoidCallback? onPressed;

  /// The button treatment; destructive kinds also mark the menu row.
  final CarbonButtonKind kind;

  /// An optional button and menu-row icon.
  final CarbonIconData? icon;
}

/// A page-level header band with a title, optional breadcrumb, description and
/// tabs.
///
/// The title is a heading at [headingLevel] (level one by default); subtitle
/// and body remain supporting prose. There is no generic container
/// announcement, so the caller's title supplies the page's own language.
/// Heading level does not change the productive-heading-04 visual style.
///
/// Ports the layered band, optional breadcrumbs/icon/actions, title and
/// description, wrapping tags and a tabs slot. Responsive action collapse,
/// tag `+N` disclosure, a truncated-title tooltip and a hero/content slot are
/// separate follow-ups: [actions](https://github.com/sunderee/carbide/issues/395),
/// [tags](https://github.com/sunderee/carbide/issues/396),
/// [tooltip](https://github.com/sunderee/carbide/issues/397), and
/// [hero](https://github.com/sunderee/carbide/issues/398).
/// The former core React preview was deprecated and moved to IBM Products;
/// this constructor intentionally preserves Carbide's composition API.
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
    this.actions,
    this.actionsOverflowLabel = 'More page actions',
    this.tags = const <Widget>[],
    this.tabs,
    this.headingLevel = 1,
  }) : assert(headingLevel >= 1 && headingLevel <= 6),
       assert(pageActions == null || actions == null);

  /// The page title (`productive-heading-04`).
  final String title;

  /// The title's semantic heading level, from one through six.
  ///
  /// Defaults to the page-level heading. Set a deeper level when composing
  /// the header inside an existing document hierarchy; styling stays fixed.
  final int headingLevel;

  /// An optional leading title icon.
  final CarbonIconData? icon;

  /// Supporting prose below the title, styled with productive-heading-03.
  /// It does not introduce a second semantic heading.
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

  /// Structured responsive actions, in priority and logical menu order.
  ///
  /// Mutually exclusive with [pageActions]. Below Carbon's `md` breakpoint,
  /// the title and actions occupy separate rows. Fitting leading actions
  /// stay visible; remaining actions use the existing Carbon overflow menu.
  /// An Overlay host, such as `WidgetsApp`, is required to open that menu.
  final List<CarbonPageHeaderAction>? actions;

  /// The localized accessible name of the hidden-action menu trigger.
  final String actionsOverflowLabel;

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
                      child: Semantics(
                        // Flutter 3.47 creates the native h1–h6 tag once.
                        // Replace just this node when its hierarchy changes.
                        key: ValueKey<int>(header.headingLevel),
                        header: true,
                        headingLevel: header.headingLevel,
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
