// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Structural locks for the generated icon data. The counts are intentional:
// they pin the generated set to the pinned Carbon submodule and must be
// updated (consciously) when the submodule is bumped. Full visual fidelity
// against upstream rasters is #32's sweep.

import 'package:carbide/carbide.dart';
import 'package:carbide/src/icons/svg_path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../spike/spike_icon_data.dart';
import '../spike/support.dart';
import 'all_icons.dart';

void main() {
  test('the full Carbon registry is generated (2,715 icons)', () {
    expect(allCarbonIcons, hasLength(2715));
  });

  test('asset counts match the source tree', () {
    int assets = 0;
    final Map<int?, int> bySize = <int?, int>{};
    for (final CarbonIconData icon in allCarbonIcons) {
      assets += icon.artwork.length;
      for (final CarbonIconArtwork artwork in icon.artwork) {
        bySize[artwork.size] = (bySize[artwork.size] ?? 0) + 1;
      }
    }
    expect(assets, 2809);
    expect(bySize[null], 18, reason: 'bespoke glyph assets');
    expect(bySize[16], 68);
    expect(bySize[20], 9);
    expect(bySize[24], 8);
    expect(bySize[32], 2706);
  });

  test('icon names are unique and artwork is ordered', () {
    final Set<String> names = <String>{};
    for (final CarbonIconData icon in allCarbonIcons) {
      expect(names.add(icon.name), isTrue, reason: 'duplicate ${icon.name}');
      for (int i = 1; i < icon.artwork.length; i++) {
        final int previous = icon.artwork[i - 1].size ?? -1;
        final int current = icon.artwork[i].size ?? -1;
        expect(
          current,
          greaterThan(previous),
          reason: '${icon.name} artwork out of order',
        );
      }
      for (final CarbonIconArtwork artwork in icon.artwork) {
        if (artwork.size != null) {
          expect(artwork.viewBoxWidth, artwork.viewBoxHeight);
        }
      }
    }
  });

  test('every shape of every asset parses to a non-empty path', () {
    for (final CarbonIconData icon in allCarbonIcons) {
      for (final CarbonIconArtwork artwork in icon.artwork) {
        expect(artwork.shapes, isNotEmpty, reason: icon.name);
        for (final CarbonIconShape shape in artwork.shapes) {
          final bounds = parseSvgPath(shape.d).getBounds();
          expect(bounds.isEmpty, isFalse, reason: '${icon.name}: empty shape');
        }
      }
    }
  });

  test('generated data matches the independently extracted spike fixture', () {
    // The spike extractor and the pipeline share normalization but run
    // independently; equal output catches emission regressions.
    final Map<String, SpikeIcon> spike = <String, SpikeIcon>{
      for (final SpikeIcon icon in spikeIcons) icon.name: icon,
    };
    void check(String spikeName, CarbonIconData generated, int size) {
      final SpikeIcon reference = spike[spikeName]!;
      final CarbonIconArtwork artwork = generated.artwork.firstWhere(
        (CarbonIconArtwork a) => a.size == size,
      );
      // The pipeline collapses whitespace in d; the spike fixture carries the
      // raw XML-normalized spacing. Compare whitespace-insensitively.
      String norm(String d) => d.split(RegExp(r'\s+')).join(' ').trim();
      expect(artwork.shapes, hasLength(reference.shapes.length));
      for (int i = 0; i < artwork.shapes.length; i++) {
        expect(
          norm(artwork.shapes[i].d),
          norm(reference.shapes[i].d),
          reason: '$spikeName shape $i',
        );
        expect(artwork.shapes[i].evenOdd, reference.shapes[i].evenOdd);
      }
    }

    check('add', CarbonIcons.add, 32);
    check('apps_16', CarbonIcons.apps, 16);
    check('apps_32', CarbonIcons.apps, 32);
    check('misuse', CarbonIcons.misuse, 32);
    check('logo_wechat', CarbonIcons.logoWechat, 32);
    check('airport_location', CarbonIcons.airportLocation, 32);
    check('accessibility_alt', CarbonIcons.accessibilityAlt, 32);
    check('q_bloch_sphere', CarbonIcons.qBlochSphere, 32);
    check('wh_3d_cursor_alt', CarbonIcons.watsonHealth3DCursorAlt, 32);
  });

  test('multi-size icons carry their bespoke artwork', () {
    expect(
      CarbonIcons.apps.artwork.map((CarbonIconArtwork a) => a.size),
      <int?>[16, 32],
    );
    expect(
      CarbonIcons.caretDown.artwork.map((CarbonIconArtwork a) => a.size),
      <int?>[null, 32],
      reason: 'caret--down has a bespoke glyph asset',
    );
    expect(CarbonIcons.add.artwork.map((CarbonIconArtwork a) => a.size), <int?>[
      32,
    ]);
  });
}
