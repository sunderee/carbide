// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 400, child: child)),
  ),
);

/// The bare host has no WidgetsApp shortcut map, so real Tab traversal is
/// wired up locally (same pattern as the ui_shell header tests).
Widget _tabTraversal(Widget child) => Shortcuts(
  shortcuts: const <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{NextFocusIntent: NextFocusAction()},
    child: FocusScope(autofocus: true, child: child),
  ),
);

List<CarbonStructuredListRow> _rows() => const <CarbonStructuredListRow>[
  CarbonStructuredListRow(
    cells: <Widget>[Text('Load balancer'), Text('Routine')],
  ),
  CarbonStructuredListRow(cells: <Widget>[Text('Database'), Text('Default')]),
  CarbonStructuredListRow(cells: <Widget>[Text('Cache'), Text('Routine')]),
];

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('structure', () {
    testWidgets('renders headers and cells', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonStructuredList(
            headers: const <String>['Name', 'Type'],
            rows: _rows(),
          ),
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Load balancer'), findsOneWidget);
      expect(find.text('Database'), findsOneWidget);
      // The header uses the secondary label colour.
      expect(
        tester.widget<Text>(find.text('Name')).style!.color,
        theme.textSecondary,
      );
    });
  });

  group('selection', () {
    testWidgets('selecting a row reports its index and shows a checkmark', (
      WidgetTester tester,
    ) async {
      int? selected;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return CarbonStructuredList(
                headers: const <String>['Name', 'Type'],
                rows: _rows(),
                selectable: true,
                selectedIndex: selected,
                onSelected: (int i) => setState(() => selected = i),
              );
            },
          ),
        ),
      );
      expect(find.byType(CarbonIcon), findsNothing);
      await tester.tap(find.text('Database'));
      await tester.pump();
      expect(selected, 1);
      // A CheckmarkFilled marks the selected row.
      expect(
        tester
            .widgetList<CarbonIcon>(find.byType(CarbonIcon))
            .where((CarbonIcon i) => i.icon == CarbonIcons.checkmarkFilled)
            .length,
        1,
      );
    });

    testWidgets('non-selectable rows are not tappable radios', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonStructuredList(
            headers: const <String>['Name', 'Type'],
            rows: _rows(),
          ),
        ),
      );
      expect(find.byType(GestureDetector), findsNothing);
      handle.dispose();
    });
  });

  group('semantics', () {
    testWidgets('selectable rows are exclusive-group radios', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonStructuredList(
            headers: const <String>['Name', 'Type'],
            rows: _rows(),
            selectable: true,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(RegExp('Load balancer'))),
        isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
      );
      handle.dispose();
    });
  });

  group('keyboard and hover', () {
    Widget selectableList(ValueChanged<int> onSelected) => _host(
      CarbonStructuredList(
        headers: const <String>['Name', 'Type'],
        rows: _rows(),
        selectable: true,
        selectedIndex: 0,
        onSelected: onSelected,
      ),
    );

    Color rowColor(WidgetTester tester, String cellText) {
      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text(cellText),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      return deco.color!;
    }

    testWidgets('Enter and Space select the focused row', (
      WidgetTester tester,
    ) async {
      final List<int> selected = <int>[];
      await tester.pumpWidget(selectableList(selected.add));
      // Focus the first row, Enter selects it.
      Focus.of(tester.element(find.text('Load balancer'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, <int>[0]);
      // Focus the second row, Space selects it too.
      Focus.of(tester.element(find.text('Database'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, <int>[0, 1]);
    });

    testWidgets('hovering a selectable row shows the hover layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(selectableList((_) {}));
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('Database')));
      await tester.pump();
      expect(rowColor(tester, 'Database'), theme.layerHover01);

      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(rowColor(tester, 'Database'), const Color(0x00000000));
    });

    testWidgets('rows built at runtime render their cells', (
      WidgetTester tester,
    ) async {
      final List<CarbonStructuredListRow> rows = <CarbonStructuredListRow>[
        for (int i = 0; i < 2; i++)
          CarbonStructuredListRow(cells: <Widget>[Text('Cell $i')]),
      ];
      await tester.pumpWidget(
        _host(
          CarbonStructuredList(headers: const <String>['Name'], rows: rows),
        ),
      );
      expect(find.text('Cell 0'), findsOneWidget);
      expect(find.text('Cell 1'), findsOneWidget);
    });
  });

  group('keyboard reachability (#231)', () {
    // Upstream: documentation/carbon-website/src/pages/components/
    // structured-list/accessibility.mdx defers to the WAI-ARIA table
    // pattern and IBM requirements 2.1.1 Keyboard, 2.4.3 Focus Order and
    // 2.4.7 Focus Visible; the react implementation
    // (documentation/carbon/packages/react/src/components/StructuredList/
    // StructuredList.tsx) defines no arrow-key handling — selectable rows
    // are sequential Tab stops activated with Enter/Space.

    testWidgets('rows are sequential Tab stops with a visible focus ring; '
        'Space selects the reached row', (WidgetTester tester) async {
      final List<int> selected = <int>[];
      await tester.pumpWidget(
        _host(
          _tabTraversal(
            CarbonStructuredList(
              headers: const <String>['Name', 'Type'],
              rows: _rows(),
              selectable: true,
              selectedIndex: 0,
              onSelected: selected.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      CarbonFocusRing ringOf(String cell) => tester.widget<CarbonFocusRing>(
        find
            .ancestor(
              of: find.text(cell),
              matching: find.byType(CarbonFocusRing),
            )
            .first,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringOf('Load balancer').visible, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringOf('Database').visible, isTrue);
      expect(ringOf('Load balancer').visible, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, <int>[1]);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(ringOf('Cache').visible, isTrue);
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonStructuredList(
            headers: const <String>['Name', 'Type'],
            rows: _rows(),
            selectable: true,
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      );
      // Selectable rows span the list width at ≥50px (16px vertical cell
      // padding around the body line, `_structured-list.scss`), and each
      // row merges its cell text into one labelled radio node.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('selectable structured list across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'structured_list',
        containsText: true,
        size: const Size(420, 240),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 380,
            child: CarbonStructuredList(
              headers: const <String>['Name', 'Type'],
              rows: _rows(),
              selectable: true,
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      );
    });
  });
}
