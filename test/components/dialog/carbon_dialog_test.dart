// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(builder: (BuildContext context) => child),
      ],
    ),
  ),
);

List<Widget> _slots({VoidCallback? onClose, Widget? body}) => <Widget>[
  CarbonDialogHeader(
    controls: CarbonDialogControls(
      children: <Widget>[CarbonDialogCloseButton(onPressed: onClose)],
    ),
    children: const <Widget>[
      CarbonDialogSubtitle('Account'),
      CarbonDialogTitle('Dialog title'),
    ],
  ),
  CarbonDialogBody(child: body ?? const Text('Body content.')),
];

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('visibility and dismissal', () {
    testWidgets('content shows only while open; Escape requests close', (
      WidgetTester tester,
    ) async {
      int closes = 0;
      late StateSetter set;
      bool open = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              set = setState;
              return CarbonDialog(
                open: open,
                onRequestClose: () => closes++,
                children: _slots(onClose: () => closes++),
              );
            },
          ),
        ),
      );
      expect(find.text('Dialog title'), findsNothing);
      set(() => open = true);
      await tester.pumpAndSettle();
      expect(find.text('Dialog title'), findsOneWidget);
      expect(find.text('Body content.'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closes, 1);
    });

    testWidgets('the close button fires; backdrop taps do NOT close', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int closes = 0;
      await tester.pumpWidget(
        _host(
          CarbonDialog(
            open: true,
            onRequestClose: () => closes++,
            children: _slots(onClose: () => closes++),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The native dialog element does not close on backdrop clicks.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(closes, 0);

      await tester.tap(find.bySemanticsLabel('Close'));
      expect(closes, 1);
      handle.dispose();
    });
  });

  group('modal vs non-modal (show()/showModal())', () {
    testWidgets('modal renders the overlay backdrop', (
      WidgetTester tester,
    ) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(
        _host(CarbonDialog(open: true, children: _slots())),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is ColoredBox && w.color == theme.overlay,
        ),
        findsOneWidget,
      );
    });

    testWidgets('non-modal has no backdrop and keeps the page interactive', (
      WidgetTester tester,
    ) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      int pagePresses = 0;
      await tester.pumpWidget(
        _host(
          Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.topLeft,
                child: CarbonButton(
                  label: 'Page action',
                  size: CarbonButtonSize.sm,
                  onPressed: () => pagePresses++,
                ),
              ),
              CarbonDialog(open: true, modal: false, children: _slots()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is ColoredBox && w.color == theme.overlay,
        ),
        findsNothing,
      );
      // The page behind stays clickable.
      await tester.tapAt(const Offset(30, 15));
      expect(pagePresses, 1);
    });
  });

  group('spec geometry (_dialog.scss)', () {
    testWidgets('width tiers: 84% under lg, capped at 48rem from xlg', (
      WidgetTester tester,
    ) async {
      // 800px viewport (>= md 672): 84% = 672.
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(CarbonDialog(open: true, children: _slots())),
      );
      await tester.pumpAndSettle();
      final Finder surface = find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration?)?.border is Border,
      );
      expect(tester.getSize(surface.first).width, closeTo(672, 0.001));
    });

    testWidgets('the 48rem cap applies on wide viewports', (
      WidgetTester tester,
    ) async {
      // 1600px (>= xlg 1312): 48% = 768 = the 48rem cap.
      await tester.binding.setSurfaceSize(const Size(1600, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(CarbonDialog(open: true, children: _slots())),
      );
      await tester.pumpAndSettle();
      final Finder surface = find.byWidgetPredicate(
        (Widget w) =>
            w is DecoratedBox &&
            (w.decoration as BoxDecoration?)?.border is Border,
      );
      expect(tester.getSize(surface.first).width, closeTo(768, 0.001));
    });

    testWidgets('slot styling: title, subtitle, footer buttons', (
      WidgetTester tester,
    ) async {
      final CarbonThemeData theme = CarbonThemeData.white;
      await tester.pumpWidget(
        _host(
          CarbonDialog(
            open: true,
            children: <Widget>[
              ..._slots(),
              CarbonDialogFooter(
                children: <Widget>[
                  CarbonButton(
                    label: 'Cancel',
                    kind: CarbonButtonKind.secondary,
                    size: CarbonButtonSize.xl,
                    onPressed: () {},
                  ),
                  CarbonButton(
                    label: 'Save',
                    size: CarbonButtonSize.xl,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final TextStyle title = tester
          .widget<Text>(find.text('Dialog title'))
          .style!;
      expect(title.fontSize, CarbonTypeStyles.heading03.fontSize);
      final TextStyle subtitle = tester
          .widget<Text>(find.text('Account'))
          .style!;
      expect(subtitle.fontSize, CarbonTypeStyles.label01.fontSize);
      expect(subtitle.color, theme.textSecondary);
      // Footer: 64px tall (`$spacing-10`).
      expect(tester.getSize(find.byType(CarbonDialogFooter)).height, 64);
    });

    testWidgets('a long body scrolls within the dialog max height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonDialog(
            open: true,
            children: _slots(
              body: Column(
                children: <Widget>[for (int i = 0; i < 60; i++) Text('Row $i')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final Finder scroll = find.descendant(
        of: find.byType(CarbonDialogBody),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scroll, findsOneWidget);
      final ScrollableState state = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)),
      );
      expect(state.position.maxScrollExtent, greaterThan(0));
    });
  });

  group('reduced motion', () {
    testWidgets('the dialog appears without the entrance transition', (
      WidgetTester tester,
    ) async {
      late StateSetter set;
      bool open = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: CarbonTheme(
              data: CarbonThemeData.white,
              child: Overlay(
                initialEntries: <OverlayEntry>[
                  OverlayEntry(
                    builder: (BuildContext context) => StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        set = setState;
                        return CarbonDialog(open: open, children: _slots());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      set(() => open = true);
      await tester.pump();
      await tester.pump();
      final AnimatedOpacity opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).last,
      );
      expect(opacity.duration, Duration.zero);
    });
  });

  group('motion spec locks (#235)', () {
    // Spec source: `_dialog.scss` — the `[open]` transitions (and the
    // `presence-dialog__enter` keyframes) run opacity + transform at
    // $duration-moderate-02 × motion(entrance, expressive); only the
    // entrance plays in Carbide (closing unmounts the overlay).
    testWidgets('entrance is moderate-02 × entrance-expressive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CarbonDialog(open: true, children: _slots())),
      );
      final AnimatedSlide slide = tester.widget<AnimatedSlide>(
        find.byType(AnimatedSlide),
      );
      expect(slide.duration, CarbonDuration.moderate02);
      expect(slide.curve, CarbonEasing.entranceExpressive);
      // The surface fade and the backdrop fade.
      for (final AnimatedOpacity fade in tester.widgetList<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      )) {
        expect(fade.duration, CarbonDuration.moderate02);
      }
    });

    // Spec source: `_dialog.scss` `--dialog__close`: transition
    // background-color $duration-fast-02 motion(standard, productive).
    testWidgets('close button hover tint is fast-02 × standard-productive; '
        'instant under reduced motion', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(CarbonDialog(open: true, children: _slots(onClose: () {}))),
      );
      final Finder button = find.descendant(
        of: find.byType(CarbonDialogCloseButton),
        matching: find.byType(AnimatedContainer),
      );
      expect(
        tester.widget<AnimatedContainer>(button).duration,
        CarbonDuration.fast02,
      );
      expect(
        tester.widget<AnimatedContainer>(button).curve,
        CarbonEasing.standardProductive,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _host(
            CarbonDialog(open: true, children: _slots(onClose: () {})),
          ),
        ),
      );
      expect(tester.widget<AnimatedContainer>(button).duration, Duration.zero);
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonDialog(
            open: true,
            children: <Widget>[
              ..._slots(onClose: () {}),
              CarbonDialogFooter(
                children: <Widget>[
                  CarbonButton(
                    label: 'Cancel',
                    kind: CarbonButtonKind.secondary,
                    size: CarbonButtonSize.xl,
                    onPressed: () {},
                  ),
                  CarbonButton(
                    label: 'Save',
                    size: CarbonButtonSize.xl,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The 48px close button (`--dialog__close`) and the 64px footer
      // buttons all clear the 48dp guideline; the backdrop is inert.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('modal dialog across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'dialog',
        containsText: true,
        size: const Size(760, 420),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => CarbonDialog(
                open: true,
                children: <Widget>[
                  CarbonDialogHeader(
                    controls: CarbonDialogControls(
                      children: <Widget>[
                        CarbonDialogCloseButton(onPressed: () {}),
                      ],
                    ),
                    children: const <Widget>[
                      CarbonDialogSubtitle('Account'),
                      CarbonDialogTitle('Update billing details'),
                    ],
                  ),
                  const CarbonDialogBody(
                    child: Text(
                      'Changing the billing contact updates every invoice '
                      'issued after the change.',
                    ),
                  ),
                  CarbonDialogFooter(
                    children: <Widget>[
                      CarbonButton(
                        label: 'Cancel',
                        kind: CarbonButtonKind.secondary,
                        size: CarbonButtonSize.xl,
                        onPressed: () {},
                      ),
                      CarbonButton(
                        label: 'Save',
                        size: CarbonButtonSize.xl,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
