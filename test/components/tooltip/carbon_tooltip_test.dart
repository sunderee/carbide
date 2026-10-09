// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/overlay_entries.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        managedOverlayEntry(
          builder: (BuildContext context) => Center(child: child),
        ),
      ],
    ),
  ),
);

/// A focusable trigger so the tooltip's focus path can be exercised.
Widget _trigger(FocusNode node) => Focus(
  focusNode: node,
  child: const SizedBox(
    width: 40,
    height: 40,
    child: ColoredBox(color: Color(0xFF8A3FFC)),
  ),
);

void main() {
  testWidgets(
    'Escape stays dismissed through ancestor parking and trigger repair',
    (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      final FocusNode other = FocusNode();
      final FocusScopeNode scope = FocusScopeNode();
      addTearDown(node.dispose);
      addTearDown(other.dispose);
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        _host(
          FocusScope(
            node: scope,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonTooltip(label: 'Information', child: _trigger(node)),
                _trigger(other),
              ],
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Information'), findsNothing);
      node.unfocus();
      await tester.pumpAndSettle();
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Information'), findsNothing);
      other.requestFocus();
      await tester.pumpAndSettle();
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Information'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'visibility callback coordinates changes without duplicate events',
    (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      final List<bool> changes = <bool>[];
      await tester.pumpWidget(
        _host(
          CarbonTooltip(
            label: 'Information',
            onOpenChanged: changes.add,
            child: _trigger(node),
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(changes, <bool>[true]);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(changes, <bool>[true]);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(changes, <bool>[true, false]);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(changes, <bool>[true, false]);
    },
  );

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('hover', () {
    testWidgets('shows after the enter delay, hides after the leave delay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTooltip(
            label: 'Duplicate',
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(CarbonTooltip)));
      await tester.pump();
      // Not yet — still within the 100ms enter delay.
      expect(find.text('Duplicate'), findsNothing);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(); // the popover's deferred show renders next frame.
      expect(find.text('Duplicate'), findsOneWidget);

      await gesture.moveTo(const Offset(500, 500));
      await tester.pump();
      // Still shown during the 300ms leave delay.
      expect(find.text('Duplicate'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 320));
      await tester.pump();
      expect(find.text('Duplicate'), findsNothing);
    });
  });

  group('focus + escape', () {
    testWidgets('focus shows immediately; Escape hides', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(CarbonTooltip(label: 'Info', child: _trigger(node))),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Info'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Info'), findsNothing);
    });
  });

  group('semantics + chrome', () {
    testWidgets('trigger exposes the tooltip label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonTooltip(
            label: 'Help',
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.byType(CarbonTooltip))
            .getSemanticsData()
            .tooltip,
        'Help',
      );
      handle.dispose();
    });

    testWidgets('bubble uses the inverse palette', (WidgetTester tester) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(
        _host(
          const CarbonTooltip(
            label: 'Dark',
            defaultOpen: true,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      );
      await tester.pump();
      final BoxDecoration box =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('Dark'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(box.color, theme.backgroundInverse);
      final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Dark'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(style.style.color, theme.textInverse);
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonTooltip(
            label: 'Duplicate',
            defaultOpen: true,
            child: SizedBox(width: 48, height: 48),
          ),
        ),
      );
      await tester.pump();
      // CarbonTooltip is hover/focus-only — it adds no tap handler of its
      // own (the trigger is whatever child the caller wraps), so there is
      // no tappable trigger to size-check. The full gate locks that the
      // open bubble introduces no unlabeled or undersized tap targets.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('motion (#235)', () {
    // Spec source: `_tooltip.scss` defines no transition or animation — the
    // bubble pops in instantly (the enter/leave delays are hover debounce,
    // not motion), so there is nothing to disable under reduced motion.
    testWidgets('shows instantly after the enter delay, with no fade', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(
            const CarbonTooltip(
              label: 'Duplicate',
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byType(CarbonTooltip)));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(); // the popover's deferred show renders next frame.
      expect(find.text('Duplicate'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.byType(FadeTransition), findsNothing);
    });
  });

  group('goldens', () {
    testWidgets('tooltip bubble across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tooltip_bubble',
        containsText: true,
        size: const Size(220, 160),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (BuildContext context) => const Center(
                child: CarbonTooltip(
                  label: 'Duplicate',
                  defaultOpen: true,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: ColoredBox(color: Color(0xFF8A3FFC)),
                  ),
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pump();
        },
      );
    });
  });
}
