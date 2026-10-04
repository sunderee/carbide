// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  final query = Uri.base.queryParameters;
  runApp(
    tableAccessibilityHost(
      TableAccessibilityFixture(
        sticky: query['sticky'] == 'true',
        size: CarbonTableSize.values.firstWhere(
          (value) => value.name == query['size'],
          orElse: () => CarbonTableSize.lg,
        ),
      ),
      theme: switch (query['theme']) {
        'g10' => CarbonThemeData.gray10,
        'g90' => CarbonThemeData.gray90,
        'g100' => CarbonThemeData.gray100,
        _ => CarbonThemeData.white,
      },
      direction: query['rtl'] == 'true' ? TextDirection.rtl : TextDirection.ltr,
      scale: double.tryParse(query['scale'] ?? '') ?? 1,
    ),
  );
}

Widget tableAccessibilityHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  onGenerateRoute: (settings) => PageRouteBuilder<void>(
    settings: settings,
    pageBuilder: (_, _, _) => child,
  ),
  builder: (_, navigator) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: CarbonTheme(
        data: theme ?? CarbonThemeData.white,
        child: navigator!,
      ),
    ),
  ),
);

class TableAccessibilityFixture extends StatefulWidget {
  const TableAccessibilityFixture({
    super.key,
    this.sticky = false,
    this.size = CarbonTableSize.lg,
  });

  final bool sticky;
  final CarbonTableSize size;

  @override
  State<TableAccessibilityFixture> createState() =>
      TableAccessibilityFixtureState();
}

class TableAccessibilityFixtureState extends State<TableAccessibilityFixture> {
  final FocusNode before = FocusNode(debugLabel: 'Before table');
  final FocusNode after = FocusNode(debugLabel: 'After table');
  List<String> records = <String>['Alpha', 'Beta', 'Charlie'];
  Set<Object> selected = <Object>{};
  Set<Object> expanded = <Object>{};
  CarbonSortDirection direction = CarbonSortDirection.none;
  int sorts = 0;
  bool enabled = true;
  bool sortable = true;
  bool french = false;
  bool handOff = false;

  @override
  void initState() {
    super.initState();
    if (widget.sticky) {
      records.addAll(<String>[for (int i = 1; i <= 12; i++) 'Record $i']);
    }
  }

  @override
  void dispose() {
    before.dispose();
    after.dispose();
    super.dispose();
  }

  void reverse() => setState(() {
    records = <String>[
      ...records.take(3).toList().reversed,
      ...records.skip(3),
    ];
  });
  void refresh() => setState(() {});

  String _directionLabel(CarbonSortDirection value) => french
      ? switch (value) {
          CarbonSortDirection.none => 'Sans tri',
          CarbonSortDirection.ascending => 'Tri croissant',
          CarbonSortDirection.descending => 'Tri décroissant',
        }
      : carbonTableSortDirectionLabel(value);

  void _sort(int column) {
    setState(() {
      sorts++;
      direction = CarbonSortDirection
          .values[(direction.index + 1) % CarbonSortDirection.values.length];
      final sorted = <String>[...records]..sort();
      records = direction == CarbonSortDirection.descending
          ? sorted.reversed.toList()
          : sorted;
    });
    if (handOff) after.requestFocus();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.f2:
        reverse();
      case LogicalKeyboardKey.f3:
        setState(() => enabled = !enabled);
      case LogicalKeyboardKey.f4:
        setState(() => french = !french);
      case LogicalKeyboardKey.f7:
        setState(
          () => selected = selected.isEmpty ? <Object>{'Alpha'} : <Object>{},
        );
      case LogicalKeyboardKey.f8:
        setState(() => handOff = !handOff);
      case LogicalKeyboardKey.f9:
        setState(() => sortable = !sortable);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: _key,
    child: ColoredBox(
      color: CarbonTheme.of(context).background,
      child: Center(
        child: SizedBox(
          width: 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CarbonButton(
                label: 'Before table',
                focusNode: before,
                onPressed: () {},
              ),
              const SizedBox(height: 16),
              CarbonDataTable(
                title: 'Jobs',
                description: 'Scheduled routines',
                semanticsLabel: french ? 'Travaux planifiés' : 'Scheduled jobs',
                size: widget.size,
                stickyHeader: widget.sticky,
                stickyHeaderHeight: 196,
                sortColumnIndex: 0,
                sortDirection: direction,
                sortDirectionFormatter: _directionLabel,
                onSort: enabled ? _sort : null,
                columns: <CarbonTableColumn>[
                  CarbonTableColumn(title: 'Name', sortable: sortable),
                  const CarbonTableColumn(
                    title: 'Status',
                    aiLabel: CarbonAILabel(content: Text('Generated status')),
                  ),
                ],
                rows: <CarbonTableRow>[
                  for (final record in records)
                    CarbonTableRow(
                      id: record,
                      label: record,
                      cells: <Widget>[
                        Text(record),
                        Text(record == 'Beta' ? 'Stopped' : 'Ready'),
                      ],
                      expandedContent: Text('Details for $record'),
                    ),
                ],
                selection: CarbonTableSelection.multi,
                selectedRowIds: selected,
                onSelectedRowIdsChanged: (next) =>
                    setState(() => selected = next),
                expandable: true,
                expandedRowIds: expanded,
                onExpansionChanged: (next) => setState(() => expanded = next),
              ),
              const SizedBox(height: 16),
              CarbonButton(
                label: 'After table',
                focusNode: after,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
