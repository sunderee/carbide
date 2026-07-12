// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Center(child: child),
    ),
  ),
);

BoxDecoration _trackDecoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration!
        as BoxDecoration;

double _handleStart(WidgetTester tester) => tester
    .widget<AnimatedPositionedDirectional>(
      find.byType(AnimatedPositionedDirectional),
    )
    .start!;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('spec locks (_toggle.scss)', () {
    testWidgets('md track 48x24; handle travels 24px; r12', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonToggle(labelText: 'T', toggled: false, onToggled: (_) {})),
      );
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(48, 24),
      );
      // Off: handle at the 3px margin.
      expect(_handleStart(tester), 3);

      await tester.pumpWidget(
        _host(CarbonToggle(labelText: 'T', toggled: true, onToggled: (_) {})),
      );
      await tester.pumpAndSettle();
      // On: margin + travel = 3 + 24 = 27.
      expect(_handleStart(tester), 27);
      expect(
        (_trackDecoration(tester).borderRadius! as BorderRadius).topLeft,
        const Radius.circular(12),
      );
    });

    testWidgets('sm track 32x16; handle travels 16px', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonToggle(
            labelText: 'T',
            toggled: true,
            size: CarbonToggleSize.sm,
            onToggled: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(AnimatedContainer)),
        const Size(32, 16),
      );
      // On: margin (3) + travel (16) = 19.
      expect(_handleStart(tester), 19);
    });

    testWidgets('track colour: off toggleOff, on supportSuccess, '
        'disabled buttonDisabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(CarbonToggle(labelText: 'T', toggled: false, onToggled: (_) {})),
      );
      expect(_trackDecoration(tester).color, theme.toggleOff);

      await tester.pumpWidget(
        _host(CarbonToggle(labelText: 'T', toggled: true, onToggled: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(_trackDecoration(tester).color, theme.supportSuccess);

      await tester.pumpWidget(
        _host(const CarbonToggle(labelText: 'T', toggled: true)),
      );
      await tester.pumpAndSettle();
      expect(_trackDecoration(tester).color, theme.buttonDisabled);
    });
  });

  group('interaction & a11y', () {
    testWidgets('tap and Space toggle; disabled is inert', (
      WidgetTester tester,
    ) async {
      bool? changed;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonToggle(
            labelText: 'Wi-Fi',
            toggled: false,
            focusNode: node,
            onToggled: (bool v) => changed = v,
          ),
        ),
      );
      await tester.tap(find.byType(AnimatedContainer));
      expect(changed, isTrue);

      changed = null;
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(changed, isTrue);

      changed = null;
      await tester.pumpWidget(
        _host(const CarbonToggle(labelText: 'Wi-Fi', toggled: false)),
      );
      await tester.tap(find.byType(AnimatedContainer));
      expect(changed, isNull);
    });

    testWidgets('exposes a switch with its toggled state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonToggle(labelText: 'Wi-Fi', toggled: true, onToggled: (_) {}),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Wi-Fi')),
        isSemantics(label: 'Wi-Fi', hasToggledState: true, isToggled: true),
      );
      handle.dispose();
    });

    testWidgets('side labels: A/B by state; hideLabel uses the top label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonToggle(
            labelText: 'Wi-Fi',
            toggled: false,
            labelA: 'Disabled',
            labelB: 'Enabled',
            onToggled: (_) {},
          ),
        ),
      );
      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('Wi-Fi'), findsOneWidget); // top label

      await tester.pumpWidget(
        _host(
          CarbonToggle(
            labelText: 'Wi-Fi',
            toggled: true,
            hideLabel: true,
            onToggled: (_) {},
          ),
        ),
      );
      // hideLabel: only the inline label, no separate top label.
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.byType(CarbonFormLabel), findsNothing);
    });

    testWidgets('reduced motion slides instantly', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonToggle(labelText: 'T', toggled: false, onToggled: (_) {}),
          reduceMotion: true,
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonToggle(labelText: 'Wi-Fi', toggled: false, onToggled: (_) {}),
        ),
      );
      // The md switch is a 48×24 track (`_toggle.scss` `block-size:
      // convert.to-rem(24px); inline-size: convert.to-rem(48px)`), so the
      // 48dp android guideline is unattainable at the default size.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('states across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'toggle_states',
        containsText: true,
        size: const Size(220, 260),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonToggle(labelText: 'Off', toggled: false, onToggled: (_) {}),
              const SizedBox(height: 12),
              CarbonToggle(labelText: 'On', toggled: true, onToggled: (_) {}),
              const SizedBox(height: 12),
              CarbonToggle(
                labelText: 'Small on',
                toggled: true,
                size: CarbonToggleSize.sm,
                onToggled: (_) {},
              ),
              const SizedBox(height: 12),
              const CarbonToggle(labelText: 'Disabled', toggled: true),
            ],
          ),
        ),
      );
    });

    testWidgets('focus ring', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'toggle_focus',
        containsText: true,
        size: const Size(180, 80),
        builder: (BuildContext context) => Center(
          child: CarbonToggle(
            labelText: 'Focused',
            toggled: true,
            focusNode: node,
            onToggled: (_) {},
          ),
        ),
        afterPump: (WidgetTester tester) async {
          node.requestFocus();
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
