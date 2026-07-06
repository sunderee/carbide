// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
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
import '../../utils/focus_ring.dart';
import '../../utils/interaction.dart';
import '../form/carbon_form.dart';

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
/// support: Down/Enter/Space opens; arrows move the highlight; Enter selects;
/// Escape closes; typing jumps to the next matching label. Reuses the
/// [CarbonField] chrome with [inline] and [fluid] layouts.
class CarbonSelect<T> extends StatefulWidget {
  /// Creates a select.
  const CarbonSelect({
    super.key,
    required this.labelText,
    required this.items,
    this.value,
    this.onChanged,
    this.placeholder,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.disabled = false,
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
  }) : assert(!(inline && fluid), 'inline and fluid are mutually exclusive');

  /// The field label.
  final String labelText;

  /// The options (items and/or groups).
  final List<CarbonSelectEntry<T>> items;

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

  /// Whether disabled.
  final bool disabled;

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

  /// An optional focus node.
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

  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  FocusNode? _internalFocus;
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());
  int _highlighted = -1;
  double _triggerWidth = 0;

  List<CarbonSelectItem<T>> get _flatItems => <CarbonSelectItem<T>>[
    for (final CarbonSelectEntry<T> entry in widget.items)
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
    _focus.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _internalFocus?.dispose();
    super.dispose();
  }

  void _open() {
    if (widget.onChanged == null) {
      return;
    }
    final List<CarbonSelectItem<T>> items = _flatItems;
    _highlighted = items.indexWhere((CarbonSelectItem<T> i) => !i.disabled);
    final CarbonSelectItem<T>? selected = _selectedItem;
    if (selected != null) {
      _highlighted = items.indexOf(selected);
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

  void _close() {
    _overlay.hide();
    setState(() {});
  }

  void _select(CarbonSelectItem<T> item) {
    if (item.disabled) {
      return;
    }
    widget.onChanged?.call(item.value);
    _close();
    _focus.requestFocus();
  }

  void _moveHighlight(int delta) {
    final List<CarbonSelectItem<T>> items = _flatItems;
    int next = _highlighted;
    for (int i = 0; i < items.length; i++) {
      next = (next + delta + items.length) % items.length;
      if (!items[next].disabled) {
        setState(() => _highlighted = next);
        return;
      }
    }
  }

  /// All keyboard handling lives on the trigger (the menu is non-focusable,
  /// so the trigger keeps focus while open): Down/Enter/Space open; arrows
  /// navigate; Enter/Space select; Escape closes; characters type-ahead.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null) {
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
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      final List<CarbonSelectItem<T>> items = _flatItems;
      if (_highlighted >= 0 && _highlighted < items.length) {
        _select(items[_highlighted]);
      }
      return KeyEventResult.handled;
    }
    final String? ch = event.character;
    if (ch != null && ch.trim().isNotEmpty) {
      final List<CarbonSelectItem<T>> items = _flatItems;
      final int start = _highlighted + 1;
      for (int i = 0; i < items.length; i++) {
        final int idx = (start + i) % items.length;
        if (!items[idx].disabled &&
            items[idx].label.toLowerCase().startsWith(ch.toLowerCase())) {
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
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool enabled = !widget.disabled;
    final CarbonSelectItem<T>? selected = _selectedItem;
    final String display = selected?.label ?? widget.placeholder ?? '';
    final Color textColor = widget.disabled
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
        color: widget.disabled ? theme.iconDisabled : theme.iconPrimary,
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
            disabled: widget.disabled,
            focused: focused,
            value: valueText,
            chevron: chevron,
          )
        : CarbonField(
            size: widget.size,
            status: _status,
            disabled: widget.disabled,
            aiLabel: widget.aiLabel,
            aiRevert: widget.aiRevert,
            focused: focused,
            trailing: chevron,
            child: ExcludeSemantics(child: valueText),
          );

    final Widget trigger = Semantics(
      button: true,
      enabled: enabled,
      label: widget.labelText,
      value: selected?.label,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        autofocus: widget.autofocus,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled
              ? () {
                  _focus.requestFocus();
                  _overlay.isShowing ? _close() : _open();
                }
              : null,
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
        ? CarbonHelperText(widget.helperText!, disabled: widget.disabled)
        : null;

    final Widget? label = widget.hideLabel || _fluid
        ? null
        : ExcludeSemantics(
            child: CarbonFormLabel(widget.labelText, disabled: widget.disabled),
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
    for (final CarbonSelectEntry<T> entry in widget.items) {
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

    return Positioned.directional(
      textDirection: Directionality.of(context),
      width: _triggerWidth,
      child: CompositedTransformFollower(
        link: _link,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        showWhenUnlinked: false,
        child: TapRegion(
          onTapOutside: (_) => _close(),
          // Non-focusable so the trigger keeps keyboard focus (and its key
          // handler) while the menu is open; rows stay tappable.
          child: ExcludeFocus(
            child: ColoredBox(
              color: layer.field,
              child: ConstrainedBox(
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
    return Semantics(
      button: true,
      selected: selected,
      enabled: !item.disabled,
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
    required this.focused,
    required this.value,
    required this.chevron,
  });

  final String label;
  final CarbonFieldStatus status;
  final bool disabled;
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
        : theme.borderStrong01;

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: layer.field,
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
