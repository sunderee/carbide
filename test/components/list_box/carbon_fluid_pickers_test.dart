// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// The fluid treatment on the list-box pickers (#217): 64px fields with the
// title inside, 16px chevrons, and 64px menu rows unless condensed, per
// _fluid-list-box.scss.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: TapRegionSurface(
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) => Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 320, child: child),
            ),
          ),
        ],
      ),
    ),
  ),
);

CarbonDropdown<int> _dropdown({bool fluid = true, bool condensed = false}) =>
    CarbonDropdown<int>(
      titleText: 'Model',
      selectedItem: 1,
      fluid: fluid,
      condensed: condensed,
      onChanged: (_) {},
      items: const <CarbonDropdownItem<int>>[
        CarbonDropdownItem<int>(value: 1, label: 'Suggested'),
        CarbonDropdownItem<int>(value: 2, label: 'Manual'),
      ],
    );

void main() {
  group('fluid fields (_fluid-list-box.scss)', () {
    testWidgets('the fluid dropdown is 64px with its title inside', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_dropdown()));
      expect(tester.getSize(find.byType(CarbonListBox)).height, 64);
      // The title renders inside the field, not as an external label.
      expect(find.byType(CarbonFormLabel), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CarbonListBox),
          matching: find.text('Model'),
        ),
        findsOneWidget,
      );
      // The chevron shrinks to the 16px fluid box.
      expect(
        tester.getSize(find.byType(CarbonListBoxMenuIcon)),
        const Size(16, 16),
      );
    });

    // Overlay.initialEntries is honored only on first build, so each
    // variant pumps in its own test.
    testWidgets('fluid menu rows are 64px', (WidgetTester tester) async {
      await tester.pumpWidget(_host(_dropdown()));
      await tester.tap(find.byType(CarbonListBox));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(CarbonListBoxMenuItem).first).height,
        64,
      );
    });

    testWidgets('condensed keeps the standard row height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_dropdown(condensed: true)));
      await tester.tap(find.byType(CarbonListBox));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(CarbonListBoxMenuItem).first).height,
        CarbonFieldSize.md.height,
      );
    });

    testWidgets('fluid multi-select is 64px with its title inside', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMultiSelect<int>(
            titleText: 'Filters',
            label: 'Choose',
            fluid: true,
            selectedValues: const <int>{},
            onChanged: (_) {},
            items: const <CarbonMultiSelectItem<int>>[
              CarbonMultiSelectItem<int>(value: 1, label: 'One'),
            ],
          ),
        ),
      );
      expect(tester.getSize(find.byType(CarbonListBox)).height, 64);
      expect(find.byType(CarbonFormLabel), findsNothing);
    });

    testWidgets('fluid combo box is 64px with its title inside', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonComboBox<int>(
            titleText: 'Country',
            fluid: true,
            onChanged: (_) {},
            items: const <CarbonComboBoxItem<int>>[
              CarbonComboBoxItem<int>(value: 1, label: 'Estonia'),
            ],
          ),
        ),
      );
      expect(find.byType(CarbonFormLabel), findsNothing);
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(CarbonComboBox<int>),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .height,
        64,
      );
      expect(find.text('Country'), findsOneWidget);
    });
  });

  group('goldens', () {
    testWidgets('fluid pickers across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'fluid_pickers',
        containsText: true,
        size: const Size(360, 260),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _dropdown(),
                const SizedBox(height: 16),
                CarbonComboBox<int>(
                  titleText: 'Country',
                  fluid: true,
                  onChanged: (_) {},
                  items: const <CarbonComboBoxItem<int>>[
                    CarbonComboBoxItem<int>(value: 1, label: 'Estonia'),
                  ],
                ),
                const SizedBox(height: 16),
                CarbonMultiSelect<int>(
                  titleText: 'Filters',
                  label: 'Choose filters',
                  fluid: true,
                  selectedValues: const <int>{1},
                  onChanged: (_) {},
                  items: const <CarbonMultiSelectItem<int>>[
                    CarbonMultiSelectItem<int>(value: 1, label: 'One'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}
