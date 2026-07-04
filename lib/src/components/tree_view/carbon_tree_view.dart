// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/treeview/_treeview.scss
//   react/src/components/TreeView/{TreeView,TreeNode}.tsx
//
// A hierarchical tree of expandable nodes with depth indentation, leading
// icons, hover / selected / active / disabled states, and full keyboard
// roving (Up/Down, Left/Right collapse-expand, Home/End, Enter/Space). Reuses
// the chevron + height-reveal pattern from the side nav and accordion.
//
// The controlled selection API (`selectedId` + `onSelect`) matches
// upstream's `enable-treeview-controllable` flagged shape — Carbide was
// written controlled-first, so the flag's fix was never needed (ADR 0002).

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

/// The tree row heights (`min-block-size`).
enum CarbonTreeSize {
  /// 24px rows.
  xs(24),

  /// 32px rows (the default).
  sm(32);

  const CarbonTreeSize(this.height);

  /// The minimum row height in logical pixels.
  final double height;
}

/// One node in a [CarbonTreeView]; parents carry [children].
@immutable
class CarbonTreeNode {
  /// Creates a tree node.
  const CarbonTreeNode({
    required this.id,
    required this.label,
    this.icon,
    this.children = const <CarbonTreeNode>[],
    this.disabled = false,
  });

  /// A stable, unique identifier used for selection and expansion.
  final Object id;

  /// The node text.
  final String label;

  /// An optional leading icon.
  final CarbonIconData? icon;

  /// The child nodes; a non-empty list makes this an expandable parent.
  final List<CarbonTreeNode> children;

  /// Whether the node is disabled (not selectable or focusable).
  final bool disabled;

  /// Whether this node has children.
  bool get isParent => children.isNotEmpty;
}

/// A hierarchical tree view of [CarbonTreeNode]s.
///
/// ```dart
/// CarbonTreeView(
///   label: 'Files',
///   selectedId: _selected,
///   onSelect: (Object id) => setState(() => _selected = id),
///   nodes: const <CarbonTreeNode>[
///     CarbonTreeNode(
///       id: 'src',
///       label: 'src',
///       icon: CarbonIcons.folder,
///       children: <CarbonTreeNode>[
///         CarbonTreeNode(id: 'main', label: 'main.dart'),
///       ],
///     ),
///   ],
/// )
/// ```
class CarbonTreeView extends StatefulWidget {
  /// Creates a tree view.
  const CarbonTreeView({
    required this.nodes,
    required this.label,
    super.key,
    this.size = CarbonTreeSize.sm,
    this.selectedId,
    this.onSelect,
    this.initiallyExpandedIds = const <Object>{},
  });

  /// The root nodes.
  final List<CarbonTreeNode> nodes;

  /// The accessible label for the tree.
  final String label;

  /// The row size.
  final CarbonTreeSize size;

  /// The currently active/selected node id.
  final Object? selectedId;

  /// Called when a node is activated (click or Enter/Space).
  final ValueChanged<Object>? onSelect;

  /// Ids of parents that start expanded.
  final Set<Object> initiallyExpandedIds;

  @override
  State<CarbonTreeView> createState() => _CarbonTreeViewState();
}

/// A flattened, currently-visible node with its depth.
class _Flat {
  const _Flat(this.node, this.depth);
  final CarbonTreeNode node;
  final int depth;
}

class _CarbonTreeViewState extends State<CarbonTreeView> {
  late final Set<Object> _expanded = <Object>{...widget.initiallyExpandedIds};
  final Map<Object, FocusNode> _focusNodes = <Object, FocusNode>{};
  List<_Flat> _visible = <_Flat>[];

  @override
  void dispose() {
    for (final FocusNode node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _focusFor(Object id) =>
      _focusNodes.putIfAbsent(id, () => FocusNode(debugLabel: 'tree-$id'));

  void _flatten(List<CarbonTreeNode> nodes, int depth, List<_Flat> out) {
    for (final CarbonTreeNode node in nodes) {
      out.add(_Flat(node, depth));
      if (node.isParent && _expanded.contains(node.id)) {
        _flatten(node.children, depth + 1, out);
      }
    }
  }

  void _toggle(CarbonTreeNode node) {
    setState(() {
      if (!_expanded.add(node.id)) {
        _expanded.remove(node.id);
      }
    });
  }

  void _select(CarbonTreeNode node) {
    if (node.disabled) {
      return;
    }
    _focusFor(node.id).requestFocus();
    widget.onSelect?.call(node.id);
  }

  int _indexOf(Object id) => _visible.indexWhere((_Flat f) => f.node.id == id);

  void _focusIndex(int index) {
    if (index >= 0 && index < _visible.length) {
      _focusFor(_visible[index].node.id).requestFocus();
    }
  }

  /// The parent id of [id] in the visible list (the nearest preceding node at
  /// a shallower depth).
  Object? _parentOf(Object id) {
    final int i = _indexOf(id);
    if (i <= 0) {
      return null;
    }
    final int depth = _visible[i].depth;
    for (int j = i - 1; j >= 0; j--) {
      if (_visible[j].depth < depth) {
        return _visible[j].node.id;
      }
    }
    return null;
  }

  KeyEventResult _onKey(_Flat flat, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final CarbonTreeNode node = flat.node;
    final int i = _indexOf(node.id);
    final LogicalKeyboardKey key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      _focusIndex(i + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _focusIndex(i - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _focusIndex(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _focusIndex(_visible.length - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _select(node);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (node.isParent && !_expanded.contains(node.id)) {
        _toggle(node);
      } else if (node.isParent) {
        _focusIndex(i + 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      if (node.isParent && _expanded.contains(node.id)) {
        _toggle(node);
      } else {
        final Object? parent = _parentOf(node.id);
        if (parent != null) {
          _focusIndex(_indexOf(parent));
        }
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    _visible = <_Flat>[];
    _flatten(widget.nodes, 0, _visible);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.label,
      child: ColoredBox(
        color: layer.layer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final _Flat flat in _visible)
              _TreeRow(
                key: ValueKey<Object>(flat.node.id),
                flat: flat,
                size: widget.size,
                expanded: _expanded.contains(flat.node.id),
                selected: flat.node.id == widget.selectedId,
                focusNode: _focusFor(flat.node.id),
                onToggle: () => _toggle(flat.node),
                onSelect: () => _select(flat.node),
                onKey: (KeyEvent e) => _onKey(flat, e),
              ),
          ],
        ),
      ),
    );
  }
}

/// A single tree row: indentation, optional chevron and icon, the label, and
/// the hover / selected / active visuals.
class _TreeRow extends StatefulWidget {
  const _TreeRow({
    required this.flat,
    required this.size,
    required this.expanded,
    required this.selected,
    required this.focusNode,
    required this.onToggle,
    required this.onSelect,
    required this.onKey,
    super.key,
  });

  final _Flat flat;
  final CarbonTreeSize size;
  final bool expanded;
  final bool selected;
  final FocusNode focusNode;
  final VoidCallback onToggle;
  final VoidCallback onSelect;
  final KeyEventResult Function(KeyEvent) onKey;

  @override
  State<_TreeRow> createState() => _TreeRowState();
}

class _TreeRowState extends State<_TreeRow> {
  bool _hovered = false;
  bool _focused = false;

  /// The label's left padding in logical pixels, recreating Carbon's
  /// depth-based indentation (`TreeNode` `calcOffset`, in rem):
  ///  - parent with icon: `depth + 1 + depth*0.5`
  ///  - parent, no icon:  `depth + 1`
  ///  - leaf with icon:   `depth + 2 + depth*0.5`
  ///  - leaf, no icon:    `depth + 2.5`
  double get _indent {
    final int depth = widget.flat.depth;
    final bool parent = widget.flat.node.isParent;
    final bool icon = widget.flat.node.icon != null;
    final double rem = parent
        ? (icon ? depth + 1 + depth * 0.5 : depth + 1)
        : (icon ? depth + 2 + depth * 0.5 : depth + 2.5);
    return rem * 16;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonTreeNode node = widget.flat.node;
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool disabled = node.disabled;

    final Color background = disabled
        ? theme.field01
        : widget.selected
        ? (_hovered ? layer.layerSelectedHover : layer.layerSelected)
        : _hovered
        ? layer.layerHover
        : layer.layer;

    final Color text = disabled
        ? theme.textDisabled
        : widget.selected || _hovered
        ? theme.textPrimary
        : theme.textSecondary;

    final Color iconColor = disabled
        ? theme.iconDisabled
        : widget.selected || _hovered
        ? theme.iconPrimary
        : theme.iconSecondary;

    final Widget label = Padding(
      padding: EdgeInsetsDirectional.only(start: _indent, end: 16),
      child: Row(
        children: <Widget>[
          if (node.isParent)
            _Toggle(
              expanded: widget.expanded,
              color: iconColor,
              disabled: disabled,
              onToggle: widget.onToggle,
            ),
          if (node.icon != null) ...<Widget>[
            SizedBox(
              width: node.isParent
                  ? CarbonSpacing.spacing02
                  : CarbonSpacing.spacing03,
            ),
            CarbonIcon(node.icon!, color: iconColor),
          ],
          Flexible(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: Text(
                node.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: CarbonTypeStyles.bodyCompact01.copyWith(color: text),
              ),
            ),
          ),
        ],
      ),
    );

    final Widget row = DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.size.height),
        child: Stack(
          // Center the (shrink-wrapped) label within the row's minHeight; the
          // Stack would otherwise pin it to the top.
          alignment: AlignmentDirectional.centerStart,
          children: <Widget>[
            label,
            // The `active` 4px interactive marker on the leading edge.
            if (widget.selected)
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: SizedBox(
                  width: 4,
                  child: ColoredBox(color: theme.interactive),
                ),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      selected: widget.selected,
      enabled: !disabled,
      label: node.label,
      expanded: node.isParent ? widget.expanded : null,
      onTap: disabled ? null : widget.onSelect,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: disabled ? null : widget.onSelect,
            child: Focus(
              focusNode: widget.focusNode,
              canRequestFocus: !disabled,
              onKeyEvent: (FocusNode _, KeyEvent e) => widget.onKey(e),
              onFocusChange: (bool f) => setState(() => _focused = f),
              child: CarbonFocusRing(
                visible: _focused,
                inset: true,
                child: row,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The expand/collapse chevron for a parent node (24x24, rotates on toggle).
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.expanded,
    required this.color,
    required this.disabled,
    required this.onToggle,
  });

  final bool expanded;
  final Color color;
  final bool disabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Toggling is a separate hit target from selecting the row.
        onTap: disabled ? null : onToggle,
        child: SizedBox.square(
          dimension: 24,
          child: Center(
            child: AnimatedRotation(
              // Collapsed chevron points right (`rotate(-90deg)`).
              turns: expanded ? 0 : -0.25,
              duration: CarbonDuration.fast02,
              curve: CarbonEasing.standardProductive,
              child: CarbonIcon(
                CarbonIcons.chevronDown,
                size: 16,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
