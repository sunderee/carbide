// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0; see LICENSE.
//
// The suite-wide tracker checks disposal, timers, focus and controllers. This
// table drives open/close/reopen and route removal; the source guard inventories
// every constructed portal and its representative lifetime scenarios.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart' show SemanticsAction, SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/specimens.dart';

typedef _Action = Future<void> Function(WidgetTester, ValueNotifier<bool>);

class _Scenario {
  const _Scenario({
    required this.name,
    required this.build,
    required this.open,
    required this.marker,
    this.close = _escape,
  });
  final String name;
  final Widget Function(ValueNotifier<bool>) build;
  final _Action open;
  final _Action close;
  final Finder marker;
}

Future<void> _escape(WidgetTester tester, ValueNotifier<bool> _) =>
    tester.sendKeyEvent(LogicalKeyboardKey.escape);
Future<void> _controlledOpen(WidgetTester _, ValueNotifier<bool> open) async {
  open.value = true;
}

Future<void> _controlledClose(WidgetTester _, ValueNotifier<bool> open) async {
  open.value = false;
}

final Map<ValueNotifier<bool>, TestGesture> _mice =
    <ValueNotifier<bool>, TestGesture>{};

Future<void> _hover(
  WidgetTester tester,
  ValueNotifier<bool> open,
  Finder target,
) async {
  TestGesture? mouse = _mice[open];
  if (mouse == null) {
    mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    _mice[open] = mouse;
    await mouse.addPointer(location: const Offset(700, 500));
  }
  await mouse.moveTo(tester.getCenter(target));
}

Future<void> _leave(WidgetTester _, ValueNotifier<bool> open) async {
  await _mice[open]?.moveTo(const Offset(700, 500));
}

Future<void> _semanticTap(WidgetTester tester, Finder target) async {
  final Finder control = target
      .evaluate()
      .map(
        (element) =>
            find.byElementPredicate((candidate) => candidate == element),
      )
      .firstWhere(
        (finder) => tester
            .getSemantics(finder)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
      );
  final SemanticsNode node = tester.getSemantics(control);
  expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
  tester
      .renderObject(control)
      .owner!
      .semanticsOwner!
      .performAction(node.id, SemanticsAction.tap);
}

_Scenario _picker(String name) => _Scenario(
  name: name,
  build: (_) => Builder(builder: carbideSpecimens[name]!),
  open: (tester, _) => carbideOpenSpecimens[name]!.$1!(tester),
  marker: carbideOpenSpecimens[name]!.$2,
);

final List<_Scenario> _scenarios = <_Scenario>[
  for (final name in <String>[
    'dropdown',
    'select',
    'combo box',
    'multi select',
    'filterable multi select',
    'date picker',
    'time picker',
    'menu',
    'overflow menu',
    'context menu',
  ])
    _picker(name),
  _Scenario(
    name: 'popover',
    build: (open) => CarbonPopover(
      open: open.value,
      content: const Text('Raw surface'),
      child: const Text('Anchor'),
    ),
    open: _controlledOpen,
    close: _controlledClose,
    marker: find.text('Raw surface'),
  ),
  _Scenario(
    name: 'modal',
    build: (open) => CarbonModal(
      open: open.value,
      title: 'Modal surface',
      child: const Text('Body'),
      onClose: () => open.value = false,
    ),
    open: _controlledOpen,
    marker: find.text('Modal surface'),
  ),
  for (final modal in <bool>[true, false])
    _Scenario(
      name: modal ? 'dialog modal' : 'dialog nonmodal',
      build: (open) => SizedBox(
        width: 400,
        height: 300,
        child: Stack(
          children: <Widget>[
            CarbonDialog(
              open: open.value,
              modal: modal,
              onRequestClose: () => open.value = false,
              children: const <Widget>[
                CarbonDialogHeader(children: <Widget>[Text('Dialog surface')]),
                CarbonDialogBody(child: Text('Body')),
              ],
            ),
          ],
        ),
      ),
      open: _controlledOpen,
      marker: find.text('Dialog surface'),
      close: _controlledClose,
    ),
  _Scenario(
    name: 'tooltip',
    build: (_) => CarbonTooltip(
      label: 'Tooltip surface',
      enterDelayMs: 20,
      leaveDelayMs: 20,
      child: CarbonButton(label: 'Tooltip trigger', onPressed: () {}),
    ),
    open: (tester, open) async {
      await _hover(tester, open, find.text('Tooltip trigger'));
      await tester.pump(const Duration(milliseconds: 40));
    },
    close: _leave,
    marker: find.text('Tooltip surface'),
  ),
  _Scenario(
    name: 'toggletip',
    build: (_) => const CarbonToggletip(content: Text('Toggletip surface')),
    open: (tester, _) => tester.tap(find.bySemanticsLabel('Show information')),
    close: (tester, _) => tester.tap(find.bySemanticsLabel('Show information')),
    marker: find.text('Toggletip surface'),
  ),
  _Scenario(
    name: 'ai label',
    build: (_) => const CarbonAILabel(content: Text('AI surface')),
    open: (tester, _) => tester.tap(find.text('AI')),
    close: (tester, _) => tester.tap(find.text('AI')),
    marker: find.text('AI surface'),
  ),
  _Scenario(
    name: 'date range',
    build: (_) =>
        SizedBox(width: 320, child: CarbonDateRangePicker(onChanged: (_) {})),
    open: (tester, _) => tester.tap(find.bySemanticsLabel('Start date').first),
    marker: find.byType(CarbonCalendar),
  ),
  _Scenario(
    name: 'header submenu',
    build: (_) => const CarbonHeaderMenu(
      label: 'Resources',
      items: <Widget>[
        CarbonMenuItem(
          label: 'Share',
          submenu: <Widget>[CarbonMenuItem(label: 'Submenu surface')],
        ),
      ],
    ),
    open: (tester, _) async {
      await tester.tap(find.text('Resources'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Share'));
    },
    close: (tester, _) => tester.tapAt(const Offset(700, 500)),
    marker: find.text('Submenu surface'),
  ),
  _Scenario(
    name: 'copy feedback',
    build: (_) => const CarbonCopyButton(
      value: 'Copied value',
      feedback: 'Copy surface',
      feedbackTimeout: Duration(milliseconds: 500),
    ),
    open: (tester, _) => tester.tap(find.byType(CarbonCopyButton)),
    close: (tester, _) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 700));
    },
    marker: find.text('Copy surface'),
  ),
  _Scenario(
    name: 'side nav rail',
    build: (_) => SizedBox(
      height: 240,
      child: CarbonSideNav(
        rail: true,
        items: <Widget>[
          CarbonSideNavLink(
            label: 'Rail surface',
            icon: CarbonIcons.dashboard,
            onPressed: () {},
          ),
        ],
      ),
    ),
    open: (tester, open) => _hover(tester, open, find.byType(CarbonSideNav)),
    close: (tester, open) async {
      await _leave(tester, open);
      FocusManager.instance.primaryFocus?.unfocus();
    },
    marker: find.text('Rail surface'),
  ),
  _Scenario(
    name: 'page tag disclosure',
    build: (_) => const SizedBox(
      width: 320,
      child: CarbonPageHeader(
        title: 'Details',
        collapseTags: true,
        tags: <Widget>[
          CarbonTag(label: 'First long category'),
          CarbonTag(label: 'Second long category'),
          CarbonTag(label: 'Hidden tag surface'),
        ],
      ),
    ),
    open: (tester, _) => tester.tap(find.byType(CarbonOperationalTag)),
    marker: find.text('Hidden tag surface'),
  ),
  for (final pageSize in <bool>[true, false])
    _Scenario(
      name: pageSize ? 'pagination size' : 'pagination page',
      build: (_) => SizedBox(
        width: 1000,
        child: CarbonPagination(
          page: 2,
          pageSize: 10,
          totalItems: 100,
          onPageChanged: (_) {},
          onPageSizeChanged: (_) {},
        ),
      ),
      open: (tester, _) => _semanticTap(
        tester,
        find.bySemanticsLabel(pageSize ? 'Items per page:' : 'Page'),
      ),
      marker: find.text(pageSize ? '20' : '3'),
    ),
];

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  for (final scenario in _scenarios) {
    testWidgets('${scenario.name}: open, close, reopen, dispose mid-open', (
      tester,
    ) async {
      final ValueNotifier<bool> open = ValueNotifier<bool>(false);
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          TapRegionSurface(
            child: carbideSpecimenHost(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: open,
                      builder: (_, _, _) => scenario.build(open),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await scenario.open(tester, open);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(
          scenario.marker,
          findsWidgets,
          reason: 'The surface must really be open.',
        );
        expect(tester.takeException(), isNull);
        await scenario.close(tester, open);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();
        expect(
          scenario.marker,
          findsNothing,
          reason: 'The closed surface must leave the tree.',
        );
        await scenario.open(tester, open);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        expect(scenario.marker, findsWidgets);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
        expect(scenario.marker, findsNothing);
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.takeException(), isNull);
      } finally {
        await _mice.remove(open)?.removePointer();
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 3));
        open.dispose();
        semantics.dispose();
      }
    });
  }
}
