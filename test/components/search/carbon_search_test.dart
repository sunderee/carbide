// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

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
    child: Center(child: SizedBox(width: 320, child: child)),
  ),
);

double _clearOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('anatomy', () {
    testWidgets('magnifier + placeholder; field height per size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonSearch()));
      expect(find.text('Search'), findsOneWidget); // placeholder
      expect(find.byType(EditableText), findsOneWidget);
      // search + (hidden) close icon.
      expect(find.byType(CarbonIcon), findsNWidgets(2));

      final double height = tester
          .getSize(
            find
                .ancestor(
                  of: find.byType(EditableText),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .height;
      expect(height, 40);

      await tester.pumpWidget(
        _host(const CarbonSearch(size: CarbonFieldSize.sm)),
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.byType(EditableText),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .height,
        32,
      );
    });
  });

  group('clear button', () {
    testWidgets('hidden when empty, shown with content; clears on tap', (
      WidgetTester tester,
    ) async {
      int cleared = 0;
      String? last;
      await tester.pumpWidget(
        _host(
          CarbonSearch(
            initialValue: 'query',
            onChanged: (String v) => last = v,
            onClear: () => cleared++,
          ),
        ),
      );
      expect(_clearOpacity(tester), 1);

      // Tap the clear (last) icon.
      await tester.tap(find.byType(CarbonIcon).last);
      await tester.pump();
      expect(cleared, 1);
      expect(last, '');
      expect(_clearOpacity(tester), 0);
      // Placeholder returns once empty.
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('typing reports the query', (WidgetTester tester) async {
      String? last;
      await tester.pumpWidget(
        _host(CarbonSearch(onChanged: (String v) => last = v)),
      );
      await tester.enterText(find.byType(EditableText), 'flutter');
      await tester.pump();
      expect(last, 'flutter');
      expect(_clearOpacity(tester), 1);
    });
  });

  group('CarbonExpandableSearch', () {
    testWidgets('collapsed is a magnifier button; tap expands to a field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonExpandableSearch()));
      // Collapsed: no text field, just the magnifier button.
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(CarbonIcon), findsOneWidget);

      await tester.tap(find.byType(CarbonIcon));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('collapses on blur when empty', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CarbonExpandableSearch()));
      await tester.tap(find.byType(CarbonIcon));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      // Remove focus while empty → collapses.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('exposes an expand button label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonExpandableSearch()));
      expect(find.bySemanticsLabel('Expand search'), findsOneWidget);
      handle.dispose();
    });
  });

  group('keyboard (#231)', () {
    // Upstream: documentation/carbon-website/src/pages/components/search/
    // accessibility.mdx — users "press Enter to submit their text as a
    // search term, or they can press Esc to clear it"; for the expandable
    // variant "the user activates the icon-only button to reveal and put
    // focus into the search input". The Escape-collapse detail comes from
    // documentation/carbon/packages/react/src/components/ExpandableSearch/
    // ExpandableSearch.tsx (handleKeyDown collapses when empty).

    testWidgets('Escape clears the query and reports the change', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController(
        text: 'query',
      );
      addTearDown(controller.dispose);
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      String? last;
      int cleared = 0;
      await tester.pumpWidget(
        _host(
          CarbonSearch(
            controller: controller,
            focusNode: node,
            onChanged: (String v) => last = v,
            onClear: () => cleared++,
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(last, '');
      expect(cleared, 1);
      // The field keeps focus after clearing (Search.tsx clearInput).
      expect(node.hasFocus, isTrue);
    });

    testWidgets('Enter on the focused magnifier expands and moves focus '
        'into the field', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CarbonExpandableSearch()));
      Focus.of(tester.element(find.byType(CarbonIcon))).requestFocus();
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('Space on the focused magnifier expands too', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonExpandableSearch()));
      Focus.of(tester.element(find.byType(CarbonIcon))).requestFocus();
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('Escape collapses the expanded empty search', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonExpandableSearch()));
      await tester.tap(find.byType(CarbonIcon));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
      // Focus lands on the magnifier button (Search.tsx focuses the
      // expand button on Escape).
      expect(
        Focus.of(tester.element(find.byType(CarbonIcon))).hasPrimaryFocus,
        isTrue,
      );
    });
  });

  group('fluid + semantics', () {
    testWidgets('fluid puts the label inside a 64px box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonSearch(labelText: 'Find', fluid: true)),
      );
      expect(find.text('Find'), findsOneWidget);
      final double height = tester
          .getSize(
            find
                .ancestor(
                  of: find.byType(EditableText),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .height;
      expect(height, 64);
    });

    testWidgets('exposes a search text field with its label', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonSearch(labelText: 'Find')));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Find')),
        isSemantics(label: 'Find', isTextField: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // An initial value keeps the clear button visible for the sweep.
      await tester.pumpWidget(
        _host(const CarbonSearch(labelText: 'Find', initialValue: 'query')),
      );
      await tester.pumpAndSettle();
      // The md field and its clear button are 40px (`_search.scss`
      // `layout.use('size', $default: 'md')` sizing `block-size:
      // layout.size('height')`), so the 48dp android guideline is
      // unattainable at the default size.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('states + expandable across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'search_states',
        containsText: true,
        size: const Size(340, 220),
        builder: (BuildContext context) => const Center(
          child: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CarbonSearch(),
                SizedBox(height: 12),
                CarbonSearch(initialValue: 'Carbon'),
                SizedBox(height: 12),
                CarbonSearch(disabled: true, initialValue: 'Disabled'),
                SizedBox(height: 12),
                CarbonExpandableSearch(),
              ],
            ),
          ),
        ),
      );
    });
  });
}
