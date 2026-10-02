// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// Browser-only: exercise the accessible native textarea and composition events
// that the Flutter 3.47.6 semantics input strategy otherwise omits.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a queued composition commit cannot rewrite a programmatic replacement',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final TextEditingController controller = TextEditingController(
        text: 'ABCD',
      );
      final FocusNode focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      try {
        await _mount(tester, controller, focus, 6);
        focus.requestFocus();
        await _settle(tester);
        _native().focus();
        controller.selection = const TextSelection.collapsed(offset: 2);
        await _settle(tester);
        _native().dispatchEvent(
          _CompositionEvent(
            'compositionstart',
            _EventOptions(data: '', bubbles: true),
          ),
        );
        _compose('AB日本語CD', 2, '日本語');
        await _settle(tester);
        _native().dispatchEvent(
          _CompositionEvent(
            'compositionend',
            _EventOptions(data: '日本語', bubbles: true),
          ),
        );
        controller.text = 'caller replacement';
        await _settle(tester);
        expect(controller.text, 'caller replacement');
        expect(_native().value, 'caller replacement');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );

  for (final (
        String name,
        int max,
        TextSelection selection,
        String composed,
        String expected,
      )
      in <(String, int, TextSelection, String, String)>[
        (
          'full',
          4,
          const TextSelection.collapsed(offset: 4),
          'ABCD日本語',
          'ABCD',
        ),
        (
          'middle',
          6,
          const TextSelection.collapsed(offset: 2),
          'AB日本語CD',
          'AB日本CD',
        ),
        (
          'replacement',
          4,
          const TextSelection(baseOffset: 1, extentOffset: 3),
          'A日本語D',
          'A日本D',
        ),
      ]) {
    testWidgets(
      'native $name composition remains intact and commits without another input event',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final TextEditingController controller = TextEditingController(
          text: 'ABCD',
        );
        final FocusNode focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        try {
          await _mount(tester, controller, focus, max);
          focus.requestFocus();
          await _settle(tester);
          _native().focus();
          controller.selection = selection;
          await _settle(tester);
          expect(_native().disabled, isFalse);
          // No native UTF-16 maxlength: the Dart formatter owns grapheme units.
          expect(_native().maxLength, -1);
          _native().dispatchEvent(
            _CompositionEvent(
              'compositionstart',
              _EventOptions(data: '', bubbles: true),
            ),
          );
          _compose(composed, selection.start, '日本語');
          await _settle(tester);
          expect(controller.text, composed);
          expect(
            controller.value.composing,
            TextRange(start: selection.start, end: selection.start + 3),
          );
          expect(_native().value, composed);
          expect(
            find.text('${composed.characters.length}/$max'),
            findsOneWidget,
          );
          _native().dispatchEvent(
            _CompositionEvent(
              'compositionend',
              _EventOptions(data: '日本語', bubbles: true),
            ),
          );
          await _settle(tester);
          expect(controller.text, expected);
          expect(controller.value.composing, TextRange.empty);
          expect(_native().value, expected);
          expect(_native().getRootNode().activeElement, _native());
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
        }
      },
    );
  }

  testWidgets(
    'native paste round-trip uses graphemes and keeps its existing suffix',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final TextEditingController controller = TextEditingController(
        text: 'ABCD',
      );
      final FocusNode focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      try {
        await _mount(tester, controller, focus, 6);
        focus.requestFocus();
        await _settle(tester);
        _native().focus();
        controller.selection = const TextSelection.collapsed(offset: 2);
        await _settle(tester);
        _input('AB🇸🇮e\u0301👨‍👩‍👧‍👦CD', 19, type: 'insertFromPaste');
        await _settle(tester);
        expect(controller.text, 'AB🇸🇮e\u0301CD');
        expect(_native().value, controller.text);
        expect(_native().selectionStart, 8);
        expect(find.text('6/6'), findsOneWidget);
        expect(_native().getRootNode().activeElement, _native());
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'blur commits composition and disposal cancels a queued native commit',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final TextEditingController controller = TextEditingController(
        text: 'ABCD',
      );
      final FocusNode focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      try {
        await _mount(tester, controller, focus, 6);
        focus.requestFocus();
        await _settle(tester);
        _native().focus();
        controller.selection = const TextSelection.collapsed(offset: 2);
        await _settle(tester);
        _native().dispatchEvent(
          _CompositionEvent(
            'compositionstart',
            _EventOptions(data: '', bubbles: true),
          ),
        );
        _compose('AB日本語CD', 2, '日本語');
        await _settle(tester);
        focus.unfocus();
        await _settle(tester);
        expect(controller.text, 'AB日本CD');
        expect(controller.value.composing, TextRange.empty);

        focus.requestFocus();
        await _settle(tester);
        _native().focus();
        controller.selection = const TextSelection.collapsed(offset: 2);
        await _settle(tester);
        _native().dispatchEvent(
          _CompositionEvent(
            'compositionstart',
            _EventOptions(data: '', bubbles: true),
          ),
        );
        _compose('AB日本語日本CD', 2, '日本語');
        await _settle(tester);
        _native().dispatchEvent(
          _CompositionEvent(
            'compositionend',
            _EventOptions(data: '日本語', bubbles: true),
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await _settle(tester);
        expect(tester.takeException(), isNull);
        controller.text = 'still caller-owned';
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );
}

Future<void> _mount(
  WidgetTester tester,
  TextEditingController controller,
  FocusNode focus,
  int max,
) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (BuildContext context, Widget? _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: 400,
            child: CarbonTextArea(
              labelText: 'Note',
              controller: controller,
              focusNode: focus,
              maxCount: max,
              enableCounter: true,
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void _compose(String fullText, int base, String composing) {
  _native().dispatchEvent(
    _CompositionEvent(
      'compositionupdate',
      _EventOptions(data: composing, bubbles: true),
    ),
  );
  _input(
    fullText,
    base + composing.length,
    type: 'insertCompositionText',
    composing: true,
  );
}

void _input(
  String text,
  int caret, {
  required String type,
  bool composing = false,
}) {
  final _Element input = _native();
  input.value = text;
  input.setSelectionRange(caret, caret);
  input.dispatchEvent(
    _InputEvent(
      'input',
      _EventOptions(
        data: text,
        inputType: type,
        bubbles: true,
        isComposing: composing,
      ),
    ),
  );
}

_Element _native() => _document.querySelector('textarea')!;

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _Element? get activeElement;
}

extension type _Element(JSObject _) implements JSObject {
  external String get value;
  external set value(String value);
  external bool get disabled;
  external int get maxLength;
  external int get selectionStart;
  external void focus();
  external void setSelectionRange(int start, int end);
  external bool dispatchEvent(JSObject event);
  external _Document getRootNode();
}

@JS()
extension type _EventOptions._(JSObject _) implements JSObject {
  external factory _EventOptions({
    String data,
    String inputType,
    bool bubbles,
    bool isComposing,
  });
}

@JS('InputEvent')
extension type _InputEvent._(JSObject _) implements JSObject {
  external factory _InputEvent(String type, _EventOptions options);
}

@JS('CompositionEvent')
extension type _CompositionEvent._(JSObject _) implements JSObject {
  external factory _CompositionEvent(String type, _EventOptions options);
}
