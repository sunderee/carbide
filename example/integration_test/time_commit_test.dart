// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/time_commit_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final (
        String name,
        CarbonTimeFormat format,
        String draft,
        String expected,
      )
      in <(String, CarbonTimeFormat, String, String)>[
        ('24', CarbonTimeFormat.twentyFourHour, '3:5', '03:05'),
        ('12', CarbonTimeFormat.twelveHour, '3:5', '03:05'),
        ('dot', dotTimeFormat, '3.5', '03.05'),
      ]) {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('native $name commits/invalid/group-blur $direction', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          final TimeCommitFixtureState state = await _mount(
            tester,
            format,
            direction,
          );
          state.focus.requestFocus();
          await _settle(tester);
          _input(draft);
          await _settle(tester);
          expect(state.edits, isEmpty);
          expect(state.times, isEmpty);
          await _enter(tester);
          expect(state.controller.text, expected);
          expect(_native().value, expected);
          expect(state.edits, <String>[expected]);
          expect(state.times, <CarbonTimeValue?>[
            const CarbonTimeValue(hour: 3, minute: 5),
          ]);
          await _enter(tester);
          expect(state.times, hasLength(1));
          _input('banana');
          await _enter(tester);
          expect(_native().value, 'banana');
          expect(find.text('Enter a valid time'), findsOneWidget);
          expect(state.times, hasLength(1));
          _input(draft);
          await _settle(tester);
          if (format.hourCycle == CarbonTimeHourCycle.twelveHour) {
            await tester.sendKeyEvent(
              LogicalKeyboardKey.tab,
              physicalKey: PhysicalKeyboardKey.tab,
            );
            await _settle(tester);
            expect(state.times, hasLength(1));
            await tester.sendKeyEvent(
              LogicalKeyboardKey.space,
              physicalKey: PhysicalKeyboardKey.space,
            );
            await _settle(tester);
            await tester.sendKeyEvent(
              LogicalKeyboardKey.arrowDown,
              physicalKey: PhysicalKeyboardKey.arrowDown,
            );
            await tester.sendKeyEvent(
              LogicalKeyboardKey.enter,
              physicalKey: PhysicalKeyboardKey.enter,
            );
            await _settle(tester);
            expect(state.periods, <CarbonTimePeriod>[CarbonTimePeriod.pm]);
            expect(
              state.times.last,
              const CarbonTimeValue(hour: 15, minute: 5),
            );
          } else {
            await tester.sendKeyEvent(
              LogicalKeyboardKey.tab,
              physicalKey: PhysicalKeyboardKey.tab,
            );
            await _settle(tester);
            expect(state.times, hasLength(1));
            state.outside.requestFocus();
            await _settle(tester);
            expect(state.times, hasLength(2));
          }
          expect(_native().value, expected);
          expect(find.text('Enter a valid time'), findsNothing);
          state.focus.requestFocus();
          await _settle(tester);
          _input('');
          await _enter(tester);
          expect(state.times.last, isNull);
          expect(_native().value, '');
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('native composition candidate Enter stays draft until end', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      final TimeCommitFixtureState state = await _mount(
        tester,
        CarbonTimeFormat.twentyFourHour,
        TextDirection.ltr,
      );
      state.focus.requestFocus();
      await _settle(tester);
      _native().focus();
      _native().dispatchEvent(
        _CompositionEvent(
          'compositionstart',
          _EventOptions(data: '', bubbles: true),
        ),
      );
      _native().dispatchEvent(
        _CompositionEvent(
          'compositionupdate',
          _EventOptions(data: '3:5', bubbles: true),
        ),
      );
      _input('3:5');
      await _settle(tester);
      expect(
        state.controller.value.composing,
        const TextRange(start: 0, end: 3),
      );
      await _enter(tester);
      tester
          .widget<EditableText>(find.byType(EditableText))
          .onEditingComplete!();
      await _settle(tester);
      expect(state.edits, isEmpty);
      expect(_native().value, '3:5');
      _native().dispatchEvent(
        _CompositionEvent(
          'compositionend',
          _EventOptions(data: '3:5', bubbles: true),
        ),
      );
      await _settle(tester);
      expect(state.controller.value.composing, TextRange.empty);
      await _enter(tester);
      expect(state.edits, <String>['03:05']);
      expect(_native().value, '03:05');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
      semantics.dispose();
    }
  });

  testWidgets('native readonly/disabled rebuilds and late semantics values', (
    WidgetTester tester,
  ) async {
    final TimeCommitFixtureState state = await _mount(
      tester,
      CarbonTimeFormat.twentyFourHour,
      TextDirection.ltr,
    );
    state.controller.text = '03:05';
    final SemanticsHandle semantics = tester.ensureSemantics();
    try {
      await _settle(tester);
      expect(_native().value, '03:05');
      state.configure(readOnly: true);
      await _settle(tester);
      expect(_native().readOnly, isTrue);
      state.configure(readOnly: false, disabled: true);
      await _settle(tester);
      expect(_native().disabled, isTrue);
      state.configure(disabled: false);
      await _settle(tester);
      expect(_native().disabled, isFalse);
      expect(_native().readOnly, isFalse);
      expect(state.times, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
      semantics.dispose();
    }
  });
}

Future<TimeCommitFixtureState> _mount(
  WidgetTester tester,
  CarbonTimeFormat format,
  TextDirection direction,
) async {
  final GlobalKey<TimeCommitFixtureState> key =
      GlobalKey<TimeCommitFixtureState>();
  await tester.pumpWidget(
    timeCommitHost(
      TimeCommitFixture(key: key, format: format),
      direction: direction,
    ),
  );
  await _settle(tester);
  return key.currentState!;
}

Future<void> _enter(WidgetTester tester) async {
  await tester.sendKeyEvent(
    LogicalKeyboardKey.enter,
    physicalKey: PhysicalKeyboardKey.enter,
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

_Element _native() {
  final _NodeList nodes = _document.querySelectorAll('flt-semantics input');
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if (node.getAttribute('aria-label') == 'Time') return node;
  }
  throw StateError('No native input named Time');
}

void _input(String text) {
  final _Element input = _native();
  input.focus();
  input.value = text;
  input.setSelectionRange(text.length, text.length);
  input.dispatchEvent(
    _InputEvent('input', _EventOptions(data: text, bubbles: true)),
  );
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}

extension type _Element(JSObject _) implements JSObject {
  external String? getAttribute(String name);
  external String get value;
  external set value(String value);
  external bool get readOnly;
  external bool get disabled;
  external void focus();
  external void setSelectionRange(int start, int end);
  external bool dispatchEvent(JSObject event);
}

@JS()
extension type _EventOptions._(JSObject _) implements JSObject {
  external factory _EventOptions({String data, bool bubbles});
}

@JS('InputEvent')
extension type _InputEvent._(JSObject _) implements JSObject {
  external factory _InputEvent(String type, _EventOptions options);
}

@JS('CompositionEvent')
extension type _CompositionEvent._(JSObject _) implements JSObject {
  external factory _CompositionEvent(String type, _EventOptions options);
}
