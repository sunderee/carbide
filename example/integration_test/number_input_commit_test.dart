// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

// Browser-only: committed values must agree with the accessible native input,
// including when a stepper owns focus and the engine stops applying edits.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native read-only and disabled state follow focused rebuilds', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final _FixtureState state = await _mount(tester);
      state.configure(readOnly: true);
      await _settle(tester);
      state.focus.requestFocus();
      await _settle(tester);
      _native('Quantity').focus();
      await _settle(tester);
      expect(_native('Quantity').readOnly, isTrue);
      expect(_native('Quantity').disabled, isFalse);
      expect(_native('Quantity').value, '5');
      state.replace(6);
      await _settle(tester);
      expect(_native('Quantity').value, '6');
      state.configure(readOnly: false);
      await _settle(tester);
      expect(_native('Quantity').readOnly, isFalse);
      state.configure(disabled: true);
      await _settle(tester);
      expect(_native('Quantity').disabled, isTrue);
      state.configure(disabled: false);
      await _settle(tester);
      expect(_native('Quantity').disabled, isFalse);
      expect(_native('Quantity').readOnly, isFalse);
      expect(state.changes, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    }
  });

  testWidgets(
    'inactive values initialize when accessibility is enabled later',
    (WidgetTester tester) async {
      await _mount(tester, secondField: true);
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await _settle(tester);
        expect(_native('Quantity').value, '5');
        expect(_native('Other quantity').value, '7');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );

  testWidgets('native IME candidate navigation preserves the composing draft', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final _FixtureState state = await _mount(tester);
      state.focus.requestFocus();
      await _settle(tester);
      await tester.tap(find.byType(EditableText));
      await _settle(tester);
      _native('Quantity').focus();
      await _settle(tester);
      _native('Quantity').setSelectionRange(0, 1);
      _native('Quantity').dispatchEvent(
        _CompositionEvent(
          'compositionstart',
          _EventOptions(data: '', bubbles: true),
        ),
      );
      _native('Quantity').dispatchEvent(
        _CompositionEvent(
          'compositionupdate',
          _EventOptions(data: '1e', bubbles: true),
        ),
      );
      _input('Quantity', '1e');
      await _settle(tester);
      final TextEditingController controller = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      expect(controller.value.composing, const TextRange(start: 0, end: 2));
      expect(controller.text, '1e');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      // The native keyboard may also report Done while selecting a candidate.
      tester
          .widget<EditableText>(find.byType(EditableText))
          .onEditingComplete!();
      await _settle(tester);
      expect(controller.text, '1e');
      expect(_native('Quantity').value, '1e');
      expect(state.changes, isEmpty);
      _native('Quantity').dispatchEvent(
        _CompositionEvent(
          'compositionend',
          _EventOptions(data: '1e', bubbles: true),
        ),
      );
      await _settle(tester);
      expect(controller.value.composing, TextRange.empty);
      expect(state.changes, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(state.changes, <num?>[5]);
      expect(controller.text, '5');
      expect(_native('Quantity').value, '5');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    }
  });

  for (final bool allowEmpty in <bool>[false, true]) {
    testWidgets('native blur commits every draft, allowEmpty=$allowEmpty', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        for (final (String draft, num? expected) in <(String, num?)>[
          ('-', 5),
          ('.', 5),
          ('1e', 5),
          ('', allowEmpty ? null : 0),
          ('bad', 5),
          ('-9', 0),
          ('99', 10),
          ('NaN', 5),
          ('Infinity', 5),
          ('0003.50', 3.5),
        ]) {
          final _FixtureState state = await _mount(
            tester,
            allowEmpty: allowEmpty,
          );
          expect(_native('Quantity').value, '5');
          state.focus.requestFocus();
          await _settle(tester);
          _native('Quantity').focus();
          await _settle(tester);
          await tester.tap(find.byType(EditableText));
          await _settle(tester);
          _input('Quantity', draft);
          await _settle(tester);
          expect(state.value, 5);
          expect(state.changes, isEmpty);
          expect(_native('Quantity').value, draft);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            draft,
          );
          state.outside.requestFocus();
          await _settle(tester);
          expect(state.value, expected);
          expect(state.changes, <num?>[expected]);
          expect(_native('Quantity').value, expected?.toString() ?? '');
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            _native('Quantity').value,
          );
          state.focus.requestFocus();
          await _settle(tester);
          state.outside.requestFocus();
          await _settle(tester);
          expect(state.changes, <num?>[expected]);
          expect(tester.takeException(), isNull);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'native stepper commits once and synchronizes the inactive input',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        for (final (String draft, num expected) in <(String, num)>[
          ('99', 10),
          ('-', 6),
          ('', 1),
          ('-9', 1),
          ('5.5', 6.5),
        ]) {
          final _FixtureState state = await _mount(tester);
          state.focus.requestFocus();
          await _settle(tester);
          _native('Quantity').focus();
          await _settle(tester);
          await tester.tap(find.byType(EditableText));
          await _settle(tester);
          _input('Quantity', draft);
          await _settle(tester);
          // Move through the component's actual keyboard focus stops before
          // activating the native button. A DOM focus event alone can leave
          // Flutter's editor focus unchanged in the integration harness.
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await _settle(tester);
          expect(state.focus.hasFocus, isFalse);
          final _Element stepper = _button('Increment number');
          stepper.focus();
          await _settle(tester);
          expect(state.changes, isEmpty);
          stepper.click();
          await _settle(tester);
          expect(state.changes, <num?>[expected]);
          expect(state.value, expected);
          expect(_native('Quantity').value, expected.toString());
          expect(
            _native('Quantity').getRootNode().activeElement,
            isNot(_native('Quantity')),
          );
          state.outside.requestFocus();
          await _settle(tester);
          expect(state.changes, <num?>[expected]);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
      }
    },
  );

  testWidgets('native values remain scoped to their field across rebuilds', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final _FixtureState state = await _mount(tester, secondField: true);
      expect(_native('Quantity').value, '5');
      expect(_native('Other quantity').value, '7');
      state.focus.requestFocus();
      await _settle(tester);
      _native('Quantity').focus();
      await _settle(tester);
      await tester.tap(find.byType(EditableText).first);
      await _settle(tester);
      _input('Quantity', '1e', caret: 1);
      await _settle(tester);
      state.rebuild(warning: true);
      await _settle(tester);
      expect(_native('Quantity').value, '1e');
      expect(_native('Quantity').selectionStart, 1);
      expect(
        _native('Quantity').getRootNode().activeElement,
        _native('Quantity'),
      );
      expect(_native('Other quantity').value, '7');
      expect(state.changes, isEmpty);
      state.replace(6);
      await _settle(tester);
      expect(_native('Quantity').value, '6');
      state.outside.requestFocus();
      await _settle(tester);
      state.replace(4);
      await _settle(tester);
      expect(_native('Quantity').value, '4');
      expect(_native('Other quantity').value, '7');
      expect(state.changes, isEmpty);
      // A scheduled native sync must not run after its state is disposed.
      state.replace(8);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      semantics.dispose();
    }
  });
}

Future<_FixtureState> _mount(
  WidgetTester tester, {
  bool allowEmpty = false,
  bool secondField = false,
}) async {
  final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (BuildContext context, Widget? _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: 400,
            child: _Fixture(
              key: key,
              allowEmpty: allowEmpty,
              secondField: secondField,
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  return key.currentState!;
}

class _Fixture extends StatefulWidget {
  const _Fixture({
    super.key,
    required this.allowEmpty,
    required this.secondField,
  });

  final bool allowEmpty;
  final bool secondField;

  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  final FocusNode focus = FocusNode();
  final FocusNode outside = FocusNode();
  final List<num?> changes = <num?>[];
  num? value = 5;
  bool warning = false;
  bool readOnly = false;
  bool disabled = false;

  void configure({bool? readOnly, bool? disabled}) => setState(() {
    this.readOnly = readOnly ?? this.readOnly;
    this.disabled = disabled ?? this.disabled;
  });

  void rebuild({required bool warning}) =>
      setState(() => this.warning = warning);

  void replace(num next) => setState(() => value = next);

  @override
  void dispose() {
    focus.dispose();
    outside.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      CarbonNumberInput(
        labelText: 'Quantity',
        value: value,
        min: 0,
        max: 10,
        allowEmpty: widget.allowEmpty,
        focusNode: focus,
        warn: warning,
        readOnly: readOnly,
        disabled: disabled,
        warnText: 'Check quantity',
        onChanged: (num? next) {
          changes.add(next);
          setState(() => value = next);
        },
      ),
      if (widget.secondField)
        const CarbonNumberInput(labelText: 'Other quantity', value: 7),
      Focus(focusNode: outside, child: const Text('Outside the field')),
    ],
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void _input(String label, String text, {int? caret}) {
  final _Element input = _native(label);
  input.value = text;
  input.setSelectionRange(caret ?? text.length, caret ?? text.length);
  input.dispatchEvent(
    _InputEvent('input', _EventOptions(data: text, bubbles: true)),
  );
}

_Element _native(String label) =>
    _document.querySelector('input[aria-label="$label"]')!;

_Element _button(String label) {
  final _NodeList buttons = _document.querySelectorAll(
    'flt-semantics[role="button"]',
  );
  for (int i = 0; i < buttons.length; i++) {
    final _Element button = buttons.item(i)!;
    if (button.textContent == label) {
      return button;
    }
  }
  throw StateError('Native button $label is missing');
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _NodeList querySelectorAll(String selector);
  external _Element? get activeElement;
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String get value;
  external set value(String value);
  external String get textContent;
  external int get selectionStart;
  external bool get readOnly;
  external bool get disabled;
  external void focus();
  external void click();
  external void setSelectionRange(int start, int end);
  external bool dispatchEvent(JSObject event);
  external _Document getRootNode();
}

@JS()
extension type _EventOptions._(JSObject _) implements JSObject {
  external factory _EventOptions({String data, bool bubbles});
}

@JS('InputEvent')
extension type _InputEvent._(JSObject _) implements JSObject {
  external factory _InputEvent(String type, _EventOptions options);
}

@JS('CompositionEvent')
extension type _CompositionEvent._(JSObject _) implements JSObject {
  external factory _CompositionEvent(String type, _EventOptions options);
}
