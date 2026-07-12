// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/multi-select/_multi-select.scss
//   react/src/components/MultiSelect/{MultiSelect,FilterableMultiSelect}.tsx
//
// MultiSelect is a multi-choice picker on the ListBox primitive (#91): the
// field shows a selection-count badge, and the menu rows are checkboxes
// (reusing the M5 Checkbox). FilterableMultiSelect adds the ComboBox-style
// filter input. The open/roving orchestration mirrors Dropdown; Space toggles.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../checkbox/carbon_checkbox.dart';
import '../form/carbon_form.dart';
import '../list_box/carbon_list_box.dart';

/// A single option in a [CarbonMultiSelect].
class CarbonMultiSelectItem<T> {
  /// Creates a multi-select item.
  const CarbonMultiSelectItem({
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

/// A Carbon multi-select: a multi-choice picker with a selection-count badge
/// and checkbox menu rows.
///
/// Down/Enter/Space opens; arrows move the highlight; Space toggles the
/// highlighted row; Escape closes. The count badge clears all selections.
class CarbonMultiSelect<T> extends StatefulWidget {
  /// Creates a multi-select.
  const CarbonMultiSelect({
    required this.titleText,
    required this.label,
    required this.items,
    super.key,
    this.selectedValues = const <Never>{},
    this.onChanged,
    this.helperText,
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.invalid = false,
    this.invalidText,
    this.warn = false,
    this.warnText,
    this.hideLabel = false,
    this.filterable = false,
    this.filterPlaceholder,
    this.aiLabel,
    this.fluid = false,
    this.condensed = false,
    this.aiRevert = false,
    this.focusNode,
  }) : assert(!(invalid && warn), 'invalid and warn are mutually exclusive');

  /// The field title shown above the trigger.
  final String titleText;

  /// The text shown in the field (next to the count badge).
  final String label;

  /// The options.
  final List<CarbonMultiSelectItem<T>> items;

  /// The currently selected values.
  final Set<T> selectedValues;

  /// Called with the new selection when a row toggles or all are cleared.
  final ValueChanged<Set<T>>? onChanged;

  /// Helper text (hidden when invalid/warn).
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether the multi-select is disabled.
  final bool disabled;

  /// Whether the multi-select is invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Whether the multi-select is in a warning state.
  final bool warn;

  /// The warning message.
  final String? warnText;

  /// Visually hides the title (kept for assistive technology).
  final bool hideLabel;

  /// Whether the field filters the options with an editable input
  /// (FilterableMultiSelect).
  final bool filterable;

  /// The placeholder for the filter input when [filterable].
  final String? filterPlaceholder;

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

  /// An optional external focus node for the field.
  final FocusNode? focusNode;

  @override
  State<CarbonMultiSelect<T>> createState() => _CarbonMultiSelectState<T>();
}

class _CarbonMultiSelectState<T> extends State<CarbonMultiSelect<T>> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final TextEditingController _filter = TextEditingController();
  FocusNode? _internalFocus;
  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());
  int _highlighted = -1;
  double _triggerWidth = 0;
  bool _hovered = false;

  List<CarbonMultiSelectItem<T>> get _filtered {
    if (!widget.filterable) return widget.items;
    final String q = _filter.text.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return <CarbonMultiSelectItem<T>>[
      for (final CarbonMultiSelectItem<T> item in widget.items)
        if (item.label.toLowerCase().contains(q)) item,
    ];
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
    _filter.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    _focus.requestFocus();
    _overlay.isShowing ? _close() : _open();
  }

  void _open() {
    if (widget.onChanged == null || widget.disabled) return;
    final List<CarbonMultiSelectItem<T>> items = _filtered;
    _highlighted = items.indexWhere(
      (CarbonMultiSelectItem<T> i) => !i.disabled,
    );
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

  void _toggle(CarbonMultiSelectItem<T> item) {
    if (item.disabled) return;
    final Set<T> next = Set<T>.of(widget.selectedValues);
    next.contains(item.value) ? next.remove(item.value) : next.add(item.value);
    widget.onChanged?.call(next);
  }

  void _clearAll() {
    widget.onChanged?.call(<T>{});
    _focus.requestFocus();
  }

  void _onFilter(String value) {
    if (!_overlay.isShowing) _overlay.show();
    final List<CarbonMultiSelectItem<T>> items = _filtered;
    _highlighted = items.indexWhere(
      (CarbonMultiSelectItem<T> i) => !i.disabled,
    );
    setState(() {});
  }

  void _moveHighlight(int delta) {
    final List<CarbonMultiSelectItem<T>> items = _filtered;
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
    if (event is! KeyDownEvent || widget.onChanged == null || widget.disabled) {
      return KeyEventResult.ignored;
    }
    if (!_overlay.isShowing) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.enter ||
          (!widget.filterable &&
              event.logicalKey == LogicalKeyboardKey.space)) {
        _open();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final List<CarbonMultiSelectItem<T>> items = _filtered;
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
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        if (_highlighted >= 0 && _highlighted < items.length) {
          _toggle(items[_highlighted]);
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
            child: widget.filterable
                ? _buildFilterField(context)
                : _buildField(context),
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

    final Widget? title = widget.hideLabel || _fluid
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

  Widget _countAndLabel(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final int count = widget.selectedValues.length;
    return Row(
      children: <Widget>[
        if (count > 0) ...<Widget>[
          CarbonListBoxSelectionCount(
            count: count,
            disabled: widget.disabled,
            onClear: _clearAll,
          ),
          const SizedBox(width: CarbonSpacing.spacing03),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CarbonTypeStyles.bodyCompact01.copyWith(
              color: widget.disabled ? theme.textDisabled : theme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: widget.titleText,
      value: widget.selectedValues.isEmpty
          ? null
          : '${widget.selectedValues.length} selected',
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: CarbonListBox(
          size: widget.size,
          expanded: _overlay.isShowing,
          disabled: widget.disabled,
          aiLabel: widget.aiLabel,
          aiRevert: widget.aiRevert,
          fluid: _fluid,
          fluidLabel: _fluid ? widget.titleText : null,
          invalid: widget.invalid,
          warn: widget.warn,
          focused: _focus.hasFocus,
          onTap: widget.disabled ? null : _toggleOpen,
          child: ExcludeSemantics(child: _countAndLabel(context)),
        ),
      ),
    );
  }

  Widget _buildFilterField(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !widget.disabled;
    final int count = widget.selectedValues.length;
    final Color background = enabled && _hovered
        ? layer.fieldHover
        : layer.field;
    final Color borderColor = widget.disabled
        ? const Color(0x00000000)
        : _overlay.isShowing
        ? layer.borderSubtle
        : theme.borderStrong01;
    final Border border = widget.invalid && enabled
        ? Border.all(color: theme.supportError, width: 2)
        : Border(bottom: BorderSide(color: borderColor));

    return MergeSemantics(
      child: Semantics(
        textField: true,
        label: widget.titleText,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: CarbonFocusRing(
              visible: _focus.hasFocus,
              inset: true,
              child: AnimatedContainer(
                duration: CarbonDuration.fast01,
                curve: CarbonEasing.standardProductive,
                height: widget.size.height,
                decoration: BoxDecoration(color: background, border: border),
                padding: const EdgeInsetsDirectional.only(
                  start: CarbonSpacing.spacing05,
                  end: CarbonSpacing.spacing04,
                ),
                child: Row(
                  children: <Widget>[
                    if (count > 0) ...<Widget>[
                      CarbonListBoxSelectionCount(
                        count: count,
                        disabled: widget.disabled,
                        onClear: _clearAll,
                      ),
                      const SizedBox(width: CarbonSpacing.spacing03),
                    ],
                    Expanded(
                      child: _FilterInput(
                        controller: _filter,
                        focusNode: _focus,
                        enabled: enabled,
                        placeholder: widget.filterPlaceholder ?? widget.label,
                        style: CarbonTypeStyles.bodyCompact01.copyWith(
                          color: widget.disabled
                              ? theme.textDisabled
                              : theme.textPrimary,
                        ),
                        placeholderColor: theme.textPlaceholder,
                        cursorColor: theme.focus,
                        onChanged: _onFilter,
                      ),
                    ),
                    const SizedBox(width: CarbonSpacing.spacing03),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: enabled ? _toggleOpen : null,
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
    final List<CarbonMultiSelectItem<T>> items = _filtered;
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
              fluidRows: _fluid && !widget.condensed,
              children: rows,
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuRow(CarbonMultiSelectItem<T> item, int index) {
    final bool selected = widget.selectedValues.contains(item.value);
    return Semantics(
      checked: selected,
      enabled: !item.disabled,
      label: item.label,
      child: ExcludeSemantics(
        child: CarbonListBoxMenuItem(
          size: widget.size,
          fluid: _fluid && !widget.condensed,
          isFirst: index == 0,
          isHighlighted: index == _highlighted,
          disabled: item.disabled,
          child: IgnorePointer(
            ignoring: item.disabled,
            child: CarbonCheckbox(
              label: item.label,
              value: selected,
              onChanged: item.disabled ? null : (_) => _toggle(item),
            ),
          ),
        ),
      ),
    );
  }
}

/// The editable filter input inside a [CarbonMultiSelect] field.
class _FilterInput extends StatelessWidget {
  const _FilterInput({
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
  final String placeholder;
  final TextStyle style;
  final Color placeholderColor;
  final Color cursorColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        if (controller.text.isEmpty)
          ExcludeSemantics(
            child: IgnorePointer(
              child: Text(
                placeholder,
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
