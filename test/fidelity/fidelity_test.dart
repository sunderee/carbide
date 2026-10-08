// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Upstream fidelity check (epic W3). For each component that has both a
// committed Carbon Storybook reference (test/fidelity/references/<c>/<theme>.png,
// captured by tool/fidelity/) and a shared Carbide fixture, this renders the
// Carbide equivalent and writes a side-by-side comparison image
// (Carbon | Carbide) to test/fidelity/comparisons/ for human review on every PR.
//
// It is deliberately NOT a strict pixel gate: Carbon renders in Chromium and
// Carbide in Flutter, so exact pixels can never match. The committed references
// are real upstream ground truth; the side-by-side is the review surface; the
// assertions reject blank renders, drift beyond measured per-story budgets,
// changed control dimensions, incorrect token fills and default-state changes.
// The metric remains a 24x24 luminance grid; it cannot establish pixel identity
// or complete variant coverage. Scores and actual sizes are always emitted for
// reviewed Linux calibration, with rationales recorded in stories.json.
//
// Reference freshness (#344) uses committed provenance and the parent gitlink.
// Missing versions, unreviewed pins and out-of-window batches fail in normal CI
// without checking out the Carbon sources.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overlay_entries.dart';
import 'support/fixtures.dart';
import 'support/freshness.dart';
import 'support/structural.dart';

const String _mutation = String.fromEnvironment('FIDELITY_MUTATION');

const String _refDir = 'test/fidelity/references';
const String _outDir = 'test/fidelity/comparisons';
const String _storiesPath = 'tool/fidelity/stories.json';

/// Capture environment and drift budgets are reviewed with each story.
final Map<String, Map<String, dynamic>> _stories =
    <String, Map<String, dynamic>>{
      for (final dynamic story
          in (jsonDecode(File(_storiesPath).readAsStringSync())
                  as Map<String, dynamic>)['stories']
              as List<dynamic>)
        (story as Map<String, dynamic>)['component'] as String: story,
    };

final Map<String, double> _thresholds = <String, double>{
  for (final MapEntry<String, Map<String, dynamic>> story in _stories.entries)
    if (story.value['threshold'] is num)
      story.key: (story.value['threshold'] as num).toDouble(),
};

/// The four Carbon themes, keyed by the reference-file slug (the Storybook
/// theme global).
const Map<String, CarbonThemeData Function()> _themes =
    <String, CarbonThemeData Function()>{
      'white': _whiteTheme,
      'g10': _g10Theme,
      'g90': _g90Theme,
      'g100': _g100Theme,
    };

CarbonThemeData _whiteTheme() => CarbonThemeData.white;
CarbonThemeData _g10Theme() => CarbonThemeData.gray10;
CarbonThemeData _g90Theme() => CarbonThemeData.gray90;
CarbonThemeData _g100Theme() => CarbonThemeData.gray100;

void main() {
  test(
    'every capture is versioned and reviewed against the parent gitlink',
    () {
      final ProcessResult git = Process.runSync('git', <String>[
        'ls-tree',
        'HEAD',
        'documentation/carbon',
      ]);
      expect(git.exitCode, 0);
      final String gitlink = (git.stdout as String).trim().split(
        RegExp(r'\s+'),
      )[2];
      verifyReferenceFreshness(
        pin: jsonDecode(
          File('tool/carbon_reference.lock.json').readAsStringSync(),
        ) as Map<String, dynamic>,
        manifest: jsonDecode(
          File('$_refDir/manifest.json').readAsStringSync(),
        ) as Map<String, dynamic>,
        gitlink: gitlink,
        components: _stories.keys.toSet(),
      );
    },
  );

  for (final String mutation in <String>['button-color', 'button-spacing']) {
    testWidgets('promoted Button gate rejects $mutation', (tester) async {
      final (ui.Image image, Size size) = await _renderCarbide(
        tester,
        CarbonThemeData.white,
        'button',
        'white',
        fidelityBuilders['button']!(),
        mutation: mutation,
      );
      try {
        await expectLater(
          checkFidelityStructure(
            tester,
            'button',
            CarbonThemeData.white,
            size,
            image,
            _stories['button']!['structural'] as Map<String, dynamic>,
          ),
          throwsA(
            isA<TestFailure>().having(
              (error) => error.message,
              'reason',
              contains(
                mutation == 'button-color'
                    ? 'token colour'
                    : 'structural width',
              ),
            ),
          ),
        );
      } finally {
        image.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }

  testWidgets('promoted Button disabled state paints its disabled token', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final (ui.Image image, Size size) = await _renderCarbide(
      tester,
      CarbonThemeData.white,
      'button',
      'white',
      const IntrinsicWidth(child: CarbonButton(label: 'Button')),
    );
    try {
      expect(size.height, 48);
      expect(
        await _pixelRgb(tester, image, const Offset(5, 24)),
        CarbonThemeData.white.buttonDisabled.toARGB32() & 0xffffff,
      );
      expect(
        tester
            .getSemantics(find.byType(CarbonButton))
            .getSemanticsData()
            .flagsCollection
            .isEnabled
            .name,
        'isFalse',
      );
    } finally {
      image.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    }
  });
  testWidgets('promoted Button focused state paints its focus ring', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final FocusNode focus = FocusNode();
    final FocusHighlightStrategy previous =
        FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    final (ui.Image image, Size size) = await _renderCarbide(
      tester,
      CarbonThemeData.white,
      'button',
      'white',
      IntrinsicWidth(
        child: CarbonButton(
          label: 'Button',
          onPressed: () {},
          focusNode: focus,
          autofocus: true,
        ),
      ),
    );
    try {
      expect(size.height, 48);
      expect(focus.hasPrimaryFocus, isTrue);
      expect(
        await _pixelRgb(tester, image, const Offset(3, 24)),
        CarbonThemeData.white.background.toARGB32() & 0xffffff,
      );
    } finally {
      image.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      focus.dispose();
      semantics.dispose();
      FocusManager.instance.highlightStrategy = previous;
    }
  });
  testWidgets('promoted text input invalid state paints its error border', (
    tester,
  ) async {
    final (ui.Image image, Size size) = await _renderCarbide(
      tester,
      CarbonThemeData.white,
      'text-input',
      'white',
      const SizedBox(
        width: 300,
        child: CarbonTextInput(
          labelText: 'Label text',
          invalid: true,
          invalidText: 'Invalid value',
        ),
      ),
    );
    try {
      expect(size.width, 300);
      expect(find.text('Invalid value'), findsOneWidget);
      expect(
        await _pixelRgb(tester, image, const Offset(0, 30)),
        CarbonThemeData.white.supportError.toARGB32() & 0xffffff,
      );
    } finally {
      image.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  for (final MapEntry<String, Widget Function()> entry
      in fidelityBuilders.entries) {
    final String component = entry.key;
    for (final String themeSlug in _themes.keys) {
      testWidgets('fidelity: $component ($themeSlug)', (
        WidgetTester tester,
      ) async {
        final File refFile = File('$_refDir/$component/$themeSlug.png');
        if (!refFile.existsSync()) {
          markTestSkipped('no reference for $component/$themeSlug');
          return;
        }

        final (ui.Image carbide, Size controlSize) = await _renderCarbide(
          tester,
          _themes[themeSlug]!(),
          component,
          themeSlug,
          entry.value(),
          mutation: component == 'button' ? _mutation : '',
        );
        final _Grid carbideGrid = await _luminanceGrid(tester, carbide);

        final ui.Image reference = await _decodePng(
          tester,
          refFile.readAsBytesSync(),
        );
        final _Grid refGrid = await _luminanceGrid(tester, reference);
        final double diff = _meanAbsDiff(refGrid, carbideGrid);

        debugPrint(
          'FIDELITY-SCORE $component $themeSlug ${diff.toStringAsFixed(6)}',
        );

        final ui.Image comparison = await _composeSideBySide(
          tester,
          reference,
          carbide,
          label: '$component — $themeSlug   (coarse diff ${_pct(diff)})',
        );
        await _writePng(
          tester,
          comparison,
          '$_outDir/${component}_$themeSlug.png',
        );
        await checkFidelityStructure(
          tester,
          component,
          _themes[themeSlug]!(),
          controlSize,
          carbide,
          _stories[component]!['structural'] as Map<String, dynamic>,
        );
        comparison.dispose();
        reference.dispose();
        carbide.dispose();

        // The hard gate: Carbide rendered something with real contrast, not a
        // blank or single-colour box. (A clipped-to-nothing or collapsed
        // component would fail here.)
        expect(
          carbideGrid.range,
          greaterThan(0.1),
          reason: '$component ($themeSlug) rendered blank/flat',
        );

        // The drift gate: the measured per-story threshold
        // bounds the coarse diff. No threshold yet → bootstrap line for
        // harvesting one (score + margin goes into stories.json).
        final double? threshold = _thresholds[component];
        if (threshold != null) {
          expect(
            diff,
            lessThanOrEqualTo(threshold),
            reason:
                '$component ($themeSlug) drifted from its committed '
                'upstream reference (diff ${_pct(diff)} > threshold '
                '${_pct(threshold)}) — inspect '
                '$_outDir/${component}_$themeSlug.png; if the change is '
                'intentional, re-baseline the threshold in '
                '$_storiesPath.',
          );
        } else {
          debugPrint(
            'FIDELITY-SCORE $component $themeSlug ${diff.toStringAsFixed(4)}',
          );
        }
      });
    }
  }
}

/// Renders [child] under [theme] and rasterizes it at 2x.
Future<(ui.Image, Size)> _renderCarbide(
  WidgetTester tester,
  CarbonThemeData theme,
  String component,
  String themeSlug,
  Widget child, {
  String mutation = '',
}) async {
  if (mutation == 'button-spacing') {
    child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: child,
    );
  }
  final CarbonThemeData renderTheme = mutation == 'button-color'
      ? theme.copyWith(buttonPrimary: const Color(0xffda1e28))
      : theme;
  final GlobalKey key = GlobalKey();
  final GlobalKey scene = GlobalKey();
  final Map<String, dynamic> fixture =
      _stories[component]!['fixture'] as Map<String, dynamic>;
  final List<dynamic> dimensions = fixture['viewport'] as List<dynamic>;
  final Size viewport = Size(
    (dimensions[0] as num).toDouble(),
    (dimensions[1] as num).toDouble(),
  );
  final Map<String, dynamic> rect = fixture['root'] as Map<String, dynamic>;
  final Rect storyRoot = Rect.fromLTWH(
    (rect['x'] as num).toDouble(),
    (rect['y'] as num).toDouble(),
    (rect['width'] as num).toDouble(),
    (rect['height'] as num).toDouble(),
  );
  await tester.binding.setSurfaceSize(viewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final Widget root = RepaintBoundary(
    key: key,
    child: ColoredBox(
      color: theme.background,
      child: SizedBox(
        width: storyRoot.width,
        child: Align(
          alignment: Alignment.topLeft,
          heightFactor: 1,
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: MediaQueryData(size: viewport),
        child: CarbonTheme(
          data: renderTheme,
          child: DefaultTextStyle(
            style: CarbonTypeStyles.body02.copyWith(color: theme.textPrimary),
            child: RepaintBoundary(
              key: scene,
              child: ColoredBox(
                color: theme.background,
                child: TapRegionSurface(
                  child: Overlay(
                    initialEntries: <OverlayEntry>[
                      managedOverlayEntry(
                        builder: (_) => component == 'modal'
                            ? child
                            : component == 'tooltip'
                            ? Center(child: root)
                            : Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: storyRoot.left,
                                    top: storyRoot.top,
                                  ),
                                  child: root,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 300));
  final Size controlSize = fidelityControlSize(tester, component, child);
  debugPrint(
    'FIDELITY-SIZE $component $themeSlug ${controlSize.width.toStringAsFixed(6)} ${controlSize.height.toStringAsFixed(6)}',
  );
  final RenderRepaintBoundary boundary =
      (component == 'modal' ? scene : key).currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
  final ui.Image rendered = (await tester.runAsync<ui.Image>(
    () => boundary.toImage(pixelRatio: 2),
  ))!;
  if (component != 'modal') return (rendered, controlSize);
  // Storybook screenshots #storybook-root, a 48px launcher-sized rectangle,
  // even though its open modal paints across the viewport. Keep that original
  // crop; also retain the full scene so humans can inspect the complete form.
  await _writePng(tester, rendered, '$_outDir/modal_full_$themeSlug.png');
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    rendered,
    Rect.fromLTWH(
      storyRoot.left * 2,
      storyRoot.top * 2,
      storyRoot.width * 2,
      storyRoot.height * 2,
    ),
    Rect.fromLTWH(0, 0, storyRoot.width * 2, storyRoot.height * 2),
    Paint(),
  );
  final ui.Picture picture = recorder.endRecording();
  final ui.Image cropped = await picture.toImage(
    (storyRoot.width * 2).ceil(),
    (storyRoot.height * 2).ceil(),
  );
  picture.dispose();
  rendered.dispose();
  return (cropped, controlSize);
}

Future<ui.Image> _decodePng(WidgetTester tester, Uint8List bytes) async {
  return (await tester.runAsync<ui.Image>(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }))!;
}

/// A downsampled luminance grid used for the coarse, framing-tolerant metric.
class _Grid {
  _Grid(this.cells, this.range);
  static const int n = 24;
  final List<double> cells; // n*n luminance values in 0..1.

  /// Exact pixel luminance range, independent of grid sampling. Tiny icon
  /// triggers can fall entirely between the coarse metric's sample points.
  final double range;
}

Future<_Grid> _luminanceGrid(WidgetTester tester, ui.Image image) async {
  final ByteData data = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final int w = image.width;
  final int h = image.height;
  const int n = _Grid.n;
  final List<double> cells = List<double>.filled(n * n, 0);
  final List<int> counts = List<int>.filled(n * n, 0);
  final Uint8List bytes = data.buffer.asUint8List();
  // Sample on a stride so huge references stay cheap.
  final int strideX = (w / (n * 4)).ceil().clamp(1, 1 << 20);
  final int strideY = (h / (n * 4)).ceil().clamp(1, 1 << 20);
  for (int y = 0; y < h; y += strideY) {
    final int gy = (y * n ~/ h).clamp(0, n - 1);
    for (int x = 0; x < w; x += strideX) {
      final int i = (y * w + x) * 4;
      final double r = bytes[i] / 255;
      final double g = bytes[i + 1] / 255;
      final double b = bytes[i + 2] / 255;
      final double lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
      final int gx = (x * n ~/ w).clamp(0, n - 1);
      final int idx = gy * n + gx;
      cells[idx] += lum;
      counts[idx]++;
    }
  }
  for (int i = 0; i < cells.length; i++) {
    if (counts[i] > 0) {
      cells[i] /= counts[i];
    }
  }
  double darkest = 1, brightest = 0;
  for (int i = 0; i < bytes.length; i += 4) {
    final double lum =
        (0.2126 * bytes[i] + 0.7152 * bytes[i + 1] + 0.0722 * bytes[i + 2]) /
        255;
    darkest = math.min(darkest, lum);
    brightest = math.max(brightest, lum);
  }
  return _Grid(cells, brightest - darkest);
}

double _meanAbsDiff(_Grid a, _Grid b) {
  double sum = 0;
  for (int i = 0; i < a.cells.length; i++) {
    sum += (a.cells[i] - b.cells[i]).abs();
  }
  return sum / a.cells.length;
}

/// Composes a labelled [reference] | [carbide] panel.
Future<ui.Image> _composeSideBySide(
  WidgetTester tester,
  ui.Image reference,
  ui.Image carbide, {
  required String label,
}) async {
  const double paneW = 680;
  const double paneH = 320;
  const double gap = 16;
  const double header = 44;
  const double pad = 16;
  const double width = pad * 2 + paneW * 2 + gap;
  const double height = header + paneH + pad;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xFF161616),
  );
  _text(canvas, label, const Offset(pad, 14), const Color(0xFFF4F4F4), 16);
  _text(
    canvas,
    'Carbon (reference)',
    const Offset(pad, header - 2),
    const Color(0xFF8D8D8D),
    11,
  );
  _text(
    canvas,
    'Carbide',
    const Offset(pad + paneW + gap, header - 2),
    const Color(0xFF8D8D8D),
    11,
  );

  _drawContained(
    canvas,
    reference,
    const Rect.fromLTWH(pad, header, paneW, paneH - 14),
  );
  _drawContained(
    canvas,
    carbide,
    const Rect.fromLTWH(pad + paneW + gap, header, paneW, paneH - 14),
  );

  final ui.Picture picture = recorder.endRecording();
  final ui.Image composed = (await tester.runAsync<ui.Image>(
    () => picture.toImage(width.ceil(), height.ceil()),
  ))!;
  picture.dispose();
  return composed;
}

void _drawContained(Canvas canvas, ui.Image image, Rect area) {
  canvas.drawRect(area, Paint()..color = const Color(0xFF262626));
  final double iw = image.width.toDouble();
  final double ih = image.height.toDouble();
  final double scale = math.min(area.width / iw, area.height / ih);
  final double dw = iw * scale;
  final double dh = ih * scale;
  final Rect dst = Rect.fromLTWH(
    area.left + (area.width - dw) / 2,
    area.top + (area.height - dh) / 2,
    dw,
    dh,
  );
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, iw, ih),
    dst,
    Paint()..filterQuality = FilterQuality.medium,
  );
}

void _text(Canvas canvas, String text, Offset at, Color color, double size) {
  final ui.ParagraphBuilder builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontFamily: CarbonFontFamily.sans,
            fontSize: size,
            maxLines: 1,
            ellipsis: '…',
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(text);
  final ui.Paragraph p = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 1400));
  canvas.drawParagraph(p, at);
}

Future<void> _writePng(WidgetTester tester, ui.Image image, String path) async {
  final ByteData? png = await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  final File file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(png!.buffer.asUint8List());
}

String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

Future<int> _pixelRgb(WidgetTester tester, ui.Image image, Offset point) async {
  final ByteData data = (await tester.runAsync<ByteData?>(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final int index =
      ((point.dy * 2).round() * image.width + (point.dx * 2).round()) * 4;
  return (data.getUint8(index) << 16) |
      (data.getUint8(index + 1) << 8) |
      data.getUint8(index + 2);
}
