// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';
import 'support/reduced_motion_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  retainIntegrationFailureDetails(binding);
  for (final direction in TextDirection.values) {
    for (final component in <String>[
      'combo',
      'containedList',
      'link',
      'listBox',
      'multi',
      'search',
      'slider',
      'tree',
      'tabs',
    ]) {
      testWidgets('reduced motion $component $direction (#316)', (
        tester,
      ) async {
        final key = GlobalKey<ReducedMotionFixtureState>();
        final previous = FocusManager.instance.highlightStrategy;
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        TestGesture? mouse;
        try {
          await tester.pumpWidget(
            reducedMotionHost(
              ReducedMotionFixture(key: key, component: component),
              direction: direction,
              reduced: true,
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          switch (component) {
            case 'combo':
            case 'containedList':
            case 'link':
            case 'multi':
              mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
              await mouse.addPointer(location: Offset.zero);
              final Finder target = component == 'containedList'
                  ? find.text('List row')
                  : find.byKey(key.currentState!.subject);
              await mouse.moveTo(tester.getCenter(target));
            case 'listBox':
              await tester.tap(find.text('List box'));
            case 'search':
              key.currentState!.controller.text = 'query';
            case 'slider':
              tester
                  .widget<Focus>(
                    find
                        .descendant(
                          of: find.byType(CarbonSlider),
                          matching: find.byType(Focus),
                        )
                        .first,
                  )
                  .focusNode!
                  .requestFocus();
            case 'tree':
              await tester.tap(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is CarbonIcon &&
                      widget.icon == CarbonIcons.chevronDown,
                ),
              );
            case 'tabs':
              await tester.tap(find.text('Tab 0'));
              await tester.pump();
              await tester.sendKeyEvent(
                LogicalKeyboardKey.end,
                physicalKey: PhysicalKeyboardKey.end,
              );
          }
          await tester.pump();
          await tester.pump();
          final states = key.currentState!.animations;
          if (component != 'tabs') expect(states, isNotEmpty);
          expect(
            states.where((state) => state.animation.status.isAnimating),
            isEmpty,
          );
          if (component == 'tabs') {
            final controller = tester
                .widget<SingleChildScrollView>(
                  find.byType(SingleChildScrollView),
                )
                .controller!;
            expect(controller.offset, controller.position.maxScrollExtent);
            expect(find.text('Panel 11'), findsOneWidget);
          }
          if (component == 'tree') expect(find.text('Child'), findsOneWidget);
          if (component == 'search') {
            expect(
              tester
                  .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
                  .opacity,
              1,
            );
            expect(key.currentState!.controller.text, 'query');
          }
          expect(tester.takeException(), isNull);
        } finally {
          await mouse?.removePointer();
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          FocusManager.instance.highlightStrategy = previous;
        }
      });
    }
  }
}
