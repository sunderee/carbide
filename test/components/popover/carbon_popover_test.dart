// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

/// OverlayPortal needs an Overlay ancestor; TapRegion.onTapOutside needs a
/// TapRegionSurface (a WidgetsApp would supply both in a real app).
///
/// [alignment] places the trigger inside the 800x600 test viewport, so
/// autoAlign tests can park it against an edge.
Widget _host(
  Widget child, {
  AlignmentGeometry alignment = Alignment.center,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          OverlayEntry(
            builder: (BuildContext context) => Stack(
              children: <Widget>[
                // A full-screen hittable backdrop so an outside tap reaches the
                // TapRegionSurface (a real app's scaffold provides this).
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),
                Align(alignment: alignment, child: child),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

/// A fixed-size trigger so positioning maths are deterministic.
Widget _trigger() => const SizedBox(
  key: ValueKey<String>('trigger'),
  width: 100,
  height: 40,
  child: ColoredBox(color: Color(0xFFCCCCCC)),
);

/// The bounds of the surface's background box.
Rect _surfaceRect(WidgetTester tester) => tester.getRect(
  find
      .ancestor(of: find.text('Body'), matching: find.byType(DecoratedBox))
      .first,
);

/// The bounds of the fixed-size trigger.
Rect _triggerRect(WidgetTester tester) =>
    tester.getRect(find.byKey(const ValueKey<String>('trigger')));

/// Pumps a closed popover, lets the trigger lay out, then opens it — the way
/// a real app does, so the surface builds with the trigger already measured.
Future<void> _pumpAndOpen(
  WidgetTester tester, {
  required CarbonPopoverAlignment align,
  bool autoAlign = false,
  AlignmentGeometry where = Alignment.center,
}) async {
  late StateSetter setOuter;
  bool open = false;
  await tester.pumpWidget(
    _host(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          setOuter = setState;
          return CarbonPopover(
            open: open,
            align: align,
            autoAlign: autoAlign,
            content: const Text('Body'),
            child: _trigger(),
          );
        },
      ),
      alignment: where,
    ),
  );
  setOuter(() => open = true);
  await tester.pumpAndSettle();
}

const Set<CarbonPopoverAlignment> _topSide = <CarbonPopoverAlignment>{
  CarbonPopoverAlignment.top,
  CarbonPopoverAlignment.topStart,
  CarbonPopoverAlignment.topEnd,
};
const Set<CarbonPopoverAlignment> _bottomSide = <CarbonPopoverAlignment>{
  CarbonPopoverAlignment.bottom,
  CarbonPopoverAlignment.bottomStart,
  CarbonPopoverAlignment.bottomEnd,
};
const Set<CarbonPopoverAlignment> _leftSide = <CarbonPopoverAlignment>{
  CarbonPopoverAlignment.left,
  CarbonPopoverAlignment.leftStart,
  CarbonPopoverAlignment.leftEnd,
};
const Set<CarbonPopoverAlignment> _startCross = <CarbonPopoverAlignment>{
  CarbonPopoverAlignment.topStart,
  CarbonPopoverAlignment.bottomStart,
  CarbonPopoverAlignment.leftStart,
  CarbonPopoverAlignment.rightStart,
};
const Set<CarbonPopoverAlignment> _endCross = <CarbonPopoverAlignment>{
  CarbonPopoverAlignment.topEnd,
  CarbonPopoverAlignment.bottomEnd,
  CarbonPopoverAlignment.leftEnd,
  CarbonPopoverAlignment.rightEnd,
};

/// The surface's background/border box is the DecoratedBox wrapping the body.
BoxDecoration _surfaceBox(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .ancestor(
                    of: find.text('Body'),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('surface chrome (_popover.scss)', () {
    testWidgets('radius 2px, layer background, drop shadow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPopover(
            open: true,
            content: Text('Body'),
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      final BoxDecoration box = _surfaceBox(tester);
      // $popover-border-radius: 2px.
      expect(box.borderRadius, BorderRadius.circular(2));
      // $popover-background-color: theme.$layer (white root → layer01).
      expect(box.color, theme.layer01);
      // drop-shadow(0 $spacing-01 $spacing-01 rgba(0, 0, 0, 0.2)); 2px.
      expect(box.boxShadow, isNotNull);
      expect(box.boxShadow!.single.offset, const Offset(0, 2));
      expect(box.boxShadow!.single.blurRadius, 2);
      expect(box.boxShadow!.single.color, const Color(0x33000000));
      // No border by default (the --border modifier is opt-in).
      expect(box.border, isNull);
    });

    testWidgets('max width 368px (23rem)', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonPopover(
            open: true,
            content: Text('Body'),
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      final ConstrainedBox clamp = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.text('Body'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(clamp.constraints.maxWidth, 368);
    });

    testWidgets('border modifier draws a 1px subtle outline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPopover(
            open: true,
            border: true,
            content: Text('Body'),
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      final Border border = _surfaceBox(tester).border! as Border;
      // outline: 1px solid $popover-border-color (border-subtle).
      expect(border.top.width, 1);
      expect(border.top.color, theme.borderSubtle00);
    });

    testWidgets('surfaceColor / surfaceBorderColor override the surface', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPopover(
            open: true,
            surfaceColor: Color(0xFF112233),
            surfaceBorderColor: Color(0xFF445566),
            content: Text('Body'),
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      final BoxDecoration box = _surfaceBox(tester);
      // The override fills the surface and forces a 1px border in its colour.
      expect(box.color, const Color(0xFF112233));
      final Border border = box.border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, const Color(0xFF445566));
    });

    testWidgets('high contrast swaps to inverse background + text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPopover(
            open: true,
            highContrast: true,
            content: Text('Body'),
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      expect(_surfaceBox(tester).color, theme.backgroundInverse);
      final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Body'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(style.style.color, theme.textInverse);
    });

    testWidgets('layer-contextual background inside a CarbonLayer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonLayer(
            child: CarbonPopover(
              open: true,
              content: Text('Body'),
              child: SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      );
      expect(_surfaceBox(tester).color, theme.layer02);
    });
  });

  group('caret (_popover.scss: 12px x 6px)', () {
    testWidgets('vertical placement caret is 12x6', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPopover(
            open: true,
            content: Text('Body'),
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.size == const Size(12, 6),
        ),
        findsOneWidget,
      );
    });

    testWidgets('horizontal placement caret is rotated to 6x12', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonPopover(
            open: true,
            align: CarbonPopoverAlignment.right,
            content: Text('Body'),
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.size == const Size(6, 12),
        ),
        findsOneWidget,
      );
    });

    testWidgets('caret:false removes it and closes the gap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            caret: false,
            content: const Text('Body'),
            child: _trigger(),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (Widget w) => w is CustomPaint && w.size == const Size(12, 6),
        ),
        findsNothing,
      );
      // No caret → no offset: the surface sits flush against the trigger.
      final double surfaceTop = tester
          .getRect(
            find
                .ancestor(
                  of: find.text('Body'),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .top;
      final double triggerBottom = tester
          .getRect(find.byKey(const ValueKey<String>('trigger')))
          .bottom;
      expect(surfaceTop, moreOrLessEquals(triggerBottom, epsilon: 0.5));
    });
  });

  group('placement geometry', () {
    Rect surfaceRect(WidgetTester tester) => tester.getRect(
      find
          .ancestor(of: find.text('Body'), matching: find.byType(DecoratedBox))
          .first,
    );
    Rect triggerRect(WidgetTester tester) =>
        tester.getRect(find.byKey(const ValueKey<String>('trigger')));

    testWidgets('bottom places the surface 10px below the trigger', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            content: const Text('Body'),
            child: _trigger(),
          ),
        ),
      );
      expect(
        surfaceRect(tester).top,
        moreOrLessEquals(triggerRect(tester).bottom + 10, epsilon: 0.5),
      );
    });

    testWidgets('top places the surface 10px above the trigger', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            align: CarbonPopoverAlignment.top,
            content: const Text('Body'),
            child: _trigger(),
          ),
        ),
      );
      expect(
        surfaceRect(tester).bottom,
        moreOrLessEquals(triggerRect(tester).top - 10, epsilon: 0.5),
      );
    });

    testWidgets('right places the surface 10px right of the trigger', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            align: CarbonPopoverAlignment.right,
            content: const Text('Body'),
            child: _trigger(),
          ),
        ),
      );
      expect(
        surfaceRect(tester).left,
        moreOrLessEquals(triggerRect(tester).right + 10, epsilon: 0.5),
      );
    });

    testWidgets('left places the surface 10px left of the trigger', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            align: CarbonPopoverAlignment.left,
            content: const Text('Body'),
            child: _trigger(),
          ),
        ),
      );
      expect(
        surfaceRect(tester).right,
        moreOrLessEquals(triggerRect(tester).left - 10, epsilon: 0.5),
      );
    });
  });

  group('open / close', () {
    testWidgets('content shows only when open', (WidgetTester tester) async {
      // Drive `open` through state inside one stable Overlay (its
      // initialEntries are honoured once, so re-pumping a fresh host wouldn't
      // update the entry).
      late StateSetter setOuter;
      bool open = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              setOuter = setState;
              return CarbonPopover(
                open: open,
                content: const Text('Body'),
                child: const SizedBox(width: 100, height: 40),
              );
            },
          ),
        ),
      );
      expect(find.text('Body'), findsNothing);

      setOuter(() => open = true);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);

      setOuter(() => open = false);
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsNothing);
    });

    testWidgets('outside tap requests close', (WidgetTester tester) async {
      int closes = 0;
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            onRequestClose: () => closes++,
            content: const Text('Body'),
            child: _trigger(),
          ),
        ),
      );
      // Tap far from both the trigger and the surface.
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(closes, 1);
    });

    testWidgets('Escape requests close', (WidgetTester tester) async {
      int closes = 0;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            onRequestClose: () => closes++,
            content: Focus(focusNode: node, child: const Text('Body')),
            child: _trigger(),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(closes, 1);
    });

    testWidgets('tapping inside the surface does not request close', (
      WidgetTester tester,
    ) async {
      int closes = 0;
      await tester.pumpWidget(
        _host(
          CarbonPopover(
            open: true,
            onRequestClose: () => closes++,
            content: const Text('Body'),
            child: _trigger(),
          ),
        ),
      );
      await tester.tap(find.text('Body'));
      await tester.pump();
      expect(closes, 0);
    });
  });

  group('alignment variants', () {
    for (final CarbonPopoverAlignment align in CarbonPopoverAlignment.values) {
      testWidgets('$align places the surface and caret', (
        WidgetTester tester,
      ) async {
        await _pumpAndOpen(tester, align: align);
        final Rect s = _surfaceRect(tester);
        final Rect t = _triggerRect(tester);

        // Main axis: the surface floats 10px off the named side.
        if (_topSide.contains(align)) {
          expect(s.bottom, moreOrLessEquals(t.top - 10, epsilon: 0.5));
        } else if (_bottomSide.contains(align)) {
          expect(s.top, moreOrLessEquals(t.bottom + 10, epsilon: 0.5));
        } else if (_leftSide.contains(align)) {
          expect(s.right, moreOrLessEquals(t.left - 10, epsilon: 0.5));
        } else {
          expect(s.left, moreOrLessEquals(t.right + 10, epsilon: 0.5));
        }

        // Cross axis: Start/End line the near edges up; plain values centre.
        final bool vertical =
            _topSide.contains(align) || _bottomSide.contains(align);
        if (_startCross.contains(align)) {
          if (vertical) {
            expect(s.left, moreOrLessEquals(t.left, epsilon: 0.5));
          } else {
            expect(s.top, moreOrLessEquals(t.top, epsilon: 0.5));
          }
        } else if (_endCross.contains(align)) {
          if (vertical) {
            expect(s.right, moreOrLessEquals(t.right, epsilon: 0.5));
          } else {
            expect(s.bottom, moreOrLessEquals(t.bottom, epsilon: 0.5));
          }
        }

        // The caret always points at the trigger centre on the cross axis
        // (via the Start/End edge inset, or by being centred on the surface).
        final Finder caret = find.byWidgetPredicate(
          (Widget w) =>
              w is CustomPaint &&
              w.size == (vertical ? const Size(12, 6) : const Size(6, 12)),
        );
        final Offset c = tester.getCenter(caret);
        if (vertical) {
          expect(c.dx, moreOrLessEquals(t.center.dx, epsilon: 0.5));
        } else {
          expect(c.dy, moreOrLessEquals(t.center.dy, epsilon: 0.5));
        }
      });
    }
  });

  group('autoAlign', () {
    for (final CarbonPopoverAlignment align in CarbonPopoverAlignment.values) {
      testWidgets('$align flips away from the viewport edge', (
        WidgetTester tester,
      ) async {
        // Park the trigger against the edge its surface would overflow.
        final Alignment where = _topSide.contains(align)
            ? Alignment.topCenter
            : _bottomSide.contains(align)
            ? Alignment.bottomCenter
            : _leftSide.contains(align)
            ? Alignment.centerLeft
            : Alignment.centerRight;
        await _pumpAndOpen(tester, align: align, autoAlign: true, where: where);
        final Rect s = _surfaceRect(tester);
        final Rect t = _triggerRect(tester);
        if (_topSide.contains(align)) {
          expect(s.top, greaterThan(t.bottom));
        } else if (_bottomSide.contains(align)) {
          expect(s.bottom, lessThan(t.top));
        } else if (_leftSide.contains(align)) {
          expect(s.left, greaterThan(t.right));
        } else {
          expect(s.right, lessThan(t.left));
        }
      });
    }

    testWidgets('keeps the preferred side when it fits', (
      WidgetTester tester,
    ) async {
      await _pumpAndOpen(
        tester,
        align: CarbonPopoverAlignment.bottom,
        autoAlign: true,
      );
      expect(
        _surfaceRect(tester).top,
        moreOrLessEquals(_triggerRect(tester).bottom + 10, epsilon: 0.5),
      );
    });
  });

  group('semantics (#226)', () {
    testWidgets('surface content is reachable when open, gone when closed', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      late StateSetter setOuter;
      bool open = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              setOuter = setState;
              return CarbonPopover(
                open: open,
                content: const Text('Body'),
                child: _trigger(),
              );
            },
          ),
        ),
      );
      expect(find.bySemanticsLabel('Body'), findsNothing);

      setOuter(() => open = true);
      await tester.pumpAndSettle();
      // The popover is a plain container: its content must surface in the
      // semantics tree as-is — reachable, and with no stray role glued on.
      expect(find.bySemanticsLabel('Body'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Body')),
        isSemantics(label: 'Body', isButton: false, isLink: false),
      );
      // Carbide has no tab-tip popover variant (upstream's tab-tip close
      // affordance lives on the trigger tab, not the surface), so there
      // are no close controls to label-check here.
      handle.dispose();
    });
  });

  group('goldens', () {
    Widget specimen(CarbonPopoverAlignment align) => Center(
      child: CarbonPopover(
        open: true,
        align: align,
        content: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Popover'),
        ),
        child: const SizedBox(
          width: 96,
          height: 40,
          child: ColoredBox(color: Color(0xFF8A3FFC)),
        ),
      ),
    );

    testWidgets('bottom-aligned across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'popover_bottom',
        containsText: true,
        size: const Size(280, 200),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) =>
                  specimen(CarbonPopoverAlignment.bottom),
            ),
          ],
        ),
      );
    });

    testWidgets('right-aligned across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'popover_right',
        containsText: true,
        size: const Size(400, 160),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) =>
                  specimen(CarbonPopoverAlignment.right),
            ),
          ],
        ),
      );
    });
  });
}
