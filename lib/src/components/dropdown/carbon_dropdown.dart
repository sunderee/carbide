// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
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

import '../../utils/typeahead.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/owned_listenable.dart';
import '../form/carbon_form.dart';
import '../list_box/list_box_semantics.dart';
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
/// Up opens at the last enabled option; Down opens at the first. Enter or Space
/// opens at the enabled selection, falling back to the first enabled option.
/// While open, arrows move the highlight (skipping disabled items), Enter or
/// Space selects, Escape closes, and typing jumps to the next matching label.
/// Keys that do not open, move, select or dismiss continue to ancestor handlers.
/// Disabled and read-only controls do not open on any key.
///
/// Closed-state Up follows the optional
/// [ARIA combobox convention](https://www.w3.org/WAI/ARIA/apg/patterns/combobox/)
/// and matches Carbide's Select. Carbon's React Dropdown currently omits this
/// opening key.
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
///
/// See the [forms pattern](https://github.com/sunderee/carbide/blob/master/docs/patterns/forms.md#disabled-and-read-only-controls)
/// for the shared disabled and read-only contract.
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
    this.readOnlyHint = CarbonControlState.defaultReadOnlyHint,
    this.activeOptionFormatter = carbonListBoxActiveOptionLabel,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.hideLabel = false,
    this.inline = false,
    this.aiLabel,
    this.aiRevert = false,
    this.fluid = false,
    this.condensed = false,
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

  /// The localizable announcement for read-only mode.
  final String readOnlyHint;

  /// Formats the highlighted option and its one-based position for assistive
  /// technology. Defaults to [carbonListBoxActiveOptionLabel].
  ///
  /// Keyboard focus stays on the trigger, including editable filters. The
  /// shared list-box policy updates a hint and polite live region while the
  /// value remains the current text or committed selection.
  final CarbonListBoxActiveOptionFormatter activeOptionFormatter;

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

  /// The fluid treatment (`_fluid-dropdown.scss`): a 64px field with the
  /// title rendered inside above the value, and 64px menu rows.
  final bool fluid;

  /// The condensed fluid variant: the field stays fluid but the menu rows
  /// keep the standard height (`--list-box__wrapper--fluid--condensed`).
  final bool condensed;

  /// A caller-owned focus node, rebound when this property changes.
  ///
  /// Current focus transfers to the replacement when it can request focus.
  /// Removing it creates an internal node. Caller-owned nodes are never disposed
  /// here.
  final FocusNode? focusNode;

  /// Whether to autofocus the trigger.
  final bool autofocus;

  @override
  State<CarbonDropdown<T>> createState() => _CarbonDropdownState<T>();
}

class _CarbonDropdownState<T> extends State<CarbonDropdown<T>> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  CarbonControlState get _controlState => CarbonControlState.resolve(
    hasCallback: widget.onChanged != null,
    disabled: widget.disabled,
    readOnly: widget.readOnly,
  );

  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  late final OwnedFocusNode _focusOwner;
  FocusNode get _focus => _focusOwner.value;
  int _highlighted = -1;
  double _triggerWidth = 0;

  bool get _enabled => _controlState.canActivate;

  CarbonDropdownItem<T>? get _selected {
    for (final CarbonDropdownItem<T> item in widget.items) {
      if (item.value == widget.selectedItem) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _focusOwner = OwnedFocusNode(
      external: widget.focusNode,
      onChanged: _rebuild,
    );
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CarbonDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focusOwner.update(widget.focusNode);
    if (!_controlState.canActivate && _overlay.isShowing) {
      // OverlayPortal cannot hide during the parent's build. Events already
      // use the current policy while the popup is removed after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_controlState.canActivate && _overlay.isShowing) {
          _close();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusOwner.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!mounted || !_controlState.canActivate) return;
    _focus.requestFocus();
    _overlay.isShowing ? _close() : _open();
  }

  void _open({bool fromEnd = false, bool preferSelection = true}) {
    if (!mounted || !_controlState.canActivate) return;
    _highlighted = fromEnd
        ? widget.items.lastIndexWhere((CarbonDropdownItem<T> i) => !i.disabled)
        : widget.items.indexWhere((CarbonDropdownItem<T> i) => !i.disabled);
    final CarbonDropdownItem<T>? selected = _selected;
    if (preferSelection && selected != null && !selected.disabled) {
      _highlighted = widget.items.indexOf(selected);
    }
    _overlay.show();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlay.isShowing) _focus.requestFocus();
    });
  }

  void _close() {
    if (!mounted) return;
    _overlay.hide();
    setState(() {});
  }

  void _select(CarbonDropdownItem<T> item) {
    if (!mounted || !_controlState.canActivate || item.disabled) return;
    widget.onChanged?.call(item.value);
    _close();
    _focus.requestFocus();
  }

  bool _moveHighlight(int delta) {
    final List<CarbonDropdownItem<T>> items = widget.items;
    int next = _highlighted;
    if (next < 0 || next >= items.length) next = delta < 0 ? 0 : -1;
    for (int i = 0; i < items.length; i++) {
      next = (next + delta + items.length) % items.length;
      if (!items[next].disabled) {
        if (next == _highlighted) return false;
        setState(() => _highlighted = next);
        return true;
      }
    }
    return false;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!mounted || event is! KeyDownEvent || !_controlState.canActivate) {
      return KeyEventResult.ignored;
    }
    if (!_overlay.isShowing) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _open(
          fromEnd: event.logicalKey == LogicalKeyboardKey.arrowUp,
          preferSelection:
              event.logicalKey != LogicalKeyboardKey.arrowDown &&
              event.logicalKey != LogicalKeyboardKey.arrowUp,
        );
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        _close();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        return _moveHighlight(1)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        return _moveHighlight(-1)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        if (_highlighted >= 0 &&
            _highlighted < widget.items.length &&
            !widget.items[_highlighted].disabled) {
          _select(widget.items[_highlighted]);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
    }
    final String? character = event.character;
    if (character != null && character.trim().isNotEmpty) {
      final String ch = carbonTypeaheadKey(character);
      final int start = _highlighted + 1;
      for (int i = 0; i < widget.items.length; i++) {
        final int idx = (start + i) % widget.items.length;
        if (!widget.items[idx].disabled &&
            carbonTypeaheadKey(widget.items[idx].label).startsWith(ch)) {
          if (idx == _highlighted) return KeyEventResult.ignored;
          setState(() => _highlighted = idx);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => CarbonListBoxSemantics(
    expanded: _controlState.canActivate && _overlay.isShowing,
    activeIndex: _highlighted,
    focusNode: _focus,
    optionLabels: <String?>[
      for (final item in widget.items) item.disabled ? null : item.label,
    ],
    formatActiveOption: widget.activeOptionFormatter,
    builder: _build,
  );

  Widget _build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonDropdownItem<T>? selected = _selected;
    final String display = selected?.label ?? widget.label ?? '';
    final Color textColor = _controlState.isDisabled
        ? theme.textDisabled
        : selected == null
        ? theme.textPlaceholder
        : theme.textPrimary;

    final Widget field = CarbonListBox(
      includeSemantics: false,
      size: widget.size,
      expanded: _overlay.isShowing,
      disabled: _controlState.isDisabled,
      readOnly: _controlState.isReadOnly,
      invalid: widget.invalid,
      warn: widget.warn,
      focused: _focus.hasFocus,
      aiLabel: widget.aiLabel,
      aiRevert: widget.aiRevert,
      fluid: _fluid,
      fluidLabel: _fluid ? widget.titleText : null,
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

    final Widget trigger = CarbonControlSemantics(
      state: _controlState,
      readOnlyHint: widget.readOnlyHint,
      expanded: _controlState.canActivate && _overlay.isShowing,
      activeOptionHint: CarbonListBoxSemantics.activeHintOf(context),
      focusNode: _focus,
      onActivate: _toggle,
      button: true,
      label: widget.titleText,
      value: selected?.label,
      builder: (FocusNode focusNode) => Focus(
        focusNode: focusNode,
        includeSemantics: false,
        canRequestFocus: _controlState.canFocus,
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
        ? CarbonHelperText(
            widget.helperText!,
            disabled: _controlState.isDisabled,
          )
        : null;

    final Widget? title = widget.hideLabel || _fluid
        ? null
        : ExcludeSemantics(
            child: CarbonFormLabel(
              widget.titleText,
              disabled: _controlState.isDisabled,
            ),
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
            child: CarbonListBoxMenu(
              size: widget.size,
              fluidRows: _fluid && !widget.condensed,
              children: rows,
            ),
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
    return CarbonListBoxOptionSemantics(
      selected: selected,
      disabled: item.disabled,
      active: index == _highlighted,
      onActivate: () => _select(item),
      label: item.label,
      child: ExcludeSemantics(
        child: CarbonListBoxMenuItem(
          size: widget.size,
          fluid: _fluid && !widget.condensed,
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
