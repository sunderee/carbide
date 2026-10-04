// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';
import 'support/static_semantics_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  retainIntegrationFailureDetails(binding);
  for (final direction in TextDirection.values) {
    testWidgets('static native structure and child actions $direction (#318)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final key = GlobalKey<StaticSemanticsFixtureState>();
      try {
        await tester.pumpWidget(
          staticSemanticsHost(
            StaticSemanticsFixture(key: key),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(_document.querySelectorAll('[role="list"]').length, 3);
        expect(_document.querySelectorAll('[role="listitem"]').length, 6);
        expect(_document.querySelectorAll('[role="region"]').length, 3);
        for (final name in [
          'Active',
          'A deliberately long complete status label',
          'Parent',
          'Nested Alpha',
          'Nested Beta',
          'Sibling',
        ]) {
          expect(
            _document.body!.textContent!.contains(name),
            isTrue,
            reason: name,
          );
        }
        expect(_document.body!.textContent!.contains('Decorative'), isFalse);
        final lists = _document.querySelectorAll('[role="list"]');
        for (var i = 0; i < lists.length; i++) {
          final direct = lists
              .item(i)!
              .querySelectorAll(':scope > [role="listitem"]');
          expect(direct.length, 2);
        }
        await tester.tap(find.text('Open record'));
        await tester.pumpAndSettle();
        expect(key.currentState!.activations, 1);
        await tester.tap(find.text('Show more'));
        await tester.pumpAndSettle();
        expect(find.text('Show less'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        handle.dispose();
      }
    });
  }
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Nodes querySelectorAll(String selector);
  external _Element? get body;
}

extension type _Nodes(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external _Nodes querySelectorAll(String selector);
}
