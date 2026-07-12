// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
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

CarbonLoadingPainter _painterOf(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(CarbonLoading),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as CarbonLoadingPainter;
}

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('spec locks (loading/_loading.scss + _vars.scss)', () {
    testWidgets('large: 88px, 81% arc, 10-unit stroke, interactive color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonLoading()));
      expect(tester.getSize(find.byType(CarbonLoading)), const Size(88, 88));
      final CarbonLoadingPainter painter = _painterOf(tester);
      expect(painter.arcFraction, 0.81);
      expect(painter.strokeWidth, 10);
      expect(painter.color, theme.interactive);
      expect(painter.trackColor, isNull);
    });

    testWidgets('small: 16px, 48% arc, 16-unit stroke, layerAccent track', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonLoading(small: true)));
      expect(tester.getSize(find.byType(CarbonLoading)), const Size(16, 16));
      final CarbonLoadingPainter painter = _painterOf(tester);
      expect(painter.arcFraction, 0.48);
      expect(painter.strokeWidth, 16);
      expect(painter.trackColor, theme.layerAccent01);
    });

    test('rotation cycle is the upstream 690ms', () {
      expect(CarbonLoading.rotationCycle, const Duration(milliseconds: 690));
    });
  });

  group('animation behaviour', () {
    testWidgets('rotates with the 690ms cycle; active=false freezes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonLoading()));
      expect(_painterOf(tester).rotation, closeTo(0, 0.01));
      await tester.pump(const Duration(milliseconds: 345));
      expect(_painterOf(tester).rotation, closeTo(0.5, 0.01));

      await tester.pumpWidget(_host(const CarbonLoading(active: false)));
      final double frozen = _painterOf(tester).rotation;
      await tester.pump(const Duration(milliseconds: 200));
      expect(_painterOf(tester).rotation, frozen);
      // Frozen spinner settles (no infinite animation pending).
      await tester.pumpAndSettle();
    });

    testWidgets('announces via a live region', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonLoading(description: 'Loading data')),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Loading data')),
        isSemantics(label: 'Loading data', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('withOverlay fills with the overlay scrim', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 200,
            height: 200,
            child: CarbonLoading(withOverlay: true),
          ),
        ),
      );
      final ColoredBox scrim = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(CarbonLoading),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(scrim.color, theme.overlay);
    });
  });

  group('reduced motion (#235)', () {
    // The spin (loading/_animation.scss: 690ms `spin`) is essential motion:
    // per Carbon's motion guidance a loading indicator communicates that
    // the system is still working, so it deliberately keeps rotating under
    // MediaQueryData.disableAnimations rather than freezing.
    testWidgets('the spinner keeps spinning (essential motion)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(const CarbonLoading()),
        ),
      );
      final double before = _painterOf(tester).rotation;
      await tester.pump(const Duration(milliseconds: 230));
      expect(_painterOf(tester).rotation, isNot(before));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('the inline loading spinner keeps spinning too', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(const CarbonInlineLoading(description: 'Saving...')),
        ),
      );
      final double before = _painterOf(tester).rotation;
      await tester.pump(const Duration(milliseconds: 230));
      expect(_painterOf(tester).rotation, isNot(before));
      expect(tester.hasRunningAnimations, isTrue);
    });
  });

  group('CarbonInlineLoading (inline-loading scss + tsx)', () {
    testWidgets('statuses render spinner / success / error with tokens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonInlineLoading(description: 'Saving...')),
      );
      expect(find.byType(CarbonLoading), findsOneWidget);
      final Text text = tester.widget<Text>(find.text('Saving...'));
      expect(text.style!.fontSize, CarbonTypeStyles.label02.fontSize);

      await tester.pumpWidget(
        _host(
          const CarbonInlineLoading(
            status: CarbonInlineLoadingStatus.finished,
            description: 'Saved',
          ),
        ),
      );
      await tester.pumpAndSettle();
      CarbonIconPainter icon() =>
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(CarbonIcon),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .painter!
              as CarbonIconPainter;
      expect(icon().color, theme.supportSuccess);

      await tester.pumpWidget(
        _host(
          const CarbonInlineLoading(
            status: CarbonInlineLoadingStatus.error,
            description: 'Failed',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(icon().color, theme.supportError);

      await tester.pumpWidget(
        _host(
          const CarbonInlineLoading(
            status: CarbonInlineLoadingStatus.inactive,
            description: 'Idle',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CarbonLoading), findsNothing);
      expect(find.byType(CarbonIcon), findsNothing);
    });

    testWidgets('onSuccess fires after the 1500ms success delay', (
      WidgetTester tester,
    ) async {
      int fired = 0;
      await tester.pumpWidget(
        _host(
          CarbonInlineLoading(
            status: CarbonInlineLoadingStatus.finished,
            onSuccess: () => fired++,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1400));
      expect(fired, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(fired, 1);
    });

    testWidgets('row meets the 32px minimum and the 8px gap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonInlineLoading(description: 'Saving...')),
      );
      expect(
        tester.getSize(find.byType(CarbonInlineLoading)).height,
        CarbonInlineLoading.minHeight,
      );
      final double gap =
          tester.getTopLeft(find.text('Saving...')).dx -
          tester.getTopRight(find.byType(CarbonLoading)).dx;
      expect(gap, 8);
    });
  });

  group('goldens', () {
    testWidgets('spinners across themes (static frame)', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'loading',
        size: const Size(180, 130),
        builder: (BuildContext context) => const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonLoading(),
              SizedBox(width: 16),
              CarbonLoading(small: true),
            ],
          ),
        ),
      );
    });

    testWidgets('inline loading states across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'inline_loading',
        containsText: true,
        size: const Size(220, 130),
        builder: (BuildContext context) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonInlineLoading(description: 'Loading...'),
              CarbonInlineLoading(
                status: CarbonInlineLoadingStatus.finished,
                description: 'Saved',
              ),
              CarbonInlineLoading(
                status: CarbonInlineLoadingStatus.error,
                description: 'Failed',
              ),
            ],
          ),
        ),
      );
    });
  });
}
