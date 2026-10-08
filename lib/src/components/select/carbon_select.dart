// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/select/_select.scss
//   styles/scss/components/fluid-select/_fluid-select.scss
//   react/src/components/{Select,SelectItem,SelectItemGroup}
//
// Carbon's Select is a native <select>; with no Material we build the menu on
// OverlayPortal — a Carbon list-box rather than the platform popup.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/indexed_options.dart';
import '../../utils/anchored_overlay.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/focus_ring.dart';
import '../../utils/typeahead.dart';
import '../../utils/interaction.dart';
import '../../utils/owned_listenable.dart';
import '../../utils/scroll_into_view.dart';
import '../form/carbon_form.dart';
import '../list_box/list_box_semantics.dart';
import '../list_box/lazy_option_menu.dart';

/// An entry in a [CarbonSelect]: either an item or a group of items.
sealed class CarbonSelectEntry<T> {
  const CarbonSelectEntry();
}

/// A single selectable option.
class CarbonSelectItem<T> extends CarbonSelectEntry<T> {
  /// Creates a select item.
  const CarbonSelectItem({
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

/// A labelled group of [CarbonSelectItem]s (`<optgroup>`).
class CarbonSelectItemGroup<T> extends CarbonSelectEntry<T> {
  /// Creates an item group.
  const CarbonSelectItemGroup({required this.label, required this.items});

  /// The group heading.
  final String label;

  /// The grouped items.
  final List<CarbonSelectItem<T>> items;
}

/// A Carbon select (single-choice picker).
///
/// A field with a trailing `ChevronDown` that opens a Carbon list-box. Keyboard
/// support: Up opens at the last enabled option; Down opens at the first.
/// Enter or Space opens at the enabled selection, falling back to the first
/// enabled option. While open, arrows move the highlight (skipping disabled
/// items), Enter or Space selects, Escape closes, and typing jumps to the next
/// matching label. Keys that perform no action continue to ancestor handlers.
/// Disabled and read-only controls do not open on any key. Reuses the
/// [CarbonField] chrome with [inline] and [fluid] layouts.
///
/// See the [forms pattern](https://github.com/sunderee/carbide/blob/master/docs/patterns/forms.md#disabled-and-read-only-controls)
/// for the shared disabled and read-only contract.
class CarbonSelect<T> extends StatefulWidget {
  /// Creates a select.
  const CarbonSelect({
    super.key,
    required this.labelText,
    List<CarbonSelectEntry<T>>? items,
    this.itemBuilder,
    this.itemCount,
    this.value,
    this.onChanged,
    this.placeholder,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.menuSide,
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
    this.fluid = false,
    this.aiLabel,
    this.aiRevert = false,
    this.focusNode,
    this.autofocus = false,
  }) : items = items ?? const [],
       assert(
         itemBuilder == null || items == null,
         'Use either items or itemBuilder.',
       ),
       assert(
         (itemBuilder == null) == (itemCount == null),
         'itemBuilder and itemCount must be supplied together.',
       ),
       assert(
         itemCount == null || itemCount >= 0,
         'itemCount must be non-negative.',
       ),
       assert(!(inline && fluid), 'inline and fluid are mutually exclusive');

  /// The field label.
  final String labelText;

  /// The options (items and/or groups).
  final List<CarbonSelectEntry<T>> items;

  /// Reads an option's data by index for a lazy menu. This callback is also
  /// used for offscreen keyboard search and value reconciliation; keep it pure
  /// and lightweight, and return stable values (fresh model objects are fine).
  /// Supply [itemCount] together with this callback and omit [items].
  final CarbonSelectItem<T> Function(int index)? itemBuilder;

  /// The number of logical options read by [itemBuilder], including disabled
  /// options. Select's builder mode supplies flat items; groups use [items].
  final int? itemCount;

  /// The selected value.
  final T? value;

  /// Called with the chosen value; null disables the select.
  final ValueChanged<T>? onChanged;

  /// Placeholder shown when nothing is selected.
  final String? placeholder;

  /// Helper text (hidden when invalid/warn).
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

  /// Pins the options to a side. Null prefers below and adapts to the viewport.
  /// Logical [CarbonOverlaySide.start] and [CarbonOverlaySide.end] follow RTL.
  final CarbonOverlaySide? menuSide;

  /// Whether disabled.
  final bool disabled;

  /// Keeps the value focusable while preventing editing and popup activation.
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

  /// Whether invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Whether in warning.
  final bool warn;

  /// The warning message.
  final String? warnText;

  /// Visually hides the label.
  final bool hideLabel;

  /// Lays the label beside the field.
  final bool inline;

  /// Uses the fluid treatment (label inside the field).
  final bool fluid;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in the
  /// field per upstream's `decorator` prop; adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// A caller-owned focus node, rebound when this property changes.
  ///
  /// Current focus transfers to the replacement when it can request focus.
  /// Removing it creates an internal node. Caller-owned nodes are never disposed
  /// here.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  State<CarbonSelect<T>> createState() => _CarbonSelectState<T>();
}

class _CarbonSelectState<T> extends State<CarbonSelect<T>> {
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
  List<CarbonSelectEntry<T>> get _items => widget.itemBuilder == null
      ? widget.items
      : CarbonIndexedOptions<CarbonSelectItem<T>>(
          widget.itemCount!,
          widget.itemBuilder!,
        );

  double _triggerWidth = 0;

  List<CarbonSelectItem<T>> get _flatItems => widget.itemBuilder != null
      ? CarbonIndexedOptions<CarbonSelectItem<T>>(
          widget.itemCount!,
          widget.itemBuilder!,
        )
      : <CarbonSelectItem<T>>[
          for (final CarbonSelectEntry<T> entry in _items)
            if (entry is CarbonSelectItem<T>)
              entry
            else if (entry is CarbonSelectItemGroup<T>)
              ...entry.items,
        ];

  CarbonSelectItem<T>? get _selectedItem {
    for (final CarbonSelectItem<T> item in _flatItems) {
      if (item.value == widget.value) {
        return item;
      }
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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(CarbonSelect<T> oldWidget) {
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

  void _open({bool fromEnd = false, bool preferSelection = true}) {
    if (!mounted || !_controlState.canActivate) return;
    final List<CarbonSelectItem<T>> items = _flatItems;
    _highlighted = fromEnd
        ? items.lastIndexWhere((CarbonSelectItem<T> i) => !i.disabled)
        : items.indexWhere((CarbonSelectItem<T> i) => !i.disabled);
    final CarbonSelectItem<T>? selected = _selectedItem;
    if (preferSelection && selected != null && !selected.disabled) {
      _highlighted = items.indexWhere((item) => item.value == selected.value);
    }
    _overlay.show();
    setState(() {});
    // Keep keyboard focus on the trigger after the overlay mounts so its key
    // handler keeps receiving navigation keys.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlay.isShowing) {
        _focus.requestFocus();
      }
    });
  }

  void _toggle() {
    if (!mounted || !_controlState.canActivate) return;
    _focus.requestFocus();
    _overlay.isShowing ? _close() : _open();
  }

  void _close() {
    if (!mounted) return;
    _overlay.hide();
    setState(() {});
  }

  void _select(CarbonSelectItem<T> item) {
    if (!mounted || !_controlState.canActivate || item.disabled) return;
    widget.onChanged?.call(item.value);
    _close();
    _focus.requestFocus();
  }

  bool _moveHighlight(int delta) {
    final List<CarbonSelectItem<T>> items = _flatItems;
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

  /// All keyboard handling lives on the trigger (the menu is non-focusable,
  /// so the trigger keeps focus while open): Up/Down/Enter/Space open; arrows
  /// navigate; Enter/Space select; Escape closes; characters type-ahead.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!mounted || event is! KeyDownEvent || !_controlState.canActivate) {
      return KeyEventResult.ignored;
    }
    if (!_overlay.isShowing) {
      // ArrowUp opens too, per native-<select> parity
      // (pagination/accessibility.mdx: "Space or Up or Down arrows").
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
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return _moveHighlight(1)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return _moveHighlight(-1)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final List<CarbonSelectItem<T>> items = _flatItems;
      if (_highlighted >= 0 &&
          _highlighted < items.length &&
          !items[_highlighted].disabled) {
        _select(items[_highlighted]);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final String? character = event.character;
    if (character != null && character.trim().isNotEmpty) {
      final String ch = carbonTypeaheadKey(character);
      final List<CarbonSelectItem<T>> items = _flatItems;
      final int start = _highlighted + 1;
      for (int i = 0; i < items.length; i++) {
        final int idx = (start + i) % items.length;
        if (!items[idx].disabled &&
            carbonTypeaheadKey(items[idx].label).startsWith(ch)) {
          if (idx == _highlighted) return KeyEventResult.ignored;
          setState(() => _highlighted = idx);
          return KeyEventResult.handled;
        }
      }
    }
    return KeyEventResult.ignored;
  }

  CarbonFieldStatus get _status => widget.invalid
      ? CarbonFieldStatus.invalid
      : widget.warn
      ? CarbonFieldStatus.warning
      : CarbonFieldStatus.none;

  @override
  Widget build(BuildContext context) => CarbonListBoxSemantics(
    expanded: _controlState.canActivate && _overlay.isShowing,
    activeIndex: _highlighted,
    focusNode: _focus,
    optionLabels: widget.itemBuilder != null
        ? CarbonIndexedOptions<String?>(_flatItems.length, (int index) {
            final item = _flatItems[index];
            return item.disabled ? null : item.label;
          })
        : <String?>[
            for (final item in _flatItems) item.disabled ? null : item.label,
          ],
    formatActiveOption: widget.activeOptionFormatter,
    builder: _build,
  );

  Widget _build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonSelectItem<T>? selected = _selectedItem;
    final String display = selected?.label ?? widget.placeholder ?? '';
    final Color textColor = _controlState.isDisabled
        ? theme.textDisabled
        : selected == null
        ? theme.textPlaceholder
        : theme.textPrimary;

    final Widget valueText = Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        display,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CarbonTypeStyles.bodyCompact01.copyWith(color: textColor),
      ),
    );
    final Widget chevron = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: CarbonSpacing.spacing03,
        end: CarbonField.paddingInline,
      ),
      child: CarbonIcon(
        CarbonIcons.chevronDown,
        size: 16,
        color: !_controlState.canActivate
            ? theme.iconDisabled
            : theme.iconPrimary,
      ),
    );

    // The trigger is a plain focusable tap target (not a CarbonInteraction):
    // a button would consume Enter/Space as activation before _onKey could
    // use them to select the highlighted item while the menu is open.
    final bool focused = _focus.hasFocus;
    final Widget fieldChrome = _fluid
        ? _FluidSelectField(
            label: widget.labelText,
            status: _status,
            disabled: _controlState.isDisabled,
            readOnly: _controlState.isReadOnly,
            focused: focused,
            value: valueText,
            chevron: chevron,
          )
        : CarbonField(
            size: widget.size,
            status: _status,
            disabled: _controlState.isDisabled,
            readOnly: _controlState.isReadOnly,
            aiLabel: widget.aiLabel,
            aiRevert: widget.aiRevert,
            focused: focused,
            trailing: chevron,
            child: ExcludeSemantics(child: valueText),
          );

    final Widget trigger = CarbonControlSemantics(
      state: _controlState,
      readOnlyHint: widget.readOnlyHint,
      expanded: _controlState.canActivate && _overlay.isShowing,
      activeOptionHint: CarbonListBoxSemantics.activeHintOf(context),
      focusNode: _focus,
      onActivate: _toggle,
      button: true,
      label: widget.labelText,
      value: selected?.label,
      builder: (FocusNode focusNode) => Focus(
        focusNode: focusNode,
        includeSemantics: false,
        canRequestFocus: _controlState.canFocus,
        onKeyEvent: _onKey,
        autofocus: widget.autofocus,
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: _controlState.canActivate ? _toggle : null,
          child: fieldChrome,
        ),
      ),
    );

    final Widget menuTrigger = CompositedTransformTarget(
      link: _link,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _triggerWidth = constraints.maxWidth;
          return OverlayPortal(
            controller: _overlay,
            overlayChildBuilder: _buildMenu,
            child: trigger,
          );
        },
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

    final Widget? label = widget.hideLabel || _fluid
        ? null
        : ExcludeSemantics(
            child: CarbonFormLabel(
              widget.labelText,
              disabled: _controlState.isDisabled,
            ),
          );

    if (widget.inline) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (label != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: CarbonSpacing.spacing05,
                top: CarbonSpacing.spacing03,
              ),
              child: label,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[menuTrigger, ?message],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[?label, menuTrigger, ?message],
    );
  }

  Widget _buildMenu(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final List<CarbonSelectItem<T>> flat = _flatItems;

    final List<Widget> rows = <Widget>[];
    if (widget.itemBuilder == null) {
      for (final CarbonSelectEntry<T> entry in _items) {
        if (entry is CarbonSelectItemGroup<T>) {
          rows.add(
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
              child: Text(
                entry.label,
                style: CarbonTypeStyles.label01.copyWith(
                  color: theme.textSecondary,
                ),
              ),
            ),
          );
          for (final CarbonSelectItem<T> item in entry.items) {
            rows.add(_menuRow(item, flat.indexOf(item), theme, layer));
          }
        } else if (entry is CarbonSelectItem<T>) {
          rows.add(_menuRow(entry, flat.indexOf(entry), theme, layer));
        }
      }
    }

    return CarbonAnchoredOverlay(
      link: _link,
      side: widget.menuSide ?? CarbonOverlaySide.bottom,
      automatic: widget.menuSide == null,
      child: SizedBox(
        width: _triggerWidth,
        child: TapRegion(
          onTapOutside: (_) => _close(),
          // Non-focusable so the trigger keeps keyboard focus (and its key
          // handler) while the menu is open; rows stay tappable.
          child: ExcludeFocus(
            child: ColoredBox(
              color: layer.field,
              child: widget.itemBuilder != null
                  ? CarbonLazyOptionMenu(
                      itemCount: flat.length,
                      itemBuilder: (_, index) =>
                          _menuRow(flat[index], index, theme, layer),
                      activeIndex: _highlighted,
                      minimumRowHeight: widget.size.height,
                      maximumHeight: 240,
                      verticalPadding: 0,
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rows,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuRow(
    CarbonSelectItem<T> item,
    int index,
    CarbonThemeData theme,
    CarbonLayerTokens layer,
  ) {
    final bool selected = item.value == widget.value;
    final bool highlighted = index == _highlighted;
    // The keyboard-roved row keeps itself inside the popup fold (#279).
    return CarbonScrollIntoView(
      active: highlighted,
      child: CarbonListBoxOptionSemantics(
        selected: selected,
        disabled: item.disabled,
        active: highlighted,
        onActivate: () => _select(item),
        label: item.label,
        child: CarbonInteraction(
          enabled: !item.disabled,
          onPressed: () => _select(item),
          builder: (BuildContext context, Set<WidgetState> states) {
            final bool hovered = states.contains(WidgetState.hovered);
            final Color bg = selected
                ? layer.layerSelected
                : (hovered || highlighted) && !item.disabled
                ? layer.layerHover
                : layer.field;
            return ColoredBox(
              color: bg,
              // Option-row height is a minimum (docs/text-scaling.md).
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.size.height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ExcludeSemantics(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CarbonTypeStyles.bodyCompact01.copyWith(
                          color: item.disabled
                              ? theme.textDisabled
                              : theme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The fluid select trigger: a 64px box with the label inside, the value
/// below, and the chevron on the end (`fluid-select/_fluid-select.scss`).
class _FluidSelectField extends StatelessWidget {
  const _FluidSelectField({
    required this.label,
    required this.status,
    required this.disabled,
    required this.readOnly,
    required this.focused,
    required this.value,
    required this.chevron,
  });

  final String label;
  final CarbonFieldStatus status;
  final bool disabled;
  final bool readOnly;
  final bool focused;
  final Widget value;
  final Widget chevron;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool invalid = status == CarbonFieldStatus.invalid;
    final Color border = disabled
        ? const Color(0x00000000)
        : readOnly
        ? layer.borderSubtle
        : theme.borderStrong01;

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: readOnly ? const Color(0x00000000) : layer.field,
        border: Border(bottom: BorderSide(color: border)),
      ),
      // Fluid field height is a minimum (docs/text-scaling.md).
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ExcludeSemantics(
                      child: Text(
                        label,
                        style: CarbonTypeStyles.label01.copyWith(
                          color: disabled
                              ? theme.textDisabled
                              : theme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    ExcludeSemantics(child: value),
                  ],
                ),
              ),
            ),
            chevron,
          ],
        ),
      ),
    );
    if (focused) {
      box = CarbonFocusRing(visible: true, child: box);
    } else if (invalid) {
      box = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(color: theme.supportError, width: 2),
        ),
        child: box,
      );
    }
    return box;
  }
}
