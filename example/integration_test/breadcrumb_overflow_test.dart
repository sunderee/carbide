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

import 'support/breadcrumb_overflow_fixture.dart';

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  for (final (String name, CarbonThemeData theme)
      in <(String, CarbonThemeData)>[
        ('white', CarbonThemeData.white),
        ('g10', CarbonThemeData.gray10),
        ('g90', CarbonThemeData.gray90),
        ('g100', CarbonThemeData.gray100),
      ]) {
    for (final TextDirection direction in TextDirection.values) {
      for (final double scale in <double>[1, 2]) {
        testWidgets('native breadcrumb $name $direction scale=$scale', (
          WidgetTester tester,
        ) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          final GlobalKey<BreadcrumbOverflowFixtureState> key =
              GlobalKey<BreadcrumbOverflowFixtureState>();
          try {
            await tester.pumpWidget(
              breadcrumbOverflowHost(
                BreadcrumbOverflowFixture(key: key),
                theme: theme,
                direction: direction,
                scale: scale,
              ),
            );
            await _settle(tester);
            expect(find.byType(CarbonOverflowMenu), findsOneWidget);
            expect(_named('Standalone link', role: 'link').tabIndex, 0);
            key.currentState!.linkFocusPolicy(canFocus: true, skip: true);
            await _settle(tester);
            expect(_named('Standalone link', role: 'link').tabIndex, -1);
            key.currentState!.linkFocusPolicy(canFocus: false, skip: false);
            await _settle(tester);
            expect(_named('Standalone link', role: 'link').tabIndex, -1);
            key.currentState!.linkFocusPolicy(canFocus: true, skip: false);
            await _settle(tester);
            expect(_named('Standalone link', role: 'link').tabIndex, 0);
            key.currentState!.enableLink(false);
            await _settle(tester);
            expect(
              _named(
                'Standalone link',
                role: 'link',
              ).getAttribute('aria-disabled'),
              'true',
            );
            expect(_named('Standalone link', role: 'link').tabIndex, -1);
            key.currentState!.enableLink(true);
            await _settle(tester);
            expect(
              _named(
                'Standalone link',
                role: 'link',
              ).getAttribute('aria-disabled'),
              'false',
            );
            expect(_named('Standalone link', role: 'link').tabIndex, 0);
            final _Element trigger = _named('More breadcrumbs', role: 'button');
            expect(trigger.getAttribute('role'), 'button');
            expect(trigger.tabIndex, 0);
            expect(
              _named('Here, Current page').getAttribute('role'),
              isNot('link'),
            );
            expect(
              _named('Here, Current page').getAttribute('aria-current'),
              'true',
            );
            expect(_named('Home', role: 'link').getAttribute('role'), 'link');
            final List<int> hidden = <int>[
              for (int i = 1; i < breadcrumbLabels.length - 1; i++)
                if (find.text(breadcrumbLabels[i]).evaluate().isEmpty) i,
            ];
            expect(hidden, isNotEmpty);
            trigger.focus();
            await _settle(tester);
            await _send(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            expect(find.byType(CarbonMenu), findsOneWidget);
            expect(
              _named(
                'More breadcrumbs',
                role: 'button',
              ).getAttribute('aria-expanded'),
              'true',
            );
            for (final int i in hidden) {
              expect(
                _named(
                  breadcrumbLabels[i],
                  role: 'button',
                ).getAttribute('role'),
                'button',
              );
            }
            await _send(
              tester,
              LogicalKeyboardKey.escape,
              PhysicalKeyboardKey.escape,
            );
            expect(find.byType(CarbonMenu), findsNothing);
            expect(
              _document.activeElement?.textContent?.trim(),
              'More breadcrumbs',
            );
            for (int row = 0; row < hidden.length; row++) {
              await _send(
                tester,
                LogicalKeyboardKey.space,
                PhysicalKeyboardKey.space,
              );
              await _send(
                tester,
                LogicalKeyboardKey.home,
                PhysicalKeyboardKey.home,
              );
              for (int step = 0; step < row; step++) {
                await _send(
                  tester,
                  LogicalKeyboardKey.arrowDown,
                  PhysicalKeyboardKey.arrowDown,
                );
              }
              await _send(
                tester,
                LogicalKeyboardKey.enter,
                PhysicalKeyboardKey.enter,
              );
              expect(key.currentState!.selected, hidden[row]);
              expect(key.currentState!.changes, row + 1);
              expect(find.byType(CarbonMenu), findsNothing);
              expect(
                _document.activeElement?.textContent?.trim(),
                'More breadcrumbs',
              );
            }
            final int before = key.currentState!.changes;
            await _send(
              tester,
              LogicalKeyboardKey.enter,
              PhysicalKeyboardKey.enter,
            );
            key.currentState!.resize(1500);
            await _settle(tester);
            expect(find.byType(CarbonMenu), findsNothing);
            expect(find.byType(CarbonOverflowMenu), findsNothing);
            expect(key.currentState!.changes, before);
            key.currentState!.resize(160);
            await _settle(tester);
            expect(find.byType(CarbonOverflowMenu), findsOneWidget);
            expect(tester.takeException(), isNull);
          } catch (error, stack) {
            binding.reportData ??= <String, dynamic>{};
            binding.reportData!['$name $direction $scale'] = <String, String>{
              'error': error.toString(),
              'stack': stack.toString(),
            };
            rethrow;
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await _settle(tester);
            semantics.dispose();
          }
        });
      }
    }
  }
}

Future<void> _send(
  WidgetTester tester,
  LogicalKeyboardKey key,
  PhysicalKeyboardKey physical,
) async {
  await tester.sendKeyEvent(key, physicalKey: physical);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 5),
  );
}

_Element _named(String label, {String? role}) {
  final _NodeList elements = _document.querySelectorAll(
    'flt-semantics, a[id^="flt-semantic-node-"]',
  );
  for (int i = 0; i < elements.length; i++) {
    final _Element element = elements.item(i)!;
    if ((role == null || element.getAttribute('role') == role) &&
        (element.getAttribute('aria-label') == label ||
            element.textContent?.trim() == label)) {
      return element;
    }
  }
  throw StateError('No native node named $label');
}

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
  external String? getAttribute(String name);
  external String? get textContent;
  external int get tabIndex;
  external void focus();
}
