// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../test/support/date_localizations.dart';

void main() {
  final parameters = Uri.base.queryParameters;
  final labels = dateLocaleFixtures
      .firstWhere((row) => row.$1 == (parameters['locale'] ?? 'en-US'))
      .$2;
  final theme = switch (parameters['theme']) {
    'g10' => CarbonThemeData.gray10,
    'g90' => CarbonThemeData.gray90,
    'g100' => CarbonThemeData.gray100,
    _ => CarbonThemeData.white,
  };
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    dateLocalizationHost(
      DateLocalizationFixture(
        labels: labels,
        longDates: parameters['long'] == 'true',
        fluid: parameters['fluid'] == 'true',
        empty: parameters['empty'] == 'true',
      ),
      theme: theme,
      direction: parameters['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      scale: double.tryParse(parameters['scale'] ?? '') ?? 1,
    ),
  );
}

Widget dateLocalizationHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) {
  final data = theme ?? CarbonThemeData.white;
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

class DateLocalizationFixture extends StatefulWidget {
  const DateLocalizationFixture({
    required this.labels,
    super.key,
    this.longDates = false,
    this.fluid = false,
    this.empty = false,
  });
  final CarbonDatePickerLocalizations labels;
  final bool longDates, fluid, empty;
  @override
  State<DateLocalizationFixture> createState() =>
      DateLocalizationFixtureState();
}

class DateLocalizationFixtureState extends State<DateLocalizationFixture> {
  late CarbonDatePickerLocalizations base;
  late bool longDates;
  DateTime? date;
  CarbonDateRange? range;
  int singleChanges = 0, rangeChanges = 0;
  CarbonDatePickerLocalizations get labels =>
      longDates &&
          (base.locale.languageCode == 'de' || base.locale.languageCode == 'ja')
      ? longDateLabels(base)
      : base;
  String get dateLabel => switch (base.locale.languageCode) {
    'de' => 'Datum',
    'ja' => '日付',
    'ar' => 'التاريخ',
    _ => 'Date',
  };
  String get fromLabel => switch (base.locale.languageCode) {
    'de' => 'Von',
    'ja' => '開始日',
    'ar' => 'من',
    _ => 'From',
  };
  String get untilLabel => switch (base.locale.languageCode) {
    'de' => 'Bis',
    'ja' => '終了日',
    'ar' => 'إلى',
    _ => 'Until',
  };
  @override
  void initState() {
    super.initState();
    base = widget.labels;
    longDates = widget.longDates;
    if (!widget.empty) {
      date = DateTime(2025, 10, 17);
      range = CarbonDateRange(DateTime(2025, 10, 17), DateTime(2025, 10, 20));
    }
  }

  void updateLabels(CarbonDatePickerLocalizations value) =>
      setState(() => base = value);
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, KeyEvent event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      if (event.logicalKey == LogicalKeyboardKey.f2) {
        final int i = dateLocaleFixtures.indexWhere(
          (row) => row.$2.locale == base.locale,
        );
        updateLabels(
          dateLocaleFixtures[(i + 1) % dateLocaleFixtures.length].$2,
        );
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.f3) {
        setState(() => longDates = !longDates);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              headingLevel: 1,
              child: Text('Localized dates ${base.locale}'),
            ),
            const SizedBox(height: 12),
            Text(
              'Single commits: $singleChanges; range commits: $rangeChanges',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 320,
              child: CarbonDatePicker(
                labelText: dateLabel,
                value: date,
                localizations: labels,
                fluid: widget.fluid,
                onChanged: (DateTime value) => setState(() {
                  date = value;
                  singleChanges++;
                }),
              ),
            ),
            const SizedBox(height: 32),
            CarbonDateRangePicker(
              startLabelText: fromLabel,
              endLabelText: untilLabel,
              value: range,
              localizations: labels,
              fluid: widget.fluid,
              onChanged: (CarbonDateRange value) => setState(() {
                range = value;
                rangeChanges++;
              }),
            ),
            const SizedBox(height: 24),
            const Text(
              'F2 changes locale; F3 toggles the long display format.',
            ),
          ],
        ),
      ),
    ),
  );
}
