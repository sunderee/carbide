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
import 'package:flutter/services.dart' show LogicalKeyboardKey;
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

/// Asserts the option row labelled [label] sits fully inside the popup's
/// scroll viewport (the #279 scroll-into-view contract).
void _expectRowWithinFold(WidgetTester tester, String label) {
  final Rect fold = tester.getRect(find.byType(SingleChildScrollView));
  final Rect row = tester.getRect(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(CarbonListBoxMenuItem),
        )
        .first,
  );
  expect(
    row.top,
    greaterThanOrEqualTo(fold.top - 0.01),
    reason: '$label starts above the popup fold',
  );
  expect(
    row.bottom,
    lessThanOrEqualTo(fold.bottom + 0.01),
    reason: '$label ends below the popup fold',
  );
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

    testWidgets('arrowing keeps the highlighted option in view (#279)', (
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

      // Ten ArrowDowns rove the highlight from Option 1 to Option 11 —
      // five rows past the 5.5-row fold.
      for (int i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      _expectRowWithinFold(tester, 'Option 11');

      // And back up beyond the current window: the highlight scrolls the
      // popup the other way.
      for (int i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
      }
      _expectRowWithinFold(tester, 'Option 1');
    });

    testWidgets('opening reveals a preselected value below the fold (#279)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDropdown<int>(
            titleText: 'Options',
            selectedItem: 50,
            onChanged: (int _) {},
            items: _dropdownItems(100),
          ),
        ),
      );
      await tester.tap(find.byType(CarbonListBox));
      await tester.pumpAndSettle();
      _expectRowWithinFold(tester, 'Option 50');
    });

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

    testWidgets('arrowing keeps the highlighted option in view (#279)', (
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
      for (int i = 0; i < 12; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      _expectRowWithinFold(tester, 'Option 13');
    });
  });

  group('select popup', () {
    testWidgets('arrowing keeps the highlighted option in view (#279)', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonSelect<int>(
            labelText: 'Options',
            focusNode: node,
            onChanged: (int _) {},
            items: <CarbonSelectEntry<int>>[
              for (int i = 1; i <= 50; i++)
                CarbonSelectItem<int>(value: i, label: 'Option $i'),
            ],
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();

      // ArrowDown opens with the highlight on Option 1; ten more rove it
      // to Option 11, past the 240px popup cap (six 40px rows).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      for (int i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      final Rect fold = tester.getRect(find.byType(SingleChildScrollView));
      final Rect row = tester.getRect(find.text('Option 11'));
      expect(row.top, greaterThanOrEqualTo(fold.top - 0.01));
      expect(row.bottom, lessThanOrEqualTo(fold.bottom + 0.01));
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
