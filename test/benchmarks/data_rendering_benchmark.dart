// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  // Tracking creation stacks dominates mount cost; this opt-in measurement
  // pauses instrumentation. The ordinary component suites still check leaks.
  LeakTesting.settings = LeakTesting.settings.withIgnoredAll();
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('measure eager data rendering', (tester) async {
    final service = (await tester.runAsync(Service.getInfo))!.serverUri;
    if (service == null) throw StateError('Use --enable-vmservice.');
    final client = (await tester.runAsync(
      () async => HttpOverrides.runWithHttpOverrides(
        () => HttpClient(),
        _RealHttpOverrides(),
      ),
    ))!;
    try {
      Future<Map<String, dynamic>> rawRpc(
        String name, [
        Map<String, String> params = const {},
      ]) async {
        final uri = service.resolve(name).replace(queryParameters: params),
            res = await (await client.getUrl(uri)).close();
        final data = jsonDecode(
          await res.transform(utf8.decoder).join(),
        ) as Map<String, dynamic>;
        if (data.containsKey('error')) throw StateError(jsonEncode(data));
        return data['result'] as Map<String, dynamic>;
      }

      Future<Map<String, dynamic>> rpc(
        String name, [
        Map<String, String> params = const {},
      ]) async => (await tester.runAsync(() => rawRpc(name, params)))!;
      final isolate = Service.getIsolateId(Isolate.current)!;
      Future<Map<String, dynamic>> iso(
        String name, [
        Map<String, String> params = const {},
      ]) => rpc(name, {'isolateId': isolate, ...params});
      Future<Map<String, dynamic>> snapshot() async {
        await iso('getAllocationProfile', {'gc': 'true'});
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        final profile = await iso('getAllocationProfile', {'gc': 'true'});
        return {
          'memory': profile['memoryUsage'],
          'rss': ProcessInfo.currentRss,
        };
      }

      const virtualized = bool.fromEnvironment('DATA_VIRTUALIZED');
      const count = int.fromEnvironment('DATA_COUNT', defaultValue: 100),
          family = String.fromEnvironment('DATA_FAMILY', defaultValue: 'table');
      final rows = [
        for (int i = 0; i < count; i++)
          CarbonTableRow(
            id: i,
            cells: [Text('Record $i'), const Text('Available')],
            expandedContent: Text('Details $i'),
          ),
      ];
      final nodes = [
        for (int i = 0; i < count; i++)
          CarbonTreeNode(id: i, label: 'Record $i'),
      ];
      Widget host(Widget child) => Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: CarbonTheme(
            data: CarbonThemeData.white,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 760, child: child),
            ),
          ),
        ),
      );
      Widget subject(int n) => family == 'table'
          ? CarbonDataTable(
              virtualized: virtualized,
              columns: const [
                CarbonTableColumn(title: 'Name'),
                CarbonTableColumn(title: 'Status'),
              ],
              rows: rows.take(n).toList(),
              stickyHeader: true,
              expandable: true,
              selectedRowIds: const {},
              expandedRowIds: const {},
            )
          : virtualized
          ? CarbonTreeView(
              label: 'Files',
              nodes: nodes.take(n).toList(),
              virtualized: true,
            )
          : SizedBox(
              height: 320,
              child: SingleChildScrollView(
                child: CarbonTreeView(
                  label: 'Files',
                  nodes: nodes.take(n).toList(),
                ),
              ),
            );
      await tester.pumpWidget(host(subject(5)));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final before = await snapshot();
      await rpc('setVMTimelineFlags', {'recordedStreams': '[Dart]'});
      await rpc('clearVMTimeline');
      final watch = Stopwatch()..start();
      await tester.pumpWidget(host(subject(count)));
      watch.stop();
      final timeline = await rpc('getVMTimeline');
      final events = (timeline['traceEvents'] as List)
          .cast<Map<String, dynamic>>();
      final spans = <String, int>{};
      final stacks = <String, List<int>>{};
      for (final e in events) {
        final name = e['name'];
        if (name != 'BUILD' && name != 'LAYOUT') continue;
        final phase = e['ph'], ts = e['ts'] as int?;
        if (ts == null) continue;
        final key = '$name:${e['tid']}';
        if (phase == 'B') {
          (stacks[key] ??= []).add(ts);
        } else if (phase == 'E' && stacks[key]?.isNotEmpty == true) {
          final start = stacks[key]!.removeLast();
          spans[name as String] = (spans[name] ?? 0) + ts - start;
        } else if (phase == 'X') {
          spans[name as String] = (spans[name] ?? 0) + (e['dur'] as int);
        }
      }
      int elements = 0;
      void visit(Element e) {
        elements++;
        e.visitChildElements(visit);
      }

      visit(tester.binding.rootElement!);
      final after = await snapshot();
      // ignore: avoid_print
      print(
        'DATA-MEASURE ${jsonEncode({'family': family, 'virtualized': virtualized, 'count': count, 'pumpUs': watch.elapsedMicroseconds, 'buildUs': spans['BUILD'], 'layoutUs': spans['LAYOUT'], 'mountedElements': elements, 'before': before, 'after': after})}',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      client.close(force: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
