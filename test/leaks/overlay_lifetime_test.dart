// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Overlay lifetime (#234): every popup-owning component is opened, closed,
// and — the hard case — torn down while open. The suite-wide leak tracker
// is the oracle for entry leaks (an OverlayPortal entry that outlived its
// trigger fails this file's teardown); these tests drive the lifecycles
// and assert the surfaces actually leave the tree.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overlay_entries.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: TapRegionSurface(
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: <OverlayEntry>[
          managedOverlayEntry(
            builder: (BuildContext context) => Stack(
              children: <Widget>[
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                  ),
                ),
                Center(child: child),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);

/// Replaces the whole tree while the overlay is open; the component must
/// tear down without throwing (and without leaking its entry — enforced
/// by the suite-wide tracker at file teardown).
Future<void> _tearDownMidOpen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('overflow menu: open, close, and dispose mid-open', (
    WidgetTester tester,
  ) async {
    Widget build() => _host(
      CarbonOverflowMenu(
        items: <CarbonMenuItem>[
          CarbonMenuItem(label: 'Stop', onPressed: () {}),
          CarbonMenuItem(label: 'Restart', onPressed: () {}),
        ],
      ),
    );
    await tester.pumpWidget(build());
    await tester.tap(find.byType(CarbonButton));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);

    // Close via Escape-equivalent outside tap; surface leaves the tree.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsNothing);

    // Reopen and tear the app down with the menu still up.
    await tester.tap(find.byType(CarbonButton));
    await tester.pumpAndSettle();
    expect(find.text('Stop'), findsOneWidget);
    await _tearDownMidOpen(tester);
  });

  testWidgets('dialog: modal and non-modal dispose mid-open', (
    WidgetTester tester,
  ) async {
    for (final bool modal in <bool>[true, false]) {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 400,
            height: 300,
            child: Stack(
              children: <Widget>[
                CarbonDialog(
                  open: true,
                  modal: modal,
                  onRequestClose: () {},
                  children: const <Widget>[
                    CarbonDialogHeader(children: <Widget>[Text('Title')]),
                    CarbonDialogBody(child: Text('Body')),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Title'), findsOneWidget, reason: 'modal=$modal');
      await _tearDownMidOpen(tester);
    }
  });

  testWidgets('modal: dispose mid-open', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 480,
          height: 360,
          child: Stack(
            children: <Widget>[
              CarbonModal(
                open: true,
                title: 'Add a domain',
                onClose: () {},
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add a domain'), findsOneWidget);
    await _tearDownMidOpen(tester);
  });

  testWidgets('tooltip: hover in, hover out, dispose while shown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const CarbonTooltip(label: 'Tip text', child: Text('target'))),
    );
    final TestGesture mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.text('target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();
    expect(find.text('Tip text'), findsOneWidget);

    await mouse.moveTo(Offset.zero);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Tip text'), findsNothing);

    await mouse.moveTo(tester.getCenter(find.text('target')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump();
    expect(find.text('Tip text'), findsOneWidget);
    await _tearDownMidOpen(tester);
  });

  testWidgets('toggletip: open, close, dispose mid-open', (
    WidgetTester tester,
  ) async {
    Widget build() => _host(
      const CarbonToggletip(
        button: Text('info'),
        content: Text('Toggletip body'),
      ),
    );
    await tester.pumpWidget(build());
    await tester.tap(find.text('info'));
    await tester.pumpAndSettle();
    expect(find.text('Toggletip body'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Toggletip body'), findsNothing);

    await tester.tap(find.text('info'));
    await tester.pumpAndSettle();
    await _tearDownMidOpen(tester);
  });

  testWidgets('dropdown popup: open, close, dispose mid-open', (
    WidgetTester tester,
  ) async {
    Widget build() => _host(
      SizedBox(
        width: 300,
        child: CarbonDropdown<int>(
          titleText: 'Options',
          onChanged: (int _) {},
          items: const <CarbonDropdownItem<int>>[
            CarbonDropdownItem<int>(value: 0, label: 'One'),
            CarbonDropdownItem<int>(value: 1, label: 'Two'),
          ],
        ),
      ),
    );
    await tester.pumpWidget(build());
    await tester.tap(find.byType(CarbonListBox));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsNothing);

    await tester.tap(find.byType(CarbonListBox));
    await tester.pumpAndSettle();
    await _tearDownMidOpen(tester);
  });

  testWidgets('AI label callout: open, dispose mid-open', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const CarbonAILabel(content: Text('Generated by AI'))),
    );
    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();
    expect(find.text('Generated by AI'), findsOneWidget);
    await _tearDownMidOpen(tester);
  });
}
