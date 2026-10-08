// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Opt-in VM measurement harness, not a timing gate. See README.md here.
// Run explicitly with flutter test --enable-vmservice; the benchmark filename
// excludes this hardware-dependent measurement from ordinary *_test.dart runs.

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';
import 'package:carbide/src/icons/svg_path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../icons/all_icons.dart';
import '../pictograms/all_pictograms.dart';

void _paint(List<CarbonIconData> data) {
  for (final icon in data) {
    for (final artwork in icon.artwork) {
      final recorder = ui.PictureRecorder();
      CarbonIconPainter(
        artwork: artwork,
        color: const ui.Color(0xff000000),
      ).paint(ui.Canvas(recorder), const ui.Size(32, 32));
      recorder.endRecording().dispose();
    }
  }
}

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('measure production path-cache retention', () async {
    final Uri? service = (await Service.getInfo()).serverUri;
    if (service == null) {
      throw StateError(
        'Run this benchmark with flutter test --enable-vmservice.',
      );
    }
    final client = HttpOverrides.runWithHttpOverrides(
      () => HttpClient(),
      _RealHttpOverrides(),
    );
    try {
      Future<Map<String, dynamic>> rpc(
        String method, [
        Map<String, String> params = const {},
      ]) async {
        final uri = service.resolve(method).replace(queryParameters: params);
        final response = await (await client.getUrl(uri)).close();
        final json = jsonDecode(
          await response.transform(utf8.decoder).join(),
        ) as Map<String, dynamic>;
        if (json.containsKey('error')) {
          throw StateError(jsonEncode(json));
        }
        return json['result'] as Map<String, dynamic>;
      }

      final isolateId = Service.getIsolateId(Isolate.current)!;
      Future<Map<String, dynamic>> isoRpc(
        String method, [
        Map<String, String> params = const {},
      ]) => rpc(method, {'isolateId': isolateId, ...params});
      final isolate = await isoRpc('getIsolate');
      final lib = (isolate['libraries'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere(
            (Map<String, dynamic> l) =>
                l['uri'] ==
                'package:carbide/src/icons/carbon_icon_painter.dart',
          );
      final libId = lib['id'] as String;
      final library = await isoRpc('getObject', {'objectId': libId});
      final painterRef = (library['classes'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere(
            (Map<String, dynamic> c) => c['name'] == 'CarbonIconPainter',
          );
      final painterClass = await isoRpc('getObject', {
        'objectId': painterRef['id'] as String,
      });
      final fieldRef = (painterClass['fields'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .singleWhere((Map<String, dynamic> f) => f['name'] == '_pathCache');
      Future<Map<String, dynamic>> cache() async {
        final f = await isoRpc('getObject', {
          'objectId': fieldRef['id'] as String,
        });
        return f['staticValue'] as Map<String, dynamic>;
      }

      Future<Map<String, dynamic>> snapshot() async {
        await isoRpc('getAllocationProfile', {'gc': 'true'});
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final profile = await isoRpc('getAllocationProfile', {'gc': 'true'});
        final map = await cache();
        final retained = await isoRpc('_getRetainedSize', {
          'targetId': map['id'] as String,
        });
        return {
          'cacheLength': map['length'],
          'retainedDartBytes': int.parse(retained['valueAsString'] as String),
          'memory': profile['memoryUsage'],
          'rss': ProcessInfo.currentRss,
        };
      }

      const family = String.fromEnvironment(
        'CACHE_FAMILY',
        defaultValue: 'icons',
      );
      const limit = int.fromEnvironment('CACHE_COUNT', defaultValue: 100);
      if (family != 'icons' && family != 'pictograms') {
        throw ArgumentError.value(
          family,
          'CACHE_FAMILY',
          'icons or pictograms',
        );
      }
      const registry = family == 'icons' ? allCarbonIcons : allCarbonPictograms;
      if (limit < 1 || limit > registry.length) {
        throw RangeError.range(limit, 1, registry.length, 'CACHE_COUNT');
      }
      final sample = registry.take(limit).toList();
      final shapes = {
        for (final i in sample)
          for (final a in i.artwork) ...a.shapes,
      };
      // Force const-data traversal before snapshots, then warm parsing without
      // populating the production cache. The dummy is a separate simple shape.
      final registryShapes = registry.fold<int>(
        0,
        (n, i) => n + i.artwork.fold<int>(0, (n, a) => n + a.shapes.length),
      );
      for (final shape in shapes.take(20)) {
        parseSvgPath(shape.d);
      }
      _paint(const [
        CarbonIconData(
          name: 'benchmark-warmup',
          artwork: [
            CarbonIconArtwork(
              viewBoxWidth: 32,
              viewBoxHeight: 32,
              shapes: [CarbonIconShape(d: 'M0 0H1V1H0Z')],
            ),
          ],
        ),
      ]);
      final before = await snapshot();
      final cold = Stopwatch()..start();
      _paint(sample);
      cold.stop();
      final after = await snapshot();
      expect(
        (after['cacheLength'] as int) - (before['cacheLength'] as int),
        shapes.length,
      );
      expect(
        after['retainedDartBytes'],
        greaterThan(before['retainedDartBytes'] as int),
      );
      final hot = Stopwatch()..start();
      for (var n = 0; n < 10; n++) {
        _paint(sample);
      }
      hot.stop();
      final reparses = <int>[];
      for (var n = 0; n < 3; n++) {
        final watch = Stopwatch()..start();
        for (final shape in shapes) {
          parseSvgPath(shape.d);
        }
        watch.stop();
        reparses.add(watch.elapsedMicroseconds);
      }
      final row = <String, dynamic>{
        'family': family,
        'count': sample.length,
        'registryShapes': registryShapes,
        'artworks': sample.fold<int>(0, (n, i) => n + i.artwork.length),
        'uniqueShapes': shapes.length,
        'coldPaintUs': cold.elapsedMicroseconds,
        'hotPaintUs': hot.elapsedMicroseconds / 10,
        'reparseUs': reparses,
        'before': before,
        'after': after,
      };
      // Machine-readable benchmark output consumed by a local runner or CI artifact.
      // ignore: avoid_print
      print('CACHE-MEASURE ${jsonEncode(row)}');
    } finally {
      client.close(force: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
