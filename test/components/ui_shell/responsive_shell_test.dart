// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(
      size: Size(width, 800),
      textScaler: TextScaler.linear(scale),
    ),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);
void main() {
  testWidgets('primary navigation appears once on either side of lg', (
    WidgetTester tester,
  ) async {
    int navigated = 0;
    for (final double width in <double>[320, 1055, 1056, 1200, 320]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          Column(
            children: <Widget>[
              CarbonHeader(
                name: const CarbonHeaderName(name: 'App'),
                navigation: <Widget>[
                  CarbonHeaderMenuItem(
                    label: 'Reports',
                    onPressed: () => navigated++,
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: <Widget>[
                    CarbonSideNav(
                      items: <Widget>[
                        CarbonHeaderSideNavItems(
                          items: <Widget>[
                            CarbonSideNavLink(
                              label: 'Reports',
                              onPressed: () => navigated++,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Expanded(child: Text('Workspace')),
                  ],
                ),
              ),
            ],
          ),
          width: width,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reports'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CarbonHeader),
          matching: find.text('Reports'),
        ),
        width >= CarbonBreakpoint.lg.width ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(navigated, 5);
  });

  testWidgets('main borrows focus and does not claim child focus', (
    WidgetTester tester,
  ) async {
    final FocusNode main = FocusNode(skipTraversal: true), editor = FocusNode();
    addTearDown(main.dispose);
    addTearDown(editor.dispose);
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          CarbonShellContent(
            focusNode: main,
            child: CarbonTextInput(labelText: 'Editor', focusNode: editor),
          ),
        ),
      );
      main.requestFocus();
      await tester.pumpAndSettle();
      expect(main.hasPrimaryFocus, isTrue);
      expect(
        tester
            .getSemantics(find.byType(CarbonShellContent))
            .getSemanticsData()
            .role,
        SemanticsRole.main,
      );
      // Let the web engine apply the main landmark focus before transferring
      // it to the editor; fake frame time alone does not flush native DOM focus.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      editor.requestFocus();
      await tester.pumpAndSettle();
      expect(editor.hasPrimaryFocus, isTrue);
      expect(
        tester
            .getSemantics(find.byType(CarbonShellContent))
            .getSemanticsData()
            .flagsCollection
            .isFocused
            .name,
        'isFalse',
      );
      expect(main.skipTraversal, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(() => main.requestFocus(), returnsNormally);
      expect(() => editor.requestFocus(), returnsNormally);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('primary divider occupies the middle of its 32px gap', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonHeaderSideNavItems(
          hasDivider: true,
          items: <Widget>[SizedBox(height: 32)],
        ),
      ),
    );
    final Finder wrapper = find.byType(CarbonHeaderSideNavItems);
    final Finder line = find.descendant(
      of: wrapper,
      matching: find.byType(ColoredBox),
    );
    expect(tester.getSize(wrapper).height, 64);
    expect(tester.getSize(line), const Size(288, 1));
    expect(
      tester.getTopLeft(line) - tester.getTopLeft(wrapper),
      const Offset(16, 47),
    );
  });

  testWidgets('main preserves replacement node policy and child state', (
    tester,
  ) async {
    final FocusNode first = FocusNode(skipTraversal: true);
    final FocusNode second = FocusNode(canRequestFocus: false);
    final TextEditingController editor = TextEditingController(text: 'Draft');
    try {
      Widget host(FocusNode? node) => _host(
        CarbonShellContent(
          focusNode: node,
          child: CarbonTextInput(labelText: 'Editor', controller: editor),
        ),
      );
      await tester.pumpWidget(host(first));
      final State<StatefulWidget> state = tester.state(
        find.byType(CarbonTextInput),
      );
      await tester.pumpWidget(host(second));
      expect(tester.state(find.byType(CarbonTextInput)), same(state));
      expect(second.canRequestFocus, isFalse);
      expect(first.skipTraversal, isTrue);
      second.canRequestFocus = true;
      second.skipTraversal = true;
      await tester.pumpAndSettle();
      expect(second.canRequestFocus, isTrue);
      expect(second.skipTraversal, isTrue);
      await tester.pumpWidget(host(null));
      expect(tester.state(find.byType(CarbonTextInput)), same(state));
      expect(editor.text, 'Draft');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(() => first.requestFocus(), returnsNormally);
      expect(() => second.requestFocus(), returnsNormally);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      first.dispose();
      second.dispose();
      editor.dispose();
    }
  });

  testWidgets('narrow shell goldens', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'ui_shell_narrow',
      containsText: true,
      size: const Size(320, 300),
      mediaQuery: const MediaQueryData(size: Size(320, 800)),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => Column(
        children: <Widget>[
          CarbonHeader(
            name: const CarbonHeaderName(name: 'App'),
            menuButton: CarbonHeaderMenuButton(
              label: 'Navigation',
              onPressed: () {},
            ),
            navigation: <Widget>[
              CarbonHeaderMenuItem(label: 'Reports', onPressed: () {}),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CarbonSideNav(
                  items: <Widget>[
                    CarbonHeaderSideNavItems(
                      items: <Widget>[
                        CarbonSideNavLink(
                          label: 'Reports',
                          current: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: CarbonShellContent(
                    child: Builder(
                      builder: (context) => Text(
                        'Body',
                        style: CarbonTypeStyles.bodyCompact01.copyWith(
                          color: CarbonTheme.of(context).textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });
  testWidgets('RTL panel and scaled switcher goldens', (
    WidgetTester tester,
  ) async {
    for (final double scale in <double>[1, 2]) {
      await expectThemeGoldens(
        tester,
        name: 'ui_shell_panel_scaled_${scale.toInt()}',
        containsText: true,
        size: const Size(320, 200),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => CarbonHeaderPanel(
          open: true,
          child: CarbonSwitcher(
            children: <Widget>[
              CarbonSwitcherItem(label: 'Cloud', onPressed: () {}),
              CarbonSwitcherItem(
                label: 'Console',
                selected: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    }
  });
  testWidgets('header navigation is hidden below Carbon lg', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarbonHeader(
          name: const CarbonHeaderName(name: 'App'),
          navigation: <Widget>[
            CarbonHeaderMenuItem(label: 'Reports', onPressed: () {}),
          ],
        ),
      ),
    );
    expect(find.text('Reports'), findsNothing);
  });
  for (final TextDirection direction in TextDirection.values) {
    testWidgets(
      'narrow scaled brand respects remaining header width $direction',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _host(
            CarbonHeader(
              menuButton: CarbonHeaderMenuButton(
                label: 'Navigation',
                onPressed: () {},
              ),
              name: CarbonHeaderName(
                prefix: 'A longer company name',
                name: 'A longer product name',
                onPressed: () {},
              ),
              globalActions: <Widget>[
                CarbonHeaderGlobalAction(
                  icon: CarbonIcons.search,
                  label: 'Search',
                  onPressed: () {},
                ),
              ],
            ),
            scale: 2,
            direction: direction,
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
    for (final double scale in <double>[1.3, 2]) {
      testWidgets('switcher rows retain scaled glyphs $direction $scale', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          _host(
            CarbonHeaderPanel(
              open: true,
              child: CarbonSwitcher(
                children: <Widget>[
                  CarbonSwitcherItem(label: 'Cloud', onPressed: () {}),
                ],
              ),
            ),
            scale: scale,
            direction: direction,
          ),
        );
        await tester.pumpAndSettle();
        expectTextNotClipped(tester, find.text('Cloud'));
        final Text label = tester.widget<Text>(find.text('Cloud'));
        final TextPainter expected = TextPainter(
          text: TextSpan(text: label.data, style: label.style),
          textDirection: direction,
          textScaler: TextScaler.linear(scale),
        )..layout(maxWidth: 224);
        try {
          expect(
            tester.getSize(find.text('Cloud')).height,
            closeTo(expected.height, .01),
          );
        } finally {
          expected.dispose();
        }
        expect(tester.takeException(), isNull);
      });
    }
    testWidgets('header panel uses both logical Carbon borders $direction', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonHeaderPanel(open: true, child: Text('Panel')),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      final AnimatedContainer panel = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final BoxDecoration decoration = panel.decoration! as BoxDecoration;
      expect(decoration.border, isA<BorderDirectional>());
    });
  }
}
