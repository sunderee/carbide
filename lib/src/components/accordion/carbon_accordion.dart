// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/accordion/_accordion.scss
//   react/src/components/Accordion/{Accordion,AccordionItem}.tsx
//
// Accordion: a list of independently collapsible items, each a title row with
// a rotating chevron over an animated-height body.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../form/carbon_form.dart' show CarbonFieldSize;

/// Which side of the title row the chevron sits on.
enum CarbonAccordionAlign {
  /// Chevron at the start (leading) edge.
  start,

  /// Chevron at the end (trailing) edge — the default.
  end,
}

/// Shared accordion configuration for its items.
class _AccordionScope extends InheritedWidget {
  const _AccordionScope({
    required this.size,
    required this.align,
    required super.child,
  });

  final CarbonFieldSize size;
  final CarbonAccordionAlign align;

  static _AccordionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AccordionScope>();

  @override
  bool updateShouldNotify(_AccordionScope old) =>
      size != old.size || align != old.align;
}

/// A list of collapsible [CarbonAccordionItem]s.
///
/// When the platform requests reduced motion, the fold, chevron, and hover
/// transitions complete instantly.
///
/// ```dart
/// CarbonAccordion(
///   children: <Widget>[
///     CarbonAccordionItem(title: 'Section 1', child: Text('Body 1')),
///     CarbonAccordionItem(title: 'Section 2', child: Text('Body 2')),
///   ],
/// )
/// ```
class CarbonAccordion extends StatelessWidget {
  /// Creates an accordion.
  const CarbonAccordion({
    required this.children,
    super.key,
    this.size = CarbonFieldSize.md,
    this.align = CarbonAccordionAlign.end,
  });

  /// The accordion items.
  final List<Widget> children;

  /// The title-row height.
  final CarbonFieldSize size;

  /// Which side the chevron sits on.
  final CarbonAccordionAlign align;

  @override
  Widget build(BuildContext context) {
    return _AccordionScope(
      size: size,
      align: align,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// A single collapsible accordion section.
class CarbonAccordionItem extends StatefulWidget {
  /// Creates an accordion item.
  const CarbonAccordionItem({
    required this.title,
    required this.child,
    super.key,
    this.initiallyOpen = false,
    this.open,
    this.onOpenChanged,
    this.disabled = false,
    this.focusNode,
  });

  /// The title row text.
  final String title;

  /// The collapsible body.
  final Widget child;

  /// The initial open state (uncontrolled).
  final bool initiallyOpen;

  /// The open state (controlled); null lets the item manage it.
  final bool? open;

  /// Called when the open state toggles.
  final ValueChanged<bool>? onOpenChanged;

  /// Whether the item is disabled.
  final bool disabled;

  /// An optional external focus node for the title row.
  final FocusNode? focusNode;

  @override
  State<CarbonAccordionItem> createState() => _CarbonAccordionItemState();
}

class _CarbonAccordionItemState extends State<CarbonAccordionItem> {
  late bool _open = widget.open ?? widget.initiallyOpen;
  bool _hovered = false;
  bool _focused = false;

  bool get _isOpen => widget.open ?? _open;

  void _toggle() {
    if (widget.disabled) return;
    final bool next = !_isOpen;
    widget.onOpenChanged?.call(next);
    if (widget.open == null) setState(() => _open = next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _toggle();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final _AccordionScope? scope = _AccordionScope.maybeOf(context);
    final CarbonFieldSize size = scope?.size ?? CarbonFieldSize.md;
    final bool atStart =
        (scope?.align ?? CarbonAccordionAlign.end) ==
        CarbonAccordionAlign.start;
    final bool enabled = !widget.disabled;
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration fast02 = reducedMotion
        ? Duration.zero
        : CarbonDuration.fast02;

    final Color titleColor = widget.disabled
        ? theme.textDisabled
        : theme.textPrimary;

    // ChevronRight rotates a quarter-turn to point down when open
    // (`_accordion.scss` `__arrow`: all $duration-fast-02
    // motion(standard, productive)).
    final Widget chevron = AnimatedRotation(
      turns: _isOpen ? 0.25 : 0,
      duration: fast02,
      curve: CarbonEasing.standardProductive,
      child: CarbonIcon(
        CarbonIcons.chevronRight,
        color: widget.disabled ? theme.iconDisabled : theme.iconPrimary,
      ),
    );

    final Widget title = Text(
      widget.title,
      style: CarbonTypeStyles.body01.copyWith(color: titleColor),
    );

    // No `onTap` on the Semantics widget: the inner GestureDetector and
    // Focus merge their tap/focus actions into this labelled node instead
    // of forking an unlabelled companion node (#268).
    final Widget header = Semantics(
      button: true,
      enabled: enabled,
      expanded: _isOpen,
      label: widget.title,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _toggle : null,
          child: Focus(
            focusNode: widget.focusNode,
            canRequestFocus: enabled,
            onKeyEvent: _onKey,
            onFocusChange: (bool f) => setState(() => _focused = f),
            child: CarbonFocusRing(
              visible: _focused,
              inset: true,
              // Hover fill per `_accordion.scss` `__heading:hover`:
              // background motion(standard, productive) $duration-fast-02.
              child: AnimatedContainer(
                duration: fast02,
                curve: CarbonEasing.standardProductive,
                constraints: BoxConstraints(minHeight: size.height),
                color: enabled && _hovered
                    ? layer.layerHover
                    : const Color(0x00000000),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: CarbonSpacing.spacing05,
                ),
                child: Row(
                  children: <Widget>[
                    if (atStart) ...<Widget>[
                      chevron,
                      const SizedBox(width: CarbonSpacing.spacing05),
                    ],
                    Expanded(child: ExcludeSemantics(child: title)),
                    if (!atStart) chevron,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Body fold per `_accordion.scss` `__wrapper`: all $duration-fast-02
    // motion(entrance, productive).
    final Widget body = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _isOpen ? 1 : 0),
      duration: fast02,
      curve: CarbonEasing.entranceProductive,
      builder: (BuildContext context, double t, Widget? child) => ClipRect(
        child: Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: t,
          child: Opacity(opacity: t, child: child),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: CarbonSpacing.spacing05,
          end: CarbonSpacing.spacing09,
          top: CarbonSpacing.spacing03,
          bottom: CarbonSpacing.spacing06,
        ),
        child: DefaultTextStyle.merge(
          style: CarbonTypeStyles.body01.copyWith(color: theme.textPrimary),
          child: widget.child,
        ),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        // 1px subtle rule between items.
        border: Border(top: BorderSide(color: layer.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[header, body],
      ),
    );
  }
}
