// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child, {double width = 300}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

Finder _trackBox = find.descendant(
  of: find.byType(CarbonProgressBar),
  matching: find.byType(ColoredBox),
);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('spec locks (progress-bar/_progress-bar.scss)', () {
    testWidgets('track heights: big 8px, small 4px; min width 48', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'L', value: 50)),
      );
      expect(tester.getSize(_trackBox.first).height, 8);

      await tester.pumpWidget(
        _host(
          const CarbonProgressBar(
            label: 'L',
            value: 50,
            size: CarbonProgressBarSize.small,
          ),
        ),
      );
      expect(tester.getSize(_trackBox.first).height, 4);
    });

    testWidgets('track reads the contextual borderSubtle token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'L', value: 50)),
      );
      final ColoredBox track = tester.widget<ColoredBox>(_trackBox.first);
      // At the root layer the contextual border-subtle is borderSubtle00
      // (the documented layer offset — level one would read borderSubtle01).
      expect(track.color, theme.borderSubtle00);
    });

    test('sizes and indeterminate cycle', () {
      expect(CarbonProgressBarSize.big.trackHeight, 8);
      expect(CarbonProgressBarSize.small.trackHeight, 4);
      expect(
        CarbonProgressBar.indeterminateCycle,
        const Duration(milliseconds: 1400),
      );
    });
  });

  group('determinate value', () {
    testWidgets('fraction = value / max, clamped; animates to target', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'L', value: 42)),
      );
      await tester.pumpAndSettle();
      double widthFactor() => tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
      expect(widthFactor(), closeTo(0.42, 0.001));

      // Over-max clamps to 1.
      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'L', value: 150)),
      );
      await tester.pumpAndSettle();
      expect(widthFactor(), 1);
    });

    testWidgets('bar color is interactive when active', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'L', value: 42)),
      );
      await tester.pumpAndSettle();
      final ColoredBox bar = tester.widget<ColoredBox>(_trackBox.last);
      expect(bar.color, theme.interactive);
    });
  });

  group('statuses', () {
    testWidgets('finished: full success bar + checkmark icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonProgressBar(
            label: 'L',
            value: 10,
            status: CarbonProgressBarStatus.finished,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Status fills the bar regardless of value.
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        1,
      );
      expect(
        tester.widget<ColoredBox>(_trackBox.last).color,
        theme.supportSuccess,
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
      expect(icon.color, theme.supportSuccess);
    });

    testWidgets('error: full error bar, error helper text color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonProgressBar(
            label: 'L',
            value: 10,
            status: CarbonProgressBarStatus.error,
            helperText: 'Something failed',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ColoredBox>(_trackBox.last).color,
        theme.supportError,
      );
      final Text helper = tester.widget<Text>(find.text('Something failed'));
      expect(helper.style!.color, theme.textError);
    });

    testWidgets('active helper text uses textSecondary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonProgressBar(
            label: 'L',
            value: 10,
            helperText: 'Uploading',
          ),
        ),
      );
      expect(
        tester.widget<Text>(find.text('Uploading')).style!.color,
        theme.textSecondary,
      );
    });
  });

  group('indeterminate', () {
    testWidgets('active with no value sweeps; setting a value stops it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonProgressBar(label: 'L')));
      // A painted sweep, not a FractionallySizedBox.
      expect(find.byType(FractionallySizedBox), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CarbonProgressBar),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );
      await tester.pump(const Duration(milliseconds: 200));
      // The controller is repeating: pumping does not settle.
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'L', value: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FractionallySizedBox), findsOneWidget);
    });
  });

  group('motion (#235)', () {
    // Spec source: `_progress-bar.scss` — the determinate bar transitions
    // `transform $duration-fast-02 motion(standard, productive)`; the
    // indeterminate sweep is the 1400ms `progress-bar-indeterminate`
    // animation (locked in the spec-locks group above).
    testWidgets('spec lock: determinate fill is fast-02 × '
        'standard-productive', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'L', value: 30)),
      );
      final TweenAnimationBuilder<double> fill = tester
          .widget<TweenAnimationBuilder<double>>(
            find.byType(TweenAnimationBuilder<double>),
          );
      expect(fill.duration, CarbonDuration.fast02);
      expect(fill.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion: determinate value changes apply instantly', (
      WidgetTester tester,
    ) async {
      Widget bar(double value) => MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _host(CarbonProgressBar(label: 'L', value: value)),
      );
      await tester.pumpWidget(bar(30));
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>),
            )
            .duration,
        Duration.zero,
      );
      await tester.pumpWidget(bar(60));
      await tester.pump();
      expect(
        tester
            .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .widthFactor,
        0.6,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    // The sweep is essential motion: per Carbon's motion guidance it
    // communicates that work is still ongoing, so it deliberately keeps
    // running under MediaQueryData.disableAnimations.
    testWidgets('reduced motion: the indeterminate sweep keeps running', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(const CarbonProgressBar(label: 'L')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
    });
  });

  group('semantics', () {
    testWidgets('exposes label and percentage; indeterminate omits value', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonProgressBar(label: 'Upload', value: 42)),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Upload')),
        isSemantics(label: 'Upload', value: '42%'),
      );

      await tester.pumpWidget(_host(const CarbonProgressBar(label: 'Upload')));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Upload')),
        isSemantics(label: 'Upload', value: ''),
      );
      handle.dispose();
    });
  });

  testWidgets('progress bar states across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'progress_bar',
      // Direction-sensitive geometry (#227): mirrored fill / side
      // accent / overlay side re-snapshots under RTL.
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      containsText: true,
      size: const Size(320, 240),
      builder: (BuildContext context) => Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const CarbonProgressBar(
                label: 'Determinate',
                value: 65,
                helperText: '65%',
              ),
              const SizedBox(height: 16),
              const CarbonProgressBar(
                label: 'Finished',
                value: 100,
                status: CarbonProgressBarStatus.finished,
              ),
              const SizedBox(height: 16),
              const CarbonProgressBar(
                label: 'Error',
                value: 40,
                status: CarbonProgressBarStatus.error,
                helperText: 'Upload failed',
              ),
              const SizedBox(height: 16),
              const CarbonProgressBar(
                label: 'Small',
                value: 30,
                size: CarbonProgressBarSize.small,
              ),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('progress bar types and indeterminate across themes', (
    WidgetTester tester,
  ) async {
    // 350ms = 25% of the 1400ms indeterminate cycle: a deterministic stripe
    // position (the determinate bars have settled by then).
    await expectThemeGoldens(
      tester,
      name: 'progress_bar_types',
      containsText: true,
      size: const Size(320, 220),
      pumpBeforeSnapshot: const Duration(milliseconds: 350),
      builder: (BuildContext context) => Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const <Widget>[
              CarbonProgressBar(label: 'Indeterminate'),
              SizedBox(height: 16),
              CarbonProgressBar(
                label: 'Inline',
                value: 60,
                type: CarbonProgressBarType.inline,
              ),
              SizedBox(height: 16),
              CarbonProgressBar(
                label: 'Indented',
                value: 45,
                type: CarbonProgressBarType.indented,
                helperText: 'Indented helper',
              ),
            ],
          ),
        ),
      ),
    );
  });
}
