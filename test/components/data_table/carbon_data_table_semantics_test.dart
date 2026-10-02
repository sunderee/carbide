// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show CheckedState;

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';

void main() {
  for (final CarbonTableSelection selection in <CarbonTableSelection>[
    CarbonTableSelection.single,
    CarbonTableSelection.multi,
  ]) {
    testWidgets(
      '$selection selectors activate through semantics and keyboard',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          Set<int> selected = <int>{};
          int calls = 0;
          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) => _table(
                  selection,
                  selected,
                  (Set<int> next) => setState(() {
                    selected = next;
                    calls++;
                  }),
                ),
              ),
            ),
          );
          final SemanticsNode row = tester.getSemantics(
            find.bySemanticsLabel('Select row 1'),
          );
          expect(row.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
          final List<SemanticsNode> selectors = tester.semantics
              .simulatedAccessibilityTraversal()
              .where(
                (SemanticsNode node) =>
                    node.getSemanticsData().flagsCollection.isChecked !=
                    CheckedState.none,
              )
              .toList();
          expect(
            selectors,
            hasLength(selection == CarbonTableSelection.multi ? 3 : 2),
          );
          tester.binding.platformDispatcher.onSemanticsActionEvent!(
            SemanticsActionEvent(
              type: SemanticsAction.tap,
              nodeId: row.id,
              viewId: tester.view.viewId,
            ),
          );
          await tester.pumpAndSettle();
          expect(selected, <int>{0});
          expect(calls, 1);
          expect(
            tester.getSemantics(find.bySemanticsLabel('Select row 1')),
            isSemantics(isChecked: true),
          );
          final SemanticsNode second = tester.getSemantics(
            find.bySemanticsLabel('Select row 2'),
          );
          tester.binding.platformDispatcher.onSemanticsActionEvent!(
            SemanticsActionEvent(
              type: SemanticsAction.tap,
              nodeId: second.id,
              viewId: tester.view.viewId,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            selected,
            selection == CarbonTableSelection.multi ? <int>{0, 1} : <int>{1},
          );
          expect(calls, 2);
          final SemanticsNode focusTarget = tester.getSemantics(
            find.bySemanticsLabel('Select row 1'),
          );
          expect(
            focusTarget.getSemanticsData().hasAction(SemanticsAction.focus),
            isTrue,
          );
          tester.binding.platformDispatcher.onSemanticsActionEvent!(
            SemanticsActionEvent(
              type: SemanticsAction.focus,
              nodeId: focusTarget.id,
              viewId: tester.view.viewId,
            ),
          );
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.pumpAndSettle();
          expect(calls, 3);
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('$selection disabled selectors expose no activation', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(_host(_table(selection, <int>{0}, null)));
        final List<SemanticsNode> selectors = tester.semantics
            .simulatedAccessibilityTraversal()
            .where((SemanticsNode node) => node.label.startsWith('Select '))
            .toList();
        expect(
          selectors,
          hasLength(selection == CarbonTableSelection.multi ? 3 : 2),
        );
        for (final SemanticsNode node in selectors) {
          if (node.label.startsWith('Select ')) {
            expect(node, isSemantics(isEnabled: false));
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              isFalse,
            );
          }
        }
      } finally {
        handle.dispose();
      }
    });
  }

  testWidgets('switching selection modes updates role and keeps activation', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      CarbonTableSelection selection = CarbonTableSelection.multi;
      Set<int> selected = <int>{};
      late StateSetter update;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              update = setState;
              return _table(
                selection,
                selected,
                (Set<int> next) => setState(() => selected = next),
              );
            },
          ),
        ),
      );
      for (final CarbonTableSelection mode in <CarbonTableSelection>[
        CarbonTableSelection.single,
        CarbonTableSelection.multi,
      ]) {
        update(() {
          selection = mode;
          selected = <int>{};
        });
        await tester.pumpAndSettle();
        final SemanticsNode row = tester.getSemantics(
          find.bySemanticsLabel('Select row 1'),
        );
        expect(
          row,
          isSemantics(
            isInMutuallyExclusiveGroup: mode == CarbonTableSelection.single,
          ),
        );
        tester.binding.platformDispatcher.onSemanticsActionEvent!(
          SemanticsActionEvent(
            type: SemanticsAction.tap,
            nodeId: row.id,
            viewId: tester.view.viewId,
          ),
        );
        await tester.pumpAndSettle();
        expect(selected, <int>{0});
      }
    } finally {
      handle.dispose();
    }
  });

  testWidgets(
    'select-all activates, announces mixed state, selects and clears',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        Set<int> selected = <int>{0};
        int calls = 0;
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) => _table(
                CarbonTableSelection.multi,
                selected,
                (Set<int> next) => setState(() {
                  selected = next;
                  calls++;
                }),
              ),
            ),
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Select all rows')),
          isSemantics(
            isCheckStateMixed: true,
            value: kIsWeb ? 'Partially selected' : '',
          ),
        );
        for (final Set<int> expected in <Set<int>>[
          <int>{0, 1},
          <int>{},
        ]) {
          final SemanticsNode node = tester.getSemantics(
            find.bySemanticsLabel('Select all rows'),
          );
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
          );
          tester.binding.platformDispatcher.onSemanticsActionEvent!(
            SemanticsActionEvent(
              type: SemanticsAction.tap,
              nodeId: node.id,
              viewId: tester.view.viewId,
            ),
          );
          await tester.pumpAndSettle();
          expect(selected, expected);
          expect(
            tester.getSemantics(find.bySemanticsLabel('Select all rows')),
            isSemantics(
              isChecked: expected.isNotEmpty,
              isCheckStateMixed: false,
            ),
          );
        }
        expect(calls, 2);
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets('selectable table meets all accessibility guidelines', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(_table(CarbonTableSelection.multi, <int>{}, (_) {})),
      );
      await expectA11y(tester);
    } finally {
      handle.dispose();
    }
  });
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 520, child: child)),
  ),
);

CarbonDataTable _table(
  CarbonTableSelection selection,
  Set<int> selected,
  ValueChanged<Set<int>>? onChanged,
) => CarbonDataTable(
  columns: const <CarbonTableColumn>[CarbonTableColumn(title: 'Name')],
  rows: const <CarbonTableRow>[
    CarbonTableRow(cells: <Widget>[Text('First')]),
    CarbonTableRow(cells: <Widget>[Text('Second')]),
  ],
  selection: selection,
  selectedRows: selected,
  onSelectionChanged: onChanged,
);
