// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child, {bool reducedMotion = false}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reducedMotion),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Center(child: child),
    ),
  ),
);

void main() {
  group('keyframe engine (utilities/_keyframes.scss value locks)', () {
    test('keyframe stops match the upstream @keyframes', () {
      // 0%: wipe collapsed at the left, breathing low.
      final CarbonSkeletonPhase start = CarbonSkeletonPhase.at(0);
      expect(start.scaleX, 0);
      expect(start.alignment, Alignment.centerLeft);
      expect(start.opacity, 0.3);

      // 20%: fully grown from the left, fully opaque.
      final CarbonSkeletonPhase grown = CarbonSkeletonPhase.at(0.20);
      expect(grown.scaleX, 1);
      expect(grown.alignment, Alignment.centerLeft);
      expect(grown.opacity, 1);

      // 28%–51%: shrinking toward the right.
      final CarbonSkeletonPhase shrinking = CarbonSkeletonPhase.at(0.395);
      expect(shrinking.alignment, Alignment.centerRight);
      expect(shrinking.scaleX, closeTo(0.5, 0.01));

      // 58%–82%: regrowing from the right.
      final CarbonSkeletonPhase regrow = CarbonSkeletonPhase.at(0.70);
      expect(regrow.alignment, Alignment.centerRight);
      expect(regrow.scaleX, closeTo(0.5, 0.01));

      // 83%–96%: shrinking toward the left; cycle ends collapsed left.
      final CarbonSkeletonPhase tail = CarbonSkeletonPhase.at(0.895);
      expect(tail.alignment, Alignment.centerLeft);
      expect(tail.scaleX, closeTo(0.5, 0.01));
      expect(CarbonSkeletonPhase.at(1).scaleX, 0);
      expect(CarbonSkeletonPhase.at(1).opacity, closeTo(0.3, 0.0001));
    });

    test('segments ease in-out (midpoints are not linear)', () {
      // 10% is the midpoint of the 0–20% grow segment: easeInOut(0.5) = 0.5,
      // but easeInOut(0.25) != 0.25 — check a quarter point.
      final CarbonSkeletonPhase quarter = CarbonSkeletonPhase.at(0.05);
      expect(quarter.scaleX, Curves.easeInOut.transform(0.25));
    });
  });

  group('SkeletonText seed algorithm (SkeletonText.tsx value locks)', () {
    test('randomInt reproduces the upstream fixed seeds', () {
      // floor(seed * 76): 73, 11, 43 — the three cycling offsets.
      expect(CarbonSkeletonText.randomInt(0, 75, 0), 73);
      expect(CarbonSkeletonText.randomInt(0, 75, 1), 11);
      expect(CarbonSkeletonText.randomInt(0, 75, 2), 43);
      expect(CarbonSkeletonText.randomInt(0, 75, 3), 73);
    });

    test('percent mode subtracts the offsets from the full width', () {
      expect(CarbonSkeletonText.lineWidth(300, 0, fixed: false), 300 - 73);
      expect(CarbonSkeletonText.lineWidth(300, 1, fixed: false), 300 - 11);
      expect(CarbonSkeletonText.lineWidth(300, 2, fixed: false), 300 - 43);
    });

    test('px mode uses the bounded upstream formula', () {
      // width 200: min = 125, range 76 → 125 + {73,11,43}.
      expect(CarbonSkeletonText.lineWidth(200, 0, fixed: true), 198);
      expect(CarbonSkeletonText.lineWidth(200, 1, fixed: true), 136);
      expect(CarbonSkeletonText.lineWidth(200, 2, fixed: true), 168);
      // width 50 (< 75): min = 0, range 51 → floor(seed * 51).
      expect(CarbonSkeletonText.lineWidth(50, 0, fixed: true), 49);
    });
  });

  group('geometry (skeleton-styles/_skeleton-styles.scss)', () {
    testWidgets('variant dimensions match the spec', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonSkeletonPlaceholder()));
      expect(
        tester.getSize(find.byType(CarbonSkeletonPlaceholder)),
        const Size(100, 100),
      );

      await tester.pumpWidget(_host(const CarbonSkeletonIcon()));
      expect(
        tester.getSize(find.byType(CarbonSkeletonIcon)),
        const Size(16, 16),
      );

      await tester.pumpWidget(_host(const CarbonButtonSkeleton()));
      expect(
        tester.getSize(find.byType(CarbonButtonSkeleton)),
        const Size(150, 48),
      );

      await tester.pumpWidget(_host(const CarbonTagSkeleton()));
      expect(
        tester.getSize(find.byType(CarbonTagSkeleton)),
        const Size(60, 24),
      );
    });

    testWidgets('shape parameters propagate to the rendered size', (
      WidgetTester tester,
    ) async {
      for (final Size custom in const <Size>[Size(80, 24), Size(40, 12)]) {
        await tester.pumpWidget(
          _host(
            CarbonSkeletonPlaceholder(
              width: custom.width,
              height: custom.height,
            ),
          ),
        );
        expect(tester.getSize(find.byType(CarbonSkeletonPlaceholder)), custom);
      }

      for (final double edge in const <double>[12, 20]) {
        await tester.pumpWidget(_host(CarbonSkeletonIcon(size: edge)));
        expect(
          tester.getSize(find.byType(CarbonSkeletonIcon)),
          Size(edge, edge),
        );
      }

      for (final CarbonButtonSize size in CarbonButtonSize.values) {
        await tester.pumpWidget(_host(CarbonButtonSkeleton(size: size)));
        expect(
          tester.getSize(find.byType(CarbonButtonSkeleton)),
          Size(CarbonButtonSkeleton.width, size.height),
        );
      }

      for (final CarbonTagSize size in CarbonTagSize.values) {
        await tester.pumpWidget(_host(CarbonTagSkeleton(size: size)));
        expect(
          tester.getSize(find.byType(CarbonTagSkeleton)),
          Size(CarbonTagSkeleton.width, size.height),
        );
      }
    });

    testWidgets('text lines: 16px body, 24px heading, 8px gap, '
        'deterministic paragraph widths', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: CarbonSkeletonText(paragraph: true),
          ),
        ),
      );
      final List<Size> lines = tester
          .widgetList<CarbonSkeleton>(find.byType(CarbonSkeleton))
          .map((CarbonSkeleton s) => Size(s.width!, s.height!))
          .toList();
      expect(lines, const <Size>[Size(227, 16), Size(289, 16), Size(257, 16)]);

      await tester.pumpWidget(
        _host(const CarbonSkeletonText(heading: true, width: 120)),
      );
      final CarbonSkeleton heading = tester.widget<CarbonSkeleton>(
        find.byType(CarbonSkeleton),
      );
      expect(heading.height, 24);
      expect(heading.width, 120);
    });
  });

  group('animation behaviour', () {
    testWidgets('the wipe advances with the 3000ms cycle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonSkeletonPlaceholder()));
      Transform wipe() => tester.widget<Transform>(
        find.descendant(
          of: find.byType(CarbonSkeleton),
          matching: find.byType(Transform),
        ),
      );
      // t = 0: collapsed. (Ticker frame timing is sub-ms off exact
      // stops; the keyframe engine itself is value-locked exactly above.)
      expect(wipe().transform.storage[0], closeTo(0, 0.001));
      // t = 600ms (20%): fully grown.
      await tester.pump(const Duration(milliseconds: 600));
      expect(wipe().transform.storage[0], closeTo(1, 0.001));
      // The animation repeats: t = 3600ms ≡ 20%.
      await tester.pump(const Duration(milliseconds: 3000));
      expect(wipe().transform.storage[0], closeTo(1, 0.001));
    });

    testWidgets('reduced motion renders the static element fill', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonSkeletonPlaceholder(), reducedMotion: true),
      );
      // No Transform wipe; a static skeletonElement fill instead.
      expect(
        find.descendant(
          of: find.byType(CarbonSkeleton),
          matching: find.byType(Transform),
        ),
        findsNothing,
      );
      final ColoredBox fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(CarbonSkeleton),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.color, CarbonThemeData.white.skeletonElement);
      // And nothing is animating, so this must not hang.
      await tester.pumpAndSettle();
    });

    testWidgets('skeletons are excluded from semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonSkeletonPlaceholder()));
      expect(
        tester.getSemantics(find.byType(CarbonSkeletonPlaceholder)).label,
        isEmpty,
      );
      handle.dispose();
    });
  });

  testWidgets('skeleton specimen across themes (mid-wipe at 300ms)', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'skeleton',
      size: const Size(220, 170),
      pumpBeforeSnapshot: const Duration(milliseconds: 300),
      builder: (BuildContext context) => const Center(
        child: SizedBox(
          width: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonSkeletonText(heading: true),
              CarbonSkeletonText(paragraph: true),
              SizedBox(height: 8),
              CarbonTagSkeleton(),
            ],
          ),
        ),
      ),
    );
  });
}
