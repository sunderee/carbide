// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final TextDirection direction in TextDirection.values) {
    for (final bool readOnly in <bool>[false, true]) {
      testWidgets(
        'native password keyboard and policy, $direction readOnly=$readOnly',
        (WidgetTester tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
          try {
            await tester.pumpWidget(
              WidgetsApp(
                color: const Color(0xFFFFFFFF),
                builder: (_, _) => Directionality(
                  textDirection: direction,
                  child: CarbonTheme(
                    data: CarbonThemeData.white,
                    child: _Fixture(key: key, readOnly: readOnly),
                  ),
                ),
              ),
            );
            await _settle(tester);
            _document.querySelectorAll('flutter-view').item(0)!.focus();
            tester.binding.handleViewFocusChanged(
              ViewFocusEvent(
                viewId: tester.view.viewId,
                state: ViewFocusState.focused,
                direction: ViewFocusDirection.undefined,
              ),
            );
            final _FixtureState state = key.currentState!;
            state.field.requestFocus();
            await _settle(tester);
            _input().focus();
            await _settle(tester);
            expect(_input().type, 'password');
            expect(_input().value, 'secret');
            await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
            expect(_document.activeElement == _button('Show password'), isTrue);
            for (final (
                  LogicalKeyboardKey logical,
                  PhysicalKeyboardKey physical,
                  String type,
                  String label,
                )
                in <(LogicalKeyboardKey, PhysicalKeyboardKey, String, String)>[
                  (
                    LogicalKeyboardKey.enter,
                    PhysicalKeyboardKey.enter,
                    'text',
                    'Hide password',
                  ),
                  (
                    LogicalKeyboardKey.space,
                    PhysicalKeyboardKey.space,
                    'password',
                    'Show password',
                  ),
                ]) {
              await _key(tester, logical, physical);
              expect(_input().type, type);
              expect(_input().value, 'secret');
              expect(_document.activeElement == _button(label), isTrue);
              expect(state.controller.text, 'secret');
              expect(state.edits, 0);
            }
            await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
            expect(_document.activeElement == _button('After'), isTrue);
            await tester.sendKeyDownEvent(
              LogicalKeyboardKey.shiftLeft,
              physicalKey: PhysicalKeyboardKey.shiftLeft,
            );
            await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
            await tester.sendKeyUpEvent(
              LogicalKeyboardKey.shiftLeft,
              physicalKey: PhysicalKeyboardKey.shiftLeft,
            );
            await _settle(tester);
            expect(_document.activeElement == _button('Show password'), isTrue);
            _button('Show password').click();
            await _settle(tester);
            expect(_input().type, 'text');
            state.configure(disabled: true);
            await _settle(tester);
            expect(
              _button('Hide password').getAttribute('aria-disabled'),
              'true',
            );
            _button('Hide password').click();
            await _key(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            await _key(
              tester,
              LogicalKeyboardKey.space,
              PhysicalKeyboardKey.space,
            );
            expect(_input().type, 'text');
            expect(state.edits, 0);
            _button('Before').focus();
            await _settle(tester);
            for (int i = 0; i < 2; i++) {
              await _key(
                tester,
                LogicalKeyboardKey.tab,
                PhysicalKeyboardKey.tab,
              );
              expect(
                _document.activeElement == _button('Hide password'),
                isFalse,
              );
            }
            state.configure(disabled: false);
            await _settle(tester);
            _button('Hide password').focus();
            await _settle(tester);
            expect(
              Focus.of(tester.element(find.byType(CarbonIcon))).hasPrimaryFocus,
              isTrue,
            );
            await _key(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            expect(_input().type, 'password');
            expect(_document.activeElement == _button('Show password'), isTrue);
            expect(state.controller.text, 'secret');
            expect(state.edits, 0);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            semantics.dispose();
          }
        },
      );
    }
  }
}

class _Fixture extends StatefulWidget {
  const _Fixture({required this.readOnly, super.key});
  final bool readOnly;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  final FocusNode field = FocusNode();
  final TextEditingController controller = TextEditingController(
    text: 'secret',
  );
  bool disabled = false;
  int edits = 0;
  void configure({required bool disabled}) =>
      setState(() => this.disabled = disabled);
  @override
  void dispose() {
    field.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarbonButton(label: 'Before', onPressed: () {}),
          CarbonPasswordInput(
            labelText: 'Password',
            controller: controller,
            focusNode: field,
            disabled: disabled,
            readOnly: widget.readOnly,
            onChanged: (_) => edits++,
          ),
          CarbonButton(label: 'After', onPressed: () {}),
        ],
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await tester.pumpAndSettle();
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey logical,
  PhysicalKeyboardKey physical,
) async {
  await tester.sendKeyEvent(logical, physicalKey: physical);
  await _settle(tester);
}

_Element _input() => _document.querySelectorAll('input').item(0)!;
_Element _button(String label) {
  final _NodeList nodes = _document.querySelectorAll(
    'flt-semantics[role="button"]',
  );
  for (int i = 0; i < nodes.length; i++) {
    final _Element element = nodes.item(i)!;
    if (element.getAttribute('aria-label') == label ||
        element.textContent?.trim() == label) {
      return element;
    }
  }
  throw StateError('Missing $label');
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
  external String? get textContent;
  external String get type;
  external String get value;
  external String? getAttribute(String name);
  external void focus();
  external void click();
}
