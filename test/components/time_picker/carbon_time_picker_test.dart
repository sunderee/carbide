// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

/// The trailing selects mount an OverlayPortal, so the picker needs an Overlay
/// + TapRegionSurface — a real app's scaffold supplies both.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: TapRegionSurface(
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Stack(
                children: <Widget>[
                  Positioned.fill(
                    // Tap-outside backdrop is test scaffolding; keep it out
                    // of the semantics tree so a11y sweeps only see the
                    // picker.
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onTap: () {},
                    ),
                  ),
                  Align(alignment: Alignment.topLeft, child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

List<CarbonSelectEntry<String>> _periods() => const <CarbonSelectEntry<String>>[
  CarbonSelectItem<String>(value: 'AM', label: 'AM'),
  CarbonSelectItem<String>(value: 'PM', label: 'PM'),
];

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('field', () {
    testWidgets('renders the label and placeholder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonTimePicker(labelText: 'Time')));
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('hh:mm'), findsOneWidget);
    });

    testWidgets('typing reports the value', (WidgetTester tester) async {
      String? value;
      await tester.pumpWidget(
        _host(
          CarbonTimePicker(
            labelText: 'Time',
            onChanged: (String v) => value = v,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '09:30');
      await tester.pump();
      expect(value, '09:30');
      // The placeholder hides once there is text.
      expect(find.text('hh:mm'), findsNothing);
    });

    testWidgets('the editable uses the code-02 monospace style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonTimePicker(labelText: 'Time')));
      final TextStyle style = tester
          .widget<EditableText>(find.byType(EditableText))
          .style;
      expect(style.fontFamily, CarbonTypeStyles.code02.fontFamily);
      expect(style.fontSize, 14);
      expect(style.letterSpacing, 0.32);
    });

    double fieldBoxWidth(WidgetTester tester) => tester
        .widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(CarbonField),
                matching: find.byType(SizedBox),
              )
              .first,
        )
        .width!;

    testWidgets('field is 4.875rem wide', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CarbonTimePicker(labelText: 'Time')));
      expect(fieldBoxWidth(tester), CarbonTimePicker.fieldWidth);
    });

    testWidgets('field widens to 6.175rem when invalid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTimePicker(
            labelText: 'Time',
            invalid: true,
            invalidText: 'Invalid time',
          ),
        ),
      );
      expect(fieldBoxWidth(tester), CarbonTimePicker.fieldWidthError);
      expect(find.text('Invalid time'), findsOneWidget);
    });

    testWidgets('exposes a text-field semantics node with the label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonTimePicker(labelText: 'Appointment time')),
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(label: 'Appointment time', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md field is 40px (_time-picker.scss block-size:
      // convert.to-rem(40px)) — below the 48dp android guideline, so pump
      // the real lg (48px) variant instead.
      await tester.pumpWidget(
        _host(
          CarbonTimePicker(
            labelText: 'Time',
            size: CarbonFieldSize.lg,
            children: <Widget>[
              CarbonTimePickerSelect<String>(
                labelText: 'AM/PM',
                value: 'AM',
                size: CarbonFieldSize.lg,
                items: _periods(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('selects', () {
    testWidgets('inline selects render and change value', (
      WidgetTester tester,
    ) async {
      String? period;
      await tester.pumpWidget(
        _host(
          CarbonTimePicker(
            labelText: 'Time',
            children: <Widget>[
              CarbonTimePickerSelect<String>(
                labelText: 'AM/PM',
                value: 'AM',
                items: _periods(),
                onChanged: (String v) => period = v,
              ),
            ],
          ),
        ),
      );
      expect(find.text('AM'), findsOneWidget);
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PM').last);
      await tester.pumpAndSettle();
      expect(period, 'PM');
    });

    testWidgets('a select sits a 2px (spacing-01) gap after the field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonTimePicker(
            labelText: 'Time',
            children: <Widget>[
              CarbonTimePickerSelect<String>(
                labelText: 'AM/PM',
                value: 'AM',
                items: _periods(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      final Padding pad = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byType(CarbonTimePickerSelect<String>),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        (pad.padding.resolve(TextDirection.ltr)).left,
        CarbonSpacing.spacing01,
      );
    });
  });

  group('goldens', () {
    testWidgets('time picker with AM/PM select across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'time_picker',
        containsText: true,
        size: const Size(220, 90),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topLeft,
          child: CarbonTimePicker(
            labelText: 'Time',
            initialValue: '09:30',
            children: <Widget>[
              CarbonTimePickerSelect<String>(
                labelText: 'AM/PM',
                value: 'AM',
                items: _periods(),
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
    });
  });
}
