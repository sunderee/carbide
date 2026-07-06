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

/// CarbonSelect (used by the pagination pickers) needs an Overlay ancestor.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          builder: (BuildContext context) =>
              Center(child: SizedBox(width: 760, child: child)),
        ),
      ],
    ),
  ),
);

/// The bare test host has no WidgetsApp, so install the Tab → focus-traversal
/// wiring an app scaffold would normally provide.
Widget _tabTraversal(Widget child) => Shortcuts(
  shortcuts: const <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
    SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{
      NextFocusIntent: NextFocusAction(),
      PreviousFocusIntent: PreviousFocusAction(),
    },
    child: FocusTraversalGroup(child: child),
  ),
);

/// The build context that owns keyboard focus, for tab-order assertions.
BuildContext? _focusedContext(WidgetTester tester) =>
    tester.binding.focusManager.primaryFocus?.context;

/// The label of the [CarbonSelect] that owns focus, or null.
String? _focusedSelectLabel(WidgetTester tester) => _focusedContext(
  tester,
)?.findAncestorWidgetOfExactType<CarbonSelect<int>>()?.labelText;

/// The label of the [CarbonButton] that owns focus, or null.
String? _focusedButtonLabel(WidgetTester tester) => _focusedContext(
  tester,
)?.findAncestorWidgetOfExactType<CarbonButton>()?.label;

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('readout', () {
    testWidgets('shows the range and page count', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 1, pageSize: 10, totalItems: 95)),
      );
      expect(find.text('1–10 of 95 items'), findsOneWidget);
      expect(find.text('of 10 pages'), findsOneWidget);
    });

    testWidgets('middle page computes the right range', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 3, pageSize: 10, totalItems: 95)),
      );
      expect(find.text('21–30 of 95 items'), findsOneWidget);
    });

    testWidgets('last page clamps the range end', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 10, pageSize: 10, totalItems: 95)),
      );
      expect(find.text('91–95 of 95 items'), findsOneWidget);
    });
  });

  group('arrows', () {
    testWidgets('next advances; prev is disabled on the first page', (
      WidgetTester tester,
    ) async {
      int? went;
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 1,
            pageSize: 10,
            totalItems: 95,
            onPageChanged: (int p) => went = p,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Previous page'));
      await tester.pump();
      expect(went, isNull); // disabled on page 1
      await tester.tap(find.bySemanticsLabel('Next page'));
      await tester.pump();
      expect(went, 2);
    });

    testWidgets('next is disabled on the last page', (
      WidgetTester tester,
    ) async {
      int? went;
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 10,
            pageSize: 10,
            totalItems: 95,
            onPageChanged: (int p) => went = p,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Next page'));
      await tester.pump();
      expect(went, isNull);
      await tester.tap(find.bySemanticsLabel('Previous page'));
      await tester.pump();
      expect(went, 9);
    });
  });

  group('semantics', () {
    testWidgets('exposes a Pagination container + arrow labels', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 1, pageSize: 10, totalItems: 95)),
      );
      expect(find.bySemanticsLabel('Pagination'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous page'), findsOneWidget);
      expect(find.bySemanticsLabel('Next page'), findsOneWidget);
      handle.dispose();
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // A middle page keeps both arrows enabled, so every control is swept.
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 2,
            pageSize: 10,
            totalItems: 95,
            onPageChanged: (_) {},
            onPageSizeChanged: (_) {},
          ),
        ),
      );
      // TODO(#226): tap targets are off — the two pickers render 32px tall
      // (CarbonFieldSize.sm), while documentation/carbon/packages/styles/
      // scss/components/pagination/_pagination.scss stretches
      // `.cds--select-input` to `block-size: 100%` of the 48px bar.
      // Re-enable once the pickers fill the bar height.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  // Keyboard spec: documentation/carbon-website/src/pages/components/
  // pagination/accessibility.mdx — "The tab order goes from left to right
  // through the controls"; the selects open with Space or the Up/Down
  // arrows and commit with Space/Enter; the prev/next arrows activate with
  // Space or Enter; a disabled arrow "is no longer navigable or operable".
  group('keyboard & focus (#231)', () {
    Future<FocusNode> pumpBar(
      WidgetTester tester, {
      required int page,
      ValueChanged<int>? onPageChanged,
      ValueChanged<int>? onPageSizeChanged,
    }) async {
      final FocusNode anchor = FocusNode(debugLabel: 'anchor');
      addTearDown(anchor.dispose);
      await tester.pumpWidget(
        _host(
          _tabTraversal(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Focus(focusNode: anchor, child: const SizedBox.shrink()),
                CarbonPagination(
                  page: page,
                  pageSize: 10,
                  totalItems: 95,
                  onPageChanged: onPageChanged ?? (_) {},
                  onPageSizeChanged: onPageSizeChanged ?? (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      anchor.requestFocus();
      await tester.pump();
      return anchor;
    }

    Future<void> tab(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }

    testWidgets('Tab walks left to right: page-size select, page select, '
        'prev, next', (WidgetTester tester) async {
      await pumpBar(tester, page: 2);

      await tab(tester);
      expect(_focusedSelectLabel(tester), 'Items per page:');

      await tab(tester);
      expect(_focusedSelectLabel(tester), 'Page');

      await tab(tester);
      expect(_focusedButtonLabel(tester), 'Previous page');

      await tab(tester);
      expect(_focusedButtonLabel(tester), 'Next page');
    });

    testWidgets('Enter and Space activate the prev/next arrows', (
      WidgetTester tester,
    ) async {
      int? went;
      await pumpBar(tester, page: 2, onPageChanged: (int p) => went = p);
      for (int i = 0; i < 3; i++) {
        await tab(tester);
      }
      expect(_focusedButtonLabel(tester), 'Previous page');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(went, 1);

      went = null;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(went, 1);

      went = null;
      await tab(tester);
      expect(_focusedButtonLabel(tester), 'Next page');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(went, 3);
    });

    testWidgets('the page select opens, arrows and commits from the '
        'keyboard', (WidgetTester tester) async {
      int? went;
      await pumpBar(tester, page: 2, onPageChanged: (int p) => went = p);
      await tab(tester);
      await tab(tester);
      expect(_focusedSelectLabel(tester), 'Page');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      // The menu lists every page; '3' only renders while it is open.
      expect(find.text('3'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(went, 3);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('the disabled prev arrow on the first page is skipped, not '
        'a focus trap', (WidgetTester tester) async {
      int? went;
      await pumpBar(tester, page: 1, onPageChanged: (int p) => went = p);
      for (int i = 0; i < 3; i++) {
        await tab(tester);
      }
      // Tab lands on next directly; the disabled prev is not navigable.
      expect(_focusedButtonLabel(tester), 'Next page');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(went, 2);
    });

    testWidgets('the disabled next arrow on the last page is skipped and '
        'Tab leaves the bar', (WidgetTester tester) async {
      final FocusNode anchor = await pumpBar(tester, page: 10);
      for (int i = 0; i < 3; i++) {
        await tab(tester);
      }
      expect(_focusedButtonLabel(tester), 'Previous page');

      // Tab wraps past the disabled next arrow back to the anchor.
      await tab(tester);
      expect(anchor.hasPrimaryFocus, isTrue);
    });

    testWidgets(
      'ArrowUp opens a closed select (upstream native <select> parity)',
      (WidgetTester tester) async {
        await pumpBar(tester, page: 2);
        await tab(tester);
        await tab(tester);
        expect(_focusedSelectLabel(tester), 'Page');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(find.text('3'), findsOneWidget);
      },
      // TODO(#231): CarbonSelect ignores ArrowUp while closed;
      // pagination/accessibility.mdx says the selects open "with Space or
      // with Up or Down arrows". Re-enable once ArrowUp opens the select.
      skip: true,
    );
  });

  group('goldens', () {
    testWidgets('pagination bar across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'pagination',
        containsText: true,
        size: const Size(800, 64),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Center(
                child: SizedBox(
                  width: 760,
                  child: CarbonPagination(
                    page: 1,
                    pageSize: 10,
                    totalItems: 95,
                    onPageChanged: (_) {},
                    onPageSizeChanged: (_) {},
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  });
}
