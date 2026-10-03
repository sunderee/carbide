// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const List<CarbonTreeNode> _initial = <CarbonTreeNode>[
  CarbonTreeNode(
    id: 'folder',
    label: 'Folder',
    children: <CarbonTreeNode>[
      CarbonTreeNode(
        id: 'branch',
        label: 'Branch',
        children: <CarbonTreeNode>[CarbonTreeNode(id: 'child', label: 'Child')],
      ),
      CarbonTreeNode(id: 'sibling', label: 'Sibling'),
    ],
  ),
  CarbonTreeNode(id: 'root', label: 'Root'),
];

void main() {
  testWidgets(
    'removed nodes are disposed and nearest surviving ancestor gets focus',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(tester);
      final FocusNode child = _focus(tester, 'Child');
      final FocusNode branch = _focus(tester, 'Branch');
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      state.replace(const <CarbonTreeNode>[
        CarbonTreeNode(
          id: 'folder',
          label: 'Folder',
          children: <CarbonTreeNode>[
            CarbonTreeNode(id: 'branch', label: 'Branch'),
            CarbonTreeNode(id: 'sibling', label: 'Sibling'),
          ],
        ),
        CarbonTreeNode(id: 'root', label: 'Root'),
      ]);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Branch'), same(branch));
      expect(FocusManager.instance.primaryFocus, branch);
      expect(() => child.addListener(() {}), throwsFlutterError);
      expect(state.selected, 'child');
      expect(state.selections, <Object>['child']);
      expect(_retainedCount(tester), 4);
    },
  );

  testWidgets(
    'programmatic focus recovers without a prior selection or expansion event',
    (tester) async {
      final state = await _mount(tester);
      _focus(tester, 'Child').requestFocus();
      await tester.pumpAndSettle();
      state.replace(const <CarbonTreeNode>[
        CarbonTreeNode(
          id: 'folder',
          label: 'Folder',
          children: <CarbonTreeNode>[
            CarbonTreeNode(id: 'sibling', label: 'Sibling'),
          ],
        ),
      ]);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Folder').hasPrimaryFocus, isTrue);
      expect(state.selections, isEmpty);
    },
  );

  testWidgets('removing a whole branch prefers the surviving grandparent', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    final FocusNode folder = _focus(tester, 'Folder');
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(
        id: 'folder',
        label: 'Folder',
        children: <CarbonTreeNode>[
          CarbonTreeNode(id: 'sibling', label: 'Sibling'),
        ],
      ),
      CarbonTreeNode(id: 'root', label: 'Root'),
    ]);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, folder);
    expect(_retainedCount(tester), 3);
  });

  testWidgets(
    'root removal picks the next surviving sibling on a distance tie',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(
        tester,
        nodes: const <CarbonTreeNode>[
          CarbonTreeNode(id: 'before', label: 'Before'),
          CarbonTreeNode(id: 'middle', label: 'Middle'),
          CarbonTreeNode(id: 'after', label: 'After'),
        ],
      );
      final FocusNode after = _focus(tester, 'After');
      await tester.tap(find.text('Middle'));
      await tester.pumpAndSettle();
      state.replace(const <CarbonTreeNode>[
        CarbonTreeNode(id: 'before', label: 'Before'),
        CarbonTreeNode(id: 'after', label: 'After'),
      ]);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, after);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, _focus(tester, 'Before'));
    },
  );

  testWidgets('unrelated data falls back to the first enabled visible row', (
    WidgetTester tester,
  ) async {
    final _FixtureState state = await _mount(tester);
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'disabled', label: 'Disabled', disabled: true),
      CarbonTreeNode(id: 'new', label: 'New'),
    ]);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, _focus(tester, 'New'));
    expect(_retainedCount(tester), 2);
    expect(state.selections, <Object>['child']);
  });

  for (final bool disabled in <bool>[false, true]) {
    testWidgets(
      'no enabled row releases focus to the enclosing scope, disabled=$disabled',
      (WidgetTester tester) async {
        final _FixtureState state = await _mount(tester);
        await tester.tap(find.text('Child'));
        await tester.pumpAndSettle();
        state.replace(<CarbonTreeNode>[
          if (disabled)
            const CarbonTreeNode(
              id: 'disabled',
              label: 'Disabled',
              disabled: true,
            ),
        ]);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isA<FocusScopeNode>());
        expect(_retainedCount(tester), disabled ? 1 : 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'data refresh preserves outside focus and surviving node identity',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(tester);
      final FocusNode root = _focus(tester, 'Root');
      state.outside.requestFocus();
      await tester.pumpAndSettle();
      state.replace(const <CarbonTreeNode>[
        CarbonTreeNode(id: 'root', label: 'Renamed root'),
        CarbonTreeNode(id: 'other', label: 'Other'),
      ]);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Renamed root'), same(root));
      expect(FocusManager.instance.primaryFocus, state.outside);
      expect(state.selections, isEmpty);
    },
  );

  testWidgets(
    'retained focus resources stay bounded through repeated data replacement',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(tester);
      for (int page = 0; page < 40; page++) {
        state.replace(<CarbonTreeNode>[
          for (int row = 0; row < 8; row++)
            CarbonTreeNode(id: '$page-$row', label: '$page-$row'),
        ]);
        await tester.pump();
        expect(_retainedCount(tester), 8);
      }
      state.replace(const <CarbonTreeNode>[]);
      await tester.pumpAndSettle();
      expect(_retainedCount(tester), 0);
    },
  );
  testWidgets('collapsed descendants retain focus resources until removed', (
    tester,
  ) async {
    final state = await _mount(tester);
    final child = _focus(tester, 'Child');
    state.expansion(<Object>{});
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsNothing);
    expect(_retainedCount(tester), 5);
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'folder', label: 'Folder'),
      CarbonTreeNode(id: 'root', label: 'Root'),
    ]);
    await tester.pumpAndSettle();
    expect(() => child.addListener(() {}), throwsFlutterError);
    expect(_retainedCount(tester), 2);
  });

  for (final bool disabled in <bool>[false, true]) {
    testWidgets(
      'hidden/disabled focused row recovers to enabled ancestor, disabled=$disabled',
      (tester) async {
        final state = await _mount(tester);
        await tester.tap(find.text('Child'));
        await tester.pumpAndSettle();
        if (disabled) {
          state.replace(const <CarbonTreeNode>[
            CarbonTreeNode(
              id: 'folder',
              label: 'Folder',
              children: <CarbonTreeNode>[
                CarbonTreeNode(
                  id: 'branch',
                  label: 'Branch',
                  disabled: true,
                  children: <CarbonTreeNode>[
                    CarbonTreeNode(id: 'child', label: 'Child', disabled: true),
                  ],
                ),
              ],
            ),
          ]);
        } else {
          state.expansion(<Object>{});
        }
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, _focus(tester, 'Folder'));
        expect(state.selections, <Object>['child']);
      },
    );
  }

  testWidgets(
    'sibling fallback skips disabled candidates before using the first row',
    (tester) async {
      final state = await _mount(
        tester,
        nodes: const <CarbonTreeNode>[
          CarbonTreeNode(id: 'before', label: 'Before'),
          CarbonTreeNode(id: 'middle', label: 'Middle'),
          CarbonTreeNode(id: 'after', label: 'After'),
        ],
      );
      await tester.tap(find.text('Middle'));
      await tester.pumpAndSettle();
      state.replace(const <CarbonTreeNode>[
        CarbonTreeNode(id: 'first', label: 'First'),
        CarbonTreeNode(id: 'before', label: 'Before'),
        CarbonTreeNode(id: 'after', label: 'After', disabled: true),
      ]);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Before').hasPrimaryFocus, isTrue);
    },
  );

  testWidgets(
    'Right descends only to enabled descendants and Left skips disabled ancestors',
    (tester) async {
      await _mount(
        tester,
        nodes: const <CarbonTreeNode>[
          CarbonTreeNode(
            id: 'folder',
            label: 'Folder',
            children: <CarbonTreeNode>[
              CarbonTreeNode(
                id: 'branch',
                label: 'Branch',
                disabled: true,
                children: <CarbonTreeNode>[
                  CarbonTreeNode(id: 'child', label: 'Child'),
                ],
              ),
            ],
          ),
          CarbonTreeNode(id: 'root', label: 'Root'),
        ],
      );
      await tester.tap(find.text('Folder'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Child').hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(_focus(tester, 'Folder').hasPrimaryFocus, isTrue);
    },
  );

  testWidgets('focused semantics remain separate from controlled selection', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await _mount(tester);
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(_rowSemantics(tester, 'Branch').properties.focused, isTrue);
      expect(_rowSemantics(tester, 'Branch').properties.selected, isFalse);
      expect(_rowSemantics(tester, 'Child').properties.focused, isFalse);
      expect(_rowSemantics(tester, 'Child').properties.selected, isTrue);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('surviving focused ID stays focused through rename and reorder', (
    tester,
  ) async {
    final state = await _mount(tester);
    final root = _focus(tester, 'Root');
    await tester.tap(find.text('Root'));
    await tester.pumpAndSettle();
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'root', label: 'Renamed'),
      CarbonTreeNode(id: 'other', label: 'Other'),
    ]);
    await tester.pumpAndSettle();
    expect(_focus(tester, 'Renamed'), same(root));
    expect(root.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_focus(tester, 'Other').hasPrimaryFocus, isTrue);
  });

  testWidgets(
    'focus recovery does not override a newer outside focus request',
    (tester) async {
      final state = await _mount(tester);
      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      state.replace(const <CarbonTreeNode>[
        CarbonTreeNode(id: 'new', label: 'New'),
      ]);
      state.outside.requestFocus();
      await tester.pumpAndSettle();
      expect(state.outside.hasPrimaryFocus, isTrue);
    },
  );

  testWidgets('pending recovery is safe when tree is unmounted', (
    tester,
  ) async {
    final state = await _mount(tester);
    await tester.tap(find.text('Child'));
    await tester.pumpAndSettle();
    state.replace(const <CarbonTreeNode>[
      CarbonTreeNode(id: 'new', label: 'New'),
    ]);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'controlled toggles propose copies and respect rejected updates',
    (tester) async {
      final original = <Object>{};
      final state = await _mount(tester, expanded: original);
      await tester.tap(find.text('Folder'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('Branch'), findsNothing);
      expect(state.proposals, <Set<Object>>[
        <Object>{'folder'},
      ]);
      expect(original, isEmpty);
      state.expansion(state.proposals.single);
      await tester.pumpAndSettle();
      expect(find.text('Branch'), findsOneWidget);
      expect(state.proposals.length, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('Branch'), findsOneWidget);
      expect(state.proposals.last, isEmpty);
      expect(state.expanded, <Object>{'folder'});
    },
  );

  testWidgets('accepted controlled proposals preserve selection and focus', (
    tester,
  ) async {
    final state = await _mount(tester, expanded: <Object>{});
    state.accept = true;
    await tester.tap(find.text('Folder'));
    await tester.pumpAndSettle();
    final folder = _focus(tester, 'Folder');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('Branch'), findsOneWidget);
    expect(folder.hasPrimaryFocus, isTrue);
    expect(state.selected, 'folder');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Branch'), findsNothing);
    expect(state.selections, <Object>['folder']);
    expect(state.proposals.length, 2);
  });

  testWidgets('controlled expansion updates in place and preserves scroll', (
    tester,
  ) async {
    final nodes = <CarbonTreeNode>[
      for (int i = 0; i < 30; i++)
        CarbonTreeNode(
          id: i,
          label: 'Row $i',
          children: <CarbonTreeNode>[
            CarbonTreeNode(id: 'child-$i', label: 'Child $i'),
          ],
        ),
    ];
    final state = await _mount(tester, nodes: nodes, expanded: <Object>{});
    final treeState = tester.state(find.byType(CarbonTreeView));
    final first = _focus(tester, 'Row 0');
    state.scroll.jumpTo(400);
    await tester.pumpAndSettle();
    state.expansion(<Object>{29});
    await tester.pumpAndSettle();
    expect(find.text('Child 29'), findsOneWidget);
    expect(state.scroll.offset, 400);
    state.replace(<CarbonTreeNode>[
      for (int i = 0; i < 30; i++)
        CarbonTreeNode(
          id: i,
          label: 'Updated $i',
          children: <CarbonTreeNode>[
            CarbonTreeNode(id: 'child-$i', label: 'Child $i'),
          ],
        ),
    ]);
    await tester.pumpAndSettle();
    expect(state.scroll.offset, 400);
    expect(tester.state(find.byType(CarbonTreeView)), same(treeState));
    expect(_focus(tester, 'Updated 0'), same(first));
    expect(state.selections, isEmpty);
    expect(state.proposals, isEmpty);
  });

  testWidgets('controlled to local handoff copies outgoing expansion', (
    tester,
  ) async {
    final external = <Object>{'folder'};
    final state = await _mount(tester, expanded: external);
    state.expansion(null);
    await tester.pumpAndSettle();
    external.clear();
    state.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Branch'), findsOneWidget);
    await tester.tap(find.text('Folder'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('Branch'), findsNothing);
    expect(state.proposals, <Set<Object>>[<Object>{}]);
  });

  testWidgets(
    'entering controlled mode overrides local state; local seed is one-shot',
    (tester) async {
      final state = await _mount(tester);
      state.seed = <Object>{};
      state.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Child'), findsOneWidget);
      state.expansion(<Object>{});
      await tester.pumpAndSettle();
      expect(find.text('Branch'), findsNothing);
      expect(state.proposals, isEmpty);
    },
  );

  testWidgets('uncontrolled proposals cannot mutate internal expansion', (
    tester,
  ) async {
    final state = await _mount(tester);
    await tester.tap(find.text('Folder'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    state.proposals.single.add('folder');
    state.refresh();
    await tester.pumpAndSettle();
    expect(find.text('Branch'), findsNothing);
  });

  for (final bool disabled in <bool>[false, true]) {
    testWidgets(
      'stored callbacks reject removed/replaced disabled rows, disabled=$disabled',
      (tester) async {
        final state = await _mount(tester);
        final row = _rowSemantics(tester, 'Folder');
        final focus = tester.widget<Focus>(
          find
              .ancestor(of: find.text('Folder'), matching: find.byType(Focus))
              .first,
        );
        state.replace(<CarbonTreeNode>[
          if (disabled)
            const CarbonTreeNode(
              id: 'folder',
              label: 'Folder',
              disabled: true,
              children: <CarbonTreeNode>[
                CarbonTreeNode(id: 'child', label: 'Child'),
              ],
            ),
          const CarbonTreeNode(id: 'other', label: 'Other'),
        ]);
        await tester.pumpAndSettle();
        row.properties.onTap!();
        row.properties.onFocus!();
        focus.onKeyEvent!(
          focus.focusNode!,
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.arrowRight,
            logicalKey: LogicalKeyboardKey.arrowRight,
            timeStamp: Duration.zero,
          ),
        );
        await tester.pumpAndSettle();
        expect(state.selections, isEmpty);
        expect(state.proposals, isEmpty);
        expect(_retainedCount(tester), disabled ? 3 : 1);
      },
    );
  }

  testWidgets('stored callbacks are inert after disposal', (tester) async {
    final state = await _mount(tester);
    final row = _rowSemantics(tester, 'Folder');
    final focus = tester.widget<Focus>(
      find
          .ancestor(of: find.text('Folder'), matching: find.byType(Focus))
          .first,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    row.properties.onTap!();
    row.properties.onFocus!();
    focus.onKeyEvent!(
      focus.focusNode!,
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      ),
    );
    await tester.pumpAndSettle();
    expect(state.selections, isEmpty);
    expect(state.proposals, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard skips disabled rows in both directions and Home/End', (
    tester,
  ) async {
    await _mount(
      tester,
      nodes: const <CarbonTreeNode>[
        CarbonTreeNode(id: 0, label: 'Disabled first', disabled: true),
        CarbonTreeNode(id: 1, label: 'One'),
        CarbonTreeNode(id: 2, label: 'Disabled middle', disabled: true),
        CarbonTreeNode(id: 3, label: 'Three'),
        CarbonTreeNode(id: 4, label: 'Disabled last', disabled: true),
      ],
    );
    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();
    for (final entry in <(LogicalKeyboardKey, String)>[
      (LogicalKeyboardKey.arrowDown, 'Three'),
      (LogicalKeyboardKey.arrowUp, 'One'),
      (LogicalKeyboardKey.end, 'Three'),
      (LogicalKeyboardKey.home, 'One'),
    ]) {
      await tester.sendKeyEvent(entry.$1);
      await tester.pumpAndSettle();
      expect(_focus(tester, entry.$2).hasPrimaryFocus, isTrue);
    }
  });

  for (final Set<Object> seed in <Set<Object>>[
    <Object>{},
    <Object>{'folder'},
  ]) {
    test('initial and controlled expansion are mutually exclusive: $seed', () {
      expect(
        () => CarbonTreeView(
          nodes: _initial,
          label: 'Files',
          initiallyExpandedIds: seed,
          expandedIds: const <Object>{},
        ),
        throwsAssertionError,
      );
    });
  }

  test('const controlled construction remains available', () {
    const tree = CarbonTreeView(
      nodes: _initial,
      label: 'Files',
      expandedIds: <Object>{'folder'},
    );
    expect(tree.expandedIds, <Object>{'folder'});
    expect(tree.initiallyExpandedIds, isEmpty);
  });

  test('duplicate IDs are rejected even in collapsed descendants', () {
    const tree = CarbonTreeView(
      nodes: <CarbonTreeNode>[
        CarbonTreeNode(
          id: 'x',
          label: 'X',
          children: <CarbonTreeNode>[
            CarbonTreeNode(id: 'x', label: 'Duplicate'),
          ],
        ),
      ],
      label: 'Files',
    );
    expect(tree.createElement, throwsAssertionError);
  });
}

Future<_FixtureState> _mount(
  WidgetTester tester, {
  List<CarbonTreeNode> nodes = _initial,
  Set<Object>? expanded,
}) async {
  final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (_, _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: 400,
            child: _Fixture(key: key, initial: nodes, expanded: expanded),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Focus tests assume an active view. Web's first programmatic focus otherwise
  // requests a forward view activation, which traverses to the first row.
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

class _Fixture extends StatefulWidget {
  const _Fixture({super.key, required this.initial, this.expanded});
  final List<CarbonTreeNode> initial;
  final Set<Object>? expanded;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  late List<CarbonTreeNode> nodes = widget.initial;
  Object? selected;
  late Set<Object>? expanded = widget.expanded;
  Set<Object> seed = <Object>{'folder', 'branch'};
  bool accept = false;
  final proposals = <Set<Object>>[];
  final scroll = ScrollController();
  void expansion(Set<Object>? next) => setState(() => expanded = next);
  void refresh() => setState(() {});
  final FocusNode outside = FocusNode(debugLabel: 'Outside');
  final List<Object> selections = <Object>[];
  void replace(List<CarbonTreeNode> next) => setState(() => nodes = next);
  @override
  void dispose() {
    outside.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        height: 160,
        child: SingleChildScrollView(
          controller: scroll,
          child: CarbonTreeView(
            label: 'Files',
            nodes: nodes,
            initiallyExpandedIds: expanded == null ? seed : null,
            expandedIds: expanded,
            onExpansionChanged: (ids) {
              proposals.add(ids);
              if (accept) setState(() => expanded = ids);
            },
            selectedId: selected,
            onSelect: (Object id) {
              selections.add(id);
              setState(() => selected = id);
            },
          ),
        ),
      ),
      CarbonButton(label: 'Outside', focusNode: outside, onPressed: () {}),
    ],
  );
}

FocusNode _focus(WidgetTester tester, String label) => tester
    .widget<Focus>(
      find.ancestor(of: find.text(label), matching: find.byType(Focus)).first,
    )
    .focusNode!;
int _retainedCount(WidgetTester tester) {
  final DiagnosticPropertiesBuilder properties = DiagnosticPropertiesBuilder();
  tester
      .state<State<CarbonTreeView>>(find.byType(CarbonTreeView))
      .debugFillProperties(properties);
  return (properties.properties.singleWhere(
    (DiagnosticsNode p) => p.name == 'retainedFocusNodeCount',
  ) as IntProperty).value!;
}

Semantics _rowSemantics(WidgetTester tester, String label) => tester
    .widgetList<Semantics>(
      find.ancestor(of: find.text(label), matching: find.byType(Semantics)),
    )
    .firstWhere(
      (row) => row.properties.label == label && row.properties.onTap != null,
    );
