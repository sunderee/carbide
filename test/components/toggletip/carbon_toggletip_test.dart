// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

/// OverlayPortal needs an Overlay ancestor; TapRegion needs a surface.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) => Stack(
              children: <Widget>[
                // The backdrop is a hit-test aid, not UI: keep it out of the
                // semantics tree so a11y sweeps only see the component.
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                    ),
                  ),
                ),
                Center(child: child),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('open / close', () {
    testWidgets('tap toggles the popover content', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonToggletip(content: Text('Details'))),
      );
      expect(find.text('Details'), findsNothing);
      await tester.tap(find.byType(CarbonIcon));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      await tester.tap(find.byType(CarbonIcon));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsNothing);
    });

    testWidgets('Enter on the trigger opens it', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonToggletip(content: Text('Details'))),
      );
      // Focus the trigger (the only focusable node) and press Enter.
      final FocusNode node = tester
          .widgetList<Focus>(find.byType(Focus))
          .map((Focus f) => f.focusNode)
          .firstWhere((FocusNode? n) => n != null && n.canRequestFocus)!;
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('outside tap closes it', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonToggletip(content: Text('Details'))),
      );
      await tester.tap(find.byType(CarbonIcon));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsNothing);
    });

    testWidgets('defaultOpen starts open', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonToggletip(defaultOpen: true, content: Text('Details')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Details'), findsOneWidget);
    });
  });

  group('content', () {
    testWidgets('actions row renders beneath the content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonToggletip(
            defaultOpen: true,
            content: const Text('Body'),
            actions: <Widget>[const Text('Cancel'), const Text('Apply')],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
      // The actions sit below the body.
      expect(
        tester.getTopLeft(find.text('Apply')).dy,
        greaterThan(tester.getTopLeft(find.text('Body')).dy),
      );
    });
  });

  group('semantics', () {
    testWidgets('trigger is a labelled button', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonToggletip(content: Text('Details'))),
      );
      expect(find.bySemanticsLabel('Show information'), findsOneWidget);
      handle.dispose();
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonToggletip(defaultOpen: true, content: Text('Details')),
        ),
      );
      await tester.pumpAndSettle();
      // Tap targets are off: the trigger is the bare 16px information icon
      // by upstream default (`.cds--toggletip-button` is only
      // `button-reset` + flex in documentation/carbon/packages/styles/
      // scss/components/toggletip/_toggletip.scss — no minimum size), so
      // 48dp is unattainable.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('motion (#235)', () {
    // Spec source: `_toggletip.scss` defines no transition or animation —
    // the popover pops in and out instantly, so there is no decorative
    // motion to disable under reduced motion.
    testWidgets('opens instantly with no implicit animations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(const CarbonToggletip(content: Text('Details'))),
        ),
      );
      await tester.tap(find.byType(CarbonIcon));
      await tester.pump();
      await tester.pump(); // the deferred overlay show renders next frame.
      expect(find.text('Details'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(AnimatedOpacity), findsNothing);
      expect(find.byType(FadeTransition), findsNothing);
    });
  });

  group('goldens', () {
    testWidgets('open toggletip across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'toggletip_open',
        containsText: true,
        size: const Size(280, 200),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => const Center(
                child: CarbonToggletip(
                  defaultOpen: true,
                  content: Text('This explains the field.'),
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
