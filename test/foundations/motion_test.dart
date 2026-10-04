// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final bool? reduced in <bool?>[null, false, true]) {
    testWidgets('duration resolver: disableAnimations=$reduced', (
      tester,
    ) async {
      final List<Duration> resolved = <Duration>[];
      Widget child = Builder(
        builder: (BuildContext context) {
          for (final Duration duration in <Duration>[
            CarbonDuration.fast01,
            CarbonDuration.fast02,
            CarbonDuration.moderate01,
            CarbonDuration.moderate02,
            CarbonDuration.slow01,
            CarbonDuration.slow02,
            const Duration(milliseconds: 1234),
            Duration.zero,
          ]) {
            resolved.add(carbonDuration(context, duration));
          }
          return const SizedBox();
        },
      );
      if (reduced != null) {
        child = MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: child,
        );
      }
      await tester.pumpWidget(child);
      expect(
        resolved,
        reduced == true
            ? List<Duration>.filled(8, Duration.zero)
            : <Duration>[
                CarbonDuration.fast01,
                CarbonDuration.fast02,
                CarbonDuration.moderate01,
                CarbonDuration.moderate02,
                CarbonDuration.slow01,
                CarbonDuration.slow02,
                const Duration(milliseconds: 1234),
                Duration.zero,
              ],
      );
    });
  }

  testWidgets('duration resolver follows the nearest live preference', (
    tester,
  ) async {
    final ValueNotifier<bool> reduced = ValueNotifier<bool>(false);
    addTearDown(reduced.dispose);
    Duration? duration;
    int builds = 0;
    final Widget reader = Builder(
      builder: (context) {
        builds++;
        duration = carbonDuration(context, CarbonDuration.slow02);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: ValueListenableBuilder<bool>(
          valueListenable: reduced,
          child: reader,
          builder: (_, value, child) => MediaQuery(
            data: MediaQueryData(disableAnimations: value),
            child: child!,
          ),
        ),
      ),
    );
    expect(duration, CarbonDuration.slow02);
    reduced.value = true;
    await tester.pump();
    expect(duration, Duration.zero);
    reduced.value = false;
    await tester.pump();
    expect(duration, CarbonDuration.slow02);
    expect(builds, 3);
  });

  test('durations match the Carbon source (ms)', () {
    expect(CarbonDuration.fast01.inMilliseconds, 70);
    expect(CarbonDuration.fast02.inMilliseconds, 110);
    expect(CarbonDuration.moderate01.inMilliseconds, 150);
    expect(CarbonDuration.moderate02.inMilliseconds, 240);
    expect(CarbonDuration.slow01.inMilliseconds, 400);
    expect(CarbonDuration.slow02.inMilliseconds, 700);
  });

  test('easing curves match the Carbon cubic-bezier values', () {
    void expectCubic(Cubic curve, double a, double b, double c, double d) {
      expect(
        <double>[curve.a, curve.b, curve.c, curve.d],
        <double>[a, b, c, d],
      );
    }

    expectCubic(CarbonEasing.standardProductive, 0.2, 0, 0.38, 0.9);
    expectCubic(CarbonEasing.standardExpressive, 0.4, 0.14, 0.3, 1);
    expectCubic(CarbonEasing.entranceProductive, 0, 0, 0.38, 0.9);
    expectCubic(CarbonEasing.entranceExpressive, 0, 0, 0.3, 1);
    expectCubic(CarbonEasing.exitProductive, 0.2, 0, 1, 0.9);
    expectCubic(CarbonEasing.exitExpressive, 0.4, 0.14, 1, 1);
  });

  test('resolve maps every style/mode pair to the right curve', () {
    expect(
      CarbonEasing.resolve(
        CarbonEasingStyle.standard,
        CarbonEasingMode.productive,
      ),
      same(CarbonEasing.standardProductive),
    );
    expect(
      CarbonEasing.resolve(
        CarbonEasingStyle.entrance,
        CarbonEasingMode.expressive,
      ),
      same(CarbonEasing.entranceExpressive),
    );
    expect(
      CarbonEasing.resolve(CarbonEasingStyle.exit, CarbonEasingMode.productive),
      same(CarbonEasing.exitProductive),
    );
  });
}
