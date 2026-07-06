// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
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

    testWidgets('keyboard focus draws the 2px pill focus border', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonChatButton(label: 'Ask', focusNode: node, onPressed: () {}),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CarbonChatButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final BoxDecoration ring =
          container.foregroundDecoration! as BoxDecoration;
      expect((ring.border! as Border).top.color, theme.focus);
      expect((ring.border! as Border).top.width, 2);
      expect(ring.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('a trailing icon renders in the label color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonChatButton(
            label: 'Ask',
            icon: CarbonIcons.arrowRight,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final CarbonIcon icon = tester.widget<CarbonIcon>(
        find.byType(CarbonIcon),
      );
      expect(icon.icon, CarbonIcons.arrowRight);
      expect(icon.color, theme.textOnColor);
    });

    testWidgets('quick action: pressed fill and disabled outline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonChatButton(label: 'Q', quickAction: true, onPressed: () {}),
        ),
      );
      await tester.pumpAndSettle();
      final TestGesture press = await tester.startGesture(
        tester.getCenter(find.byType(CarbonChatButton)),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.chatButtonActive);
      expect(
        tester.widget<Text>(find.text('Q')).style!.color,
        theme.chatButtonTextHover,
      );
      await press.up();
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _host(const CarbonChatButton(label: 'Q', quickAction: true)),
      );
      await tester.pumpAndSettle();
      final BoxDecoration decoration = _decoration(tester);
      expect((decoration.border! as Border).top.color, theme.buttonDisabled);
      expect(
        tester.widget<Text>(find.text('Q')).style!.color,
        theme.buttonDisabled,
      );
    });

    testWidgets('disabled: solid kinds fill, tertiary keeps its border, '
        'ghost keeps none', (WidgetTester tester) async {
      const Color transparent = Color(0x00000000);
      Future<void> pumpDisabled(CarbonButtonKind kind) async {
        await tester.pumpWidget(
          _host(CarbonChatButton(label: 'Ask', kind: kind)),
        );
        await tester.pumpAndSettle();
      }

      await pumpDisabled(CarbonButtonKind.primary);
      expect(_decoration(tester).color, theme.buttonDisabled);
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.textOnColorDisabled,
      );

      await pumpDisabled(CarbonButtonKind.tertiary);
      expect(_decoration(tester).color, transparent);
      expect(
        (_decoration(tester).border! as Border).top.color,
        theme.buttonDisabled,
      );
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.textDisabled,
      );

      await pumpDisabled(CarbonButtonKind.ghost);
      expect(_decoration(tester).color, transparent);
      expect((_decoration(tester).border! as Border).top.color, transparent);
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.textDisabled,
      );
    });

    testWidgets('rest colors: secondary fill, tertiary outline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonChatButton(
            label: 'Ask',
            kind: CarbonButtonKind.secondary,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.buttonSecondary);
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.textOnColor,
      );

      await tester.pumpWidget(
        _host(
          CarbonChatButton(
            label: 'Ask',
            kind: CarbonButtonKind.tertiary,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, const Color(0x00000000));
      expect(
        (_decoration(tester).border! as Border).top.color,
        theme.buttonTertiary,
      );
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.buttonTertiary,
      );
    });

    testWidgets('hover fills per kind', (WidgetTester tester) async {
      Future<void> pumpKind(CarbonButtonKind kind) async {
        await tester.pumpWidget(
          _host(CarbonChatButton(label: 'Ask', kind: kind, onPressed: () {})),
        );
        await tester.pumpAndSettle();
      }

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);

      await pumpKind(CarbonButtonKind.primary);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CarbonChatButton)),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.buttonPrimaryHover);

      await pumpKind(CarbonButtonKind.secondary);
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.buttonSecondaryHover);

      await pumpKind(CarbonButtonKind.tertiary);
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.buttonTertiaryHover);
      expect(
        (_decoration(tester).border! as Border).top.color,
        theme.buttonTertiary,
      );
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.textInverse,
      );

      await pumpKind(CarbonButtonKind.ghost);
      await tester.pumpAndSettle();
      expect(_decoration(tester).color, theme.backgroundHover);
      expect(
        tester.widget<Text>(find.text('Ask')).style!.color,
        theme.linkPrimaryHover,
      );
    });

    testWidgets('pressed fills per kind', (WidgetTester tester) async {
      Future<void> pressAndExpect(CarbonButtonKind kind, Color color) async {
        await tester.pumpWidget(
          _host(CarbonChatButton(label: 'Ask', kind: kind, onPressed: () {})),
        );
        await tester.pumpAndSettle();
        final TestGesture press = await tester.startGesture(
          tester.getCenter(find.byType(CarbonChatButton)),
        );
        await tester.pumpAndSettle();
        expect(_decoration(tester).color, color, reason: '$kind');
        await press.up();
        await tester.pumpAndSettle();
      }

      await pressAndExpect(CarbonButtonKind.primary, theme.buttonPrimaryActive);
      await pressAndExpect(
        CarbonButtonKind.secondary,
        theme.buttonSecondaryActive,
      );
      await pressAndExpect(
        CarbonButtonKind.tertiary,
        theme.buttonTertiaryActive,
      );
      await pressAndExpect(CarbonButtonKind.ghost, theme.backgroundActive);
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

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonChatButton(label: 'Ask a question', onPressed: () {})),
      );
      await tester.pumpAndSettle();
      // The default lg pill is 48px tall (`_chat-button.scss` lg); the
      // sm/md variants (32/40px) stay ungated by design.
      await expectA11y(tester);
      handle.dispose();
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
