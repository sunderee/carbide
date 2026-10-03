// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';
import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/dialog_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final DialogKind kind in DialogKind.values) {
    for (final String policy in <String>['passive', 'confirmation', 'danger']) {
      _test('native ${kind.name}: $policy initial focus', (
        WidgetTester tester,
      ) async {
        final DialogFixtureState state = await _mount(
          tester,
          kind,
          danger: policy == 'danger',
          passive: policy == 'passive',
        );
        expect(
          _activeName,
          kind == DialogKind.nonModalDialog
              ? 'Launcher'
              : policy == 'danger'
              ? 'Cancel'
              : 'Close',
        );
        expect(state.primaryPresses, 0);
      });
    }

    _test('native ${kind.name}: forward and backward keyboard traversal', (
      WidgetTester tester,
    ) async {
      await _mount(tester, kind);
      _button('Save').focus();
      await _settle(tester);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(
        _activeName,
        kind == DialogKind.nonModalDialog ? 'Launcher' : 'Close',
      );
      _button('Close').focus();
      await _settle(tester);
      await _key(tester, LogicalKeyboardKey.tab, backwards: true);
      expect(_activeName, kind == DialogKind.nonModalDialog ? 'After' : 'Save');
      if (kind != DialogKind.nonModalDialog) {
        for (final bool backwards in <bool>[false, true]) {
          final Set<String?> visited = <String?>{};
          for (int i = 0; i < 12; i++) {
            await _key(tester, LogicalKeyboardKey.tab, backwards: backwards);
            expect(_activeName, isNot(anyOf('Launcher', 'After')));
            visited.add(_activeName);
          }
          expect(
            visited,
            containsAll(<String>[
              'Close',
              'First inside',
              'Second inside',
              'Cancel',
              'Save',
            ]),
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
      _test('native ${kind.name}: $path dismissal', (
        WidgetTester tester,
      ) async {
        final DialogFixtureState state = await _mount(tester, kind);
        _button('Second inside').focus();
        await _settle(tester);
        switch (path) {
          case 'button':
            await tester.tap(find.bySemanticsLabel('Close'));
          case 'escape':
            await _key(tester, LogicalKeyboardKey.escape);
          case 'semantics':
            _button('Close').click();
          case 'outside':
            await tester.tapAt(
              Offset(
                tester.view.physicalSize.width / tester.view.devicePixelRatio -
                    5,
                tester.view.physicalSize.height / tester.view.devicePixelRatio -
                    5,
              ),
            );
          case 'programmatic':
            state.hide();
        }
        await _settle(tester);
        if (path == 'outside' && kind != DialogKind.modal) {
          expect(state.open, isTrue);
          expect(state.closes, 0);
          expect(_activeName, 'Second inside');
        } else {
          expect(state.open, isFalse);
          expect(state.closes, path == 'programmatic' ? 0 : 1);
          if (kind != DialogKind.nonModalDialog) {
            expect(_activeName, 'Launcher');
          }
        }
        expect(tester.takeException(), isNull);
      });
    }

    _test('native ${kind.name}: removed opener cannot receive restoration', (
      WidgetTester tester,
    ) async {
      final DialogFixtureState state = await _mount(tester, kind);
      state.removeLauncher();
      await _settle(tester);
      state.hide();
      await _settle(tester);
      expect(state.open, isFalse);
      expect(tester.takeException(), isNull);
      _button('After').focus();
      await _settle(tester);
      expect(_activeName, 'After');
    });
  }

  _test('native non-modal close preserves a new page focus target', (
    WidgetTester tester,
  ) async {
    final DialogFixtureState state = await _mount(
      tester,
      DialogKind.nonModalDialog,
    );
    _button('After').focus();
    await _settle(tester);
    await _key(tester, LogicalKeyboardKey.escape);
    expect(state.open, isTrue);
    expect(state.closes, 0);
    state.hide();
    await _settle(tester);
    expect(_activeName, 'After');
  });
}

void _test(String name, WidgetTesterCallback body) =>
    testWidgets(name, (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _settle(tester);
        handle.dispose();
      }
    });

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
  await _settle(tester);
  _document.querySelectorAll('flutter-view').item(0)!.focus();
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  _button('Launcher').focus();
  await _settle(tester);
  await tester.tap(find.text('Launcher'));
  await _settle(tester);
  return key.currentState!;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 60));
  await tester.pumpAndSettle();
}

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool backwards = false,
}) async {
  // Release builds strip diagnostic key names; always supply physical keys.
  final PhysicalKeyboardKey physical = key == LogicalKeyboardKey.tab
      ? PhysicalKeyboardKey.tab
      : PhysicalKeyboardKey.escape;
  if (backwards) {
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey.shiftLeft,
      physicalKey: PhysicalKeyboardKey.shiftLeft,
    );
  }
  await tester.sendKeyEvent(key, physicalKey: physical);
  if (backwards) {
    await tester.sendKeyUpEvent(
      LogicalKeyboardKey.shiftLeft,
      physicalKey: PhysicalKeyboardKey.shiftLeft,
    );
  }
  await _settle(tester);
}

_Element _button(String name) {
  final _NodeList nodes = _document.querySelectorAll(
    'flt-semantics[role="button"]',
  );
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if (node.getAttribute('aria-label') == name ||
        node.textContent?.trim() == name) {
      return node;
    }
  }
  throw StateError('Missing native button $name');
}

String? get _activeName =>
    _document.activeElement?.getAttribute('aria-label') ??
    _document.activeElement?.textContent?.trim();

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
  external _Element? get activeElement;
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? get textContent;
  external String? getAttribute(String name);
  external void focus();
  external void click();
}
