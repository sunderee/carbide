// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// Dot-separated policy used by both native and trusted browser contracts.
final CarbonTimeFormat dotTimeFormat = CarbonTimeFormat(
  pattern: 'HH.mm',
  hourCycle: CarbonTimeHourCycle.twentyFourHour,
  formatter: (CarbonTimeValue time) =>
      CarbonTimeFormat.twentyFourHour.format(time).replaceAll(':', '.'),
  parser: (String text, CarbonTimePeriod _) =>
      CarbonTimeFormat.twentyFourHour.tryParse(text.replaceAll('.', ':')),
);

void main() {
  final Map<String, String> parameters = Uri.base.queryParameters;
  final CarbonTimeFormat? format = switch (parameters['mode']) {
    '12' => CarbonTimeFormat.twelveHour,
    'dot' => dotTimeFormat,
    'free' => null,
    _ => CarbonTimeFormat.twentyFourHour,
  };
  final CarbonThemeData theme = switch (parameters['theme']) {
    'g10' => CarbonThemeData.gray10,
    'g90' => CarbonThemeData.gray90,
    'g100' => CarbonThemeData.gray100,
    _ => CarbonThemeData.white,
  };
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    timeCommitHost(
      TimeCommitFixture(
        format: format,
        fluid: parameters['fluid'] == 'true',
        normalize: parameters['normalize'] != 'false',
        initialPeriod: parameters['pm'] == 'true'
            ? CarbonTimePeriod.pm
            : CarbonTimePeriod.am,
      ),
      theme: theme,
      direction: parameters['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      scale: double.tryParse(parameters['scale'] ?? '') ?? 1,
    ),
  );
}

/// A real app host for native editable and selector focus behavior.
Widget timeCommitHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) {
  final CarbonThemeData data = theme ?? CarbonThemeData.white;
  return WidgetsApp(
    color: data.background,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext context, _, _) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: CarbonTheme(
            data: data,
            child: ColoredBox(
              color: data.background,
              child: DefaultTextStyle(
                style: CarbonTypeStyles.body01.copyWith(
                  color: data.textPrimary,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Interactive fixture for the optional time parsing/commit policy.
class TimeCommitFixture extends StatefulWidget {
  /// Creates a policy fixture with an editable draft and independent controls.
  const TimeCommitFixture({
    required this.format,
    super.key,
    this.fluid = false,
    this.normalize = true,
    this.initialPeriod = CarbonTimePeriod.am,
  });

  /// Null preserves permissive typing; other policies commit typed drafts.
  final CarbonTimeFormat? format;

  /// Whether the field and period selector use fluid chrome.
  final bool fluid;

  /// Whether successful commits canonicalize the displayed draft.
  final bool normalize;

  /// The initial period for twelve-hour mode.
  final CarbonTimePeriod initialPeriod;

  @override
  State<TimeCommitFixture> createState() => TimeCommitFixtureState();
}

/// The fixture's observable edits, canonical times, periods and owned nodes.
class TimeCommitFixtureState extends State<TimeCommitFixture> {
  /// Caller-owned text controller used to verify native value synchronization.
  final TextEditingController controller = TextEditingController();

  /// Caller-owned field focus used by native integration contracts.
  final FocusNode focus = FocusNode();

  /// The independent control focus that causes whole-group blur.
  final FocusNode outside = FocusNode();

  /// Successfully displayed commits, or permissive typing notifications.
  final List<String> edits = <String>[];

  /// Successfully committed civil times, including null for cleared input.
  final List<CarbonTimeValue?> times = <CarbonTimeValue?>[];

  /// Changes to the built-in period selector.
  final List<CarbonTimePeriod> periods = <CarbonTimePeriod>[];

  /// Whether the fixture's input is disabled.
  bool disabled = false;

  /// Whether the fixture's input is read-only.
  bool readOnly = false;

  String _zone = 'UTC';

  /// Rebuilds the field's native enabled/read-only contract.
  void configure({bool? disabled, bool? readOnly}) => setState(() {
    this.disabled = disabled ?? this.disabled;
    this.readOnly = readOnly ?? this.readOnly;
  });

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    outside.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(headingLevel: 1, child: const Text('Time commit policy')),
        const SizedBox(height: 16),
        Text(
          'Edits: ${edits.length}; commits: ${times.length}; periods: ${periods.length}',
        ),
        Text(
          'Canonical: ${times.isEmpty || times.last == null ? 'empty' : CarbonTimeFormat.twentyFourHour.format(times.last!)}',
        ),
        const SizedBox(height: 24),
        CarbonTimePicker(
          labelText: 'Time',
          controller: controller,
          focusNode: focus,
          format: widget.format,
          normalizeOnCommit: widget.normalize,
          initialPeriod: widget.initialPeriod,
          fluid: widget.fluid,
          disabled: disabled,
          readOnly: readOnly,
          invalidText: 'Enter a valid time',
          onChanged: (String text) => setState(() => edits.add(text)),
          onCommitted: (CarbonTimeValue? value) =>
              setState(() => times.add(value)),
          onPeriodChanged: (CarbonTimePeriod period) =>
              setState(() => periods.add(period)),
          children: <Widget>[
            CarbonTimePickerSelect<String>(
              labelText: 'Timezone',
              value: _zone,
              width: 112,
              fluid: widget.fluid,
              onChanged: (String zone) => setState(() => _zone = zone),
              items: const <CarbonSelectEntry<String>>[
                CarbonSelectItem<String>(value: 'UTC', label: 'UTC'),
                CarbonSelectItem<String>(value: 'CET', label: 'CET'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        CarbonButton(
          label: 'Outside',
          focusNode: outside,
          onPressed: outside.requestFocus,
        ),
        const SizedBox(height: 16),
        const Text(
          'Enter commits. Tab into AM/PM keeps the draft; choosing a period commits it.',
        ),
      ],
    ),
  );
}
