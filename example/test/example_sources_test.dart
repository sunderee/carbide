// Copyright 2026 Bizjak Tech OÜ

import 'dart:convert';
import 'dart:io';

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/demo_scaffold.dart';
import 'package:carbide_gallery/src/examples/button_example.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, String> sources = <String, String>{};
  testWidgets('collect complete examples from every component page', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final GalleryEntry entry in allEntries(kCatalog)) {
      await tester.pumpWidget(
        WidgetsApp(
          key: ValueKey<String>(entry.slug),
          color: const Color(0xffffffff),
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => CarbonTheme(
              data: CarbonThemeData.white,
              child: entry.builder(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final List<DemoScaffold> demos = tester
          .widgetList<DemoScaffold>(find.byType(DemoScaffold))
          .toList();
      if (demos.isNotEmpty) {
        expect(demos, hasLength(1), reason: entry.slug);
        expect(demos.single.code, isNotEmpty, reason: entry.slug);
        sources[entry.slug] = demos.single.code!;
      }
      expect(tester.takeException(), isNull, reason: entry.slug);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  tearDownAll(() {
    // Compile every enum/boolean shape of the shared immutable Button example.
    for (final CarbonButtonKind kind in CarbonButtonKind.values) {
      for (final CarbonButtonSize size in CarbonButtonSize.values) {
        for (int flags = 0; flags < 8; flags++) {
          final ButtonExample config = ButtonExample(
            kind: kind,
            size: size,
            withIcon: flags & 1 != 0,
            enabled: flags & 2 != 0,
            expressive: flags & 4 != 0,
          );
          sources['button-${kind.name}-${size.name}-$flags'] = config.code;
        }
      }
    }
    const String exportPath = String.fromEnvironment('CARBIDE_EXPORT_EXAMPLES');
    if (exportPath.isNotEmpty) {
      File(exportPath).writeAsStringSync(jsonEncode(sources));
    }
  });
}
