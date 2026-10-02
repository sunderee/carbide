// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 320, child: child)),
  ),
);

/// The field's background/border box is the innermost DecoratedBox (an error
/// ring, when present, wraps it as a foreground decoration).
BoxDecoration _fieldBox(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(CarbonField),
                    matching: find.byType(DecoratedBox),
                  )
                  .last,
            )
            .decoration
        as BoxDecoration;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('text primitives (_form.scss)', () {
    testWidgets('label: label-01 / text-secondary / 8px bottom; disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonFormLabel('Name')));
      final Text text = tester.widget<Text>(find.text('Name'));
      expect(text.style!.fontSize, CarbonTypeStyles.label01.fontSize);
      expect(text.style!.color, theme.textSecondary);
      final Padding pad = tester.widget<Padding>(
        find.ancestor(of: find.text('Name'), matching: find.byType(Padding)),
      );
      expect(pad.padding, const EdgeInsets.only(bottom: 8));

      await tester.pumpWidget(
        _host(const CarbonFormLabel('Name', disabled: true)),
      );
      expect(
        tester.widget<Text>(find.text('Name')).style!.color,
        theme.textDisabled,
      );
    });

    testWidgets('helper: helper-text-01 / text-helper / 4px top', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonHelperText('Optional')));
      final Text text = tester.widget<Text>(find.text('Optional'));
      expect(text.style!.fontSize, CarbonTypeStyles.helperText01.fontSize);
      expect(text.style!.color, theme.textHelper);
      final Padding pad = tester.widget<Padding>(
        find.ancestor(
          of: find.text('Optional'),
          matching: find.byType(Padding),
        ),
      );
      expect(pad.padding, const EdgeInsets.only(top: 4));
    });

    testWidgets('requirement: error→text-error, warn→text-primary, live', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonFieldRequirement('Required field')),
      );
      expect(
        tester.widget<Text>(find.text('Required field')).style!.color,
        theme.textError,
      );
      expect(
        tester.getSemantics(find.text('Required field')),
        isSemantics(isLiveRegion: true),
      );

      await tester.pumpWidget(
        _host(
          const CarbonFieldRequirement(
            'Heads up',
            status: CarbonFieldStatus.warning,
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Heads up')).style!.color,
        theme.textPrimary,
      );
      handle.dispose();
    });
  });

  group('field surface (_text-input.scss)', () {
    testWidgets('heights per size; 1px border-strong bottom border', (
      WidgetTester tester,
    ) async {
      for (final (CarbonFieldSize size, double height)
          in <(CarbonFieldSize, double)>[
            (CarbonFieldSize.sm, 32),
            (CarbonFieldSize.md, 40),
            (CarbonFieldSize.lg, 48),
          ]) {
        await tester.pumpWidget(
          _host(CarbonField(size: size, child: const Text('v'))),
        );
        expect(
          tester.getSize(find.byType(CarbonField)).height,
          height,
          reason: '$size',
        );
      }
      final Border border = _fieldBox(tester).border! as Border;
      // The 1px rest border width is spec-locked, not just its colour.
      expect(border.bottom.width, 1);
      expect(border.bottom.color, theme.borderStrong01);
      expect(border.top, BorderSide.none);
    });

    testWidgets('background is the contextual field token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonField(child: Text('v'))));
      expect(_fieldBox(tester).color, theme.field01);

      await tester.pumpWidget(
        _host(const CarbonLayer(child: CarbonField(child: Text('v')))),
      );
      expect(_fieldBox(tester).color, theme.field02);
    });

    testWidgets('disabled: field bg + transparent bottom border', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonField(disabled: true, child: Text('v'))),
      );
      final Border border = _fieldBox(tester).border! as Border;
      expect(_fieldBox(tester).color, theme.field01);
      expect(border.bottom.color, const Color(0x00000000));
    });

    testWidgets('read-only: transparent bg + border-subtle bottom border', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonField(readOnly: true, child: Text('v'))),
      );
      final Border border = _fieldBox(tester).border! as Border;
      expect(_fieldBox(tester).color, const Color(0x00000000));
      // At the root layer the contextual border-subtle is borderSubtle00
      // (the documented layer offset).
      expect(border.bottom.color, theme.borderSubtle00);
    });

    testWidgets('invalid: 2px error ring + ErrorFilled in support-error', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonField(
            status: CarbonFieldStatus.invalid,
            child: Text('v'),
          ),
        ),
      );
      // The error ring is the foreground DecoratedBox (the bg box is .last).
      final BoxDecoration ring =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(CarbonField),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect((ring.border! as Border).top.width, 2);
      expect((ring.border! as Border).top.color, theme.supportError);
      final CarbonIconPainter icon =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(CarbonIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as CarbonIconPainter;
      expect(icon.color, theme.supportError);
    });

    testWidgets('warning: WarningAltFilled, border stays border-strong', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonField(
            status: CarbonFieldStatus.warning,
            child: Text('v'),
          ),
        ),
      );
      final Border border = _fieldBox(tester).border! as Border;
      expect(border.bottom.color, theme.borderStrong01);
      final CarbonIconPainter icon =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(CarbonIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as CarbonIconPainter;
      expect(icon.color, theme.supportWarning);
    });

    testWidgets('focused draws the inset focus ring and wins over invalid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonField(
            focused: true,
            status: CarbonFieldStatus.invalid,
            child: Text('v'),
          ),
        ),
      );
      // Focus ring present (its CustomPaint is the outer one; the error
      // icon paints a second CustomPaint deeper in).
      final CustomPaint ring = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CarbonFocusRing),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(ring.foregroundPainter, isNotNull);
      // The error wrapper remains mounted, but paints no error border while
      // focused. Keeping it mounted preserves the child's editor state.
      expect(
        find.descendant(
          of: find.byType(CarbonField),
          matching: find.byWidgetPredicate(
            (Widget widget) =>
                widget is DecoratedBox &&
                widget.position == DecorationPosition.foreground &&
                (widget.decoration as BoxDecoration).border != null,
          ),
        ),
        findsNothing,
      );
    });
  });

  group('FormGroup', () {
    testWidgets('legend label-01 / text-secondary + group semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonFormGroup(legend: 'Contact', child: Text('fields'))),
      );
      final Text legend = tester.widget<Text>(find.text('Contact'));
      expect(legend.style!.fontSize, CarbonTypeStyles.label01.fontSize);
      expect(legend.style!.color, theme.textSecondary);
      expect(find.bySemanticsLabel('Contact'), findsOneWidget);
      handle.dispose();
    });
  });

  group('traversal order (#226)', () {
    testWidgets('reads legend, then the labelled field, then helper text', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonFormGroup(
            legend: 'Contact',
            child: CarbonTextInput(
              labelText: 'Name',
              helperText: 'Your full name',
            ),
          ),
        ),
      );
      final List<String> labels = <String>[
        for (final SemanticsNode node
            in tester.semantics.simulatedAccessibilityTraversal())
          if (node.label.isNotEmpty) node.label,
      ];
      // The visible CarbonFormLabel is folded into the text field's own
      // semantic label, so the field node itself reads 'Name'.
      expect(
        labels,
        containsAllInOrder(<String>['Contact', 'Name', 'Your full name']),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('form item (label + field + helper) across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'form_item',
        containsText: true,
        size: const Size(320, 130),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 280,
            child: CarbonFormItem(
              children: <Widget>[
                const CarbonFormLabel('Label'),
                CarbonField(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'Input value',
                      style: CarbonTypeStyles.bodyCompact01.copyWith(
                        color: CarbonTheme.of(context).textPrimary,
                      ),
                    ),
                  ),
                ),
                const CarbonHelperText('Helper text'),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('field states across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'field_states',
        containsText: true,
        size: const Size(320, 340),
        builder: (BuildContext context) {
          Widget value() => Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'Value',
              style: CarbonTypeStyles.bodyCompact01.copyWith(
                color: CarbonTheme.of(context).textPrimary,
              ),
            ),
          );
          return Center(
            child: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonField(child: value()),
                  const SizedBox(height: 12),
                  CarbonField(focused: true, child: value()),
                  const SizedBox(height: 12),
                  CarbonField(
                    status: CarbonFieldStatus.invalid,
                    child: value(),
                  ),
                  const SizedBox(height: 12),
                  CarbonField(
                    status: CarbonFieldStatus.warning,
                    child: value(),
                  ),
                  const SizedBox(height: 12),
                  CarbonField(disabled: true, child: value()),
                  const SizedBox(height: 12),
                  CarbonField(readOnly: true, child: value()),
                ],
              ),
            ),
          );
        },
      );
    });
  });
}
