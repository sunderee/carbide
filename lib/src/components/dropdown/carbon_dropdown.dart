// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/dropdown/_dropdown.scss
//   react/src/components/Dropdown/Dropdown.tsx
//
// Dropdown is a single-select picker built on the ListBox primitive (#91): the
// field trigger + the popup of option rows. The open/close + roving + type-
// ahead orchestration mirrors the M5 Select (the trigger is a focusable tap
// target, never a button, so it keeps the keys the open menu needs).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../form/carbon_form.dart';
import '../list_box/carbon_list_box.dart';

/// Where a [CarbonDropdown] opens its menu relative to the field.
enum CarbonDropdownDirection {
  /// Below the field (the default).
  bottom,

  /// Above the field.
  top,
}

/// A single option in a [CarbonDropdown].
class CarbonDropdownItem<T> {
  /// Creates a dropdown item.
  const CarbonDropdownItem({
    required this.value,
    required this.label,
    this.disabled = false,
  });

  /// The option value.
  final T value;

  /// The visible text.
  final String label;

  /// Whether the option is selectable.
  final bool disabled;
}

/// A Carbon dropdown: a single-select picker on the ListBox chrome.
///
/// Down/Enter/Space opens the menu; arrows move the highlight (skipping
/// disabled items); Enter selects; Escape closes; typing jumps to the next
/// matching label.
///
/// ```dart
/// CarbonDropdown<String>(
///   titleText: 'Contact method',
///   label: 'Choose an option',
///   items: const <CarbonDropdownItem<String>>[
///     CarbonDropdownItem<String>(value: 'email', label: 'Email'),
///     CarbonDropdownItem<String>(value: 'phone', label: 'Phone'),
///   ],
///   selectedItem: _value,
///   onChanged: (String v) => setState(() => _value = v),
/// )
/// ```
class CarbonDropdown<T> extends StatefulWidget {
  /// Creates a dropdown.
  const CarbonDropdown({
    required this.titleText,
    required this.items,
    super.key,
    this.selectedItem,
    this.onChanged,
    this.label,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.direction = CarbonDropdownDirection.bottom,
    this.disabled = false,
    this.readOnly = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.hideLabel = false,
    this.inline = false,
    this.aiLabel,
    this.aiRevert = false,
    this.focusNode,
    this.autofocus = false,
  }) : assert(!(invalid && warn), 'invalid and warn are mutually exclusive');

  /// The field title shown above (or beside, when [inline]) the trigger.
  final String titleText;

  /// The options.
  final List<CarbonDropdownItem<T>> items;

  /// The selected value.
  final T? selectedItem;

  /// Called with the chosen value; null disables selection.
  final ValueChanged<T>? onChanged;

  /// The placeholder shown when nothing is selected.
  final String? label;

  /// Helper text (hidden when invalid/warn).
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

  /// Which way the menu opens.
  final CarbonDropdownDirection direction;

  /// Whether the dropdown is disabled.
  final bool disabled;

  /// Whether the value is read-only (shown, not editable).
  final bool readOnly;

  /// Whether the dropdown is invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Whether the dropdown is in a warning state.
  final bool warn;

  /// The warning message.
  final String? warnText;

  /// Visually hides the title (kept for assistive technology).
  final bool hideLabel;

  /// Places the title beside the field instead of above it.
  final bool inline;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in the
  /// field per upstream's `decorator` prop; adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// An optional external focus node for the trigger.
  final FocusNode? focusNode;

  /// Whether to autofocus the trigger.
  final bool autofocus;

  @override
  State<CarbonDropdown<T>> createState() => _CarbonDropdownState<T>();
}

class _CarbonDropdownState<T> extends State<CarbonDropdown<T>> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  FocusNode? _internalFocus;
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());
  int _highlighted = -1;
  double _triggerWidth = 0;

  bool get _enabled => !widget.disabled && !widget.readOnly;

  CarbonDropdownItem<T>? get _selected {
    for (final CarbonDropdownItem<T> item in widget.items) {
      if (item.value == widget.selectedItem) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _internalFocus?.dispose();
    super.dispose();
  }

  void _toggle() {
    _focus.requestFocus();
    _overlay.isShowing ? _close() : _open();
  }

  void _open() {
    if (widget.onChanged == null || !_enabled) return;
    _highlighted = widget.items.indexWhere(
      (CarbonDropdownItem<T> i) => !i.disabled,
    );
    final CarbonDropdownItem<T>? selected = _selected;
    if (selected != null) _highlighted = widget.items.indexOf(selected);
    _overlay.show();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlay.isShowing) _focus.requestFocus();
    });
  }

  void _close() {
    _overlay.hide();
    setState(() {});
  }

  void _select(CarbonDropdownItem<T> item) {
    if (item.disabled) return;
    widget.onChanged?.call(item.value);
    _close();
    _focus.requestFocus();
  }

  void _moveHighlight(int delta) {
    final List<CarbonDropdownItem<T>> items = widget.items;
    int next = _highlighted;
    for (int i = 0; i < items.length; i++) {
      next = (next + delta + items.length) % items.length;
      if (!items[next].disabled) {
        setState(() => _highlighted = next);
        return;
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null || !_enabled) {
      return KeyEventResult.ignored;
    }
    if (!_overlay.isShowing) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _open();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _moveHighlight(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveHighlight(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        if (_highlighted >= 0 && _highlighted < widget.items.length) {
          _select(widget.items[_highlighted]);
        }
        return KeyEventResult.handled;
    }
    final String? ch = event.character;
    if (ch != null && ch.trim().isNotEmpty) {
      final int start = _highlighted + 1;
      for (int i = 0; i < widget.items.length; i++) {
        final int idx = (start + i) % widget.items.length;
        if (!widget.items[idx].disabled &&
            widget.items[idx].label.toLowerCase().startsWith(
              ch.toLowerCase(),
            )) {
          setState(() => _highlighted = idx);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonDropdownItem<T>? selected = _selected;
    final String display = selected?.label ?? widget.label ?? '';
    final Color textColor = widget.disabled
        ? theme.textDisabled
        : selected == null
        ? theme.textPlaceholder
        : theme.textPrimary;

    final Widget field = CarbonListBox(
      size: widget.size,
      expanded: _overlay.isShowing,
      disabled: widget.disabled,
      invalid: widget.invalid,
      warn: widget.warn,
      focused: _focus.hasFocus,
      aiLabel: widget.aiLabel,
      aiRevert: widget.aiRevert,
      onTap: _enabled ? _toggle : null,
      child: ExcludeSemantics(
        child: Text(
          display,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CarbonTypeStyles.bodyCompact01.copyWith(color: textColor),
        ),
      ),
    );

    final Widget trigger = Semantics(
      button: true,
      enabled: _enabled,
      label: widget.titleText,
      value: selected?.label,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        autofocus: widget.autofocus,
        child: CompositedTransformTarget(
          link: _link,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              _triggerWidth = constraints.maxWidth;
              return OverlayPortal(
                controller: _overlay,
                overlayChildBuilder: _buildMenu,
                child: field,
              );
            },
          ),
        ),
      ),
    );

    final Widget? message = widget.invalid && widget.invalidText != null
        ? CarbonFieldRequirement(widget.invalidText!)
        : widget.warn && widget.warnText != null
        ? CarbonFieldRequirement(
            widget.warnText!,
            status: CarbonFieldStatus.warning,
          )
        : widget.helperText != null
        ? CarbonHelperText(widget.helperText!, disabled: widget.disabled)
        : null;

    final Widget? title = widget.hideLabel
        ? null
        : ExcludeSemantics(
            child: CarbonFormLabel(widget.titleText, disabled: widget.disabled),
          );

    if (widget.inline) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: CarbonSpacing.spacing05,
                top: CarbonSpacing.spacing03,
              ),
              child: title,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[trigger, ?message],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[?title, trigger, ?message],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final List<Widget> rows = <Widget>[
      for (int i = 0; i < widget.items.length; i++)
        _menuRow(widget.items[i], i, theme),
    ];

    final bool below = widget.direction == CarbonDropdownDirection.bottom;
    return Positioned.directional(
      textDirection: Directionality.of(context),
      width: _triggerWidth,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: below ? Alignment.bottomLeft : Alignment.topLeft,
        followerAnchor: below ? Alignment.topLeft : Alignment.bottomLeft,
        showWhenUnlinked: false,
        child: TapRegion(
          onTapOutside: (_) => _close(),
          // Non-focusable so the trigger keeps keyboard focus (and its key
          // handler) while the menu is open; rows stay tappable.
          child: ExcludeFocus(
            child: CarbonListBoxMenu(size: widget.size, children: rows),
          ),
        ),
      ),
    );
  }

  Widget _menuRow(
    CarbonDropdownItem<T> item,
    int index,
    CarbonThemeData theme,
  ) {
    final bool selected = item.value == widget.selectedItem;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !item.disabled,
      label: item.label,
      child: ExcludeSemantics(
        child: CarbonListBoxMenuItem(
          size: widget.size,
          isFirst: index == 0,
          isActive: selected,
          isHighlighted: index == _highlighted,
          disabled: item.disabled,
          onTap: () => _select(item),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                CarbonIcon(CarbonIcons.checkmark, color: theme.iconPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
