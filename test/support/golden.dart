// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four Carbon themes, used to snapshot a widget on each one.
///
/// Each variant exposes its full [theme] token set, so goldens render against
/// the real semantic tokens. [background] is a convenience for the host
/// backdrop.
enum CarbonThemeVariant {
  /// The White theme.
  white('white'),

  /// The Gray 10 theme.
  gray10('g10'),

  /// The Gray 90 theme.
  gray90('g90'),

  /// The Gray 100 theme.
  gray100('g100');

  const CarbonThemeVariant(this.label);

  /// Short, file-safe identifier used in golden file names.
  final String label;

  /// The full semantic token set for this theme.
  CarbonThemeData get theme => switch (this) {
    CarbonThemeVariant.white => CarbonThemeData.white,
    CarbonThemeVariant.gray10 => CarbonThemeData.gray10,
    CarbonThemeVariant.gray90 => CarbonThemeData.gray90,
    CarbonThemeVariant.gray100 => CarbonThemeData.gray100,
  };

  /// The theme's base background color, used as the golden backdrop.
  Color get background => theme.background;
}

/// Pumps [child] in a deterministic host and snapshots it on every
/// [CarbonThemeVariant] background.
///
/// Produces one golden per theme at `goldens/<name>.<variant>.png`. The host
/// fixes text scaling, surface size, and direction so output depends only on
/// the widget under test. Builds with [builder] so the widget can read its
/// `BuildContext` (and, later, theme tokens).
///
/// Set [containsText] when the snapshot renders glyphs: the golden is named
/// `<name>.text.<variant>.png`, which the comparator treats as
/// Linux-authoritative (glyph rasterization differs across platforms —
/// generate these with the “Regenerate goldens” workflow, not locally).
///
/// For animated widgets, [pumpBeforeSnapshot] advances the clock by a fixed
/// amount after the initial frame, capturing a deterministic mid-animation
/// frame: each theme variant re-pumps under a fresh key, so animations
/// restart from zero and every variant snapshots the same cycle position.
///
/// [afterPump] runs once per variant after the initial frame, before the
/// snapshot, so a test can stage an interactive state — typically focusing a
/// node to capture a focus ring (custom-painted geometry that the state-matrix
/// tests assert by token but never pin as pixels). It should settle any
/// resulting animation itself (e.g. `await tester.pumpAndSettle()`). Pair it
/// with `FocusHighlightStrategy.alwaysTraditional` so the ring actually paints.
///
/// [directions] adds a direction axis: the default `{ltr}` keeps the golden
/// count flat repo-wide, while `{ltr, rtl}` re-snapshots every theme under
/// `Directionality(rtl)` as `goldens/<name>[.text].<variant>.rtl.png`. Opt in
/// for components with direction-sensitive geometry (mirrored fills, side
/// accents, submenu sides); direction-neutral components stay LTR-only.
///
/// [mediaQuery] overrides the host's `MediaQueryData` — the default pins
/// text scale 1.0 like always. Use sparingly (docs/text-scaling.md): the
/// text-input 1.3x canary is the intended kind of use, not per-component
/// scaled variants.
///
/// [strict] names the golden `<name>.strict[.text].<variant>.png`, which
/// the comparator bounds at 0.05% differing pixels instead of the default
/// 0.5% (#236). Opt in for small-surface goldens, where 0.5% of the area
/// is whole feature-rows of pixels.
///
/// [devicePixelRatio] paints the scene through a scale transform, the way
/// a fractional-DPR display rasterizes it — 1px hairlines land on
/// physical-pixel boundaries and anti-alias exactly as they would on a
/// 1.5x screen. The surface (and golden) is `size × devicePixelRatio`.
/// Used by the DPR canaries (#236); leave at 1.0 elsewhere.
Future<void> expectThemeGoldens(
  WidgetTester tester, {
  required String name,
  required Size size,
  required WidgetBuilder builder,
  bool containsText = false,
  Duration? pumpBeforeSnapshot,
  Future<void> Function(WidgetTester tester)? afterPump,
  Set<TextDirection> directions = const <TextDirection>{TextDirection.ltr},
  MediaQueryData mediaQuery = const MediaQueryData(),
  bool strict = false,
  double devicePixelRatio = 1.0,
}) async {
  assert(directions.isNotEmpty, 'directions must name at least one direction');
  final Size surface = size * devicePixelRatio;
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  for (final TextDirection direction in directions) {
    final String directionSuffix = direction == TextDirection.rtl ? '.rtl' : '';
    for (final CarbonThemeVariant variant in CarbonThemeVariant.values) {
      final Key key = ValueKey<String>(
        'carbide-golden-${variant.label}$directionSuffix',
      );
      Widget scene = SizedBox.fromSize(
        size: size,
        child: ColoredBox(
          color: variant.background,
          child: Builder(builder: builder),
        ),
      );
      if (devicePixelRatio != 1.0) {
        scene = SizedBox.fromSize(
          size: surface,
          child: Transform.scale(
            scale: devicePixelRatio,
            alignment: AlignmentDirectional.topStart,
            child: scene,
          ),
        );
      }
      await tester.pumpWidget(
        Directionality(
          textDirection: direction,
          child: RepaintBoundary(
            key: key,
            child: MediaQuery(
              data: mediaQuery,
              child: CarbonTheme(data: variant.theme, child: scene),
            ),
          ),
        ),
      );
      await tester.pump();
      if (afterPump != null) {
        await afterPump(tester);
      }
      if (pumpBeforeSnapshot != null) {
        await tester.pump(pumpBeforeSnapshot);
      }
      final String strictSuffix = strict ? '.strict' : '';
      final String suffix = containsText ? '.text' : '';
      await expectLater(
        find.byKey(key),
        matchesGoldenFile(
          'goldens/$name$strictSuffix$suffix'
          '.${variant.label}$directionSuffix.png',
        ),
      );
    }
  }
}
