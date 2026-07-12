// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/legibility.dart';
import '../../support/overlay_entries.dart';

/// CarbonCopyButton / the inline chip use a Popover; tests need an Overlay and
/// a TapRegion surface.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
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

  const String code = 'flutter pub add carbide';

  group('layout / spec-lock', () {
    testWidgets('single is a 40px bar with mono code and a copy button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonCodeSnippet(code: code)));
      expect(tester.getSize(find.byType(CarbonCodeSnippet)).height, 40);
      final Text text = tester.widget<Text>(find.text(code));
      expect(text.style!.fontFamily, CarbonFontFamily.mono);
      expect(text.style!.color, CarbonThemeData.white.textPrimary);
      expect(find.byType(CarbonCopyButton), findsOneWidget);
    });

    testWidgets('inline is a rounded chip', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'npm i',
            type: CarbonCodeSnippetType.inline,
          ),
        ),
      );
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('npm i'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(4));
      expect(decoration.color, CarbonThemeData.white.layer01);
    });

    testWidgets('disabled greys the code and disables copy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonCodeSnippet(code: code, disabled: true)),
      );
      final Text text = tester.widget<Text>(find.text(code));
      expect(text.style!.color, CarbonThemeData.white.textDisabled);
      expect(
        tester.widget<CarbonCopyButton>(find.byType(CarbonCopyButton)).enabled,
        isFalse,
      );
    });

    testWidgets('hideCopyButton drops the copy button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonCodeSnippet(code: code, hideCopyButton: true)),
      );
      expect(find.byType(CarbonCopyButton), findsNothing);
    });
  });

  group('copy', () {
    testWidgets('single copies the code via the copy button', (
      WidgetTester tester,
    ) async {
      String? copied;
      _mockClipboard(tester, (String? value) => copied = value);
      await tester.pumpWidget(_host(const CarbonCodeSnippet(code: code)));
      await tester.tap(find.byType(CarbonCopyButton));
      await tester.pump();
      expect(copied, code);
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('inline copies on tap and shows feedback', (
      WidgetTester tester,
    ) async {
      String? copied;
      _mockClipboard(tester, (String? value) => copied = value);
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'npm i',
            type: CarbonCodeSnippetType.inline,
          ),
        ),
      );
      await tester.tap(find.text('npm i'));
      await tester.pumpAndSettle();
      expect(copied, 'npm i');
      expect(find.text('Copied!'), findsOneWidget);
      expectTextNotClipped(tester, find.text('Copied!'));
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('inline copies with Enter when focused', (
      WidgetTester tester,
    ) async {
      String? copied;
      _mockClipboard(tester, (String? value) => copied = value);
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'npm i',
            type: CarbonCodeSnippetType.inline,
          ),
        ),
      );
      Focus.of(tester.element(find.text('npm i'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(copied, 'npm i');
      expect(find.text('Copied!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('tapping outside dismisses the inline copy feedback', (
      WidgetTester tester,
    ) async {
      _mockClipboard(tester, (String? _) {});
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'npm i',
            type: CarbonCodeSnippetType.inline,
          ),
        ),
      );
      await tester.tap(find.text('npm i'));
      await tester.pumpAndSettle();
      expect(find.text('Copied!'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Copied!'), findsNothing);
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('hovering the inline chip shows the hover layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'npm i',
            type: CarbonCodeSnippetType.inline,
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      BoxDecoration chipDecoration() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('npm i'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;

      await gesture.moveTo(tester.getCenter(find.text('npm i')));
      await tester.pump();
      expect(chipDecoration().color, CarbonThemeData.white.layerHover01);

      await gesture.moveTo(Offset.zero);
      await tester.pump();
      expect(chipDecoration().color, CarbonThemeData.white.layer01);
    });
  });

  group('multi-line expand', () {
    Widget multi(int collapsed) => _host(
      CarbonCodeSnippet(
        code: 'a\nb\nc\nd\ne',
        type: CarbonCodeSnippetType.multi,
        maxCollapsedRows: collapsed,
      ),
    );

    testWidgets('no toggle when the content fits', (WidgetTester tester) async {
      await tester.pumpWidget(multi(10));
      expect(find.text('Show more'), findsNothing);
    });

    testWidgets('shows the toggle when the content overflows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(multi(2));
      expect(find.text('Show more'), findsOneWidget);
    });

    testWidgets('toggles between show more and show less', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(multi(2));
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();
      expect(find.text('Show less'), findsOneWidget);
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(find.text('Show more'), findsOneWidget);
    });

    testWidgets('Enter on the focused toggle expands to maxExpandedRows', (
      WidgetTester tester,
    ) async {
      bool hasCodeBox(double height) => find
          .byWidgetPredicate((Widget w) => w is SizedBox && w.height == height)
          .evaluate()
          .isNotEmpty;

      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'a\nb\nc\nd\ne\nf',
            type: CarbonCodeSnippetType.multi,
            maxCollapsedRows: 2,
            maxExpandedRows: 3,
            hideCopyButton: true,
          ),
        ),
      );
      // Collapsed: 2 rows * 16px.
      expect(hasCodeBox(32), isTrue);

      Focus.of(tester.element(find.text('Show more'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Show less'), findsOneWidget);
      // Expanded but still bounded: 3 rows * 16px.
      expect(hasCodeBox(48), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Show more'), findsOneWidget);
      expect(hasCodeBox(32), isTrue);
    });
  });

  group('keyboard (#231)', () {
    // Upstream: documentation/carbon-website/src/pages/components/
    // code-snippet/accessibility.mdx — "For all three variants, the code
    // snippet can be copied with Space or Enter" and "The multi-line's
    // buttons are reachable by Tab and activated with Space or Enter". The
    // show-more/less toggle's Enter/Space drive is covered in the
    // 'multi-line expand' group above; the inline chip's in 'copy'.

    Finder copyIcon() => find.descendant(
      of: find.byType(CarbonCopyButton),
      matching: find.byType(CarbonIcon),
    );

    testWidgets('Enter and Space on the focused copy button copy the code', (
      WidgetTester tester,
    ) async {
      final List<String?> copies = <String?>[];
      int notified = 0;
      _mockClipboard(tester, copies.add);
      await tester.pumpWidget(
        _host(CarbonCodeSnippet(code: code, onCopy: () => notified++)),
      );
      Focus.of(tester.element(copyIcon())).requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(copies, <String?>[code]);
      expect(notified, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(copies, <String?>[code, code]);
      expect(notified, 2);
      await tester.pump(const Duration(milliseconds: 2100));
    });

    testWidgets('the multi-line copy button also copies with Enter', (
      WidgetTester tester,
    ) async {
      String? copied;
      _mockClipboard(tester, (String? value) => copied = value);
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'a\nb\nc\nd\ne',
            type: CarbonCodeSnippetType.multi,
            maxCollapsedRows: 2,
          ),
        ),
      );
      Focus.of(tester.element(copyIcon())).requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(copied, 'a\nb\nc\nd\ne');
      await tester.pump(const Duration(milliseconds: 2100));
    });
  });

  group('semantics', () {
    testWidgets('inline chip is a labelled button', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippet(
            code: 'npm i',
            type: CarbonCodeSnippetType.inline,
          ),
        ),
      );
      expect(find.bySemanticsLabel('Copy to clipboard: npm i'), findsOneWidget);
      handle.dispose();
    });
  });

  group('skeleton', () {
    testWidgets('renders for single and multi', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CarbonCodeSnippetSkeleton()));
      expect(find.byType(CarbonCodeSnippetSkeleton), findsOneWidget);
      await tester.pumpWidget(
        _host(
          const CarbonCodeSnippetSkeleton(type: CarbonCodeSnippetType.multi),
        ),
      );
      expect(find.byType(CarbonCodeSnippetSkeleton), findsOneWidget);
    });

    testWidgets('multi skeleton shows three placeholder lines', (
      WidgetTester tester,
    ) async {
      // Built at runtime (non-const) in a fresh host: the shared Overlay host
      // keeps its first entry, so the multi variant needs its own pump.
      final CarbonCodeSnippetType type = CarbonCodeSnippetType.multi;
      await tester.pumpWidget(_host(CarbonCodeSnippetSkeleton(type: type)));
      expect(
        tester
            .widget<CarbonSkeletonText>(find.byType(CarbonSkeletonText))
            .lineCount,
        3,
      );
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // A backdrop-free host: `_host`'s full-screen tap catcher is test
      // scaffolding and would register as an unlabelled tappable node.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TapRegionSurface(
            child: CarbonTheme(
              data: CarbonThemeData.white,
              child: Overlay(
                initialEntries: <OverlayEntry>[
                  managedOverlayEntry(
                    builder: (BuildContext context) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(
                            width: 320,
                            child: CarbonCodeSnippet(code: code),
                          ),
                          const SizedBox(height: 8),
                          const CarbonCodeSnippet(
                            code: 'npm i',
                            type: CarbonCodeSnippetType.inline,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 320,
                            child: CarbonCodeSnippet(
                              code: 'a\nb\nc\nd\ne',
                              type: CarbonCodeSnippetType.multi,
                              maxCollapsedRows: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      // Tap targets are exempt: styles/scss/components/code-snippet/
      // _code-snippet.scss locks the single bar and its copy button to
      // `$spacing-08` (40px), the inline chip to 1.25rem (20px,
      // `--snippet--inline.--btn`), and the Show more toggle to a ~32px
      // ghost control, so 48dp is unattainable at Carbon's spec sizes.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    Widget overlaid(Widget child) => Overlay(
      initialEntries: <OverlayEntry>[
        managedOverlayEntry(
          builder: (BuildContext context) => Center(
            child: Padding(padding: const EdgeInsets.all(8), child: child),
          ),
        ),
      ],
    );

    testWidgets('single', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'code_snippet_single',
        containsText: true,
        size: const Size(360, 80),
        builder: (BuildContext context) => overlaid(
          const SizedBox(width: 320, child: CarbonCodeSnippet(code: code)),
        ),
      );
    });

    testWidgets('multi with expand', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'code_snippet_multi',
        containsText: true,
        size: const Size(360, 160),
        builder: (BuildContext context) => overlaid(
          const SizedBox(
            width: 320,
            child: CarbonCodeSnippet(
              code: 'line one\nline two\nline three\nline four',
              type: CarbonCodeSnippetType.multi,
              maxCollapsedRows: 2,
            ),
          ),
        ),
      );
    });

    testWidgets('inline', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'code_snippet_inline',
        containsText: true,
        size: const Size(160, 60),
        builder: (BuildContext context) => overlaid(
          const CarbonCodeSnippet(
            code: 'npm i',
            type: CarbonCodeSnippetType.inline,
          ),
        ),
      );
    });
  });
}
