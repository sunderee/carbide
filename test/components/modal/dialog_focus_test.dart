// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/dialog_fixture.dart';
import '../../support/overlay_entries.dart';

FocusNode _buttonFocus(WidgetTester tester, String label) {
  final Finder button = find.bySemanticsLabel(label);
  final Finder target = find.descendant(
    of: button,
    matching: find.byType(GestureDetector),
  );
  return Focus.of(tester.element(target.last));
}

Future<void> _tab(WidgetTester tester, {bool backwards = false}) async {
  if (backwards) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  if (backwards) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.pumpAndSettle();
}

Future<DialogFixtureState> _mount(
  WidgetTester tester,
  DialogKind kind, {
  bool danger = false,
  bool passive = false,
}) async {
  final GlobalKey<DialogFixtureState> key = GlobalKey<DialogFixtureState>();
  await tester.pumpWidget(
    dialogTestApp(
      fixtureKey: key,
      kind: kind,
      danger: danger,
      passive: passive,
    ),
  );
  await tester.pumpAndSettle();
  final DialogFixtureState state = key.currentState!;
  state.before.requestFocus();
  await tester.pump();
  state.show();
  await tester.pumpAndSettle();
  return state;
}

void _test(String name, WidgetTesterCallback body) =>
    testWidgets(name, (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        handle.dispose();
      }
    });

void main() {
  for (final DialogKind kind in DialogKind.values) {
    group(kind.name, () {
      for (final String policy in <String>[
        'passive',
        'confirmation',
        'danger',
      ]) {
        _test('$policy initial focus is safe and documented (#306)', (
          WidgetTester tester,
        ) async {
          final DialogFixtureState state = await _mount(
            tester,
            kind,
            danger: policy == 'danger',
            passive: policy == 'passive',
          );
          if (kind == DialogKind.nonModalDialog) {
            expect(state.before.hasPrimaryFocus, isTrue);
          } else {
            expect(
              _buttonFocus(
                tester,
                policy == 'danger' ? 'Cancel' : 'Close',
              ).hasPrimaryFocus,
              isTrue,
            );
          }
          expect(state.primaryPresses, 0);
        });
      }

      // The pre-fix modal scopes already closed the traversal loop. These
      // regressions preserve it without adding another traversal policy.
      _test('forward and reverse Tab prove the focus contract (#306)', (
        WidgetTester tester,
      ) async {
        final DialogFixtureState state = await _mount(tester, kind);
        final FocusNode close = _buttonFocus(tester, 'Close');
        final FocusNode last = _buttonFocus(tester, 'Save');
        last.requestFocus();
        await tester.pump();
        await _tab(tester);
        if (kind == DialogKind.nonModalDialog) {
          expect(state.before.hasPrimaryFocus, isTrue);
          close.requestFocus();
          await tester.pump();
          await _tab(tester, backwards: true);
          expect(state.after.hasPrimaryFocus, isTrue);
        } else {
          expect(close.hasPrimaryFocus, isTrue);
          await _tab(tester, backwards: true);
          expect(last.hasPrimaryFocus, isTrue);
          for (final bool backwards in <bool>[false, true]) {
            final Set<FocusNode> visited = <FocusNode>{};
            for (int i = 0; i < 18; i++) {
              await _tab(tester, backwards: backwards);
              expect(state.before.hasFocus, isFalse);
              expect(state.after.hasFocus, isFalse);
              visited.add(FocusManager.instance.primaryFocus!);
            }
            expect(
              visited,
              containsAll(<FocusNode>[close, state.first, state.second, last]),
            );
          }
        }
      });

      for (final String path in <String>[
        'button',
        'escape',
        'semantics',
        'outside',
        'programmatic',
      ]) {
        _test('$path close has the expected callback and focus (#306)', (
          WidgetTester tester,
        ) async {
          final DialogFixtureState state = await _mount(tester, kind);
          state.second.requestFocus();
          await tester.pump();
          switch (path) {
            case 'button':
              await tester.tap(find.bySemanticsLabel('Close'));
            case 'escape':
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            case 'semantics':
              tester
                  .renderObject(find.bySemanticsLabel('Close'))
                  .owner!
                  .semanticsOwner!
                  .performAction(
                    tester.getSemantics(find.bySemanticsLabel('Close')).id,
                    SemanticsAction.tap,
                  );
            case 'outside':
              await tester.tapAt(const Offset(790, 590));
            case 'programmatic':
              state.hide();
          }
          await tester.pumpAndSettle();
          if (path == 'outside' && kind != DialogKind.modal) {
            // The composable Dialog follows native <dialog>: backdrop
            // clicks do not request dismissal, in either mode.
            expect(state.open, isTrue);
            expect(state.closes, 0);
            expect(state.second.hasPrimaryFocus, isTrue);
          } else {
            expect(state.open, isFalse);
            expect(state.closes, path == 'programmatic' ? 0 : 1);
            if (kind != DialogKind.nonModalDialog) {
              expect(state.before.hasPrimaryFocus, isTrue);
            }
          }
          expect(tester.takeException(), isNull);
        });
      }

      _test('disposed opener is not restored (#306)', (
        WidgetTester tester,
      ) async {
        final DialogFixtureState state = await _mount(tester, kind);
        state.removeLauncher();
        await tester.pumpAndSettle();
        state.hide();
        await tester.pumpAndSettle();
        expect(state.open, isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });

      _test('reopening captures the current launcher (#306)', (
        WidgetTester tester,
      ) async {
        final DialogFixtureState state = await _mount(tester, kind);
        state.hide();
        await tester.pumpAndSettle();
        state.after.requestFocus();
        await tester.pump();
        state.show();
        await tester.pumpAndSettle();
        if (kind == DialogKind.nonModalDialog) {
          state.before.requestFocus();
          await tester.pump();
        }
        state.hide();
        await tester.pumpAndSettle();
        expect(state.after.hasPrimaryFocus, kind != DialogKind.nonModalDialog);
        if (kind == DialogKind.nonModalDialog) {
          expect(state.before.hasPrimaryFocus, isTrue);
        }
        expect(tester.takeException(), isNull);
      });

      if (kind == DialogKind.nonModalDialog) {
        _test('focus picked on the page survives a non-modal close (#306)', (
          WidgetTester tester,
        ) async {
          final DialogFixtureState state = await _mount(tester, kind);
          state.after.requestFocus();
          await tester.pump();
          state.hide();
          await tester.pumpAndSettle();
          expect(state.after.hasPrimaryFocus, isTrue);
        });
      }
      if (kind != DialogKind.modal) {
        _test('changing modal mode reconciles live focus (#306)', (
          WidgetTester tester,
        ) async {
          final DialogFixtureState state = await _mount(tester, kind);
          final bool nextModal = kind == DialogKind.nonModalDialog;
          (nextModal ? state.after : state.first).requestFocus();
          await tester.pump();
          state.setModal(nextModal);
          await tester.pumpAndSettle();
          if (nextModal) {
            expect(_buttonFocus(tester, 'Close').hasPrimaryFocus, isTrue);
            expect(state.after.hasFocus, isFalse);
          } else {
            expect(state.first.hasPrimaryFocus, isTrue);
            expect(state.before.hasFocus, isFalse);
          }
        });
      }
    });
  }

  _test('a destructive primary action is never the initial fallback (#306)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xffffffff),
        builder: (BuildContext context, Widget? child) => CarbonTheme(
          data: CarbonThemeData.white,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (BuildContext context) => CarbonModal(
                  open: true,
                  danger: true,
                  title: 'Delete permanently',
                  primaryButton: CarbonModalAction(
                    label: 'Delete',
                    onPressed: () {},
                  ),
                  child: const Text('No safe action is available.'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_buttonFocus(tester, 'Delete').hasPrimaryFocus, isFalse);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'CarbonModal');
  });
}
