// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

/// CarbonOverflowMenu needs an Overlay + TapRegionSurface + a hittable backdrop.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) => Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),
                Center(child: SizedBox(width: 520, child: child)),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('search', () {
    testWidgets('the expandable search reports the query as typed', (
      WidgetTester tester,
    ) async {
      String? query;
      await tester.pumpWidget(
        _host(CarbonTableToolbar(onSearchChanged: (String q) => query = q)),
      );
      // Expand the search, then type.
      await tester.tap(find.byType(CarbonExpandableSearch));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'load');
      await tester.pump();
      expect(query, 'load');
    });
  });

  group('overflow menu', () {
    testWidgets('the settings menu opens and runs an item', (
      WidgetTester tester,
    ) async {
      int ran = 0;
      await tester.pumpWidget(
        _host(
          CarbonTableToolbar(
            overflowItems: <Widget>[
              CarbonMenuItem(label: 'Settings', onPressed: () => ran++),
            ],
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Table settings'));
      await tester.pumpAndSettle();
      expect(find.byType(CarbonMenu), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(ran, 1);
    });
  });

  group('actions', () {
    testWidgets('action buttons render and fire', (WidgetTester tester) async {
      int added = 0;
      await tester.pumpWidget(
        _host(
          CarbonTableToolbar(
            actions: <Widget>[
              CarbonButton(label: 'Add', onPressed: () => added++),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Add'));
      expect(added, 1);
    });
  });

  group('traversal order (#226)', () {
    testWidgets('reads toolbar controls, then column headers, then the '
        'first row', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonTableToolbar(
                onSearchChanged: (_) {},
                overflowItems: <Widget>[
                  CarbonMenuItem(label: 'Settings', onPressed: () {}),
                ],
                actions: <Widget>[
                  CarbonButton(label: 'Add new', onPressed: () {}),
                ],
              ),
              const CarbonDataTable(
                columns: <CarbonTableColumn>[
                  CarbonTableColumn(title: 'Name'),
                  CarbonTableColumn(title: 'Status'),
                ],
                rows: <CarbonTableRow>[
                  CarbonTableRow(
                    cells: <Widget>[Text('Load'), Text('Running')],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      final List<String> labels = <String>[
        for (final SemanticsNode node
            in tester.semantics.simulatedAccessibilityTraversal())
          if (node.label.isNotEmpty) node.label,
      ];
      expect(
        labels,
        containsAllInOrder(<String>[
          'Expand search',
          'Table settings',
          'Add new',
          'Name',
          'Status',
          'Load',
        ]),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('toolbar with search, menu and action', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'table_toolbar',
        containsText: true,
        size: const Size(540, 80),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Center(
                child: SizedBox(
                  width: 520,
                  child: CarbonTableToolbar(
                    onSearchChanged: (_) {},
                    overflowItems: <Widget>[
                      CarbonMenuItem(label: 'Settings', onPressed: () {}),
                    ],
                    actions: <Widget>[
                      CarbonButton(label: 'Add new', onPressed: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  });
}
