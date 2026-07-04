// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/combo-box/_combo-box.scss
//   react/src/components/ComboBox/ComboBox.tsx
//
// ComboBox is a filterable single-select on the ListBox primitive (#91): the
// field carries an editable text input that filters the menu as you type, plus
// a clear (X) control. It reuses the ListBox menu/option chrome and the
// Dropdown open/roving orchestration, adapted for live filtering.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../form/carbon_form.dart';
import '../list_box/carbon_list_box.dart';

/// A single option in a [CarbonComboBox].
class CarbonComboBoxItem<T> {
  /// Creates a combo-box item.
  const CarbonComboBoxItem({
    required this.value,
    required this.label,
    this.disabled = false,
  });

  /// The option value.
  final T value;

  /// The visible, filterable text.
  final String label;

  /// Whether the option is selectable.
  final bool disabled;
}

/// A Carbon combo box: a single-select picker whose field filters the options
/// as you type.
///
/// Typing filters the menu (case-insensitive substring); arrows move the
/// highlight; Enter selects; Escape clears or closes; the clear (X) control
/// resets the value.
class CarbonComboBox<T> extends StatefulWidget {
  /// Creates a combo box.
  const CarbonComboBox({
    required this.titleText,
    required this.items,
    super.key,
    this.selectedItem,
    this.onChanged,
    this.onInputChange,
    this.placeholder,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.hideLabel = false,
    this.aiLabel,
    this.fluid = false,
    this.condensed = false,
    this.aiRevert = false,
    this.focusNode,
  }) : assert(!(invalid && warn), 'invalid and warn are mutually exclusive');

  /// The field title shown above the trigger.
  final String titleText;

  /// The options.
  final List<CarbonComboBoxItem<T>> items;

  /// The selected value.
  final T? selectedItem;

  /// Called with the chosen value, or null when cleared.
  final ValueChanged<T?>? onChanged;

  /// Called with the field text as the user types.
  final ValueChanged<String>? onInputChange;

  /// The placeholder shown when the field is empty.
  final String? placeholder;

  /// Helper text (hidden when invalid/warn).
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether the combo box is disabled.
  final bool disabled;

  /// Whether the combo box is invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Whether the combo box is in a warning state.
  final bool warn;

  /// The warning message.
  final String? warnText;

  /// Visually hides the title (kept for assistive technology).
  final bool hideLabel;

  /// The fluid treatment: a 64px field with the title rendered inside
  /// above the value, and 64px menu rows (`_fluid-list-box.scss`).
  final bool fluid;

  /// The condensed fluid variant: the field stays fluid but the menu rows
  /// keep the standard height (`--list-box__wrapper--fluid--condensed`).
  final bool condensed;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in the
  /// field per upstream's `decorator` prop; adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// An optional external focus node for the input.
  final FocusNode? focusNode;

  @override
  State<CarbonComboBox<T>> createState() => _CarbonComboBoxState<T>();
}

class _CarbonComboBoxState<T> extends State<CarbonComboBox<T>> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  late final TextEditingController _controller;
  FocusNode? _internalFocus;
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());
  int _highlighted = -1;
  double _triggerWidth = 0;
  bool _hovered = false;

  CarbonComboBoxItem<T>? get _selected {
    for (final CarbonComboBoxItem<T> item in widget.items) {
      if (item.value == widget.selectedItem) return item;
    }
    return null;
  }

  List<CarbonComboBoxItem<T>> get _filtered {
    final String q = _controller.text.trim().toLowerCase();
    if (q.isEmpty || q == _selected?.label.toLowerCase()) return widget.items;
    return <CarbonComboBoxItem<T>>[
      for (final CarbonComboBoxItem<T> item in widget.items)
        if (item.label.toLowerCase().contains(q)) item,
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _selected?.label ?? '');
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CarbonComboBox<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItem != oldWidget.selectedItem) {
      final String text = _selected?.label ?? '';
      if (text != _controller.text) _controller.text = text;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _internalFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focus.hasFocus && !_overlay.isShowing && !widget.disabled) {
      _open();
    }
    setState(() {});
  }

  void _onText(String value) {
    widget.onInputChange?.call(value);
    if (!_overlay.isShowing) _overlay.show();
    final List<CarbonComboBoxItem<T>> items = _filtered;
    _highlighted = items.indexWhere((CarbonComboBoxItem<T> i) => !i.disabled);
    setState(() {});
  }

  void _open() {
    if (widget.disabled) return;
    final List<CarbonComboBoxItem<T>> items = _filtered;
    _highlighted = items.indexWhere((CarbonComboBoxItem<T> i) => !i.disabled);
    final CarbonComboBoxItem<T>? selected = _selected;
    if (selected != null && items.contains(selected)) {
      _highlighted = items.indexOf(selected);
    }
    _overlay.show();
    setState(() {});
  }

  void _close() {
    _overlay.hide();
    setState(() {});
  }

  void _select(CarbonComboBoxItem<T> item) {
    if (item.disabled) return;
    _controller.value = TextEditingValue(
      text: item.label,
      selection: TextSelection.collapsed(offset: item.label.length),
    );
    widget.onChanged?.call(item.value);
    _close();
    _focus.requestFocus();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call(null);
    _focus.requestFocus();
    _open();
  }

  void _moveHighlight(int delta) {
    final List<CarbonComboBoxItem<T>> items = _filtered;
    if (items.isEmpty) return;
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
    if (event is! KeyDownEvent || widget.disabled) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _overlay.isShowing ? _moveHighlight(1) : _open();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        if (_overlay.isShowing) _moveHighlight(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        final List<CarbonComboBoxItem<T>> items = _filtered;
        if (_overlay.isShowing &&
            _highlighted >= 0 &&
            _highlighted < items.length) {
          _select(items[_highlighted]);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (_overlay.isShowing) {
          _close();
        } else if (_controller.text.isNotEmpty) {
          _clear();
        }
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final Widget field = CompositedTransformTarget(
      link: _link,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _triggerWidth = constraints.maxWidth;
          return OverlayPortal(
            controller: _overlay,
            overlayChildBuilder: _buildMenu,
            child: _buildField(context),
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

    final Widget? title = widget.hideLabel || widget.fluid
        ? null
        : ExcludeSemantics(
            child: CarbonFormLabel(widget.titleText, disabled: widget.disabled),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[?title, field, ?message],
    );
  }

  Widget _buildField(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled;
    final bool focused = _focus.hasFocus;

    final Color background = enabled && _hovered
        ? layer.fieldHover
        : layer.field;
    // The AI treatment: aura gradient + ai-border-strong bottom border.
    final bool ai = widget.aiLabel != null && !widget.aiRevert;
    final Color borderColor = widget.disabled
        ? const Color(0x00000000)
        : _overlay.isShowing
        ? layer.borderSubtle
        : ai
        ? theme.aiBorderStrong
        : theme.borderStrong01;
    final Border border = widget.invalid && enabled
        ? Border.all(color: theme.supportError, width: 2)
        : Border(bottom: BorderSide(color: borderColor));

    final Widget editable = _ComboInput(
      controller: _controller,
      focusNode: _focus,
      enabled: enabled,
      placeholder: widget.placeholder,
      style: CarbonTypeStyles.bodyCompact01.copyWith(
        color: widget.disabled ? theme.textDisabled : theme.textPrimary,
      ),
      placeholderColor: theme.textPlaceholder,
      cursorColor: theme.focus,
      onChanged: _onText,
    );

    return MergeSemantics(
      child: Semantics(
        textField: true,
        label: widget.titleText,
        child: Focus(
          // Intercepts navigation keys before the editor's text actions; an
          // ancestor onKeyEvent runs before Shortcuts/Actions.
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: CarbonFocusRing(
              visible: focused,
              inset: true,
              child: AnimatedContainer(
                duration: CarbonDuration.fast01,
                curve: CarbonEasing.standardProductive,
                height: widget.fluid ? 64 : widget.size.height,
                decoration: BoxDecoration(
                  color: background,
                  gradient: ai ? CarbonField.aiFieldGradient(theme) : null,
                  border: border,
                ),
                padding: const EdgeInsetsDirectional.only(
                  start: CarbonSpacing.spacing05,
                  end: CarbonSpacing.spacing04,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      // Fluid stacks the label-01 title above the input
                      // (the house centered-column fluid treatment).
                      child: widget.fluid
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                ExcludeSemantics(
                                  child: Text(
                                    widget.titleText,
                                    style: CarbonTypeStyles.label01.copyWith(
                                      color: widget.disabled
                                          ? theme.textDisabled
                                          : theme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                editable,
                              ],
                            )
                          : editable,
                    ),
                    if (_controller.text.isNotEmpty && enabled) ...<Widget>[
                      const SizedBox(width: CarbonSpacing.spacing03),
                      CarbonListBoxSelection(onClear: _clear),
                    ],
                    // The AI label sits before the menu chevron
                    // (`_list-box.scss` decorator placement).
                    if (widget.aiLabel != null) ...<Widget>[
                      const SizedBox(width: CarbonSpacing.spacing03),
                      widget.aiLabel!,
                    ],
                    const SizedBox(width: CarbonSpacing.spacing03),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled
                          ? () {
                              _focus.requestFocus();
                              _overlay.isShowing ? _close() : _open();
                            }
                          : null,
                      child: CarbonListBoxMenuIcon(
                        open: _overlay.isShowing,
                        disabled: widget.disabled,
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

  Widget _buildMenu(BuildContext context) {
    final List<CarbonComboBoxItem<T>> items = _filtered;
    final List<Widget> rows = <Widget>[
      for (int i = 0; i < items.length; i++) _menuRow(items[i], i),
    ];

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
          child: ExcludeFocus(
            child: CarbonListBoxMenu(
              size: widget.size,
              fluidRows: widget.fluid && !widget.condensed,
              children: rows,
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuRow(CarbonComboBoxItem<T> item, int index) {
    final bool selected = item.value == widget.selectedItem;
    return CarbonListBoxMenuItem(
      size: widget.size,
      fluid: widget.fluid && !widget.condensed,
      isFirst: index == 0,
      isActive: selected,
      isHighlighted: index == _highlighted,
      disabled: item.disabled,
      onTap: () => _select(item),
      child: Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// The editable text field inside the combo-box surface: a placeholder shown
/// when empty, over a single-line [EditableText].
class _ComboInput extends StatelessWidget {
  const _ComboInput({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.placeholder,
    required this.style,
    required this.placeholderColor,
    required this.cursorColor,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String? placeholder;
  final TextStyle style;
  final Color placeholderColor;
  final Color cursorColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        if (placeholder != null && controller.text.isEmpty)
          ExcludeSemantics(
            child: IgnorePointer(
              child: Text(
                placeholder!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: placeholderColor),
              ),
            ),
          ),
        EditableText(
          controller: controller,
          focusNode: focusNode,
          readOnly: !enabled,
          onChanged: onChanged,
          style: style,
          cursorColor: cursorColor,
          backgroundCursorColor: placeholderColor,
          selectionColor: cursorColor.withValues(alpha: 0.2),
          cursorWidth: 1,
          maxLines: 1,
        ),
      ],
    );
  }
}
