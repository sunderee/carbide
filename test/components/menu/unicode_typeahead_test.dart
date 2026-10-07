// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide/src/components/list_box/list_box_semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';

const List<String> _labels = <String>[
  'Start',
  'Écarté',
  'Éditer',
  'Über',
  'Данные',
  '東京',
  '𐐨eseret',
  '١ item',
  'ßort',
  'Export',
  'Xray',
  '?Help',
];
const List<(String, String)> _cases = <(String, String)>[
  ('e', 'Éditer'),
  ('é', 'Éditer'),
  ('E\u0301', 'Éditer'),
  ('u', 'Über'),
  ('Ü', 'Über'),
  ('Д', 'Данные'),
  ('東', '東京'),
  ('𐐀', '𐐨eseret'),
  ('١', '١ item'),
  ('s', 'ßort'),
];

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    Directionality(
      textDirection: direction,
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (BuildContext context) =>
                  Center(child: SizedBox(width: 320, child: child)),
            ),
          ],
        ),
      ),
    );

Widget _control(String family, FocusNode node, ValueChanged<String> onChosen) =>
    switch (family) {
      'menu' => CarbonMenu(
        children: <Widget>[
          for (final String label in _labels)
            CarbonMenuItem(
              label: label,
              disabled: label == 'Écarté',
              onPressed: () => onChosen(label),
            ),
        ],
      ),
      'select' => CarbonSelect<String>(
        labelText: 'Actions',
        focusNode: node,
        onChanged: (String? value) => onChosen(value!),
        items: <CarbonSelectItem<String>>[
          for (final String label in _labels)
            CarbonSelectItem<String>(
              value: label,
              label: label,
              disabled: label == 'Écarté',
            ),
        ],
      ),
      _ => CarbonDropdown<String>(
        titleText: 'Actions',
        focusNode: node,
        onChanged: onChosen,
        items: <CarbonDropdownItem<String>>[
          for (final String label in _labels)
            CarbonDropdownItem<String>(
              value: label,
              label: label,
              disabled: label == 'Écarté',
            ),
        ],
      ),
    };

String? _active(WidgetTester tester, String family) {
  if (family == 'menu') {
    for (final Focus focus in tester.widgetList<Focus>(find.byType(Focus))) {
      if (focus.focusNode?.hasPrimaryFocus ?? false) {
        final Finder labels = find.descendant(
          of: find.byWidget(focus),
          matching: find.byType(Text),
        );
        if (labels.evaluate().isNotEmpty) {
          return tester.widget<Text>(labels.first).data;
        }
      }
    }
    return null;
  }
  final CarbonListBoxOptionSemantics item = tester
      .widgetList<CarbonListBoxOptionSemantics>(
        find.byType(CarbonListBoxOptionSemantics),
      )
      .singleWhere((CarbonListBoxOptionSemantics row) => row.active);
  return item.label;
}

Future<void> _open(WidgetTester tester, String family, FocusNode node) async {
  if (family != 'menu') {
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
  }
  await tester.pumpAndSettle();
  expect(_active(tester, family), 'Start');
}

void main() {
  for (final String family in <String>['menu', 'select', 'dropdown']) {
    for (final (String input, String expected) in _cases) {
      testWidgets('$family matches $input to $expected without committing', (
        WidgetTester tester,
      ) async {
        final FocusNode node = FocusNode();
        addTearDown(node.dispose);
        String? chosen;
        await tester.pumpWidget(
          _host(_control(family, node, (String value) => chosen = value)),
        );
        await _open(tester, family, node);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: input);
        await tester.pumpAndSettle();
        expect(_active(tester, family), expected);
        expect(chosen, isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(chosen, expected);
      });
    }
    testWidgets(
      '$family cycles repeated characters and keeps independent keys over time',
      (WidgetTester tester) async {
        final FocusNode node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(_host(_control(family, node, (String _) {})));
        await _open(tester, family, node);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: 'e');
        await tester.pumpAndSettle();
        expect(_active(tester, family), 'Éditer');
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: 'e');
        await tester.pumpAndSettle();
        expect(_active(tester, family), 'Export');
        await tester.pump(const Duration(seconds: 1));
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: 'e');
        await tester.pumpAndSettle();
        expect(_active(tester, family), 'Éditer');
        await tester.sendKeyEvent(LogicalKeyboardKey.keyX, character: 'x');
        await tester.pumpAndSettle();
        expect(_active(tester, family), 'Xray');
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: '\n');
        await tester.pumpAndSettle();
        expect(_active(tester, family), 'Xray');
      },
    );
    testWidgets(
      '$family preserves its existing multi-character and punctuation policy',
      (WidgetTester tester) async {
        final FocusNode node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(
          _host(
            _control(family, node, (String _) {}),
            direction: TextDirection.rtl,
          ),
        );
        await _open(tester, family, node);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: 'ex');
        await tester.pumpAndSettle();
        expect(_active(tester, family), family == 'menu' ? 'Start' : 'Export');
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: '?');
        await tester.pumpAndSettle();
        expect(_active(tester, family), family == 'menu' ? 'Start' : '?Help');
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE, character: 'Д');
        await tester.pumpAndSettle();
        expect(_active(tester, family), 'Данные');
      },
    );
  }
}
