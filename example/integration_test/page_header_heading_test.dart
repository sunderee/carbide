// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';
import 'support/page_header_fixture.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  retainIntegrationFailureDetails(binding);
  for (final (String name, CarbonThemeData theme)
      in <(String, CarbonThemeData)>[
        ('white', CarbonThemeData.white),
        ('g10', CarbonThemeData.gray10),
        ('g90', CarbonThemeData.gray90),
        ('g100', CarbonThemeData.gray100),
      ]) {
    for (final TextDirection direction in TextDirection.values) {
      for (final double scale in <double>[1, 2]) {
        testWidgets('native page heading $name $direction scale=$scale', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          final GlobalKey<PageHeaderFixtureState> key =
              GlobalKey<PageHeaderFixtureState>();
          try {
            await tester.pumpWidget(
              pageHeaderHost(
                PageHeaderFixture(key: key),
                theme: theme,
                direction: direction,
                scale: scale,
              ),
            );
            await _settle(tester);
            key.currentState!.editorFocus.requestFocus();
            await _settle(tester);
            for (int level = 1; level <= 6; level++) {
              key.currentState!.setHeadingLevel(level);
              await _settle(tester);
              final _Nodes headings = _document.querySelectorAll(
                'h1, h2, h3, h4, h5, h6, [role="heading"]',
              );
              expect(headings.length, 1);
              final _Element title = headings.item(0)!;
              expect(title.tagName, 'H$level');
              expect(
                title.getAttribute('aria-label') ?? title.textContent?.trim(),
                pageHeaderTitle,
              );
              expect(key.currentState!.editorFocus.hasPrimaryFocus, isTrue);
              expect(_document.activeElement?.tagName, 'INPUT');
              expect(
                _document.querySelectorAll('[aria-label="Page header"]').length,
                0,
              );
              expect(key.currentState!.actions, 0);
            }
            await tester.tap(find.text('Edit report'));
            await _settle(tester);
            expect(key.currentState!.actions, 1);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            handle.dispose();
          }
        });
      }
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Nodes querySelectorAll(String selector);
  external _Element? get activeElement;
}

extension type _Nodes(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? getAttribute(String name);
  external String? get textContent;
  external String get tagName;
}
