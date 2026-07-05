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

/// OverlayPortal needs an Overlay ancestor; TapRegion needs a surface.
Widget _overlayHost(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) =>
                Center(child: SizedBox(width: 360, child: child)),
          ),
        ],
      ),
    ),
  ),
);

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

    testWidgets('selectable tile anchors the label beside the checkmark slot '
        '(16/40)', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonSelectableTile(
            selected: true,
            onChanged: (_) {},
            aiLabel: _aiLabel(),
            child: const Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // CSS insets measure from the padding box, inside the selection
      // border, so outer-edge distances carry the 1px border.
      final Rect tile = tester.getRect(find.byType(CarbonSelectableTile));
      final Rect label = tester.getRect(find.byType(CarbonAILabel));
      expect(label.top - tile.top, 17);
      expect(tile.right - label.right, 41);
      // The checkmark keeps its own 16px corner slot.
      final Rect checkmark = tester.getRect(find.byType(CarbonIcon));
      expect(tile.right - checkmark.right, 17);
    });

    testWidgets('radio tile label rests in the corner and slides inward when '
        'selected (fast-02)', (WidgetTester tester) async {
      bool selected = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                CarbonRadioTile(
                  selected: selected,
                  onSelected: () => setState(() => selected = true),
                  aiLabel: _aiLabel(),
                  child: const Text('Content'),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Outer-edge distances carry the 1px selection border.
      final Rect tile = tester.getRect(find.byType(CarbonRadioTile));
      Rect label() => tester.getRect(find.byType(CarbonAILabel));
      expect(label().top - tile.top, 17);
      expect(tile.right - label().right, 17);

      final AnimatedPositionedDirectional positioned = tester
          .widget<AnimatedPositionedDirectional>(
            find.byType(AnimatedPositionedDirectional),
          );
      expect(positioned.duration, CarbonDuration.fast02);
      expect(positioned.curve, CarbonEasing.standardProductive);

      await tester.tap(find.text('Content'));
      await tester.pumpAndSettle();
      expect(tile.right - label().right, 41);
    });

    testWidgets('disabled selectable and radio tiles keep the label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonSelectableTile(
                selected: true,
                aiLabel: _aiLabel(),
                child: const Text('S'),
              ),
              CarbonRadioTile(
                selected: true,
                aiLabel: _aiLabel(),
                child: const Text('R'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CarbonAILabel), findsNWidgets(2));
    });

    testWidgets('tapping the label does not toggle the selectable tile', (
      WidgetTester tester,
    ) async {
      bool? changed;
      await tester.pumpWidget(
        _overlayHost(
          CarbonSelectableTile(
            selected: false,
            onChanged: (bool v) => changed = v,
            aiLabel: const CarbonAILabel(
              size: CarbonAILabelSize.mini,
              content: Text('Generated by AI'),
            ),
            child: const Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CarbonAILabel));
      await tester.pumpAndSettle();
      expect(changed, isNull);
      // The label's own callout opened instead.
      expect(find.text('Generated by AI'), findsOneWidget);
    });

    testWidgets('checked semantics survive the decorator', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonRadioTile(
            selected: true,
            onSelected: () {},
            aiLabel: _aiLabel(),
            child: const Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Content')),
        isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
      );
      handle.dispose();
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

    testWidgets('AI tiles across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'ai_tiles',
        containsText: true,
        size: const Size(300, 320),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonSelectableTile(
                  selected: true,
                  onChanged: (_) {},
                  aiLabel: _aiLabel(),
                  child: const Text('Selected'),
                ),
                const SizedBox(height: 8),
                CarbonSelectableTile(
                  selected: false,
                  onChanged: (_) {},
                  aiLabel: _aiLabel(),
                  child: const Text('Unselected'),
                ),
                const SizedBox(height: 8),
                CarbonRadioTile(
                  selected: true,
                  onSelected: () {},
                  aiLabel: _aiLabel(),
                  child: const Text('Radio selected'),
                ),
                const SizedBox(height: 8),
                CarbonRadioTile(
                  selected: false,
                  onSelected: () {},
                  aiLabel: _aiLabel(),
                  child: const Text('Radio unselected'),
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}
