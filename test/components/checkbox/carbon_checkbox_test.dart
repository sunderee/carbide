// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

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
    child: Center(child: SizedBox(width: 260, child: child)),
  ),
);

Finder _box = find.descendant(
  of: find.byType(CarbonCheckbox),
  matching: find.byType(CustomPaint),
);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('spec locks (_checkbox.scss)', () {
    testWidgets('16px box; label body-compact-01 at the 20px offset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonCheckbox(label: 'Subscribe', value: false, onChanged: (_) {}),
        ),
      );
      expect(tester.getSize(_box.first), const Size(16, 16));
      final double offset =
          tester.getTopLeft(find.text('Subscribe')).dx -
          tester.getTopLeft(find.byType(CarbonCheckbox)).dx;
      expect(offset, 20);
      final Text label = tester.widget<Text>(find.text('Subscribe'));
      expect(label.style!.fontSize, CarbonTypeStyles.bodyCompact01.fontSize);
      expect(label.style!.color, theme.textPrimary);
    });

    testWidgets('disabled greys the label', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonCheckbox(label: 'X', value: true, onChanged: null)),
      );
      expect(
        tester.widget<Text>(find.text('X')).style!.color,
        theme.textDisabled,
      );
    });
  });

  group('interaction', () {
    testWidgets('tap and Space toggle; disabled is inert', (
      WidgetTester tester,
    ) async {
      bool? changed;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonCheckbox(
            label: 'A',
            value: false,
            focusNode: node,
            onChanged: (bool v) => changed = v,
          ),
        ),
      );
      await tester.tap(find.byType(CarbonCheckbox));
      expect(changed, isTrue);

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(changed, isTrue);

      changed = null;
      await tester.pumpWidget(
        _host(const CarbonCheckbox(label: 'A', value: false, onChanged: null)),
      );
      await tester.tap(find.byType(CarbonCheckbox));
      expect(changed, isNull);
    });
  });

  group('bounded-row centering (#262)', () {
    testWidgets('a labeled checkbox stays content-height in a bounded, '
        'taller parent', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 64,
            child: Container(
              alignment: AlignmentDirectional.centerStart,
              child: const CarbonCheckbox(label: 'Read', value: true),
            ),
          ),
        ),
      );
      // The Align inside the label layout must not inflate to fill the row
      // (it used to, pinning the box to the top of list-box menu rows).
      final Size checkbox = tester.getSize(find.byType(CarbonCheckbox));
      expect(checkbox.height, lessThan(32));
      expect(
        tester.getCenter(find.byType(CarbonCheckbox)).dy,
        moreOrLessEquals(
          tester.getCenter(find.byType(Container)).dy,
          epsilon: 1,
        ),
      );
    });
  });

  group('semantics (tri-state)', () {
    testWidgets('unchecked / checked / indeterminate(mixed)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonCheckbox(label: 'Opt', value: false, onChanged: (_) {})),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Opt')),
        isSemantics(label: 'Opt', hasCheckedState: true, isChecked: false),
      );

      await tester.pumpWidget(
        _host(CarbonCheckbox(label: 'Opt', value: true, onChanged: (_) {})),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Opt')),
        isSemantics(isChecked: true),
      );

      await tester.pumpWidget(
        _host(
          CarbonCheckbox(
            label: 'Opt',
            value: false,
            indeterminate: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Opt')),
        isSemantics(isCheckStateMixed: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonCheckbox(label: 'Subscribe', value: false, onChanged: (_) {}),
        ),
      );
      // The row is label-height (~24px) around a 16px box (`_checkbox.scss`
      // `block-size: convert.to-rem(16px)`), so the 48dp android guideline
      // is unattainable at the default size.
      // a11y-exception: https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/styles/scss/components/checkbox/_checkbox.scss
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('CarbonCheckboxGroup', () {
    testWidgets('legend + invalid/warn/helper message precedence', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonCheckboxGroup(
            legend: 'Toppings',
            invalid: true,
            invalidText: 'Pick at least one',
            helperText: 'Optional',
            children: <Widget>[
              CarbonCheckbox(label: 'Cheese', value: false, onChanged: (_) {}),
              CarbonCheckbox(label: 'Olives', value: true, onChanged: (_) {}),
            ],
          ),
        ),
      );
      expect(find.text('Toppings'), findsOneWidget);
      // Invalid wins over helper.
      expect(find.text('Pick at least one'), findsOneWidget);
      expect(find.text('Optional'), findsNothing);
      expect(
        tester.widget<Text>(find.text('Pick at least one')).style!.color,
        theme.textError,
      );
    });
  });

  group('goldens', () {
    testWidgets('states across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'checkbox_states',
        containsText: true,
        size: const Size(220, 200),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonCheckbox(
                label: 'Unchecked',
                value: false,
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              CarbonCheckbox(label: 'Checked', value: true, onChanged: (_) {}),
              const SizedBox(height: 8),
              CarbonCheckbox(
                label: 'Indeterminate',
                value: false,
                indeterminate: true,
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              CarbonCheckbox(
                label: 'Invalid',
                value: true,
                invalid: true,
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              const CarbonCheckbox(
                label: 'Disabled',
                value: true,
                onChanged: null,
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
        name: 'checkbox_focus',
        containsText: true,
        size: const Size(220, 60),
        builder: (BuildContext context) => Center(
          child: CarbonCheckbox(
            label: 'Focused',
            value: true,
            focusNode: node,
            onChanged: (_) {},
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
