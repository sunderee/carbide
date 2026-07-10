// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// DPR canaries (#236): the hairline-heavy primitives rendered through a
// 1.5x scale, the way a fractional-DPR display rasterizes them. Carbon
// leans on 1px borders and 2px focus strokes everywhere — exactly the
// geometry that shimmers or doubles at fractional scales, and exactly
// what a 1.0-DPR golden can never catch. Six scenes, strict-bounded
// (0.05%), instead of multiplying the whole golden matrix by a DPR axis.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  testWidgets('checkbox hairlines at 1.5x DPR', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'dpr15_checkbox',
      strict: true,
      containsText: true,
      devicePixelRatio: 1.5,
      size: const Size(180, 60),
      builder: (BuildContext context) =>
          const Center(child: CarbonCheckbox(label: 'Option', value: false)),
    );
  });

  testWidgets('radio ring at 1.5x DPR', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'dpr15_radio',
      strict: true,
      containsText: true,
      devicePixelRatio: 1.5,
      size: const Size(180, 60),
      builder: (BuildContext context) => Center(
        child: CarbonRadioButton(
          label: 'Option',
          selected: true,
          onSelected: () {},
        ),
      ),
    );
  });

  testWidgets('text input border at 1.5x DPR', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'dpr15_text_input',
      strict: true,
      containsText: true,
      devicePixelRatio: 1.5,
      size: const Size(260, 100),
      builder: (BuildContext context) => const Center(
        child: SizedBox(
          width: 220,
          child: CarbonTextInput(labelText: 'Label', placeholder: 'Value'),
        ),
      ),
    );
  });

  testWidgets('focus ring stroke at 1.5x DPR', (WidgetTester tester) async {
    // One node per theme variant; each pump builds a fresh host.
    final List<FocusNode> nodes = <FocusNode>[];
    addTearDown(() {
      for (final FocusNode node in nodes) {
        node.dispose();
      }
    });
    FocusNode nextNode() {
      final FocusNode node = FocusNode();
      nodes.add(node);
      return node;
    }

    await expectThemeGoldens(
      tester,
      name: 'dpr15_focus_ring',
      strict: true,
      containsText: true,
      devicePixelRatio: 1.5,
      size: const Size(220, 70),
      afterPump: (WidgetTester tester) async {
        tester
            .widget<CarbonButton>(find.byType(CarbonButton))
            .focusNode!
            .requestFocus();
        await tester.pumpAndSettle();
      },
      builder: (BuildContext context) => Center(
        child: IntrinsicWidth(
          child: CarbonButton(
            label: 'Focused',
            focusNode: nextNode(),
            onPressed: () {},
          ),
        ),
      ),
    );
  });

  testWidgets('data table row dividers at 1.5x DPR', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'dpr15_table_dividers',
      strict: true,
      containsText: true,
      devicePixelRatio: 1.5,
      size: const Size(300, 160),
      builder: (BuildContext context) => const CarbonDataTable(
        size: CarbonTableSize.sm,
        columns: <CarbonTableColumn>[
          CarbonTableColumn(title: 'Name'),
          CarbonTableColumn(title: 'Role'),
        ],
        rows: <CarbonTableRow>[
          CarbonTableRow(cells: <Widget>[Text('Ada'), Text('Admin')]),
          CarbonTableRow(cells: <Widget>[Text('Grace'), Text('Editor')]),
          CarbonTableRow(cells: <Widget>[Text('Mary'), Text('Viewer')]),
        ],
      ),
    );
  });

  testWidgets('tag outline at 1.5x DPR', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'dpr15_tag_outline',
      strict: true,
      containsText: true,
      devicePixelRatio: 1.5,
      size: const Size(200, 50),
      builder: (BuildContext context) => Center(
        child: CarbonOperationalTag(label: 'Filter', onPressed: () {}),
      ),
    );
  });
}
