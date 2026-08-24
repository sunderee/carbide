// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// Generates a high-DPI visual review surface: every catalog component's live
// preview, captured per theme, plus a per-theme contact-sheet montage. This is
// the human-reviewable counterpart to the spec-lock + legibility tests — it
// exists so rendering defects that assertions can't express get *seen* on every
// PR (see fidelity epic, W2). It is NOT a pass/fail gate: glyph rasterization
// differs across platforms, so the output is an artifact for eyes, not a diff.
//
// Generate locally:
//   flutter test --dart-define=SCREENSHOTS=true test/contact_sheet_test.dart
// Output lands in test/screenshots/ (git-ignored):
//   contact_sheet_<theme>.png           — the montage per theme
//   components/<theme>/<slug>.png        — the individual previews

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/demo_scaffold.dart';
import 'package:carbide_gallery/src/gallery_controller.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Only runs when explicitly asked for: this writes files and is slow.
const bool _enabled = bool.fromEnvironment('SCREENSHOTS');

/// Capture resolution. 2x is crisp enough to spot a clipped glyph (the bug
/// class W2 targets) while keeping the montage a manageable size.
const double _dpr = 2;

const String _outDir = 'test/screenshots';
const Size _surface = Size(1000, 720);

/// The host every preview is captured in: a theme, a media query, an overlay
/// (popovers/menus/modals) and a tap-region surface — matching the gallery's
/// own runtime, mirroring `all_pages_test`.
///
/// [slug] keys the [Overlay] so that re-pumping for the next component
/// actually rebuilds it: `Overlay.initialEntries` are honoured only on first
/// mount, so without a changing key Flutter would reuse the first page for
/// every subsequent capture.
Widget _host(CarbonThemeData theme, Widget page, String slug) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(size: _surface),
    child: CarbonTheme(
      data: theme,
      child: TapRegionSurface(
        child: Overlay(
          key: ValueKey<String>('overlay-$slug'),
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => ColoredBox(
                color: theme.background,
                child: Padding(padding: const EdgeInsets.all(24), child: page),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

String _themeSlug(String label) => label.toLowerCase().replaceAll(' ', '-');

/// A captured preview: its catalog slug and the rasterized image.
class _Shot {
  _Shot(this.slug, this.image);
  final String slug;
  final ui.Image image;
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });

  for (final GalleryTheme gTheme in kGalleryThemes) {
    testWidgets('contact sheet — ${gTheme.label}', skip: !_enabled, (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(_surface);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final String slug = _themeSlug(gTheme.label);
      final Directory dir = Directory('$_outDir/components/$slug')
        ..createSync(recursive: true);

      final List<_Shot> shots = <_Shot>[];
      for (final GalleryEntry entry in allEntries(kCatalog)) {
        final ui.Image? image = await _capture(tester, gTheme.data, entry);
        if (image == null) {
          continue;
        }
        final ByteData? png = await tester.runAsync<ByteData?>(
          () => image.toByteData(format: ui.ImageByteFormat.png),
        );
        File(
          '${dir.path}/${entry.slug}.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
        shots.add(_Shot(entry.slug, image));
      }

      final ui.Image sheet = await _montage(tester, shots, gTheme);
      final ByteData? png = await tester.runAsync<ByteData?>(
        () => sheet.toByteData(format: ui.ImageByteFormat.png),
      );
      File(
        '$_outDir/contact_sheet_$slug.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());

      // A sanity check so the run still fails loudly if the whole catalog
      // stops rendering (e.g. a host regression), without gating on pixels.
      expect(shots, isNotEmpty);
    });
  }
}

/// Pumps one entry and rasterizes just its preview surface, or null if the
/// page threw or has no preview.
Future<ui.Image?> _capture(
  WidgetTester tester,
  CarbonThemeData theme,
  GalleryEntry entry,
) async {
  try {
    await tester.pumpWidget(_host(theme, entry.builder(), entry.slug));
    // Advance without settling — some pages host perpetual animations.
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 200));
    final Object? thrown = tester.takeException();
    if (thrown != null) {
      // ignore: avoid_print
      print('SKIP ${entry.slug}: threw $thrown');
      return null;
    }
    final Finder preview = find.byKey(kDemoPreviewKey);
    if (preview.evaluate().isEmpty) {
      // ignore: avoid_print
      print('SKIP ${entry.slug}: no preview key');
      return null;
    }
    final RenderRepaintBoundary boundary = tester.renderObject(preview);
    // toImage must run in a real async zone — in the fake-async test
    // environment the Future never completes and the run hangs.
    return await tester.runAsync(() => boundary.toImage(pixelRatio: _dpr));
  } catch (e) {
    // ignore: avoid_print
    print('SKIP ${entry.slug}: $e');
    return null;
  }
}

/// Composes the captured previews into a single labelled grid for the theme.
Future<ui.Image> _montage(
  WidgetTester tester,
  List<_Shot> shots,
  GalleryTheme gTheme,
) async {
  final CarbonThemeData t = gTheme.data;
  const int cols = 4;
  const double cellW = 360;
  const double imgH = 210;
  const double labelH = 30;
  const double pad = 12;
  const double cellH = imgH + labelH;
  const double headerH = 64;
  final int rows = math.max(1, (shots.length / cols).ceil());
  const double width = cols * cellW;
  final double height = headerH + rows * cellH;

  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()..color = t.background,
  );
  _text(
    canvas,
    'Carbide components — ${gTheme.label}  (${shots.length})',
    const Offset(16, 20),
    color: t.textPrimary,
    size: 20,
    weight: FontWeight.w600,
    maxWidth: width - 32,
  );

  for (int i = 0; i < shots.length; i++) {
    final int row = i ~/ cols;
    final int col = i % cols;
    final double x = col * cellW;
    final double y = headerH + row * cellH;

    final Rect imgArea = Rect.fromLTWH(
      x + pad,
      y + pad,
      cellW - 2 * pad,
      imgH - 2 * pad,
    );
    canvas
      ..drawRect(imgArea, Paint()..color = t.layer01)
      ..drawRect(
        imgArea,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = t.borderSubtle01,
      );

    final ui.Image img = shots[i].image;
    final double iw = img.width.toDouble();
    final double ih = img.height.toDouble();
    final double scale = math.min(imgArea.width / iw, imgArea.height / ih);
    final double dw = iw * scale;
    final double dh = ih * scale;
    final Rect dst = Rect.fromLTWH(
      imgArea.left + (imgArea.width - dw) / 2,
      imgArea.top + (imgArea.height - dh) / 2,
      dw,
      dh,
    );
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, iw, ih),
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );

    _text(
      canvas,
      shots[i].slug,
      Offset(x + pad, y + imgH - 2),
      color: t.textSecondary,
      size: 12,
      weight: FontWeight.w400,
      maxWidth: cellW - 2 * pad,
    );
  }

  final ui.Picture picture = recorder.endRecording();
  return (await tester.runAsync<ui.Image>(
    () => picture.toImage(width.ceil(), height.ceil()),
  ))!;
}

void _text(
  Canvas canvas,
  String text,
  Offset at, {
  required Color color,
  required double size,
  required FontWeight weight,
  required double maxWidth,
}) {
  final ui.ParagraphBuilder builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontFamily: CarbonFontFamily.sans,
            fontSize: size,
            fontWeight: weight,
            maxLines: 1,
            ellipsis: '…',
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(text);
  final ui.Paragraph paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: maxWidth));
  canvas.drawParagraph(paragraph, at);
}
