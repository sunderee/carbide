// Copyright 2026 Bizjak Tech OÜ
import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/demo_scaffold.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'fake upload adapter selects, progresses, fails, retries and removes',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final GalleryEntry entry = entryForSlug(kCatalog, 'file-uploader')!;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => CarbonTheme(
              data: CarbonThemeData.white,
              child: entry.builder(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder preview = find.byKey(kDemoPreviewKey);
      Finder action(String label) =>
          find.descendant(of: preview, matching: find.text(label));
      Future<void> press(String label) async {
        await tester.ensureVisible(action(label));
        await tester.tap(action(label));
        await tester.pump(const Duration(milliseconds: 200));
      }

      CarbonFileUploaderItem item() => tester.widget<CarbonFileUploaderItem>(
        find.byType(CarbonFileUploaderItem),
      );
      expect(find.byType(CarbonFileUploaderItem), findsNothing);
      await press('Select demo file');
      expect(item().status, CarbonFileStatus.edit);
      expect(find.text('Selected (pending upload)'), findsOneWidget);
      await press('Start upload');
      expect(item().status, CarbonFileStatus.uploading);
      await press('Advance upload');
      expect(find.text('Uploading: 50%'), findsOneWidget);
      await press('Simulate failure');
      expect(item().invalid, isTrue);
      expect(item().status, CarbonFileStatus.edit);
      expect(
        find.text('Simulated failure. Retry or remove this file.'),
        findsOneWidget,
      );
      await press('Retry upload');
      expect(item().invalid, isFalse);
      await press('Advance upload');
      await press('Advance upload');
      expect(item().status, CarbonFileStatus.complete);
      expect(find.text('Upload complete'), findsOneWidget);
      await press('Remove file');
      expect(find.byType(CarbonFileUploaderItem), findsNothing);
      final CarbonFileUploaderDropContainer drop = tester
          .widget<CarbonFileUploaderDropContainer>(
            find.byType(CarbonFileUploaderDropContainer),
          );
      Focus.of(tester.element(find.text(drop.label))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(item().status, CarbonFileStatus.edit);
      item().onDelete!();
      await tester.pump();
      expect(find.byType(CarbonFileUploaderItem), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
