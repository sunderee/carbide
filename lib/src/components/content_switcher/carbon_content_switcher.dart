// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/content-switcher/_content-switcher.scss
//   react/src/components/{ContentSwitcher,Switch}
//
// ContentSwitcher: a horizontal segmented single-select. (Carbon's Switch here
// is the segment, not the M5 Toggle.)

import 'dart:math' as math;

import 'package:flutter/services.dart';
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
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../form/carbon_form.dart' show CarbonFieldSize;

/// A single segment of a [CarbonContentSwitcher].
class CarbonSwitch {
  /// Creates a content-switcher segment.
  const CarbonSwitch({
    this.text,
    this.icon,
    this.semanticLabel,
    this.disabled = false,
  }) : assert(text != null || icon != null, 'a switch needs text or an icon'),
       assert(
         text != null || semanticLabel != null,
         'an icon-only switch needs a semanticLabel',
       );

  /// The segment label.
  final String? text;

  /// An optional icon (icon-only when [text] is null).
  final CarbonIconData? icon;

  /// The accessible name, overriding [text] when supplied.
  ///
  /// Required for icon-only segments. The icon remains decorative inside the
  /// named segment, so assistive technology announces the name once.
  final String? semanticLabel;

  /// Whether the segment is disabled.
  final bool disabled;
}

/// A horizontal segmented control that selects one of several [switches].
///
/// When the platform requests reduced motion, the selection transition
/// completes instantly.
///
/// Bounded text segments share the available width equally. When that would
/// leave less than one glyph plus an ellipsis, the group scrolls horizontally
/// with equal minimum widths, retaining scaled labels and complete names.
/// Keyboard and accessibility focus reveal the selected segment. Icon-only
/// and unbounded compositions retain their intrinsic sizing.
///
/// ```dart
/// CarbonContentSwitcher(
///   switches: const <CarbonSwitch>[
///     CarbonSwitch(text: 'All'),
///     CarbonSwitch(text: 'Archived'),
///   ],
///   selectedIndex: _index,
///   onChanged: (int i) => setState(() => _index = i),
/// )
/// ```
class CarbonContentSwitcher extends StatefulWidget {
  /// Creates a content switcher.
  const CarbonContentSwitcher({
    required this.switches,
    super.key,
    this.selectedIndex,
    this.onChanged,
    this.size = CarbonFieldSize.md,
  });

  /// The segments.
  final List<CarbonSwitch> switches;

  /// The selected index (controlled); null lets the widget manage it.
  final int? selectedIndex;

  /// Called when the selection changes.
  final ValueChanged<int>? onChanged;

  /// The minimum control height at the default text scale.
  ///
  /// Text-bearing groups grow by the extra scaled line height, preserving
  /// their density padding. Icon-only groups keep this height.
  final CarbonFieldSize size;

  @override
  State<CarbonContentSwitcher> createState() => _CarbonContentSwitcherState();
}

class _CarbonContentSwitcherState extends State<CarbonContentSwitcher> {
  late int _selected = widget.selectedIndex ?? 0;
  late List<FocusNode> _nodes = _makeNodes();

  List<FocusNode> _makeNodes() =>
      List<FocusNode>.generate(widget.switches.length, (_) => FocusNode());

  int get _current => widget.selectedIndex ?? _selected;

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_fontsChanged);
  }

  void _fontsChanged() {
    if (mounted) setState(() {});
  }

  double _textWidth(String text, TextScaler scaler) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: CarbonTypeStyles.bodyCompact01),
      textScaler: scaler,
      textDirection: Directionality.of(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  void didUpdateWidget(CarbonContentSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.switches.length != oldWidget.switches.length) {
      for (final FocusNode node in _nodes) {
        node.dispose();
      }
      _nodes = _makeNodes();
      if (_selected >= widget.switches.length) _selected = 0;
    }
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_fontsChanged);
    for (final FocusNode node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    if (index < 0 ||
        index >= widget.switches.length ||
        widget.switches[index].disabled) {
      return;
    }
    widget.onChanged?.call(index);
    if (widget.selectedIndex == null) setState(() => _selected = index);
    _nodes[index].requestFocus();
  }

  void _move(int delta) {
    final int n = widget.switches.length;
    int next = _current;
    for (int i = 0; i < n; i++) {
      next = (next + delta + n) % n;
      if (!widget.switches[next].disabled) {
        _select(next);
        return;
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // Horizontal arrows follow the visual direction (mirrored under RTL,
    // like slider and menu); vertical arrows stay logical.
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey nextKey = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final LogicalKeyboardKey previousKey = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (event.logicalKey == nextKey ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == previousKey ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.home:
        _select(widget.switches.indexWhere((CarbonSwitch s) => !s.disabled));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _select(
          widget.switches.lastIndexWhere((CarbonSwitch s) => !s.disabled),
        );
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool hasText = widget.switches.any((segment) => segment.text != null);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double glyphSpace = math.max(
      scaler.scale(32),
      _textWidth('M…', scaler),
    );
    final bool textWithIcon = widget.switches.any(
      (segment) => segment.text != null && segment.icon != null,
    );
    final double minimumWidth = 32 + glyphSpace + (textWithIcon ? 24 : 0) + 1;
    final double height =
        widget.size.height +
        (hasText
            ? math.max(0, scaler.scale(14) - 14) *
                  CarbonTypeStyles.bodyCompact01.height!
            : 0);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          // The group outline (_content-switcher.scss: 1px border-inverse,
          // 4px radius).
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.borderInverse),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool expand = constraints.hasBoundedWidth && hasText;
                final List<Widget> segments = <Widget>[
                  for (int i = 0; i < widget.switches.length; i++)
                    _SwitchSegment(
                      data: widget.switches[i],
                      size: widget.size,
                      selected: i == _current,
                      isFirst: i == 0,
                      focusNode: _nodes[i],
                      onKey: _onKey,
                      onTap: () => _select(i),
                    ),
                ];
                if (expand) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(
                        constraints.maxWidth,
                        minimumWidth * segments.length,
                      ),
                      child: Row(
                        children: <Widget>[
                          for (final Widget segment in segments)
                            Expanded(child: segment),
                        ],
                      ),
                    ),
                  );
                }
                return Row(mainAxisSize: MainAxisSize.min, children: segments);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchSegment extends StatefulWidget {
  const _SwitchSegment({
    required this.data,
    required this.size,
    required this.selected,
    required this.isFirst,
    required this.focusNode,
    required this.onKey,
    required this.onTap,
  });

  final CarbonSwitch data;
  final CarbonFieldSize size;
  final bool selected;
  final bool isFirst;
  final FocusNode focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;
  final VoidCallback onTap;

  @override
  State<_SwitchSegment> createState() => _SwitchSegmentState();
}

class _SwitchSegmentState extends State<_SwitchSegment> {
  bool _hovered = false;
  bool _focused = false;

  @override
  void didUpdateWidget(_SwitchSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode.hasPrimaryFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.focusNode.hasPrimaryFocus) {
          Scrollable.ensureVisible(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.data.disabled;
    final bool hover = enabled && _hovered && !widget.selected;

    final Color foreground = widget.data.disabled
        ? theme.textDisabled
        : widget.selected
        ? theme.textInverse
        : hover
        ? theme.textPrimary
        : theme.textSecondary;
    final Color background = widget.selected
        ? theme.layerSelectedInverse
        : hover
        ? layer.layerHover
        : const Color(0x00000000);

    final Widget label = widget.data.icon != null && widget.data.text == null
        ? CarbonIcon(widget.data.icon!, color: foreground)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.data.icon != null) ...<Widget>[
                CarbonIcon(widget.data.icon!, color: foreground),
                const SizedBox(width: CarbonSpacing.spacing03),
              ],
              Flexible(
                child: Text(
                  widget.data.text!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CarbonTypeStyles.bodyCompact01.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          );

    return CarbonControlSemantics(
      state: enabled
          ? CarbonControlState.interactive
          : CarbonControlState.disabled,
      readOnlyHint: CarbonControlState.defaultReadOnlyHint,
      focusNode: widget.focusNode,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: widget.selected,
      label: (widget.data.semanticLabel ?? widget.data.text)!,
      onActivate: enabled ? widget.onTap : null,
      builder: (FocusNode node) => ExcludeSemantics(
        child: MouseRegion(
          cursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.onTap : null,
            child: Focus(
              focusNode: node,
              includeSemantics: false,
              canRequestFocus: enabled,
              onKeyEvent: widget.onKey,
              onFocusChange: (bool f) {
                setState(() => _focused = f);
                if (f) Scrollable.ensureVisible(context);
              },
              child: CarbonFocusRing(
                visible: _focused,
                inset: true,
                child: Container(
                  // A 1px border-inverse divider between segments.
                  decoration: BoxDecoration(
                    color: background,
                    border: widget.isFirst
                        ? null
                        : BorderDirectional(
                            start: BorderSide(color: theme.borderInverse),
                          ),
                  ),
                  // `_content-switcher.scss` cites no transition tokens;
                  // fast-01 × standard-productive is Carbide's choice for
                  // this micro-interaction.
                  child: AnimatedDefaultTextStyle(
                    duration: carbonDuration(context, CarbonDuration.fast01),
                    curve: CarbonEasing.standardProductive,
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: foreground,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CarbonSpacing.spacing05,
                      ),
                      child: Center(child: label),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
