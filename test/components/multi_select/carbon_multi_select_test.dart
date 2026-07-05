// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          builder: (BuildContext context) =>
              Center(child: SizedBox(width: 320, child: child)),
        ),
      ],
    ),
  ),
);

const List<CarbonMultiSelectItem<String>> _items =
    <CarbonMultiSelectItem<String>>[
      CarbonMultiSelectItem<String>(value: 'a', label: 'Apple'),
      CarbonMultiSelectItem<String>(value: 'b', label: 'Banana'),
      CarbonMultiSelectItem<String>(value: 'c', label: 'Cherry'),
      CarbonMultiSelectItem<String>(value: 'd', label: 'Date'),
    ];

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  /// A stateful host that tracks the selection set.
  Widget stateful({
    Set<String> initial = const <String>{},
    bool filterable = false,
    void Function(Set<String>)? sink,
  }) => _host(
    _Tracked(initial: initial, filterable: filterable, onChanged: sink),
  );

  group('anatomy', () {
    testWidgets('title, label, helper, no badge when empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(stateful());
      expect(find.text('Fruit'), findsOneWidget);
      expect(find.text('Choose options'), findsOneWidget);
      expect(find.text('Pick some'), findsOneWidget);
      expect(find.byType(CarbonListBoxSelectionCount), findsNothing);
    });

    testWidgets('count badge shows the number selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(stateful(initial: <String>{'a', 'b'}));
      expect(find.byType(CarbonListBoxSelectionCount), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('count badge renders the number legibly (not clipped)', (
      WidgetTester tester,
    ) async {
      // Regression: the badge pill clamped its content to an 8px band, clipping
      // the count to an unreadable sliver. `find.text('2')` still passed, so
      // only a render-height check catches it.
      await tester.pumpWidget(stateful(initial: <String>{'a', 'b'}));
      expectTextNotClipped(tester, find.text('2'));
    });
  });

  group('selection', () {
    testWidgets('open shows checkbox rows; tapping toggles', (
      WidgetTester tester,
    ) async {
      Set<String>? last;
      await tester.pumpWidget(stateful(sink: (Set<String> s) => last = s));
      await tester.tap(find.byType(CarbonListBox));
      await tester.pump();
      expect(find.byType(CarbonCheckbox), findsNWidgets(4));
      await tester.tap(find.text('Cherry'));
      await tester.pump();
      expect(last, <String>{'c'});
    });

    testWidgets('clear-all badge empties the selection', (
      WidgetTester tester,
    ) async {
      Set<String>? last;
      await tester.pumpWidget(
        stateful(
          initial: <String>{'a', 'b'},
          sink: (Set<String> s) => last = s,
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(CarbonListBoxSelectionCount),
          matching: find.byType(CarbonIcon),
        ),
      );
      await tester.pump();
      expect(last, <String>{});
    });
  });

  group('row centering (#262)', () {
    Future<void> expectCenteredRows(WidgetTester tester) async {
      await tester.tap(find.byType(CarbonListBox));
      await tester.pump();
      final Finder rows = find.byType(CarbonListBoxMenuItem);
      expect(rows, findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        final Finder row = rows.at(i);
        final Finder checkbox = find.descendant(
          of: row,
          matching: find.byType(CarbonCheckbox),
        );
        expect(
          tester.getCenter(checkbox).dy,
          moreOrLessEquals(tester.getCenter(row).dy, epsilon: 1),
          reason: 'row $i',
        );
      }
    }

    testWidgets('option checkboxes centre in their menu rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(stateful());
      await expectCenteredRows(tester);
    });

    testWidgets('option checkboxes centre in the 64px fluid rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonMultiSelect<String>(
            titleText: 'Fruit',
            label: 'Choose fruit',
            fluid: true,
            selectedValues: const <String>{'a'},
            onChanged: (Set<String> _) {},
            items: _items,
          ),
        ),
      );
      await expectCenteredRows(tester);
    });
  });

  group('keyboard', () {
    testWidgets('Down opens; arrows move; Space toggles; Escape closes', (
      WidgetTester tester,
    ) async {
      Set<String>? last;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          _Tracked(
            initial: const <String>{},
            onChanged: (Set<String> s) => last = s,
            focusNode: node,
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsOneWidget);
      // Apple highlighted → Down → Banana → Space toggles Banana.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(last, <String>{'b'});
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(CarbonListBoxMenu), findsNothing);
    });
  });

  group('filterable', () {
    testWidgets('typing filters the checkbox rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const _Tracked(initial: <String>{}, filterable: true)),
      );
      await tester.enterText(find.byType(EditableText), 'ch');
      await tester.pumpAndSettle();
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    });
  });

  group('semantics', () {
    testWidgets('field is a button carrying the title', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(stateful(initial: <String>{'a'}));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Fruit')),
        isSemantics(label: 'Fruit', isButton: true, value: '1 selected'),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('states across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'multi_select_states',
        containsText: true,
        size: const Size(340, 220),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                CarbonMultiSelect<String>(
                  titleText: 'Empty',
                  label: 'Choose options',
                  items: _items,
                  onChanged: _noop,
                ),
                SizedBox(height: 12),
                CarbonMultiSelect<String>(
                  titleText: 'Selected',
                  label: 'Choose options',
                  items: _items,
                  selectedValues: <String>{'a', 'b', 'c'},
                  onChanged: _noop,
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('open menu across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'multi_select_open',
        containsText: true,
        size: const Size(320, 280),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Padding(
                padding: const EdgeInsets.all(12),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 280,
                    child: CarbonMultiSelect<String>(
                      titleText: 'Fruit',
                      label: 'Choose options',
                      items: _items,
                      selectedValues: <String>{'b', 'd'},
                      onChanged: _noop,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.tap(find.byType(CarbonListBox));
          await tester.pumpAndSettle();
        },
      );
    });
  });
}

void _noop(Set<String> _) {}

/// A small stateful wrapper that owns the selection set for interaction tests.
class _Tracked extends StatefulWidget {
  const _Tracked({
    required this.initial,
    this.filterable = false,
    this.onChanged,
    this.focusNode,
  });

  final Set<String> initial;
  final bool filterable;
  final void Function(Set<String>)? onChanged;
  final FocusNode? focusNode;

  @override
  State<_Tracked> createState() => _TrackedState();
}

class _TrackedState extends State<_Tracked> {
  late Set<String> _selected = widget.initial;

  @override
  Widget build(BuildContext context) => CarbonMultiSelect<String>(
    titleText: 'Fruit',
    label: 'Choose options',
    helperText: 'Pick some',
    items: _items,
    selectedValues: _selected,
    filterable: widget.filterable,
    filterPlaceholder: 'Filter…',
    focusNode: widget.focusNode,
    onChanged: (Set<String> s) {
      setState(() => _selected = s);
      widget.onChanged?.call(s);
    },
  );
}
