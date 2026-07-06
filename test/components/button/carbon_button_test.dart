// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// The component testing template: spec-lock tests cite the upstream SCSS
// they assert; the state matrix drives real pointer/keyboard input through
// CarbonInteraction; goldens cover the four themes.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child, {CarbonThemeData? theme}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: theme ?? CarbonThemeData.white,
    child: Center(child: child),
  ),
);

BoxDecoration _decorationOf(WidgetTester tester) {
  final AnimatedContainer container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(CarbonButton),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

Color? _textColorOf(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('motion', () {
    testWidgets('fill tokens match button/_mixins.scss', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonButton(label: 'Go', onPressed: () {})),
      );
      // background / box-shadow / border-color / outline $duration-fast-01
      // motion(entrance, productive).
      final AnimatedContainer fill = tester.widget(
        find.byType(AnimatedContainer),
      );
      expect(fill.duration, CarbonDuration.fast01);
      expect(fill.curve, CarbonEasing.entranceProductive);
    });

    testWidgets('reduced motion fills instantly', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: CarbonButton(label: 'Go', onPressed: () {}),
          ),
        ),
      );
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero,
      );
    });
  });

  group('spec locks (styles/scss/components/button)', () {
    testWidgets('heights per size (layout sizes, _button.scss)', (
      WidgetTester tester,
    ) async {
      const Map<CarbonButtonSize, double> heights = <CarbonButtonSize, double>{
        CarbonButtonSize.xs: 24,
        CarbonButtonSize.sm: 32,
        CarbonButtonSize.md: 40,
        CarbonButtonSize.lg: 48,
        CarbonButtonSize.xl: 64,
        CarbonButtonSize.xxl: 80,
      };
      for (final MapEntry<CarbonButtonSize, double> entry in heights.entries) {
        await tester.pumpWidget(
          _host(CarbonButton(label: 'B', size: entry.key, onPressed: () {})),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(CarbonButton)).height,
          entry.value,
          reason: '${entry.key}',
        );
      }
    });

    testWidgets('label inset and vertical alignment (_mixins.scss '
        'padding-block: centered to lg, capped above)', (
      WidgetTester tester,
    ) async {
      Future<double> labelTop(CarbonButtonSize size) async {
        await tester.pumpWidget(
          _host(CarbonButton(label: 'B', size: size, onPressed: () {})),
        );
        await tester.pumpAndSettle();
        final Offset button = tester.getTopLeft(find.byType(CarbonButton));
        final Offset label = tester.getTopLeft(find.text('B'));
        expect(label.dx - button.dx, 16, reason: 'start inset = 1 + 15');
        return label.dy - tester.getTopLeft(find.byType(CarbonButton)).dy;
      }

      // border 1 + min((H − 18)/2 − 1, 14); xs adds 1.5. The 18px line is
      // 14 × 1.28572 = 18.00008, hence the tolerance — same float CSS computes.
      expect(await labelTop(CarbonButtonSize.lg), closeTo(15, 0.001));
      expect(await labelTop(CarbonButtonSize.xl), closeTo(15, 0.001));
      expect(await labelTop(CarbonButtonSize.xxl), closeTo(15, 0.001));
      expect(await labelTop(CarbonButtonSize.md), closeTo(11, 0.001));
      expect(await labelTop(CarbonButtonSize.sm), closeTo(7, 0.001));
      // xs replaces padding-block-start with a flat 1.5px (+1 border).
      expect(await labelTop(CarbonButtonSize.xs), closeTo(2.5, 0.001));
    });

    testWidgets('trailing icon geometry (_mixins.scss .cds--btn__icon)', (
      WidgetTester tester,
    ) async {
      Future<(double, double)> iconOffsets(CarbonButtonSize size) async {
        await tester.pumpWidget(
          _host(
            CarbonButton(
              label: 'B',
              size: size,
              icon: CarbonIcons.add,
              onPressed: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Rect button = tester.getRect(find.byType(CarbonButton));
        final Rect icon = tester.getRect(find.byType(CarbonIcon));
        return (button.right - icon.right, icon.top - button.top);
      }

      // Right inset 16 (15 padding + 1 border); centered ≤ lg, top 16 above.
      for (final (CarbonButtonSize size, double top)
          in <(CarbonButtonSize, double)>[
            (CarbonButtonSize.lg, 16),
            (CarbonButtonSize.md, 12),
            (CarbonButtonSize.xl, 16),
            (CarbonButtonSize.xxl, 16),
          ]) {
        final (double right, double actualTop) = await iconOffsets(size);
        expect(right, closeTo(16, 0.001), reason: '$size');
        expect(actualTop, closeTo(top, 0.001), reason: '$size');
      }
    });

    testWidgets('icon-only buttons are square', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonButton.iconOnly(
            icon: CarbonIcons.add,
            iconDescription: 'Add',
            onPressed: () {},
          ),
        ),
      );
      expect(tester.getSize(find.byType(CarbonButton)), const Size(48, 48));
    });

    testWidgets('max width is 320 (192 in sets is the set cap)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonButton(label: 'B' * 200, onPressed: () {})),
      );
      expect(tester.getSize(find.byType(CarbonButton)).width, 320);
    });

    test('label type style is body-compact-01', () {
      expect(CarbonButton.labelStyle, CarbonTypeStyles.bodyCompact01);
      expect(CarbonButton.labelStyle.fontSize, 14);
      expect(CarbonButton.labelStyle.fontWeight, FontWeight.w400);
    });

    testWidgets('rest border is 1px (the 2px var is the focus inset only)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonButton(
            label: 'B',
            kind: CarbonButtonKind.tertiary,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).border!.top.width, 1);
    });
  });

  group('kind × state token matrix (_button.scss button-theme calls)', () {
    final CarbonThemeData theme = CarbonThemeData.white;

    Future<void> pump(
      WidgetTester tester,
      CarbonButtonKind kind, {
      bool enabled = true,
    }) {
      return tester
          .pumpWidget(
            _host(
              CarbonButton(
                label: 'B',
                kind: kind,
                onPressed: enabled ? () {} : null,
              ),
            ),
          )
          .then((_) => tester.pumpAndSettle());
    }

    testWidgets('rest colors per kind', (WidgetTester tester) async {
      const Color transparent = Color(0x00000000);

      await pump(tester, CarbonButtonKind.primary);
      expect(_decorationOf(tester).color, theme.buttonPrimary);
      expect(_textColorOf(tester, 'B'), theme.textOnColor);

      await pump(tester, CarbonButtonKind.secondary);
      expect(_decorationOf(tester).color, theme.buttonSecondary);

      await pump(tester, CarbonButtonKind.tertiary);
      expect(_decorationOf(tester).color, transparent);
      expect(_decorationOf(tester).border!.top.color, theme.buttonTertiary);
      expect(_textColorOf(tester, 'B'), theme.buttonTertiary);

      await pump(tester, CarbonButtonKind.ghost);
      expect(_decorationOf(tester).color, transparent);
      expect(_textColorOf(tester, 'B'), theme.linkPrimary);

      await pump(tester, CarbonButtonKind.danger);
      expect(_decorationOf(tester).color, theme.buttonDangerPrimary);

      await pump(tester, CarbonButtonKind.dangerTertiary);
      expect(
        _decorationOf(tester).border!.top.color,
        theme.buttonDangerSecondary,
      );
      expect(_textColorOf(tester, 'B'), theme.buttonDangerSecondary);

      await pump(tester, CarbonButtonKind.dangerGhost);
      expect(_textColorOf(tester, 'B'), theme.buttonDangerSecondary);
    });

    testWidgets('hover state', (WidgetTester tester) async {
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);

      await pump(tester, CarbonButtonKind.primary);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CarbonButton)),
      );
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonPrimaryHover);

      await pump(tester, CarbonButtonKind.tertiary);
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonTertiaryHover);
      expect(_textColorOf(tester, 'B'), theme.textInverse);

      await pump(tester, CarbonButtonKind.ghost);
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.backgroundHover);
      expect(_textColorOf(tester, 'B'), theme.linkPrimaryHover);

      await pump(tester, CarbonButtonKind.dangerGhost);
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonDangerHover);
      expect(_textColorOf(tester, 'B'), theme.textOnColor);
    });

    testWidgets('pressed state', (WidgetTester tester) async {
      await pump(tester, CarbonButtonKind.primary);
      final TestGesture press = await tester.startGesture(
        tester.getCenter(find.byType(CarbonButton)),
      );
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonPrimaryActive);
      await press.up();
    });

    testWidgets('pressed fills for the remaining kinds', (
      WidgetTester tester,
    ) async {
      Future<void> pressAndExpect(
        CarbonButtonKind kind,
        Color color, {
        Color? text,
      }) async {
        await pump(tester, kind);
        final TestGesture press = await tester.startGesture(
          tester.getCenter(find.byType(CarbonButton)),
        );
        await tester.pumpAndSettle();
        expect(_decorationOf(tester).color, color, reason: '$kind');
        if (text != null) {
          expect(_textColorOf(tester, 'B'), text, reason: '$kind');
        }
        await press.up();
        await tester.pumpAndSettle();
      }

      await pressAndExpect(
        CarbonButtonKind.secondary,
        theme.buttonSecondaryActive,
      );
      await pressAndExpect(
        CarbonButtonKind.tertiary,
        theme.buttonTertiaryActive,
        text: theme.textInverse,
      );
      await pressAndExpect(CarbonButtonKind.ghost, theme.backgroundActive);
      await pressAndExpect(CarbonButtonKind.danger, theme.buttonDangerActive);
      await pressAndExpect(
        CarbonButtonKind.dangerTertiary,
        theme.buttonDangerActive,
        text: theme.textOnColor,
      );
      await pressAndExpect(
        CarbonButtonKind.dangerGhost,
        theme.buttonDangerActive,
        text: theme.textOnColor,
      );
    });

    testWidgets('hover: secondary, danger, and danger--tertiary', (
      WidgetTester tester,
    ) async {
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);

      await pump(tester, CarbonButtonKind.secondary);
      await mouse.addPointer(
        location: tester.getCenter(find.byType(CarbonButton)),
      );
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonSecondaryHover);

      await pump(tester, CarbonButtonKind.danger);
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonDangerHover);

      await pump(tester, CarbonButtonKind.dangerTertiary);
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonDangerHover);
      expect(_decorationOf(tester).border!.top.color, theme.buttonDangerHover);
      expect(_textColorOf(tester, 'B'), theme.textOnColor);
    });

    testWidgets('focus: danger--tertiary fills; ghost icon-only keeps the '
        'single 1px inset ring', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonButton(
            label: 'B',
            kind: CarbonButtonKind.dangerTertiary,
            focusNode: node,
            onPressed: () {},
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonDangerPrimary);
      expect(_decorationOf(tester).border!.top.color, theme.focus);
      expect(_textColorOf(tester, 'B'), theme.textOnColor);

      final FocusNode ghostNode = FocusNode();
      addTearDown(ghostNode.dispose);
      await tester.pumpWidget(
        _host(
          CarbonButton.iconOnly(
            icon: CarbonIcons.add,
            iconDescription: 'Add',
            kind: CarbonButtonKind.ghost,
            focusNode: ghostNode,
            onPressed: () {},
          ),
        ),
      );
      ghostNode.requestFocus();
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.backgroundActive);
      // `_button.scss`: ghost icon-only focus keeps the transparent border
      // (no square focus border) and paints only the single inset ring.
      expect(_decorationOf(tester).border!.top.color, const Color(0x00000000));
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CarbonButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(container.foregroundDecoration, isNotNull);
    });

    testWidgets('keyboard focus: border + double inset ring; tertiary '
        'fills', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(CarbonButton(label: 'B', focusNode: node, onPressed: () {})),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).border!.top.color, theme.focus);
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CarbonButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(container.foregroundDecoration, isNotNull);

      final FocusNode tertiaryNode = FocusNode();
      addTearDown(tertiaryNode.dispose);
      await tester.pumpWidget(
        _host(
          CarbonButton(
            label: 'B',
            kind: CarbonButtonKind.tertiary,
            focusNode: tertiaryNode,
            onPressed: () {},
          ),
        ),
      );
      tertiaryNode.requestFocus();
      await tester.pumpAndSettle();
      expect(_decorationOf(tester).color, theme.buttonTertiary);
      expect(_textColorOf(tester, 'B'), theme.textInverse);
    });

    testWidgets('disabled: solid kinds fill buttonDisabled, transparent '
        'kinds keep transparency (tertiary keeps its border)', (
      WidgetTester tester,
    ) async {
      const Color transparent = Color(0x00000000);

      await pump(tester, CarbonButtonKind.primary, enabled: false);
      expect(_decorationOf(tester).color, theme.buttonDisabled);
      expect(_textColorOf(tester, 'B'), theme.textOnColorDisabled);

      await pump(tester, CarbonButtonKind.tertiary, enabled: false);
      expect(_decorationOf(tester).color, transparent);
      expect(_decorationOf(tester).border!.top.color, theme.buttonDisabled);
      expect(_textColorOf(tester, 'B'), theme.textDisabled);

      await pump(tester, CarbonButtonKind.ghost, enabled: false);
      expect(_decorationOf(tester).color, transparent);
      expect(_decorationOf(tester).border!.top.color, transparent);
      expect(_textColorOf(tester, 'B'), theme.textDisabled);
    });

    testWidgets('ghost icon color is iconPrimary while enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonButton(
            label: 'B',
            kind: CarbonButtonKind.ghost,
            icon: CarbonIcons.add,
            onPressed: () {},
          ),
        ),
      );
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CarbonIcon),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((paint.painter! as CarbonIconPainter).color, theme.iconPrimary);
    });
  });

  group('interaction & semantics', () {
    testWidgets('tap and keyboard activate; disabled does not', (
      WidgetTester tester,
    ) async {
      int pressed = 0;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonButton(
            label: 'Go',
            focusNode: node,
            onPressed: () => pressed++,
          ),
        ),
      );
      await tester.tap(find.byType(CarbonButton));
      expect(pressed, 1);
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(pressed, 2);

      await tester.pumpWidget(
        _host(const CarbonButton(label: 'Go', onPressed: null)),
      );
      await tester.tap(find.byType(CarbonButton));
      expect(pressed, 2);
    });

    testWidgets('button semantics; icon-only exposes its description', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonButton.iconOnly(
            icon: CarbonIcons.add,
            iconDescription: 'Add item',
            onPressed: () {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Add item')),
        isSemantics(label: 'Add item', isButton: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonButton(label: 'Go', onPressed: () {})),
      );
      await tester.pumpAndSettle();
      // Only the default lg (48px) is gated; xs/sm/md are 24/32/40px by
      // design (`_button.scss` layout.use('size') heights), so 48dp is
      // unattainable there.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('CarbonButtonSet (_button.scss .cds--btn-set)', () {
    testWidgets('equal widths capped at 196 with a 1px separator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 500,
            child: CarbonButtonSet(
              children: <CarbonButton>[
                CarbonButton(
                  label: 'Cancel',
                  kind: CarbonButtonKind.secondary,
                  onPressed: () {},
                ),
                CarbonButton(label: 'Save', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      final Size first = tester.getSize(find.byType(CarbonButton).first);
      final Size last = tester.getSize(find.byType(CarbonButton).last);
      expect(first.width, 196);
      expect(last.width, 196);
      final ColoredBox separator = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(CarbonButtonSet),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(separator.color, CarbonThemeData.white.buttonSeparator);
    });

    testWidgets('disabled following button switches the separator color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 400,
            child: CarbonButtonSet(
              children: <CarbonButton>[
                CarbonButton(
                  label: 'Cancel',
                  kind: CarbonButtonKind.secondary,
                  onPressed: () {},
                ),
                const CarbonButton(label: 'Save', onPressed: null),
              ],
            ),
          ),
        ),
      );
      final ColoredBox separator = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(CarbonButtonSet),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(separator.color, CarbonThemeData.white.iconOnColorDisabled);
    });

    testWidgets('stacked lays buttons out vertically with a 1px separator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonButtonSet(
            stacked: true,
            children: <CarbonButton>[
              CarbonButton(
                label: 'Cancel',
                kind: CarbonButtonKind.secondary,
                onPressed: () {},
              ),
              CarbonButton(label: 'Save', onPressed: () {}),
            ],
          ),
        ),
      );
      final Rect first = tester.getRect(find.byType(CarbonButton).first);
      final Rect last = tester.getRect(find.byType(CarbonButton).last);
      expect(first.width, CarbonButtonSet.maxButtonWidth);
      expect(last.width, CarbonButtonSet.maxButtonWidth);
      expect(last.top, first.bottom + 1);
      final ColoredBox separator = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(CarbonButtonSet),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(separator.color, CarbonThemeData.white.buttonSeparator);

      // A disabled following button switches the stacked separator color.
      await tester.pumpWidget(
        _host(
          CarbonButtonSet(
            stacked: true,
            children: <CarbonButton>[
              CarbonButton(
                label: 'Cancel',
                kind: CarbonButtonKind.secondary,
                onPressed: () {},
              ),
              const CarbonButton(label: 'Save', onPressed: null),
            ],
          ),
        ),
      );
      final ColoredBox disabledSeparator = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(CarbonButtonSet),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(
        disabledSeparator.color,
        CarbonThemeData.white.layerSelectedDisabled,
      );
    });
  });

  group('goldens', () {
    testWidgets('kinds at rest across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'button_kinds',
        containsText: true,
        size: const Size(420, 260),
        builder: (BuildContext context) => Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CarbonButtonKind kind in CarbonButtonKind.values)
                CarbonButton(
                  label: kind.name,
                  kind: kind,
                  size: CarbonButtonSize.md,
                  onPressed: () {},
                ),
              const CarbonButton(label: 'disabled', onPressed: null),
            ],
          ),
        ),
      );
    });

    testWidgets('sizes and icons across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'button_sizes',
        containsText: true,
        size: const Size(360, 320),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final CarbonButtonSize size in CarbonButtonSize.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: CarbonButton(
                    label: size.name,
                    size: size,
                    icon: CarbonIcons.add,
                    onPressed: () {},
                  ),
                ),
            ],
          ),
        ),
      );
    });

    testWidgets('icon-only buttons across themes', (WidgetTester tester) async {
      // Icons are vector (platform-stable); no text glyphs here.
      await expectThemeGoldens(
        tester,
        name: 'button_icon_only',
        size: const Size(360, 90),
        builder: (BuildContext context) => Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CarbonButtonKind kind in <CarbonButtonKind>[
                CarbonButtonKind.primary,
                CarbonButtonKind.secondary,
                CarbonButtonKind.tertiary,
                CarbonButtonKind.ghost,
                CarbonButtonKind.danger,
              ])
                CarbonButton.iconOnly(
                  icon: CarbonIcons.add,
                  iconDescription: kind.name,
                  kind: kind,
                  onPressed: () {},
                ),
              const CarbonButton.iconOnly(
                icon: CarbonIcons.add,
                iconDescription: 'disabled',
                onPressed: null,
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('focused button shows the double inset ring', (
      WidgetTester tester,
    ) async {
      // The focus ring is custom-painted (border → focus + 1px + 2px inset);
      // the matrix tests assert its tokens, this golden pins its geometry.
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'button_focus',
        containsText: true,
        size: const Size(200, 100),
        builder: (BuildContext context) => Center(
          child: CarbonButton(
            label: 'Focused',
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

  group('expressive (_button.scss .cds--btn--expressive)', () {
    testWidgets('label is body-compact-02', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(CarbonButton(label: 'B', isExpressive: true, onPressed: () {})),
      );
      await tester.pumpAndSettle();
      final TextStyle style = tester.widget<Text>(find.text('B')).style!;
      expect(style.fontSize, 16);
      expect(style.height, 1.375);
    });

    testWidgets('padding-block: min((H − 22)/2 − 1, 14); no xs override', (
      WidgetTester tester,
    ) async {
      Future<double> labelTop(CarbonButtonSize size) async {
        await tester.pumpWidget(
          _host(
            CarbonButton(
              label: 'B',
              size: size,
              isExpressive: true,
              onPressed: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getTopLeft(find.text('B')).dy -
            tester.getTopLeft(find.byType(CarbonButton)).dy;
      }

      // +1px border in each expectation. The cap stays --temp-1lh based
      // (14px, from the default 18px line), so xl/2xl pin to 15.
      expect(await labelTop(CarbonButtonSize.lg), closeTo(13, 0.001));
      expect(await labelTop(CarbonButtonSize.xl), closeTo(15, 0.001));
      expect(await labelTop(CarbonButtonSize.xxl), closeTo(15, 0.001));
      expect(await labelTop(CarbonButtonSize.md), closeTo(9, 0.001));
      expect(await labelTop(CarbonButtonSize.sm), closeTo(5, 0.001));
      // The xs 1.5px padding-block-start class is dropped when expressive
      // (ButtonBase.tsx: `size === 'xs' && !isExpressive`).
      expect(await labelTop(CarbonButtonSize.xs), closeTo(1, 0.001));
    });

    testWidgets('icons render at 20px; the inset formula is unchanged', (
      WidgetTester tester,
    ) async {
      Future<(double, double)> iconOf({required bool expressive}) async {
        await tester.pumpWidget(
          _host(
            CarbonButton(
              label: 'B',
              icon: CarbonIcons.add,
              isExpressive: expressive,
              onPressed: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Finder icon = find.byType(CarbonIcon);
        return (
          tester.widget<CarbonIcon>(icon).size,
          tester.getTopLeft(icon).dy -
              tester.getTopLeft(find.byType(CarbonButton)).dy,
        );
      }

      final (double defaultSize, double defaultTop) = await iconOf(
        expressive: false,
      );
      final (double expressiveSize, double expressiveTop) = await iconOf(
        expressive: true,
      );
      expect(defaultSize, 16);
      expect(expressiveSize, 20);
      // `.cds--btn--expressive .cds--btn__icon` overrides only the icon
      // size; inset-block-start keeps the 16px-based formula.
      expect(expressiveTop, defaultTop);
    });

    testWidgets('ghost inline and icon-only icons are 20px too', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonButton(
            label: 'B',
            kind: CarbonButtonKind.ghost,
            icon: CarbonIcons.add,
            isExpressive: true,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<CarbonIcon>(find.byType(CarbonIcon)).size, 20);

      await tester.pumpWidget(
        _host(
          CarbonButton.iconOnly(
            icon: CarbonIcons.add,
            iconDescription: 'Add',
            isExpressive: true,
            onPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<CarbonIcon>(find.byType(CarbonIcon)).size, 20);
    });
  });

  group('link mode (ButtonBase.tsx href branch)', () {
    testWidgets('enabled link buttons expose link semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CarbonButton(label: 'Docs', link: true, onPressed: () {})),
      );
      await tester.pumpAndSettle();
      final SemanticsNode node = tester.getSemantics(find.text('Docs'));
      expect(node.flagsCollection.isLink, isTrue);
      expect(node.flagsCollection.isButton, isFalse);
      handle.dispose();
    });

    testWidgets('a disabled link keeps button semantics (href && !disabled)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonButton(label: 'Docs', link: true)),
      );
      await tester.pumpAndSettle();
      final SemanticsNode node = tester.getSemantics(find.text('Docs'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isLink, isFalse);
      handle.dispose();
    });

    testWidgets('link buttons activate like buttons', (
      WidgetTester tester,
    ) async {
      int presses = 0;
      await tester.pumpWidget(
        _host(
          CarbonButton(label: 'Docs', link: true, onPressed: () => presses++),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CarbonButton));
      expect(presses, 1);
    });
  });

  group('expressive goldens', () {
    testWidgets('expressive buttons across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'button_expressive',
        containsText: true,
        size: const Size(480, 180),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonButton(
                    label: 'Primary',
                    isExpressive: true,
                    icon: CarbonIcons.add,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 12),
                  CarbonButton(
                    label: 'Ghost',
                    kind: CarbonButtonKind.ghost,
                    isExpressive: true,
                    icon: CarbonIcons.arrowRight,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CarbonButton(
                label: 'Expressive md',
                size: CarbonButtonSize.md,
                isExpressive: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    });
  });
}
