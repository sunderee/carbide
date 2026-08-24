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

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
  ),
);

const List<CarbonSwitch> _switches = <CarbonSwitch>[
  CarbonSwitch(text: 'All'),
  CarbonSwitch(text: 'Archived'),
  CarbonSwitch(text: 'Spam', disabled: true),
  CarbonSwitch(text: 'Drafts'),
];

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('motion', () {
    testWidgets('selection transition tokens', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      // `_content-switcher.scss` cites no transition tokens; Carbide uses
      // fast-01 × standard-productive for this micro-interaction.
      final AnimatedDefaultTextStyle segment = tester.widget(
        find.byType(AnimatedDefaultTextStyle).first,
      );
      expect(segment.duration, CarbonDuration.fast01);
      expect(segment.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion is instant', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: CarbonContentSwitcher(switches: _switches),
          ),
        ),
      );
      expect(
        tester
            .widget<AnimatedDefaultTextStyle>(
              find.byType(AnimatedDefaultTextStyle).first,
            )
            .duration,
        Duration.zero,
      );
    });
  });

  Color segmentColor(WidgetTester tester, String label) =>
      (tester
                  .widget<Container>(
                    find
                        .ancestor(
                          of: find.text(label),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration)
          .color!;

  group('selection', () {
    testWidgets('first selected; selected fills the inverse token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      expect(segmentColor(tester, 'All'), theme.layerSelectedInverse);
      expect(
        tester.widget<Text>(find.text('All')).style!.color,
        theme.textInverse,
      );
      expect(segmentColor(tester, 'Archived'), const Color(0x00000000));
    });

    testWidgets('tapping selects a segment', (WidgetTester tester) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          CarbonContentSwitcher(
            switches: _switches,
            onChanged: (int i) => changed = i,
          ),
        ),
      );
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();
      expect(changed, 1);
      expect(segmentColor(tester, 'Archived'), theme.layerSelectedInverse);
    });

    testWidgets('disabled segment does not select', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      await tester.tap(find.text('Spam'));
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Spam'), const Color(0x00000000));
      expect(segmentColor(tester, 'All'), theme.layerSelectedInverse);
    });

    testWidgets('a switch requires text or an icon', (
      WidgetTester tester,
    ) async {
      expect(() => CarbonSwitch(), throwsAssertionError);
    });

    testWidgets('hover fills layerHover and darkens the label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('Archived')));
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Archived'), theme.layerHover01);
      expect(
        tester.widget<Text>(find.text('Archived')).style!.color,
        theme.textPrimary,
      );
      // Leaving the segment clears the hover fill.
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Archived'), const Color(0x00000000));
    });

    testWidgets('shrinking the switch list resets an out-of-range selection', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Drafts'), theme.layerSelectedInverse);
      await tester.pumpWidget(
        _host(
          const CarbonContentSwitcher(
            switches: <CarbonSwitch>[
              CarbonSwitch(text: 'All'),
              CarbonSwitch(text: 'Archived'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'All'), theme.layerSelectedInverse);
    });

    testWidgets('icon-only and icon+text segments render icons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonContentSwitcher(
            switches: <CarbonSwitch>[
              CarbonSwitch(icon: CarbonIcons.add),
              CarbonSwitch(text: 'Both', icon: CarbonIcons.add),
            ],
          ),
        ),
      );
      expect(find.byType(CarbonIcon), findsNWidgets(2));
      expect(find.text('Both'), findsOneWidget);
      // The selected icon-only segment paints the inverse foreground.
      expect(
        tester.widget<CarbonIcon>(find.byType(CarbonIcon).first).color,
        theme.textInverse,
      );
    });

    testWidgets('controlled selectedIndex + onChanged', (
      WidgetTester tester,
    ) async {
      int? changed;
      await tester.pumpWidget(
        _host(
          CarbonContentSwitcher(
            switches: _switches,
            selectedIndex: 1,
            onChanged: (int i) => changed = i,
          ),
        ),
      );
      expect(segmentColor(tester, 'Archived'), theme.layerSelectedInverse);
      await tester.tap(find.text('Drafts'));
      await tester.pumpAndSettle();
      expect(changed, 3);
      // Controlled: stays on 'Archived' until the parent updates.
      expect(segmentColor(tester, 'Archived'), theme.layerSelectedInverse);
    });
  });

  group('keyboard roving', () {
    testWidgets('Right/Left + Home/End select, skipping disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      tester
          .widget<Focus>(
            find
                .ancestor(of: find.text('All'), matching: find.byType(Focus))
                .first,
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Archived'), theme.layerSelectedInverse);
      // Right skips the disabled 'Spam' and lands on 'Drafts'.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Drafts'), theme.layerSelectedInverse);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'All'), theme.layerSelectedInverse);
    });

    testWidgets('End selects the last enabled; Left wraps and skips disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      tester
          .widget<Focus>(
            find
                .ancestor(of: find.text('All'), matching: find.byType(Focus))
                .first,
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Drafts'), theme.layerSelectedInverse);
      // Left skips the disabled 'Spam' and lands on 'Archived'.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(segmentColor(tester, 'Archived'), theme.layerSelectedInverse);
    });
  });

  group('semantics', () {
    testWidgets('segments are exclusive-group buttons with selected state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonContentSwitcher(switches: _switches)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('All')),
        isSemantics(
          label: 'All',
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          isSelected: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md switcher is 40px (_content-switcher.scss layout.use('size',
      // $default: 'md')) — below the 48dp android guideline, so pump the
      // real lg (48px) variant instead.
      await tester.pumpWidget(
        _host(
          const CarbonContentSwitcher(
            switches: _switches,
            size: CarbonFieldSize.lg,
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('content switcher across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'content_switcher',
        containsText: true,
        size: const Size(360, 80),
        builder: (BuildContext context) =>
            const Center(child: CarbonContentSwitcher(switches: _switches)),
      );
    });
  });
}
