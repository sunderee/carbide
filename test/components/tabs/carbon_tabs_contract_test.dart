// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final bool vertical in <bool>[false, true]) {
    Widget tabs(
      List<CarbonTab> entries,
      List<Widget> panels, {
      int? selectedIndex,
      ValueChanged<int>? onChanged,
    }) => vertical
        ? CarbonTabsVertical(
            tabs: entries,
            panels: panels,
            selectedIndex: selectedIndex,
            onChanged: onChanged,
            height: 200,
          )
        : CarbonTabs(
            tabs: entries,
            panels: panels,
            selectedIndex: selectedIndex,
            onChanged: onChanged,
          );

    test('vertical=$vertical rejects invalid configurations', () {
      const List<CarbonTab> entries = <CarbonTab>[CarbonTab(label: 'A')];
      const List<Widget> panels = <Widget>[Text('A panel')];
      expect(() => tabs(entries, <Widget>[]), throwsAssertionError);
      expect(() => tabs(<CarbonTab>[], <Widget>[]), throwsAssertionError);
      expect(
        () => tabs(entries, <Widget>[...panels, const Text('Extra')]),
        throwsAssertionError,
      );
      expect(
        () => tabs(entries, panels, selectedIndex: -1),
        throwsAssertionError,
      );
      expect(
        () => tabs(entries, panels, selectedIndex: 1),
        throwsAssertionError,
      );
      expect(
        () => tabs(entries, panels, selectedIndex: 5),
        throwsAssertionError,
      );
    });

    for (final bool controlled in <bool>[false, true]) {
      testWidgets(
        'vertical=$vertical controlled=$controlled reconciles removal',
        (WidgetTester tester) async {
          List<CarbonTab> entries = <CarbonTab>[
            const CarbonTab(label: 'A'),
            const CarbonTab(label: 'B'),
            const CarbonTab(label: 'C'),
          ];
          List<Widget> panels = <Widget>[
            const Text('A panel'),
            const Text('B panel'),
            const Text('C panel'),
          ];
          int? index = controlled ? 2 : null;
          int calls = 0;
          await tester.pumpWidget(
            _host(
              tabs(
                entries,
                panels,
                selectedIndex: index,
                onChanged: (_) => calls++,
              ),
            ),
          );
          if (!controlled) {
            await tester.tap(find.text('C'));
            await tester.pumpAndSettle();
          }
          expect(find.text('C panel'), findsOneWidget);
          // Reuse mutable lists to exercise production safeguards independently
          // of constructor assertions (the widget was valid when constructed).
          final Widget shrinking = tabs(
            entries,
            panels,
            selectedIndex: index,
            onChanged: (_) => calls++,
          );
          entries.removeLast();
          panels.removeLast();
          await tester.pumpWidget(_host(shrinking));
          expect(tester.takeException(), isNull);
          expect(find.text('B panel'), findsOneWidget);
          expect(
            calls,
            controlled ? 0 : 1,
            reason: 'reconciliation does not call onChanged during build',
          );
          // Dropping controlled mode inherits the reconciled visible selection.
          index = null;
          entries = List<CarbonTab>.of(entries);
          panels = List<Widget>.of(panels);
          await tester.pumpWidget(
            _host(tabs(entries, panels, selectedIndex: index)),
          );
          expect(find.text('B panel'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('vertical=$vertical panel shrink clamps the release path', (
      WidgetTester tester,
    ) async {
      final List<CarbonTab> entries = <CarbonTab>[
        const CarbonTab(label: 'A'),
        const CarbonTab(label: 'B'),
      ];
      final List<Widget> panels = <Widget>[
        const Text('A panel'),
        const Text('B panel'),
      ];
      final Widget widget = tabs(entries, panels, selectedIndex: 1);
      panels.removeLast();
      await tester.pumpWidget(_host(widget));
      expect(tester.takeException(), isNull);
      expect(find.text('A panel'), findsOneWidget);
      // Even all panels/tabs disappearing cannot cause a RangeError in release.
      panels.clear();
      entries.clear();
      await tester.pumpWidget(
        _host(
          tabs(
            <CarbonTab>[const CarbonTab(label: 'Placeholder')],
            <Widget>[const SizedBox.shrink()],
          ),
        ),
      );
      await tester.pumpWidget(_host(widget));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'vertical=$vertical controlled selection survives switching modes',
      (WidgetTester tester) async {
        const List<CarbonTab> entries = <CarbonTab>[
          CarbonTab(label: 'A'),
          CarbonTab(label: 'B'),
        ];
        const List<Widget> panels = <Widget>[Text('A panel'), Text('B panel')];
        await tester.pumpWidget(_host(tabs(entries, panels, selectedIndex: 0)));
        await tester.pumpWidget(_host(tabs(entries, panels, selectedIndex: 1)));
        await tester.pumpWidget(_host(tabs(entries, panels)));
        expect(find.text('B panel'), findsOneWidget);
      },
    );
  }
}

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 420, child: child)),
  ),
);
