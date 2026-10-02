// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final bool range in <bool>[false, true]) {
    testWidgets('native slider policy and role transitions, range=$range', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        final _FixtureState state = await _mount(tester, range: range);
        for (final (bool disabled, bool readOnly, bool callback)
            in <(bool, bool, bool)>[
              (false, false, true),
              (true, false, true),
              (false, true, true),
              (true, true, true),
              (false, false, false),
              (false, false, true),
            ]) {
          state.configure(
            disabled: disabled,
            readOnly: readOnly,
            callback: callback,
          );
          await _settle(tester);
          final bool enabled = !disabled && !readOnly && callback;
          for (final bool upper in <bool>[false, if (range) true]) {
            final _Element slider = _slider(range: range, upper: upper);
            expect(slider.getAttribute('aria-disabled'), (!enabled).toString());
            expect(slider.getAttribute('aria-readonly'), readOnly.toString());
            expect(slider.getAttribute('aria-valuenow'), upper ? '70' : '40');
            expect(slider.getAttribute('aria-valuetext'), upper ? '70' : '40');
            expect(slider.getAttribute('aria-valuemin'), upper ? '40' : '0');
            expect(
              slider.getAttribute('aria-valuemax'),
              range && !upper ? '70' : '100',
            );
            expect(
              slider.getAttribute('tabindex'),
              !disabled && callback ? '0' : '-1',
            );
          }
          if (!range) {
            expect(_input().disabled, disabled || !callback);
            expect(_input().readOnly, !enabled);
            expect(_input().value, '40');
          }
          expect(state.lowerChanges, isEmpty);
          expect(state.upperChanges, isEmpty);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    });
  }

  testWidgets(
    'native adjustment changes each handle once and late events are gated',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        final _FixtureState state = await _mount(tester, range: true);
        final _Element lower = _slider(range: true, upper: false);
        final _Element upper = _slider(range: true, upper: true);
        _adjust(lower, 1);
        await _settle(tester);
        expect(state.value, 45);
        expect(state.lowerChanges, <num>[45]);
        expect(_slider(range: true).getAttribute('aria-valuenow'), '45');
        _adjust(upper, -1);
        await _settle(tester);
        expect(state.upper, 65);
        expect(state.upperChanges, <num>[65]);
        state.configure(readOnly: true);
        await _settle(tester);
        // These detached native inputs held the old adjustment listeners.
        _adjust(lower, 1);
        _adjust(upper, -1);
        await _settle(tester);
        expect(state.lowerChanges, <num>[45]);
        expect(state.upperChanges, <num>[65]);
        expect(_slider(range: true).getAttribute('aria-valuenow'), '45');
        expect(
          _slider(range: true, upper: true).getAttribute('aria-valuenow'),
          '65',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    },
  );

  testWidgets(
    'a rejected controlled adjustment keeps the native announced value',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        final _FixtureState state = await _mount(tester, accept: false);
        _adjust(_slider(), 1);
        await _settle(tester);
        expect(state.lowerChanges, <num>[45]);
        expect(state.value, 40);
        expect(_slider().getAttribute('aria-valuenow'), '40');
        expect(_slider().getAttribute('aria-valuetext'), '40');
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    },
  );

  for (final bool readOnly in <bool>[false, true]) {
    testWidgets(
      'a native value draft is discarded on policy change, readOnly=$readOnly',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        try {
          final _FixtureState state = await _mount(tester);
          final EditableText editable = tester.widget<EditableText>(
            find.byType(EditableText),
          );
          editable.focusNode.requestFocus();
          await _settle(tester);
          _input().focus();
          await tester.tap(find.byType(EditableText));
          await _settle(tester);
          _input().value = '90';
          _input().setSelectionRange(2, 2);
          _input().dispatchEvent(
            _InputEvent('input', _Options(data: '90', bubbles: true)),
          );
          await _settle(tester);
          expect(editable.controller.text, '90');
          expect(state.lowerChanges, isEmpty);
          final ValueChanged<String> staleSubmit = editable.onSubmitted!;
          state.configure(disabled: !readOnly, readOnly: readOnly);
          await _settle(tester);
          staleSubmit('90');
          state.outside.requestFocus();
          await _settle(tester);
          expect(state.value, 40);
          expect(state.lowerChanges, isEmpty);
          expect(_input().value, '40');
          state.configure(disabled: false, readOnly: false);
          await _settle(tester);
          expect(state.lowerChanges, isEmpty);
          expect(_input().disabled, isFalse);
          expect(_input().readOnly, isFalse);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          handle.dispose();
        }
      },
    );
  }

  testWidgets(
    'late accessibility and disposal preserve a static read-only range',
    (WidgetTester tester) async {
      final _FixtureState state = await _mount(
        tester,
        range: true,
        readOnly: true,
      );
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await _settle(tester);
        expect(_slider(range: true).getAttribute('aria-readonly'), 'true');
        expect(
          _slider(range: true, upper: true).getAttribute('aria-valuenow'),
          '70',
        );
        state.configure(disabled: true);
        await tester.pumpWidget(const SizedBox.shrink());
        await _settle(tester);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        handle.dispose();
      }
    },
  );
}

Future<_FixtureState> _mount(
  WidgetTester tester, {
  bool range = false,
  bool accept = true,
  bool readOnly = false,
}) async {
  final GlobalKey<_FixtureState> key = GlobalKey<_FixtureState>();
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xffffffff),
      builder: (BuildContext context, Widget? _) => CarbonTheme(
        data: CarbonThemeData.white,
        child: Center(
          child: SizedBox(
            width: 400,
            child: _Fixture(
              key: key,
              range: range,
              accept: accept,
              readOnly: readOnly,
            ),
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
  return key.currentState!;
}

class _Fixture extends StatefulWidget {
  const _Fixture({
    super.key,
    required this.range,
    required this.accept,
    required this.readOnly,
  });
  final bool range;
  final bool accept;
  final bool readOnly;
  @override
  State<_Fixture> createState() => _FixtureState();
}

class _FixtureState extends State<_Fixture> {
  num value = 40, upper = 70;
  bool disabled = false, callback = true;
  late bool readOnly = widget.readOnly;
  final List<num> lowerChanges = <num>[], upperChanges = <num>[];
  final FocusNode outside = FocusNode();
  void configure({bool? disabled, bool? readOnly, bool? callback}) =>
      setState(() {
        this.disabled = disabled ?? this.disabled;
        this.readOnly = readOnly ?? this.readOnly;
        this.callback = callback ?? this.callback;
      });
  @override
  void dispose() {
    outside.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      CarbonSlider(
        labelText: 'Volume',
        value: value,
        upperValue: widget.range ? upper : null,
        min: 0,
        max: 100,
        step: 5,
        disabled: disabled,
        readOnly: readOnly,
        onChanged: !callback
            ? null
            : (num next) {
                lowerChanges.add(next);
                if (widget.accept) setState(() => value = next);
              },
        onUpperChanged: !widget.range
            ? null
            : (num next) {
                upperChanges.add(next);
                setState(() => upper = next);
              },
      ),
      Focus(focusNode: outside, child: const Text('Outside')),
    ],
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

_Element _slider({
  bool range = false,
  bool upper = false,
}) => _document.querySelector(
  '[role="slider"][aria-label="${range ? 'Volume ${upper ? 'upper' : 'lower'}' : 'Volume'}"]',
)!;
_Element _input() =>
    _document.querySelector('input[aria-label="Volume value"]')!;

void _adjust(_Element input, int delta) {
  // Native accessibility/browser gesture mode enables the surrogate range.
  // Simulate its change event without changing the engine's internal counter.
  input.disabled = false;
  input.value = (int.parse(input.value) + delta).toString();
  input.dispatchEvent(_Event('change', _Options(bubbles: true)));
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selector);
}

extension type _Element(JSObject _) implements JSObject {
  external String get value;
  external set value(String value);
  external bool get disabled;
  external set disabled(bool value);
  external bool get readOnly;
  external String? getAttribute(String name);
  external void focus();
  external void setSelectionRange(int start, int end);
  external bool dispatchEvent(JSObject event);
}

@JS()
extension type _Options._(JSObject _) implements JSObject {
  external factory _Options({String data, bool bubbles});
}

@JS('Event')
extension type _Event._(JSObject _) implements JSObject {
  external factory _Event(String type, _Options options);
}

@JS('InputEvent')
extension type _InputEvent._(JSObject _) implements JSObject {
  external factory _InputEvent(String type, _Options options);
}
