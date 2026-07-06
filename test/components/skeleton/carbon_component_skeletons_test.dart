// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart'
    show SemanticsAction, SemanticsData, SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 600, child: child),
    ),
  ),
);

void main() {
  final Map<String, Widget> all = <String, Widget>{
    'text input': const CarbonTextInputSkeleton(),
    'text area': const CarbonTextAreaSkeleton(),
    'number input': const CarbonNumberInputSkeleton(),
    'select': const CarbonSelectSkeleton(),
    'dropdown': const CarbonDropdownSkeleton(),
    'date picker': const CarbonDatePickerSkeleton(),
    'search': const CarbonSearchSkeleton(),
    'checkbox': const CarbonCheckboxSkeleton(),
    'radio': const CarbonRadioButtonSkeleton(),
    'toggle': const CarbonToggleSkeleton(),
    'slider': const CarbonSliderSkeleton(),
    'file uploader': const CarbonFileUploaderSkeleton(),
    'tabs': const CarbonTabsSkeleton(),
    'breadcrumb': const CarbonBreadcrumbSkeleton(),
    'pagination': const CarbonPaginationSkeleton(),
    'progress indicator': const CarbonProgressIndicatorSkeleton(),
    'accordion': const CarbonAccordionSkeleton(),
    'structured list': const CarbonStructuredListSkeleton(),
    'data table': const CarbonDataTableSkeleton(),
  };

  group('renders', () {
    all.forEach((String name, Widget widget) {
      testWidgets('$name skeleton renders shimmer shapes', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(_host(widget));
        expect(tester.takeException(), isNull);
        expect(find.byType(CarbonSkeleton), findsWidgets);
      });
    });
  });

  group('geometry', () {
    testWidgets('a field skeleton has a label bar and a 40px field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonTextInputSkeleton()));
      expect(find.byType(CarbonSkeleton), findsNWidgets(2));
      // The field bar is 40px tall.
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CarbonSkeleton && w.height == 40,
        ),
        findsOneWidget,
      );
    });

    testWidgets('a text area skeleton field is 100px tall', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonTextAreaSkeleton()));
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CarbonSkeleton && w.height == 100,
        ),
        findsOneWidget,
      );
    });

    testWidgets('hideLabel drops the label bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonTextInputSkeleton(hideLabel: true)),
      );
      expect(find.byType(CarbonSkeleton), findsOneWidget);
    });

    testWidgets('a data table skeleton fills header + body cells', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonDataTableSkeleton(rowCount: 3, columnCount: 4)),
      );
      // header (4) + 3 rows × 4 columns = 16 cells.
      expect(find.byType(CarbonSkeleton), findsNWidgets(16));
    });
  });

  group('variants', () {
    testWidgets('fluid fields are a single 64px block with the label inside', (
      WidgetTester tester,
    ) async {
      final List<Widget> fluids = <Widget>[
        CarbonTextInputSkeleton(fluid: true, key: UniqueKey()),
        CarbonSelectSkeleton(fluid: true, key: UniqueKey()),
        CarbonDropdownSkeleton(fluid: true, key: UniqueKey()),
      ];
      for (final Widget widget in fluids) {
        await tester.pumpWidget(_host(widget));
        expect(
          tester.getSize(find.byKey(widget.key!)).height,
          64,
          reason: '${widget.runtimeType}',
        );
        // Label bar + value bar, both inside the field block.
        expect(find.byType(CarbonSkeleton), findsNWidgets(2));
      }
    });

    testWidgets('hideLabel drops the label bar on every labelled field', (
      WidgetTester tester,
    ) async {
      final List<Widget> fields = <Widget>[
        CarbonTextAreaSkeleton(hideLabel: true, key: UniqueKey()),
        CarbonNumberInputSkeleton(hideLabel: true, key: UniqueKey()),
        CarbonSelectSkeleton(hideLabel: true, key: UniqueKey()),
        CarbonDropdownSkeleton(hideLabel: true, key: UniqueKey()),
        CarbonDatePickerSkeleton(hideLabel: true, key: UniqueKey()),
      ];
      for (final Widget widget in fields) {
        await tester.pumpWidget(_host(widget));
        expect(
          find.byType(CarbonSkeleton),
          findsOneWidget,
          reason: '${widget.runtimeType}',
        );
      }
    });

    testWidgets('count controls the number of repeated placeholders', (
      WidgetTester tester,
    ) async {
      for (final int count in <int>[1, 3]) {
        await tester.pumpWidget(_host(CarbonTabsSkeleton(count: count)));
        expect(find.byType(CarbonSkeleton), findsNWidgets(count));

        await tester.pumpWidget(_host(CarbonBreadcrumbSkeleton(count: count)));
        expect(find.byType(CarbonSkeleton), findsNWidgets(count));

        // count step circles joined by count - 1 connector lines.
        await tester.pumpWidget(
          _host(CarbonProgressIndicatorSkeleton(count: count)),
        );
        expect(find.byType(CarbonSkeleton), findsNWidgets(2 * count - 1));

        // One title bar + one chevron placeholder per item.
        await tester.pumpWidget(_host(CarbonAccordionSkeleton(count: count)));
        expect(find.byType(CarbonSkeleton), findsNWidgets(2 * count));
      }
    });

    testWidgets('grid skeletons honour row and column counts', (
      WidgetTester tester,
    ) async {
      for (final (int rows, int columns) in <(int, int)>[(2, 3), (1, 5)]) {
        await tester.pumpWidget(
          _host(
            CarbonStructuredListSkeleton(rowCount: rows, columnCount: columns),
          ),
        );
        expect(find.byType(CarbonSkeleton), findsNWidgets(rows * columns));

        // The data table adds one header row.
        await tester.pumpWidget(
          _host(CarbonDataTableSkeleton(rowCount: rows, columnCount: columns)),
        );
        expect(
          find.byType(CarbonSkeleton),
          findsNWidgets((rows + 1) * columns),
        );
      }
    });

    testWidgets('fixed-shape skeletons render their spec shape counts', (
      WidgetTester tester,
    ) async {
      final Map<Widget, int> shapeCounts = <Widget, int>{
        CarbonSearchSkeleton(key: UniqueKey()): 1,
        CarbonPaginationSkeleton(key: UniqueKey()): 1,
        CarbonCheckboxSkeleton(key: UniqueKey()): 2,
        CarbonRadioButtonSkeleton(key: UniqueKey()): 2,
        CarbonToggleSkeleton(key: UniqueKey()): 2,
        CarbonFileUploaderSkeleton(key: UniqueKey()): 2,
        CarbonSliderSkeleton(key: UniqueKey()): 3,
      };
      for (final MapEntry<Widget, int> entry in shapeCounts.entries) {
        await tester.pumpWidget(_host(entry.key));
        expect(
          find.byType(CarbonSkeleton),
          findsNWidgets(entry.value),
          reason: '${entry.key.runtimeType}',
        );
      }
    });
  });

  group('semantics (#226)', () {
    testWidgets('skeletons are hidden from assistive technology', (
      WidgetTester tester,
    ) async {
      // Loading placeholders are decorative; none of them may leak a
      // label or an action into the semantics tree.
      final SemanticsHandle handle = tester.ensureSemantics();
      for (final MapEntry<String, Widget> entry in all.entries) {
        await tester.pumpWidget(_host(entry.value));
        final Iterable<SemanticsNode> leaked = tester.semantics
            .simulatedAccessibilityTraversal()
            .where((SemanticsNode node) {
              final SemanticsData data = node.getSemanticsData();
              return data.label.isNotEmpty ||
                  data.hasAction(SemanticsAction.tap) ||
                  data.hasAction(SemanticsAction.longPress);
            });
        expect(leaked, isEmpty, reason: '${entry.key} skeleton');
      }
      handle.dispose();
    });
  });

  group('goldens', () {
    Widget stack(double width, List<Widget> rows) => Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final Widget r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(width: width, child: r),
            ),
        ],
      ),
    );

    testWidgets('form skeletons', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'skeleton_form',
        size: const Size(280, 320),
        builder: (BuildContext context) => stack(240, const <Widget>[
          CarbonTextInputSkeleton(),
          CarbonCheckboxSkeleton(),
          CarbonToggleSkeleton(),
          CarbonSliderSkeleton(),
        ]),
      );
    });

    testWidgets('structural skeletons', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'skeleton_structural',
        size: const Size(360, 360),
        builder: (BuildContext context) => stack(320, const <Widget>[
          CarbonTabsSkeleton(count: 3),
          CarbonAccordionSkeleton(count: 3),
          CarbonDataTableSkeleton(rowCount: 3, columnCount: 3),
        ]),
      );
    });
  });
}
