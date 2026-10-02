// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.
//
// Run with assertions disabled in a real release browser:
// flutter drive --release --driver=test_driver/integration_test.dart
//   --target=integration_test/tabs_release_contract_test.dart -d web-server

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final bool vertical in <bool>[false, true]) {
    testWidgets('vertical=$vertical release inputs never index outside pairs', (
      WidgetTester tester,
    ) async {
      expect(
        kReleaseMode,
        isTrue,
        reason: 'this regression must run with --release',
      );
      bool assertionsEnabled = false;
      assert(assertionsEnabled = true);
      expect(assertionsEnabled, isFalse);
      const List<CarbonTab> tabs = <CarbonTab>[
        CarbonTab(label: 'A'),
        CarbonTab(label: 'B'),
      ];
      const List<Widget> panels = <Widget>[Text('A panel'), Text('B panel')];
      for (final (int index, String expected) in <(int, String)>[
        (-5, 'A panel'),
        (99, 'B panel'),
      ]) {
        await tester.pumpWidget(_host(_tabs(vertical, tabs, panels, index)));
        await tester.pumpAndSettle();
        expect(find.text(expected), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        _host(_tabs(vertical, tabs, const <Widget>[Text('Only panel')], 1)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Only panel'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        _host(
          _tabs(vertical, const <CarbonTab>[CarbonTab(label: 'A')], panels, 1),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A panel'), findsOneWidget);
      for (final (List<CarbonTab> entries, List<Widget> content)
          in <(List<CarbonTab>, List<Widget>)>[
            (tabs, <Widget>[]),
            (<CarbonTab>[], panels),
            (<CarbonTab>[], <Widget>[]),
          ]) {
        await tester.pumpWidget(_host(_tabs(vertical, entries, content, -1)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('A panel'), findsNothing);
        expect(find.text('B panel'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Widget _tabs(
  bool vertical,
  List<CarbonTab> tabs,
  List<Widget> panels,
  int index,
) => vertical
    ? CarbonTabsVertical(
        tabs: tabs,
        panels: panels,
        selectedIndex: index,
        height: 200,
      )
    : CarbonTabs(tabs: tabs, panels: panels, selectedIndex: index);

Widget _host(Widget child) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (BuildContext context, Widget? _) => CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 420, child: child)),
  ),
);
