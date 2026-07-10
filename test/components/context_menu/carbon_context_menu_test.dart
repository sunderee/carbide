// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/overlay_entries.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (BuildContext context) => Center(child: child),
          ),
        ],
      ),
    ),
  ),
);

CarbonContextMenu _menu({VoidCallback? onCut, bool enabled = true}) =>
    CarbonContextMenu(
      enabled: enabled,
      items: <Widget>[
        CarbonMenuItem(label: 'Cut', onPressed: onCut ?? () {}),
        CarbonMenuItem(label: 'Copy', onPressed: () {}),
      ],
      child: const SizedBox(
        key: ValueKey<String>('target'),
        width: 200,
        height: 120,
        child: ColoredBox(color: Color(0xFFEEEEEE)),
      ),
    );

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  Future<void> rightClick(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey<String>('target'))),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
  }

  group('open', () {
    testWidgets('secondary click opens the menu at the pointer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(_menu()));
      expect(find.text('Cut'), findsNothing);
      await rightClick(tester);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      // The menu appears near the click point (centre of an 800x600 surface).
      expect(tester.getTopLeft(find.text('Cut')).dx, greaterThan(380));
    });

    testWidgets('long press opens the menu', (WidgetTester tester) async {
      await tester.pumpWidget(_host(_menu()));
      await tester.longPressAt(
        tester.getCenter(find.byKey(const ValueKey<String>('target'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsOneWidget);
    });

    testWidgets('disabled does not open', (WidgetTester tester) async {
      await tester.pumpWidget(_host(_menu(enabled: false)));
      await rightClick(tester);
      expect(find.text('Cut'), findsNothing);
    });
  });

  group('close', () {
    testWidgets('activating an item fires it and closes the menu', (
      WidgetTester tester,
    ) async {
      bool cut = false;
      await tester.pumpWidget(_host(_menu(onCut: () => cut = true)));
      await rightClick(tester);
      await tester.tap(find.text('Cut'));
      await tester.pumpAndSettle();
      expect(cut, isTrue);
      expect(find.text('Cut'), findsNothing);
    });

    testWidgets('an outside tap closes the menu', (WidgetTester tester) async {
      await tester.pumpWidget(_host(_menu()));
      await rightClick(tester);
      expect(find.text('Cut'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
    });

    testWidgets('Escape closes the menu', (WidgetTester tester) async {
      await tester.pumpWidget(_host(_menu()));
      await rightClick(tester);
      expect(find.text('Cut'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Cut'), findsNothing);
    });
  });

  group('semantics (#226)', () {
    testWidgets('menu items expose label, button role and tap action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_menu()));
      await rightClick(tester);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Cut')),
        isSemantics(
          label: 'Cut',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Copy')),
        isSemantics(
          label: 'Copy',
          isButton: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('open menu across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'context_menu_open',
        containsText: true,
        size: const Size(280, 200),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (BuildContext context) => Align(
                alignment: Alignment.topLeft,
                child: CarbonContextMenu(
                  items: <Widget>[
                    CarbonMenuItem(label: 'Cut', onPressed: () {}),
                    CarbonMenuItem(label: 'Copy', onPressed: () {}),
                    CarbonMenuItem(label: 'Paste', onPressed: () {}),
                  ],
                  child: const SizedBox(
                    key: ValueKey<String>('target'),
                    width: 120,
                    height: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.tapAt(
            tester.getCenter(find.byKey(const ValueKey<String>('target'))),
            buttons: kSecondaryButton,
          );
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
