// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Align(alignment: Alignment.topRight, child: child),
  ),
);

/// Adds the Tab → next-focus wiring a WidgetsApp would normally provide, so
/// tests can drive real Tab key traversal without one.
Widget _tabTraversal(Widget child) => Shortcuts(
  shortcuts: const <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{NextFocusIntent: NextFocusAction()},
    child: FocusScope(autofocus: true, child: child),
  ),
);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Widget switcher(VoidCallback onTap, {bool open = true}) => _host(
    CarbonHeaderPanel(
      open: open,
      child: CarbonSwitcher(
        children: <Widget>[
          CarbonSwitcherItem(
            label: 'Console',
            selected: true,
            onPressed: () {},
          ),
          const CarbonSwitcherDivider(),
          CarbonSwitcherItem(label: 'Catalog', onPressed: onTap),
        ],
      ),
    ),
  );

  group('header panel', () {
    testWidgets('open is 256px wide; closed collapses to 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(switcher(() {}));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(CarbonHeaderPanel)).width, 256);

      await tester.pumpWidget(switcher(() {}, open: false));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(CarbonHeaderPanel)).width, 0);
    });
  });

  group('switcher', () {
    testWidgets('items render; tapping navigates; selected is bold', (
      WidgetTester tester,
    ) async {
      int went = 0;
      await tester.pumpWidget(switcher(() => went++));
      await tester.pumpAndSettle();
      expect(find.text('Console'), findsOneWidget);
      expect(find.text('Catalog'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Console')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(
        tester.widget<Text>(find.text('Console')).style!.color,
        theme.textPrimary,
      );
      await tester.tap(find.text('Catalog'));
      expect(went, 1);
    });

    testWidgets('selected item exposes selected semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(switcher(() {}));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Console')),
        isSemantics(label: 'Console', isButton: true, isSelected: true),
      );
      handle.dispose();
    });

    testWidgets('item activates with Enter and Space and shows the focus '
        'ring', (WidgetTester tester) async {
      int pressed = 0;
      await tester.pumpWidget(switcher(() => pressed++));
      await tester.pumpAndSettle();

      Focus.of(tester.element(find.text('Catalog'))).requestFocus();
      await tester.pumpAndSettle();
      final CarbonFocusRing ring = tester.widget<CarbonFocusRing>(
        find
            .ancestor(
              of: find.text('Catalog'),
              matching: find.byType(CarbonFocusRing),
            )
            .first,
      );
      expect(ring.visible, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(pressed, 2);
    });

    testWidgets('hovering tints a non-selected item only', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(switcher(() {}));
      await tester.pumpAndSettle();
      final Color hoverColor = CarbonLayer.of(
        tester.element(find.text('Catalog')),
      ).layerHover;
      Color itemColor(String label) => tester
          .widget<ColoredBox>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color;

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.text('Catalog')));
      await tester.pump();
      expect(itemColor('Catalog'), hoverColor);

      // The selected item stays transparent even while hovered.
      await gesture.moveTo(tester.getCenter(find.text('Console')));
      await tester.pump();
      expect(itemColor('Console'), const Color(0x00000000));
      expect(itemColor('Catalog'), const Color(0x00000000));
    });

    testWidgets('divider renders a 1px rule between sections', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 256,
            child: CarbonSwitcher(
              children: <Widget>[
                CarbonSwitcherItem(label: 'A', onPressed: () {}),
                CarbonSwitcherDivider(key: UniqueKey()),
                CarbonSwitcherItem(label: 'B', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      final Finder rule = find.descendant(
        of: find.byType(CarbonSwitcherDivider),
        matching: find.byType(SizedBox),
      );
      expect(tester.getSize(rule).height, 1);
    });
  });

  // Keyboard spec (Apache-2.0 Carbon Design System; see NOTICE):
  //   documentation/carbon-website/src/pages/components/UI-shell-right-panel/
  //     accessibility.mdx — "All actionable links in the panel can be
  //     reached by Tab. Activating any of the links (with Enter) loads new
  //     content." (Enter/Space activation of a focused item is covered in
  //     the switcher group above.)
  group('keyboard (#231)', () {
    testWidgets('Tab reaches each item in order and Enter activates', (
      WidgetTester tester,
    ) async {
      int went = 0;
      await tester.pumpWidget(
        _host(
          _tabTraversal(
            CarbonHeaderPanel(
              open: true,
              child: CarbonSwitcher(
                children: <Widget>[
                  CarbonSwitcherItem(
                    label: 'Console',
                    selected: true,
                    onPressed: () {},
                  ),
                  const CarbonSwitcherDivider(),
                  CarbonSwitcherItem(label: 'Catalog', onPressed: () => went++),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      CarbonFocusRing ring(String label) => tester.widget<CarbonFocusRing>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(CarbonFocusRing),
            )
            .first,
      );
      bool focused(String label) =>
          Focus.of(tester.element(find.text(label))).hasPrimaryFocus;

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focused('Console'), isTrue);
      expect(ring('Console').visible, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(focused('Catalog'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(went, 1);
    });
  });

  group('content', () {
    testWidgets('pads the page body by spacing05 on every side', (
      WidgetTester tester,
    ) async {
      final Key bodyKey = UniqueKey();
      await tester.pumpWidget(
        _host(
          CarbonShellContent(
            child: SizedBox(key: bodyKey, width: 40, height: 40),
          ),
        ),
      );
      final Offset region = tester.getTopLeft(find.byType(CarbonShellContent));
      final Offset body = tester.getTopLeft(find.byKey(bodyKey));
      expect(
        body - region,
        const Offset(CarbonSpacing.spacing05, CarbonSpacing.spacing05),
      );
    });

    testWidgets('exposes a main-content region', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonShellContent(child: Text('Body'))),
      );
      expect(find.text('Body'), findsOneWidget);
      expect(find.bySemanticsLabel('Main content'), findsOneWidget);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('switcher panel across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'ui_shell_switcher',
        containsText: true,
        size: const Size(280, 200),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topRight,
          child: CarbonHeaderPanel(
            open: true,
            child: CarbonSwitcher(
              children: <Widget>[
                CarbonSwitcherItem(
                  label: 'Console',
                  selected: true,
                  onPressed: () {},
                ),
                CarbonSwitcherItem(label: 'Catalog', onPressed: () {}),
                const CarbonSwitcherDivider(),
                CarbonSwitcherItem(label: 'Account', onPressed: () {}),
              ],
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
