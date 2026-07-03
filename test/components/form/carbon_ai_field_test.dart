// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// The AI decorator surface on the field chrome (#216): the aura gradient
// (`ai-gradient('bottom', 50%)`), the ai-border-strong bottom border, and
// the AI label placement per _text-input.scss / _text-area.scss /
// _number-input.scss.

import 'package:carbide/carbide.dart';
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

Widget _aiLabel() => const CarbonAILabel(size: CarbonAILabelSize.mini);

BoxDecoration _fieldDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(CarbonField),
                    matching: find.byWidgetPredicate(
                      (Widget w) =>
                          w is DecoratedBox &&
                          w.position == DecorationPosition.background,
                    ),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('CarbonField AI chrome (utilities/_ai-gradient.scss)', () {
    testWidgets('the aura gradient and ai-border-strong bottom border', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonField(aiLabel: _aiLabel(), child: const SizedBox.shrink())),
      );
      final BoxDecoration decoration = _fieldDecoration(tester);
      final LinearGradient gradient = decoration.gradient! as LinearGradient;
      // ai-gradient('bottom', 50%): aura-start-sm at the bottom edge,
      // aura-end at 50%, transparent at 100%.
      expect(gradient.begin, Alignment.bottomCenter);
      expect(gradient.colors.first, theme.aiAuraStartSm);
      expect(gradient.colors[2], theme.aiAuraEnd);
      expect(gradient.stops![2], 0.5);
      expect(gradient.colors.last.a, 0);
      expect((decoration.border! as Border).bottom.color, theme.aiBorderStrong);
    });

    testWidgets('revert suppresses the aura; read-only never shows it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonField(
            aiLabel: _aiLabel(),
            aiRevert: true,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      expect(_fieldDecoration(tester).gradient, isNull);
      expect(
        (_fieldDecoration(tester).border! as Border).bottom.color,
        theme.borderStrong01,
      );

      await tester.pumpWidget(
        _host(
          CarbonField(
            aiLabel: _aiLabel(),
            readOnly: true,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      expect(_fieldDecoration(tester).gradient, isNull);
    });

    testWidgets('the gradient stays under invalid (padding-only selectors)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonField(
            aiLabel: _aiLabel(),
            status: CarbonFieldStatus.invalid,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      expect(_fieldDecoration(tester).gradient, isNotNull);
    });

    testWidgets('the AI label sits 16px from the end, after the icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonField(
            aiLabel: _aiLabel(),
            status: CarbonFieldStatus.invalid,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      final Rect field = tester.getRect(find.byType(CarbonField));
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      expect(field.right - label.right, 16);
      // The status icon sits flush before the label.
      final Rect icon = tester.getRect(
        find.byWidgetPredicate(
          (Widget w) => w is CarbonIcon && w.icon == CarbonIcons.errorFilled,
        ),
      );
      expect(icon.right <= label.left, isTrue);
    });
  });

  group('component passthroughs', () {
    testWidgets('text input renders the aura and hosts the label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonTextInput(labelText: 'Prompt', aiLabel: _aiLabel())),
      );
      expect(find.byType(CarbonAILabel), findsOneWidget);
      expect(_fieldDecoration(tester).gradient, isNotNull);
    });

    testWidgets('text area anchors the label at the top end (12/16)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonTextArea(labelText: 'Prompt', aiLabel: _aiLabel())),
      );
      expect(find.byType(CarbonAILabel), findsOneWidget);
      final PositionedDirectional positioned = tester
          .widget<PositionedDirectional>(
            find.ancestor(
              of: find.byType(CarbonAILabel),
              matching: find.byType(PositionedDirectional),
            ),
          );
      expect(positioned.top, 12);
      expect(positioned.end, 16);
    });

    testWidgets('number input places the label before the steppers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonNumberInput(
            labelText: 'Count',
            value: 1,
            onChanged: (_) {},
            aiLabel: _aiLabel(),
          ),
        ),
      );
      expect(find.byType(CarbonAILabel), findsOneWidget);
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      final Rect increment = tester.getRect(
        find
            .byWidgetPredicate(
              (Widget w) => w is CarbonIcon && w.icon == CarbonIcons.add,
            )
            .first,
      );
      expect(label.right <= increment.left, isTrue);
    });
  });

  group('goldens', () {
    testWidgets('AI fields across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'ai_fields',
        containsText: true,
        size: const Size(360, 340),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CarbonTextInput(
                  labelText: 'Prompt',
                  initialValue: 'Generated text',
                  aiLabel: _aiLabel(),
                ),
                const SizedBox(height: 16),
                CarbonNumberInput(
                  labelText: 'Tokens',
                  value: 1024,
                  onChanged: (_) {},
                  aiLabel: _aiLabel(),
                ),
                const SizedBox(height: 16),
                CarbonTextArea(
                  labelText: 'Description',
                  rows: 2,
                  initialValue: 'A generated description.',
                  aiLabel: _aiLabel(),
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}
