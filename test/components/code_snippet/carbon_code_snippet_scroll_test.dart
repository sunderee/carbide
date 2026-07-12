// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Scroll behavior of the code snippet (#232), per `_code-snippet.scss`:
//  * single: `.cds--snippet--single .cds--snippet-container` has
//    `overflow-x: auto` and `pre { white-space: pre }` — long lines scroll
//    horizontally, never wrap;
//  * multi: `.cds--snippet--multi .cds--snippet-container` has
//    `max-block-size: 100%; overflow-y: auto` — the collapsed block is capped
//    at maxCollapsedRows × 16px rows and scrolls vertically; `pre` has
//    `overflow: auto` (horizontal scroll) unless `--wraptext` sets
//    `white-space: pre-wrap`.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// CarbonCopyButton uses a Popover; tests need an Overlay and a TapRegion
/// surface. The 240px-wide slot forces long lines to overflow horizontally.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) =>
                Center(child: SizedBox(width: 240, child: child)),
          ),
        ],
      ),
    ),
  ),
);

final Finder _verticalScroll = find.byWidgetPredicate(
  (Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.vertical,
);

final Finder _horizontalScroll = find.byWidgetPredicate(
  (Widget w) =>
      w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
);

const String _longLine =
    'flutter pub add carbide --dev --directory=examples/kitchen_sink';

/// 30 long rows: taller than the 15-row collapsed cap and wider than the
/// 240px slot.
final String _tallCode = List<String>.generate(
  30,
  (int i) => 'const int value${i + 1} = ${i + 1}; // a long trailing comment',
).join('\n');

void main() {
  group('single-line horizontal scroll', () {
    testWidgets('a long line scrolls horizontally; the copy button stays '
        'put', (WidgetTester tester) async {
      await tester.pumpWidget(_host(const CarbonCodeSnippet(code: _longLine)));
      expect(_horizontalScroll, findsOneWidget);

      final Offset codeBefore = tester.getTopLeft(find.text(_longLine));
      final Offset copyBefore = tester.getTopLeft(
        find.bySemanticsLabel('Copy to clipboard'),
      );

      await tester.drag(_horizontalScroll, const Offset(-80, 0));
      await tester.pumpAndSettle();

      // The code shifted left; the copy affordance sits outside the
      // scrollable region and did not move.
      expect(
        tester.getTopLeft(find.text(_longLine)).dx,
        lessThan(codeBefore.dx),
      );
      expect(
        tester.getTopLeft(find.bySemanticsLabel('Copy to clipboard')),
        copyBefore,
      );
    });
  });

  group('multi-line collapsed scroll', () {
    testWidgets('the collapsed block is capped at maxCollapsedRows x 16px '
        'and scrolls vertically', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonCodeSnippet(code: _tallCode, type: CarbonCodeSnippetType.multi),
        ),
      );
      // 15 default collapsed rows × the 16px Carbon row height.
      expect(
        tester.getSize(_verticalScroll).height,
        15 * CarbonCodeSnippet.rowHeight,
      );

      final Offset before = tester.getTopLeft(find.text(_tallCode));
      await tester.drag(_verticalScroll, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text(_tallCode)).dy, lessThan(before.dy));
    });

    testWidgets('long lines also scroll horizontally when not wrapping', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonCodeSnippet(code: _tallCode, type: CarbonCodeSnippetType.multi),
        ),
      );
      expect(_horizontalScroll, findsOneWidget);

      final Offset before = tester.getTopLeft(find.text(_tallCode));
      // The horizontal scroll view is as tall as the full code (480px), so
      // its center sits below the 240px collapsed viewport clip; drag from a
      // point inside the visible region instead.
      await tester.dragFrom(
        tester.getTopLeft(_verticalScroll) + const Offset(60, 60),
        const Offset(-80, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text(_tallCode)).dx, lessThan(before.dx));
    });

    testWidgets('wrapText drops the horizontal scrollable (`--wraptext` '
        'pre-wrap)', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonCodeSnippet(
            code: _tallCode,
            type: CarbonCodeSnippetType.multi,
            wrapText: true,
          ),
        ),
      );
      expect(_horizontalScroll, findsNothing);
      expect(tester.widget<Text>(find.text(_tallCode)).softWrap, isTrue);
    });
  });

  group('multi-line expanded scroll', () {
    testWidgets('show more removes the cap when maxExpandedRows is '
        'unbounded', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonCodeSnippet(code: _tallCode, type: CarbonCodeSnippetType.multi),
        ),
      );
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      // maxExpandedRows == 0 → the block grows to its content and the
      // vertical scrollable disappears.
      expect(_verticalScroll, findsNothing);
      expect(
        tester.getSize(find.text(_tallCode)).height,
        greaterThan(15 * CarbonCodeSnippet.rowHeight),
      );
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('a bounded maxExpandedRows keeps a taller scrolling '
        'viewport', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonCodeSnippet(
            code: _tallCode,
            type: CarbonCodeSnippetType.multi,
            maxExpandedRows: 20,
          ),
        ),
      );
      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(_verticalScroll).height,
        20 * CarbonCodeSnippet.rowHeight,
      );
    });
  });
}
