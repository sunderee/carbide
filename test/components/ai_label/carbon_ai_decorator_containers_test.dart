// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// The AI decorator surface on container components (#216, part 3):
// checkbox/radio legends, tags, tiles, and the data table, per the
// per-component `--decorator` selectors.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child, {double width = 360}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

Widget _aiLabel() => const CarbonAILabel(size: CarbonAILabelSize.mini);

void main() {
  group('legend decorators (_checkbox.scss / _radio-button.scss)', () {
    testWidgets('checkbox group renders the label 8px after the legend', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonCheckboxGroup(
            legend: 'Suggestions',
            aiLabel: _aiLabel(),
            children: <Widget>[
              CarbonCheckbox(label: 'One', value: false, onChanged: (_) {}),
            ],
          ),
        ),
      );
      final Rect legend = tester.getRect(find.text('Suggestions'));
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      expect(label.left - legend.right, 8);
    });

    testWidgets('a single checkbox renders the label after its text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonCheckbox(
            label: 'Enable',
            value: true,
            onChanged: (_) {},
            aiLabel: _aiLabel(),
          ),
        ),
      );
      final Rect text = tester.getRect(find.text('Enable'));
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      expect(label.left - text.right, 8);
    });

    testWidgets('radio group renders the label after the legend', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonRadioButtonGroup<int>(
            legend: 'Model',
            value: 1,
            aiLabel: _aiLabel(),
            onChanged: (_) {},
            options: const <(int, String)>[(1, 'One')],
          ),
        ),
      );
      final Rect legend = tester.getRect(find.text('Model'));
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      expect(label.left - legend.right, 8);
    });
  });

  group('tag and tiles (_tag.scss / _tile.scss)', () {
    testWidgets('tag renders the label after its text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.centerLeft,
            child: CarbonTag(label: 'Generated', aiLabel: _aiLabel()),
          ),
        ),
      );
      final Rect text = tester.getRect(find.text('Generated'));
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      expect(label.left, greaterThan(text.right));
    });

    testWidgets('tiles anchor the label at the top end (16/16)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonTile(aiLabel: _aiLabel(), child: const Text('Content'))),
      );
      final Rect tile = tester.getRect(find.byType(CarbonTile));
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      expect(label.top - tile.top, 16);
      expect(tile.right - label.right, 16);
    });

    testWidgets('clickable and expandable tiles host the label too', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonClickableTile(
            onPressed: () {},
            aiLabel: _aiLabel(),
            child: const Text('Content'),
          ),
        ),
      );
      expect(find.byType(CarbonAILabel), findsOneWidget);

      await tester.pumpWidget(
        _host(
          CarbonExpandableTile(
            aiLabel: _aiLabel(),
            expanded: false,
            aboveTheFold: const Text('Above'),
            belowTheFold: const Text('Below'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CarbonAILabel), findsOneWidget);
    });
  });

  group('data table (ai-label-with-* stories)', () {
    testWidgets('table title and column headers host labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            title: 'Models',
            aiLabel: _aiLabel(),
            columns: <CarbonTableColumn>[
              CarbonTableColumn(title: 'Score', aiLabel: _aiLabel()),
              const CarbonTableColumn(title: 'Name'),
            ],
            rows: const <CarbonTableRow>[
              CarbonTableRow(cells: <Widget>[Text('98'), Text('A')]),
            ],
          ),
          width: 480,
        ),
      );
      expect(find.byType(CarbonAILabel), findsNWidgets(2));
      // The title-level label sits beside the title text.
      final Rect title = tester.getRect(find.text('Models'));
      final Rect titleLabel = tester.getRect(find.byType(CarbonAILabel).first);
      expect(titleLabel.left - title.right, 8);
      // The column label follows its header text.
      final Rect header = tester.getRect(find.text('Score'));
      final Rect columnLabel = tester.getRect(find.byType(CarbonAILabel).last);
      expect(columnLabel.left, greaterThan(header.right));
    });
  });

  group('goldens', () {
    testWidgets('AI containers across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'ai_containers',
        containsText: true,
        size: const Size(400, 300),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CarbonCheckboxGroup(
                  legend: 'Suggestions',
                  aiLabel: _aiLabel(),
                  children: <Widget>[
                    CarbonCheckbox(
                      label: 'Enable',
                      value: true,
                      onChanged: (_) {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CarbonTag(label: 'Generated', aiLabel: _aiLabel()),
                const SizedBox(height: 16),
                SizedBox(
                  width: 360,
                  child: CarbonTile(
                    aiLabel: _aiLabel(),
                    child: const Text('Tile content'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}
