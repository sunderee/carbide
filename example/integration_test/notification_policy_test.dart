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
import 'support/notification_fixture.dart';

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
        testWidgets('native notifications $name $direction scale=$scale', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          final GlobalKey<NotificationFixtureState> key =
              GlobalKey<NotificationFixtureState>();
          String stage = 'mount';
          try {
            await tester.pumpWidget(
              notificationHost(
                NotificationFixture(key: key),
                theme: theme,
                direction: direction,
                scale: scale,
                viewport: 320,
              ),
            );
            await _settle(tester);
            stage = 'initial native roles';
            expect(_message('Inline 0').getAttribute('role'), 'status');
            expect(_message('Toast 0').getAttribute('role'), 'alert');
            expect(
              _message('Toast 0').getAttribute('aria-label'),
              contains('Just now'),
            );
            expect(_message('Actionable 0').getAttribute('role'), 'status');
            expect(
              _message('Actionable 0').getAttribute('aria-label'),
              contains('Retry operation'),
            );
            expect(
              _document.querySelectorAll('[role="alertdialog"]').length,
              0,
            );
            stage = 'static callout';
            await tester.ensureVisible(find.byType(CarbonCallout));
            await _settle(tester);
            expect(
              _staticNote().closest(
                '[role="status"], [role="alert"], [aria-live]',
              ),
              isNull,
            );
            stage = 'editor focus';
            key.currentState!.editorFocus.requestFocus();
            await _settle(tester);
            stage = 'live update';
            key.currentState!.update();
            await _settle(tester);
            expect(key.currentState!.editorFocus.hasPrimaryFocus, isTrue);
            expect(_document.activeElement?.tagName, 'INPUT');
            expect(_message('Toast 1').getAttribute('role'), 'alert');
            expect(
              _message('Actionable 1').getAttribute('aria-label'),
              contains('Retry operation'),
            );
            final Finder action = find.text('Retry operation');
            stage = 'action layout';
            await tester.ensureVisible(action);
            await _settle(tester);
            expect(
              tester.getTopLeft(action).dy,
              greaterThanOrEqualTo(
                tester
                    .getBottomLeft(
                      find.text('Supporting detail for the optional action.'),
                    )
                    .dy,
              ),
            );
            await tester.tap(action);
            stage = 'action pointer';
            await _settle(tester);
            expect(key.currentState!.actions, 1);
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            stage = 'action Enter';
            await _settle(tester);
            expect(key.currentState!.actions, 2);
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            stage = 'action Tab';
            await _settle(tester);
            expect(
              _document.activeElement?.textContent?.trim(),
              'Close notification',
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            stage = 'close Space';
            await _settle(tester);
            expect(key.currentState!.closes, 1);
            expect(tester.takeException(), isNull);
          } catch (error, stack) {
            Error.throwWithStackTrace(
              StateError('Notification $stage: $error'),
              stack,
            );
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            semantics.dispose();
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

_Element _message(String prefix) {
  final _NodeList nodes = _document.querySelectorAll(
    'flt-semantics[role="status"], flt-semantics[role="alert"]',
  );
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if (node.getAttribute('aria-label')?.startsWith(prefix) ?? false) {
      return node;
    }
  }
  throw StateError('No notification named $prefix');
}

_Element _staticNote() {
  final _NodeList nodes = _document.querySelectorAll('flt-semantics');
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if (node.textContent?.trim() == 'Static note') {
      return node;
    }
  }
  throw StateError('No native static note');
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
  external _Element? get activeElement;
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external _Element? closest(String selector);
  external String? getAttribute(String name);
  external String? get textContent;
  external String get tagName;
}
