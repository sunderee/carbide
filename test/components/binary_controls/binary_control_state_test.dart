// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

enum _Kind { checkbox, radio, toggle }

Widget _control(
  _Kind kind, {
  required bool value,
  required bool readOnly,
  required bool callback,
  bool disabled = false,
  String readOnlyHint = 'Read only',
  required FocusNode? focus,
  required VoidCallback change,
}) => switch (kind) {
  _Kind.checkbox => CarbonCheckbox(
    label: 'Control',
    value: value,
    readOnly: readOnly,
    disabled: disabled,
    readOnlyHint: readOnlyHint,
    focusNode: focus,
    onChanged: callback ? (_) => change() : null,
  ),
  _Kind.radio => CarbonRadioButton(
    label: 'Control',
    selected: value,
    readOnly: readOnly,
    disabled: disabled,
    readOnlyHint: readOnlyHint,
    focusNode: focus,
    onSelected: callback ? change : null,
  ),
  _Kind.toggle => CarbonToggle(
    labelText: 'Control',
    toggled: value,
    readOnly: readOnly,
    disabled: disabled,
    readOnlyHint: readOnlyHint,
    focusNode: focus,
    onToggled: callback ? (_) => change() : null,
  ),
};

Widget _host(Widget control, FocusNode before, FocusNode after) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (BuildContext context, Widget? child) => Directionality(
    textDirection: TextDirection.ltr,
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Focus(
                focusNode: before,
                includeSemantics: false,
                child: const SizedBox(width: 40, height: 40),
              ),
              control,
              Focus(
                focusNode: after,
                includeSemantics: false,
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final _Kind kind in _Kind.values) {
    for (final bool value in <bool>[false, true]) {
      for (final String mode in <String>[
        'interactive',
        'read-only',
        'null callback',
        'read-only null callback',
        'explicit disabled',
        'read-only explicit disabled',
      ]) {
        testWidgets(
          '${kind.name} $mode exposes $value and the correct interaction state (#310)',
          (WidgetTester tester) async {
            final SemanticsHandle semantics = tester.ensureSemantics();
            final FocusNode before = FocusNode();
            final FocusNode controlFocus = FocusNode();
            final FocusNode after = FocusNode();
            final bool readOnly = mode.contains('read-only');
            final bool callback = !mode.contains('null callback');
            final bool disabled = mode.contains('explicit disabled');
            final bool focusable = callback && !disabled;
            final bool operable = focusable && !readOnly;
            int changes = 0;
            try {
              await tester.pumpWidget(
                _host(
                  _control(
                    kind,
                    value: value,
                    readOnly: readOnly,
                    disabled: disabled,
                    callback: callback,
                    focus: controlFocus,
                    change: () => changes++,
                  ),
                  before,
                  after,
                ),
              );
              await tester.pumpAndSettle();
              final SemanticsNode node = tester.getSemantics(
                find.bySemanticsLabel('Control'),
              );
              expect(
                node,
                isSemantics(
                  label: 'Control',
                  hasEnabledState: true,
                  isEnabled: operable,
                  hint: focusable && readOnly ? 'Read only' : '',
                  isFocusable: focusable,
                  hasCheckedState: kind != _Kind.toggle,
                  isChecked: kind != _Kind.toggle && value,
                  // Flutter exposes switches through hasToggledState, rather than
                  // hasCheckedState. Preserve that role and its on/off state.
                  hasToggledState: kind == _Kind.toggle,
                  isToggled: kind == _Kind.toggle && value,
                ),
              );
              before.requestFocus();
              await tester.pump();
              await tester.sendKeyEvent(LogicalKeyboardKey.tab);
              await tester.pumpAndSettle();
              expect(controlFocus.hasPrimaryFocus, focusable);
              expect(after.hasPrimaryFocus, !focusable);
              if (focusable) {
                await tester.sendKeyEvent(LogicalKeyboardKey.enter);
                await tester.sendKeyEvent(LogicalKeyboardKey.space);
              }
              tester
                  .renderObject(find.bySemanticsLabel('Control'))
                  .owner!
                  .semanticsOwner!
                  .performAction(node.id, SemanticsAction.tap);
              await tester.pumpAndSettle();
              await tester.tap(find.bySemanticsLabel('Control'));
              await tester.pumpAndSettle();
              expect(changes, operable ? 4 : 0);
              expect(tester.takeException(), isNull);
            } finally {
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pumpAndSettle();
              before.dispose();
              controlFocus.dispose();
              after.dispose();
              semantics.dispose();
            }
          },
        );
      }
    }
  }
  for (final _Kind kind in _Kind.values) {
    for (final String policy in <String>[
      'read-only',
      'disabled',
      'null callback',
    ]) {
      testWidgets(
        '${kind.name} cancels a pending press on $policy and can recover (#310)',
        (WidgetTester tester) async {
          final FocusNode before = FocusNode();
          final FocusNode focus = FocusNode();
          final FocusNode after = FocusNode();
          final SemanticsHandle semantics = tester.ensureSemantics();
          int changes = 0;
          Widget build({bool restricted = false}) => _host(
            _control(
              kind,
              value: true,
              readOnly: restricted && policy == 'read-only',
              disabled: restricted && policy == 'disabled',
              callback: !(restricted && policy == 'null callback'),
              readOnlyHint: 'Nur lesen',
              focus: focus,
              change: () => changes++,
            ),
            before,
            after,
          );
          try {
            await tester.pumpWidget(build());
            await tester.pumpAndSettle();
            focus.requestFocus();
            await tester.pump();
            final TestGesture gesture = await tester.startGesture(
              tester.getCenter(find.bySemanticsLabel('Control')),
            );
            await tester.pump();
            await tester.pumpWidget(build(restricted: true));
            await tester.pumpAndSettle();
            await gesture.up();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.sendKeyEvent(LogicalKeyboardKey.space);
            final SemanticsNode node = tester.getSemantics(
              find.bySemanticsLabel('Control'),
            );
            tester
                .renderObject(find.bySemanticsLabel('Control'))
                .owner!
                .semanticsOwner!
                .performAction(node.id, SemanticsAction.tap);
            await tester.pumpAndSettle();
            expect(changes, 0);
            expect(
              node.getSemanticsData().hint,
              policy == 'read-only' ? 'Nur lesen' : '',
            );
            expect(focus.hasPrimaryFocus, policy == 'read-only');
            await tester.pumpWidget(build());
            await tester.pumpAndSettle();
            await tester.tap(find.bySemanticsLabel('Control'));
            expect(changes, 1);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            before.dispose();
            focus.dispose();
            after.dispose();
            semantics.dispose();
          }
        },
      );
    }
  }

  for (final _Kind kind in _Kind.values) {
    testWidgets(
      '${kind.name} disposes owned focus and keeps borrowed nodes reusable (#310)',
      (WidgetTester tester) async {
        final FocusNode before = FocusNode();
        final FocusNode after = FocusNode();
        final FocusNode a = FocusNode();
        final FocusNode b = FocusNode();
        void listener() {}
        Widget build(FocusNode? node) => _host(
          _control(
            kind,
            value: true,
            readOnly: true,
            callback: true,
            focus: node,
            change: () {},
          ),
          before,
          after,
        );
        try {
          await tester.pumpWidget(build(null));
          await tester.pumpAndSettle();
          final FocusNode owned = tester
              .widget<CarbonInteraction>(find.byType(CarbonInteraction))
              .focusNode!;
          before.requestFocus();
          await tester.pump();
          for (final FocusNode? node in <FocusNode?>[a, b, null]) {
            await tester.pumpWidget(build(node));
            await tester.pumpAndSettle();
            expect(before.hasPrimaryFocus, isTrue);
          }
          expect(() => owned.addListener(listener), throwsFlutterError);
          expect(a.parent, isNull);
          expect(b.parent, isNull);
          for (final FocusNode node in <FocusNode>[a, b]) {
            node.addListener(listener);
            node.removeListener(listener);
          }
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          before.dispose();
          after.dispose();
          a.dispose();
          b.dispose();
        }
      },
    );
  }

  testWidgets(
    'read-only radio groups remain inspectable without arrow selection (#310)',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      int changes = 0;
      try {
        await tester.pumpWidget(
          WidgetsApp(
            color: const Color(0xFFFFFFFF),
            builder: (_, _) => CarbonTheme(
              data: CarbonThemeData.white,
              child: Center(
                child: CarbonRadioButtonGroup<String>(
                  legend: 'Delivery',
                  options: const <(String, String)>[
                    ('a', 'Standard'),
                    ('b', 'Express'),
                  ],
                  value: 'a',
                  onChanged: (_) => changes++,
                  readOnly: true,
                  readOnlyHint: 'Nur lesen',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final FocusNode first = tester
            .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).first)
            .focusNode!;
        first.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();
        expect(changes, 0);
        expect(
          tester
              .widget<CarbonRadioButton>(find.byType(CarbonRadioButton).last)
              .focusNode!
              .hasPrimaryFocus,
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(first.hasPrimaryFocus, isTrue);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Express')),
          isSemantics(
            hint: 'Nur lesen',
            hasCheckedState: true,
            isChecked: false,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'binary enabled, read-only and disabled visuals across themes (#310)',
    (WidgetTester tester) async {
      final FocusNode readOnlyFocus = FocusNode();
      final FocusHighlightStrategy old =
          FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      try {
        await expectThemeGoldens(
          tester,
          name: 'binary_control_states',
          size: const Size(600, 540),
          containsText: true,
          afterPump: (WidgetTester tester) async {
            readOnlyFocus.requestFocus();
            await tester.pumpAndSettle();
          },
          builder: (BuildContext context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final _Kind kind in _Kind.values)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(kind.name),
                        const SizedBox(height: 16),
                        for (final String mode in <String>[
                          'Enabled',
                          'Read only',
                          'Disabled',
                        ])
                          for (final bool value in <bool>[false, true])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: switch (kind) {
                                _Kind.checkbox => CarbonCheckbox(
                                  label: '$mode $value',
                                  value: value,
                                  onChanged: (_) {},
                                  readOnly: mode == 'Read only',
                                  disabled: mode == 'Disabled',
                                  focusNode: mode == 'Read only' && value
                                      ? readOnlyFocus
                                      : null,
                                ),
                                _Kind.radio => CarbonRadioButton(
                                  label: '$mode $value',
                                  selected: value,
                                  onSelected: () {},
                                  readOnly: mode == 'Read only',
                                  disabled: mode == 'Disabled',
                                ),
                                _Kind.toggle => CarbonToggle(
                                  labelText: '$mode $value',
                                  toggled: value,
                                  onToggled: (_) {},
                                  readOnly: mode == 'Read only',
                                  disabled: mode == 'Disabled',
                                ),
                              },
                            ),
                        if (kind == _Kind.checkbox)
                          CarbonCheckbox(
                            label: 'Read only mixed',
                            value: false,
                            indeterminate: true,
                            readOnly: true,
                            onChanged: (_) {},
                          ),
                        if (kind == _Kind.toggle)
                          CarbonToggle(
                            labelText: 'Read only small',
                            toggled: true,
                            size: CarbonToggleSize.sm,
                            readOnly: true,
                            onToggled: (_) {},
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        readOnlyFocus.dispose();
        FocusManager.instance.highlightStrategy = old;
      }
    },
  );
}
