// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) =>
    Directionality(textDirection: TextDirection.ltr, child: child);

void main() {
  testWidgets('of returns the nearest theme data', (WidgetTester tester) async {
    late CarbonThemeData resolved;
    await tester.pumpWidget(
      _host(
        CarbonTheme(
          data: CarbonThemeData.gray100,
          child: Builder(
            builder: (BuildContext context) {
              resolved = CarbonTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(resolved, CarbonThemeData.gray100);
  });

  testWidgets('maybeOf returns null with no CarbonTheme', (
    WidgetTester tester,
  ) async {
    CarbonThemeData? resolved = CarbonThemeData.white;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (BuildContext context) {
            resolved = CarbonTheme.maybeOf(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(resolved, isNull);
  });

  testWidgets('of asserts when no CarbonTheme is present', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (BuildContext context) {
            CarbonTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('updateShouldNotify rebuilds dependents only on change', (
    WidgetTester tester,
  ) async {
    // The dependent is a single stable instance, so it rebuilds only when the
    // inherited CarbonTheme tells it to — not because its own widget changed.
    int builds = 0;
    final GlobalKey<_ThemeSwitcherState> key = GlobalKey<_ThemeSwitcherState>();
    final Widget dependent = Builder(
      builder: (BuildContext context) {
        CarbonTheme.of(context);
        builds++;
        return const SizedBox();
      },
    );

    await tester.pumpWidget(_host(_ThemeSwitcher(key: key, child: dependent)));
    expect(builds, 1);

    // Same data: updateShouldNotify is false, so the dependent is not rebuilt.
    key.currentState!.setData(CarbonThemeData.white);
    await tester.pump();
    expect(builds, 1);

    // Different data: the dependent rebuilds.
    key.currentState!.setData(CarbonThemeData.gray100);
    await tester.pump();
    expect(builds, 2);
  });

  testWidgets('AnimatedCarbonTheme interpolates between themes', (
    WidgetTester tester,
  ) async {
    late Color observed;
    Widget tree(CarbonThemeData data) => _host(
      AnimatedCarbonTheme(
        data: data,
        duration: const Duration(milliseconds: 200),
        child: Builder(
          builder: (BuildContext context) {
            observed = CarbonTheme.of(context).background;
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpWidget(tree(CarbonThemeData.white));
    expect(observed, CarbonThemeData.white.background);

    // Switch theme; halfway through, the background is between the two.
    await tester.pumpWidget(tree(CarbonThemeData.gray100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(observed, isNot(CarbonThemeData.white.background));
    expect(observed, isNot(CarbonThemeData.gray100.background));

    await tester.pumpAndSettle();
    expect(observed, CarbonThemeData.gray100.background);
  });

  testWidgets('AnimatedCarbonTheme applies instantly under reduced motion', (
    WidgetTester tester,
  ) async {
    // The theme crossfade is decorative, so disableAnimations collapses it
    // to zero: the new theme is fully applied on the next frame.
    late Color observed;
    Widget tree(CarbonThemeData data) => _host(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: AnimatedCarbonTheme(
          data: data,
          duration: const Duration(milliseconds: 200),
          child: Builder(
            builder: (BuildContext context) {
              observed = CarbonTheme.of(context).background;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(tree(CarbonThemeData.white));
    expect(observed, CarbonThemeData.white.background);

    await tester.pumpWidget(tree(CarbonThemeData.gray100));
    await tester.pump();
    expect(observed, CarbonThemeData.gray100.background);
  });
}

/// A harness that swaps the [CarbonTheme] data while keeping its child stable.
class _ThemeSwitcher extends StatefulWidget {
  const _ThemeSwitcher({super.key, required this.child});

  final Widget child;

  @override
  State<_ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<_ThemeSwitcher> {
  CarbonThemeData _data = CarbonThemeData.white;

  void setData(CarbonThemeData data) => setState(() => _data = data);

  @override
  Widget build(BuildContext context) =>
      CarbonTheme(data: _data, child: widget.child);
}
