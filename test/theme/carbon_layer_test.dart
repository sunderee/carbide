// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(data: CarbonThemeData.white, child: child),
);

void main() {
  group('level semantics', () {
    testWidgets('root content sits on level 0', (WidgetTester tester) async {
      late int level;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (BuildContext context) {
              level = CarbonLayer.levelOf(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(level, 0);
    });

    testWidgets('each CarbonLayer raises the level; capped at 2', (
      WidgetTester tester,
    ) async {
      final List<int> seen = <int>[];
      Widget probe(Widget child) => Builder(
        builder: (BuildContext context) {
          seen.add(CarbonLayer.levelOf(context));
          return child;
        },
      );

      await tester.pumpWidget(
        _host(
          CarbonLayer(
            child: probe(
              CarbonLayer(
                child: probe(CarbonLayer(child: probe(const SizedBox()))),
              ),
            ),
          ),
        ),
      );
      expect(seen, <int>[1, 2, 2]);
    });

    testWidgets('an explicit level overrides the hierarchy', (
      WidgetTester tester,
    ) async {
      final List<int> seen = <int>[];
      await tester.pumpWidget(
        _host(
          CarbonLayer(
            child: CarbonLayer(
              level: 0,
              child: Builder(
                builder: (BuildContext context) {
                  seen.add(CarbonLayer.levelOf(context));
                  return CarbonLayer(
                    child: Builder(
                      builder: (BuildContext context) {
                        seen.add(CarbonLayer.levelOf(context));
                        return const SizedBox();
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      expect(seen, <int>[0, 1]);
    });

    test('constructing with an out-of-range level asserts', () {
      expect(
        () => CarbonLayer(level: 3, child: const SizedBox()),
        throwsAssertionError,
      );
    });

    test('resolving an out-of-range level throws a RangeError', () {
      expect(
        () => CarbonLayerTokens.resolve(CarbonThemeData.white, 3),
        throwsRangeError,
      );
    });
  });

  group('token resolution', () {
    final List<CarbonThemeData> themes = <CarbonThemeData>[
      CarbonThemeData.white,
      CarbonThemeData.gray10,
      CarbonThemeData.gray90,
      CarbonThemeData.gray100,
    ];

    test('level 0 maps to the -01 tokens (and borderSubtle00)', () {
      for (final CarbonThemeData theme in themes) {
        final CarbonLayerTokens tokens = CarbonLayerTokens.resolve(theme, 0);
        expect(tokens.layer, theme.layer01);
        expect(tokens.layerActive, theme.layerActive01);
        expect(tokens.layerBackground, theme.layerBackground01);
        expect(tokens.layerHover, theme.layerHover01);
        expect(tokens.layerSelected, theme.layerSelected01);
        expect(tokens.layerSelectedHover, theme.layerSelectedHover01);
        expect(tokens.layerAccent, theme.layerAccent01);
        expect(tokens.layerAccentHover, theme.layerAccentHover01);
        expect(tokens.layerAccentActive, theme.layerAccentActive01);
        expect(tokens.field, theme.field01);
        expect(tokens.fieldHover, theme.fieldHover01);
        expect(tokens.borderSubtle, theme.borderSubtle00);
        expect(tokens.borderSubtleSelected, theme.borderSubtleSelected01);
        expect(tokens.borderStrong, theme.borderStrong01);
        expect(tokens.borderTile, theme.borderTile01);
      }
    });

    test('level 1 maps to the -02 tokens (and borderSubtle01)', () {
      for (final CarbonThemeData theme in themes) {
        final CarbonLayerTokens tokens = CarbonLayerTokens.resolve(theme, 1);
        expect(tokens.layer, theme.layer02);
        expect(tokens.layerActive, theme.layerActive02);
        expect(tokens.layerBackground, theme.layerBackground02);
        expect(tokens.layerHover, theme.layerHover02);
        expect(tokens.layerSelected, theme.layerSelected02);
        expect(tokens.layerSelectedHover, theme.layerSelectedHover02);
        expect(tokens.layerAccent, theme.layerAccent02);
        expect(tokens.layerAccentHover, theme.layerAccentHover02);
        expect(tokens.layerAccentActive, theme.layerAccentActive02);
        expect(tokens.field, theme.field02);
        expect(tokens.fieldHover, theme.fieldHover02);
        expect(tokens.borderSubtle, theme.borderSubtle01);
        expect(tokens.borderSubtleSelected, theme.borderSubtleSelected02);
        expect(tokens.borderStrong, theme.borderStrong02);
        expect(tokens.borderTile, theme.borderTile02);
      }
    });

    test('level 2 maps to the -03 tokens (and borderSubtle02)', () {
      for (final CarbonThemeData theme in themes) {
        final CarbonLayerTokens tokens = CarbonLayerTokens.resolve(theme, 2);
        expect(tokens.layer, theme.layer03);
        expect(tokens.layerActive, theme.layerActive03);
        expect(tokens.layerBackground, theme.layerBackground03);
        expect(tokens.layerHover, theme.layerHover03);
        expect(tokens.layerSelected, theme.layerSelected03);
        expect(tokens.layerSelectedHover, theme.layerSelectedHover03);
        expect(tokens.layerAccent, theme.layerAccent03);
        expect(tokens.layerAccentHover, theme.layerAccentHover03);
        expect(tokens.layerAccentActive, theme.layerAccentActive03);
        expect(tokens.field, theme.field03);
        expect(tokens.fieldHover, theme.fieldHover03);
        expect(tokens.borderSubtle, theme.borderSubtle02);
        expect(tokens.borderSubtleSelected, theme.borderSubtleSelected03);
        expect(tokens.borderStrong, theme.borderStrong03);
        expect(tokens.borderTile, theme.borderTile03);
      }
    });

    test('equal levels resolve to equal token sets', () {
      expect(
        CarbonLayerTokens.resolve(CarbonThemeData.white, 1),
        CarbonLayerTokens.resolve(CarbonThemeData.white, 1),
      );
      expect(
        CarbonLayerTokens.resolve(CarbonThemeData.white, 1),
        isNot(CarbonLayerTokens.resolve(CarbonThemeData.white, 2)),
      );
    });

    test('equal token sets share one hash code', () {
      expect(
        CarbonLayerTokens.resolve(CarbonThemeData.white, 1).hashCode,
        CarbonLayerTokens.resolve(CarbonThemeData.white, 1).hashCode,
      );
      expect(
        CarbonLayerTokens.resolve(CarbonThemeData.white, 1).hashCode,
        isNot(CarbonLayerTokens.resolve(CarbonThemeData.gray100, 1).hashCode),
      );
    });
  });

  group('withBackground', () {
    testWidgets('paints layerBackground for the new level', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonLayer(withBackground: true, child: SizedBox())),
      );
      final ColoredBox box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(CarbonLayer),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(box.color, CarbonThemeData.white.layerBackground02);
    });
  });

  testWidgets('stacked layers across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'layer_stack',
      size: const Size(200, 88),
      builder: (BuildContext context) => const Center(child: _LayerStack()),
    );
  });
}

class _LayerStack extends StatelessWidget {
  const _LayerStack();

  @override
  Widget build(BuildContext context) {
    return const _LayerSwatch(
      child: CarbonLayer(
        child: _LayerSwatch(
          child: CarbonLayer(child: _LayerSwatch(child: SizedBox())),
        ),
      ),
    );
  }
}

class _LayerSwatch extends StatelessWidget {
  const _LayerSwatch({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens tokens = CarbonLayer.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.layer,
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}
