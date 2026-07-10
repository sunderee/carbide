// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/overlay_entries.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
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

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('composition / spec-lock', () {
    testWidgets('wraps an icon-only button in a tooltip', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonIconButton(
            icon: CarbonIcons.add,
            label: 'Add item',
            kind: CarbonButtonKind.ghost,
            size: CarbonButtonSize.sm,
            isSelected: true,
            onPressed: () {},
          ),
        ),
      );
      final CarbonTooltip tooltip = tester.widget<CarbonTooltip>(
        find.byType(CarbonTooltip),
      );
      expect(tooltip.label, 'Add item');
      final CarbonButton button = tester.widget<CarbonButton>(
        find.byType(CarbonButton),
      );
      expect(button.icon, CarbonIcons.add);
      expect(button.label, 'Add item');
      expect(button.kind, CarbonButtonKind.ghost);
      expect(button.size, CarbonButtonSize.sm);
      expect(button.isSelected, isTrue);
    });

    testWidgets('a null onPressed disables the button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonIconButton(icon: CarbonIcons.add, label: 'Add')),
      );
      expect(
        tester.widget<CarbonButton>(find.byType(CarbonButton)).onPressed,
        isNull,
      );
    });
  });

  group('behaviour', () {
    testWidgets('tap fires onPressed', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _host(
          CarbonIconButton(
            icon: CarbonIcons.add,
            label: 'Add',
            onPressed: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(CarbonButton));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('hover reveals the tooltip label', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonIconButton(
            icon: CarbonIcons.add,
            label: 'Add item',
            onPressed: () {},
          ),
        ),
      );
      expect(find.text('Add item'), findsNothing);
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(CarbonButton)));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('Add item'), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('is a button carrying the label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonIconButton(
            icon: CarbonIcons.add,
            label: 'Add item',
            onPressed: () {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Add item'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonIconButton(
            icon: CarbonIcons.add,
            label: 'Add item',
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The default lg icon button is a 48px square (CarbonButton.iconOnly).
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    Widget overlaid(Widget child) => Overlay(
      initialEntries: <OverlayEntry>[
        managedOverlayEntry(
          builder: (BuildContext context) => Center(child: child),
        ),
      ],
    );

    testWidgets('kinds', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'icon_button_kinds',
        size: const Size(320, 96),
        builder: (BuildContext context) => overlaid(
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final CarbonButtonKind kind in <CarbonButtonKind>[
                CarbonButtonKind.primary,
                CarbonButtonKind.secondary,
                CarbonButtonKind.tertiary,
                CarbonButtonKind.ghost,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: CarbonIconButton(
                    icon: CarbonIcons.add,
                    label: 'Add',
                    kind: kind,
                    onPressed: () {},
                  ),
                ),
            ],
          ),
        ),
      );
    });

    testWidgets('focus ring', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'icon_button_focus',
        size: const Size(96, 96),
        builder: (BuildContext context) => overlaid(
          CarbonIconButton(
            icon: CarbonIcons.add,
            label: 'Add',
            focusNode: node,
            onPressed: () {},
          ),
        ),
        afterPump: (WidgetTester tester) async {
          node.requestFocus();
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
