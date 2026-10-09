// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show ViewFocusEvent, ViewFocusState, ViewFocusDirection;

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';
import '../../support/overlay_entries.dart';

const String _long =
    'Quarterly report with a deliberately long title and additional regional context';

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  builder: (_, _) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Overlay(
          key: UniqueKey(),
          initialEntries: [
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

void _enter(WidgetTester tester) => tester.binding.handleViewFocusChanged(
  ViewFocusEvent(
    viewId: tester.view.viewId,
    state: ViewFocusState.focused,
    direction: ViewFocusDirection.undefined,
  ),
);

List<SemanticsData> _headings(WidgetTester tester) {
  final data = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (node.getSemanticsData().headingLevel > 0) {
      data.add(node.getSemanticsData());
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return data;
}

void main() {
  testWidgets(
    'Escape dismisses a hovered title while another control keeps focus',
    (WidgetTester tester) async {
      final FocusNode other = FocusNode();
      addTearDown(other.dispose);
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CarbonPageHeader(title: _long),
              Focus(
                focusNode: other,
                child: const SizedBox(width: 40, height: 40),
              ),
            ],
          ),
        ),
      );
      _enter(tester);
      other.requestFocus();
      await tester.pumpAndSettle();
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text(_long)));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(find.text(_long), findsNWidgets(2));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text(_long), findsOneWidget);
      expect(other.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'very long title can scroll by keyboard while retaining heading focus',
    (WidgetTester tester) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      final String title = List<String>.filled(
        30,
        'Quarterly regional report',
      ).join(' ');
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(320, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      try {
        await tester.pumpWidget(
          _host(
            CarbonPageHeader(title: title, titleFocusNode: focus),
            scale: 2,
          ),
        );
        _enter(tester);
        focus.requestFocus();
        await tester.pumpAndSettle();
        final ScrollableState scroll = tester.state<ScrollableState>(
          find.byType(Scrollable),
        );
        expect(scroll.position.maxScrollExtent, greaterThan(0));
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, scroll.position.maxScrollExtent);
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, 0);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, greaterThan(0));
        expect(focus.hasFocus, isTrue);
        expect(_headings(tester).single.label, title);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets('fitting title has no tooltip or extra focus stop', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(CarbonPageHeader(title: 'Report', titleFocusNode: focus)),
      );
      expect(find.byType(CarbonTooltip), findsNothing);
      expect(focus.canRequestFocus, isFalse);
      expect(
        tester
            .getSemantics(find.text('Report'))
            .getSemanticsData()
            .headingLevel,
        1,
      );
    } finally {
      handle.dispose();
    }
  });
  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'truncated title recovers full text and keeps one heading $direction/$scale',
        (tester) async {
          final focus = FocusNode();
          addTearDown(focus.dispose);
          final handle = tester.ensureSemantics();
          try {
            await tester.pumpWidget(
              _host(
                CarbonPageHeader(
                  title: _long,
                  headingLevel: 3,
                  titleFocusNode: focus,
                  icon: CarbonIcons.document,
                  actions: [
                    CarbonPageHeaderAction(
                      id: 'edit',
                      label: 'Edit',
                      onPressed: () {},
                    ),
                  ],
                ),
                direction: direction,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(CarbonTooltip), findsOneWidget);
            _enter(tester);
            focus.requestFocus();
            await tester.pumpAndSettle();
            expect(find.text(_long), findsNWidgets(2));
            expect(
              _headings(tester).map((data) => (data.headingLevel, data.label)),
              [(3, _long)],
            );
            expect(
              tester
                  .getSemantics(find.text(_long).first)
                  .getSemanticsData()
                  .tooltip,
              isEmpty,
            );
            expectNoClippedTextAtScale(tester, scale);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await tester.pumpAndSettle();
            expect(find.text(_long), findsOneWidget);
            expect(focus.hasFocus, isTrue);
            expect(tester.takeException(), isNull);
          } finally {
            handle.dispose();
          }
        },
      );
    }
  }
  testWidgets(
    'width, labels, scaling and hierarchy update without stale overlays',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      final handle = tester.ensureSemantics();
      double width = 160, scale = 1;
      String title = _long;
      int level = 1;
      late StateSetter update;
      try {
        await tester.pumpWidget(
          _host(
            Align(
              alignment: Alignment.topLeft,
              child: StatefulBuilder(
                builder: (_, setState) {
                  update = setState;
                  return SizedBox(
                    width: width,
                    child: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: CarbonPageHeader(
                        title: title,
                        headingLevel: level,
                        titleFocusNode: focus,
                      ),
                    ),
                  );
                },
              ),
            ),
            width: 760,
          ),
        );
        await tester.pumpAndSettle();
        final id = _headings(tester).single;
        _enter(tester);
        focus.requestFocus();
        await tester.pumpAndSettle();
        expect(find.text(_long), findsNWidgets(2));
        update(
          () => title = 'A changed long report title that remains truncated',
        );
        await tester.pumpAndSettle();
        expect(find.text(_long), findsNothing);
        expect(find.text(title), findsNWidgets(2));
        update(() => title = 'Report');
        await tester.pumpAndSettle();
        expect(find.byType(CarbonTooltip), findsNothing);
        expect(focus.canRequestFocus, isFalse);
        expect(_headings(tester).single.headingLevel, id.headingLevel);
        update(() {
          title = _long;
          width = 320;
          scale = 2;
          level = 4;
        });
        await tester.pumpAndSettle();
        expect(find.byType(CarbonTooltip), findsOneWidget);
        expect(_headings(tester).single.headingLevel, 4);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    },
  );
  testWidgets('caller focus remains usable after header disposal', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _host(CarbonPageHeader(title: _long, titleFocusNode: focus)),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _host(Focus(focusNode: focus, child: const Text('Next owner'))),
    );
    _enter(tester);
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('hover reveals only truncated titles and remains over bubble', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const CarbonPageHeader(title: _long)));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text(_long)));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();
    expect(find.text(_long), findsNWidgets(2));
    await mouse.moveTo(tester.getCenter(find.text(_long).last));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text(_long), findsNWidgets(2));
    await mouse.moveTo(const Offset(750, 550));
    await tester.pump(const Duration(milliseconds: 320));
    await tester.pumpAndSettle();
    expect(find.text(_long), findsOneWidget);
  });
  for (final (name, width, scale, open) in [
    ('fitting', 760.0, 1.0, false),
    ('truncated', 320.0, 1.3, false),
    ('focused', 320.0, 2.0, true),
  ]) {
    testWidgets('golden title recovery $name', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await expectThemeGoldens(
        tester,
        name: 'page_header_title_$name',
        size: Size(width, 580),
        containsText: true,
        directions: TextDirection.values.toSet(),
        mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
        builder: (_) => Overlay(
          initialEntries: [
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: CarbonPageHeader(
                  title: name == 'fitting' ? 'Quarterly report' : _long,
                  icon: CarbonIcons.document,
                ),
              ),
            ),
          ],
        ),
        afterPump: (tester) async {
          if (open) {
            _enter(tester);
            final node = tester.getSemantics(find.text(_long));
            tester.binding.platformDispatcher.onSemanticsActionEvent!(
              SemanticsActionEvent(
                type: SemanticsAction.focus,
                nodeId: node.id,
                viewId: tester.view.viewId,
              ),
            );
          }
          await tester.pumpAndSettle();
        },
      );
    });
  }
}
