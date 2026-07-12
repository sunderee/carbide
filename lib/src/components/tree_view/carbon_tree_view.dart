// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
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
// The controlled selection API matches upstream's
// `enable-treeview-controllable` flagged shape — Carbide was written
// controlled-first, so the flag's fix was never needed (ADR 0002). #253
// ports the rest of that flagged surface: `multiselect` (Ctrl/Cmd
// activation toggles membership, Ctrl+Shift+Home/End extends, Ctrl/Cmd+A
// selects all) and the active/selected split (`_treeview.scss`
// `--tree-node--active` drives the 4px marker, `--tree-node--selected`
// the layer-selected background).

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
///
/// For multi-selection, control the selected set and the active node
/// separately:
///
/// ```dart
/// CarbonTreeView(
///   label: 'Files',
///   multiselect: true,
///   selectedIds: _selected,
///   activeId: _active,
///   onSelectionChanged: (Set<Object> ids) =>
///       setState(() => _selected = ids),
///   onActivate: (Object id) => setState(() => _active = id),
///   nodes: const <CarbonTreeNode>[/* … */],
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
    this.multiselect = false,
    this.selectedIds,
    this.onSelectionChanged,
    this.activeId,
    this.onActivate,
    this.initiallyExpandedIds = const <Object>{},
  }) : assert(
         selectedId == null || selectedIds == null,
         'Provide selectedId (the single-select shorthand) or selectedIds, '
         'not both.',
       ),
       assert(
         !multiselect || selectedId == null,
         'multiselect selection is controlled through selectedIds; '
         'selectedId is the single-select shorthand.',
       );

  /// The root nodes.
  final List<CarbonTreeNode> nodes;

  /// The accessible label for the tree.
  final String label;

  /// The row size.
  final CarbonTreeSize size;

  /// The selected node id — the single-select shorthand.
  ///
  /// Drives the layer-selected background, and (unless [activeId] is set)
  /// also the 4px active marker, matching how upstream's single-select
  /// tree keeps the two in step on every plain activation. For
  /// multi-selection, or to drive the marker separately, use [selectedIds]
  /// and [activeId] instead.
  final Object? selectedId;

  /// Called with the node id on plain activation (click or Enter/Space
  /// without modifiers).
  final ValueChanged<Object>? onSelect;

  /// Whether more than one node can be selected at a time.
  ///
  /// When true, Ctrl/Cmd-activation toggles a node's membership,
  /// Ctrl+Shift+Home/End extends the selection to the first/last visible
  /// node, and Ctrl/Cmd+A selects every visible enabled node
  /// (react `TreeView.tsx` `handleTreeSelect`/`handleKeyDown`). Control
  /// the selection through [selectedIds] + [onSelectionChanged].
  final bool multiselect;

  /// The selected node ids (controlled).
  ///
  /// Drives the layer-selected background
  /// (`_treeview.scss` `--tree-node--selected`). The 4px marker follows
  /// [activeId] independently (`--tree-node--active`).
  final Set<Object>? selectedIds;

  /// Called with the full new selection whenever it changes: `{id}` on a
  /// plain activation, the toggled set on Ctrl/Cmd-activation, and the
  /// extended set on range or select-all keys.
  final ValueChanged<Set<Object>>? onSelectionChanged;

  /// The active node id (controlled): the node last activated, marked
  /// with the 4px leading bar.
  ///
  /// When null and selection uses the [selectedId] shorthand, the marker
  /// follows the selection — the pre-split behavior.
  final Object? activeId;

  /// Called with the node id when a plain activation makes it active.
  final ValueChanged<Object>? onActivate;

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

  /// The controlled selection, whichever API carries it.
  Set<Object> get _selectedIds =>
      widget.selectedIds ??
      (widget.selectedId != null
          ? <Object>{widget.selectedId!}
          : const <Object>{});

  /// The id carrying the 4px active marker; falls back to the
  /// single-select shorthand so the pre-split rendering is preserved.
  Object? get _activeId =>
      widget.activeId ??
      (widget.selectedIds == null ? widget.selectedId : null);

  /// Plain activation (click or Enter/Space without modifiers): the
  /// selection collapses to the node and it becomes active — upstream's
  /// `handleTreeSelect` else-branch.
  void _select(CarbonTreeNode node) {
    if (node.disabled) {
      return;
    }
    _focusFor(node.id).requestFocus();
    widget.onSelect?.call(node.id);
    widget.onSelectionChanged?.call(<Object>{node.id});
    widget.onActivate?.call(node.id);
  }

  /// Ctrl/Cmd-activation in multiselect: toggles the node's membership
  /// and leaves the active node untouched.
  void _toggleSelection(CarbonTreeNode node) {
    if (node.disabled) {
      return;
    }
    _focusFor(node.id).requestFocus();
    final Set<Object> next = <Object>{..._selectedIds};
    if (!next.add(node.id)) {
      next.remove(node.id);
    }
    widget.onSelectionChanged?.call(next);
  }

  /// Routes an activation by the held modifiers, like upstream's
  /// `handleTreeSelect` reading `event.metaKey || event.ctrlKey`.
  void _activate(CarbonTreeNode node) {
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    final bool toggles =
        widget.multiselect &&
        (keyboard.isControlPressed || keyboard.isMetaPressed);
    toggles ? _toggleSelection(node) : _select(node);
  }

  /// Adds every enabled node between the visible indices [from] and [to]
  /// (inclusive, either direction) to the selection.
  void _extendSelection(int from, int to) {
    final Set<Object> next = <Object>{..._selectedIds};
    final int step = to >= from ? 1 : -1;
    for (int i = from; i != to + step; i += step) {
      final CarbonTreeNode node = _visible[i].node;
      if (!node.disabled) {
        next.add(node.id);
      }
    }
    widget.onSelectionChanged?.call(next);
  }

  /// Adds every visible enabled node to the selection (Ctrl/Cmd+A).
  void _selectAll() {
    final Set<Object> next = <Object>{
      ..._selectedIds,
      for (final _Flat flat in _visible)
        if (!flat.node.disabled) flat.node.id,
    };
    widget.onSelectionChanged?.call(next);
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
    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    // Upstream checks `event.ctrlKey` for the multiselect chords; Cmd is
    // accepted too, matching the Ctrl/Cmd equivalence of activation.
    final bool ctrlLike = keyboard.isControlPressed || keyboard.isMetaPressed;

    if (key == LogicalKeyboardKey.arrowDown) {
      _focusIndex(i + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _focusIndex(i - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      // Ctrl+Shift+Home extends the selection through the first node
      // (react `TreeView.tsx` `handleKeyDown`).
      if (widget.multiselect && ctrlLike && keyboard.isShiftPressed) {
        _extendSelection(i, 0);
      }
      _focusIndex(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      // Ctrl+Shift+End extends the selection through the last node.
      if (widget.multiselect && ctrlLike && keyboard.isShiftPressed) {
        _extendSelection(i, _visible.length - 1);
      }
      _focusIndex(_visible.length - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA && widget.multiselect && ctrlLike) {
      _selectAll();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _activate(node);
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
                selected: _selectedIds.contains(flat.node.id),
                active: flat.node.id == _activeId,
                focusNode: _focusFor(flat.node.id),
                onToggle: () => _toggle(flat.node),
                onSelect: () => _activate(flat.node),
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
    required this.active,
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
  final bool active;
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
            // The 4px interactive marker follows the *active* node
            // (`_treeview.scss` `--tree-node--active`), independent of
            // the selected background (`--tree-node--selected`).
            if (widget.active)
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
