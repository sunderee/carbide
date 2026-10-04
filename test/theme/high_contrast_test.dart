// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/a11y.dart';

void main() {
  final themes = <String, CarbonThemeData>{
    'white': CarbonThemeData.white,
    'g10': CarbonThemeData.gray10,
    'g90': CarbonThemeData.gray90,
    'g100': CarbonThemeData.gray100,
  };

  for (final entry in themes.entries) {
    testWidgets('${entry.key} strengthens boundaries and disabled text', (
      tester,
    ) async {
      late CarbonThemeData resolved;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: CarbonTheme(
            data: entry.value,
            child: Builder(
              builder: (context) {
                resolved = CarbonTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(
        wcagContrastRatio(resolved.borderSubtle00, resolved.field01),
        greaterThanOrEqualTo(3),
        reason: 'A meaningful field boundary must remain visible.',
      );
      expect(
        wcagContrastRatio(resolved.textDisabled, resolved.field01),
        greaterThanOrEqualTo(4.5),
        reason: 'Our high-contrast policy keeps inactive labels readable.',
      );
    });
  }

  testWidgets('live preference rebuilds a cached reader and restores base', (
    tester,
  ) async {
    final media = ValueNotifier(const MediaQueryData());
    addTearDown(media.dispose);
    late CarbonThemeData resolved;
    var builds = 0;
    final reader = CarbonTheme(
      data: CarbonThemeData.white,
      child: Builder(
        builder: (context) {
          builds++;
          resolved = CarbonTheme.of(context);
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(
      ValueListenableBuilder<MediaQueryData>(
        valueListenable: media,
        child: reader,
        builder: (_, data, child) => MediaQuery(data: data, child: child!),
      ),
    );
    expect(resolved, same(CarbonThemeData.white));
    expect(builds, 1);
    media.value = const MediaQueryData(highContrast: true);
    await tester.pump();
    expect(resolved, isNot(same(CarbonThemeData.white)));
    expect(builds, 2);
    media.value = const MediaQueryData(
      highContrast: true,
      size: Size(900, 700),
    );
    await tester.pump();
    expect(
      builds,
      2,
      reason: 'Unrelated media properties do not invalidate tokens.',
    );
    media.value = const MediaQueryData();
    await tester.pump();
    expect(resolved, same(CarbonThemeData.white));
    expect(builds, 3);
  });

  for (final local in <bool>[false, true]) {
    testWidgets('nearest media override below the theme wins: $local', (
      tester,
    ) async {
      late CarbonThemeData resolved;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(highContrast: !local),
          child: CarbonTheme(
            data: CarbonThemeData.gray90,
            child: MediaQuery(
              data: MediaQueryData(highContrast: local),
              child: Builder(
                builder: (context) {
                  resolved = CarbonTheme.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      if (local) {
        expect(resolved, isNot(same(CarbonThemeData.gray90)));
        expect(
          wcagContrastRatio(resolved.borderSubtle00, resolved.field01),
          greaterThanOrEqualTo(3),
        );
      } else {
        expect(resolved, same(CarbonThemeData.gray90));
      }
    });
  }

  testWidgets('absent media query preserves the original theme', (
    tester,
  ) async {
    late CarbonThemeData resolved;
    await tester.pumpWidget(
      CarbonTheme(
        data: CarbonThemeData.gray10,
        child: Builder(
          builder: (context) {
            resolved = CarbonTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, same(CarbonThemeData.gray10));
  });

  testWidgets('high contrast does not create a missing theme', (tester) async {
    CarbonThemeData? resolved = CarbonThemeData.white;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(highContrast: true),
        child: Builder(
          builder: (context) {
            resolved = CarbonTheme.maybeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, isNull);
  });

  testWidgets('nearest theme can change while high contrast remains enabled', (
    tester,
  ) async {
    final base = ValueNotifier(CarbonThemeData.white);
    addTearDown(base.dispose);
    late CarbonThemeData resolved;
    final reader = Builder(
      builder: (context) {
        resolved = CarbonTheme.of(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(highContrast: true),
        child: CarbonTheme(
          data: CarbonThemeData.gray10,
          child: ValueListenableBuilder<CarbonThemeData>(
            valueListenable: base,
            child: reader,
            builder: (_, data, child) => CarbonTheme(data: data, child: child!),
          ),
        ),
      ),
    );
    expect(resolved, same(CarbonThemeData.highContrast(CarbonThemeData.white)));
    base.value = CarbonThemeData.gray90;
    await tester.pump();
    expect(
      resolved,
      same(CarbonThemeData.highContrast(CarbonThemeData.gray90)),
    );
  });

  testWidgets(
    'an explicit derived theme stays enabled with a normal preference',
    (tester) async {
      final explicit = CarbonThemeData.highContrast(CarbonThemeData.gray100);
      late CarbonThemeData resolved;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: CarbonTheme(
            data: explicit,
            child: Builder(
              builder: (context) {
                resolved = CarbonTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(resolved, same(explicit));
    },
  );

  testWidgets('high-contrast theme changes apply without intermediate colors', (
    tester,
  ) async {
    late CarbonThemeData resolved;
    Widget tree(CarbonThemeData data) => MediaQuery(
      data: const MediaQueryData(highContrast: true),
      child: AnimatedCarbonTheme(
        data: data,
        duration: const Duration(milliseconds: 200),
        child: Builder(
          builder: (context) {
            resolved = CarbonTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(tree(CarbonThemeData.white));
    await tester.pumpWidget(tree(CarbonThemeData.gray100));
    await tester.pump();
    expect(resolved.background, CarbonThemeData.gray100.background);
    expect(
      wcagContrastRatio(resolved.focus, resolved.background),
      greaterThanOrEqualTo(3),
    );
    final state = tester
        .state<ImplicitlyAnimatedWidgetState<AnimatedCarbonTheme>>(
          find.byType(AnimatedCarbonTheme),
        );
    expect(state.animation.status.isAnimating, isFalse);
  });

  testWidgets('enabling high contrast finishes an in-flight theme change', (
    tester,
  ) async {
    final preference = ValueNotifier(false);
    addTearDown(preference.dispose);
    late CarbonThemeData resolved;
    Widget tree(CarbonThemeData data) => ValueListenableBuilder<bool>(
      valueListenable: preference,
      child: AnimatedCarbonTheme(
        data: data,
        duration: const Duration(milliseconds: 200),
        child: Builder(
          builder: (context) {
            resolved = CarbonTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
      builder: (_, highContrast, child) => MediaQuery(
        data: MediaQueryData(highContrast: highContrast),
        child: child!,
      ),
    );
    await tester.pumpWidget(tree(CarbonThemeData.white));
    await tester.pumpWidget(tree(CarbonThemeData.gray100));
    await tester.pump(const Duration(milliseconds: 50));
    expect(resolved.background, isNot(CarbonThemeData.gray100.background));
    preference.value = true;
    await tester.pump();
    expect(resolved.background, CarbonThemeData.gray100.background);
    expect(
      wcagContrastRatio(resolved.focus, resolved.background),
      greaterThanOrEqualTo(3),
    );
    preference.value = false;
    await tester.pump();
    expect(resolved.background, CarbonThemeData.gray100.background);
    expect(resolved.focus, CarbonThemeData.gray100.focus);
  });
}
