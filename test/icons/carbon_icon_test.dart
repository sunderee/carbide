// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

Widget _host(Widget child, {CarbonThemeData? theme}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: theme ?? CarbonThemeData.white,
    child: Center(child: child),
  ),
);

CarbonIconPainter _painterOf(WidgetTester tester) {
  final CustomPaint paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(CarbonIcon),
      matching: find.byType(CustomPaint),
    ),
  );
  return paint.painter! as CarbonIconPainter;
}

void main() {
  group('artworkFor selection', () {
    test('exact size match wins (hand-tuned artwork)', () {
      expect(CarbonIcons.apps.artworkFor(16).size, 16);
      expect(CarbonIcons.apps.artworkFor(32).size, 32);
    });

    test('misses scale down the smallest larger artwork', () {
      expect(CarbonIcons.apps.artworkFor(20).size, 32);
      expect(CarbonIcons.add.artworkFor(16).size, 32);
      expect(CarbonIcons.apps.artworkFor(12).size, 16);
    });

    test('sizes above the largest artwork scale it up', () {
      expect(CarbonIcons.add.artworkFor(64).size, 32);
    });

    test('glyph-only icons fall back to their glyph', () {
      expect(CarbonIcons.circleFill.artworkFor(16).size, isNull);
      expect(CarbonIcons.caution.artworkFor(32).size, isNull);
    });

    test('glyph artwork is never preferred over sized artwork', () {
      // caret--down has both a glyph and a 32 master.
      expect(CarbonIcons.caretDown.artworkFor(16).size, 32);
    });
  });

  group('value semantics', () {
    // Runtime construction: const instances are canonicalized, so == would
    // short-circuit on identity and never compare the fields.
    CarbonIconShape shapeOf(String d) => CarbonIconShape(d: d);
    CarbonIconArtwork artworkOf(int size) => CarbonIconArtwork(
      size: size,
      viewBoxWidth: size.toDouble(),
      viewBoxHeight: size.toDouble(),
      shapes: <CarbonIconShape>[shapeOf('M0 0H8V8H0Z')],
    );
    CarbonIconData dataOf(String name) =>
        CarbonIconData(name: name, artwork: <CarbonIconArtwork>[artworkOf(16)]);

    test('equal definitions are equal and share a hash code', () {
      expect(dataOf('box'), dataOf('box'));
      expect(dataOf('box').hashCode, dataOf('box').hashCode);
      expect(artworkOf(16), artworkOf(16));
      expect(artworkOf(16).hashCode, artworkOf(16).hashCode);
      expect(shapeOf('M0 0Z'), shapeOf('M0 0Z'));
      expect(shapeOf('M0 0Z').hashCode, shapeOf('M0 0Z').hashCode);
    });

    test('a differing field breaks equality', () {
      expect(dataOf('box'), isNot(dataOf('circle')));
      expect(artworkOf(16), isNot(artworkOf(20)));
      expect(shapeOf('M0 0Z'), isNot(shapeOf('M1 1Z')));
    });
  });

  group('layout', () {
    testWidgets('renders at the default productive size of 16', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonIcon(CarbonIcons.add)));
      expect(tester.getSize(find.byType(CarbonIcon)), const Size(16, 16));
    });

    testWidgets('renders at an explicit size', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonIcon(CarbonIcons.add, size: 24)),
      );
      expect(tester.getSize(find.byType(CarbonIcon)), const Size(24, 24));
    });
  });

  group('color', () {
    testWidgets('defaults to the theme iconPrimary token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_host(const CarbonIcon(CarbonIcons.add)));
      expect(_painterOf(tester).color, CarbonThemeData.white.iconPrimary);

      await tester.pumpWidget(
        _host(
          const CarbonIcon(CarbonIcons.add),
          theme: CarbonThemeData.gray100,
        ),
      );
      expect(_painterOf(tester).color, CarbonThemeData.gray100.iconPrimary);
    });

    testWidgets('an explicit color overrides the theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonIcon(CarbonIcons.add, color: CarbonColors.red60)),
      );
      expect(_painterOf(tester).color, CarbonColors.red60);
    });
  });

  group('semantics', () {
    testWidgets('decorative by default: absent from the semantics tree', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const CarbonIcon(CarbonIcons.add)));
      expect(find.bySemanticsLabel('add'), findsNothing);
      expect(tester.getSemantics(find.byType(CarbonIcon)).label, isEmpty);
      handle.dispose();
    });

    testWidgets('semanticLabel exposes a labeled image', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonIcon(CarbonIcons.add, semanticLabel: 'Add item')),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Add item'),
      );
      expect(node.label, 'Add item');
      expect(node.flagsCollection.isImage, isTrue);
      handle.dispose();
    });
  });

  group('painter', () {
    test('repaints only when artwork or color changes', () {
      final CarbonIconPainter base = CarbonIconPainter(
        artwork: CarbonIcons.add.artworkFor(16),
        color: CarbonColors.gray100,
      );
      expect(
        base.shouldRepaint(
          CarbonIconPainter(
            artwork: CarbonIcons.add.artworkFor(16),
            color: CarbonColors.gray100,
          ),
        ),
        isFalse,
      );
      expect(
        base.shouldRepaint(
          CarbonIconPainter(
            artwork: CarbonIcons.add.artworkFor(16),
            color: CarbonColors.blue60,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          CarbonIconPainter(
            artwork: CarbonIcons.misuse.artworkFor(16),
            color: CarbonColors.gray100,
          ),
        ),
        isTrue,
      );
    });
  });

  testWidgets('icon specimen across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'carbon_icon',
      size: const Size(168, 72),
      builder: (BuildContext context) => const Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CarbonIcon(CarbonIcons.add, size: 32),
            SizedBox(width: 8),
            CarbonIcon(CarbonIcons.misuse, size: 32),
            SizedBox(width: 8),
            CarbonIcon(CarbonIcons.logoWechat, size: 32),
            SizedBox(width: 8),
            CarbonIcon(CarbonIcons.apps, size: 16),
          ],
        ),
      ),
    );
  });
}
