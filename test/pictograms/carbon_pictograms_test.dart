// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Structural locks + the full fidelity sweep for the generated pictogram
// data, plus the CarbonPictogram widget contract. Counts pin the set to the
// pinned Carbon submodule; update them consciously on a bump.

import 'dart:io';
import 'dart:typed_data';

import 'package:carbide/carbide.dart';
import 'package:carbide/src/icons/svg_path_parser.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fidelity.dart';
import '../support/golden.dart';
import 'all_pictograms.dart';

const double maxCoverageMismatch = 0.005;
const String referenceDir = 'test/pictograms/references';

Widget _host(Widget child, {CarbonThemeData? theme}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: theme ?? CarbonThemeData.white,
    child: Center(child: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('structure', () {
    test('the full pictogram registry is generated (1,572)', () {
      expect(allCarbonPictograms, hasLength(1572));
    });

    test('names are unique; each has one 32-grid artwork', () {
      final Set<String> names = <String>{};
      for (final CarbonIconData pictogram in allCarbonPictograms) {
        expect(names.add(pictogram.name), isTrue, reason: pictogram.name);
        expect(pictogram.artwork, hasLength(1));
        final CarbonIconArtwork artwork = pictogram.artwork.single;
        expect(artwork.size, 32);
        expect(artwork.viewBoxWidth, 32);
        expect(artwork.viewBoxHeight, 32);
      }
    });

    test('every shape parses to a non-empty path', () {
      for (final CarbonIconData pictogram in allCarbonPictograms) {
        for (final CarbonIconShape shape in pictogram.artwork.single.shapes) {
          expect(
            parseSvgPath(shape.d).getBounds().isEmpty,
            isFalse,
            reason: pictogram.name,
          );
        }
      }
    });
  });

  test(
    'every pictogram matches its upstream raster',
    () async {
      final Stopwatch watch = Stopwatch()..start();
      final List<String> failures = <String>[];
      double worst = 0;
      for (final CarbonIconData pictogram in allCarbonPictograms) {
        final CarbonIconArtwork artwork = pictogram.artwork.single;
        const int size = 64;
        final Uint8List png = File(
          '$referenceDir/${pictogram.name}_32.png',
        ).readAsBytesSync();
        final Uint8List ours = await renderArtworkAlpha(artwork, size, size);
        final Uint8List reference = await decodePngAlpha(png, size, size);
        final FidelityResult result = compareAlphaRect(
          ours,
          reference,
          size,
          size,
        );
        if (result.coverageMismatchFraction > worst) {
          worst = result.coverageMismatchFraction;
        }
        if (result.coverageMismatchFraction > maxCoverageMismatch) {
          failures.add(
            '${pictogram.name}: coverage '
            '${(result.coverageMismatchFraction * 100).toStringAsFixed(3)}%',
          );
        }
      }
      watch.stop();
      debugPrint(
        'pictogram sweep: ${allCarbonPictograms.length} assets in '
        '${watch.elapsed.inSeconds}s; worst coverage mismatch '
        '${(worst * 100).toStringAsFixed(3)}%',
      );
      expect(failures, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  group('CarbonPictogram widget', () {
    testWidgets('renders at the 48px minimum by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonPictogram(CarbonPictograms.solarPanel)),
      );
      expect(tester.getSize(find.byType(CarbonPictogram)), const Size(48, 48));
    });

    test('sizes below the Carbon minimum assert', () {
      expect(
        () => CarbonPictogram(CarbonPictograms.solarPanel, size: 32),
        throwsAssertionError,
      );
    });

    testWidgets('color defaults to the theme iconPrimary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPictogram(CarbonPictograms.solarPanel),
          theme: CarbonThemeData.gray100,
        ),
      );
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CarbonPictogram),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(
        (paint.painter! as CarbonIconPainter).color,
        CarbonThemeData.gray100.iconPrimary,
      );
    });

    testWidgets('decorative by default; semanticLabel exposes an image', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonPictogram(CarbonPictograms.solarPanel)),
      );
      expect(tester.getSemantics(find.byType(CarbonPictogram)).label, isEmpty);
      await tester.pumpWidget(
        _host(
          const CarbonPictogram(
            CarbonPictograms.solarPanel,
            semanticLabel: 'Solar panel',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Solar panel'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('pictogram specimen across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'carbon_pictogram',
        size: const Size(140, 72),
        builder: (BuildContext context) => const Center(
          child: CarbonPictogram(CarbonPictograms.solarPanel, size: 64),
        ),
      );
    });
  });
}
