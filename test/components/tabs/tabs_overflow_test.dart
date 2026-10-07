// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show Tristate;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

final List<CarbonTab> _many = <CarbonTab>[
  for (int i = 0; i < 18; i++)
    CarbonTab(label: 'Tab ${i.toString().padLeft(2, '0')}', disabled: i == 2),
];
final List<Widget> _panels = <Widget>[
  for (int i = 0; i < 18; i++) Text('Panel $i'),
];

Widget _host(
  Widget child, {
  double width = 320,
  TextDirection direction = TextDirection.ltr,
  bool reduced = false,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
      PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (BuildContext context, _, _) => builder(context),
      ),
  home: Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

FocusNode _focus(WidgetTester tester, int index) => tester
    .widget<Focus>(
      find
          .ancestor(
            of: find.text('Tab ${index.toString().padLeft(2, '0')}'),
            matching: find.byType(Focus),
          )
          .first,
    )
    .focusNode!;

ScrollPosition _position(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

void _expectVisible(WidgetTester tester, int index) {
  final Rect viewport = tester.getRect(find.byType(Scrollable).first);
  final Rect label = tester.getRect(
    find.text('Tab ${index.toString().padLeft(2, '0')}'),
  );
  expect(label.left, greaterThanOrEqualTo(viewport.left - 0.5));
  expect(label.right, lessThanOrEqualTo(viewport.right + 0.5));
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  for (final CarbonTabVariant variant in CarbonTabVariant.values) {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('$variant 320px logical controls and Home/End $direction', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _host(
            CarbonTabs(tabs: _many, panels: _panels, variant: variant),
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Scrollable), findsOneWidget);
        _focus(tester, 0).requestFocus();
        await tester.pump();
        await _key(tester, LogicalKeyboardKey.end);
        expect(find.text('Panel 17'), findsOneWidget);
        expect(_position(tester).pixels, greaterThan(0));
        _expectVisible(tester, 17);
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          expect(
            tester.getSemantics(
              find.bySemanticsLabel('Scroll toward last tab'),
            ),
            matchesSemantics(
              isButton: true,
              hasEnabledState: true,
              isEnabled: false,
              label: 'Scroll toward last tab',
            ),
          );
        } finally {
          semantics.dispose();
        }
        await _key(tester, LogicalKeyboardKey.home);
        expect(_position(tester).pixels, closeTo(0, 0.5));
        _expectVisible(tester, 0);
        await _key(
          tester,
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        expect(find.text('Panel 1'), findsOneWidget);
        await _key(
          tester,
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        expect(find.text('Panel 3'), findsOneWidget);
        _expectVisible(tester, 3);
      });

      testWidgets(
        '$variant manual focus reveals without selecting $direction',
        (WidgetTester tester) async {
          final List<int> changes = <int>[];
          await tester.pumpWidget(
            _host(
              CarbonTabs(
                tabs: _many,
                panels: _panels,
                variant: variant,
                activation: CarbonTabActivationMode.manual,
                onChanged: changes.add,
              ),
              direction: direction,
            ),
          );
          await tester.pumpAndSettle();
          _focus(tester, 0).requestFocus();
          await tester.pump();
          await _key(tester, LogicalKeyboardKey.end);
          expect(_focus(tester, 17).hasPrimaryFocus, isTrue);
          expect(find.text('Panel 0'), findsOneWidget);
          expect(changes, isEmpty);
          _expectVisible(tester, 17);
          await _key(tester, LogicalKeyboardKey.enter);
          expect(find.text('Panel 17'), findsOneWidget);
          expect(changes, <int>[17]);
          await _key(tester, LogicalKeyboardKey.home);
          expect(find.text('Panel 17'), findsOneWidget);
          _expectVisible(tester, 0);
          await _key(tester, LogicalKeyboardKey.space);
          expect(find.text('Panel 0'), findsOneWidget);
          expect(changes, <int>[17, 0]);
        },
      );
    }
  }

  testWidgets(
    'controlled callbacks advance actual focus independently of selection',
    (WidgetTester tester) async {
      final List<int> changes = <int>[];
      await tester.pumpWidget(
        _host(
          CarbonTabs(
            tabs: _many,
            panels: _panels,
            selectedIndex: 0,
            onChanged: changes.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      _focus(tester, 0).requestFocus();
      await tester.pump();
      await _key(tester, LogicalKeyboardKey.arrowRight);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(changes, <int>[1, 3]);
      expect(_focus(tester, 3).hasPrimaryFocus, isTrue);
      expect(find.text('Panel 0'), findsOneWidget);
      _expectVisible(tester, 3);
    },
  );

  testWidgets(
    'programmatic selection and resizing keep the current tab visible',
    (WidgetTester tester) async {
      Widget tabs(int selected) =>
          CarbonTabs(tabs: _many, panels: _panels, selectedIndex: selected);
      await tester.pumpWidget(_host(tabs(0)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_host(tabs(17)));
      await tester.pumpAndSettle();
      _expectVisible(tester, 17);
      await tester.pumpWidget(_host(tabs(17), width: 480));
      await tester.pumpAndSettle();
      _expectVisible(tester, 17);
      await tester.pumpWidget(_host(tabs(0)));
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, closeTo(0, 0.5));
    },
  );

  testWidgets(
    'scroll controls change the viewport without selecting or bouncing back',
    (WidgetTester tester) async {
      final List<int> changes = <int>[];
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            CarbonTabs(tabs: _many, panels: _panels, onChanged: changes.add),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Scroll toward last tab'));
        await tester.pumpAndSettle();
        expect(_position(tester).pixels, greaterThan(0));
        final double at = _position(tester).pixels;
        await tester.pump(const Duration(seconds: 1));
        expect(_position(tester).pixels, at);
        expect(changes, isEmpty);
        expect(find.text('Panel 0'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'a resized strip drops controls once its content fits without them',
    (WidgetTester tester) async {
      final List<CarbonTab> tabs = <CarbonTab>[
        const CarbonTab(label: 'Overview'),
        const CarbonTab(label: 'Details'),
        const CarbonTab(label: 'Activity'),
      ];
      final List<Widget> panels = List<Widget>.filled(3, const Text('Panel'));
      await tester.pumpWidget(
        _host(CarbonTabs(tabs: tabs, panels: panels), width: 160),
      );
      await tester.pumpAndSettle();
      expect(_position(tester).maxScrollExtent, greaterThan(0));
      await tester.pumpWidget(
        _host(CarbonTabs(tabs: tabs, panels: panels), width: 740),
      );
      await tester.pumpAndSettle();
      expect(_position(tester).maxScrollExtent, closeTo(0, 0.5));
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pump();
        expect(find.bySemanticsLabel('Scroll toward last tab'), findsNothing);
        expect(find.bySemanticsLabel('Scroll toward first tab'), findsNothing);
      } finally {
        semantics.dispose();
      }
    },
  );

  for (final bool reduced in <bool>[false, true]) {
    testWidgets('scroll duration respects reduced=$reduced', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonTabs(tabs: _many, panels: _panels),
          reduced: reduced,
        ),
      );
      await tester.pumpAndSettle();
      _focus(tester, 0).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.pump();
      if (reduced) {
        expect(_position(tester).isScrollingNotifier.value, isFalse);
        _expectVisible(tester, 17);
      } else {
        expect(_position(tester).isScrollingNotifier.value, isTrue);
        await tester.pumpAndSettle();
        _expectVisible(tester, 17);
      }
    });
  }

  testWidgets('only the active tab participates in keyboard traversal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(CarbonTabs(tabs: _many, panels: _panels)));
    await tester.pumpAndSettle();
    expect(_focus(tester, 0).skipTraversal, isFalse);
    expect(_focus(tester, 1).skipTraversal, isTrue);
    _focus(tester, 0).requestFocus();
    await tester.pump();
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focus(tester, 0).skipTraversal, isTrue);
    expect(_focus(tester, 1).skipTraversal, isFalse);
  });

  for (final bool vertical in <bool>[false, true]) {
    testWidgets('supported tab roles and panel controls vertical=$vertical', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        final Widget tabs = vertical
            ? CarbonTabsVertical(
                tabs: _many,
                panels: _panels,
                height: 200,
                tabListLabel: 'Sections',
              )
            : CarbonTabs(
                tabs: _many,
                panels: _panels,
                tabListLabel: 'Sections',
              );
        await tester.pumpWidget(_host(tabs));
        await tester.pumpAndSettle();
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Sections'))
              .getSemanticsData()
              .role,
          SemanticsRole.tabBar,
        );
        final SemanticsData tab = tester
            .getSemantics(find.bySemanticsLabel('Tab 00'))
            .getSemanticsData();
        final SemanticsData panel = tester
            .getSemantics(find.bySemanticsLabel('Panel 0'))
            .getSemanticsData();
        expect(tab.role, SemanticsRole.tab);
        expect(panel.role, SemanticsRole.tabPanel);
        expect(tab.controlsNodes, <String>{panel.identifier});
        expect(tab.flagsCollection.isFocused, Tristate.isFalse);
        for (final int index in <int>[1, 2, 17]) {
          expect(
            tester
                .getSemantics(
                  find.bySemanticsLabel(
                    'Tab ${index.toString().padLeft(2, '0')}',
                  ),
                )
                .getSemanticsData()
                .flagsCollection
                .isFocused,
            Tristate.none,
          );
        }
        _focus(tester, 0).requestFocus();
        await tester.pump();
        await _key(tester, LogicalKeyboardKey.end);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Tab 17'))
              .getSemanticsData()
              .flagsCollection
              .isFocused,
          Tristate.isTrue,
        );
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Tab 00'))
              .getSemanticsData()
              .flagsCollection
              .isFocused,
          Tristate.none,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'manual activation works with shared overflow vertical=$vertical',
      (WidgetTester tester) async {
        final Widget tabs = vertical
            ? CarbonTabsVertical(
                tabs: _many,
                panels: _panels,
                height: 200,
                activation: CarbonTabActivationMode.manual,
              )
            : CarbonTabs(
                tabs: _many,
                panels: _panels,
                activation: CarbonTabActivationMode.manual,
              );
        await tester.pumpWidget(_host(tabs));
        await tester.pumpAndSettle();
        _focus(tester, 0).requestFocus();
        await tester.pump();
        await _key(tester, LogicalKeyboardKey.end);
        expect(find.text('Panel 0'), findsOneWidget);
        expect(_position(tester).pixels, greaterThan(0));
        await _key(tester, LogicalKeyboardKey.enter);
        expect(find.text('Panel 17'), findsOneWidget);
      },
    );
  }

  for (final bool vertical in <bool>[false, true]) {
    testWidgets(
      'focused selection and shrinking rows reconcile vertical=$vertical',
      (WidgetTester tester) async {
        final List<int> changes = <int>[];
        Widget tabs(int selected, int count) => vertical
            ? CarbonTabsVertical(
                tabs: _many.take(count).toList(),
                panels: _panels.take(count).toList(),
                selectedIndex: selected,
                height: 200,
                onChanged: changes.add,
              )
            : CarbonTabs(
                tabs: _many.take(count).toList(),
                panels: _panels.take(count).toList(),
                selectedIndex: selected,
                onChanged: changes.add,
              );
        await tester.pumpWidget(_host(tabs(0, 18)));
        await tester.pumpAndSettle();
        _focus(tester, 0).requestFocus();
        await tester.pump();
        await tester.pumpWidget(_host(tabs(17, 18)));
        await tester.pumpAndSettle();
        expect(_focus(tester, 17).hasPrimaryFocus, isTrue);
        await tester.pumpWidget(_host(tabs(3, 4)));
        await tester.pumpAndSettle();
        expect(_focus(tester, 3).hasPrimaryFocus, isTrue);
        expect(find.text('Panel 3'), findsOneWidget);
        expect(changes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'reduced motion finishes a pending programmatic scroll immediately',
    (WidgetTester tester) async {
      Widget tabs() => CarbonTabs(tabs: _many, panels: _panels);
      await tester.pumpWidget(_host(tabs()));
      await tester.pumpAndSettle();
      _focus(tester, 0).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.pump();
      expect(_position(tester).isScrollingNotifier.value, isTrue);
      await tester.pumpWidget(_host(tabs(), reduced: true));
      await tester.pump();
      expect(_position(tester).isScrollingNotifier.value, isFalse);
      _expectVisible(tester, 17);
    },
  );

  testWidgets(
    'long icon/dismiss labels fit one viewport and keep their full names',
    (WidgetTester tester) async {
      final String label = List<String>.filled(12, 'Long label').join(' ');
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            CarbonTabs(
              tabs: <CarbonTab>[
                CarbonTab(
                  label: label,
                  icon: CarbonIcons.settings,
                  dismissable: true,
                  onDismiss: () {},
                ),
                const CarbonTab(label: 'Other'),
              ],
              panels: const <Widget>[Text('First'), Text('Second')],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Rect viewport = tester.getRect(find.byType(Scrollable).first);
        expect(
          tester.getSize(find.text(label)).width,
          lessThan(viewport.width),
        );
        expect(find.bySemanticsLabel(label), findsOneWidget);
        expect(find.bySemanticsLabel('Dismiss $label'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('disabled-only strips are stable and have no roving tab stop', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarbonTabs(
          tabs: <CarbonTab>[
            for (int i = 0; i < 18; i++)
              CarbonTab(
                label: 'Tab ${i.toString().padLeft(2, '0')}',
                disabled: true,
              ),
          ],
          panels: _panels,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (int i = 0; i < 18; i++) {
      expect(_focus(tester, i).canRequestFocus, isFalse);
      expect(_focus(tester, i).skipTraversal, isTrue);
    }
  });

  for (final CarbonTabVariant variant in CarbonTabVariant.values) {
    testWidgets('320px ${variant.name} overflow across themes/RTL', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'tabs_overflow_${variant.name}',
        containsText: true,
        size: const Size(320, 150),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) =>
            CarbonTabs(tabs: _many, panels: _panels, variant: variant),
        afterPump: (WidgetTester tester) async => tester.pumpAndSettle(),
      );
    });
  }
}
