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
// not ported — the hero-image slot (callers compose CarbonAspectRatio) — is
// catalogued in the #222 gap table. No
// sticky/condensed collapse-on-scroll exists upstream in core either.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/native_control_focus.dart';
import '../../utils/overlay_focus_repair.dart';
import '../breadcrumb/carbon_breadcrumb.dart';
import '../button/carbon_button.dart';
import '../menu/carbon_menu.dart';
import '../overflow_menu/carbon_overflow_menu.dart';
import '../popover/carbon_popover.dart';
import '../tag/carbon_tag.dart';
import '../tag/carbon_interactive_tags.dart';
import '../tooltip/carbon_tooltip.dart';

part 'page_header_tags.dart';
part 'page_header_title.dart';

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
/// description, wrapping tags and a tabs slot. Opt into [actions] for measured
/// responsive buttons and an overflow menu; [pageActions] preserves arbitrary
/// caller composition. Opt into [collapseTags] for measured `+N` disclosure.
/// Ellipsized titles reveal their complete text on hover or keyboard focus,
/// while keeping one accessible heading with its complete name. Fitting titles
/// add no focus stop. The [hero](https://github.com/sunderee/carbide/issues/398)
/// slot remains a separate follow-up.
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
///   actions: <CarbonPageHeaderAction>[
///     CarbonPageHeaderAction(id: 'edit', label: 'Edit', onPressed: _edit),
///   ],
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
    this.collapseTags = false,
    this.tagsOverflowLabel,
    this.tagsDisclosureLabel = 'Hidden tags',
    this.tabs,
    this.headingLevel = 1,
    this.titleFocusNode,
  }) : assert(headingLevel >= 1 && headingLevel <= 6),
       assert(pageActions == null || actions == null);

  /// The page title (`productive-heading-04`).
  final String title;

  /// The title's semantic heading level, from one through six.
  ///
  /// Defaults to the page-level heading. Set a deeper level when composing
  /// the header inside an existing document hierarchy; styling stays fixed.
  final int headingLevel;

  /// An optional caller-owned focus node for truncated-title disclosure.
  ///
  /// Fitting titles remain outside focus traversal. The complete title is
  /// always the accessible heading name; focus reveals its visual tooltip
  /// only while the title is ellipsized.
  final FocusNode? titleFocusNode;

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
  /// IDs must be unique; this is checked when built to preserve const
  /// construction. At extremely narrow widths even the first action moves
  /// into overflow. Buttons use Carbon's `md` density and scaled Plex labels.
  final List<CarbonPageHeaderAction>? actions;

  /// The localized accessible name of the hidden-action menu trigger.
  final String actionsOverflowLabel;

  /// Tags rendered after the body.
  final List<Widget> tags;

  /// Whether to keep fitting tags on one row and disclose the rest in a popover.
  ///
  /// Defaults to wrapping all [tags]. Opt-in children must support dry layout
  /// within Carbon's 208px tag maximum. Give stateful/reordered tags stable
  /// keys; their original instances move between the row and disclosure.
  /// Custom viewport or LayoutBuilder children should keep the wrapping mode.
  final bool collapseTags;

  /// The localized hidden-count name; defaults to `N more tags`.
  final String Function(int hiddenCount)? tagsOverflowLabel;

  /// The localized name of the disclosed tag list.
  final String tagsDisclosureLabel;

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
    assert(
      actions == null ||
          actions!
                  .map((CarbonPageHeaderAction action) => action.id)
                  .toSet()
                  .length ==
              actions!.length,
      'PageHeader action IDs must be unique.',
    );
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
            child: header.actions != null && header.actions!.isNotEmpty
                ? _StructuredTitleRow(header)
                : ConstrainedBox(
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
                            child: _PageTitle(
                              header,
                              maxLines: header.pageActions != null ? 1 : 2,
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
              child: header.collapseTags
                  ? _ResponsiveTags(
                      tags: header.tags,
                      overflowLabel: header.tagsOverflowLabel,
                      disclosureLabel: header.tagsDisclosureLabel,
                    )
                  : Wrap(
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

/// The opt-in structured composition follows core's historical md row/column
/// policy. Button widths use the same Plex style, scaler and padding as Button.
class _StructuredTitleRow extends StatefulWidget {
  const _StructuredTitleRow(this.header);

  final CarbonPageHeader header;

  @override
  State<_StructuredTitleRow> createState() => _StructuredTitleRowState();
}

class _StructuredTitleRowState extends State<_StructuredTitleRow> {
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _actionsKey = GlobalKey();
  final GlobalKey _overflowKey = GlobalKey();
  final FocusNode _overflowFocus = FocusNode();
  final Map<Object, FocusNode> _nodes = <Object, FocusNode>{};
  final Map<Object, GlobalKey> _keys = <Object, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  void _fontsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(_StructuredTitleRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Set<Object> ids = widget.header.actions!
        .map((CarbonPageHeaderAction action) => action.id)
        .toSet();
    for (final Object id in _nodes.keys.toList()) {
      if (!ids.contains(id)) {
        _nodes.remove(id)!.dispose();
        _keys.remove(id);
      }
    }
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    for (final FocusNode node in _nodes.values) {
      node.dispose();
    }
    _overflowFocus.dispose();
    super.dispose();
  }

  double _measure(String text, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  double _actionWidth(CarbonPageHeaderAction action) {
    final bool ghost = switch (action.kind) {
      CarbonButtonKind.ghost || CarbonButtonKind.dangerGhost => true,
      _ => false,
    };
    return math.min(
      CarbonButton.maxWidth,
      _measure(action.label, CarbonButton.labelStyle) +
          (ghost ? 32 + (action.icon == null ? 0 : 24) : 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CarbonPageHeader header = widget.header;
    final List<CarbonPageHeaderAction> actions = header.actions!;
    final CarbonThemeData theme = CarbonTheme.of(context);
    final List<double> widths = actions.map(_actionWidth).toList();
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextStyle titleStyle = CarbonTypeStyles.productiveHeading04.copyWith(
      color: theme.textPrimary,
    );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double iconWidth = header.icon == null ? 0 : 36;
        final double titleMinimum = math.min(
          _measure(header.title, titleStyle),
          scaler.scale(240),
        );
        final bool stacked =
            constraints.maxWidth + 2 * CarbonPageHeader.gutter <
                CarbonBreakpoint.md.width ||
            constraints.maxWidth < titleMinimum + iconWidth + 16 + 32;
        final double available = stacked
            ? constraints.maxWidth
            : math.max(0, constraints.maxWidth - titleMinimum - iconWidth - 16);
        final double total = widths.fold(
          0,
          (double sum, double width) => sum + width,
        );
        int visible = actions.length;
        if (total > available) {
          visible = 0;
          double used = 32;
          while (visible < actions.length &&
              used + widths[visible] <= available) {
            used += widths[visible++];
          }
        }
        final List<CarbonPageHeaderAction> hidden = actions
            .skip(visible)
            .toList();
        final Set<Object> visibleIds = actions
            .take(visible)
            .map((CarbonPageHeaderAction action) => action.id)
            .toSet();
        final bool lostFocus = _nodes.entries.any(
          (MapEntry<Object, FocusNode> entry) =>
              entry.value.hasFocus && !visibleIds.contains(entry.key),
        );
        final BuildContext? focusedContext =
            FocusManager.instance.primaryFocus?.context;
        final bool overflowRemoved =
            hidden.isEmpty &&
            (_overflowFocus.hasFocus ||
                (focusedContext != null &&
                    focusedContext
                            .findAncestorWidgetOfExactType<
                              CarbonOverflowMenu
                            >() ==
                        _overflowKey.currentWidget));
        if (lostFocus || overflowRemoved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (hidden.isNotEmpty) {
              _overflowFocus.requestFocus();
            } else {
              for (final CarbonPageHeaderAction action in actions) {
                if (action.onPressed != null) {
                  _nodes[action.id]?.requestFocus();
                  break;
                }
              }
            }
          });
        }
        final Widget title = KeyedSubtree(
          key: _titleKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (header.icon != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16, top: 4),
                    child: CarbonIcon(
                      header.icon!,
                      size: 20,
                      color: theme.iconPrimary,
                    ),
                  ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: CarbonPageHeader.maxTextWidth,
                      ),
                      child: _PageTitle(header, maxLines: stacked ? 2 : 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        final Widget bar = KeyedSubtree(
          key: _actionsKey,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (int i = 0; i < visible; i++)
                SizedBox(
                  width: widths[i],
                  child: CarbonButton(
                    key: _keys.putIfAbsent(actions[i].id, GlobalKey.new),
                    label: actions[i].label,
                    kind: actions[i].kind,
                    icon: actions[i].icon,
                    size: CarbonButtonSize.md,
                    focusNode: _nodes.putIfAbsent(actions[i].id, FocusNode.new),
                    onPressed: actions[i].onPressed,
                  ),
                ),
              if (hidden.isNotEmpty)
                CarbonOverflowMenu(
                  key: _overflowKey,
                  focusNode: _overflowFocus,
                  iconDescription: header.actionsOverflowLabel,
                  items: <Widget>[
                    for (final CarbonPageHeaderAction action in hidden)
                      CarbonMenuItem(
                        key: ValueKey<Object>(action.id),
                        label: action.label,
                        icon: action.icon,
                        disabled: action.onPressed == null,
                        kind: switch (action.kind) {
                          CarbonButtonKind.danger ||
                          CarbonButtonKind.dangerTertiary ||
                          CarbonButtonKind.dangerGhost =>
                            CarbonMenuItemKind.danger,
                          _ => CarbonMenuItemKind.normal,
                        },
                        onPressed: action.onPressed,
                      ),
                  ],
                  triggerBuilder:
                      (BuildContext context, bool open, VoidCallback toggle) =>
                          CarbonButton.iconOnly(
                            icon: CarbonIcons.overflowMenuVertical,
                            iconDescription: header.actionsOverflowLabel,
                            kind: CarbonButtonKind.ghost,
                            size: CarbonButtonSize.sm,
                            focusNode: _overflowFocus,
                            isSelected: open,
                            onPressed: () {
                              _overflowFocus.requestFocus();
                              toggle();
                            },
                          ),
                ),
            ],
          ),
        );
        return stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  title,
                  const SizedBox(height: CarbonSpacing.spacing05),
                  bar,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: title),
                  const SizedBox(width: CarbonSpacing.spacing05),
                  bar,
                ],
              );
      },
    );
  }
}
