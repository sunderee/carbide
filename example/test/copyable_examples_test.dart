// Copyright 2026 Bizjak Tech OÜ

import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/catalog.dart';
import 'package:carbide_gallery/src/demo_scaffold.dart';
import 'package:carbide_gallery/src/registry.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Button knobs update the immutable preview and copied example', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final List<String> copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add(
            (call.arguments as Map<dynamic, dynamic>)['text'] as String,
          );
        }
        return null;
      },
    );
    try {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => CarbonTheme(
              data: CarbonThemeData.white,
              child: entryForSlug(kCatalog, 'button')!.builder(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder previewButton() => find.descendant(
        of: find.byKey(kDemoPreviewKey),
        matching: find.byType(CarbonButton),
      );
      CarbonCodeSnippet source() =>
          tester.widget<CarbonCodeSnippet>(find.byType(CarbonCodeSnippet));
      expect(source().type, CarbonCodeSnippetType.multi);
      expect(source().code, contains('onPressed: () {}'));

      final Finder iconKnob = find.byWidgetPredicate(
        (Widget widget) =>
            widget is CarbonToggle && widget.labelText == 'With icon',
      );
      await tester.ensureVisible(iconKnob);
      await tester.tap(
        find.descendant(of: iconKnob, matching: find.byType(CarbonInteraction)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CarbonButton>(previewButton()).icon,
        CarbonIcons.add,
      );
      expect(source().code, contains('icon: CarbonIcons.add'));

      final Finder enabledKnob = find.byWidgetPredicate(
        (Widget widget) =>
            widget is CarbonToggle && widget.labelText == 'Enabled',
      );
      await tester.ensureVisible(enabledKnob);
      await tester.tap(
        find.descendant(
          of: enabledKnob,
          matching: find.byType(CarbonInteraction),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<CarbonButton>(previewButton()).onPressed, isNull);
      expect(source().code, contains('onPressed: null'));

      final String expectedCode = source().code;
      final Finder copy = find.bySemanticsLabel('Copy Button example');
      await tester.ensureVisible(copy);
      await tester.pumpAndSettle();
      tester.binding.handleViewFocusChanged(
        ViewFocusEvent(
          viewId: tester.view.viewId,
          state: ViewFocusState.focused,
          direction: ViewFocusDirection.undefined,
        ),
      );
      final Finder ring = find
          .descendant(of: copy, matching: find.byType(CarbonFocusRing))
          .first;
      FocusManager.instance.primaryFocus?.unfocus();
      bool reached = false;
      for (int i = 0; i < 40; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        if (Focus.of(tester.element(ring)).hasFocus) {
          reached = true;
          break;
        }
      }
      expect(reached, isTrue, reason: 'copy must be reachable by Tab');
      final SemanticsNode node = tester.getSemantics(copy);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(copied, <String>[expectedCode]);
      tester.binding.platformDispatcher.onSemanticsActionEvent!(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          viewId: tester.view.viewId,
          nodeId: node.id,
        ),
      );
      await tester.pump();
      expect(copied, <String>[expectedCode, expectedCode]);
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      handle.dispose();
      tester.view.reset();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    }
  });
}
