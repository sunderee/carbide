// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(
  Widget password, {
  FocusNode? before,
  FocusNode? after,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  builder: (_, _) => Directionality(
    textDirection: direction,
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Center(
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonButton(
                label: 'Before',
                focusNode: before,
                onPressed: () {},
              ),
              password,
              CarbonButton(label: 'After', focusNode: after, onPressed: () {}),
            ],
          ),
        ),
      ),
    ),
  ),
);

EditableText _editor(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText));

void _focusInput(WidgetTester tester, FocusNode input) {
  // A newly opened browser test view has not received a platform focus event.
  // Model entering the view before exercising traversal, as the native fixture
  // and real gallery pointer/keyboard interaction do.
  tester.binding.handleViewFocusChanged(
    ViewFocusEvent(
      viewId: tester.view.viewId,
      state: ViewFocusState.focused,
      direction: ViewFocusDirection.undefined,
    ),
  );
  input.requestFocus();
}

void _semanticsTap(WidgetTester tester, String label) {
  final Finder button = find.bySemanticsLabel(label);
  final SemanticsNode node = tester.getSemantics(button);
  tester
      .renderObject(button)
      .owner!
      .semanticsOwner!
      .performAction(node.id, SemanticsAction.tap);
}

void main() {
  for (final bool readOnly in <bool>[false, true]) {
    for (final String path in <String>[
      'Enter',
      'Space',
      'pointer',
      'semantics',
    ]) {
      testWidgets('$path reveals and hides once, readOnly=$readOnly (#308)', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final FocusNode input = FocusNode();
        final TextEditingController controller =
            TextEditingController.fromValue(
              const TextEditingValue(
                text: 'secret',
                selection: TextSelection(baseOffset: 2, extentOffset: 4),
              ),
            );
        int edits = 0;
        try {
          await tester.pumpWidget(
            _host(
              CarbonPasswordInput(
                labelText: 'Password',
                controller: controller,
                focusNode: input,
                readOnly: readOnly,
                onChanged: (_) => edits++,
                showPasswordLabel: 'Anzeigen',
                hidePasswordLabel: 'Ausblenden',
              ),
            ),
          );
          await tester.pumpAndSettle();
          _focusInput(tester, input);
          await tester.pumpAndSettle();
          final TextEditingValue original = controller.value;
          if (path == 'Enter' || path == 'Space') {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pumpAndSettle();
            expect(
              tester.getSemantics(find.bySemanticsLabel('Anzeigen')),
              isSemantics(isButton: true, isFocusable: true, isFocused: true),
            );
          }
          for (final String label in <String>['Anzeigen', 'Ausblenden']) {
            expect(_editor(tester).obscureText, label == 'Anzeigen');
            switch (path) {
              case 'Enter':
                await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              case 'Space':
                await tester.sendKeyEvent(LogicalKeyboardKey.space);
              case 'pointer':
                await tester.tap(find.bySemanticsLabel(label));
              case 'semantics':
                _semanticsTap(tester, label);
            }
            await tester.pumpAndSettle();
            final String next = label == 'Anzeigen' ? 'Ausblenden' : 'Anzeigen';
            expect(find.bySemanticsLabel(next), findsOneWidget);
            expect(find.bySemanticsLabel(label), findsNothing);
            expect(_editor(tester).obscureText, label != 'Anzeigen');
            expect(controller.value, original);
            expect(edits, 0);
          }
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          controller.dispose();
          input.dispose();
          semantics.dispose();
        }
      });
    }
  }

  for (final TextDirection direction in TextDirection.values) {
    testWidgets('input, toggle, next traversal in $direction (#308)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final FocusNode input = FocusNode();
      final FocusNode after = FocusNode();
      try {
        await tester.pumpWidget(
          _host(
            CarbonPasswordInput(labelText: 'Password', focusNode: input),
            direction: direction,
            after: after,
          ),
        );
        _focusInput(tester, input);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Show password')),
          isSemantics(isFocused: true, isButton: true),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(after.hasPrimaryFocus, isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Show password')),
          isSemantics(isFocused: true),
        );
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(input.hasPrimaryFocus, isTrue);
        final List<String> labels = tester.semantics
            .simulatedAccessibilityTraversal()
            .map((SemanticsNode node) => node.getSemanticsData().label)
            .where((String label) => label.isNotEmpty)
            .toList();
        expect(labels, <String>[
          'Before',
          'Password',
          'Show password',
          'After',
        ]);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        input.dispose();
        after.dispose();
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'disabled visibility is skipped and rejects stale activation (#308)',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final FocusNode before = FocusNode();
      final FocusNode after = FocusNode();
      final FocusNode input = FocusNode();
      bool disabled = false;
      late StateSetter update;
      try {
        await tester.pumpWidget(
          _host(
            StatefulBuilder(
              builder: (_, StateSetter setState) {
                update = setState;
                return CarbonPasswordInput(
                  labelText: 'Password',
                  disabled: disabled,
                  focusNode: input,
                );
              },
            ),
            before: before,
            after: after,
          ),
        );
        await tester.pumpAndSettle();
        final VoidCallback stale = tester
            .widget<GestureDetector>(
              find
                  .ancestor(
                    of: find.byType(CarbonIcon),
                    matching: find.byType(GestureDetector),
                  )
                  .first,
            )
            .onTap!;
        final TestGesture press = await tester.startGesture(
          tester.getCenter(find.byType(CarbonIcon)),
        );
        await tester.pump();
        update(() => disabled = true);
        await tester.pumpAndSettle();
        await press.up();
        stale();
        await tester.pumpAndSettle();
        expect(_editor(tester).obscureText, isTrue);
        _semanticsTap(tester, 'Show password');
        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pumpAndSettle();
        expect(_editor(tester).obscureText, isTrue);
        expect(
          tester.getSemantics(find.bySemanticsLabel('Show password')),
          isSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            isFocusable: false,
          ),
        );
        before.requestFocus();
        await tester.pumpAndSettle();
        _focusInput(tester, input);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(after.hasPrimaryFocus, isTrue);
        update(() => disabled = false);
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pumpAndSettle();
        expect(_editor(tester).obscureText, isFalse);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        before.dispose();
        after.dispose();
        input.dispose();
        semantics.dispose();
      }
    },
  );

  testWidgets(
    'visibility ring follows keyboard highlight, not pointer focus (#308)',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final FocusNode after = FocusNode();
      final FocusHighlightStrategy old =
          FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
      try {
        await tester.pumpWidget(
          _host(const CarbonPasswordInput(labelText: 'Password'), after: after),
        );
        await tester.tap(find.bySemanticsLabel('Show password'));
        await tester.pumpAndSettle();
        final Finder ring = find
            .ancestor(
              of: find.byType(CarbonIcon),
              matching: find.byType(CarbonFocusRing),
            )
            .first;
        expect(tester.widget<CarbonFocusRing>(ring).visible, isFalse);
        after.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.bySemanticsLabel('Hide password')),
          isSemantics(isButton: true, isFocused: true),
        );
        expect(tester.widget<CarbonFocusRing>(ring).visible, isTrue);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        after.dispose();
        semantics.dispose();
        FocusManager.instance.highlightStrategy = old;
      }
    },
  );

  testWidgets(
    'password density, state and keyboard focus across themes (#308)',
    (WidgetTester tester) async {
      final FocusHighlightStrategy old =
          FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      try {
        await expectThemeGoldens(
          tester,
          name: 'password_visibility',
          size: const Size(420, 460),
          containsText: true,
          directions: const <TextDirection>{
            TextDirection.ltr,
            TextDirection.rtl,
          },
          afterPump: (WidgetTester tester) async {
            final Finder password = find.byWidgetPredicate(
              (Widget widget) =>
                  widget is CarbonPasswordInput &&
                  widget.labelText == 'Medium focused',
            );
            final Finder icon = find.descendant(
              of: password,
              matching: find.byType(CarbonIcon),
            );
            final FocusNode focus = Focus.of(tester.element(icon));
            focus.requestFocus();
            await tester.pumpAndSettle();
            final Finder ring = find
                .ancestor(of: icon, matching: find.byType(CarbonFocusRing))
                .first;
            expect(focus.hasPrimaryFocus, isTrue);
            expect(tester.widget<CarbonFocusRing>(ring).visible, isTrue);
            expect(tester.takeException(), isNull);
          },
          builder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CarbonPasswordInput(
                  labelText: 'Small',
                  initialValue: 'secret',
                  size: CarbonFieldSize.sm,
                ),
                SizedBox(height: 12),
                CarbonPasswordInput(
                  labelText: 'Medium focused',
                  initialValue: 'secret',
                ),
                SizedBox(height: 12),
                CarbonPasswordInput(
                  labelText: 'Large',
                  initialValue: 'secret',
                  size: CarbonFieldSize.lg,
                ),
                SizedBox(height: 12),
                CarbonPasswordInput(
                  labelText: 'Read only',
                  initialValue: 'secret',
                  readOnly: true,
                ),
                SizedBox(height: 12),
                CarbonPasswordInput(
                  labelText: 'Disabled',
                  initialValue: 'secret',
                  disabled: true,
                ),
              ],
            ),
          ),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        FocusManager.instance.highlightStrategy = old;
      }
    },
  );

  for (final CarbonFieldSize size in CarbonFieldSize.values) {
    testWidgets(
      '${size.name} visibility target follows upstream density (#308)',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _host(CarbonPasswordInput(labelText: 'Password', size: size)),
          );
          expect(
            tester.getSize(find.bySemanticsLabel('Show password')),
            Size.square(size.height),
          );
          // _text-input.scss: the button fills field height with aspect-ratio: 1.
          // Carbon's sm/md densities deliberately use 32/40px targets; lg is 48px.
          // a11y-exception: https://github.com/carbon-design-system/carbon/blob/44f90d8d6b24889af06cee1422ceb37f58e40bed/packages/styles/scss/components/text-input/_text-input.scss
          await expectA11y(tester, tapTargets: size == CarbonFieldSize.lg);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          semantics.dispose();
        }
      },
    );
  }
}
