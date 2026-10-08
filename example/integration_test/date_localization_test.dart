// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:js_interop';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/support/date_localizations.dart';
import 'support/date_localization_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final (String name, CarbonDatePickerLocalizations labels, _, _)
      in dateLocaleFixtures) {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('native localized selection and range $name $direction', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final GlobalKey<DateLocalizationFixtureState> key =
            GlobalKey<DateLocalizationFixtureState>();
        try {
          await tester.pumpWidget(
            dateLocalizationHost(
              DateLocalizationFixture(key: key, labels: labels),
              direction: direction,
            ),
          );
          await _settle(tester);
          final DateLocalizationFixtureState state = key.currentState!;
          await tester.tap(
            find.text(labels.dateFormat.format(DateTime(2025, 10, 17))).first,
          );
          await _settle(tester);
          expect(
            find.text(labels.formatMonthYear(DateTime(2025, 10, 1))),
            findsOneWidget,
          );
          expect(_button(labels.previousMonthLabel), isNotNull);
          expect(_button(labels.nextMonthLabel), isNotNull);
          await tester.sendKeyEvent(
            direction == TextDirection.ltr
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft,
            physicalKey: direction == TextDirection.ltr
                ? PhysicalKeyboardKey.arrowRight
                : PhysicalKeyboardKey.arrowLeft,
          );
          await _settle(tester);
          expect(state.singleChanges, 0);
          await tester.sendKeyEvent(
            LogicalKeyboardKey.enter,
            physicalKey: PhysicalKeyboardKey.enter,
          );
          await _settle(tester);
          expect(state.date, DateTime(2025, 10, 18));
          expect(state.singleChanges, 1);
          expect(find.byType(CarbonCalendar), findsNothing);
          await tester.tap(
            find.text(labels.dateFormat.format(DateTime(2025, 10, 17))).first,
          );
          await _settle(tester);
          _button(labels.formatDayLabel(DateTime(2025, 10, 19))).click();
          await _settle(tester);
          expect(state.rangeChanges, 0);
          expect(
            find.text(labels.dateFormat.format(DateTime(2025, 10, 19))),
            findsOneWidget,
          );
          _button(labels.formatDayLabel(DateTime(2025, 10, 21))).click();
          await _settle(tester);
          expect(
            state.range,
            CarbonDateRange(DateTime(2025, 10, 19), DateTime(2025, 10, 21)),
          );
          expect(state.rangeChanges, 1);
          expect(find.byType(CarbonCalendar), findsNothing);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await _settle(tester);
          semantics.dispose();
        }
      });
    }
  }
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

_Element _button(String name) {
  final _NodeList nodes = _document.querySelectorAll('[role="button"], button');
  for (int i = 0; i < nodes.length; i++) {
    final _Element node = nodes.item(i)!;
    if (node.getAttribute('aria-label') == name ||
        node.textContent?.trim() == name) {
      return node;
    }
  }
  throw StateError('No native date button named $name');
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _NodeList querySelectorAll(String selector);
}

extension type _Element(JSObject _) implements JSObject {
  external String? getAttribute(String name);
  external String? get textContent;
  external void click();
}

extension type _NodeList(JSObject _) implements JSObject {
  external int get length;
  external _Element? item(int index);
}
