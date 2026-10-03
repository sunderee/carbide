// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// This web-only regression inspects the actual HTML inputs. Flutter's focus
// state alone cannot detect a disabled or reparented native input.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

typedef _FieldBuilder = Widget Function(
  TextEditingController? controller,
  FocusNode? focus,
  bool disabled,
);

final Map<String, _FieldBuilder> _fields = <String, _FieldBuilder>{
  'text input': (TextEditingController? c, FocusNode? f, bool d) =>
      CarbonTextInput(
        labelText: 'Field',
        controller: c,
        focusNode: f,
        disabled: d,
      ),
  'password': (TextEditingController? c, FocusNode? f, bool d) =>
      CarbonPasswordInput(
        labelText: 'Field',
        controller: c,
        focusNode: f,
        disabled: d,
      ),
  'text area': (TextEditingController? c, FocusNode? f, bool d) =>
      CarbonTextArea(
        labelText: 'Field',
        controller: c,
        focusNode: f,
        disabled: d,
      ),
  'search': (TextEditingController? c, FocusNode? f, bool d) => CarbonSearch(
    labelText: 'Field',
    controller: c,
    focusNode: f,
    disabled: d,
  ),
  'time picker': (TextEditingController? c, FocusNode? f, bool d) =>
      CarbonTimePicker(
        labelText: 'Field',
        controller: c,
        focusNode: f,
        disabled: d,
      ),
  'expandable search': (TextEditingController? c, FocusNode? f, bool d) =>
      CarbonExpandableSearch(labelText: 'Field', controller: c, disabled: d),
  'number input': (TextEditingController? c, FocusNode? f, bool d) =>
      CarbonNumberInput(
        labelText: 'Field',
        value: 2,
        focusNode: f,
        disabled: d,
      ),
  'combo box': (TextEditingController? c, FocusNode? f, bool d) =>
      CarbonComboBox<String>(
        titleText: 'Field',
        selectedItem: 'a',
        focusNode: f,
        disabled: d,
        items: const <CarbonComboBoxItem<String>>[
          CarbonComboBoxItem<String>(value: 'a', label: 'Apple'),
        ],
      ),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final MapEntry<String, _FieldBuilder> field in _fields.entries) {
    testWidgets(
      '${field.key}: native focus survives ownership and content changes',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final TextEditingController a = TextEditingController(text: 'alpha');
        final TextEditingController b = TextEditingController(text: 'beta');
        final FocusNode fa = FocusNode();
        final FocusNode fb = FocusNode();
        addTearDown(a.dispose);
        addTearDown(b.dispose);
        addTearDown(fa.dispose);
        addTearDown(fb.dispose);
        TextEditingController? controller = a;
        FocusNode? focus = fa;
        bool disabled = false;
        final bool controllerField = !<String>[
          'number input',
          'combo box',
        ].contains(field.key);
        final String initial = field.key == 'number input'
            ? '2'
            : field.key == 'combo box'
            ? 'Apple'
            : 'alpha';
        late StateSetter update;
        final OverlayEntry entry = OverlayEntry(
          builder: (BuildContext context) => Center(
            child: SizedBox(
              width: 400,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  update = setState;
                  return field.value(controller, focus, disabled);
                },
              ),
            ),
          ),
        );
        try {
          await tester.pumpWidget(
            WidgetsApp(
              color: const Color(0xFFFFFFFF),
              builder: (BuildContext context, Widget? child) => CarbonTheme(
                data: CarbonThemeData.white,
                child: Overlay(initialEntries: <OverlayEntry>[entry]),
              ),
            ),
          );
          await _settle(tester);
          if (field.key == 'expandable search') {
            await tester.tap(find.byType(CarbonInteraction).first);
          } else {
            fa.requestFocus();
          }
          await _settle(tester);
          _input().focus();
          await _settle(tester);
          _expectInput(initial);
          // Exercise the field's real tap-region geometry while native editing
          // is active, including a combo box whose menu opens on focus.
          await tester.tap(find.byType(EditableText));
          await _settle(tester);
          _expectInput(initial);

          update(() {
            controller = b;
            focus = fb;
          });
          await _settle(tester);
          _expectInput(controllerField ? 'beta' : initial);
          a.text = 'obsolete';
          await _settle(tester);
          _expectInput(controllerField ? 'beta' : initial);
          if (controllerField) {
            b.clear();
            await _settle(tester);
            _expectInput('');
            b.text = 'current';
            await _settle(tester);
            _expectInput('current');
          }
          update(() {
            controller = null;
            focus = null;
          });
          await _settle(tester);
          _expectInput(controllerField ? 'current' : initial);
          b.text = 'obsolete';
          fb.requestFocus();
          await _settle(tester);
          _expectInput(controllerField ? 'current' : initial);

          update(() => disabled = true);
          await _settle(tester);
          expect(_input().disabled, isTrue);
          expect(tester.takeException(), isNull);
        } finally {
          entry.remove();
          await tester.pumpWidget(const SizedBox.shrink());
          entry.dispose();
          semantics.dispose();
        }
        // Both caller-owned resources remain usable after teardown.
        a.text = 'still owned by caller';
        b.text = 'still owned by caller';
      },
    );
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // The web engine applies semantics updates asynchronously after the frame.
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void _expectInput(String text) {
  final _Element input = _input();
  expect(input.value, text);
  expect(input.disabled, isFalse);
  expect(identical(input.getRootNode().activeElement, input), isTrue);
}

_Element _input() => _document.querySelector('input,textarea')!;

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
  external _Element? get activeElement;
}

extension type _Element(JSObject _) implements JSObject {
  external String get value;
  external bool get disabled;
  external void focus();
  external _Document getRootNode();
}
