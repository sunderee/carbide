// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// CarbonFluidForm (#217): the inherited scope that opts every fluid-capable
// descendant into the fluid treatment (upstream FluidForm), the fluid time
// picker, and the fluid field skeletons.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/overlay_entries.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: TapRegionSurface(
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
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

void main() {
  group('CarbonFluidForm scope', () {
    testWidgets('descendant fields render fluid without their own flag', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonFluidForm(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CarbonTextInput(labelText: 'Name'),
                const SizedBox(height: 16),
                CarbonDropdown<int>(
                  titleText: 'Team',
                  selectedItem: 1,
                  onChanged: (_) {},
                  items: const <CarbonDropdownItem<int>>[
                    CarbonDropdownItem<int>(value: 1, label: 'Core'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      // Fluid moves both labels inside their fields.
      expect(find.byType(CarbonFormLabel), findsNothing);
      // The dropdown's list box takes the 64px fluid height.
      expect(tester.getSize(find.byType(CarbonListBox)).height, 64);
      // The text input renders its fluid treatment (label inside).
      expect(
        find.descendant(
          of: find.byType(CarbonTextInput),
          matching: find.text('Name'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('fields outside the scope stay non-fluid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonTextInput(labelText: 'Name')));
      expect(find.byType(CarbonFormLabel), findsOneWidget);
    });
  });

  group('fluid time picker (_fluid-time-picker.scss)', () {
    testWidgets('the field is 64px with its label inside', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTimePicker(
            labelText: 'Start time',
            initialValue: '09:30',
            fluid: true,
          ),
        ),
      );
      expect(find.byType(CarbonFormLabel), findsNothing);
      expect(
        find.descendant(
          of: find.byType(CarbonTimePicker),
          matching: find.text('Start time'),
        ),
        findsOneWidget,
      );
      // The fluid time field box is 64px tall.
      final Finder box = find
          .descendant(
            of: find.byType(CarbonTimePicker),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(tester.getSize(box).height, 64);
    });
  });

  group('fluid skeletons', () {
    // Overlay.initialEntries is honored only on first build: one pump each.
    testWidgets('the text-input skeleton renders the 64px fluid box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonTextInputSkeleton(fluid: true)),
      );
      expect(tester.getSize(find.byType(CarbonTextInputSkeleton)).height, 64);
    });

    testWidgets('the dropdown skeleton renders the 64px fluid box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonDropdownSkeleton(fluid: true)));
      expect(tester.getSize(find.byType(CarbonDropdownSkeleton)).height, 64);
    });
  });

  group('goldens', () {
    testWidgets('a fluid form across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'fluid_form',
        containsText: true,
        size: const Size(360, 300),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 320,
            child: CarbonFluidForm(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const CarbonTextInput(
                    labelText: 'Name',
                    initialValue: 'Ada Lovelace',
                  ),
                  const SizedBox(height: 16),
                  CarbonDropdown<int>(
                    titleText: 'Team',
                    selectedItem: 1,
                    onChanged: (_) {},
                    items: const <CarbonDropdownItem<int>>[
                      CarbonDropdownItem<int>(value: 1, label: 'Core'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const CarbonTextInputSkeleton(fluid: true),
                ],
              ),
            ),
          ),
        ),
      );
    });
  });
}
