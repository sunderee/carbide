// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';
import 'package:flutter_test/flutter_test.dart';

// Runtime construction prevents canonical const identity from short-circuiting
// the value-key contract being exercised.
CarbonIconShape _shape({
  required String d,
  bool evenOdd = false,
  List<double>? matrix,
}) => CarbonIconShape(d: d, evenOdd: evenOdd, matrix: matrix);

Future<Uint8List> _paint(CarbonIconShape shape) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  CarbonIconPainter(
    artwork: CarbonIconArtwork(
      viewBoxWidth: 32,
      viewBoxHeight: 32,
      shapes: <CarbonIconShape>[shape],
    ),
    color: const ui.Color(0xFF000000),
  ).paint(ui.Canvas(recorder), const ui.Size(32, 32));
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(32, 32);
  try {
    final ByteData bytes = (await image.toByteData())!;
    return Uint8List.fromList(bytes.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

int _alpha(Uint8List rgba, int x, int y) => rgba[(y * 32 + x) * 4 + 3];

void main() {
  test('separately allocated shape values share a hash-map key', () {
    CarbonIconShape shape() => _shape(
      d: 'M0 0H8V8H0Z',
      evenOdd: true,
      matrix: <double>[1, 0, 0, 1, 8, 4],
    );
    final CarbonIconShape first = shape();
    final CarbonIconShape second = shape();
    expect(identical(first, second), isFalse);
    expect(identical(first.matrix, second.matrix), isFalse);
    expect(first, second);
    expect(first.hashCode, second.hashCode);
    final Map<CarbonIconShape, String> lookup = <CarbonIconShape, String>{
      first: 'parsed',
    };
    expect(lookup[second], 'parsed');
    lookup[second] = 'reused';
    expect(lookup.length, 1);
  });

  test('path, winding rule and transform each distinguish cache keys', () {
    final Set<CarbonIconShape> shapes = <CarbonIconShape>{
      _shape(d: 'M0 0H8V8H0Z'),
      _shape(d: 'M0 0H9V8H0Z'),
      _shape(d: 'M0 0H8V8H0Z', evenOdd: true),
      _shape(d: 'M0 0H8V8H0Z', matrix: <double>[1, 0, 0, 1, 8, 4]),
      _shape(d: 'M0 0H8V8H0Z', matrix: <double>[1, 0, 0, 1, 9, 4]),
    };
    expect(shapes.length, 5);
    expect(shapes.first, isNot(Object()));
  });

  test(
    'cached paths preserve different winding rules for the same data',
    () async {
      const String path = 'M0 0H32V32H0Z M8 8H24V24H8Z';
      final Uint8List solid = await _paint(_shape(d: path));
      final Uint8List hole = await _paint(_shape(d: path, evenOdd: true));
      expect(_alpha(solid, 16, 16), 255);
      expect(_alpha(hole, 16, 16), 0);
      expect(_alpha(hole, 4, 4), 255);
      expect(await _paint(_shape(d: path)), solid);
    },
  );

  test(
    'cached transforms do not modify or alias the untranslated path',
    () async {
      const String path = 'M0 0H8V8H0Z';
      final Uint8List original = await _paint(_shape(d: path));
      final Uint8List shifted = await _paint(
        _shape(d: path, matrix: <double>[1, 0, 0, 1, 16, 0]),
      );
      expect(_alpha(original, 4, 4), 255);
      expect(_alpha(original, 20, 4), 0);
      expect(_alpha(shifted, 4, 4), 0);
      expect(_alpha(shifted, 20, 4), 255);
      expect(await _paint(_shape(d: path)), original);
    },
  );
}
