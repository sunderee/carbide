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
import '../../utils/picker_overlay.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/focus_ring.dart';
import '../checkbox/carbon_checkbox.dart';
import '../../utils/owned_listenable.dart';
import '../../utils/text_control_semantics.dart';
import '../form/carbon_form.dart';
import '../list_box/list_box_semantics.dart';
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
/// Down or Enter opens; Space also opens a non-filterable picker. Arrows move
/// the highlight; Enter toggles an enabled highlighted row; Space toggles it
/// only in a non-filterable picker, leaving spaces available for filter text.
/// Escape closes an open popup. Keys that perform no action continue to
/// ancestor handlers. The count badge clears all selections.
///
/// See the [forms pattern](https://github.com/sunderee/carbide/blob/master/docs/patterns/forms.md#disabled-and-read-only-controls)
/// for the shared disabled and read-only contract.
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
    this.readOnly = false,
    this.readOnlyHint = CarbonControlState.defaultReadOnlyHint,
    this.activeOptionFormatter = carbonListBoxActiveOptionLabel,
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
  ///
  /// A null callback disables selection and takes precedence over [readOnly].
  final ValueChanged<Set<T>>? onChanged;

  /// Helper text (hidden when invalid/warn).
  final String? helperText;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether the multi-select is disabled.
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

  /// A caller-owned focus node, rebound when this property changes.
  ///
  /// Current focus transfers to the replacement when it can request focus.
  /// Removing it creates an internal node. Caller-owned nodes are never disposed
  /// here.
  final FocusNode? focusNode;

  @override
  State<CarbonMultiSelect<T>> createState() => _CarbonMultiSelectState<T>();
}

class _CarbonMultiSelectState<T> extends State<CarbonMultiSelect<T>> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  CarbonControlState get _controlState => CarbonControlState.resolve(
    hasCallback: widget.onChanged != null,
    disabled: widget.disabled,
    readOnly: widget.readOnly,
  );

  final CarbonPickerOverlayController _overlay =
      CarbonPickerOverlayController();
  final LayerLink _link = LayerLink();
  final TextEditingController _filter = TextEditingController();
  TextEditingValue _filterDraft = TextEditingValue.empty;

  String get _selectedLabels => widget.items
      .where(
        (CarbonMultiSelectItem<T> item) =>
            widget.selectedValues.contains(item.value),
      )
      .map((CarbonMultiSelectItem<T> item) => item.label)
      .join(', ');
  late final OwnedFocusNode _focusOwner;
  FocusNode get _focus => _focusOwner.value;
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
    if (!_controlState.canActivate) _showInspectionValue();
    _focusOwner = OwnedFocusNode(
      external: widget.focusNode,
      onChanged: _rebuild,
    );
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CarbonMultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focusOwner.update(widget.focusNode);
    final bool wasEditable = CarbonControlState.resolve(
      hasCallback: oldWidget.onChanged != null,
      disabled: oldWidget.disabled,
      readOnly: oldWidget.readOnly,
    ).canActivate;
    // Keep one editor controller across the policy change. Swapping controllers
    // can leave Flutter web's native connection on the inspection value after
    // re-enabling. The full draft retains selection and composing state.
    if (wasEditable && !_controlState.canActivate) _filterDraft = _filter.value;
    if (_controlState.canActivate) {
      if (!wasEditable) _filter.value = _filterDraft;
    } else {
      _showInspectionValue();
    }
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

  void _showInspectionValue() {
    final String text = _selectedLabels;
    if (_filter.text == text) return;
    _filter.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _overlay.dispose();
    _focusOwner.dispose();
    _filter.dispose();
    super.dispose();
  }

  void _toggleOpen() {
    if (!mounted || !_controlState.canActivate) return;
    _focus.requestFocus();
    _overlay.isShowing ? _close() : _open();
  }

  void _open() {
    if (!mounted || !_controlState.canActivate) return;
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
    if (!mounted) return;
    _overlay.hide();
    setState(() {});
  }

  void _toggle(CarbonMultiSelectItem<T> item) {
    if (!mounted || !_controlState.canActivate || item.disabled) return;
    final Set<T> next = Set<T>.of(widget.selectedValues);
    next.contains(item.value) ? next.remove(item.value) : next.add(item.value);
    // A pointer selection can blur the native editor before Flutter receives
    // the tap. Keep keyboard navigation on the trigger; a caller's subsequent
    // focus request from onChanged still takes precedence.
    _focus.requestFocus();
    widget.onChanged?.call(next);
  }

  void _clearAll() {
    if (!mounted || !_controlState.canActivate) return;
    widget.onChanged?.call(<T>{});
    _focus.requestFocus();
  }

  void _onFilter(String value) {
    if (!mounted || !_controlState.canActivate) return;
    if (!_overlay.isShowing) _overlay.show();
    final List<CarbonMultiSelectItem<T>> items = _filtered;
    _highlighted = items.indexWhere(
      (CarbonMultiSelectItem<T> i) => !i.disabled,
    );
    setState(() {});
  }

  bool _moveHighlight(int delta) {
    final List<CarbonMultiSelectItem<T>> items = _filtered;
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
        return _moveHighlight(1)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        return _moveHighlight(-1)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        if (widget.filterable && event.logicalKey == LogicalKeyboardKey.space) {
          return KeyEventResult.ignored;
        }
        if (_highlighted >= 0 &&
            _highlighted < items.length &&
            !items[_highlighted].disabled) {
          _toggle(items[_highlighted]);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => CarbonListBoxSemantics(
    expanded: _controlState.canActivate && _overlay.isShowing,
    activeIndex: _highlighted,
    focusNode: _focus,
    optionLabels: <String?>[
      for (final item in _filtered) item.disabled ? null : item.label,
    ],
    formatActiveOption: widget.activeOptionFormatter,
    builder: _build,
  );

  Widget _build(BuildContext context) {
    final Widget field = CompositedTransformTarget(
      link: _link,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _triggerWidth = constraints.maxWidth;
          return CarbonPickerOverlay(
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
            disabled: _controlState.isDisabled,
            onClear: _clearAll,
            readOnly: _controlState.isReadOnly,
          ),
          const SizedBox(width: CarbonSpacing.spacing03),
        ],
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: CarbonTypeStyles.bodyCompact01.copyWith(
              color: _controlState.isDisabled
                  ? theme.textDisabled
                  : theme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    return CarbonControlSemantics(
      state: _controlState,
      readOnlyHint: widget.readOnlyHint,
      expanded: _controlState.canActivate && _overlay.isShowing,
      activeOptionHint: CarbonListBoxSemantics.activeHintOf(context),
      focusNode: _focus,
      onActivate: _toggleOpen,
      button: true,
      label: widget.titleText,
      value: _selectedLabels.isEmpty ? null : _selectedLabels,
      builder: (FocusNode focusNode) => Focus(
        focusNode: focusNode,
        includeSemantics: false,
        canRequestFocus: _controlState.canFocus,
        onKeyEvent: _onKey,
        child: CarbonListBox(
          includeSemantics: false,
          size: widget.size,
          expanded: _overlay.isShowing,
          disabled: _controlState.isDisabled,
          readOnly: _controlState.isReadOnly,
          aiLabel: widget.aiLabel,
          aiRevert: widget.aiRevert,
          fluid: _fluid,
          fluidLabel: _fluid ? widget.titleText : null,
          invalid: widget.invalid,
          warn: widget.warn,
          focused: _focus.hasFocus,
          onTap: _controlState.canActivate ? _toggleOpen : null,
          child: ExcludeSemantics(child: _countAndLabel(context)),
        ),
      ),
    );
  }

  Widget _buildFilterField(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool enabled = !_controlState.isDisabled;
    final TextEditingController controller = _filter;
    final int count = widget.selectedValues.length;
    final Color background = _controlState.isReadOnly
        ? const Color(0x00000000)
        : _controlState.canActivate && _hovered
        ? layer.fieldHover
        : layer.field;
    final Color borderColor = _controlState.isDisabled
        ? const Color(0x00000000)
        : _controlState.isReadOnly || _overlay.isShowing
        ? layer.borderSubtle
        : theme.borderStrong01;
    final Border border = widget.invalid && enabled
        ? Border.all(color: theme.supportError, width: 2)
        : Border(bottom: BorderSide(color: borderColor));

    return Semantics(
      container: true,
      explicitChildNodes: true,
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
              duration: carbonDuration(context, CarbonDuration.fast01),
              curve: CarbonEasing.standardProductive,
              constraints: BoxConstraints(
                minHeight: _fluid ? 64 : widget.size.height,
              ),
              decoration: BoxDecoration(color: background, border: border),
              padding: const EdgeInsetsDirectional.only(
                start: CarbonSpacing.spacing05,
                end: CarbonSpacing.spacing04,
                top: CarbonSpacing.spacing01,
                bottom: CarbonSpacing.spacing01,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_fluid) ...<Widget>[
                    ExcludeSemantics(
                      child: Text(
                        widget.titleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CarbonTypeStyles.label01.copyWith(
                          color: _controlState.isDisabled
                              ? theme.textDisabled
                              : theme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    key: const ValueKey<String>(
                      'carbon-multi-select-filter-row',
                    ),
                    children: <Widget>[
                      if (count > 0) ...<Widget>[
                        ExcludeSemantics(
                          excluding: !_controlState.canActivate,
                          child: CarbonListBoxSelectionCount(
                            count: count,
                            disabled: _controlState.isDisabled,
                            readOnly: _controlState.isReadOnly,
                            onClear: _clearAll,
                          ),
                        ),
                        const SizedBox(width: CarbonSpacing.spacing03),
                      ],
                      Expanded(
                        child: CarbonTextControlSemantics(
                          state: _controlState,
                          label: widget.titleText,
                          value: controller.text,
                          readOnlyHint: widget.readOnlyHint,
                          expanded:
                              _controlState.canActivate && _overlay.isShowing,
                          activeOptionHint: CarbonListBoxSemantics.activeHintOf(
                            context,
                          ),
                          focusNode: _focus,
                          child: _FilterInput(
                            controller: controller,
                            focusNode: _focus,
                            enabled: _controlState.canActivate,
                            placeholder:
                                widget.filterPlaceholder ?? widget.label,
                            style: CarbonTypeStyles.bodyCompact01.copyWith(
                              color: _controlState.isDisabled
                                  ? theme.textDisabled
                                  : theme.textPrimary,
                            ),
                            placeholderColor: theme.textPlaceholder,
                            cursorColor: theme.focus,
                            onChanged: _onFilter,
                          ),
                        ),
                      ),
                      const SizedBox(width: CarbonSpacing.spacing03),
                      ExcludeSemantics(
                        excluding: !_controlState.canActivate,
                        child: Semantics(
                          button: true,
                          label: widget.titleText,
                          expanded: _overlay.isShowing,
                          onTap: _controlState.canActivate ? _toggleOpen : null,
                          child: GestureDetector(
                            excludeFromSemantics: true,
                            behavior: HitTestBehavior.opaque,
                            onTap: _controlState.canActivate
                                ? _toggleOpen
                                : null,
                            child: CarbonListBoxMenuIcon(
                              open: _overlay.isShowing,
                              disabled: !_controlState.canActivate,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
    return CarbonListBoxOptionSemantics(
      multiple: true,
      selected: selected,
      disabled: item.disabled,
      active: index == _highlighted,
      onActivate: () => _toggle(item),
      label: item.label,
      child: ExcludeSemantics(
        child: CarbonListBoxMenuItem(
          size: widget.size,
          fluid: _fluid && !widget.condensed,
          isFirst: index == 0,
          isHighlighted: index == _highlighted,
          disabled: item.disabled,
          onTap: () => _toggle(item),
          child: IgnorePointer(
            // The whole option row owns pointer activation, including taps
            // over the checkbox. Its checkbox paints the committed state.
            ignoring: true,
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
          groupId: focusNode,
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
