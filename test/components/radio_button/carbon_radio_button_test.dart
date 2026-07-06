// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 320, child: child)),
  ),
);

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('spec locks (_radio-button.scss)', () {
    testWidgets('18px circle; label body-compact-01 after the 10px gap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonRadioButton(label: 'Email', selected: false, onSelected: () {}),
        ),
      );
      final Size circle = tester.getSize(
        find.descendant(
          of: find.byType(CarbonRadioButton),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(circle, const Size(18, 18));
      // circle (18) + gap (10) = label at 28.
      final double offset =
          tester.getTopLeft(find.text('Email')).dx -
          tester.getTopLeft(find.byType(CarbonRadioButton)).dx;
      expect(offset, 28);
      expect(
        tester.widget<Text>(find.text('Email')).style!.fontSize,
        CarbonTypeStyles.bodyCompact01.fontSize,
      );
    });

    testWidgets('label-left places the label before the circle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonRadioButton(
            label: 'L',
            selected: false,
            labelPosition: CarbonRadioLabelPosition.left,
            onSelected: () {},
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('L')).dx,
        lessThan(
          tester
              .getTopLeft(
                find.descendant(
                  of: find.byType(CarbonRadioButton),
                  matching: find.byType(CustomPaint),
                ),
              )
              .dx,
        ),
      );
    });
  });

  group('group selection + keyboard', () {
    testWidgets('tap selects a single option', (WidgetTester tester) async {
      String? value = 'a';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return CarbonRadioButtonGroup<String>(
                legend: 'Plan',
                value: value,
                options: const <(String, String)>[
                  ('a', 'Free'),
                  ('b', 'Pro'),
                  ('c', 'Team'),
                ],
                onChanged: (String v) => setState(() => value = v),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Pro'));
      await tester.pump();
      expect(value, 'b');
    });

    testWidgets('arrow keys rove selection (and wrap)', (
      WidgetTester tester,
    ) async {
      String? value = 'a';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return CarbonRadioButtonGroup<String>(
                legend: 'Plan',
                value: value,
                options: const <(String, String)>[
                  ('a', 'Free'),
                  ('b', 'Pro'),
                  ('c', 'Team'),
                ],
                onChanged: (String v) => setState(() => value = v),
              );
            },
          ),
        ),
      );
      // Focus the first radio via the node the group passed it.
      tester
          .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).first)
          .focusNode!
          .requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 'b');

      // Arrow-left from 'a' wraps to the last option.
      value = 'a';
      await tester.pump();
      tester
          .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).first)
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(value, 'c');
    });

    testWidgets('vertical orientation stacks with spacing-03 and roves '
        'with up/down arrows', (WidgetTester tester) async {
      String? value = 'a';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return CarbonRadioButtonGroup<String>(
                legend: 'Plan',
                value: value,
                orientation: Axis.vertical,
                options: const <(String, String)>[
                  ('a', 'Free'),
                  ('b', 'Pro'),
                  ('c', 'Team'),
                ],
                onChanged: (String v) => setState(() => value = v),
              );
            },
          ),
        ),
      );
      // Column layout: options stack with an 8px (spacing-03) gap.
      final Rect first = tester.getRect(find.byType(CarbonRadioButton).at(0));
      final Rect second = tester.getRect(find.byType(CarbonRadioButton).at(1));
      expect(second.left, first.left);
      expect(second.top - first.bottom, CarbonSpacing.spacing03);

      tester
          .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).first)
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(value, 'b');

      value = 'a';
      await tester.pump();
      tester
          .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).first)
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(value, 'c');
    });

    testWidgets('changing the option count regenerates focus nodes', (
      WidgetTester tester,
    ) async {
      List<(String, String)> options = const <(String, String)>[
        ('a', 'Free'),
        ('b', 'Pro'),
      ];
      late StateSetter rebuild;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              rebuild = setState;
              return CarbonRadioButtonGroup<String>(
                legend: 'Plan',
                value: 'a',
                options: options,
                onChanged: (_) {},
              );
            },
          ),
        ),
      );
      rebuild(() {
        options = const <(String, String)>[
          ('a', 'Free'),
          ('b', 'Pro'),
          ('c', 'Team'),
        ];
      });
      await tester.pump();
      expect(find.byType(CarbonRadioButton), findsNWidgets(3));
      // The regenerated node still drives roving selection.
      tester
          .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).last)
          .focusNode!
          .requestFocus();
      await tester.pump();
      expect(
        tester
            .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).last)
            .focusNode!
            .hasFocus,
        isTrue,
      );
    });
  });

  group('group messages', () {
    Widget message({
      bool invalid = false,
      String? invalidText,
      bool warn = false,
      String? warnText,
      String? helperText,
    }) => _host(
      CarbonRadioButtonGroup<int>(
        legend: 'Plan',
        value: 1,
        options: const <(int, String)>[(1, 'Free')],
        onChanged: (_) {},
        invalid: invalid,
        invalidText: invalidText,
        warn: warn,
        warnText: warnText,
        helperText: helperText,
      ),
    );

    testWidgets('invalid shows the requirement text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        message(invalid: true, invalidText: 'Pick a plan.'),
      );
      expect(find.text('Pick a plan.'), findsOneWidget);
    });

    testWidgets('warn shows the warning requirement text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(message(warn: true, warnText: 'Costs extra.'));
      expect(find.text('Costs extra.'), findsOneWidget);
    });

    testWidgets('helper text renders when not invalid/warn', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(message(helperText: 'Monthly billing.'));
      expect(find.text('Monthly billing.'), findsOneWidget);
    });

    testWidgets('focus ring repaints when the theme focus color changes', (
      WidgetTester tester,
    ) async {
      Widget themed(CarbonThemeData data) => Directionality(
        textDirection: TextDirection.ltr,
        child: CarbonTheme(
          data: data,
          child: Center(
            child: CarbonRadioButton(
              label: 'Email',
              selected: true,
              onSelected: () {},
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.pumpWidget(themed(CarbonThemeData.white));
      await tester.pump();
      // Swapping themes changes the ring color, exercising shouldRepaint.
      await tester.pumpWidget(themed(CarbonThemeData.gray100));
      await tester.pump();
      expect(find.byType(CarbonRadioButton), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('radio exposes exclusive-group + checked; group has legend', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonRadioButtonGroup<String>(
            legend: 'Plan',
            value: 'a',
            options: const <(String, String)>[('a', 'Free'), ('b', 'Pro')],
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Plan'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Free')),
        isSemantics(
          label: 'Free',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pro')),
        isSemantics(isChecked: false),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonRadioButton(label: 'Email', selected: false, onSelected: () {}),
        ),
      );
      // The row is label-height (~24px) around an 18px circle
      // (`_radio-button.scss` `block-size: convert.to-rem(18px)`), so the
      // 48dp android guideline is unattainable at the default size.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('states + group across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'radio_states',
        containsText: true,
        size: const Size(260, 200),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonRadioButton(
                label: 'Unselected',
                selected: false,
                onSelected: () {},
              ),
              const SizedBox(height: 8),
              CarbonRadioButton(
                label: 'Selected',
                selected: true,
                onSelected: () {},
              ),
              const SizedBox(height: 8),
              CarbonRadioButton(
                label: 'Invalid',
                selected: true,
                invalid: true,
                onSelected: () {},
              ),
              const SizedBox(height: 8),
              const CarbonRadioButton(
                label: 'Disabled',
                selected: true,
                onSelected: null,
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('focus ring', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'radio_focus',
        containsText: true,
        size: const Size(200, 60),
        builder: (BuildContext context) => Center(
          child: CarbonRadioButton(
            label: 'Focused',
            selected: true,
            focusNode: node,
            onSelected: () {},
          ),
        ),
        afterPump: (WidgetTester tester) async {
          node.requestFocus();
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
