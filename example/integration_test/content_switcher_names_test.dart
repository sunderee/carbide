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
    for (final bool iconOnly in <bool>[false, true]) {
      testWidgets('native switcher names, $direction iconOnly=$iconOnly', (
        WidgetTester tester,
      ) async {
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
                  child: _Fixture(key: key, iconOnly: iconOnly),
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
          await _settle(tester);
          final _FixtureState state = key.currentState!;
          expect(_named('Liste anzeigen').length, 1);
          expect(_named('Grid view').length, 1);
          expect(_named('Archived view').length, 1);
          expect(
            _button('Liste anzeigen').getAttribute('aria-current'),
            'true',
          );
          expect(_button('Grid view').getAttribute('aria-current'), 'false');
          expect(
            _button('Archived view').getAttribute('aria-disabled'),
            'true',
          );
          // Labels belong to the button; its decorative icon adds no child.
          expect(
            _button('Liste anzeigen').querySelectorAll('[aria-label]').length,
            0,
          );
          _button('Grid view').click();
          await _settle(tester);
          expect(state.selected, 1);
          expect(state.changes, 1);
          expect(_button('Grid view').getAttribute('aria-current'), 'true');
          _button('Archived view').click();
          await _settle(tester);
          expect(state.selected, 1);
          expect(state.changes, 1);
          await tester.sendKeyEvent(
            direction == TextDirection.ltr
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft,
            // Flutter infers physical keys from debug names, which are absent
            // in release mode. Supply the real key in both configurations.
            physicalKey: direction == TextDirection.ltr
                ? PhysicalKeyboardKey.arrowRight
                : PhysicalKeyboardKey.arrowLeft,
          );
          await _settle(tester);
          expect(state.selected, 0);
          expect(state.changes, 2);
          state.renameAndEnable();
          await _settle(tester);
          expect(_named('Liste anzeigen'), isEmpty);
          expect(_named('List view').length, 1);
          expect(_button('List view').getAttribute('aria-current'), 'true');
          expect(
            _button('Archived view').getAttribute('aria-disabled'),
            isNull,
          );
          _button('Archived view').click();
          await _settle(tester);
          expect(state.selected, 2);
          expect(state.changes, 3);
          expect(tester.takeException(), isNull);
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
  const _Fixture({required this.iconOnly, super.key});
  final bool iconOnly;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  int selected = 0;
  int changes = 0;
  bool disabled = true;
  String label = 'Liste anzeigen';
  void renameAndEnable() => setState(() {
    label = 'List view';
    disabled = false;
  });
  @override
  Widget build(BuildContext context) => Center(
    child: CarbonContentSwitcher(
      selectedIndex: selected,
      onChanged: (int index) => setState(() {
        selected = index;
        changes++;
      }),
      switches: <CarbonSwitch>[
        CarbonSwitch(
          text: widget.iconOnly ? null : 'Visible list',
          icon: CarbonIcons.list,
          semanticLabel: label,
        ),
        const CarbonSwitch(icon: CarbonIcons.grid, semanticLabel: 'Grid view'),
        CarbonSwitch(
          icon: CarbonIcons.archive,
          semanticLabel: 'Archived view',
          disabled: disabled,
        ),
      ],
    ),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await tester.pumpAndSettle();
}

List<_Element> _named(String label) {
  final _NodeList nodes = _document.querySelectorAll(
    'flt-semantics[role="button"]',
  );
  return <_Element>[
    for (int i = 0; i < nodes.length; i++)
      if (nodes.item(i)!.getAttribute('aria-label') == label ||
          nodes.item(i)!.textContent?.trim() == label)
        nodes.item(i)!,
  ];
}

_Element _button(String label) => _named(label).single;

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external String? getAttribute(String name);
  external _NodeList querySelectorAll(String selector);
  external void click();
  external void focus();
}
