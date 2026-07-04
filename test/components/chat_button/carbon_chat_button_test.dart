// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<AnimatedContainer>(
              find.descendant(
                of: find.byType(CarbonChatButton),
                matching: find.byType(AnimatedContainer),
              ),
            )
            .decoration!
        as BoxDecoration;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('chat button (_chat-button.scss)', () {
    testWidgets('pill radius and height per size', (WidgetTester tester) async {
      for (final (CarbonChatButtonSize size, double radius)
          in <(CarbonChatButtonSize, double)>[
            (CarbonChatButtonSize.sm, 16),
            (CarbonChatButtonSize.md, 20),
            (CarbonChatButtonSize.lg, 24),
          ]) {
        await tester.pumpWidget(
          _host(CarbonChatButton(label: 'Ask', size: size, onPressed: () {})),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(CarbonChatButton)).height,
          size.height,
          reason: '$size',
        );
        expect(
          _decoration(tester).borderRadius,
          BorderRadius.circular(radius),
          reason: '$size',
        );
      }
    });

    testWidgets('primary kind uses the button tokens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonChatButton(label: 'Ask', onPressed: () {})),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.buttonPrimary);
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.textOnColor,
      );
    });

    testWidgets('quick action: outline rest, hover fill, selected state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonChatButton(
            label: 'Summarize',
            quickAction: true,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      BoxDecoration decoration = _decoration(tester);
      expect((decoration.border! as Border).top.color, theme.chatButton);
      expect(
        tester.widget<Text>(find.text('Summarize')).style!.color,
        theme.chatButton,
      );

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Summarize')));
      await tester.pumpAndSettle();
      decoration = _decoration(tester);
      expect(decoration.color, theme.chatButtonHover);
      expect(
        tester.widget<Text>(find.text('Summarize')).style!.color,
        theme.chatButtonTextHover,
      );
    });

    testWidgets('selected survives disabling (--quick-action--selected)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonChatButton(
            label: 'Summarize',
            quickAction: true,
            isSelected: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.chatButtonSelected);
      expect(
        tester.widget<Text>(find.text('Summarize')).style!.color,
        theme.chatButtonTextSelected,
      );
    });

    testWidgets('activation, semantics, and the kind/selected asserts', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int presses = 0;
      await tester.pumpWidget(
        _host(
          CarbonChatButton(
            label: 'Ask',
            quickAction: true,
            isSelected: true,
            onPressed: () => presses++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CarbonChatButton));
      expect(presses, 1);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ask')),
        isSemantics(label: 'Ask', isButton: true, isSelected: true),
      );
      handle.dispose();

      expect(
        () => CarbonChatButton(label: 'x', kind: CarbonButtonKind.danger),
        throwsAssertionError,
      );
      expect(
        () => CarbonChatButton(label: 'x', isSelected: true),
        throwsAssertionError,
      );
    });
  });

  group('AI skeletons (_ai-skeleton-styles.scss)', () {
    testWidgets('shapes: line heights, icon, placeholder, paragraph', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonAISkeletonText(),
                CarbonAISkeletonText(heading: true),
                CarbonAISkeletonIcon(),
                CarbonAISkeletonPlaceholder(),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(find.byType(CarbonAISkeletonText).first).height,
        16,
      );
      expect(tester.getSize(find.byType(CarbonAISkeletonText).last).height, 24);
      expect(
        tester.getSize(find.byType(CarbonAISkeletonIcon)),
        const Size(16, 16),
      );
      expect(
        tester.getSize(find.byType(CarbonAISkeletonPlaceholder)),
        const Size(100, 100),
      );
    });

    testWidgets('the fill uses the ai-skeleton tokens; reduced motion is '
        'static', (WidgetTester tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: CarbonTheme(
              data: CarbonThemeData.white,
              child: const Center(
                child: SizedBox(width: 200, child: CarbonAISkeletonText()),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              (w.decoration as BoxDecoration?)?.color ==
                  CarbonThemeData.white.aiSkeletonBackground,
        ),
        findsOneWidget,
      );
      // No sweeping band under reduced motion.
      expect(find.byType(FractionalTranslation), findsNothing);
    });
  });

  group('goldens', () {
    testWidgets('chat buttons across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'chat_button',
        containsText: true,
        size: const Size(420, 220),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonChatButton(label: 'Ask a question', onPressed: () {}),
                  const SizedBox(width: 12),
                  CarbonChatButton(
                    label: 'Ghost',
                    kind: CarbonButtonKind.ghost,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonChatButton(
                    label: 'Quick action',
                    quickAction: true,
                    size: CarbonChatButtonSize.sm,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  CarbonChatButton(
                    label: 'Selected',
                    quickAction: true,
                    isSelected: true,
                    size: CarbonChatButtonSize.sm,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('AI skeletons across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'ai_skeleton',
        containsText: false,
        size: const Size(280, 200),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 240,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                CarbonAISkeletonText(paragraph: true),
                SizedBox(height: 16),
                CarbonAISkeletonPlaceholder(width: 80, height: 80),
              ],
            ),
          ),
        ),
        // A deterministic mid-sweep frame of the 1250ms shimmer.
        pumpBeforeSnapshot: const Duration(milliseconds: 300),
      );
    });
  });
}
