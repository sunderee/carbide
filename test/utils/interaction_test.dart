// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Set<WidgetState> states;

  // Hover and focus highlights only show in "traditional" highlight mode. A
  // real mouse/keyboard flips the mode; synthetic test input does not, so force
  // it for deterministic hover/focus assertions.
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Widget build({
    bool enabled = true,
    VoidCallback? onPressed,
    FocusNode? focusNode,
  }) {
    states = <WidgetState>{};
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: CarbonInteraction(
          enabled: enabled,
          onPressed: onPressed,
          focusNode: focusNode,
          builder: (BuildContext context, Set<WidgetState> current) {
            states = current;
            return const SizedBox(width: 60, height: 40);
          },
        ),
      ),
    );
  }

  testWidgets('reports pressed on tap-down and clears on release', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(build(onPressed: () {}));
    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(CarbonInteraction)),
    );
    await tester.pump();
    expect(states, contains(WidgetState.pressed));

    await gesture.up();
    await tester.pump();
    expect(states, isNot(contains(WidgetState.pressed)));
  });

  testWidgets('reports hovered while a mouse is over it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(build(onPressed: () {}));
    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(
      location: tester.getCenter(find.byType(CarbonInteraction)),
    );
    addTearDown(mouse.removePointer);
    await tester.pumpAndSettle();
    expect(states, contains(WidgetState.hovered));

    await mouse.moveTo(const Offset(500, 500));
    await tester.pumpAndSettle();
    expect(states, isNot(contains(WidgetState.hovered)));
  });

  testWidgets('reports focused for keyboard focus highlight', (
    WidgetTester tester,
  ) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(build(onPressed: () {}, focusNode: node));
    node.requestFocus();
    await tester.pump();
    expect(states, contains(WidgetState.focused));
  });

  testWidgets('calls onPressed on tap and keyboard activation', (
    WidgetTester tester,
  ) async {
    int pressed = 0;
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);

    await tester.pumpWidget(build(onPressed: () => pressed++, focusNode: node));

    await tester.tap(find.byType(CarbonInteraction));
    expect(pressed, 1);

    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(pressed, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(pressed, 3);
  });

  testWidgets('disabled reports the disabled state and ignores input', (
    WidgetTester tester,
  ) async {
    int pressed = 0;
    await tester.pumpWidget(build(enabled: false, onPressed: () => pressed++));

    expect(states, contains(WidgetState.disabled));

    await tester.tap(find.byType(CarbonInteraction));
    await tester.pump();
    expect(pressed, 0);
    expect(states, isNot(contains(WidgetState.pressed)));
  });
}
