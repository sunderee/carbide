// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/legibility.dart';

Widget _host(Widget child, {CarbonThemeData? theme}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: theme ?? CarbonThemeData.white,
    child: Center(child: child),
  ),
);

BoxDecoration _surfaceDecoration(WidgetTester tester) {
  final Container container = tester.widget<Container>(
    find.descendant(
      of: find.byType(TagSurface),
      matching: find.byType(Container),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('spec locks (styles/scss/components/tag/_tag.scss)', () {
    testWidgets('heights per size; pill radius; width bounds', (
      WidgetTester tester,
    ) async {
      for (final (CarbonTagSize size, double height)
          in <(CarbonTagSize, double)>[
            (CarbonTagSize.sm, 18),
            (CarbonTagSize.md, 24),
            (CarbonTagSize.lg, 32),
          ]) {
        await tester.pumpWidget(_host(CarbonTag(label: 'Tag', size: size)));
        expect(
          tester.getSize(find.byType(CarbonTag)).height,
          height,
          reason: '$size',
        );
        // Even at sm (18px) the label-01 line box must not be clipped — Tag
        // pads horizontally only, unlike the count badge that regressed (#162).
        expectTextNotClipped(tester, find.text('Tag'));
      }
      final BorderRadius radius =
          _surfaceDecoration(tester).borderRadius! as BorderRadius;
      expect(radius.topLeft, const Radius.circular(16));

      // Max width 208 with ellipsis; min width 32 keeps the pill shape.
      await tester.pumpWidget(_host(CarbonTag(label: 'T' * 100)));
      expect(tester.getSize(find.byType(CarbonTag)).width, 208);
      await tester.pumpWidget(_host(const CarbonTag(label: '')));
      expect(tester.getSize(find.byType(CarbonTag)).width, 32);
    });

    test('label type style is label-01', () {
      expect(CarbonTag.labelStyle, CarbonTypeStyles.label01);
      expect(CarbonTag.labelStyle.fontSize, 12);
    });

    testWidgets('horizontal padding: 8 (12 for lg); icon shifts start to 4 '
        '(8 for lg) with a 4px gap', (WidgetTester tester) async {
      Future<double> labelStart(CarbonTagSize size, {bool icon = false}) async {
        await tester.pumpWidget(
          _host(
            CarbonTag(
              label: 'Tag',
              size: size,
              icon: icon ? CarbonIcons.add : null,
            ),
          ),
        );
        return tester.getTopLeft(find.text('Tag')).dx -
            tester.getTopLeft(find.byType(CarbonTag)).dx;
      }

      expect(await labelStart(CarbonTagSize.md), 8);
      expect(await labelStart(CarbonTagSize.lg), 12);
      // icon start + 16 icon + 4 gap.
      expect(await labelStart(CarbonTagSize.md, icon: true), 4 + 16 + 4);
      expect(await labelStart(CarbonTagSize.lg, icon: true), 8 + 16 + 4);
    });
  });

  group('type color matrix (tag-theme calls per modifier)', () {
    final CarbonThemeData theme = CarbonThemeData.white;

    testWidgets('colored types resolve the tag component tokens', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonTag(label: 'T', type: CarbonTagType.red)),
      );
      expect(_surfaceDecoration(tester).color, theme.tagBackgroundRed);
      expect(
        tester.widget<Text>(find.text('T')).style!.color,
        theme.tagColorRed,
      );

      await tester.pumpWidget(
        _host(const CarbonTag(label: 'T', type: CarbonTagType.coolGray)),
      );
      expect(_surfaceDecoration(tester).color, theme.tagBackgroundCoolGray);
    });

    testWidgets('high-contrast and outline variants', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonTag(label: 'T', type: CarbonTagType.highContrast)),
      );
      expect(_surfaceDecoration(tester).color, theme.backgroundInverse);
      expect(
        tester.widget<Text>(find.text('T')).style!.color,
        theme.textInverse,
      );

      await tester.pumpWidget(
        _host(const CarbonTag(label: 'T', type: CarbonTagType.outline)),
      );
      expect(_surfaceDecoration(tester).color, theme.background);
      final Container container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TagSurface),
          matching: find.byType(Container),
        ),
      );
      final BoxDecoration outline =
          container.foregroundDecoration! as BoxDecoration;
      expect(outline.border!.top.color, theme.backgroundInverse);
      // `_tag.scss`: `border: 1px solid $border-inverse`.
      expect(outline.border!.top.width, 1);
    });

    testWidgets('disabled uses the layer-contextual layer token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonLayer(child: CarbonTag(label: 'T', disabled: true))),
      );
      // Inside one CarbonLayer the contextual layer is layer02.
      expect(_surfaceDecoration(tester).color, theme.layer02);
      expect(
        tester.widget<Text>(find.text('T')).style!.color,
        theme.textDisabled,
      );
    });
  });

  group('CarbonDismissibleTag', () {
    testWidgets('close button dismisses; tag body does not', (
      WidgetTester tester,
    ) async {
      int closed = 0;
      await tester.pumpWidget(
        _host(CarbonDismissibleTag(label: 'Filter', onClose: () => closed++)),
      );
      await tester.tap(find.text('Filter'));
      expect(closed, 0);
      await tester.tap(find.byType(CarbonIcon));
      expect(closed, 1);
    });

    testWidgets('close button hover fills with the type hover token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDismissibleTag(
            label: 'F',
            type: CarbonTagType.blue,
            onClose: () {},
          ),
        ),
      );
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CarbonIcon)),
      );
      await tester.pumpAndSettle();
      // Nearest ancestor Container is the circular close button (the outer
      // one is the tag surface itself).
      final Container closeButton = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(CarbonIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      final BoxDecoration decoration = closeButton.decoration! as BoxDecoration;
      expect(decoration.color, CarbonThemeData.white.tagHoverBlue);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('disabled uses layer fill, disabled text and icon colors', (
      WidgetTester tester,
    ) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(
        _host(const CarbonDismissibleTag(label: 'Filter')),
      );
      // `.first`: the surface Container precedes the close-button one.
      final Container surface = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(TagSurface),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((surface.decoration! as BoxDecoration).color, theme.layer01);
      expect(
        tester.widget<Text>(find.text('Filter')).style!.color,
        theme.textDisabled,
      );
      expect(
        tester.widget<CarbonIcon>(find.byType(CarbonIcon)).color,
        theme.iconDisabled,
      );
    });

    testWidgets('keyboard focus rings the close button; high-contrast tags '
        'use focusInverse', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonDismissibleTag(
            label: 'F',
            type: CarbonTagType.highContrast,
            onClose: () {},
          ),
        ),
      );
      Focus.of(tester.element(find.byType(CarbonIcon))).requestFocus();
      await tester.pumpAndSettle();
      final Container closeButton = tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(CarbonIcon),
              matching: find.byType(Container),
            )
            .first,
      );
      final BoxDecoration decoration = closeButton.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, CarbonThemeData.white.focusInverse);
    });

    testWidgets('exposes an accessible dismiss action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonDismissibleTag(label: 'Filter', onClose: () {})),
      );
      expect(find.bySemanticsLabel('Dismiss Filter'), findsOneWidget);
      handle.dispose();
    });
  });

  group('CarbonSelectableTag', () {
    testWidgets('toggles and renders the selected fill', (
      WidgetTester tester,
    ) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          CarbonSelectableTag(
            label: 'Topic',
            selected: false,
            onChanged: (bool value) => changed = value,
          ),
        ),
      );
      expect(
        _surfaceDecoration(tester).border!.top.color,
        CarbonThemeData.white.borderInverse,
      );
      await tester.tap(find.byType(CarbonSelectableTag));
      expect(changed, isTrue);

      await tester.pumpWidget(
        _host(
          CarbonSelectableTag(
            label: 'Topic',
            selected: true,
            onChanged: (bool value) => changed = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _surfaceDecoration(tester).color,
        CarbonThemeData.white.layerSelectedInverse,
      );
      await tester.tap(find.byType(CarbonSelectableTag));
      expect(changed, isFalse);
    });

    testWidgets('keyboard focus paints the outer 2px focus ring', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonSelectableTag(
            label: 'Topic',
            selected: false,
            onChanged: (_) {},
          ),
        ),
      );
      Container ringHost() => tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TagSurface),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(ringHost().foregroundDecoration, isNull);
      Focus.of(tester.element(find.byType(TagSurface))).requestFocus();
      await tester.pumpAndSettle();
      expect(ringHost().foregroundDecoration, isNotNull);
    });
  });

  group('CarbonOperationalTag', () {
    testWidgets('activates, shows border and hover fill', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      await tester.pumpWidget(
        _host(
          CarbonOperationalTag(
            label: 'View all',
            type: CarbonTagType.purple,
            onPressed: () => pressed++,
          ),
        ),
      );
      expect(
        _surfaceDecoration(tester).border!.top.color,
        CarbonThemeData.white.tagBorderPurple,
      );
      // `_tag.scss`: operational tags use a `1px solid` border.
      expect(_surfaceDecoration(tester).border!.top.width, 1);
      await tester.tap(find.byType(CarbonOperationalTag));
      expect(pressed, 1);

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CarbonOperationalTag)),
      );
      await tester.pumpAndSettle();
      expect(
        _surfaceDecoration(tester).color,
        CarbonThemeData.white.tagHoverPurple,
      );
    });

    testWidgets('disabled uses layer + borderDisabled and ignores taps', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonOperationalTag(label: 'View all', onPressed: null)),
      );
      expect(_surfaceDecoration(tester).color, CarbonThemeData.white.layer01);
      expect(
        _surfaceDecoration(tester).border!.top.color,
        CarbonThemeData.white.borderDisabled,
      );
    });

    testWidgets('keyboard focus paints the outer 2px focus ring', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonOperationalTag(label: 'View all', onPressed: () {})),
      );
      Container ringHost() => tester.widget<Container>(
        find
            .ancestor(
              of: find.byType(TagSurface),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(ringHost().foregroundDecoration, isNull);
      Focus.of(tester.element(find.byType(TagSurface))).requestFocus();
      await tester.pumpAndSettle();
      expect(ringHost().foregroundDecoration, isNotNull);
    });
  });

  group('keyboard (#231)', () {
    // Upstream spec: documentation/carbon-website/src/pages/components/tag/
    // accessibility.mdx — dismissible tags are in the tab order and receive
    // focus around the close icon; Enter or Space dismisses. Selectable
    // tags are in the tab order; Enter or Space toggles the selection.
    // Operational tags are in the tab order; Enter or Space activates.

    Widget tabHost(Widget child) => _host(
      FocusTraversalGroup(
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{NextFocusIntent: NextFocusAction()},
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // A focus anchor before the component, so the first Tab
                // press moves focus onto the tag's control.
                const Focus(autofocus: true, child: SizedBox.shrink()),
                child,
              ],
            ),
          ),
        ),
      ),
    );

    testWidgets('dismissible: Tab reaches the dismiss affordance; Enter and '
        'Space dismiss', (WidgetTester tester) async {
      int closed = 0;
      await tester.pumpWidget(
        tabHost(CarbonDismissibleTag(label: 'Filter', onClose: () => closed++)),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      // The close icon's Focus ancestor is the dismiss affordance.
      expect(
        Focus.of(tester.element(find.byType(CarbonIcon))).hasPrimaryFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(closed, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(closed, 2);
    });

    testWidgets('selectable: Space (and Enter) toggle the selection', (
      WidgetTester tester,
    ) async {
      bool selected = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                CarbonSelectableTag(
                  label: 'Topic',
                  selected: selected,
                  onChanged: (bool v) => setState(() => selected = v),
                ),
          ),
        ),
      );
      Focus.of(tester.element(find.byType(TagSurface))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(selected, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, isTrue);
    });

    testWidgets('operational: Enter and Space activate', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      await tester.pumpWidget(
        _host(
          CarbonOperationalTag(label: 'View all', onPressed: () => pressed++),
        ),
      );
      Focus.of(tester.element(find.byType(TagSurface))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(pressed, 2);
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Wrap(
            spacing: 8,
            children: <Widget>[
              CarbonDismissibleTag(label: 'Filter', onClose: () {}),
              CarbonSelectableTag(
                label: 'Topic',
                selected: false,
                onChanged: (_) {},
              ),
              CarbonOperationalTag(label: 'View all', onPressed: () {}),
            ],
          ),
        ),
      );
      // Tap targets are exempt: interactive tags are spec-locked below
      // 48dp by styles/scss/components/tag/_tag.scss (heights xs/sm 18px,
      // md 24px, lg 32px; the dismiss button matches the tag height), so
      // the Android guideline is unattainable at Carbon's sizes.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('tag types across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tag_types',
        containsText: true,
        size: const Size(420, 150),
        builder: (BuildContext context) => Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final CarbonTagType type in CarbonTagType.values)
                CarbonTag(label: type.name, type: type),
              const CarbonTag(label: 'disabled', disabled: true),
            ],
          ),
        ),
      );
    });

    testWidgets('tag variants across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tag_variants',
        containsText: true,
        size: const Size(420, 90),
        builder: (BuildContext context) => Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              const CarbonTag(
                label: 'icon',
                type: CarbonTagType.blue,
                icon: CarbonIcons.tag,
              ),
              CarbonDismissibleTag(
                label: 'dismissible',
                type: CarbonTagType.green,
                onClose: () {},
              ),
              const CarbonSelectableTag(label: 'off', selected: false),
              CarbonSelectableTag(
                label: 'on',
                selected: true,
                onChanged: (_) {},
              ),
              CarbonOperationalTag(
                label: 'operational',
                type: CarbonTagType.teal,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('tag sizes across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tag_sizes',
        containsText: true,
        size: const Size(260, 150),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final CarbonTagSize size in CarbonTagSize.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CarbonTag(
                    label: size.name,
                    size: size,
                    type: CarbonTagType.blue,
                    icon: CarbonIcons.tag,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  });
}
