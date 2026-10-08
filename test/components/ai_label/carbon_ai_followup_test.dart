// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// The deferred #216/#217 follow-up: the date pickers' AI + fluid slots and
// the modal AI treatment, landed after #241/#243 merged (their files were
// rewritten by those PRs).

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/overlay_entries.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: TapRegionSurface(
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (BuildContext context) => Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(width: 320, child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

Widget _aiLabel() => const CarbonAILabel(size: CarbonAILabelSize.mini);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('date picker AI + fluid (deferred from #216/#217)', () {
    testWidgets('the AI label renders in the field with the aura', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDatePicker(
            labelText: 'Date',
            value: DateTime(2026, 6, 15),
            onChanged: (_) {},
            aiLabel: _aiLabel(),
          ),
        ),
      );
      expect(find.byType(CarbonAILabel), findsOneWidget);
      final BoxDecoration decoration =
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
      expect(decoration.gradient, isNotNull);
      expect((decoration.border! as Border).bottom.color, theme.aiBorderStrong);
    });

    testWidgets('fluid renders the 64px field with the label inside', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDatePicker(
            labelText: 'Date',
            fluid: true,
            value: DateTime(2026, 6, 15),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(CarbonFormLabel), findsNothing);
      expect(tester.getSize(find.byType(CarbonField)).height, 64);
      expect(
        find.descendant(
          of: find.byType(CarbonField),
          matching: find.text('Date'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a CarbonFluidForm flips the range picker to fluid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonFluidForm(
            child: CarbonDateRangePicker(
              value: CarbonDateRange(
                DateTime(2026, 6, 1),
                DateTime(2026, 6, 8),
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(CarbonFormLabel), findsNothing);
      // Both fields select fluid chrome. Chrome's Ahem placeholder makes the
      // date glyph line taller than Plex, so 64px remains a minimum there.
      for (final Element field in find.byType(CarbonField).evaluate()) {
        expect((field.widget as CarbonField).fluid, isTrue);
        expect(
          tester.getSize(find.byWidget(field.widget)).height,
          kIsWeb ? greaterThanOrEqualTo(64) : equals(64),
        );
      }
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('End date'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('modal AI treatment (--modal--decorator)', () {
    testWidgets('ai scrim, aura surface, border, and header label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonModal(
            open: true,
            title: 'Generated summary',
            aiLabel: _aiLabel(),
            passiveModal: true,
            onClose: () {},
            child: const Text('Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The scrim switches to the ai-overlay token.
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is ColoredBox && w.color == theme.aiOverlay,
        ),
        findsOneWidget,
      );
      // The surface takes the aura gradient + ai-border-start border.
      final DecoratedBox surface = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Generated summary'),
              matching: find.byWidgetPredicate(
                (Widget w) =>
                    w is DecoratedBox &&
                    (w.decoration as BoxDecoration?)?.gradient != null,
              ),
            )
            .first,
      );
      final BoxDecoration decoration = surface.decoration as BoxDecoration;
      expect(
        (decoration.gradient! as LinearGradient).colors.first,
        theme.aiAuraStart,
      );
      expect((decoration.border! as Border).top.color, theme.aiBorderStart);
      expect(decoration.boxShadow!.single.color, theme.aiDropShadow);
      expect(find.byType(CarbonAILabel), findsOneWidget);
    });

    testWidgets('aiRevert falls back to the standard treatment', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonModal(
            open: true,
            title: 'Summary',
            aiLabel: _aiLabel(),
            aiRevert: true,
            passiveModal: true,
            onClose: () {},
            child: const Text('Body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is ColoredBox && w.color == theme.overlay,
        ),
        findsOneWidget,
      );
      // The label still renders (only the aura treatment is suppressed).
      expect(find.byType(CarbonAILabel), findsOneWidget);
    });
  });

  group('goldens', () {
    testWidgets('AI + fluid date pickers across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'ai_fluid_date_picker',
        containsText: true,
        size: const Size(360, 220),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CarbonDatePicker(
                  labelText: 'Suggested date',
                  value: DateTime(2026, 6, 15),
                  onChanged: (_) {},
                  aiLabel: _aiLabel(),
                ),
                const SizedBox(height: 16),
                CarbonDatePicker(
                  labelText: 'Fluid date',
                  fluid: true,
                  value: DateTime(2026, 6, 15),
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('AI modal across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'ai_modal',
        containsText: true,
        size: const Size(720, 360),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (BuildContext context) => CarbonModal(
                open: true,
                title: 'Generated summary',
                size: CarbonModalSize.sm,
                aiLabel: _aiLabel(),
                onClose: () {},
                primaryButton: CarbonModalAction(
                  label: 'Accept',
                  onPressed: () {},
                ),
                secondaryButton: CarbonModalAction(
                  label: 'Revert',
                  onPressed: () {},
                ),
                child: const Text(
                  'This summary was generated from the case notes.',
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
