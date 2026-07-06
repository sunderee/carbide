// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/legibility.dart';

/// OverlayPortal needs an Overlay ancestor; TapRegion needs a surface.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) => Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),
                Center(child: child),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

/// Records text written to the system clipboard during a test.
void _mockClipboard(WidgetTester tester, void Function(String?) onSet) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'Clipboard.setData') {
        onSet((call.arguments as Map<Object?, Object?>)['text'] as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('layout / spec-lock', () {
    testWidgets('default size is 40px (md); sm 32; lg 48', (
      WidgetTester tester,
    ) async {
      // One pump: re-pumping a host with an Overlay does not swap its entry.
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: const <Widget>[
              CarbonCopyButton(
                key: ValueKey<String>('sm'),
                size: CarbonCopySize.sm,
              ),
              CarbonCopyButton(key: ValueKey<String>('md')),
              CarbonCopyButton(
                key: ValueKey<String>('lg'),
                size: CarbonCopySize.lg,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('sm'))),
        const Size(32, 32),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('md'))),
        const Size(40, 40),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('lg'))),
        const Size(48, 48),
      );
    });

    testWidgets('rest fill is the contextual layer token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonCopyButton()));
      final ColoredBox surface = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(CarbonCopy),
          matching: find.byType(ColoredBox),
        ),
      );
      // Root sits on layer 0 → layer01.
      expect(surface.color, CarbonThemeData.white.layer01);
    });

    testWidgets('renders the Copy icon, icon-primary when enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonCopyButton()));
      final CarbonIcon icon = tester.widget<CarbonIcon>(
        find.byType(CarbonIcon),
      );
      expect(icon.icon, CarbonIcons.copy);
      expect(icon.color, CarbonThemeData.white.iconPrimary);
    });

    testWidgets('disabled tints the icon icon-disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonCopyButton(enabled: false)));
      final CarbonIcon icon = tester.widget<CarbonIcon>(
        find.byType(CarbonIcon),
      );
      expect(icon.color, CarbonThemeData.white.iconDisabled);
    });

    testWidgets('focus ring is a 2px outline, shown only on focus', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(_host(CarbonCopyButton(focusNode: node)));

      CarbonFocusRing ring() =>
          tester.widget<CarbonFocusRing>(find.byType(CarbonFocusRing));
      expect(ring().thickness, 2);
      expect(ring().visible, isFalse);

      node.requestFocus();
      await tester.pumpAndSettle();
      expect(ring().visible, isTrue);
    });
  });

  group('copy + feedback', () {
    testWidgets('tap copies the value and calls onCopy', (
      WidgetTester tester,
    ) async {
      String? copied;
      bool called = false;
      _mockClipboard(tester, (String? value) => copied = value);

      await tester.pumpWidget(
        _host(
          CarbonCopyButton(value: 'token-value', onCopy: () => called = true),
        ),
      );
      await tester.tap(find.byType(CarbonCopyButton));
      await tester.pump();

      expect(copied, 'token-value');
      expect(called, isTrue);

      // Flush the pending feedback timer.
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets(
      'tap shows the feedback bubble, which fades after the timeout',
      (WidgetTester tester) async {
        await tester.pumpWidget(_host(const CarbonCopyButton()));
        expect(find.text('Copied!'), findsNothing);

        await tester.tap(find.byType(CarbonCopyButton));
        await tester.pumpAndSettle();
        expect(find.text('Copied!'), findsOneWidget);
        expectTextNotClipped(tester, find.text('Copied!'));

        await tester.pump(const Duration(milliseconds: 2100));
        await tester.pumpAndSettle();
        expect(find.text('Copied!'), findsNothing);
      },
    );

    testWidgets('a custom feedback message is shown', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonCopyButton(feedback: 'Copied to clipboard')),
      );
      await tester.tap(find.byType(CarbonCopyButton));
      await tester.pumpAndSettle();
      expect(find.text('Copied to clipboard'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('Enter and Space activate the button', (
      WidgetTester tester,
    ) async {
      for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.space,
      ]) {
        final FocusNode node = FocusNode();
        addTearDown(node.dispose);
        await tester.pumpWidget(_host(CarbonCopyButton(focusNode: node)));
        node.requestFocus();
        await tester.pump();

        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
        expect(find.text('Copied!'), findsOneWidget, reason: '$key activates');

        await tester.pump(const Duration(milliseconds: 2100));
      }
    });

    testWidgets('Escape dismisses the feedback', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(_host(CarbonCopyButton(focusNode: node)));
      node.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Copied!'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Copied!'), findsNothing);
    });

    testWidgets('disabled does not activate', (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(
        _host(CarbonCopyButton(enabled: false, onCopy: () => called = true)),
      );
      await tester.tap(find.byType(CarbonCopyButton));
      await tester.pumpAndSettle();
      expect(called, isFalse);
      expect(find.text('Copied!'), findsNothing);
    });
  });

  group('resting tooltip', () {
    testWidgets('hover shows the icon description', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonCopyButton()));
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(find.byType(CarbonCopyButton)));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(find.text('Copy to clipboard'), findsOneWidget);
    });

    testWidgets('keyboard focus shows the icon description', (
      WidgetTester tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(_host(CarbonCopyButton(focusNode: node)));
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Copy to clipboard'), findsOneWidget);
    });
  });

  group('semantics', () {
    testWidgets('is a labelled button with a tap action', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonCopyButton()));

      expect(find.bySemanticsLabel('Copy to clipboard'), findsOneWidget);
      final SemanticsData data = tester
          .getSemantics(find.byType(CarbonCopyButton))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('label reflects the feedback after activation', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonCopyButton()));
      await tester.tap(find.byType(CarbonCopyButton));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Copied!'), findsOneWidget);
      handle.dispose();
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // `_host`'s tap-outside backdrop is itself an unlabelled tap target,
      // so pump the same shell without the backdrop.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TapRegionSurface(
            child: CarbonTheme(
              data: CarbonThemeData.white,
              child: Overlay(
                initialEntries: <OverlayEntry>[
                  OverlayEntry(
                    builder: (BuildContext context) =>
                        const Center(child: CarbonCopyButton()),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // The default md button is a 40px square (CarbonCopySize.md; upstream
      // the copy button fills its 40px single-line snippet row —
      // `_code-snippet.scss` `block-size: $spacing-08`), so the 48dp android
      // guideline is unattainable at the default size.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    Widget overlaid(Widget child) => Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(builder: (BuildContext context) => Center(child: child)),
      ],
    );

    testWidgets('copy button at rest (layer 0)', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'copy_button',
        size: const Size(96, 96),
        builder: (BuildContext context) => overlaid(const CarbonCopyButton()),
      );
    });

    testWidgets('copy button at rest (layer 1)', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'copy_button_layer1',
        size: const Size(96, 96),
        builder: (BuildContext context) =>
            overlaid(const CarbonLayer(child: CarbonCopyButton())),
      );
    });

    testWidgets('copy button focus ring', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await expectThemeGoldens(
        tester,
        name: 'copy_button_focus',
        size: const Size(96, 96),
        builder: (BuildContext context) =>
            overlaid(CarbonCopyButton(focusNode: node)),
        afterPump: (WidgetTester tester) async {
          node.requestFocus();
          await tester.pumpAndSettle();
        },
      );
    });

    testWidgets('copy button feedback bubble', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'copy_button_feedback',
        containsText: true,
        size: const Size(160, 140),
        builder: (BuildContext context) => overlaid(const CarbonCopyButton()),
        afterPump: (WidgetTester tester) async {
          await tester.tap(find.byType(CarbonCopyButton));
          await tester.pumpAndSettle();
        },
      );
      // Flush the last variant's pending feedback timer.
      await tester.pump(const Duration(milliseconds: 2100));
    });
  });
}
