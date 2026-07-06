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

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: child),
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

  group('spec locks (styles/scss/components/tile/_tile.scss)', () {
    testWidgets('minimum size 128×64 and 16px padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonTile(child: Text('T'))));
      expect(tester.getSize(find.byType(CarbonTile)), const Size(128, 64));
      final Offset inset =
          tester.getTopLeft(find.text('T')) -
          tester.getTopLeft(find.byType(CarbonTile));
      expect(inset, const Offset(16, 16));
    });

    testWidgets('clickable corner icon: 20px at 12px insets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonClickableTile(
            onPressed: () {},
            icon: CarbonIcons.arrowRight,
            child: const Text('T'),
          ),
        ),
      );
      final Rect tile = tester.getRect(find.byType(CarbonClickableTile));
      final Rect icon = tester.getRect(find.byType(CarbonIcon));
      expect(icon.width, 20);
      expect(tile.right - icon.right, 12);
      expect(tile.bottom - icon.bottom, 12);
    });

    testWidgets('corner icon/checkmark Stack does not clip the overflow', (
      WidgetTester tester,
    ) async {
      // Regression: the icon is inset 12px from the tile edge, which places it
      // 4px outside the Stack's content box. With the default Clip.hardEdge the
      // overflow was sliced off, rendering a cut-off "artifact".
      Stack iconStack() => tester.widget<Stack>(
        find
            .ancestor(of: find.byType(CarbonIcon), matching: find.byType(Stack))
            .first,
      );

      await tester.pumpWidget(
        _host(
          CarbonClickableTile(
            onPressed: () {},
            icon: CarbonIcons.arrowRight,
            child: const Text('T'),
          ),
        ),
      );
      expect(iconStack().clipBehavior, Clip.none);

      await tester.pumpWidget(
        _host(
          CarbonSelectableTile(
            selected: true,
            onChanged: (_) {},
            child: const Text('T'),
          ),
        ),
      );
      expect(iconStack().clipBehavior, Clip.none);
    });

    testWidgets('selectable checkmark: 16px at the 16px top/end insets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonSelectableTile(
            selected: true,
            onChanged: (_) {},
            child: const Text('T'),
          ),
        ),
      );
      final Rect tile = tester.getRect(find.byType(CarbonSelectableTile));
      final Rect icon = tester.getRect(find.byType(CarbonIcon));
      expect(icon.width, 16);
      // Upstream positions the checkmark 16px inside the padding box, which
      // sits within the 1px selection border: 17px from the outer edge.
      expect(tile.right - icon.right, 17);
      expect(icon.top - tile.top, 17);
    });
  });

  group('layer context (the first layer-contextual component)', () {
    testWidgets('tile fills layer01 at root and layer02 inside a layer', (
      WidgetTester tester,
    ) async {
      Color tileColor() {
        final Container container = tester.widget<Container>(
          find.descendant(
            of: find.byType(CarbonTile),
            matching: find.byType(Container),
          ),
        );
        return (container.constraints != null ? container.color : null)!;
      }

      await tester.pumpWidget(_host(const CarbonTile(child: Text('T'))));
      expect(tileColor(), theme.layer01);

      await tester.pumpWidget(
        _host(const CarbonLayer(child: CarbonTile(child: Text('T')))),
      );
      expect(tileColor(), theme.layer02);
    });

    testWidgets('clickable hover uses the contextual layerHover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonLayer(
            child: CarbonClickableTile(
              onPressed: () {},
              child: const Text('T'),
            ),
          ),
        ),
      );
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CarbonClickableTile)),
      );
      await tester.pumpAndSettle();
      // AnimatedContainer folds its `color:` into the decoration; inside one
      // layer the contextual hover token is layerHover02.
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (container.decoration! as BoxDecoration).color,
        theme.layerHover02,
      );
    });
  });

  group('CarbonClickableTile behaviour', () {
    testWidgets('activates on tap; disabled greys text and icon', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      await tester.pumpWidget(
        _host(
          CarbonClickableTile(
            onPressed: () => pressed++,
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.byType(CarbonClickableTile));
      expect(pressed, 1);

      await tester.pumpWidget(
        _host(
          const CarbonClickableTile(
            onPressed: null,
            icon: CarbonIcons.arrowRight,
            child: Text('Open'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Open'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(style.style.color, theme.textDisabled);
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CarbonIcon),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as CarbonIconPainter).color, theme.iconDisabled);
    });

    testWidgets('keyboard focus shows the inset focus outline', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonClickableTile(
            onPressed: () {},
            focusNode: node,
            child: const Text('T'),
          ),
        ),
      );
      CustomPaint ring() => tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CarbonFocusRing),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(ring().foregroundPainter, isNull);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(ring().foregroundPainter, isNotNull);
    });
  });

  group('CarbonSelectableTile behaviour', () {
    testWidgets('toggles; checkmark and border follow selection', (
      WidgetTester tester,
    ) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          CarbonSelectableTile(
            selected: false,
            onChanged: (bool v) => changed = v,
            child: const Text('T'),
          ),
        ),
      );
      // Unselected at rest: checkmark hidden.
      AnimatedOpacity checkmark() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(checkmark().opacity, 0);

      await tester.tap(find.byType(CarbonSelectableTile));
      expect(changed, isTrue);

      await tester.pumpWidget(
        _host(
          CarbonSelectableTile(
            selected: true,
            onChanged: (bool v) => changed = v,
            child: const Text('T'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(checkmark().opacity, 1);
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(
        (container.decoration! as BoxDecoration).border!.top.color,
        theme.layerSelectedInverse,
      );
      // `_tile.scss`: the selection border is `1px solid`.
      expect((container.decoration! as BoxDecoration).border!.top.width, 1);
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CarbonIcon),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as CarbonIconPainter).color, theme.iconPrimary);
      await tester.tap(find.byType(CarbonSelectableTile));
      expect(changed, isFalse);
    });

    testWidgets('exposes checked state to assistive technology', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonSelectableTile(
            selected: true,
            onChanged: (_) {},
            child: const Text('Option'),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Option')),
        isSemantics(isChecked: true, isEnabled: true),
      );
      handle.dispose();
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonClickableTile(
                onPressed: () {},
                child: const Text('Clickable'),
              ),
              const SizedBox(height: 8),
              CarbonSelectableTile(
                selected: false,
                onChanged: (_) {},
                child: const Text('Selectable'),
              ),
              const SizedBox(height: 8),
              CarbonRadioTile(
                selected: true,
                onSelected: () {},
                child: const Text('Radio'),
              ),
            ],
          ),
        ),
      );
      // Interactive tiles are 128×64 minimum (`_tile.scss`), comfortably
      // above the 48dp Android tap-target guideline.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens (layer 0 and layer 1, per the issue requirement)', () {
    Widget specimen(BuildContext context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 200,
            child: CarbonTile(child: Text('Static tile')),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: CarbonClickableTile(
              onPressed: () {},
              icon: CarbonIcons.arrowRight,
              child: const Text('Clickable tile'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 200,
            child: CarbonSelectableTile(
              selected: true,
              onChanged: (_) {},
              child: const Text('Selected tile'),
            ),
          ),
        ],
      ),
    );

    testWidgets('tiles at layer 0', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tile_layer0',
        containsText: true,
        size: const Size(260, 260),
        builder: specimen,
      );
    });

    testWidgets('tiles inside a CarbonLayer', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tile_layer1',
        containsText: true,
        size: const Size(260, 260),
        builder: (BuildContext context) =>
            CarbonLayer(child: Builder(builder: specimen)),
      );
    });

    testWidgets('focused clickable tile shows the inset focus ring', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'tile_focus',
        containsText: true,
        size: const Size(260, 120),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 200,
            child: CarbonClickableTile(
              onPressed: () {},
              focusNode: node,
              icon: CarbonIcons.arrowRight,
              child: const Text('Focused tile'),
            ),
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
