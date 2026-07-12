// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 520, child: child)),
  ),
);

const List<CarbonTableColumn> _columns = <CarbonTableColumn>[
  CarbonTableColumn(title: 'Name'),
  CarbonTableColumn(title: 'Status'),
];

List<CarbonTableRow> _rows() => const <CarbonTableRow>[
  CarbonTableRow(
    cells: <Widget>[Text('Load'), Text('Running')],
    expandedContent: Text('Load balancer details'),
  ),
  CarbonTableRow(
    cells: <Widget>[Text('Store'), Text('Stopped')],
    expandedContent: Text('Object store details'),
  ),
];

double _detailFactor(WidgetTester tester, String detail) => tester
    .widget<Align>(
      find.ancestor(of: find.text(detail), matching: find.byType(Align)).first,
    )
    .heightFactor!;

/// A controlled expandable table.
class _Expandable extends StatefulWidget {
  const _Expandable();
  @override
  State<_Expandable> createState() => _ExpandableState();
}

class _ExpandableState extends State<_Expandable> {
  Set<int> _expanded = <int>{};
  @override
  Widget build(BuildContext context) => CarbonDataTable(
    columns: _columns,
    rows: _rows(),
    expandable: true,
    expandedRows: _expanded,
    onExpandedChanged: (Set<int> s) => setState(() => _expanded = s),
  );
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('motion', () {
    testWidgets('expansion tokens match _data-table-expandable.scss', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const _Expandable()));
      // `__expand__svg`: transform $duration-moderate-01
      // motion(standard, productive).
      final AnimatedRotation chevron = tester.widget(
        find.byType(AnimatedRotation).first,
      );
      expect(chevron.duration, CarbonDuration.moderate01);
      expect(chevron.curve, CarbonEasing.standardProductive);
      // `tr[data-child-row]`: height $duration-moderate-01
      // motion(standard, productive).
      final TweenAnimationBuilder<double> detail = tester.widget(
        find.byType(TweenAnimationBuilder<double>).first,
      );
      expect(detail.duration, CarbonDuration.moderate01);
      expect(detail.curve, CarbonEasing.standardProductive);
    });

    testWidgets('reduced motion expands instantly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: _Expandable(),
          ),
        ),
      );
      expect(
        tester
            .widget<AnimatedRotation>(find.byType(AnimatedRotation).first)
            .duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>).first,
            )
            .duration,
        Duration.zero,
      );
      // The detail row is fully revealed on the next frame.
      await tester.tap(find.bySemanticsLabel('Expand row 1'));
      await tester.pump();
      await tester.pump();
      expect(_detailFactor(tester, 'Load balancer details'), 1);
    });
  });

  group('expansion', () {
    testWidgets('a chevron expands and collapses a row detail', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const _Expandable()));
      await tester.pumpAndSettle();
      expect(_detailFactor(tester, 'Load balancer details'), 0);
      await tester.tap(find.bySemanticsLabel('Expand row 1'));
      await tester.pumpAndSettle();
      expect(_detailFactor(tester, 'Load balancer details'), 1);
      // The other row stays collapsed (rows are independent).
      expect(_detailFactor(tester, 'Object store details'), 0);
      await tester.tap(find.bySemanticsLabel('Expand row 1'));
      await tester.pumpAndSettle();
      expect(_detailFactor(tester, 'Load balancer details'), 0);
    });

    testWidgets('the chevron exposes an expanded-state button', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonDataTable(
            columns: _columns,
            rows: _rows(),
            expandable: true,
            expandedRows: const <int>{0},
            onExpandedChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Expand row 1')),
        isSemantics(isButton: true, isExpanded: true),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('expanded row across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'data_table_expanded',
        containsText: true,
        size: const Size(560, 200),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 520,
            child: CarbonDataTable(
              columns: _columns,
              rows: _rows(),
              expandable: true,
              expandedRows: const <int>{0},
              onExpandedChanged: (_) {},
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
