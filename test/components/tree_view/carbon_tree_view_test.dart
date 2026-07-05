// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 320, child: child),
    ),
  ),
);

List<CarbonTreeNode> _nodes() => const <CarbonTreeNode>[
  CarbonTreeNode(
    id: 'src',
    label: 'src',
    icon: CarbonIcons.folder,
    children: <CarbonTreeNode>[
      CarbonTreeNode(id: 'main', label: 'main.dart'),
      CarbonTreeNode(
        id: 'utils',
        label: 'utils',
        icon: CarbonIcons.folder,
        children: <CarbonTreeNode>[
          CarbonTreeNode(id: 'math', label: 'math.dart'),
        ],
      ),
    ],
  ),
  CarbonTreeNode(id: 'readme', label: 'README.md'),
  CarbonTreeNode(id: 'secret', label: 'secret.env', disabled: true),
];

double _labelIndent(WidgetTester tester, String text) {
  final Iterable<Padding> pads = tester.widgetList<Padding>(
    find.ancestor(of: find.text(text), matching: find.byType(Padding)),
  );
  // The label padding is the one with the 16px trailing inset.
  final Padding label = pads.firstWhere(
    (Padding p) => p.padding.resolve(TextDirection.ltr).right == 16,
  );
  return label.padding.resolve(TextDirection.ltr).left;
}

Widget _tree({
  Object? selectedId,
  ValueChanged<Object>? onSelect,
  Set<Object> expanded = const <Object>{},
  CarbonTreeSize size = CarbonTreeSize.sm,
}) => _host(
  CarbonTreeView(
    label: 'Files',
    nodes: _nodes(),
    selectedId: selectedId,
    onSelect: onSelect,
    initiallyExpandedIds: expanded,
    size: size,
  ),
);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('structure', () {
    testWidgets('roots render; collapsed children are hidden', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_tree());
      expect(find.text('src'), findsOneWidget);
      expect(find.text('README.md'), findsOneWidget);
      expect(find.text('main.dart'), findsNothing);
    });

    testWidgets('expanding a parent reveals its children, collapsing hides', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_tree());
      await tester.tap(find.text('src'));
      await tester.pumpAndSettle();
      // Tap selects but does not toggle; use the chevron to expand.
      expect(find.text('main.dart'), findsNothing);

      await tester.tap(
        find
            .descendant(
              of: find.byType(CarbonTreeView),
              matching: find.byType(CarbonIcon),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('utils'), findsOneWidget);
    });

    testWidgets('initiallyExpanded shows children at first build', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_tree(expanded: <Object>{'src'}));
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('utils'), findsOneWidget);
      // Grandchild stays hidden until its own parent expands.
      expect(find.text('math.dart'), findsNothing);
    });
  });

  group('selection', () {
    testWidgets('tapping selects: callback, layer-selected bg, 4px marker', (
      WidgetTester tester,
    ) async {
      Object? picked;
      await tester.pumpWidget(
        _tree(selectedId: 'readme', onSelect: (Object id) => picked = id),
      );
      await tester.tap(find.text('README.md'));
      expect(picked, 'readme');

      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('README.md'),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(deco.color, theme.layerSelected01);
      expect(
        tester.widget<Text>(find.text('README.md')).style!.color,
        theme.textPrimary,
      );
      // The active marker is a 4px interactive strip.
      final ColoredBox marker = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(PositionedDirectional),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(marker.color, theme.interactive);
    });

    testWidgets('a disabled node does not select and is greyed', (
      WidgetTester tester,
    ) async {
      Object? picked;
      await tester.pumpWidget(_tree(onSelect: (Object id) => picked = id));
      await tester.tap(find.text('secret.env'));
      expect(picked, isNull);
      expect(
        tester.widget<Text>(find.text('secret.env')).style!.color,
        theme.textDisabled,
      );
    });
  });

  group('indentation and size', () {
    testWidgets('depth offsets follow calcOffset (rem * 16)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_tree(expanded: <Object>{'src'}));
      // Parent with icon at depth 0: (0 + 1) rem = 16.
      expect(_labelIndent(tester, 'src'), 16);
      // Leaf, no icon at depth 0: 2.5 rem = 40.
      expect(_labelIndent(tester, 'README.md'), 40);
      // Leaf, no icon at depth 1: (1 + 2.5) rem = 56.
      expect(_labelIndent(tester, 'main.dart'), 56);
      // Parent with icon at depth 1: (1 + 1 + 0.5) rem = 40.
      expect(_labelIndent(tester, 'utils'), 40);
    });

    testWidgets('the label is vertically centered in the row', (
      WidgetTester tester,
    ) async {
      // Regression: the row Stack defaulted to topStart, pinning the
      // shrink-wrapped label to the top of the row instead of centering it.
      await tester.pumpWidget(_tree());
      final Rect row = tester.getRect(
        find
            .ancestor(
              of: find.text('README.md'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      final Rect label = tester.getRect(find.text('README.md'));
      expect(label.center.dy, moreOrLessEquals(row.center.dy, epsilon: 0.5));
    });

    testWidgets('xs rows are 24px, sm rows are 32px', (
      WidgetTester tester,
    ) async {
      for (final (CarbonTreeSize size, double h) in <(CarbonTreeSize, double)>[
        (CarbonTreeSize.xs, 24),
        (CarbonTreeSize.sm, 32),
      ]) {
        await tester.pumpWidget(_tree(size: size));
        final ConstrainedBox box = tester.widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.text('README.md'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        );
        expect(box.constraints.minHeight, h);
        // The label must stay legible inside the tight row (xs is 24px with an
        // 18px body-compact-01 line box).
        expectTextNotClipped(tester, find.text('README.md'));
      }
    });
  });

  group('keyboard', () {
    /// Runtime-built nodes (non-const) with an enabled last root so End can
    /// land on it.
    List<CarbonTreeNode> keyboardNodes() {
      final List<CarbonTreeNode> children = <CarbonTreeNode>[
        for (int i = 1; i <= 2; i++) CarbonTreeNode(id: 'a$i', label: 'a$i'),
      ];
      return <CarbonTreeNode>[
        CarbonTreeNode(id: 'a', label: 'a', children: children),
        const CarbonTreeNode(id: 'b', label: 'b'),
      ];
    }

    testWidgets('Up/Home/End rove; Right descends; Left ascends to parent', (
      WidgetTester tester,
    ) async {
      Object? picked;
      await tester.pumpWidget(
        _host(
          CarbonTreeView(
            label: 'Keys',
            nodes: keyboardNodes(),
            initiallyExpandedIds: const <Object>{'a'},
            onSelect: (Object id) => picked = id,
          ),
        ),
      );
      // Visible: a, a1, a2, b. Focus + select the parent.
      await tester.tap(find.text('a'));
      await tester.pumpAndSettle();
      expect(picked, 'a');

      // Right on an already-expanded parent moves focus to its first child.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(picked, 'a1');

      // Left on a leaf jumps back to the nearest shallower ancestor.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(picked, 'a');

      // End focuses the last visible node.
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(picked, 'b');

      // Home returns to the first; Down then Up round-trips back to it.
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(picked, 'a');

      // First Left collapses the expanded root; a second Left is a no-op
      // because a root has no parent to ascend to.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('a1'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(picked, 'a');
    });

    testWidgets('Right expands, Left collapses, Down+Enter selects next', (
      WidgetTester tester,
    ) async {
      Object? picked;
      await tester.pumpWidget(_tree(onSelect: (Object id) => picked = id));
      // Focus + select the parent.
      await tester.tap(find.text('src'));
      await tester.pumpAndSettle();
      expect(picked, 'src');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('main.dart'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('main.dart'), findsNothing);

      // Re-expand, then move down to the first child and activate it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(picked, 'main');
    });
  });

  group('hover', () {
    Color rowColor(WidgetTester tester, String label) {
      final BoxDecoration deco =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text(label),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      return deco.color!;
    }

    testWidgets('hovering an unselected row paints the hover layer', (
      WidgetTester tester,
    ) async {
      // The tree is top-left aligned, so park the pointer far away from it.
      const Offset away = Offset(600, 500);
      await tester.pumpWidget(_tree());
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: away);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('README.md')));
      await tester.pump();
      expect(rowColor(tester, 'README.md'), theme.layerHover01);
      expect(
        tester.widget<Text>(find.text('README.md')).style!.color,
        theme.textPrimary,
      );

      await gesture.moveTo(away);
      await tester.pump();
      expect(rowColor(tester, 'README.md'), theme.layer01);
    });
  });

  group('semantics', () {
    testWidgets('a parent exposes selected + expanded state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _tree(selectedId: 'src', expanded: <Object>{'src'}),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('src')),
        isSemantics(
          label: 'src',
          isSelected: true,
          hasExpandedState: true,
          isExpanded: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('tree across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'tree_view',
        containsText: true,
        size: const Size(280, 220),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 260,
            child: CarbonTreeView(
              label: 'Files',
              selectedId: 'main',
              initiallyExpandedIds: const <Object>{'src'},
              onSelect: (_) {},
              nodes: _nodes(),
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
