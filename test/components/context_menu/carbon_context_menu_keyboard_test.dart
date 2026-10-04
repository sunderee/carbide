// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';
import '../../support/golden.dart';
import '../../support/a11y.dart';

void main() {
  setUp(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional,
  );
  tearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  for (final radio in <bool>[false, true]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'focus enters ${radio ? 'radio' : 'selectable'} item: $direction',
        (tester) async {
          final semantics = tester.ensureSemantics();
          final origin = FocusNode();
          addTearDown(origin.dispose);
          try {
            bool selected = false;
            int value = 1;
            await tester.pumpWidget(
              _host(
                StatefulBuilder(
                  builder: (_, refresh) => CarbonContextMenu(
                    size: CarbonMenuSize.lg,
                    items: <Widget>[
                      const CarbonMenuItem(
                        label: 'Unavailable',
                        disabled: true,
                      ),
                      if (radio)
                        CarbonMenuItemRadioGroup<int>(
                          label: 'Mode',
                          value: value,
                          options: const <(int, String)>[
                            (1, 'First mode'),
                            (2, 'Second mode'),
                          ],
                          onChanged: (v) => refresh(() => value = v),
                        )
                      else
                        CarbonMenuItemSelectable(
                          label: 'Pinned',
                          selected: selected,
                          onChanged: (v) => refresh(() => selected = v),
                        ),
                    ],
                    child: Focus(
                      focusNode: origin,
                      child: const Text('Origin'),
                    ),
                  ),
                ),
                direction,
              ),
            );
            origin.requestFocus();
            await tester.pump();
            await _open(tester, 'Shift+F10');
            final label = radio ? 'First mode' : 'Pinned';
            final node = tester.getSemantics(find.bySemanticsLabel(label));
            expect(node, isSemantics(isFocused: true, isFocusable: true));
            await expectA11y(tester);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            await tester.pumpAndSettle();
            expect(radio ? value == 1 : selected, isTrue);
            expect(find.byType(CarbonMenu), findsOneWidget);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            expect(origin.hasPrimaryFocus, isTrue);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }
  for (final backwards in <bool>[false, true]) {
    testWidgets('Tab dismisses and continues traversal: reverse=$backwards', (
      tester,
    ) async {
      final key = GlobalKey<_FixtureState>();
      await tester.pumpWidget(_host(_Fixture(key: key)));
      final state = key.currentState!;
      (backwards ? state.second : state.target).requestFocus();
      await tester.pump();
      await _open(tester, 'Shift+F10');
      if (backwards) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      if (backwards) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(find.byType(CarbonMenu), findsNothing);
      expect((backwards ? state.target : state.second).hasPrimaryFocus, isTrue);
      await _open(tester, 'ContextMenu');
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<CarbonMenuItem>()
            ?.label,
        'Cut',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect((backwards ? state.target : state.second).hasPrimaryFocus, isTrue);
    });
  }
  testWidgets('nested region handles shortcut once before ancestor', (
    tester,
  ) async {
    final target = FocusNode();
    addTearDown(target.dispose);
    await tester.pumpWidget(
      _host(
        CarbonContextMenu(
          items: <Widget>[CarbonMenuItem(label: 'Outer', onPressed: () {})],
          child: CarbonContextMenu(
            items: <Widget>[CarbonMenuItem(label: 'Inner', onPressed: () {})],
            child: Focus(
              focusNode: target,
              child: const SizedBox(
                width: 180,
                height: 40,
                child: Text('Nested target'),
              ),
            ),
          ),
        ),
      ),
    );
    target.requestFocus();
    await tester.pump();
    await _open(tester, 'Shift+F10');
    expect(find.text('Inner'), findsOneWidget);
    expect(find.text('Outer'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(target.hasPrimaryFocus, isTrue);
  });
  for (final direction in TextDirection.values) {
    testWidgets(
      'keyboard and pointer positions use nested overlay bounds: $direction',
      (tester) async {
        final key = GlobalKey<_FixtureState>();
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 440,
              height: 240,
              child: Overlay(
                initialEntries: <OverlayEntry>[
                  managedOverlayEntry(builder: (_) => _Fixture(key: key)),
                ],
              ),
            ),
            direction,
          ),
        );
        final state = key.currentState!;
        state.target.requestFocus();
        await tester.pump();
        final bounds = state.target.rect;
        await _open(tester, 'ContextMenu');
        final menu = tester.getRect(find.byType(CarbonMenu));
        expect(menu.top, bounds.bottom);
        expect(
          direction == TextDirection.ltr ? menu.left : menu.right,
          direction == TextDirection.ltr ? bounds.left : bounds.right,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        final point = tester.getCenter(find.byKey(const ValueKey('target')));
        await tester.tapAt(point, buttons: kSecondaryButton);
        await tester.pumpAndSettle();
        final overlay = tester.getRect(find.byType(Overlay).last);
        final pointerMenu = tester.getRect(find.byType(CarbonMenu));
        expect(
          pointerMenu.topLeft,
          Offset(
            point.dx.clamp(overlay.left, overlay.right - pointerMenu.width),
            point.dy.clamp(overlay.top, overlay.bottom - pointerMenu.height),
          ),
        );
      },
    );
  }
  testWidgets('key repeats, releases and retained handler cannot reopen', (
    tester,
  ) async {
    final key = GlobalKey<_FixtureState>();
    await tester.pumpWidget(_host(_Fixture(key: key)));
    final state = key.currentState!;
    state.target.requestFocus();
    await tester.pump();
    final boundary = tester.widget<Focus>(
      find
          .ancestor(
            of: find.byType(CarbonContextMenu),
            matching: find.byType(Focus),
          )
          .first,
    );
    final handler = tester
        .widgetList<Focus>(
          find.descendant(
            of: find.byType(CarbonContextMenu),
            matching: find.byType(Focus),
          ),
        )
        .firstWhere(
          (focus) =>
              focus.focusNode?.debugLabel == 'Carbon context-menu region',
        )
        .onKeyEvent!;
    const repeat = KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.contextMenu,
      logicalKey: LogicalKeyboardKey.contextMenu,
      timeStamp: Duration.zero,
    );
    expect(
      handler(boundary.focusNode ?? state.target, repeat),
      KeyEventResult.ignored,
    );
    await _open(tester, 'ContextMenu');
    final first = tester.state(find.byType(CarbonMenu));
    expect(
      handler(
        state.target,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.contextMenu,
          logicalKey: LogicalKeyboardKey.contextMenu,
          timeStamp: Duration.zero,
        ),
      ),
      KeyEventResult.ignored,
    );
    await tester.pump();
    expect(tester.state(find.byType(CarbonMenu)), same(first));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(
      handler(
        state.target,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.contextMenu,
          logicalKey: LogicalKeyboardKey.contextMenu,
          timeStamp: Duration.zero,
        ),
      ),
      KeyEventResult.ignored,
    );
  });
  testWidgets('keyboard-opened menu focus across themes and directions', (
    tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'context_menu_keyboard',
      containsText: true,
      size: const Size(480, 360),
      directions: TextDirection.values.toSet(),
      builder: (_) => Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (_) =>
                const Align(alignment: Alignment.topLeft, child: _Fixture()),
          ),
        ],
      ),
      afterPump: (tester) async {
        tester
            .state<_FixtureState>(find.byType(_Fixture))
            .target
            .requestFocus();
        await tester.pump();
        await _open(tester, 'Shift+F10');
      },
    );
  });
  for (final direction in TextDirection.values) {
    for (final shortcut in <String>['Shift+F10', 'ContextMenu']) {
      testWidgets(
        '$shortcut anchors to focused child and restores it: $direction',
        (tester) async {
          final key = GlobalKey<_FixtureState>();
          await tester.pumpWidget(_host(_Fixture(key: key), direction));
          final state = key.currentState!;
          state.target.requestFocus();
          await tester.pump();
          final target = state.target.rect;
          await _open(tester, shortcut);
          expect(find.byType(CarbonMenu), findsOneWidget);
          final menu = tester.getRect(find.byType(CarbonMenu));
          expect(menu.top, target.bottom);
          expect(
            direction == TextDirection.ltr ? menu.left : menu.right,
            direction == TextDirection.ltr ? target.left : target.right,
          );
          expect(
            FocusManager.instance.primaryFocus!.context!
                .findAncestorWidgetOfExactType<CarbonMenuItem>()!
                .label,
            'Cut',
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.byType(CarbonMenu), findsNothing);
          expect(state.target.hasPrimaryFocus, isTrue);
        },
      );
    }
    for (final close in <String>[
      'Escape',
      'outside',
      'secondary',
      'Enter',
      'pointer',
      'disabled',
    ]) {
      testWidgets('$close returns focus to exact opener: $direction', (
        tester,
      ) async {
        final key = GlobalKey<_FixtureState>();
        await tester.pumpWidget(_host(_Fixture(key: key), direction));
        final state = key.currentState!;
        state.target.requestFocus();
        await tester.pump();
        await _open(tester, 'ContextMenu');
        expect(find.byType(CarbonMenu), findsOneWidget);
        switch (close) {
          case 'Escape':
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          case 'outside':
            await tester.tapAt(const Offset(2, 2));
          case 'secondary':
            await tester.tapAt(const Offset(2, 2), buttons: kSecondaryButton);
          case 'Enter':
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          case 'pointer':
            await tester.tap(find.text('Cut'));
          case 'disabled':
            state.refresh(() => state.enabled = false);
        }
        await tester.pumpAndSettle();
        expect(find.byType(CarbonMenu), findsNothing);
        expect(state.target.hasPrimaryFocus, isTrue);
        expect(state.actions, close == 'Enter' || close == 'pointer' ? 1 : 0);
      });
    }
  }
  for (final empty in <bool>[true, false]) {
    testWidgets(
      '${empty ? 'empty' : 'all-disabled'} menu retains Escape dismissal',
      (tester) async {
        final key = GlobalKey<_FixtureState>();
        await tester.pumpWidget(
          _host(_Fixture(key: key, empty: empty, allDisabled: !empty)),
        );
        final state = key.currentState!;
        state.target.requestFocus();
        await tester.pump();
        await _open(tester, 'ContextMenu');
        expect(find.byType(CarbonMenu), findsOneWidget);
        expect(state.target.hasPrimaryFocus, isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(CarbonMenu), findsNothing);
        expect(state.target.hasPrimaryFocus, isTrue);
      },
    );
  }
  testWidgets('both shortcuts are scoped and disabled keys bubble', (
    tester,
  ) async {
    final key = GlobalKey<_FixtureState>();
    await tester.pumpWidget(_host(_Fixture(key: key)));
    final state = key.currentState!;
    state.outside.requestFocus();
    await tester.pump();
    await _open(tester, 'Shift+F10');
    await _open(tester, 'ContextMenu');
    expect(find.byType(CarbonMenu), findsNothing);
    expect(state.bubbled, 2);
    state.refresh(() => state.enabled = false);
    state.target.requestFocus();
    await tester.pump();
    await _open(tester, 'Shift+F10');
    await _open(tester, 'ContextMenu');
    expect(find.byType(CarbonMenu), findsNothing);
    expect(state.bubbled, 4);
  });
  testWidgets('unmodified F10 and extra modifiers do not open', (tester) async {
    final key = GlobalKey<_FixtureState>();
    await tester.pumpWidget(_host(_Fixture(key: key)));
    key.currentState!.target.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await _open(tester, 'Shift+F10');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await _open(tester, 'ContextMenu');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    expect(find.byType(CarbonMenu), findsNothing);
  });
  testWidgets('close respects consumer focus request from action', (
    tester,
  ) async {
    final key = GlobalKey<_FixtureState>();
    await tester.pumpWidget(_host(_Fixture(key: key, handoff: true)));
    final state = key.currentState!;
    state.target.requestFocus();
    await tester.pump();
    await _open(tester, 'ContextMenu');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(state.actions, 1);
    expect(state.outside.hasPrimaryFocus, isTrue);
    expect(find.byType(CarbonMenu), findsNothing);
  });
  testWidgets('close respects focus moved elsewhere while open', (
    tester,
  ) async {
    final key = GlobalKey<_FixtureState>();
    await tester.pumpWidget(_host(_Fixture(key: key)));
    final state = key.currentState!;
    state.target.requestFocus();
    await tester.pump();
    await _open(tester, 'ContextMenu');
    state.outside.requestFocus();
    await tester.pump();
    state.refresh(() => state.enabled = false);
    await tester.pumpAndSettle();
    expect(state.outside.hasPrimaryFocus, isTrue);
    expect(find.byType(CarbonMenu), findsNothing);
  });
  for (final disable in <bool>[false, true]) {
    testWidgets('detached/unfocusable opener is not restored: $disable', (
      tester,
    ) async {
      final key = GlobalKey<_FixtureState>();
      await tester.pumpWidget(_host(_Fixture(key: key)));
      final state = key.currentState!;
      state.target.requestFocus();
      await tester.pump();
      await _open(tester, 'ContextMenu');
      state.refresh(() {
        if (disable) {
          state.canFocus = false;
        } else {
          state.showTarget = false;
        }
      });
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CarbonMenu), findsNothing);
      expect(state.target.hasPrimaryFocus, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('repeated sessions return to the current focused descendant', (
    tester,
  ) async {
    final key = GlobalKey<_FixtureState>();
    await tester.pumpWidget(_host(_Fixture(key: key)));
    final state = key.currentState!;
    for (final target in <FocusNode>[
      state.target,
      state.second,
      state.target,
    ]) {
      target.requestFocus();
      await tester.pump();
      await _open(tester, 'ContextMenu');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(target.hasPrimaryFocus, isTrue);
    }
  });
  testWidgets('removal while open restores still-attached external opener', (
    tester,
  ) async {
    final key = GlobalKey<_FixtureState>();
    await tester.pumpWidget(_host(_Fixture(key: key)));
    final state = key.currentState!;
    state.outside.requestFocus();
    await tester.pump();
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('target'))),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();
    expect(find.byType(CarbonMenu), findsOneWidget);
    state.refresh(() => state.showRegion = false);
    await tester.pumpAndSettle();
    expect(find.byType(CarbonMenu), findsNothing);
    expect(state.outside.hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _open(WidgetTester tester, String shortcut) async {
  if (shortcut == 'Shift+F10') {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  } else {
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
  }
  await tester.pumpAndSettle();
}

Widget _host(Widget child, [TextDirection direction = TextDirection.ltr]) =>
    Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(builder: (_) => Center(child: child)),
            ],
          ),
        ),
      ),
    );

class _Fixture extends StatefulWidget {
  const _Fixture({
    super.key,
    this.empty = false,
    this.allDisabled = false,
    this.handoff = false,
  });
  final bool empty;
  final bool allDisabled;
  final bool handoff;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  final target = FocusNode(debugLabel: 'First context target');
  final second = FocusNode(debugLabel: 'Second context target');
  final outside = FocusNode(debugLabel: 'Outside context region');
  bool enabled = true;
  bool showTarget = true;
  bool showRegion = true;
  bool canFocus = true;
  int actions = 0;
  int bubbled = 0;
  void refresh(VoidCallback change) => setState(change);
  @override
  void dispose() {
    target.dispose();
    second.dispose();
    outside.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.f10 ||
              event.logicalKey == LogicalKeyboardKey.contextMenu)) {
        bubbled++;
      }
      return KeyEventResult.ignored;
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (showRegion)
          CarbonContextMenu(
            enabled: enabled,
            items: widget.empty
                ? <Widget>[]
                : <Widget>[
                    const CarbonMenuItem(label: 'Unavailable', disabled: true),
                    CarbonMenuItem(
                      label: 'Cut',
                      disabled: widget.allDisabled,
                      onPressed: () {
                        actions++;
                        if (widget.handoff) outside.requestFocus();
                      },
                    ),
                    CarbonMenuItem(
                      label: 'Copy',
                      disabled: widget.allDisabled,
                      onPressed: () {},
                    ),
                  ],
            child: SizedBox(
              width: 400,
              height: 140,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 40,
                  top: 8,
                  end: 100,
                ),
                child: Column(
                  children: <Widget>[
                    if (showTarget)
                      Focus(
                        focusNode: target,
                        canRequestFocus: canFocus,
                        child: const SizedBox(
                          key: ValueKey('target'),
                          width: 200,
                          height: 40,
                          child: Text('Target'),
                        ),
                      ),
                    Focus(
                      focusNode: second,
                      child: const SizedBox(
                        width: 150,
                        height: 40,
                        child: Text('Second target'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Focus(
          focusNode: outside,
          child: const SizedBox(width: 200, height: 40, child: Text('Outside')),
        ),
      ],
    ),
  );
}
