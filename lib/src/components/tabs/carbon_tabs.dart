// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/tabs/_tabs.scss
//   react/src/components/Tabs/Tabs.tsx
//
// Tabs: a TabList of Tabs over matching TabPanels, in line (underline) and
// contained (filled) variants, plus the vertical variant (CarbonTabsVertical,
// upstream TabsVertical/TabListVertical — always contained). Roving keyboard
// selection with automatic or manual activation, shared overflow handling and
// logical horizontal scroll controls.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../../utils/native_tab_semantics.dart';
import '../form/carbon_form.dart' show CarbonFieldSize;

int _nextTabsSemanticsId = 0;

void _syncTabAfterFrame(
  String identifier, {
  required bool enabled,
  required bool roving,
  required bool Function() mounted,
}) {
  if (!kIsWeb) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted()) {
      syncNativeTabSemantics(identifier, enabled: enabled, roving: roving);
    }
  });
}

/// Shared scroll metrics, edge state and reveal policy for both tab axes.
class _TabOverflowCoordinator extends ChangeNotifier {
  _TabOverflowCoordinator({required this.onViewportChanged}) {
    controller.addListener(refresh);
  }

  final ScrollController controller = ScrollController();
  final VoidCallback onViewportChanged;
  bool before = false;
  bool after = false;
  bool hasOverflow = false;
  double edgeThreshold = 0;
  double? wholeExtent;
  double? _viewport;
  double? _animationTarget;
  int _animationSerial = 0;
  bool _disposed = false;

  void refresh() {
    if (_disposed || !controller.hasClients) return;
    final ScrollPosition position = controller.position;
    if (!position.hasContentDimensions) return;
    final bool viewportChanged = _viewport != position.viewportDimension;
    _viewport = position.viewportDimension;
    final double contentExtent =
        position.maxScrollExtent + position.viewportDimension;
    final bool overflow =
        contentExtent > (wholeExtent ?? position.viewportDimension) + 0.5;
    final bool start = edgeThreshold == 0
        ? position.pixels > 0.5
        : position.pixels > edgeThreshold;
    final double remaining = position.maxScrollExtent - position.pixels;
    final bool end = edgeThreshold == 0
        ? remaining > 0.5
        : remaining >= edgeThreshold;
    if (viewportChanged) onViewportChanged();
    if (overflow != hasOverflow ||
        start != before ||
        end != after ||
        viewportChanged) {
      hasOverflow = overflow;
      before = start;
      after = end;
      notifyListeners();
    }
  }

  void scrollTo(BuildContext context, double target) {
    if (_disposed || !controller.hasClients) return;
    final double offset = target.clamp(
      controller.position.minScrollExtent,
      controller.position.maxScrollExtent,
    );
    if ((offset - controller.position.pixels).abs() < 0.1) return;
    final Duration duration = carbonDuration(
      context,
      CarbonDuration.moderate01,
    );
    final int serial = ++_animationSerial;
    if (duration == Duration.zero) {
      _animationTarget = null;
      controller.jumpTo(offset);
    } else {
      _animationTarget = offset;
      unawaited(
        controller
            .animateTo(
              offset,
              duration: duration,
              curve: CarbonEasing.standardProductive,
            )
            .then((_) {
              if (!_disposed && serial == _animationSerial) {
                _animationTarget = null;
              }
            }),
      );
    }
  }

  void finishReducedMotion(BuildContext context) {
    if (_animationTarget != null &&
        controller.hasClients &&
        carbonDuration(context, CarbonDuration.moderate01) == Duration.zero) {
      final double target = _animationTarget!;
      _animationTarget = null;
      _animationSerial++;
      controller.jumpTo(
        target.clamp(
          controller.position.minScrollExtent,
          controller.position.maxScrollExtent,
        ),
      );
    }
  }

  void reveal(
    BuildContext owner,
    BuildContext? targetContext, {
    double padding = 0,
    double? preferredOffset,
  }) {
    if (_disposed || !controller.hasClients || targetContext == null) return;
    final RenderObject? object = targetContext.findRenderObject();
    if (object == null || !object.attached) return;
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      object,
    );
    if (viewport == null) return;
    final double start = viewport.getOffsetToReveal(object, 0).offset - padding;
    final double end = viewport.getOffsetToReveal(object, 1).offset + padding;
    final double pixels = controller.position.pixels;
    final double? target = pixels > start
        ? start
        : pixels < end
        ? end
        : null;
    if (target != null) {
      scrollTo(owner, preferredOffset ?? target);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    controller.removeListener(refresh);
    controller.dispose();
    super.dispose();
  }
}

/// The visual style of a [CarbonTabs].
enum CarbonTabVariant {
  /// An underline indicator beneath the selected tab.
  line,

  /// Filled tabs with a top indicator on the selected tab.
  contained,
}

/// Whether moving keyboard focus also selects a tab.
enum CarbonTabActivationMode {
  /// Arrow keys and Home/End focus and select the destination tab.
  automatic,

  /// Navigation changes focus; Enter or Space selects the focused tab.
  manual,
}

/// A single tab in a [CarbonTabs].
class CarbonTab {
  /// Creates a tab.
  const CarbonTab({
    required this.label,
    this.icon,
    this.disabled = false,
    this.dismissable = false,
    this.onDismiss,
  });

  /// The tab label.
  final String label;

  /// An optional leading icon.
  final CarbonIconData? icon;

  /// Whether the tab is disabled.
  final bool disabled;

  /// Whether the tab shows a close control.
  final bool dismissable;

  /// Called when the close control is activated.
  final VoidCallback? onDismiss;
}

/// A tabbed interface: a row of [tabs] with a matching panel each.
///
/// [tabs] must be non-empty, with exactly one entry in [panels] per tab.
/// A supplied [selectedIndex] must be in `[0, tabs.length)`. These contracts
/// are asserted in debug builds. In release builds, selection clamps to the
/// available tab/panel pairs; no pairs render an empty panel. Reconciliation
/// does not call [onChanged], and switching to internal selection keeps the
/// last visible selection.
///
/// Selection is controlled when [selectedIndex] is provided, otherwise managed
/// internally. Left/Right (Home/End) move focus and, under [activation]'s
/// automatic default, select the destination. Manual mode waits for Enter or
/// Space. Overflow controls use logical first/last directions; the selected or
/// focused tab is revealed when it changes and after viewport resizing. When the
/// platform requests reduced motion, tab state transitions complete
/// instantly.
///
/// ```dart
/// CarbonTabs(
///   tabs: const <CarbonTab>[
///     CarbonTab(label: 'Overview'),
///     CarbonTab(label: 'Details'),
///   ],
///   panels: const <Widget>[Text('Overview'), Text('Details')],
/// )
/// ```
class CarbonTabs extends StatefulWidget {
  /// Creates a tabbed interface.
  // List-length validation cannot be evaluated in a const constructor call.
  // ignore: prefer_const_constructors_in_immutables
  CarbonTabs({
    required this.tabs,
    required this.panels,
    super.key,
    this.selectedIndex,
    this.onChanged,
    this.variant = CarbonTabVariant.line,
    this.size = CarbonFieldSize.lg,
    this.activation = CarbonTabActivationMode.automatic,
    this.tabListLabel = 'Tabs',
    this.scrollBackwardLabel = 'Scroll toward first tab',
    this.scrollForwardLabel = 'Scroll toward last tab',
  }) : assert(tabs.isNotEmpty, 'tabs must not be empty'),
       assert(panels.length == tabs.length, 'each tab must have a panel'),
       assert(
         selectedIndex == null ||
             (selectedIndex >= 0 && selectedIndex < tabs.length),
         'selectedIndex must identify a tab',
       );

  /// The tabs.
  final List<CarbonTab> tabs;

  /// The panels, one per tab.
  final List<Widget> panels;

  /// The selected index (controlled); null lets the widget manage it.
  final int? selectedIndex;

  /// Called when the selection changes.
  final ValueChanged<int>? onChanged;

  /// The visual variant.
  final CarbonTabVariant variant;

  /// The tab height.
  final CarbonFieldSize size;

  /// Whether keyboard navigation selects immediately or waits for activation.
  final CarbonTabActivationMode activation;

  /// The localized accessible name of the tab list.
  final String tabListLabel;

  /// The localized name of the control that scrolls toward earlier tabs.
  final String scrollBackwardLabel;

  /// The localized name of the control that scrolls toward later tabs.
  final String scrollForwardLabel;

  @override
  State<CarbonTabs> createState() => _CarbonTabsState();
}

class _CarbonTabsState extends State<CarbonTabs> {
  late int _selected = widget.selectedIndex ?? 0;
  late int _active = _current;
  late List<FocusNode> _nodes = _makeNodes();
  late final _TabOverflowCoordinator _overflow;
  final String _semanticId = 'carbide-tabs-${_nextTabsSemanticsId++}';
  bool _revealPending = true;

  String get _panelId => '$_semanticId-panel';
  int _clampIndex(int index) =>
      _safeTabIndex(index, widget.tabs.length, widget.panels.length);
  int get _current => _clampIndex(widget.selectedIndex ?? _selected);
  int get _activeIndex =>
      _active >= 0 &&
          _active < widget.tabs.length &&
          !widget.tabs[_active].disabled
      ? _active
      : widget.tabs.indexWhere((CarbonTab tab) => !tab.disabled);

  List<FocusNode> _makeNodes() =>
      List<FocusNode>.generate(widget.tabs.length, (int i) {
        final FocusNode node = FocusNode();
        node.addListener(() {
          if (mounted && node.hasPrimaryFocus) {
            setState(() {
              _active = i;
              _revealPending = true;
            });
          }
        });
        return node;
      });

  @override
  void initState() {
    super.initState();
    _overflow = _TabOverflowCoordinator(
      onViewportChanged: () => _revealPending = true,
    )..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overflow.finishReducedMotion(context);
    _revealPending = true;
  }

  @override
  void didUpdateWidget(CarbonTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool focused = _nodes.any((FocusNode node) => node.hasFocus);
    if (widget.tabs.length != _nodes.length) {
      for (final FocusNode node in _nodes) {
        node.dispose();
      }
      _nodes = _makeNodes();
      _active = _clampIndex(_active);
      _revealPending = true;
      if (focused && _activeIndex >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeIndex >= 0) _nodes[_activeIndex].requestFocus();
        });
      }
    }
    _selected = _clampIndex(
      widget.selectedIndex ?? oldWidget.selectedIndex ?? _selected,
    );
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _active = _current;
      _revealPending = true;
      if (focused && _activeIndex >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _activeIndex >= 0) _nodes[_activeIndex].requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    _overflow.removeListener(_refresh);
    _overflow.dispose();
    for (final FocusNode node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _focusIndex(int index) {
    if (index < 0 ||
        index >= widget.tabs.length ||
        widget.tabs[index].disabled) {
      return;
    }
    setState(() {
      _active = index;
      _revealPending = true;
    });
    _nodes[index].requestFocus();
  }

  void _select(int index) {
    if (index < 0 ||
        index >= widget.tabs.length ||
        widget.tabs[index].disabled) {
      return;
    }
    setState(() {
      if (widget.selectedIndex == null) _selected = index;
      _active = index;
      _revealPending = true;
    });
    widget.onChanged?.call(index);
    _nodes[index].requestFocus();
  }

  void _navigate(int index) =>
      widget.activation == CarbonTabActivationMode.manual
      ? _focusIndex(index)
      : _select(index);

  void _move(int delta) {
    final int n = widget.tabs.length;
    int next = _activeIndex;
    for (int i = 0; i < n; i++) {
      next = (next + delta + n) % n;
      if (!widget.tabs[next].disabled) {
        _navigate(next);
        return;
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey next = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final LogicalKeyboardKey previous = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (event.logicalKey == next ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == previous ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _navigate(widget.tabs.indexWhere((CarbonTab tab) => !tab.disabled));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _navigate(widget.tabs.lastIndexWhere((CarbonTab tab) => !tab.disabled));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _select(_activeIndex);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _scheduleLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _overflow.refresh();
      if (_revealPending) {
        _revealPending = false;
        final int index = _activeIndex;
        if (index >= 0 && index < _nodes.length) {
          _overflow.reveal(context, _nodes[index].context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLayout();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Focus(
          canRequestFocus: false,
          includeSemantics: false,
          onFocusChange: (bool focused) {
            if (!focused && mounted && _active != _current) {
              setState(() {
                _active = _current;
                _revealPending = false;
              });
            }
          },
          child: SizedBox(
            height: widget.size.height,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                _overflow.wholeExtent = constraints.maxWidth;
                final bool controls = _overflow.hasOverflow;
                final double available =
                    (constraints.maxWidth - (controls ? 64 : 0)).clamp(
                      64,
                      double.infinity,
                    );
                final bool rtl =
                    Directionality.of(context) == TextDirection.rtl;
                return Stack(
                  children: <Widget>[
                    if (widget.variant == CarbonTabVariant.line)
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _LineFiller(),
                      ),
                    Row(
                      children: <Widget>[
                        if (controls)
                          _TabScrollButton(
                            label: widget.scrollBackwardLabel,
                            icon: rtl
                                ? CarbonIcons.chevronRight
                                : CarbonIcons.chevronLeft,
                            height: widget.size.height,
                            onPressed: _overflow.before
                                ? () => _overflow.scrollTo(
                                    context,
                                    _overflow.controller.position.pixels -
                                        _overflow
                                            .controller
                                            .position
                                            .viewportDimension,
                                  )
                                : null,
                          ),
                        Expanded(
                          key: const ValueKey<String>('carbide-tab-viewport'),
                          child:
                              NotificationListener<ScrollMetricsNotification>(
                                onNotification: (_) {
                                  _scheduleLayout();
                                  return false;
                                },
                                child: ScrollConfiguration(
                                  behavior: ScrollConfiguration.of(context)
                                      .copyWith(scrollbars: false),
                                  child: SingleChildScrollView(
                                    controller: _overflow.controller,
                                    scrollDirection: Axis.horizontal,
                                    child: Semantics(
                                      container: true,
                                      explicitChildNodes: true,
                                      role: widget.tabs.isEmpty
                                          ? SemanticsRole.none
                                          : SemanticsRole.tabBar,
                                      label: widget.tabListLabel,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          for (
                                            int i = 0;
                                            i < widget.tabs.length;
                                            i++
                                          )
                                            _TabButton(
                                              tab: widget.tabs[i],
                                              variant: widget.variant,
                                              size: widget.size,
                                              selected: i == _current,
                                              focusNode: _nodes[i],
                                              roving: i == _activeIndex,
                                              maxWidth: available,
                                              identifier: '$_semanticId-tab-$i',
                                              panelId: widget.panels.isEmpty
                                                  ? ''
                                                  : _panelId,
                                              onKey: _onKey,
                                              onTap: () => _select(i),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ),
                        if (controls)
                          _TabScrollButton(
                            label: widget.scrollForwardLabel,
                            icon: rtl
                                ? CarbonIcons.chevronLeft
                                : CarbonIcons.chevronRight,
                            height: widget.size.height,
                            onPressed: _overflow.after
                                ? () => _overflow.scrollTo(
                                    context,
                                    _overflow.controller.position.pixels +
                                        _overflow
                                            .controller
                                            .position
                                            .viewportDimension,
                                  )
                                : null,
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        if (widget.tabs.isNotEmpty && widget.panels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: CarbonSpacing.spacing05),
            child: Semantics(
              container: true,
              role: SemanticsRole.tabPanel,
              identifier: _panelId,
              child: KeyedSubtree(
                key: ValueKey<int>(_current),
                child: widget.panels[_current],
              ),
            ),
          ),
      ],
    );
  }
}

/// The row height of a [CarbonTabsVertical].
enum CarbonTabsVerticalSize {
  /// 32px; labels clamp to a single line.
  sm(32),

  /// 40px.
  md(40),

  /// 48px.
  lg(48),

  /// 64px — the vertical default (`layout.use(..., $default: 'xl')` and
  /// upstream's `verticalTabHeight`).
  xl(64);

  const CarbonTabsVerticalSize(this.height);

  /// The fixed row height in logical pixels.
  final double height;
}

/// Vertical tabs: a scrollable column of contained tabs beside its panel.
///
/// [tabs] must be non-empty, with exactly one entry in [panels] per tab.
/// A supplied [selectedIndex] must be in `[0, tabs.length)`. These contracts
/// are asserted in debug builds. In release builds, selection clamps to the
/// available tab/panel pairs; no pairs render an empty panel. Reconciliation
/// does not call [onChanged], and switching to internal selection keeps the
/// last visible selection.
///
/// Ports upstream `TabsVertical`/`TabListVertical`, which always render the
/// contained visual style (`--tabs--vertical --tabs--contained`). The tab
/// list takes a quarter of the available width (the upstream grid spans),
/// scrolls when its tabs overflow the available height — with 64px fade
/// gradients marking the overflow — and keeps the selected tab scrolled
/// into view. Up/Down move focus (Home/End jump); [activation] controls whether
/// navigation selects immediately or Enter/Space commits. Labels wrap to
/// two lines (one at [CarbonTabsVerticalSize.sm]).
///
/// Dismissable tabs are not part of the vertical variant upstream and are
/// asserted against. Give the widget a bounded height (or [height]); an
/// unbounded host falls back to the tabs' natural height without scrolling.
class CarbonTabsVertical extends StatefulWidget {
  /// Creates vertical tabs.
  // List-length validation cannot be evaluated in a const constructor call.
  // ignore: prefer_const_constructors_in_immutables
  CarbonTabsVertical({
    required this.tabs,
    required this.panels,
    super.key,
    this.selectedIndex,
    this.onChanged,
    this.size = CarbonTabsVerticalSize.xl,
    this.height,
    this.activation = CarbonTabActivationMode.automatic,
    this.tabListLabel = 'Tabs',
  }) : assert(tabs.isNotEmpty, 'tabs must not be empty'),
       assert(panels.length == tabs.length, 'each tab must have a panel'),
       assert(
         selectedIndex == null ||
             (selectedIndex >= 0 && selectedIndex < tabs.length),
         'selectedIndex must identify a tab',
       );

  /// The tabs. Dismissable tabs are unsupported in the vertical variant.
  final List<CarbonTab> tabs;

  /// The panels, one per tab.
  final List<Widget> panels;

  /// The selected index (controlled); null lets the widget manage it.
  final int? selectedIndex;

  /// Called when the selection changes.
  final ValueChanged<int>? onChanged;

  /// The tab row height; defaults to the 64px vertical default.
  final CarbonTabsVerticalSize size;

  /// An optional fixed height (upstream `TabsVertical.height`). When null,
  /// the widget fills a bounded parent, or falls back to the tabs' natural
  /// height in an unbounded one.
  final double? height;

  /// Whether keyboard navigation selects immediately or waits for activation.
  final CarbonTabActivationMode activation;

  /// The localized accessible name of the tab list.
  final String tabListLabel;

  @override
  State<CarbonTabsVertical> createState() => _CarbonTabsVerticalState();
}

class _CarbonTabsVerticalState extends State<CarbonTabsVertical> {
  late int _selected = widget.selectedIndex ?? 0;
  late List<FocusNode> _nodes = _makeNodes();
  late final _TabOverflowCoordinator _overflow;
  late int _active = _current;
  bool _revealPending = true;
  final String _semanticId = 'carbide-tabs-${_nextTabsSemanticsId++}';
  String get _panelId => '$_semanticId-panel';
  int get _activeIndex =>
      _active >= 0 &&
          _active < widget.tabs.length &&
          !widget.tabs[_active].disabled
      ? _active
      : widget.tabs.indexWhere((CarbonTab tab) => !tab.disabled);

  List<FocusNode> _makeNodes() =>
      List<FocusNode>.generate(widget.tabs.length, (int i) {
        final FocusNode node = FocusNode();
        node.addListener(() {
          if (mounted && node.hasPrimaryFocus) {
            setState(() {
              _active = i;
              _revealPending = true;
            });
          }
        });
        return node;
      });

  int _clampIndex(int index) =>
      _safeTabIndex(index, widget.tabs.length, widget.panels.length);

  int get _current => _clampIndex(widget.selectedIndex ?? _selected);

  @override
  void initState() {
    super.initState();
    _overflow = _TabOverflowCoordinator(
      onViewportChanged: () => _revealPending = true,
    )..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _overflow.finishReducedMotion(context);
    _revealPending = true;
  }

  @override
  void didUpdateWidget(CarbonTabsVertical oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool focused = _nodes.any((FocusNode node) => node.hasFocus);
    if (widget.tabs.length != _nodes.length) {
      for (final FocusNode node in _nodes) {
        node.dispose();
      }
      _nodes = _makeNodes();
    }
    _revealPending = true;
    _selected = _clampIndex(
      widget.selectedIndex ?? oldWidget.selectedIndex ?? _selected,
    );
    if (widget.selectedIndex != oldWidget.selectedIndex ||
        _active >= widget.tabs.length) {
      _active = _current;
    }
    if (focused && _activeIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeIndex >= 0) _nodes[_activeIndex].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _nodes) {
      node.dispose();
    }
    _overflow.removeListener(_refresh);
    _overflow.dispose();
    super.dispose();
  }

  void _revealSelected(int index) {
    if (index < 0 || index >= _nodes.length) return;
    final double height = widget.size.height;
    _overflow.reveal(
      context,
      _nodes[index].context,
      padding: height / 2,
      preferredOffset: (index - 1) * height,
    );
  }

  void _focusIndex(int index) {
    if (index < 0 ||
        index >= widget.tabs.length ||
        widget.tabs[index].disabled) {
      return;
    }
    setState(() {
      _active = index;
      _revealPending = true;
    });
    _nodes[index].requestFocus();
  }

  void _navigate(int index) =>
      widget.activation == CarbonTabActivationMode.manual
      ? _focusIndex(index)
      : _select(index);

  void _select(int index) {
    if (index < 0 ||
        index >= widget.tabs.length ||
        widget.tabs[index].disabled) {
      return;
    }
    _active = index;
    _revealPending = true;
    widget.onChanged?.call(index);
    if (widget.selectedIndex == null) setState(() => _selected = index);
    _nodes[index].requestFocus();
    _revealSelected(index);
  }

  void _move(int delta) {
    final int n = widget.tabs.length;
    int next = _activeIndex;
    for (int i = 0; i < n; i++) {
      next = (next + delta + n) % n;
      if (!widget.tabs[next].disabled) {
        _navigate(next);
        return;
      }
    }
  }

  /// Up/Down/Home/End only — the vertical list does not react to
  /// Left/Right (`getNextIndexVertical` upstream).
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _move(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _move(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _navigate(widget.tabs.indexWhere((CarbonTab t) => !t.disabled));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _navigate(widget.tabs.lastIndexWhere((CarbonTab t) => !t.disabled));
        return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _select(_activeIndex);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      !widget.tabs.any((CarbonTab tab) => tab.dismissable),
      'Dismissable tabs are not supported in the vertical variant.',
    );
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);

    final Widget list = Semantics(
      container: true,
      explicitChildNodes: true,

      child: Stack(
        children: <Widget>[
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
            child: SingleChildScrollView(
              controller: _overflow.controller,
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                role: widget.tabs.isEmpty
                    ? SemanticsRole.none
                    : SemanticsRole.tabBar,
                label: widget.tabListLabel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (int i = 0; i < widget.tabs.length; i++)
                      _VerticalTabButton(
                        tab: widget.tabs[i],
                        size: widget.size,
                        selected: i == _current,
                        roving: i == _activeIndex,
                        identifier: '$_semanticId-tab-$i',
                        panelId: widget.panels.isEmpty ? '' : _panelId,
                        focusNode: _nodes[i],
                        onKey: _onKey,
                        onTap: () => _select(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // 64px fade gradients mark hidden rows past either edge
          // (`--tab--list-gradient_top/_bottom`, block-size $spacing-10).
          if (_overflow.before)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 64,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: <Color>[
                        layer.layer.withValues(alpha: 0),
                        layer.layer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_overflow.after)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 64,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        layer.layer.withValues(alpha: 0),
                        layer.layer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final Widget body = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The tab list spans a quarter of the width (grid-column span 2 of
        // 8 / span 4 of 16 upstream).
        final double listWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth / 4
            : 256;
        final Widget row = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              explicitChildNodes: true,
              container: true,
              child: DecoratedBox(
                // The list surface: contextual layer background with a 1px
                // border-strong rule along the start edge.
                decoration: BoxDecoration(
                  color: layer.layer,
                  border: BorderDirectional(
                    start: BorderSide(color: theme.borderStrong01),
                  ),
                ),
                child: SizedBox(width: listWidth, child: list),
              ),
            ),
            // The panel: contained tab content sits on the layer, hosts its
            // children a layer up (`update_fields_on_layer`), and inherits
            // body text.
            Expanded(
              child: ColoredBox(
                color: layer.layer,
                child: CarbonLayer(
                  child: Padding(
                    padding: const EdgeInsets.all(CarbonSpacing.spacing05),
                    child: DefaultTextStyle.merge(
                      style: CarbonTypeStyles.body01.copyWith(
                        color: theme.textPrimary,
                      ),
                      child: Semantics(
                        container: true,
                        role: SemanticsRole.tabPanel,
                        identifier: _panelId,
                        child: KeyedSubtree(
                          key: ValueKey<int>(_current),
                          child: widget.tabs.isEmpty || widget.panels.isEmpty
                              ? const SizedBox.shrink()
                              : widget.panels[_current],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
        final double? fixed =
            widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : null);
        return SizedBox(
          // In an unbounded host, fall back to the tabs' natural height.
          height: fixed ?? widget.tabs.length * widget.size.height,
          child: row,
        );
      },
    );

    // Recompute the overflow marks once the list has laid out.
    _overflow.edgeThreshold = widget.size.height / 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _overflow.refresh();
      if (_revealPending) {
        _revealPending = false;
        _revealSelected(_activeIndex);
      }
    });
    return body;
  }
}

/// One row of a [CarbonTabsVertical].
class _VerticalTabButton extends StatefulWidget {
  const _VerticalTabButton({
    required this.tab,
    required this.size,
    required this.selected,
    required this.focusNode,
    required this.onKey,
    required this.onTap,
    required this.roving,
    required this.identifier,
    required this.panelId,
  });

  final CarbonTab tab;
  final CarbonTabsVerticalSize size;
  final bool selected;
  final FocusNode focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;
  final VoidCallback onTap;
  final bool roving;
  final String identifier;
  final String panelId;

  @override
  State<_VerticalTabButton> createState() => _VerticalTabButtonState();
}

class _VerticalTabButtonState extends State<_VerticalTabButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    assert(
      !widget.tab.dismissable,
      'Dismissable tabs are not supported in the vertical variant.',
    );
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.tab.disabled;
    final bool hovered = enabled && _hovered && !widget.selected;
    _syncTabAfterFrame(
      widget.identifier,
      enabled: enabled,
      roving: widget.roving,
      mounted: () => mounted,
    );

    final Color text = widget.tab.disabled
        ? theme.textDisabled
        : widget.selected || hovered
        ? theme.textPrimary
        : theme.textSecondary;

    // Rows carry a 3px inset start bar (subtle → strong on hover →
    // interactive when selected), a 1px subtle bottom border, and a 1px
    // subtle end border that the selected row drops (border-inline: none).
    final Color bar = widget.selected
        ? theme.borderInteractive
        : hovered
        ? theme.borderStrong01
        : layer.borderSubtle;
    final Color background = widget.tab.disabled
        ? layer.layer
        : widget.selected
        ? layer.layer
        : hovered
        ? layer.layerHover
        : theme.layer01;

    final BoxDecoration decoration = BoxDecoration(
      color: background,
      border: BorderDirectional(
        bottom: BorderSide(color: layer.borderSubtle),
        end: widget.selected
            ? BorderSide.none
            : BorderSide(color: layer.borderSubtle),
      ),
    );

    final TextStyle labelStyle = widget.selected
        ? CarbonTypeStyles.headingCompact01
        : CarbonTypeStyles.bodyCompact01;

    // This labelled tab owns its actions. The pointer detector and Focus
    // exclude their automatic semantics to keep one actionable node (#268).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.tab,
      identifier: widget.identifier,
      controlsNodes: widget.panelId.isEmpty
          ? const <String>{}
          : <String>{widget.panelId},
      // A non-null focused value makes the native node a Tab stop in Flutter.
      // Inactive tabs still expose their named accessibility focus action.
      focused: enabled && widget.roving ? _focused : null,
      onFocus: enabled ? widget.focusNode.requestFocus : null,
      onTap: enabled ? widget.onTap : null,
      selected: widget.selected,
      enabled: enabled,
      button: true,
      label: widget.tab.label,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? widget.onTap : null,
          child: Focus(
            includeSemantics: false,
            skipTraversal: !widget.roving,
            focusNode: widget.focusNode,
            canRequestFocus: enabled,
            onKeyEvent: widget.onKey,
            onFocusChange: (bool f) => setState(() => _focused = f),
            child: CarbonFocusRing(
              visible: _focused,
              inset: true,
              child: Container(
                height: widget.size.height,
                decoration: decoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(width: 3, child: ColoredBox(color: bar)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: CarbonSpacing.spacing05,
                        ),
                        alignment: AlignmentDirectional.centerStart,
                        child: Row(
                          children: <Widget>[
                            if (widget.tab.icon != null) ...<Widget>[
                              CarbonIcon(widget.tab.icon!, color: text),
                              const SizedBox(width: CarbonSpacing.spacing03),
                            ],
                            Expanded(
                              child: ExcludeSemantics(
                                child: Text(
                                  widget.tab.label,
                                  maxLines:
                                      widget.size == CarbonTabsVerticalSize.sm
                                      ? 1
                                      : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: labelStyle.copyWith(color: text),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The 1px subtle baseline that line tabs sit on, filling the unused width.
/// Scroll controls are outside keyboard traversal; arrows navigate the tabs.
class _TabScrollButton extends StatelessWidget {
  const _TabScrollButton({
    required this.label,
    required this.icon,
    required this.height,
    required this.onPressed,
  });

  final String label;
  final CarbonIconData icon;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    enabled: onPressed != null,
    focusable: false,
    onTap: onPressed,
    child: GestureDetector(
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: SizedBox(
        width: 32,
        height: height,
        child: Center(
          child: CarbonIcon(
            icon,
            size: 16,
            color: onPressed == null
                ? CarbonTheme.of(context).iconDisabled
                : CarbonTheme.of(context).iconPrimary,
          ),
        ),
      ),
    ),
  );
}

class _LineFiller extends StatelessWidget {
  const _LineFiller();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CarbonLayer.of(context).borderSubtle),
        ),
      ),
      child: const SizedBox(height: 1),
    );
  }
}

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.tab,
    required this.variant,
    required this.size,
    required this.selected,
    required this.focusNode,
    required this.onKey,
    required this.onTap,
    required this.roving,
    required this.maxWidth,
    required this.identifier,
    required this.panelId,
  });

  final CarbonTab tab;
  final CarbonTabVariant variant;
  final CarbonFieldSize size;
  final bool selected;
  final FocusNode focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;
  final VoidCallback onTap;
  final bool roving;
  final double maxWidth;
  final String identifier;
  final String panelId;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.tab.disabled;
    final bool line = widget.variant == CarbonTabVariant.line;
    _syncTabAfterFrame(
      widget.identifier,
      enabled: enabled,
      roving: widget.roving,
      mounted: () => mounted,
    );
    final bool active = enabled && (_hovered);

    final Color text = widget.tab.disabled
        ? theme.textDisabled
        : widget.selected || active
        ? theme.textPrimary
        : theme.textSecondary;

    // Line: a bottom underline (1px subtle / hover strong / 2px interactive
    // selected). Contained: a filled cell with a top indicator when selected.
    final BoxDecoration decoration = line
        ? BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.selected
                    ? theme.borderInteractive
                    : active
                    ? theme.borderStrong01
                    : layer.borderSubtle,
                width: widget.selected ? 2 : 1,
              ),
            ),
          )
        : BoxDecoration(
            color: widget.selected
                ? layer.layer
                : active
                ? layer.layerAccentHover
                : layer.layerAccent,
            border: BorderDirectional(
              top: BorderSide(
                color: widget.selected
                    ? theme.borderInteractive
                    : const Color(0x00000000),
                width: 2,
              ),
              end: BorderSide(color: layer.borderSubtle),
            ),
          );

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.tab.icon != null) ...<Widget>[
          CarbonIcon(widget.tab.icon!, color: text),
          const SizedBox(width: CarbonSpacing.spacing03),
        ],
        Flexible(
          child: ExcludeSemantics(
            child: Text(
              widget.tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CarbonTypeStyles.bodyCompact01.copyWith(color: text),
            ),
          ),
        ),
        if (widget.tab.dismissable) ...<Widget>[
          const SizedBox(width: CarbonSpacing.spacing03),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? widget.tab.onDismiss : null,
            child: CarbonIcon(
              CarbonIcons.close,
              size: 16,
              color: text,
              semanticLabel: 'Dismiss ${widget.tab.label}',
            ),
          ),
        ],
      ],
    );

    // This labelled tab owns its actions. The pointer detector and Focus
    // exclude their automatic semantics to keep one actionable node (#268). The dismiss icon's
    // own tap handler still forks, but that node carries its own label.
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.tab,
      identifier: widget.identifier,
      controlsNodes: widget.panelId.isEmpty
          ? const <String>{}
          : <String>{widget.panelId},
      // A non-null focused value makes the native node a Tab stop in Flutter.
      // Inactive tabs still expose their named accessibility focus action.
      focused: enabled && widget.roving ? _focused : null,
      onFocus: enabled ? widget.focusNode.requestFocus : null,
      onTap: enabled ? widget.onTap : null,
      selected: widget.selected,
      enabled: enabled,
      button: true,
      label: widget.tab.label,
      child: MouseRegion(
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? widget.onTap : null,
          child: Focus(
            includeSemantics: false,
            skipTraversal: !widget.roving,
            focusNode: widget.focusNode,
            canRequestFocus: enabled,
            onKeyEvent: widget.onKey,
            onFocusChange: (bool f) => setState(() => _focused = f),
            child: CarbonFocusRing(
              visible: _focused,
              inset: true,
              // State transition per `_tabs.scss` `__nav-item`: color /
              // border-bottom-color / outline $duration-fast-01
              // motion(standard, productive).
              child: AnimatedContainer(
                constraints: BoxConstraints(
                  minWidth: 64,
                  maxWidth: widget.maxWidth,
                ),
                duration: carbonDuration(context, CarbonDuration.fast01),
                curve: CarbonEasing.standardProductive,
                height: widget.size.height,
                padding: const EdgeInsets.symmetric(
                  horizontal: CarbonSpacing.spacing05,
                ),
                decoration: decoration,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Parallel-list safeguards also run without constructor assertions. Keeping
// this shared prevents horizontal and vertical release behavior from drifting.
int _safeTabIndex(int index, int tabCount, int panelCount) {
  final int pairs = tabCount < panelCount ? tabCount : panelCount;
  return pairs == 0 ? 0 : index.clamp(0, pairs - 1);
}
