// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';

const List<CarbonProgressStep> _steps = <CarbonProgressStep>[
  CarbonProgressStep(label: 'Complete'),
  CarbonProgressStep(label: 'Current'),
  CarbonProgressStep(label: 'Invalid', invalid: true),
  CarbonProgressStep(label: 'Incomplete'),
  CarbonProgressStep(label: 'Disabled', disabled: true),
];

void main() {
  for (final bool vertical in <bool>[false, true]) {
    testWidgets('vertical=$vertical AT, Enter and Space activate once', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        final List<int> calls = <int>[];
        await tester.pumpWidget(
          _host(
            CarbonProgressIndicator(
              steps: _steps,
              currentIndex: 1,
              vertical: vertical,
              interactive: true,
              onStepSelected: calls.add,
            ),
          ),
        );
        final SemanticsNode node = tester.getSemantics(
          find.bySemanticsLabel('Current'),
        );
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester.binding.platformDispatcher.onSemanticsActionEvent!(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            nodeId: node.id,
            viewId: tester.view.viewId,
          ),
        );
        await tester.pump();
        expect(calls, <int>[1]);
        Focus.of(tester.element(find.text('Complete'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(calls, <int>[1, 0]);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(calls, <int>[1, 0, 0]);
        Focus.of(tester.element(find.text('Current'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(calls.last, 1);
        await expectA11y(tester);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('vertical=$vertical one node carries each step state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            CarbonProgressIndicator(
              steps: _steps,
              currentIndex: 1,
              vertical: vertical,
              interactive: true,
              onStepSelected: (_) {},
            ),
          ),
        );
        final List<SemanticsNode> nodes = tester.semantics
            .simulatedAccessibilityTraversal()
            .where(
              (SemanticsNode node) => _steps.any(
                (CarbonProgressStep step) => step.label == node.label,
              ),
            )
            .toList();
        expect(nodes, hasLength(5));
        for (int i = 0; i < _steps.length; i++) {
          final SemanticsNode node = tester.getSemantics(
            find.bySemanticsLabel(_steps[i].label),
          );
          expect(
            node.value,
            <String>[
              'Complete',
              'Current',
              'Invalid',
              'Incomplete',
              'Disabled',
            ][i],
          );
          expect(node, isSemantics(isSelected: i == 1, isEnabled: i != 4));
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            i != 4,
          );
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'vertical=$vertical disabled and callback-free steps are inert',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          int calls = 0;
          await tester.pumpWidget(
            _host(
              CarbonProgressIndicator(
                steps: const <CarbonProgressStep>[
                  CarbonProgressStep(label: 'Disabled', disabled: true),
                ],
                currentIndex: 0,
                vertical: vertical,
                interactive: true,
                onStepSelected: (_) => calls++,
              ),
            ),
          );
          expect(
            tester
                .getSemantics(find.bySemanticsLabel('Disabled'))
                .getSemanticsData()
                .hasAction(SemanticsAction.tap),
            isFalse,
          );
          await tester.tap(find.text('Disabled'));
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          expect(calls, 0);
          await tester.pumpWidget(
            _host(
              CarbonProgressIndicator(
                steps: _steps,
                currentIndex: 1,
                vertical: vertical,
                interactive: true,
              ),
            ),
          );
          for (final CarbonProgressStep step in _steps) {
            final SemanticsData data = tester
                .getSemantics(find.bySemanticsLabel(step.label))
                .getSemanticsData();
            expect(data.flagsCollection.isButton, isFalse);
            expect(data.hasAction(SemanticsAction.tap), isFalse);
          }
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('vertical=$vertical focus ring follows input highlight mode', (
      WidgetTester tester,
    ) async {
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      await tester.pumpWidget(
        _host(
          CarbonProgressIndicator(
            steps: _steps,
            currentIndex: 1,
            vertical: vertical,
            interactive: true,
            onStepSelected: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Current'));
      await tester.pump();
      expect(
        tester
            .widgetList<CarbonFocusRing>(find.byType(CarbonFocusRing))
            .any((CarbonFocusRing ring) => ring.visible),
        isFalse,
      );
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      Focus.of(tester.element(find.text('Current'))).requestFocus();
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<CarbonFocusRing>(find.byType(CarbonFocusRing))
            .any((CarbonFocusRing ring) => ring.visible),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  }
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);
