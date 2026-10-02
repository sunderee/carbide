// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

const List<CarbonProgressStep> _steps = <CarbonProgressStep>[
  CarbonProgressStep(label: 'Account'),
  CarbonProgressStep(label: 'Details', secondaryLabel: 'Optional'),
  CarbonProgressStep(label: 'Problem', invalid: true),
  CarbonProgressStep(label: 'Review'),
  CarbonProgressStep(label: 'Locked', disabled: true),
];

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('states', () {
    testWidgets('labels render; complete + invalid glyphs by state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonProgressIndicator(steps: _steps, currentIndex: 1)),
      );
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);

      // A complete step (index 0) shows the CheckmarkOutline.
      final bool hasCheck = tester
          .widgetList<CarbonIcon>(find.byType(CarbonIcon))
          .any((CarbonIcon i) => i.icon == CarbonIcons.checkmarkOutline);
      expect(hasCheck, isTrue);
      // The invalid step's label is in support-error.
      expect(
        tester.widget<Text>(find.text('Problem')).style!.color,
        theme.supportError,
      );
      // The disabled step's label is greyed.
      expect(
        tester.widget<Text>(find.text('Locked')).style!.color,
        theme.textDisabled,
      );
    });
  });

  group('interactive', () {
    testWidgets('tapping a step reports its index; disabled is inert', (
      WidgetTester tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        _host(
          CarbonProgressIndicator(
            steps: _steps,
            currentIndex: 1,
            interactive: true,
            onStepSelected: (int i) => selected = i,
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      expect(selected, 3);
      selected = null;
      await tester.tap(find.text('Locked'));
      expect(selected, isNull);
    });

    testWidgets('non-interactive steps do not report taps', (
      WidgetTester tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        _host(
          CarbonProgressIndicator(
            steps: _steps,
            currentIndex: 1,
            onStepSelected: (int i) => selected = i,
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      expect(selected, isNull);
    });
  });

  group('semantics', () {
    testWidgets('steps expose labels; current is selected', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonProgressIndicator(steps: _steps, currentIndex: 1)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Details')),
        isSemantics(label: 'Details', isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Account')),
        isSemantics(label: 'Account', isSelected: false),
      );
      handle.dispose();
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonProgressIndicator(
            steps: _steps,
            currentIndex: 1,
            interactive: true,
            onStepSelected: (_) {},
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('interactive horizontal and vertical focus across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'progress_indicator_interactive',
        containsText: true,
        size: const Size(560, 440),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonProgressIndicator(
                steps: _steps,
                currentIndex: 1,
                interactive: true,
                onStepSelected: (_) {},
              ),
              const SizedBox(height: 32),
              CarbonProgressIndicator(
                steps: _steps,
                currentIndex: 1,
                vertical: true,
                interactive: true,
                onStepSelected: (_) {},
              ),
            ],
          ),
        ),
        afterPump: (WidgetTester tester) async {
          Focus.of(tester.element(find.text('Account').first)).requestFocus();
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('horizontal + vertical across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'progress_indicator',
        containsText: true,
        size: const Size(560, 400),
        builder: (BuildContext context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonProgressIndicator(steps: _steps, currentIndex: 1),
              SizedBox(height: 32),
              CarbonProgressIndicator(
                steps: _steps,
                currentIndex: 1,
                vertical: true,
              ),
            ],
          ),
        ),
      );
    });
  });
}
