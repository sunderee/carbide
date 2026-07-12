// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 280, child: child)),
  ),
);

/// A stateful wrapper so the controlled tile can actually toggle in tests.
class _Stateful extends StatefulWidget {
  const _Stateful({this.interactive = false});
  final bool interactive;

  @override
  State<_Stateful> createState() => _StatefulState();
}

class _StatefulState extends State<_Stateful> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => _host(
    CarbonExpandableTile(
      interactive: widget.interactive,
      expanded: _expanded,
      onExpandedChanged: (bool v) => setState(() => _expanded = v),
      aboveTheFold: const Text('above'),
      belowTheFold: const SizedBox(height: 40, child: Text('below')),
    ),
  );
}

double _belowOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text('below'), matching: find.byType(Opacity)),
    )
    .opacity;

double _chevronTurns(WidgetTester tester) =>
    tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;

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
    testWidgets('spec tokens match _tile.scss', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonExpandableTile(
            expanded: false,
            onExpandedChanged: (_) {},
            aboveTheFold: const Text('above'),
            belowTheFold: const Text('below'),
          ),
        ),
      );
      // `__chevron svg`: transform $duration-fast-02
      // motion(standard, productive).
      final AnimatedRotation chevron = tester.widget(
        find.byType(AnimatedRotation),
      );
      expect(chevron.duration, CarbonDuration.fast02);
      expect(chevron.curve, CarbonEasing.standardProductive);
      // `--tile--expandable`: max-height $duration-moderate-01
      // motion(standard, productive).
      final TweenAnimationBuilder<double> fold = tester.widget(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(fold.duration, CarbonDuration.moderate01);
      expect(fold.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion snaps the fold and chevron', (
      WidgetTester tester,
    ) async {
      Widget tree(bool expanded) => _host(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CarbonExpandableTile(
            expanded: expanded,
            onExpandedChanged: (_) {},
            aboveTheFold: const Text('above'),
            belowTheFold: const Text('below'),
          ),
        ),
      );
      await tester.pumpWidget(tree(false));
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>),
            )
            .duration,
        Duration.zero,
      );
      // The below-the-fold content is fully revealed on the next frame.
      await tester.pumpWidget(tree(true));
      await tester.pump();
      expect(_belowOpacity(tester), 1);
    });
  });

  group('spec locks (_tile.scss expandable + chevron)', () {
    testWidgets('chevron container is 48px and rotates 180° when expanded', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonExpandableTile(
            expanded: false,
            aboveTheFold: Text('above'),
            belowTheFold: Text('below'),
          ),
        ),
      );
      final SizedBox box = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(AnimatedRotation),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.width, 48);
      expect(box.height, 48);
      expect(_chevronTurns(tester), 0);

      await tester.pumpWidget(
        _host(
          const CarbonExpandableTile(
            expanded: true,
            aboveTheFold: Text('above'),
            belowTheFold: Text('below'),
          ),
        ),
      );
      expect(_chevronTurns(tester), 0.5);
    });

    testWidgets(
      'below-the-fold is hidden when collapsed, shown when expanded',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _host(
            const CarbonExpandableTile(
              expanded: false,
              aboveTheFold: Text('above'),
              belowTheFold: Text('below'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_belowOpacity(tester), 0);

        await tester.pumpWidget(
          _host(
            const CarbonExpandableTile(
              expanded: true,
              aboveTheFold: Text('above'),
              belowTheFold: Text('below'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(_belowOpacity(tester), 1);
      },
    );
  });

  group('toggle modes', () {
    testWidgets('default: tapping anywhere on the tile toggles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Stateful());
      expect(_belowOpacity(tester), 0);
      await tester.tap(find.text('above'));
      await tester.pumpAndSettle();
      expect(_belowOpacity(tester), 1);
    });

    testWidgets('interactive: only the chevron toggles, not the body', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Stateful(interactive: true));
      // Tapping the body does nothing.
      await tester.tap(find.text('above'));
      await tester.pumpAndSettle();
      expect(_belowOpacity(tester), 0);
      // Tapping the chevron toggles.
      await tester.tap(find.byType(CarbonIcon));
      await tester.pumpAndSettle();
      expect(_belowOpacity(tester), 1);
    });
  });

  group('interaction states', () {
    testWidgets('default mode hovers the whole tile to layerHover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Stateful());
      ColoredBox tileFill() => tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(CarbonExpandableTile),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(tileFill().color, theme.layer01);
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: tester.getCenter(find.text('above')));
      await tester.pumpAndSettle();
      expect(tileFill().color, theme.layerHover01);
    });

    testWidgets('interactive mode keeps the tile fill flat on body hover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Stateful(interactive: true));
      final ColoredBox tileFill = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(CarbonExpandableTile),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      // The outermost fill is the static layer (the chevron has its own).
      expect(tileFill.color, theme.layer01);
    });

    testWidgets('keyboard focus shows the inset focus ring', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonExpandableTile(
            expanded: false,
            focusNode: node,
            onExpandedChanged: (_) {},
            aboveTheFold: const Text('above'),
            belowTheFold: const Text('below'),
          ),
        ),
      );
      // The focus ring's own CustomPaint is the outer one (the chevron icon
      // paints a second CustomPaint inside).
      CustomPaint ring() => tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CarbonFocusRing),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(ring().foregroundPainter, isNull);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(ring().foregroundPainter, isNotNull);
    });
  });

  group('semantics', () {
    testWidgets('chevron button exposes expanded state and a toggle label', (
      WidgetTester tester,
    ) async {
      // Interactive mode keeps the chevron button label isolated; the
      // whole-tile mode would (correctly) merge the content into its name.
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonExpandableTile(
            interactive: true,
            expanded: false,
            onExpandedChanged: (_) {},
            aboveTheFold: const Text('above'),
            belowTheFold: const Text('below'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Expand')),
        isSemantics(label: 'Expand', isButton: true, hasExpandedState: true),
      );

      await tester.pumpWidget(
        _host(
          CarbonExpandableTile(
            interactive: true,
            expanded: true,
            onExpandedChanged: (_) {},
            aboveTheFold: const Text('above'),
            belowTheFold: const Text('below'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Collapse')),
        isSemantics(
          label: 'Collapse',
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
        ),
      );
      handle.dispose();
    });
  });

  group('goldens (layer 0 and layer 1)', () {
    Widget specimen(bool expanded) => Center(
      child: SizedBox(
        width: 240,
        child: CarbonExpandableTile(
          expanded: expanded,
          onExpandedChanged: (_) {},
          aboveTheFold: const Text('Above the fold'),
          belowTheFold: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Below the fold detail'),
          ),
        ),
      ),
    );

    testWidgets('collapsed across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'expandable_tile_collapsed',
        containsText: true,
        size: const Size(300, 140),
        builder: (BuildContext context) => specimen(false),
      );
    });

    testWidgets('expanded inside a CarbonLayer', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'expandable_tile_expanded',
        containsText: true,
        size: const Size(300, 180),
        builder: (BuildContext context) =>
            CarbonLayer(child: Builder(builder: (_) => specimen(true))),
      );
    });

    testWidgets('focused interactive chevron shows its focus ring', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'expandable_tile_focus',
        containsText: true,
        size: const Size(300, 140),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 240,
            child: CarbonExpandableTile(
              interactive: true,
              expanded: false,
              focusNode: node,
              onExpandedChanged: (_) {},
              aboveTheFold: const Text('Above the fold'),
              belowTheFold: const Text('Below the fold detail'),
            ),
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
