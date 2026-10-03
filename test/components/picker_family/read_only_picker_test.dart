// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui'
    show Tristate, ViewFocusDirection, ViewFocusEvent, ViewFocusState;

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';
import '../../support/picker_fixture.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    WidgetsApp(
      color: const Color(0xFFFFFFFF),
      builder: (_, _) => Directionality(
        textDirection: direction,
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) =>
                    Center(child: SizedBox(width: 360, child: child)),
              ),
            ],
          ),
        ),
      ),
    );

void _action(WidgetTester tester, SemanticsAction action) {
  final Finder control = find.bySemanticsLabel(RegExp(r'^Field($|\n)')).first;
  final SemanticsNode node = tester.getSemantics(control);
  tester
      .renderObject(control)
      .owner!
      .semanticsOwner!
      .performAction(node.id, action);
}

void _enterView(WidgetTester tester) => tester.binding.handleViewFocusChanged(
  ViewFocusEvent(
    viewId: tester.view.viewId,
    state: ViewFocusState.focused,
    direction: ViewFocusDirection.undefined,
  ),
);

void _expectClosed() {
  expect(find.byType(CarbonCalendar), findsNothing);
  expect(find.byType(CarbonListBoxMenu), findsNothing);
  expect(find.text('Alpha'), findsNothing);
}

bool _hasPopup() =>
    find.byType(CarbonCalendar).evaluate().isNotEmpty ||
    find.byType(CarbonListBoxMenu).evaluate().isNotEmpty ||
    find.text('Alpha').evaluate().isNotEmpty;

Future<void> _open(WidgetTester tester, PickerKind kind) async {
  _action(tester, SemanticsAction.focus);
  await tester.pumpAndSettle();
  if (!_hasPopup()) {
    await tester.sendKeyEvent(
      kind == PickerKind.date || kind == PickerKind.range
          ? LogicalKeyboardKey.enter
          : LogicalKeyboardKey.arrowDown,
    );
    await tester.pumpAndSettle();
  }
  expect(_hasPopup(), isTrue);
}

List<VoidCallback> _retainedEdits(WidgetTester tester) => <VoidCallback>[
  for (final CarbonListBoxMenuItem row
      in tester.widgetList<CarbonListBoxMenuItem>(
        find.byType(CarbonListBoxMenuItem),
      ))
    if (row.onTap != null) row.onTap!,
  for (final CarbonInteraction control in tester.widgetList<CarbonInteraction>(
    find.byType(CarbonInteraction),
  ))
    if (find.byType(CarbonCalendar).evaluate().isEmpty &&
        control.onPressed != null)
      control.onPressed!,
  for (final CarbonCheckbox checkbox in tester.widgetList<CarbonCheckbox>(
    find.byType(CarbonCheckbox),
  ))
    if (checkbox.onChanged != null) () => checkbox.onChanged!(false),
  for (final CarbonCalendar calendar in tester.widgetList<CarbonCalendar>(
    find.byType(CarbonCalendar),
  )) ...<VoidCallback>[
    if (calendar.onChanged != null)
      () => calendar.onChanged!(DateTime(2026, 1, 8)),
    if (calendar.onRangeChanged != null)
      () => calendar.onRangeChanged!(
        CarbonDateRange(DateTime(2026, 1, 8), DateTime(2026, 1, 9)),
      ),
  ],
];

void main() {
  for (final PickerKind kind in PickerKind.values) {
    testWidgets('$kind announces a focusable non-editable value (#312)', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final GlobalKey<PickerFixtureState> key = GlobalKey<PickerFixtureState>();
      try {
        await tester.pumpWidget(_host(PickerFixture(key: key, kind: kind)));
        await tester.pumpAndSettle();
        _enterView(tester);
        final Finder control = find
            .bySemanticsLabel(RegExp(r'^Field($|\n)'))
            .first;
        final SemanticsNode node = tester.getSemantics(control);
        expect(node.getSemanticsData().hint, 'Nur lesen');
        expect(node.flagsCollection.isFocused, isNot(Tristate.none));
        if (node.flagsCollection.isTextField) {
          expect(node.flagsCollection.isReadOnly, isTrue);
        } else {
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
        }
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.setText),
          isFalse,
        );
        expect(
          node.getSemanticsData().value,
          contains(key.currentState!.announcedValue),
        );
        _action(tester, SemanticsAction.focus);
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(control).flagsCollection.isFocused,
          Tristate.isTrue,
        );
        _expectClosed();
        key.currentState!.configure(disabled: true);
        await tester.pumpAndSettle();
        final SemanticsNode disabled = tester.getSemantics(
          find.bySemanticsLabel(RegExp(r'^Field($|\n)')).first,
        );
        expect(disabled.flagsCollection.isFocused, Tristate.none);
        expect(disabled.getSemanticsData().hint, isEmpty);
        expect(
          disabled.getSemanticsData().value,
          contains(key.currentState!.announcedValue),
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        semantics.dispose();
      }
    });

    testWidgets(
      '$kind rejects pointer, keys and accessibility editing (#312)',
      (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final GlobalKey<PickerFixtureState> key =
            GlobalKey<PickerFixtureState>();
        try {
          await tester.pumpWidget(_host(PickerFixture(key: key, kind: kind)));
          await tester.pumpAndSettle();
          _enterView(tester);
          _action(tester, SemanticsAction.focus);
          await tester.pumpAndSettle();
          _expectClosed();
          for (final LogicalKeyboardKey key in <LogicalKeyboardKey>[
            LogicalKeyboardKey.enter,
            LogicalKeyboardKey.space,
            LogicalKeyboardKey.arrowDown,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.escape,
            LogicalKeyboardKey.keyB,
          ]) {
            await tester.sendKeyEvent(
              key,
              character: key == LogicalKeyboardKey.keyB ? 'b' : null,
            );
            await tester.pumpAndSettle();
            _expectClosed();
          }
          _action(tester, SemanticsAction.tap);
          await tester.pumpAndSettle();
          _expectClosed();
          await tester.tap(
            find.bySemanticsLabel(RegExp(r'^Field($|\n)')).first,
          );
          await tester.pumpAndSettle();
          _expectClosed();
          if (kind == PickerKind.range) {
            await tester.tap(find.text('Field end'));
            await tester.pumpAndSettle();
            _expectClosed();
          }
          final PickerFixtureState state = key.currentState!;
          expect(state.changes, 0);
          expect(state.clears, 0);
          expect(state.inputs, 0);
          expect(state.query.text, 'Retained query');
          expect(state.chosen, 'b');
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          semantics.dispose();
        }
      },
    );

    if (kind.hasPopup) {
      testWidgets('$kind closes a live popup when becoming read-only (#312)', (
        tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final GlobalKey<PickerFixtureState> key =
            GlobalKey<PickerFixtureState>();
        try {
          await tester.pumpWidget(
            _host(PickerFixture(key: key, kind: kind, readOnly: false)),
          );
          await tester.pumpAndSettle();
          _enterView(tester);
          _action(tester, SemanticsAction.focus);
          await tester.pumpAndSettle();
          if (find.byType(CarbonCalendar).evaluate().isEmpty &&
              find.byType(CarbonListBoxMenu).evaluate().isEmpty &&
              find.text('Alpha').evaluate().isEmpty) {
            await tester.sendKeyEvent(
              kind == PickerKind.date || kind == PickerKind.range
                  ? LogicalKeyboardKey.enter
                  : LogicalKeyboardKey.arrowDown,
            );
            await tester.pumpAndSettle();
          }
          expect(
            find.byType(CarbonCalendar).evaluate().isNotEmpty ||
                find.byType(CarbonListBoxMenu).evaluate().isNotEmpty ||
                find.text('Alpha').evaluate().isNotEmpty,
            isTrue,
          );
          key.currentState!.configure(readOnly: true);
          await tester.pumpAndSettle();
          _expectClosed();
          expect(key.currentState!.changes, 0);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          semantics.dispose();
        }
      });
    }

    testWidgets('$kind resumes editing after inspection in RTL (#312)', (
      tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final GlobalKey<PickerFixtureState> key = GlobalKey<PickerFixtureState>();
      try {
        await tester.pumpWidget(
          _host(
            PickerFixture(key: key, kind: kind),
            direction: TextDirection.rtl,
          ),
        );
        await tester.pumpAndSettle();
        _enterView(tester);
        _action(tester, SemanticsAction.focus);
        await tester.pumpAndSettle();
        _expectClosed();
        key.currentState!.configure(readOnly: false);
        await tester.pumpAndSettle();
        if (kind.hasPopup) {
          await _open(tester, kind);
          if (kind == PickerKind.date || kind == PickerKind.range) {
            final CarbonCalendar calendar = tester.widget(
              find.byType(CarbonCalendar),
            );
            if (kind == PickerKind.date) {
              calendar.onChanged!(DateTime(2026, 1, 8));
            } else {
              calendar.onRangeChanged!(
                CarbonDateRange(DateTime(2026, 1, 8), DateTime(2026, 1, 9)),
              );
            }
          } else {
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          }
          await tester.pumpAndSettle();
          expect(key.currentState!.changes, 1);
        } else {
          await tester.enterText(find.byType(EditableText), 'Edited');
          await tester.pumpAndSettle();
          expect(key.currentState!.query.text, 'Edited');
          expect(key.currentState!.changes, 1);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        semantics.dispose();
      }
    });

    testWidgets(
      '$kind ignores retained edits after locking and disposal (#312)',
      (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final GlobalKey<PickerFixtureState> key =
            GlobalKey<PickerFixtureState>();
        try {
          await tester.pumpWidget(
            _host(PickerFixture(key: key, kind: kind, readOnly: false)),
          );
          await tester.pumpAndSettle();
          _enterView(tester);
          if (kind == PickerKind.expandableSearch) {
            await tester.tap(find.bySemanticsLabel('Expand search'));
            await tester.pumpAndSettle();
          }
          if (kind.hasPopup) await _open(tester, kind);
          final List<VoidCallback> edits = _retainedEdits(tester);
          expect(edits, isNotEmpty);
          final PickerFixtureState state = key.currentState!;
          state.configure(readOnly: true);
          // Flush the new policy; callbacks may outlive the removed popup.
          await tester.pumpAndSettle();
          for (final VoidCallback edit in edits) {
            edit();
          }
          await tester.pumpAndSettle();
          _expectClosed();
          expect(state.changes, 0);
          expect(state.clears, 0);
          expect(state.query.text, 'Retained query');
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          for (final VoidCallback edit in edits) {
            edit();
          }
          await tester.pumpAndSettle();
          expect(state.changes, 0);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          semantics.dispose();
        }
      },
    );
  }

  testWidgets('filter draft survives read-only value inspection (#312)', (
    tester,
  ) async {
    final GlobalKey<PickerFixtureState> key = GlobalKey<PickerFixtureState>();
    await tester.pumpWidget(
      _host(
        PickerFixture(
          key: key,
          kind: PickerKind.filteredMulti,
          readOnly: false,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Al');
    await tester.pumpAndSettle();
    key.currentState!.configure(readOnly: true);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Beta',
    );
    key.currentState!.configure(selected: <String>{'a', 'b'});
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Alpha, Beta',
    );
    key.currentState!.configure(readOnly: false);
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Al',
    );
    expect(key.currentState!.changes, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  for (final PickerKind kind in <PickerKind>[
    PickerKind.dropdown,
    PickerKind.select,
    PickerKind.multi,
    PickerKind.filteredMulti,
  ]) {
    testWidgets(
      '$kind missing callback takes precedence over read-only (#312)',
      (tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            _host(PickerFixture(kind: kind, callback: false)),
          );
          await tester.pumpAndSettle();
          final SemanticsNode node = tester.getSemantics(
            find.bySemanticsLabel('Field'),
          );
          expect(node.flagsCollection.isFocused, Tristate.none);
          expect(node.getSemanticsData().hint, isEmpty);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isFalse,
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          semantics.dispose();
        }
      },
    );
  }
}
