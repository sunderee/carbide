// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Upstream fidelity check (epic W3). For each component that has both a
// committed Carbon Storybook reference (test/fidelity/references/<c>/<theme>.png,
// captured by tool/fidelity/) and a Carbide builder below, this renders the
// Carbide equivalent and writes a side-by-side comparison image
// (Carbon | Carbide) to test/fidelity/comparisons/ for human review on every PR.
//
// It is deliberately NOT a strict pixel gate: Carbon renders in Chromium and
// Carbide in Flutter, so exact pixels can never match. The committed references
// are real upstream ground truth; the side-by-side is the review surface; the
// hard assertions are (a) Carbide renders something non-trivial and (b) the
// coarse luminance-grid diff stays within the story's committed `threshold`
// (#230) — a soft drift gate, per-component and deliberately lax, because the
// value is drift *detection* across renderers, not pixel identity. Stories
// without a threshold print a `FIDELITY-SCORE` bootstrap line instead.
//
// Reference freshness (#230): the manifest stamps the @carbon/react version
// the live Storybook ran at capture; a check below warns when the submodule
// pin drifts ≥2 minors ahead of the captured references.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const String _refDir = 'test/fidelity/references';
const String _outDir = 'test/fidelity/comparisons';
const String _storiesPath = 'tool/fidelity/stories.json';
const String _submodulePackage =
    'documentation/carbon/packages/react/package.json';

/// Per-component drift thresholds from stories.json (absent → bootstrap).
final Map<String, double> _thresholds = () {
  final Map<String, dynamic> stories =
      jsonDecode(File(_storiesPath).readAsStringSync())
          as Map<String, dynamic>;
  return <String, double>{
    for (final dynamic s in stories['stories'] as List<dynamic>)
      if ((s as Map<String, dynamic>)['threshold'] != null)
        s['component'] as String: (s['threshold'] as num).toDouble(),
  };
}();

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

void _noop() {}

/// Carbide widgets that mirror the captured Carbon default stories. Add an
/// entry (plus a story in tool/fidelity/stories.json) to extend coverage.
final Map<String, Widget Function()> _builders = <String, Widget Function()>{
  'button': () => CarbonButton(label: 'Button', onPressed: _noop),
  'tag': () => const Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      CarbonTag(label: 'Tag', type: CarbonTagType.gray),
      CarbonTag(label: 'Tag', type: CarbonTagType.blue),
      CarbonTag(label: 'Tag', type: CarbonTagType.green),
      CarbonTag(label: 'Tag', type: CarbonTagType.red),
    ],
  ),
  'checkbox': () =>
      CarbonCheckbox(label: 'Checkbox', value: true, onChanged: (_) {}),
  'toggle': () =>
      CarbonToggle(labelText: 'Toggle', toggled: true, onToggled: (_) {}),
  'text-input': () => const SizedBox(
    width: 320,
    child: CarbonTextInput(
      labelText: 'Text input label',
      placeholder: 'Placeholder text',
    ),
  ),
  'tree-view': () => SizedBox(
    width: 320,
    child: CarbonTreeView(
      label: 'Tree view',
      initiallyExpandedIds: const <Object>{'a'},
      nodes: const <CarbonTreeNode>[
        CarbonTreeNode(
          id: 'a',
          label: 'Artificial intelligence',
          children: <CarbonTreeNode>[
            CarbonTreeNode(id: 'a1', label: 'Machine learning'),
            CarbonTreeNode(id: 'a2', label: 'Deep learning'),
          ],
        ),
        CarbonTreeNode(id: 'b', label: 'Blockchain'),
      ],
    ),
  ),
  'data-table': () => SizedBox(
    width: 640,
    child: CarbonDataTable(
      columns: const <CarbonTableColumn>[
        CarbonTableColumn(title: 'Name'),
        CarbonTableColumn(title: 'Rule'),
        CarbonTableColumn(title: 'Status'),
      ],
      rows: const <CarbonTableRow>[
        CarbonTableRow(
          cells: <Widget>[
            Text('Load Balancer 1'),
            Text('Round robin'),
            Text('Starting'),
          ],
        ),
        CarbonTableRow(
          cells: <Widget>[
            Text('Load Balancer 2'),
            Text('DNS delegation'),
            Text('Active'),
          ],
        ),
        CarbonTableRow(
          cells: <Widget>[
            Text('Load Balancer 3'),
            Text('Round robin'),
            Text('Disabled'),
          ],
        ),
      ],
    ),
  ),
  'notification': () => const SizedBox(
    width: 480,
    child: CarbonInlineNotification(
      kind: CarbonNotificationKind.error,
      title: 'Notification title',
      subtitle: 'Subtitle text goes here.',
    ),
  ),
};

void main() {
  test('references are not stale relative to the submodule pin', () {
    final File pkg = File(_submodulePackage);
    if (!pkg.existsSync()) {
      // CI checks out without the documentation submodules; the check
      // only runs where the pin is present (local dev, capture time).
      markTestSkipped('submodule not checked out');
      return;
    }
    final Map<String, dynamic> manifest =
        jsonDecode(File('$_refDir/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    // Fresh captures stamp a top-level version; the hand-merged manifest
    // carries per-batch stamps. Use the newest non-null one.
    final List<String> stamped = <String>[
      if (manifest['carbonReactVersion'] is String)
        manifest['carbonReactVersion'] as String,
      if (manifest['captures'] is List)
        for (final dynamic c in manifest['captures'] as List<dynamic>)
          if ((c as Map<String, dynamic>)['carbonReactVersion'] is String)
            c['carbonReactVersion'] as String,
    ];
    if (stamped.isEmpty) {
      markTestSkipped('no capture version stamped (pre-#230 references)');
      return;
    }
    int minor(String v) => int.parse(v.split('.')[1]);
    final int captured = stamped.map(minor).reduce(math.max);
    final String pinVersion =
        (jsonDecode(pkg.readAsStringSync())
                as Map<String, dynamic>)['version']
            as String;
    final int pin = minor(pinVersion);
    if (pin - captured >= 2) {
      // A warning, not a failure: stale references still detect drift,
      // they just measure against an older upstream. Re-capture via
      // tool/fidelity/capture.sh when this fires.
      debugPrint(
        'WARNING: fidelity references were captured at @carbon/react '
        'minor $captured but the submodule pin is at minor $pin — '
        're-capture (tool/fidelity/capture.sh) to refresh ground truth.',
      );
    }
    expect(captured, greaterThan(0));
  });

  for (final MapEntry<String, Widget Function()> entry in _builders.entries) {
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

        final ui.Image carbide = await _renderCarbide(
          tester,
          _themes[themeSlug]!(),
          entry.value(),
        );
        final _Grid carbideGrid = await _luminanceGrid(tester, carbide);

        // The hard gate: Carbide rendered something with real contrast, not a
        // blank or single-colour box. (A clipped-to-nothing or collapsed
        // component would fail here.)
        expect(
          carbideGrid.range,
          greaterThan(0.1),
          reason: '$component ($themeSlug) rendered blank/flat',
        );

        final ui.Image reference = await _decodePng(
          tester,
          refFile.readAsBytesSync(),
        );
        final _Grid refGrid = await _luminanceGrid(tester, reference);
        final double diff = _meanAbsDiff(refGrid, carbideGrid);

        // The soft drift gate (#230): the committed per-story threshold
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
      });
    }
  }
}

/// Renders [child] under [theme] and rasterizes it at 2x.
Future<ui.Image> _renderCarbide(
  WidgetTester tester,
  CarbonThemeData theme,
  Widget child,
) async {
  final GlobalKey key = GlobalKey();
  await tester.binding.setSurfaceSize(const Size(800, 600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: CarbonTheme(
          data: theme,
          child: TapRegionSurface(
            child: Overlay(
              initialEntries: <OverlayEntry>[
                OverlayEntry(
                  builder: (BuildContext context) => Center(
                    // Capture the component tight, on the theme background (as
                    // the Carbon reference has it). The background keeps
                    // light-theme content from sitting on transparent black;
                    // the tight bounds keep small components (checkbox) from
                    // being diluted below the non-blank threshold.
                    child: RepaintBoundary(
                      key: key,
                      child: ColoredBox(color: theme.background, child: child),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 200));
  final RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync<ui.Image>(
    () => boundary.toImage(pixelRatio: 2),
  ))!;
}

Future<ui.Image> _decodePng(WidgetTester tester, Uint8List bytes) async {
  return (await tester.runAsync<ui.Image>(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }))!;
}

/// A downsampled luminance grid used for the coarse, framing-tolerant metric.
class _Grid {
  _Grid(this.cells);
  static const int n = 24;
  final List<double> cells; // n*n luminance values in 0..1.

  /// Brightest minus darkest cell. A blank/flat render is ~0; any component
  /// with content (e.g. light text on a dark field) is well above, regardless
  /// of how much surrounding background dilutes a global variance.
  double get range => cells.reduce(math.max) - cells.reduce(math.min);
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
  return _Grid(cells);
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
  final double width = pad * 2 + paneW * 2 + gap;
  final double height = header + paneH + pad;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width, height),
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
    Offset(pad + paneW + gap, header - 2),
    const Color(0xFF8D8D8D),
    11,
  );

  _drawContained(
    canvas,
    reference,
    Rect.fromLTWH(pad, header, paneW, paneH - 14),
  );
  _drawContained(
    canvas,
    carbide,
    Rect.fromLTWH(pad + paneW + gap, header, paneW, paneH - 14),
  );

  final ui.Picture picture = recorder.endRecording();
  return (await tester.runAsync<ui.Image>(
    () => picture.toImage(width.ceil(), height.ceil()),
  ))!;
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
