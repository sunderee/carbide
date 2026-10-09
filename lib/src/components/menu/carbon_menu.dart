// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/menu/_menu.scss
//   react/src/components/Menu/{Menu,MenuItem}
//
// The composable action-menu primitive behind OverflowMenu, MenuButton and
// ComboButton. CarbonMenu is the floating surface + keyboard roving; consumers
// position it (typically inside a CarbonPopover) and open/close it.

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
import '../../utils/anchored_overlay.dart';
import '../../utils/scroll_into_view.dart';
import '../../utils/menu_shadow.dart';
import '../../utils/typeahead.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';

/// The item height of a [CarbonMenu] (`_menu.scss` supported sizes).
enum CarbonMenuSize {
  /// 24px rows.
  xs(24),

  /// 32px rows — the default.
  sm(32),

  /// 40px rows.
  md(40),

  /// 48px rows.
  lg(48);

  const CarbonMenuSize(this.height);

  /// The row height in logical pixels.
  final double height;
}

/// Registers the focusable rows of a [CarbonMenu] in visual order so the menu
/// can rove focus across them with the arrow keys, Home/End and type-ahead.
class _MenuRegistry {
  final List<({FocusNode node, String label})> _entries =
      <({FocusNode node, String label})>[];

  List<({FocusNode node, String label})> get entries => _entries
      .where((entry) => entry.node.canRequestFocus && !entry.node.skipTraversal)
      .toList(growable: false);

  void register(FocusNode node, String label) =>
      _entries.add((node: node, label: label));

  void unregister(FocusNode node) => _entries.removeWhere(
    (({FocusNode node, String label}) e) => e.node == node,
  );

  void updateLabel(FocusNode node, String label) {
    final int index = _entries.indexWhere((entry) => entry.node == node);
    if (index >= 0) _entries[index] = (node: node, label: label);
  }
}

/// Inherited menu context shared with descendant items.
class _MenuScope extends InheritedWidget {
  const _MenuScope({
    required this.size,
    required this.reserveLeading,
    required this.registry,
    required this.onClose,
    required super.child,
  });

  final CarbonMenuSize size;
  final bool reserveLeading;
  final _MenuRegistry registry;
  final VoidCallback? onClose;

  static _MenuScope of(BuildContext context) {
    final _MenuScope? scope = context
        .dependOnInheritedWidgetOfExactType<_MenuScope>();
    assert(scope != null, 'Menu items must be placed inside a CarbonMenu.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_MenuScope old) =>
      size != old.size || reserveLeading != old.reserveLeading;
}

/// A floating action menu: a shadowed surface of [children] rows that the user
/// roves with the keyboard.
///
/// CarbonMenu owns no position of its own — a consumer renders it inside an
/// overlay (for example a [CarbonPopover]) anchored to its trigger, and calls
/// [onClose] in response to selection or dismissal.
///
/// The menu opens and closes instantly (Carbon defines no open transition);
/// row hover tints ease at `fast-01`, applied instantly under reduced motion
/// (`MediaQueryData.disableAnimations`).
///
/// ```dart
/// CarbonMenu(
///   onClose: () => setState(() => _open = false),
///   children: <Widget>[
///     CarbonMenuItem(label: 'Cut', onPressed: _cut),
///     CarbonMenuItem(label: 'Copy', onPressed: _copy),
///     const CarbonMenuItemDivider(),
///     CarbonMenuItem(label: 'Delete', kind: CarbonMenuItemKind.danger,
///         onPressed: _delete),
///   ],
/// )
/// ```
/// **Stable API.** This standalone menu and its exported item widgets are
/// supported composition APIs. See the gallery Menu recipe.
class CarbonMenu extends StatefulWidget {
  /// Creates an action menu.
  const CarbonMenu({
    required this.children,
    this.size = CarbonMenuSize.sm,
    this.border = false,
    this.autofocus = true,
    this.onClose,
    super.key,
  });

  /// The menu rows (items, groups, dividers).
  final List<Widget> children;

  /// The minimum row height; rows grow to accommodate scaled text.
  final CarbonMenuSize size;

  /// Whether to outline the surface with a 1px subtle border.
  final bool border;

  /// Whether to focus the first item when the menu mounts.
  final bool autofocus;

  /// Called when the menu requests dismissal (Escape, or after a selection).
  final VoidCallback? onClose;

  @override
  State<CarbonMenu> createState() => _CarbonMenuState();
}

class _CarbonMenuState extends State<CarbonMenu> {
  final _MenuRegistry _registry = _MenuRegistry();
  final FocusNode _key = FocusNode(skipTraversal: true);

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusFirst();
      });
    }
  }

  void _focusFirst() {
    if (_registry.entries.isEmpty) {
      _key.requestFocus();
    } else {
      _registry.entries.first.node.requestFocus();
    }
  }

  @override
  void didUpdateWidget(CarbonMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A responsive owner may remove the focused row while keeping its menu.
    // Wait for registry updates, then retain keyboard ownership even if the
    // remaining actions are all disabled (Escape must still dismiss).
    if (widget.autofocus && oldWidget.children != widget.children) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusedIndex < 0) _focusFirst();
      });
    }
  }

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  int get _focusedIndex => _registry.entries.indexWhere(
    (({FocusNode node, String label}) e) => e.node.hasFocus,
  );

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose?.call();
      return KeyEventResult.handled;
    }
    final List<({FocusNode node, String label})> items = _registry.entries;
    if (items.isEmpty) return KeyEventResult.ignored;
    final int current = _focusedIndex;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        items[(current + 1) % items.length].node.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        items[(current - 1 + items.length) % items.length].node.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        items.first.node.requestFocus();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        items.last.node.requestFocus();
        return KeyEventResult.handled;
    }

    // Type-ahead: jump to the next item whose label starts with the character.
    final String? character = event.character;
    if (isCarbonTypeaheadCharacter(character)) {
      final String ch = carbonTypeaheadKey(character!);
      for (int offset = 1; offset <= items.length; offset++) {
        final int i = (current + offset) % items.length;
        if (carbonTypeaheadKey(items[i].label).startsWith(ch)) {
          items[i].node.requestFocus();
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool reserveLeading = _reservesLeading(widget.children);
    final Widget rows = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.children,
    );

    return Focus(
      focusNode: _key,
      includeSemantics: false,
      onKeyEvent: _onKey,
      child: _MenuScope(
        size: widget.size,
        reserveLeading: reserveLeading,
        registry: _registry,
        onClose: widget.onClose,
        child: ConstrainedBox(
          // _menu.scss: min 10rem (12rem with icons), max 18rem.
          constraints: BoxConstraints(
            minWidth: reserveLeading ? 192 : 160,
            maxWidth: 288,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: layer.layer,
              boxShadow: <BoxShadow>[carbonMenuShadow(theme.shadow)],
              border: widget.border
                  ? Border.all(color: layer.borderSubtle)
                  : null,
            ),
            child: Padding(
              // padding: $spacing-02 0.
              padding: const EdgeInsets.symmetric(
                vertical: CarbonSpacing.spacing02,
              ),
              child: DefaultTextStyle.merge(
                style: CarbonTypeStyles.bodyCompact01.copyWith(
                  color: theme.textSecondary,
                ),
                child: isCarbonOverlaySurface(context)
                    ? SingleChildScrollView(child: rows)
                    : rows,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Whether any item (recursively) reserves a leading icon/selection column.
bool _reservesLeading(List<Widget> children) {
  for (final Widget child in children) {
    if (child is CarbonMenuItem && child.icon != null) return true;
    if (child is CarbonMenuItemSelectable) return true;
    if (child is CarbonMenuItemRadioGroup) return true;
    if (child is CarbonMenuItemGroup && _reservesLeading(child.children)) {
      return true;
    }
  }
  return false;
}

/// The visual kind of a [CarbonMenuItem].
enum CarbonMenuItemKind {
  /// The default appearance.
  normal,

  /// A destructive action: red fill on hover/focus.
  danger,
}

/// A single selectable row in a [CarbonMenu].
class CarbonMenuItem extends StatefulWidget {
  /// Creates a menu item.
  const CarbonMenuItem({
    required this.label,
    this.icon,
    this.shortcut,
    this.kind = CarbonMenuItemKind.normal,
    this.disabled = false,
    this.submenu,
    this.onPressed,
    super.key,
  });

  /// The item label.
  final String label;

  /// An optional leading icon.
  final CarbonIconData? icon;

  /// An optional trailing shortcut hint (for example `⌘C`).
  final String? shortcut;

  /// The item kind (normal or danger).
  final CarbonMenuItemKind kind;

  /// Whether the item is disabled (not focusable, inert).
  final bool disabled;

  /// An optional submenu opened to the side; renders a trailing chevron.
  final List<Widget>? submenu;

  /// Called when the item is activated; the menu then closes.
  final VoidCallback? onPressed;

  @override
  State<CarbonMenuItem> createState() => _CarbonMenuItemState();
}

class _CarbonMenuItemState extends State<CarbonMenuItem> {
  final FocusNode _node = FocusNode();
  final OverlayPortalController _submenu = OverlayPortalController();
  final LayerLink _link = LayerLink();
  bool _hovered = false;
  bool _focused = false;
  _MenuRegistry? _registry;

  bool get _hasSubmenu => widget.submenu != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _MenuRegistry registry = _MenuScope.of(context).registry;
    if (registry != _registry) {
      _registry?.unregister(_node);
      _registry = registry;
      registry.register(_node, widget.label);
    }
  }

  @override
  void didUpdateWidget(CarbonMenuItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.label != oldWidget.label) {
      _registry?.updateLabel(_node, widget.label);
    }
  }

  @override
  void dispose() {
    _registry?.unregister(_node);
    _node.dispose();
    super.dispose();
  }

  void _activate() {
    if (!mounted || widget.disabled) return;
    if (_hasSubmenu) {
      _submenu.show();
      return;
    }
    _MenuScope.of(context).onClose?.call();
    // Restore the menu origin before invoking the consumer so its focus or
    // navigation request takes precedence over dismissal.
    widget.onPressed?.call();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _activate();
      return KeyEventResult.handled;
    }
    // Submenus open toward the end side, so the expand/collapse arrows
    // follow the ambient direction (Right expands in LTR, Left in RTL).
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey expandKey = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final LogicalKeyboardKey collapseKey = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (_hasSubmenu && event.logicalKey == expandKey && !_submenu.isShowing) {
      _submenu.show();
      return KeyEventResult.handled;
    }
    if (_hasSubmenu && event.logicalKey == collapseKey && _submenu.isShowing) {
      _submenu.hide();
      _node.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final _MenuScope scope = _MenuScope.of(context);
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled;
    final bool danger = widget.kind == CarbonMenuItemKind.danger;
    final bool active = enabled && (_hovered || _focused);

    final Color background = active
        ? (danger ? theme.buttonDangerPrimary : layer.layerHover)
        : const Color(0x00000000);
    final Color foreground = !enabled
        ? theme.textDisabled
        : danger && active
        ? theme.textOnColor
        : active
        ? theme.textPrimary
        : theme.textSecondary;

    final Widget row = _MenuItemRow(
      size: scope.size,
      reserveLeading: scope.reserveLeading,
      leading: widget.icon != null
          ? CarbonIcon(widget.icon!, color: foreground)
          : null,
      label: widget.label,
      foreground: foreground,
      trailing: _hasSubmenu
          // The indicator points toward the submenu side (upstream renders
          // CaretLeft under RTL, MenuItem.tsx).
          ? CarbonIcon(
              Directionality.of(context) == TextDirection.rtl
                  ? CarbonIcons.chevronLeft
                  : CarbonIcons.chevronRight,
              color: foreground,
            )
          : widget.shortcut != null
          ? Text(
              widget.shortcut!,
              style: CarbonTypeStyles.bodyCompact01.copyWith(color: foreground),
            )
          : null,
      background: background,
    );

    final Widget interaction = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _activate : null,
        child: Focus(
          focusNode: _node,
          canRequestFocus: enabled,
          onKeyEvent: _onKey,
          onFocusChange: (bool f) => setState(() => _focused = f),
          child: ScrollIntoView(
            active: _focused && isCarbonOverlaySurface(context),
            child: CarbonFocusRing(visible: _focused, inset: true, child: row),
          ),
        ),
      ),
    );

    final Widget item = CarbonControlSemantics(
      focusNode: _node,
      state: enabled
          ? CarbonControlState.interactive
          : CarbonControlState.disabled,
      button: true,
      label: widget.label,
      readOnlyHint: '',
      onActivate: _activate,
      builder: (_) => ExcludeSemantics(child: interaction),
    );

    if (!_hasSubmenu) return item;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _submenu,
        overlayChildBuilder: (BuildContext context) => CarbonAnchoredOverlay(
          link: _link,
          side: CarbonOverlaySide.end,
          child: Focus(
            skipTraversal: true,
            canRequestFocus: false,
            // The collapse arrow (Left in LTR, Right in RTL) anywhere in
            // the submenu closes it and returns focus to the parent item
            // (the submenu owns focus once open).
            onKeyEvent: (FocusNode node, KeyEvent event) {
              final LogicalKeyboardKey collapseKey =
                  Directionality.of(context) == TextDirection.rtl
                  ? LogicalKeyboardKey.arrowRight
                  : LogicalKeyboardKey.arrowLeft;
              if (event is KeyDownEvent && event.logicalKey == collapseKey) {
                _submenu.hide();
                _node.requestFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TapRegion(
              onTapOutside: (_) => _submenu.hide(),
              child: CarbonMenu(
                size: scope.size,
                onClose: () {
                  _submenu.hide();
                  scope.onClose?.call();
                },
                children: widget.submenu!,
              ),
            ),
          ),
        ),
        child: item,
      ),
    );
  }
}

/// Shared row layout for menu items: optional leading slot, label, trailing.
class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.size,
    required this.reserveLeading,
    required this.leading,
    required this.label,
    required this.foreground,
    required this.trailing,
    required this.background,
  });

  final CarbonMenuSize size;
  final bool reserveLeading;
  final Widget? leading;
  final String label;
  final Color foreground;
  final Widget? trailing;
  final Color background;

  @override
  Widget build(BuildContext context) {
    // `_menu.scss`: background-color $duration-fast-01
    // motion(standard, productive); instant under reduced motion.
    return AnimatedContainer(
      duration: carbonDuration(context, CarbonDuration.fast01),
      curve: CarbonEasing.standardProductive,
      constraints: BoxConstraints(minHeight: size.height),
      decoration: BoxDecoration(color: background),
      padding: const EdgeInsets.symmetric(
        horizontal: CarbonSpacing.spacing05,
        vertical: CarbonSpacing.spacing01,
      ),
      child: Row(
        children: <Widget>[
          if (reserveLeading) ...<Widget>[
            SizedBox.square(dimension: 16, child: leading),
            const SizedBox(width: CarbonSpacing.spacing03),
          ],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CarbonTypeStyles.bodyCompact01.copyWith(color: foreground),
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: CarbonSpacing.spacing03),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// A 1px divider between menu sections (`_menu.scss` MenuItemDivider).
class CarbonMenuItemDivider extends StatelessWidget {
  /// Creates a menu divider.
  const CarbonMenuItemDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return Padding(
      // margin-block: $spacing-02.
      padding: const EdgeInsets.symmetric(vertical: CarbonSpacing.spacing02),
      child: SizedBox(height: 1, child: ColoredBox(color: layer.borderSubtle)),
    );
  }
}

/// A labelled group of menu items.
class CarbonMenuItemGroup extends StatelessWidget {
  /// Creates a menu item group.
  const CarbonMenuItemGroup({
    required this.label,
    required this.children,
    super.key,
  });

  /// The group's accessible label.
  final String label;

  /// The grouped items.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// A toggleable menu item showing a leading checkmark when [selected].
class CarbonMenuItemSelectable extends StatefulWidget {
  /// Creates a selectable menu item.
  const CarbonMenuItemSelectable({
    required this.label,
    required this.selected,
    required this.onChanged,
    this.disabled = false,
    super.key,
  });

  /// The item label.
  final String label;

  /// Whether the item is currently selected.
  final bool selected;

  /// Called with the new value when toggled.
  final ValueChanged<bool>? onChanged;

  /// Whether the item is disabled.
  final bool disabled;

  @override
  State<CarbonMenuItemSelectable> createState() =>
      _CarbonMenuItemSelectableState();
}

class _CarbonMenuItemSelectableState extends State<CarbonMenuItemSelectable> {
  final FocusNode _node = FocusNode();
  bool _hovered = false;
  bool _focused = false;
  _MenuRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _MenuRegistry registry = _MenuScope.of(context).registry;
    if (registry != _registry) {
      _registry?.unregister(_node);
      _registry = registry;
      registry.register(_node, widget.label);
    }
  }

  @override
  void didUpdateWidget(CarbonMenuItemSelectable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.label != oldWidget.label) {
      _registry?.updateLabel(_node, widget.label);
    }
  }

  @override
  void dispose() {
    _registry?.unregister(_node);
    _node.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!mounted || widget.disabled) return;
    widget.onChanged?.call(!widget.selected);
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
    final CarbonMenuSize size = _MenuScope.of(context).size;
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled;
    final bool active = enabled && (_hovered || _focused);
    final Color foreground = !enabled
        ? theme.textDisabled
        : active
        ? theme.textPrimary
        : theme.textSecondary;

    final Widget row = _MenuItemRow(
      size: size,
      reserveLeading: true,
      leading: widget.selected
          ? CarbonIcon(CarbonIcons.checkmark, color: foreground)
          : null,
      label: widget.label,
      foreground: foreground,
      trailing: null,
      background: active ? layer.layerHover : const Color(0x00000000),
    );

    return CarbonControlSemantics(
      focusNode: _node,
      state: enabled
          ? CarbonControlState.interactive
          : CarbonControlState.disabled,
      inMutuallyExclusiveGroup: false,
      checked: widget.selected,
      label: widget.label,
      readOnlyHint: '',
      onActivate: _toggle,
      builder: (_) => ExcludeSemantics(
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
              focusNode: _node,
              canRequestFocus: enabled,
              onKeyEvent: _onKey,
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

/// A single-select group of radio menu items.
class CarbonMenuItemRadioGroup<T> extends StatelessWidget {
  /// Creates a radio group of menu items.
  const CarbonMenuItemRadioGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  /// The group's accessible label.
  final String label;

  /// The currently selected value.
  final T? value;

  /// The options as `(value, label)` pairs.
  final List<(T, String)> options;

  /// Called with the chosen value.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final (T v, String l) in options)
            _RadioItem<T>(
              label: l,
              selected: v == value,
              onSelected: () => onChanged?.call(v),
            ),
        ],
      ),
    );
  }
}

class _RadioItem<T> extends StatefulWidget {
  const _RadioItem({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  State<_RadioItem<T>> createState() => _RadioItemState<T>();
}

class _RadioItemState<T> extends State<_RadioItem<T>> {
  final FocusNode _node = FocusNode();
  bool _hovered = false;
  bool _focused = false;
  _MenuRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final _MenuRegistry registry = _MenuScope.of(context).registry;
    if (registry != _registry) {
      _registry?.unregister(_node);
      _registry = registry;
      registry.register(_node, widget.label);
    }
  }

  @override
  void didUpdateWidget(_RadioItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.label != oldWidget.label) {
      _registry?.updateLabel(_node, widget.label);
    }
  }

  @override
  void dispose() {
    _registry?.unregister(_node);
    _node.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _select();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _select() {
    if (mounted) widget.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final CarbonMenuSize size = _MenuScope.of(context).size;
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool active = _hovered || _focused;
    final Color foreground = active ? theme.textPrimary : theme.textSecondary;

    final Widget row = _MenuItemRow(
      size: size,
      reserveLeading: true,
      leading: widget.selected
          ? CarbonIcon(CarbonIcons.checkmark, color: foreground)
          : null,
      label: widget.label,
      foreground: foreground,
      trailing: null,
      background: active ? layer.layerHover : const Color(0x00000000),
    );

    return CarbonControlSemantics(
      focusNode: _node,
      state: CarbonControlState.interactive,
      inMutuallyExclusiveGroup: true,
      checked: widget.selected,
      label: widget.label,
      readOnlyHint: '',
      onActivate: _select,
      builder: (_) => ExcludeSemantics(
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _select,
            child: Focus(
              focusNode: _node,
              onKeyEvent: _onKey,
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
