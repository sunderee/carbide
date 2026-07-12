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
import '../form/carbon_form.dart' show CarbonFieldSize;

/// A single segment of a [CarbonContentSwitcher].
class CarbonSwitch {
  /// Creates a content-switcher segment.
  const CarbonSwitch({this.text, this.icon, this.disabled = false})
    : assert(text != null || icon != null, 'a switch needs text or an icon');

  /// The segment label.
  final String? text;

  /// An optional icon (icon-only when [text] is null).
  final CarbonIconData? icon;

  /// Whether the segment is disabled.
  final bool disabled;
}

/// A horizontal segmented control that selects one of several [switches].
///
/// When the platform requests reduced motion, the selection transition
/// completes instantly.
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

  /// The control height.
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
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: widget.size.height,
        child: DecoratedBox(
          // The group outline (_content-switcher.scss: 1px border-inverse,
          // 4px radius).
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.borderInverse),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
              ],
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
        ? CarbonIcon(
            widget.data.icon!,
            color: foreground,
            semanticLabel: widget.data.text,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.data.icon != null) ...<Widget>[
                CarbonIcon(widget.data.icon!, color: foreground),
                const SizedBox(width: CarbonSpacing.spacing03),
              ],
              Text(
                widget.data.text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CarbonTypeStyles.bodyCompact01.copyWith(
                  color: foreground,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: widget.selected,
      enabled: enabled,
      label: widget.data.text,
      onTap: enabled ? widget.onTap : null,
      child: ExcludeSemantics(
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
              focusNode: widget.focusNode,
              canRequestFocus: enabled,
              onKeyEvent: widget.onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
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
                    duration:
                        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                        ? Duration.zero
                        : CarbonDuration.fast01,
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
