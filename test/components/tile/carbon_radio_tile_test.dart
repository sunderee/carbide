// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
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
          CarbonRadioTile(
            selected: true,
            onSelected: () {},
            aiLabel: const SizedBox.square(dimension: 8),
            child: const Text('R'),
          ),
        ),
      );
      // Surface: $duration-moderate-01 motion(standard, productive).
      final AnimatedContainer surface = tester.widget(
        find.byType(AnimatedContainer),
      );
      expect(surface.duration, CarbonDuration.moderate01);
      expect(surface.curve, CarbonEasing.standardProductive);
      // Indicator fade: opacity $duration-fast-02
      // motion(standard, productive).
      final AnimatedOpacity indicator = tester.widget(
        find.byType(AnimatedOpacity),
      );
      expect(indicator.duration, CarbonDuration.fast02);
      expect(indicator.curve, CarbonEasing.standardProductive);
      // AI decorator slide (`--tile--radio` AI selectors):
      // inset-inline-end $duration-fast-02 motion(standard, productive).
      final AnimatedPositionedDirectional slide = tester.widget(
        find.byType(AnimatedPositionedDirectional),
      );
      expect(slide.duration, CarbonDuration.fast02);
      expect(slide.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion is instant', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: CarbonRadioTile(
              selected: true,
              onSelected: () {},
              aiLabel: const SizedBox.square(dimension: 8),
              child: const Text('R'),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<AnimatedPositionedDirectional>(
              find.byType(AnimatedPositionedDirectional),
            )
            .duration,
        Duration.zero,
      );
    });
  });

  group('spec locks (_tile.scss radio-tile)', () {
    testWidgets('selected: layerSelectedInverse border + visible checkmark', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonRadioTile(
            selected: true,
            onSelected: () {},
            child: const Text('Standard'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (container.decoration! as BoxDecoration).border!.top.color,
        theme.layerSelectedInverse,
      );
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      final CarbonIconPainter icon =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(CarbonIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as CarbonIconPainter;
      expect(icon.color, theme.iconPrimary);
    });

    testWidgets('unselected at rest hides the checkmark', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonRadioTile(
            selected: false,
            onSelected: () {},
            child: const Text('Standard'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });
  });

  group('TileGroup selection + keyboard', () {
    Widget group(String? value, ValueChanged<String> onChanged) =>
        CarbonTileGroup<String>(
          legend: 'Storage',
          value: value,
          onChanged: onChanged,
          options: const <(String, Widget)>[
            ('s', Text('Small')),
            ('m', Text('Medium')),
            ('l', Text('Large')),
          ],
        );

    testWidgets('tap single-selects', (WidgetTester tester) async {
      String? value = 's';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                group(value, (String v) => setState(() => value = v)),
          ),
        ),
      );
      await tester.tap(find.text('Large'));
      await tester.pump();
      expect(value, 'l');
    });

    testWidgets('arrow up/down rove selection with wrap', (
      WidgetTester tester,
    ) async {
      String? value = 's';
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                group(value, (String v) => setState(() => value = v)),
          ),
        ),
      );
      tester
          .widget<CarbonRadioTile>(find.byType(CarbonRadioTile).first)
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(value, 'm');

      value = 's';
      await tester.pump();
      tester
          .widget<CarbonRadioTile>(find.byType(CarbonRadioTile).first)
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(value, 'l'); // wraps to last
    });

    testWidgets('exclusive-group semantics + legend', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(group('s', (_) {})));
      expect(find.text('Storage'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Small')),
        isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
      );
      handle.dispose();
    });
  });

  group('goldens (layer 0 and layer 1)', () {
    Widget specimen() => Center(
      child: SizedBox(
        width: 220,
        child: CarbonTileGroup<String>(
          legend: 'Plan',
          value: 'pro',
          onChanged: (_) {},
          options: const <(String, Widget)>[
            ('free', Text('Free')),
            ('pro', Text('Pro')),
          ],
        ),
      ),
    );

    testWidgets('tiles at layer 0', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'radio_tile_layer0',
        containsText: true,
        size: const Size(260, 220),
        builder: (BuildContext context) => specimen(),
      );
    });

    testWidgets('tiles inside a CarbonLayer', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'radio_tile_layer1',
        containsText: true,
        size: const Size(260, 220),
        builder: (BuildContext context) =>
            CarbonLayer(child: Builder(builder: (_) => specimen())),
      );
    });
  });
}
