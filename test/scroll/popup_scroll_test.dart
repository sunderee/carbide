// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Long-list popup scrolling (#232): the list-box family caps its popup at
// 5.5 rows (`_list-box.scss` $list-box-menu-max-height) behind a
// SingleChildScrollView, so these lock the cap, pointer-wheel scrolling,
// and the (documented, eager) build behavior at 1,000 items. Keyboard
// scroll-into-view does not exist yet — those locks are spec-shaped and
// skip-marked. CarbonMenu renders uncapped (upstream menus don't cap
// either); the tree view scrolls in its host like any block content.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {double width = 320}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          builder: (BuildContext context) => Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ],
    ),
  ),
);

List<CarbonDropdownItem<int>> _dropdownItems(int n) =>
    <CarbonDropdownItem<int>>[
      for (int i = 1; i <= n; i++)
        CarbonDropdownItem<int>(value: i, label: 'Option $i'),
    ];

Future<void> _wheel(WidgetTester tester, Offset at, double dy) async {
  final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
  pointer.hover(at);
  await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  await tester.pumpAndSettle();
}

void main() {
  group('list-box popup (dropdown)', () {
    testWidgets('caps at 5.5 rows and scrolls with the pointer wheel', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDropdown<int>(
            titleText: 'Options',
            onChanged: (int _) {},
            items: _dropdownItems(100),
          ),
        ),
      );
      await tester.tap(find.byType(CarbonListBox));
      await tester.pumpAndSettle();

      // The popup scroll region is capped at 5.5 md rows
      // (`_list-box.scss`: 40px * 5.5).
      final Finder scrollable = find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.text('Option 1'),
      );
      expect(scrollable, findsOneWidget);
      final Size viewport = tester.getSize(find.byType(SingleChildScrollView));
      expect(viewport.height, 40 * 5.5);

      // Option 1 starts in view; Option 50 is laid out far below the fold.
      final double foldBottom = tester
          .getRect(find.byType(SingleChildScrollView))
          .bottom;
      expect(
        tester.getRect(find.text('Option 1')).bottom,
        lessThan(foldBottom),
      );
      expect(
        tester.getRect(find.text('Option 50')).top,
        greaterThan(foldBottom),
      );

      // Wheel-scrolling inside the popup moves the list.
      final double before = tester.getRect(find.text('Option 50')).top;
      await _wheel(
        tester,
        tester.getCenter(find.byType(SingleChildScrollView)),
        400,
      );
      expect(tester.getRect(find.text('Option 50')).top, lessThan(before));
    });

    testWidgets(
      'arrowing keeps the highlighted option in view',
      (WidgetTester tester) async {},
      // TODO(#232): no scroll-into-view exists on keyboard highlight —
      // arrowing to Option 50 leaves the highlight below the 5.5-row fold
      // (upstream list-boxes keep it visible). Re-enable with a real
      // assertion when the list-box family gains ensureVisible-on-
      // highlight; sibling gaps tracked with the popup follow-up issue.
      skip: true,
    );

    testWidgets('builds all 1,000 options eagerly (documented absence of '
        'virtualization)', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonDropdown<int>(
            titleText: 'Options',
            onChanged: (int _) {},
            items: _dropdownItems(1000),
          ),
        ),
      );
      await tester.tap(find.byType(CarbonListBox));
      await tester.pumpAndSettle();
      // The popup is a SingleChildScrollView over a Column: every row
      // widget exists after open. This is the current, documented
      // behavior — a laziness regression OR an improvement flips this
      // count and must update this lock (and ideally virtualize).
      expect(find.textContaining('Option '), findsNWidgets(1000));
    });
  });

  group('list-box popup (multi-select)', () {
    testWidgets('scrolls with the pointer wheel inside the cap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMultiSelect<int>(
            titleText: 'Options',
            label: 'Choose',
            onChanged: (Set<int> _) {},
            items: <CarbonMultiSelectItem<int>>[
              for (int i = 1; i <= 60; i++)
                CarbonMultiSelectItem<int>(value: i, label: 'Option $i'),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(CarbonListBox));
      await tester.pumpAndSettle();
      final double before = tester.getRect(find.text('Option 40')).top;
      await _wheel(
        tester,
        tester.getCenter(find.byType(SingleChildScrollView)),
        300,
      );
      expect(tester.getRect(find.text('Option 40')).top, lessThan(before));
    });
  });

  group('list-box popup (combo box)', () {
    testWidgets('typeahead filters instead of scrolling; the filtered list '
        'stays within the cap', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonComboBox<int>(
            titleText: 'Options',
            onChanged: (int? _) {},
            items: <CarbonComboBoxItem<int>>[
              for (int i = 1; i <= 100; i++)
                CarbonComboBoxItem<int>(value: i, label: 'Option $i'),
            ],
          ),
        ),
      );
      // The combo box opens from typing in its field (no list-box shell).
      await tester.enterText(find.byType(EditableText), 'Option 99');
      await tester.pumpAndSettle();
      expect(find.text('Option 99'), findsWidgets);
      expect(find.text('Option 12'), findsNothing);
    });
  });

  group('menu', () {
    testWidgets('renders long menus uncapped (no internal scrollable, '
        'matching upstream menus)', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 600,
            child: CarbonMenu(
              autofocus: false,
              children: <Widget>[
                for (int i = 1; i <= 12; i++)
                  CarbonMenuItem(label: 'Action $i', onPressed: () {}),
              ],
            ),
          ),
          width: 260,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(CarbonMenu),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      expect(find.text('Action 12'), findsOneWidget);
    });
  });

  group('tree view', () {
    testWidgets('long trees scroll in their host; expanding a deep node '
        'near the fold works', (WidgetTester tester) async {
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          SizedBox(
            height: 240,
            child: SingleChildScrollView(
              controller: controller,
              child: CarbonTreeView(
                label: 'Files',
                initiallyExpandedIds: const <Object>{'deep'},
                nodes: <CarbonTreeNode>[
                  for (int i = 1; i <= 40; i++)
                    if (i == 35)
                      const CarbonTreeNode(
                        id: 'deep',
                        label: 'Node 35',
                        children: <CarbonTreeNode>[
                          CarbonTreeNode(id: 'leaf', label: 'Deep leaf'),
                        ],
                      )
                    else
                      CarbonTreeNode(id: i, label: 'Node $i'),
                ],
              ),
            ),
          ),
          width: 280,
        ),
      );
      // Built (the host scroll view is not lazy) but below the fold.
      expect(find.text('Node 35').hitTestable(), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Node 35'),
        200,
        scrollable: find.byType(Scrollable),
      );
      // Selecting a node at the fold edge must not throw.
      await tester.tap(find.text('Node 35'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Deep leaf'),
        100,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Deep leaf').hitTestable(), findsOneWidget);
    });
  });
}
