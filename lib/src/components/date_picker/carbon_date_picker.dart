// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/date-picker/{_date-picker,_flatpickr}.scss
//   react/src/components/DatePicker/{DatePicker,DatePickerInput}.tsx
//
// Carbon's DatePicker wraps the flatpickr JS calendar, which is not portable.
// Carbide builds a self-contained CarbonCalendar (no Material) opened from a
// DatePickerInput via the Popover (#90), in single and range modes. The
// range selection mirrors flatpickr's observable behavior: the first
// activation starts a range, activating a later day commits it, activating
// an earlier day restarts it, and hovering (or arrowing) previews the
// in-between band. Day styling follows the _flatpickr.scss selectors —
// committed ends on button-primary, in-range days on the highlight token,
// and the preview end as a layer-01 cell with the 2px focus outline.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/control_state.dart';
import '../../utils/native_control_focus.dart';
import '../form/carbon_form.dart';
import '../popover/carbon_popover.dart';

const List<String> _months = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December', //
];
const List<String> _weekdays = <String>[
  'Su',
  'Mo',
  'Tu',
  'We',
  'Th',
  'Fr',
  'Sa',
];

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void _validateDateBounds(DateTime? first, DateTime? last) {
  assert(
    first == null || last == null || !_dayOnly(first).isAfter(_dayOnly(last)),
    'firstDate must not be after lastDate.',
  );
}

/// An inclusive date range; [end] is null while a range is in progress.
@immutable
class CarbonDateRange {
  /// Creates a range from [start] to an optional [end].
  const CarbonDateRange(this.start, [this.end]);

  /// The first day of the range.
  final DateTime start;

  /// The last day, or null while only the start has been picked.
  final DateTime? end;

  /// Whether both ends have been picked.
  bool get isComplete => end != null;

  @override
  bool operator ==(Object other) =>
      other is CarbonDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'CarbonDateRange($start, $end)';
}

/// A self-contained month calendar for picking a date or a date range.
///
/// Provide [onChanged] for single-date mode, or [onRangeChanged] for range
/// mode (exactly one of the two). Arrow keys move the focused day (crossing
/// month edges turns the page), Enter/Space activates it, and Escape calls
/// [onEscape]. PageUp/PageDown move by a month, preserving the day where
/// possible. Navigation skips dates outside the inclusive [firstDate] and
/// [lastDate] bounds and stops at their edges; month chevrons are disabled
/// when their target month has no selectable dates.
///
/// Changes to the selected civil date or range reanchor the visible month
/// and focused day. Bounds changes clamp the current navigation. An unchanged
/// selected date preserves in-progress keyboard navigation, including when
/// its time of day changes. Focused-day semantics are separate from selection.
class CarbonCalendar extends StatefulWidget {
  /// Creates a calendar.
  const CarbonCalendar({
    super.key,
    this.value,
    this.onChanged,
    this.range,
    this.onRangeChanged,
    this.firstDate,
    this.lastDate,
    this.onEscape,
    this.autofocus = false,
  }) : assert(
         (onChanged != null) ^ (onRangeChanged != null),
         'Provide exactly one of onChanged (single) or onRangeChanged '
         '(range).',
       ),
       assert(
         range == null || onRangeChanged != null,
         'range requires onRangeChanged.',
       ),
       assert(value == null || onChanged != null, 'value requires onChanged.');

  /// The selected date (single mode).
  final DateTime? value;

  /// Called with the picked date (single mode).
  final ValueChanged<DateTime>? onChanged;

  /// The selected range (range mode).
  final CarbonDateRange? range;

  /// Called as the range progresses (range mode): first with a start-only
  /// range, then with the completed range — or with a new start-only range
  /// when an earlier day restarts the selection.
  final ValueChanged<CarbonDateRange>? onRangeChanged;

  /// The earliest selectable date (inclusive).
  final DateTime? firstDate;

  /// The latest selectable date (inclusive).
  final DateTime? lastDate;

  /// Called when Escape is pressed on the day grid.
  final VoidCallback? onEscape;

  /// Whether the day grid takes focus when first built.
  final bool autofocus;

  @override
  StatefulElement createElement() {
    // Validate before allocating state/focus resources. Flutter can retain
    // an element whose initState throws, particularly on the web test engine.
    _validateDateBounds(firstDate, lastDate);
    return super.createElement();
  }

  @override
  State<CarbonCalendar> createState() => _CarbonCalendarState();
}

class _CarbonCalendarState extends State<CarbonCalendar> {
  late DateTime _month = _monthOf(_initialAnchor);
  DateTime? _hoverDay;
  late DateTime _focusedDay = _initialAnchor;
  bool _gridFocused = false;
  final FocusNode _gridNode = FocusNode(debugLabel: 'CarbonCalendar');

  DateTime get _initialAnchor => _dayOnly(
    widget.range?.end ?? widget.range?.start ?? widget.value ?? DateTime.now(),
  );

  static DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

  static DateTime? _optionalDay(DateTime? d) => d == null ? null : _dayOnly(d);

  DateTime _clampDay(DateTime day) {
    final DateTime normalized = _dayOnly(day);
    final DateTime? first = _optionalDay(widget.firstDate);
    final DateTime? last = _optionalDay(widget.lastDate);
    if (first != null && normalized.isBefore(first)) return first;
    if (last != null && normalized.isAfter(last)) return last;
    return normalized;
  }

  @override
  void initState() {
    super.initState();
    _focusedDay = _clampDay(_initialAnchor);
    _month = _monthOf(_focusedDay);
  }

  @override
  void didUpdateWidget(CarbonCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateDateBounds(widget.firstDate, widget.lastDate);
    final bool selectionChanged =
        _optionalDay(widget.value) != _optionalDay(oldWidget.value) ||
        _optionalDay(widget.range?.start) !=
            _optionalDay(oldWidget.range?.start) ||
        _optionalDay(widget.range?.end) != _optionalDay(oldWidget.range?.end) ||
        (widget.onRangeChanged != null) != (oldWidget.onRangeChanged != null);
    final bool boundsChanged =
        _optionalDay(widget.firstDate) != _optionalDay(oldWidget.firstDate) ||
        _optionalDay(widget.lastDate) != _optionalDay(oldWidget.lastDate);
    if (selectionChanged || boundsChanged) {
      _focusedDay = _clampDay(selectionChanged ? _initialAnchor : _focusedDay);
      _month = _monthOf(_focusedDay);
      _hoverDay = null;
    }
  }

  bool get _rangeMode => widget.onRangeChanged != null;

  bool get _rangeInProgress =>
      _rangeMode && widget.range != null && !widget.range!.isComplete;

  @override
  void dispose() {
    _gridNode.dispose();
    super.dispose();
  }

  bool _disabled(DateTime day) =>
      (widget.firstDate != null && day.isBefore(_dayOnly(widget.firstDate!))) ||
      (widget.lastDate != null && day.isAfter(_dayOnly(widget.lastDate!)));

  bool _canStep(int months) {
    final DateTime target = DateTime(_month.year, _month.month + months);
    return (widget.firstDate == null ||
            !target.isBefore(_monthOf(widget.firstDate!))) &&
        (widget.lastDate == null ||
            !target.isAfter(_monthOf(widget.lastDate!)));
  }

  void _step(int months) {
    if (_canStep(months)) _moveMonth(months);
  }

  void _moveMonth(int months) {
    final DateTime target = DateTime(
      _focusedDay.year,
      _focusedDay.month + months,
    );
    final int lastDay = DateTime(target.year, target.month + 1, 0).day;
    _focusDay(
      DateTime(
        target.year,
        target.month,
        _focusedDay.day > lastDay ? lastDay : _focusedDay.day,
      ),
    );
  }

  void _focusDay(DateTime day) {
    setState(() {
      _focusedDay = _clampDay(day);
      _month = _monthOf(_focusedDay);
      _hoverDay = null;
    });
  }

  void _activate(DateTime day) {
    if (_disabled(day)) {
      return;
    }
    _focusDay(day);
    _gridNode.requestFocus();
    if (!_rangeMode) {
      widget.onChanged!(day);
      return;
    }
    final CarbonDateRange? range = widget.range;
    // The flatpickr machine: no range, a completed range, or an earlier day
    // restarts with a new start; a later (or equal) day completes it.
    if (range == null || range.isComplete || day.isBefore(range.start)) {
      widget.onRangeChanged!(CarbonDateRange(day));
    } else {
      widget.onRangeChanged!(CarbonDateRange(range.start, day));
    }
  }

  void _moveFocus(int days) {
    // Calendar arithmetic preserves civil days across daylight-saving changes.
    _focusDay(
      DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day + days),
    );
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
        _moveFocus(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _moveFocus(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _moveFocus(7);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveFocus(-7);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageUp:
        _moveMonth(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageDown:
        _moveMonth(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _activate(_focusedDay);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (widget.onEscape != null) {
          widget.onEscape!();
          return KeyEventResult.handled;
        }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final DateTime today = _dayOnly(DateTime.now());
    final int firstWeekday = DateTime(_month.year, _month.month).weekday % 7;
    final int daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return ColoredBox(
      color: layer.layer,
      child: Padding(
        padding: const EdgeInsets.all(CarbonSpacing.spacing05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Month / year header with prev/next.
            Row(
              children: <Widget>[
                _NavArrow(
                  icon: CarbonIcons.chevronLeft,
                  label: 'Previous month',
                  onTap: _canStep(-1) ? () => _step(-1) : null,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_months[_month.month - 1]} ${_month.year}',
                      style: CarbonTypeStyles.headingCompact01.copyWith(
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                ),
                _NavArrow(
                  icon: CarbonIcons.chevronRight,
                  label: 'Next month',
                  onTap: _canStep(1) ? () => _step(1) : null,
                ),
              ],
            ),
            const SizedBox(height: CarbonSpacing.spacing03),
            Row(
              children: <Widget>[
                for (final String w in _weekdays)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        w,
                        style: CarbonTypeStyles.label01.copyWith(
                          color: theme.textHelper,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Focus(
              focusNode: _gridNode,
              includeSemantics: false,
              autofocus: widget.autofocus,
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _gridFocused = f),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int week = 0; week < 6; week++)
                    Row(
                      children: <Widget>[
                        for (int wd = 0; wd < 7; wd++)
                          _dayCell(
                            theme,
                            today,
                            firstWeekday,
                            daysInMonth,
                            week * 7 + wd,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(
    CarbonThemeData theme,
    DateTime today,
    int firstWeekday,
    int daysInMonth,
    int slot,
  ) {
    final int dayNum = slot - firstWeekday + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(width: 40, height: 40);
    }
    final DateTime day = DateTime(_month.year, _month.month, dayNum);
    final bool disabled = _disabled(day);

    final CarbonDateRange? range = widget.range;
    final DateTime? start = range == null ? null : _dayOnly(range.start);
    final DateTime? end = range?.end == null ? null : _dayOnly(range!.end!);
    // The preview end while a range is in progress: the hovered day, or the
    // keyboard-focused day when the grid has focus.
    final DateTime? preview = !_rangeInProgress
        ? null
        : _hoverDay ?? (_gridFocused ? _focusedDay : null);
    final DateTime? bandEnd =
        end ?? (preview != null && !preview.isBefore(start!) ? preview : null);

    final bool selected = _rangeMode
        ? day == start || day == end
        : widget.value != null && _dayOnly(widget.value!) == day;
    final bool inRange =
        start != null &&
        bandEnd != null &&
        day.isAfter(start) &&
        day.isBefore(bandEnd);
    final bool previewEnd =
        preview != null && day == preview && day != start && end == null;

    return _DayCell(
      day: dayNum,
      selected: selected,
      inRange: inRange,
      previewEnd: previewEnd,
      focused: _gridFocused && day == _focusedDay,
      focusable: !disabled && day == _focusedDay,
      isToday: day == today,
      disabled: disabled,
      onTap: disabled ? null : () => _activate(day),
      onFocus: disabled
          ? null
          : () {
              _focusDay(day);
              _gridNode.requestFocus();
            },
      onHover: (bool hovered) =>
          setState(() => _hoverDay = hovered && !disabled ? day : null),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final CarbonIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 40,
            child: Center(
              child: CarbonIcon(
                icon,
                color: onTap == null ? theme.iconDisabled : theme.iconPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.inRange,
    required this.previewEnd,
    required this.focused,
    required this.focusable,
    required this.isToday,
    required this.disabled,
    required this.onTap,
    required this.onFocus,
    required this.onHover,
  });

  final int day;
  final bool selected;
  final bool inRange;
  final bool previewEnd;
  final bool focused;
  final bool focusable;
  final bool isToday;
  final bool disabled;
  final VoidCallback? onTap;
  final VoidCallback? onFocus;
  final ValueChanged<bool> onHover;

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    // Day fills per _flatpickr.scss: committed ends on button-primary,
    // in-range days on the highlight token, the preview end on layer-01,
    // hover on the layer-hover token.
    final Color background = widget.selected
        ? theme.buttonPrimary
        : widget.previewEnd
        ? theme.layer01
        : widget.inRange
        ? theme.highlight
        : _hovered && !widget.disabled
        ? layer.layerHover
        : const Color(0x00000000);
    final Color text = widget.disabled
        ? theme.textDisabled
        : widget.selected
        ? theme.textOnColor
        : theme.textPrimary;
    // The 2px focus outline marks both the keyboard-focused day and the
    // range preview end (focus-outline('outline')).
    final bool outlined = widget.previewEnd || widget.focused;

    return Semantics(
      button: !widget.disabled,
      selected: widget.selected,
      enabled: !widget.disabled,
      focusable: widget.focusable,
      focused: widget.focused,
      label: '${widget.day}',
      onTap: widget.onTap,
      onFocus: widget.onFocus,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          onEnter: (_) {
            setState(() => _hovered = true);
            widget.onHover(true);
          },
          onExit: (_) {
            setState(() => _hovered = false);
            widget.onHover(false);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: SizedBox.square(
              dimension: 40,
              child: Container(
                color: background,
                foregroundDecoration: outlined
                    ? BoxDecoration(
                        border: Border.all(color: theme.focus, width: 2),
                      )
                    : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Text(
                      '${widget.day}',
                      style: CarbonTypeStyles.bodyCompact01.copyWith(
                        color: text,
                      ),
                    ),
                    // The today marker — a small dot beneath the number.
                    if (widget.isToday && !widget.selected)
                      Positioned(
                        bottom: 6,
                        child: SizedBox.square(
                          dimension: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.linkPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
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
}

/// A Carbon date picker: a field that opens a [CarbonCalendar].
///
/// ```dart
/// CarbonDatePicker(
///   labelText: 'Date',
///   value: _date,
///   onChanged: (DateTime d) => setState(() => _date = d),
/// )
/// ```
///
/// See the [forms pattern](https://github.com/sunderee/carbide/blob/master/docs/patterns/forms.md#disabled-and-read-only-controls)
/// for the shared disabled and read-only contract.
class CarbonDatePicker extends StatefulWidget {
  /// Creates a date picker.
  const CarbonDatePicker({
    required this.labelText,
    required this.onChanged,
    super.key,
    this.value,
    this.firstDate,
    this.lastDate,
    this.placeholder = 'mm/dd/yyyy',
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.readOnly = false,
    this.readOnlyHint = CarbonControlState.defaultReadOnlyHint,
    this.invalid = false,
    this.invalidText,
    this.helperText,
    this.aiLabel,
    this.aiRevert = false,
    this.fluid = false,
  });

  /// The field label.
  final String labelText;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in the
  /// field per upstream's `decorator` prop; adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// The fluid treatment (`_fluid-date-picker.scss`): a 64px field with the
  /// label rendered inside above the value.
  final bool fluid;

  /// The selected date.
  final DateTime? value;

  /// Called with the picked date.
  final ValueChanged<DateTime> onChanged;

  /// The earliest selectable date.
  final DateTime? firstDate;

  /// The latest selectable date.
  final DateTime? lastDate;

  /// The placeholder shown when empty.
  final String placeholder;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether disabled.
  final bool disabled;

  /// Keeps the value focusable while preventing editing and popup activation.
  final bool readOnly;

  /// The localizable announcement for read-only mode.
  final String readOnlyHint;

  /// Whether invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Helper text.
  final String? helperText;

  @override
  State<CarbonDatePicker> createState() => _CarbonDatePickerState();
}

String _format(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/'
    '${d.day.toString().padLeft(2, '0')}/${d.year}';

void _returnPickerFocus(
  FocusNode? opener, {
  required bool deferred,
  required bool Function() allowed,
}) {
  final FocusNode? previous = FocusManager.instance.primaryFocus;
  final bool inCalendar =
      previous?.context?.findAncestorWidgetOfExactType<CarbonCalendar>() !=
      null;
  void restore() {
    if (!allowed()) return;
    final FocusNode? current = FocusManager.instance.primaryFocus;
    if (!deferred ||
        current == null ||
        current is FocusScopeNode ||
        (inCalendar && identical(previous, current))) {
      opener?.requestFocus();
    }
  }

  // TapRegion closes on pointer down. Let the outside target take focus
  // before deciding whether the opener still needs a focus return.
  if (deferred) {
    WidgetsBinding.instance.addPostFrameCallback((_) => restore());
  } else {
    restore();
  }
}

class _CarbonDatePickerState extends State<CarbonDatePicker> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  CarbonControlState get _controlState => CarbonControlState.resolve(
    hasCallback: true,
    disabled: widget.disabled,
    readOnly: widget.readOnly,
  );

  bool _open = false;
  final Object _group = UniqueKey();
  final FocusNode _focus = FocusNode(debugLabel: 'CarbonDatePicker');

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(CarbonDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_controlState.canActivate && _open) _closeAndRefocus();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  /// Enter/Space open the calendar from the focused trigger (WAI-ARIA
  /// date-picker dialog pattern via `date-picker/accessibility.mdx`).
  ///
  /// The popup owns a separate focus scope, so the grid takes focus even
  /// when the trigger or another control already holds it.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_controlState.canActivate || _open || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      setState(() => _open = true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _toggle() {
    if (!mounted || !_controlState.canActivate) return;
    if (_open) {
      _closeAndRefocus();
    } else {
      setState(() => _open = true);
    }
  }

  /// Closes the calendar and returns keyboard focus to the trigger, per
  /// the WAI-ARIA dialog pattern ("Escape: closes the dialog and returns
  /// focus"; choosing a date does the same).
  void _closeAndRefocus({bool deferred = false}) {
    if (!mounted || !_open) return;
    setState(() => _open = false);
    _returnPickerFocus(
      _focus,
      deferred: deferred,
      allowed: () => mounted && _controlState.canFocus && !_open,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget trigger = CarbonPopover(
      open: _open,
      align: CarbonPopoverAlignment.bottomStart,
      caret: false,
      tapRegionGroupId: _group,
      onRequestClose: () => _closeAndRefocus(deferred: true),
      content: FocusScope(
        debugLabel: 'CarbonDatePicker.calendar',
        autofocus: true,
        includeSemantics: false,
        child: CarbonCalendar(
          value: widget.value,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          autofocus: true,
          onEscape: _closeAndRefocus,
          onChanged: (DateTime d) {
            if (!mounted || !_open || !_controlState.canActivate) return;
            // End the session before notifying, matching range commits.
            _closeAndRefocus();
            widget.onChanged(d);
          },
        ),
      ),
      child: TapRegion(
        groupId: _group,
        child: _PickerTriggerSemantics(
          focusNode: _focus,
          state: _controlState,
          readOnlyHint: widget.readOnlyHint,
          recoverFocus: !_open,
          label: widget.labelText,
          value: widget.value != null ? _format(widget.value!) : null,
          child: Focus(
            focusNode: _focus,
            includeSemantics: false,
            canRequestFocus: _controlState.canFocus,
            onKeyEvent: _onKey,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _controlState.canActivate ? _toggle : null,
              child: _DateField(
                size: widget.size,
                disabled: _controlState.isDisabled,
                readOnly: _controlState.isReadOnly,
                invalid: widget.invalid,
                focused: _focus.hasFocus,
                text: widget.value == null ? null : _format(widget.value!),
                placeholder: widget.placeholder,
                aiLabel: widget.aiLabel,
                aiRevert: widget.aiRevert,
                fluidLabel: _fluid ? widget.labelText : null,
              ),
            ),
          ),
        ),
      ),
    );

    final Widget? message = widget.invalid && widget.invalidText != null
        ? CarbonFieldRequirement(widget.invalidText!)
        : widget.helperText != null
        ? CarbonHelperText(widget.helperText!, disabled: widget.disabled)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!_fluid)
          ExcludeSemantics(
            child: CarbonFormLabel(widget.labelText, disabled: widget.disabled),
          ),
        trigger,
        ?message,
      ],
    );
  }
}

/// A Carbon date range picker: two fields sharing one range [CarbonCalendar].
///
/// The calendar keeps the flatpickr machine: picking a day starts the range
/// (the popover stays open), picking a later day completes it (the popover
/// closes), picking an earlier day restarts it. Edits remain a local draft
/// until both endpoints are picked; [onChanged] fires once with the completed
/// range. Escape, outside dismissal, trigger toggles and disabling discard
/// the draft and restore the pre-open value, including null, without calling
/// [onChanged]. Completion and Escape return focus to the enabled opener.
/// Outside dismissal preserves a newly focused target or returns focus to
/// the opener when the calendar still owns it. A new external [value]
/// rebases an open session; an unchanged
/// parent rebuild preserves the draft.
///
/// ```dart
/// CarbonDateRangePicker(
///   value: _range,
///   onChanged: (CarbonDateRange r) => setState(() => _range = r),
/// )
/// ```
///
/// See the [forms pattern](https://github.com/sunderee/carbide/blob/master/docs/patterns/forms.md#disabled-and-read-only-controls)
/// for the shared disabled and read-only contract.
class CarbonDateRangePicker extends StatefulWidget {
  /// Creates a date range picker.
  const CarbonDateRangePicker({
    required this.onChanged,
    super.key,
    this.value,
    this.startLabelText = 'Start date',
    this.endLabelText = 'End date',
    this.firstDate,
    this.lastDate,
    this.placeholder = 'mm/dd/yyyy',
    this.size = CarbonFieldSize.md,
    this.disabled = false,
    this.readOnly = false,
    this.readOnlyHint = CarbonControlState.defaultReadOnlyHint,
    this.invalid = false,
    this.invalidText,
    this.helperText,
    this.aiLabel,
    this.aiRevert = false,
    this.fluid = false,
  });

  /// The selected range; null when nothing has been picked.
  final CarbonDateRange? value;

  /// Called once when a complete range is committed.
  ///
  /// Picking or restarting a start date only changes the local draft.
  /// Cancellation never calls this callback.
  final ValueChanged<CarbonDateRange> onChanged;

  /// The label above the start field.
  final String startLabelText;

  /// The label above the end field.
  final String endLabelText;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in the
  /// field per upstream's `decorator` prop; adds the AI aura treatment.
  final Widget? aiLabel;

  /// Suppresses the aura while the AI label shows its revert control.
  final bool aiRevert;

  /// The fluid treatment (`_fluid-date-picker.scss`): a 64px field with the
  /// label rendered inside above the value.
  final bool fluid;

  /// The earliest selectable date.
  final DateTime? firstDate;

  /// The latest selectable date.
  final DateTime? lastDate;

  /// The placeholder shown in an empty field.
  final String placeholder;

  /// The field size.
  final CarbonFieldSize size;

  /// Whether disabled.
  final bool disabled;

  /// Keeps the value focusable while preventing editing and popup activation.
  final bool readOnly;

  /// The localizable announcement for read-only mode.
  final String readOnlyHint;

  /// Whether invalid.
  final bool invalid;

  /// The error message.
  final String? invalidText;

  /// Helper text.
  final String? helperText;

  @override
  State<CarbonDateRangePicker> createState() => _CarbonDateRangePickerState();
}

class _RangeSession {
  _RangeSession(this.snapshot) : draft = snapshot;
  final CarbonDateRange? snapshot;
  CarbonDateRange? draft;
}

class _CarbonDateRangePickerState extends State<CarbonDateRangePicker> {
  /// The effective fluid flag: the widget's own, or an enclosing
  /// [CarbonFluidForm] scope.
  bool get _fluid => widget.fluid || CarbonFluidForm.of(context);

  CarbonControlState get _controlState => CarbonControlState.resolve(
    hasCallback: true,
    disabled: widget.disabled,
    readOnly: widget.readOnly,
  );

  _RangeSession? _session;
  bool get _open => _session != null;
  final Object _group = UniqueKey();
  final FocusNode _startFocus = FocusNode(
    debugLabel: 'CarbonDateRangePicker.start',
  );
  final FocusNode _endFocus = FocusNode(
    debugLabel: 'CarbonDateRangePicker.end',
  );

  /// The field that opened the calendar; Escape returns focus to it.
  FocusNode? _opener;

  /// The two range inputs are a fixed 143.5px wide with a 1px gap
  /// (`_date-picker.scss` `--date-picker--range`).
  static const double _inputWidth = 143.5;

  @override
  void initState() {
    super.initState();
    _startFocus.addListener(_rebuild);
    _endFocus.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(CarbonDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_controlState.canActivate && _open) {
      _cancel(_session);
    } else if (_open && widget.value != oldWidget.value) {
      _session = _sessionFor(widget.value);
    } else if (_session?.draft case final CarbonDateRange draft) {
      if (!_validDraft(draft)) _session!.draft = null;
    }
  }

  bool _validDraft(CarbonDateRange range) {
    bool inside(DateTime day) =>
        (widget.firstDate == null ||
            !_dayOnly(day).isBefore(_dayOnly(widget.firstDate!))) &&
        (widget.lastDate == null ||
            !_dayOnly(day).isAfter(_dayOnly(widget.lastDate!)));
    return inside(range.start) &&
        (range.end == null ||
            (inside(range.end!) &&
                !_dayOnly(range.end!).isBefore(_dayOnly(range.start))));
  }

  _RangeSession _sessionFor(CarbonDateRange? snapshot) {
    final _RangeSession session = _RangeSession(snapshot);
    if (snapshot != null && !_validDraft(snapshot)) session.draft = null;
    return session;
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _startFocus.removeListener(_rebuild);
    _endFocus.removeListener(_rebuild);
    _startFocus.dispose();
    _endFocus.dispose();
    super.dispose();
  }

  void _toggle(FocusNode opener) {
    if (!mounted || !_controlState.canActivate) {
      return;
    }
    if (_open) {
      _cancel(_session);
      return;
    }
    setState(() {
      _session = _sessionFor(widget.value);
      _opener = opener;
    });
  }

  void _cancel(_RangeSession? session, {bool deferred = false}) {
    if (!mounted || session == null || !identical(session, _session)) return;
    // The caller's value is the snapshot: draft edits never changed it.
    setState(() => _session = null);
    _returnPickerFocus(
      _opener,
      deferred: deferred,
      allowed: () => mounted && _controlState.canFocus && !_open,
    );
  }

  void _changeDraft(_RangeSession? session, CarbonDateRange range) {
    if (!mounted ||
        !_controlState.canActivate ||
        session == null ||
        !identical(session, _session) ||
        !_validDraft(range)) {
      return;
    }
    if (range.isComplete) {
      // End the session before notifying, so duplicate/late events cannot
      // commit again even when the controlled caller rejects the value.
      setState(() => _session = null);
      widget.onChanged(range);
      _opener?.requestFocus();
    } else {
      setState(() => session.draft = range);
    }
  }

  /// Enter/Space open the shared calendar from either focused field.
  /// Its separate focus scope lets the grid take focus on every opening.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_controlState.canActivate || _open || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _toggle(node);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _labelledField(String label, DateTime? date, FocusNode focus) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!_fluid)
            // The label opens the calendar too (upstream's label-for);
            // excluded from semantics so the labelled field node below
            // stays the only actionable one.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              onTap: _controlState.canActivate ? () => _toggle(focus) : null,
              child: ExcludeSemantics(
                child: CarbonFormLabel(label, disabled: widget.disabled),
              ),
            ),
          _PickerTriggerSemantics(
            focusNode: focus,
            state: _controlState,
            readOnlyHint: widget.readOnlyHint,
            recoverFocus: !_open,
            label: label,
            value: date == null ? null : _format(date),
            child: Focus(
              focusNode: focus,
              includeSemantics: false,
              canRequestFocus: _controlState.canFocus,
              onKeyEvent: _onKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _controlState.canActivate ? () => _toggle(focus) : null,
                child: SizedBox(
                  width: _inputWidth,
                  child: _DateField(
                    size: widget.size,
                    disabled: _controlState.isDisabled,
                    readOnly: _controlState.isReadOnly,
                    invalid: widget.invalid,
                    focused: focus.hasFocus,
                    text: date == null ? null : _format(date),
                    placeholder: widget.placeholder,
                    aiLabel: widget.aiLabel,
                    aiRevert: widget.aiRevert,
                    fluidLabel: _fluid ? label : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final _RangeSession? session = _session;
    final CarbonDateRange? displayed = session == null
        ? widget.value
        : session.draft;
    final Widget fields = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _labelledField(widget.startLabelText, displayed?.start, _startFocus),
        const SizedBox(width: 1),
        _labelledField(widget.endLabelText, displayed?.end, _endFocus),
      ],
    );

    final Widget trigger = CarbonPopover(
      open: _open,
      align: CarbonPopoverAlignment.bottomStart,
      caret: false,
      tapRegionGroupId: _group,
      onRequestClose: () => _cancel(session, deferred: true),
      content: FocusScope(
        debugLabel: 'CarbonDateRangePicker.calendar',
        autofocus: true,
        includeSemantics: false,
        child: CarbonCalendar(
          range: displayed,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          autofocus: true,
          onEscape: () => _cancel(session),
          onRangeChanged: (CarbonDateRange range) =>
              _changeDraft(session, range),
        ),
      ),
      child: TapRegion(groupId: _group, child: fields),
    );

    final Widget? message = widget.invalid && widget.invalidText != null
        ? CarbonFieldRequirement(widget.invalidText!)
        : widget.helperText != null
        ? CarbonHelperText(widget.helperText!, disabled: widget.disabled)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[trigger, ?message],
    );
  }
}

int _nextPickerControlId = 0;

/// Keeps the opener's native focus when the popup changes DOM reading order.
class _PickerTriggerSemantics extends StatefulWidget {
  const _PickerTriggerSemantics({
    required this.focusNode,
    required this.state,
    required this.readOnlyHint,
    required this.recoverFocus,
    required this.label,
    required this.value,
    required this.child,
  });

  final FocusNode focusNode;
  final CarbonControlState state;
  final String readOnlyHint;
  final bool recoverFocus;
  final String label;
  final String? value;
  final Widget child;

  @override
  State<_PickerTriggerSemantics> createState() =>
      _PickerTriggerSemanticsState();
}

class _PickerTriggerSemanticsState extends State<_PickerTriggerSemantics> {
  Timer? _nativeFocusTimer;
  late final String _identifier =
      'carbon-date-picker-control-${_nextPickerControlId++}';

  @override
  void dispose() {
    _nativeFocusTimer?.cancel();
    super.dispose();
  }

  void _requestFocus() {
    if (mounted && widget.state.canFocus) widget.focusNode.requestFocus();
  }

  void _scheduleNativeFocusRestore(bool Function()? nativeRestore) {
    if (!mounted) return;
    _nativeFocusTimer?.cancel();
    // Let the engine finish any view-focus update caused by a DOM move.
    _nativeFocusTimer = Timer(Duration.zero, () {
      if (!mounted || !widget.state.canFocus || !widget.recoverFocus) return;
      final FocusNode? current = FocusManager.instance.primaryFocus;
      if (current != widget.focusNode &&
          current != FocusManager.instance.rootScope) {
        return;
      }
      if (nativeRestore?.call() ?? restoreNativeControlFocus(_identifier)) {
        _requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb &&
        widget.state.canFocus &&
        widget.recoverFocus &&
        widget.focusNode.hasPrimaryFocus) {
      final bool Function()? nativeRestore = widget.state.isReadOnly
          ? captureReadOnlyControlFocus(_identifier)
          : null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduleNativeFocusRestore(nativeRestore);
        // Popover hides its OverlayPortal after the triggering frame. Its DOM
        // reading order changes in the next frame without rebuilding this
        // trigger. Reconcile there too; both checks respect another control.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scheduleNativeFocusRestore(nativeRestore),
        );
      });
    }
    return Semantics(
      container: true,
      identifier: _identifier,
      button: true,
      enabled: widget.state.canActivate,
      hint: widget.state.semanticsHint(widget.readOnlyHint),
      focusable: widget.state.canFocus,
      focused: widget.state.canFocus ? widget.focusNode.hasFocus : null,
      onFocus: widget.state.canFocus ? _requestFocus : null,
      label: widget.label,
      value: widget.value,
      child: widget.child,
    );
  }
}

/// The shared read-only field chrome of the date pickers.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.size,
    required this.disabled,
    this.readOnly = false,
    required this.invalid,
    required this.text,
    required this.placeholder,
    this.focused = false,
    this.aiLabel,
    this.aiRevert = false,
    this.fluidLabel,
  });

  final CarbonFieldSize size;
  final bool disabled;
  final bool readOnly;
  final bool invalid;
  final bool focused;
  final String? text;
  final String placeholder;
  final Widget? aiLabel;
  final bool aiRevert;

  /// When set, renders the 64px fluid field with this label inside
  /// (`_fluid-date-picker.scss`, the house fluid column).
  final String? fluidLabel;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Color textColor = disabled
        ? theme.textDisabled
        : text == null
        ? theme.textPlaceholder
        : theme.textPrimary;
    return CarbonField(
      size: size,
      disabled: disabled,
      readOnly: readOnly,
      status: invalid ? CarbonFieldStatus.invalid : CarbonFieldStatus.none,
      focused: focused,
      aiLabel: aiLabel,
      aiRevert: aiRevert,
      fluid: fluidLabel != null,
      trailing: Padding(
        padding: const EdgeInsetsDirectional.only(end: CarbonSpacing.spacing05),
        child: CarbonIcon(
          CarbonIcons.calendar,
          color: disabled || readOnly ? theme.iconDisabled : theme.iconPrimary,
        ),
      ),
      child: ExcludeSemantics(
        child: fluidLabel == null
            ? Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  text ?? placeholder,
                  style: CarbonTypeStyles.bodyCompact01.copyWith(
                    color: textColor,
                  ),
                ),
              )
            // Fluid stacks the label-01 label above the value (the house
            // fluid column shared with the other fluid fields).
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    fluidLabel!,
                    style: CarbonTypeStyles.label01.copyWith(
                      color: disabled
                          ? theme.textDisabled
                          : theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text ?? placeholder,
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
