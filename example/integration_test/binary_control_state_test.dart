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

enum _Kind { checkbox, radio, toggle }

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final _Kind kind in _Kind.values) {
    for (final bool initial in <bool>[false, true]) {
      testWidgets('native ${kind.name} states and activation, value=$initial', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
        try {
          await tester.pumpWidget(
            WidgetsApp(
              color: const Color(0xFFFFFFFF),
              builder: (_, _) => CarbonTheme(
                data: CarbonThemeData.white,
                child: _Fixture(key: key, kind: kind, initial: initial),
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
          for (final (bool disabled, bool readOnly, bool callback)
              in <(bool, bool, bool)>[
                (false, false, true),
                (false, true, true),
                (true, false, true),
                (true, true, true),
                (false, true, false),
                (false, false, false),
                (false, false, true),
              ]) {
            state.configure(
              disabled: disabled,
              readOnly: readOnly,
              callback: callback,
            );
            await _settle(tester);
            final bool focusable = !disabled && callback;
            final bool operable = focusable && !readOnly;
            final _Element control = _control();
            expect(control.getAttribute('aria-checked'), initial.toString());
            expect(
              control.getAttribute('aria-disabled'),
              operable ? anyOf(isNull, 'false') : 'true',
            );
            expect(
              control.getAttribute('aria-description'),
              focusable && readOnly ? 'Read only' : anyOf(isNull, ''),
            );
            _button('Before').focus();
            await _settle(tester);
            await _key(tester, LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab);
            expect(state.focus.hasPrimaryFocus, focusable);
            expect(
              _document.activeElement == _control(),
              focusable,
              reason:
                  'mode=($disabled,$readOnly,$callback) active=${_document.activeElement?.tagName}/${_document.activeElement?.getAttribute('role')}/${_document.activeElement?.getAttribute('aria-label')} control=${_control().getAttribute('tabindex')}/${_control().getAttribute('aria-label')}',
            );
            final int count = state.changes;
            if (focusable) {
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
            }
            _control().click();
            await _settle(tester);
            expect(state.changes - count, operable ? 3 : 0);
            expect(_control().getAttribute('aria-checked'), initial.toString());
            if (focusable && readOnly) {
              _button('After').focus();
              await _settle(tester);
              state.focus.requestFocus();
              await tester.pump();
              _button('After').focus();
              await _settle(tester);
              expect(state.focus.hasPrimaryFocus, isFalse);
              expect(_document.activeElement == _button('After'), isTrue);
              expect(state.changes, count);
            }
            expect(tester.takeException(), isNull);
          }
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          semantics.dispose();
        }
      });
    }
  }
}

class _Fixture extends StatefulWidget {
  const _Fixture({required this.kind, required this.initial, super.key});
  final _Kind kind;
  final bool initial;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  final FocusNode focus = FocusNode();
  bool disabled = false, readOnly = false, callback = true;
  int changes = 0;
  void configure({
    required bool disabled,
    required bool readOnly,
    required bool callback,
  }) => setState(() {
    this.disabled = disabled;
    this.readOnly = readOnly;
    this.callback = callback;
  });
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CarbonButton(label: 'Before', onPressed: () {}),
        const SizedBox(width: 24),
        switch (widget.kind) {
          _Kind.checkbox => CarbonCheckbox(
            label: 'Control',
            value: widget.initial,
            disabled: disabled,
            readOnly: readOnly,
            focusNode: focus,
            onChanged: callback ? (_) => changes++ : null,
          ),
          _Kind.radio => CarbonRadioButton(
            label: 'Control',
            selected: widget.initial,
            disabled: disabled,
            readOnly: readOnly,
            focusNode: focus,
            onSelected: callback ? () => changes++ : null,
          ),
          _Kind.toggle => CarbonToggle(
            labelText: 'Control',
            toggled: widget.initial,
            disabled: disabled,
            readOnly: readOnly,
            focusNode: focus,
            onToggled: callback ? (_) => changes++ : null,
          ),
        },
        const SizedBox(width: 24),
        CarbonButton(label: 'After', onPressed: () {}),
      ],
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

_Element _control() => _document
    .querySelectorAll('[role="checkbox"], [role="radio"], [role="switch"]')
    .item(0)!;
_Element _button(String name) {
  final _NodeList nodes = _document.querySelectorAll(
    'flt-semantics[role="button"]',
  );
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if (node.textContent?.trim() == name ||
        node.getAttribute('aria-label') == name) {
      return node;
    }
  }
  throw StateError('Missing $name');
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
  external String get tagName;
  external String? get textContent;
  external String? getAttribute(String name);
  external void focus();
  external void click();
}
