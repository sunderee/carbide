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
import 'support/high_contrast_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  retainIntegrationFailureDetails(binding);
  final themes = {
    'white': CarbonThemeData.white,
    'g10': CarbonThemeData.gray10,
    'g90': CarbonThemeData.gray90,
    'g100': CarbonThemeData.gray100,
  };
  for (final entry in themes.entries) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'live contrast preserves native controls ${entry.key} $direction (#317)',
        (tester) async {
          final semantics = tester.ensureSemantics();
          final key = GlobalKey<HighContrastFixtureState>();
          try {
            await tester.pumpWidget(
              highContrastHost(
                HighContrastFixture(key: key),
                theme: entry.value,
                direction: direction,
              ),
            );
            await _settle(tester);
            final state = key.currentState!;
            state.setPreference(false);
            await _settle(tester);
            expect(state.resolved, same(entry.value));
            final run = _named('button', 'Run 1');
            final id = run.getAttribute('id');
            run.focus();
            await _settle(tester);
            expect(
              state.specimen.currentState!.buttonFocus.first.hasFocus,
              isTrue,
            );
            await _enter(tester);
            expect(state.activations, 1);
            state.setPreference(true);
            await _settle(tester);
            expect(
              state.resolved,
              same(CarbonThemeData.highContrast(entry.value)),
            );
            expect(_named('button', 'Run 1').getAttribute('id'), id);
            expect(_name(_document.activeElement!), 'Run 1');
            expect(
              state.specimen.currentState!.buttonFocus.first.hasFocus,
              isTrue,
            );
            await _enter(tester);
            expect(state.activations, 2);
            expect(
              _named('button', 'Inactive').getAttribute('aria-disabled'),
              'true',
            );
            await tester.tap(find.text('Inactive').first);
            await _settle(tester);
            expect(state.activations, 2);
            expect(_named('textbox', 'Disabled 1').disabled, isTrue);

            final editorFinder = find.descendant(
              of: find.byWidgetPredicate(
                (widget) =>
                    widget is CarbonTextInput && widget.labelText == 'Name 1',
              ),
              matching: find.byType(EditableText),
            );
            // Activate editing through the public widget before injecting a
            // native input event into Flutter's current text-editing connection.
            await tester.tap(editorFinder);
            await _settle(tester);
            final editor = tester.widget<EditableText>(editorFinder);
            final input = _document.activeElement!;
            _type(input, 'Ada');
            await _settle(tester);
            expect(editor.controller.text, 'Ada');
            state.setPreference(false);
            await _settle(tester);
            expect(state.resolved, same(entry.value));
            expect(editor.focusNode.hasFocus, isTrue);
            expect(_document.activeElement!.value, 'Ada');
            _type(_document.activeElement!, 'Ada!');
            await _settle(tester);
            expect(editor.controller.text, 'Ada!');
            state.setPreference(true);
            await _settle(tester);
            expect(editor.focusNode.hasFocus, isTrue);
            expect(_document.activeElement!.value, 'Ada!');
            _type(_document.activeElement!, 'Ada!!');
            await _settle(tester);
            expect(editor.controller.text, 'Ada!!');
            expect(_document.querySelectorAll('[role="table"]').length, 1);
            expect(
              _document.querySelectorAll('[role="columnheader"]').length,
              2,
            );
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
            semantics.dispose();
          }
        },
      );
    }
  }
}

_Element _named(String role, String name) {
  // Native HTML editors have an implicit textbox role, without role="textbox".
  final nodes = _document.querySelectorAll(
    role == 'textbox' ? 'input, textarea, [role="textbox"]' : '[role="$role"]',
  );
  for (var i = 0; i < nodes.length; i++) {
    final node = nodes.item(i)!;
    if (_name(node) == name) return node;
  }
  throw StateError(
    'Missing native $role "$name"; present: ${[for (var i = 0; i < nodes.length; i++) _name(nodes.item(i)!)]}',
  );
}

String _name(_Element node) =>
    node.getAttribute('aria-label') ?? node.textContent?.trim() ?? '';

void _type(_Element input, String text) {
  input.value = text;
  input.setSelectionRange(text.length, text.length);
  input.dispatchEvent(
    _InputEvent(
      'input',
      _InputOptions(data: text, inputType: 'insertText', bubbles: true),
    ),
  );
}

Future<void> _enter(WidgetTester tester) async {
  final target = _document.activeElement!;
  for (final type in ['keydown', 'keyup']) {
    target.dispatchEvent(
      _KeyboardEvent(
        type,
        _KeyboardOptions(
          key: 'Enter',
          code: 'Enter',
          bubbles: true,
          cancelable: true,
        ),
      ),
    );
  }
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
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
  external String? getAttribute(String name);
  external String? get textContent;
  external String get value;
  external bool get disabled;
  external set value(String value);
  external void focus();
  external void setSelectionRange(int start, int end);
  external bool dispatchEvent(JSObject event);
}

@JS('InputEvent')
extension type _InputEvent._(JSObject _) implements JSObject {
  external factory _InputEvent(String type, _InputOptions options);
}

@JS()
@anonymous
extension type _InputOptions._(JSObject _) implements JSObject {
  external factory _InputOptions({
    required String data,
    required String inputType,
    required bool bubbles,
  });
}

@JS('KeyboardEvent')
extension type _KeyboardEvent._(JSObject _) implements JSObject {
  external factory _KeyboardEvent(String type, _KeyboardOptions options);
}

@JS()
@anonymous
extension type _KeyboardOptions._(JSObject _) implements JSObject {
  external factory _KeyboardOptions({
    required String key,
    required String code,
    required bool bubbles,
    required bool cancelable,
  });
}
