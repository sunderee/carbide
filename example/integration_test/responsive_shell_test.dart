// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.
import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';
import 'support/shell_fixture.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  retainIntegrationFailureDetails(binding);
  for (int theme = 0; theme < 4; theme++) {
    for (final TextDirection direction in TextDirection.values) {
      for (final double scale in <double>[1, 1.3, 2]) {
        testWidgets('native shell theme=$theme $direction scale=$scale', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle handle = tester.ensureSemantics();
          final GlobalKey<ShellFixtureAppState> key =
              GlobalKey<ShellFixtureAppState>();
          try {
            await tester.pumpWidget(
              ShellFixtureApp(
                key: key,
                themeIndex: theme,
                direction: direction,
                scale: scale,
                width: 320,
              ),
            );
            await _settle(tester);
            final Size headerSize = tester.getSize(find.byType(CarbonHeader));
            await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
            expect(
              _document.activeElement?.getAttribute('aria-label'),
              'Skip to main content',
            );
            await _key(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            expect(_document.activeElement?.getAttribute('role'), 'main');
            expect(_document.activeElement?.getAttribute('tabindex'), '-1');
            expect(tester.getSize(find.byType(CarbonHeader)), headerSize);
            await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
            expect(_document.activeElement?.tagName, 'INPUT');
            await tester.enterText(find.byType(EditableText), 'Retained draft');
            await _settle(tester);
            expect(_document.activeElement?.tagName, 'INPUT');
            final ShellFixturePageState page = tester.state(
              find.byType(ShellFixturePage),
            );
            _button('Toggle navigation').focus();
            await _settle(tester);
            await _key(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            expect(find.byType(CarbonSideNav), findsOneWidget);
            expect(find.text('Overview'), findsOneWidget);
            expect(tester.getSize(find.byType(CarbonShellContent)).width, 320);
            final _Element category = _button('Foundational');
            expect(category.getAttribute('aria-expanded'), 'false');
            category.focus();
            await _settle(tester);
            await _key(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            expect(
              _button('Foundational').getAttribute('aria-expanded'),
              'true',
            );
            await _key(
              tester,
              LogicalKeyboardKey.escape,
              PhysicalKeyboardKey.escape,
            );
            expect(find.byType(CarbonSideNav), findsNothing);
            expect(
              _document.activeElement?.getAttribute('aria-label'),
              'Toggle navigation',
            );
            key.currentState!.resize(1200);
            await _settle(tester);
            expect(tester.state(find.byType(ShellFixturePage)), same(page));
            expect(page.editor.text, 'Retained draft');
            expect(find.text('Overview'), findsOneWidget);
            expect(
              find.descendant(
                of: find.byType(CarbonHeader),
                matching: find.text('Overview'),
              ),
              findsOneWidget,
            );
            key.currentState!.detail();
            await _settle(tester);
            expect(find.text('Detail workspace'), findsOneWidget);
            _button('Carbide Gallery').focus();
            await _settle(tester);
            await _key(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            expect(find.text('Shell workspace'), findsOneWidget);
            await tester.ensureVisible(find.text('Cloud'));
            await tester.tap(find.text('Cloud'));
            await _settle(tester);
            final ShellFixturePageState home = tester.state(
              find.byType(ShellFixturePage),
            );
            expect(home.actions, 1);
            _button('Cloud').focus();
            await _settle(tester);
            await _key(
              tester,
              LogicalKeyboardKey.space,
              PhysicalKeyboardKey.space,
            );
            expect(home.actions, 2);
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

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical,
) async {
  await tester.sendKeyEvent(logical, physicalKey: physical);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

_Element _button(String name) {
  final _Nodes nodes = _document.querySelectorAll('[role="button"], button');
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if ((node.getAttribute('aria-label') ?? node.textContent?.trim()) == name) {
      return node;
    }
  }
  throw StateError('Missing native button: $name');
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
  external void focus();
}
