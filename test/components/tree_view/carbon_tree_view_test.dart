// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
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

/// The background color of the row containing [label].
Color _rowColor(WidgetTester tester, String label) {
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

/// The 4px active-marker strip inside the row containing [label], if any.
Finder _marker(WidgetTester tester, String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(Stack)).first,
  matching: find.byType(PositionedDirectional),
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

    testWidgets('activeId and selectedIds render independently (#253)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonTreeView(
            label: 'Files',
            nodes: _nodes(),
            initiallyExpandedIds: const <Object>{'src'},
            selectedIds: const <Object>{'main'},
            activeId: 'readme',
            onSelectionChanged: (_) {},
          ),
        ),
      );

      // The selected node paints layer-selected but carries no marker.
      expect(_rowColor(tester, 'main.dart'), theme.layerSelected01);
      expect(_marker(tester, 'main.dart'), findsNothing);

      // The active node carries the 4px interactive marker on the plain
      // layer background.
      expect(_rowColor(tester, 'README.md'), theme.layer01);
      expect(_marker(tester, 'README.md'), findsOneWidget);
      final ColoredBox marker = tester.widget<ColoredBox>(
        find.descendant(
          of: _marker(tester, 'README.md'),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(marker.color, theme.interactive);
    });
  });

  // Multiselect + controllable-parity (#253): react `TreeView.tsx`
  // `handleTreeSelect` toggles membership on Ctrl/Cmd-activation and
  // collapses to the plain-activated node otherwise; `handleKeyDown`
  // extends with Ctrl+Shift+Home/End and selects all with Ctrl+A.
  group('multiselect (#253)', () {
    Widget multi({
      Set<Object> selectedIds = const <Object>{},
      Object? activeId,
      ValueChanged<Set<Object>>? onSelectionChanged,
      ValueChanged<Object>? onActivate,
      ValueChanged<Object>? onSelect,
      bool multiselect = true,
    }) => _host(
      CarbonTreeView(
        label: 'Files',
        nodes: _nodes(),
        multiselect: multiselect,
        selectedIds: selectedIds,
        activeId: activeId,
        onSelectionChanged: onSelectionChanged,
        onActivate: onActivate,
        onSelect: onSelect,
        initiallyExpandedIds: const <Object>{'src'},
      ),
    );

    testWidgets('Ctrl-click adds an unselected node to the selection and '
        'does not activate it', (WidgetTester tester) async {
      Set<Object>? selection;
      int activations = 0;
      await tester.pumpWidget(
        multi(
          selectedIds: const <Object>{'main'},
          onSelectionChanged: (Set<Object> ids) => selection = ids,
          onActivate: (_) => activations++,
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('README.md'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(selection, <Object>{'main', 'readme'});
      expect(activations, 0);
    });

    testWidgets('Ctrl-click removes an already-selected node', (
      WidgetTester tester,
    ) async {
      Set<Object>? selection;
      await tester.pumpWidget(
        multi(
          selectedIds: const <Object>{'main', 'readme'},
          onSelectionChanged: (Set<Object> ids) => selection = ids,
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('README.md'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(selection, <Object>{'main'});
    });

    testWidgets('Cmd-click toggles too (meta ≡ ctrl, like upstream)', (
      WidgetTester tester,
    ) async {
      Set<Object>? selection;
      await tester.pumpWidget(
        multi(onSelectionChanged: (Set<Object> ids) => selection = ids),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.tap(find.text('src'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      expect(selection, <Object>{'src'});
    });

    testWidgets('a plain tap collapses the selection to the tapped node '
        'and activates it', (WidgetTester tester) async {
      Set<Object>? selection;
      Object? activated;
      Object? picked;
      await tester.pumpWidget(
        multi(
          selectedIds: const <Object>{'main', 'src'},
          onSelectionChanged: (Set<Object> ids) => selection = ids,
          onActivate: (Object id) => activated = id,
          onSelect: (Object id) => picked = id,
        ),
      );
      await tester.tap(find.text('README.md'));
      expect(selection, <Object>{'readme'});
      expect(activated, 'readme');
      expect(picked, 'readme');
    });

    testWidgets('Ctrl+Space toggles the focused node from the keyboard', (
      WidgetTester tester,
    ) async {
      Set<Object>? selection;
      await tester.pumpWidget(
        multi(
          selectedIds: const <Object>{'src'},
          onSelectionChanged: (Set<Object> ids) => selection = ids,
        ),
      );
      // Plain-activate src (focuses it), rove down to main.dart.
      await tester.tap(find.text('src'));
      await tester.pumpAndSettle();
      expect(selection, <Object>{'src'});
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      // The toggle reports the controlled selection plus the roved node.
      expect(selection, <Object>{'src', 'main'});
    });

    testWidgets('Ctrl+Shift+End extends the selection to the last visible '
        'node, skipping disabled ones', (WidgetTester tester) async {
      Set<Object>? selection;
      await tester.pumpWidget(
        multi(onSelectionChanged: (Set<Object> ids) => selection = ids),
      );
      // Visible: src, main, utils, readme, secret(disabled).
      await tester.tap(find.text('src'));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(selection, <Object>{'src', 'main', 'utils', 'readme'});
    });

    testWidgets('Ctrl+Shift+Home extends the selection to the first node', (
      WidgetTester tester,
    ) async {
      Set<Object>? selection;
      await tester.pumpWidget(
        multi(onSelectionChanged: (Set<Object> ids) => selection = ids),
      );
      await tester.tap(find.text('README.md'));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(selection, <Object>{'readme', 'utils', 'main', 'src'});
    });

    testWidgets('Ctrl+A selects every visible enabled node — not the '
        'collapsed or disabled ones', (WidgetTester tester) async {
      Set<Object>? selection;
      await tester.pumpWidget(
        multi(onSelectionChanged: (Set<Object> ids) => selection = ids),
      );
      await tester.tap(find.text('src'));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      // math is hidden under the collapsed utils; secret is disabled.
      expect(selection, <Object>{'src', 'main', 'utils', 'readme'});
    });

    testWidgets('without multiselect, Ctrl-click stays a plain activation', (
      WidgetTester tester,
    ) async {
      Set<Object>? selection;
      Object? activated;
      await tester.pumpWidget(
        multi(
          multiselect: false,
          selectedIds: const <Object>{'main'},
          onSelectionChanged: (Set<Object> ids) => selection = ids,
          onActivate: (Object id) => activated = id,
        ),
      );
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.tap(find.text('README.md'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      expect(selection, <Object>{'readme'});
      expect(activated, 'readme');
    });

    testWidgets('two selected rows both expose selected semantics', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        multi(selectedIds: const <Object>{'main', 'readme'}),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('main.dart')),
        isSemantics(label: 'main.dart', isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('README.md')),
        isSemantics(label: 'README.md', isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('src')),
        isSemantics(label: 'src', isSelected: false),
      );
      handle.dispose();
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

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _tree(onSelect: (_) {}, expanded: const <Object>{'src', 'utils'}),
      );
      await tester.pumpAndSettle();
      // Tap targets are off: tree rows are 32px by upstream default
      // (`min-block-size: convert.to-rem(32px)` in documentation/carbon/
      // packages/styles/scss/components/treeview/_treeview.scss), so 48dp
      // is unattainable at the default `sm` size.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('multi-selection with a separate active node across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'tree_view_states',
        containsText: true,
        size: const Size(280, 220),
        builder: (BuildContext context) => Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 260,
            child: CarbonTreeView(
              label: 'Files',
              multiselect: true,
              // main + README selected (layer-selected background); utils
              // active (4px marker only) — the #253 split matrix.
              selectedIds: const <Object>{'main', 'readme'},
              activeId: 'utils',
              onSelectionChanged: (_) {},
              initiallyExpandedIds: const <Object>{'src'},
              nodes: _nodes(),
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });

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
