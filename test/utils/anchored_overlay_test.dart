// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide/src/utils/anchored_overlay.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overlay_entries.dart';
import '../support/golden.dart';
import '../support/scaled_fields.dart';

Widget _host(
  Widget child,
  TextDirection direction,
  Alignment corner, {
  double width = 180,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: const MediaQueryData(size: Size(320, 360)),
    child: TapRegionSurface(
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: corner,
                child: SizedBox(width: width, child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, String name) async {
  if (name != 'popover') {
    final Finder trigger = switch (name) {
      'combo box' || 'filterable multi select' => find.byType(EditableText),
      'overflow menu' => find.byType(CarbonButton),
      'select' => find.text('gypy 0'),
      _ => find.byType(CarbonListBox),
    };
    await tester.tap(trigger.first);
    if (name == 'filterable multi select') {
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
  }
  await tester.pumpAndSettle();
}

Finder _popup(String name) => switch (name) {
  'popover' => find.byKey(const ValueKey<String>('popup')),
  'overflow menu' => find.byType(CarbonMenu),
  'select' => find.byType(SingleChildScrollView).last,
  _ => find.byType(CarbonListBoxMenu),
};

void main() {
  final Map<String, WidgetBuilder> surfaces = <String, WidgetBuilder>{
    for (final String name in <String>[
      'dropdown',
      'select',
      'combo box',
      'multi select',
      'filterable multi select',
    ])
      name: scaledFieldSpecimens()[name]!,
    'overflow menu': (_) => CarbonOverflowMenu(
      items: <Widget>[
        CarbonMenuItem(label: 'Edit', onPressed: () {}),
        CarbonMenuItem(label: 'Duplicate', onPressed: () {}),
      ],
    ),
    'popover': (_) => const CarbonPopover(
      open: true,
      autoAlign: true,
      content: SizedBox(
        key: ValueKey<String>('popup'),
        width: 250,
        height: 130,
        child: Text('Popover body'),
      ),
      child: SizedBox(width: 180, height: 32),
    ),
  };
  for (final TextDirection direction in TextDirection.values) {
    for (final Alignment corner in <Alignment>[
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ]) {
      for (final MapEntry<String, WidgetBuilder> entry in surfaces.entries) {
        testWidgets('${entry.key} fits $corner in $direction', (tester) async {
          tester.view.physicalSize = const Size(320, 360);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
          await tester.pumpWidget(
            _host(Builder(builder: entry.value), direction, corner),
          );
          await _open(tester, entry.key);
          final Finder popup = _popup(entry.key);
          final Rect bounds = tester.getRect(popup.first);
          expect(bounds.left, greaterThanOrEqualTo(-0.01));
          expect(bounds.right, lessThanOrEqualTo(320.01));
          expect(bounds.top, greaterThanOrEqualTo(-0.01));
          expect(bounds.bottom, lessThanOrEqualTo(360.01));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final MapEntry<String, WidgetBuilder> entry in surfaces.entries) {
    testWidgets('${entry.key} follows scroll and viewport resize', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 280),
                Builder(builder: entry.value),
                const SizedBox(height: 600),
              ],
            ),
          ),
          TextDirection.ltr,
          Alignment.topLeft,
        ),
      );
      await _open(tester, entry.key);
      final Finder trigger = find.byType(CompositedTransformTarget).first;
      expect(
        tester.getRect(_popup(entry.key)).bottom,
        lessThanOrEqualTo(tester.getRect(trigger).top + 0.01),
      );
      scroll.jumpTo(220);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_popup(entry.key)).top,
        greaterThanOrEqualTo(tester.getRect(trigger).bottom - 0.01),
      );
      // Resizing an already open surface must change its side and bounds.
      tester.view.physicalSize = const Size(240, 160);
      await tester.pumpAndSettle();
      final Rect resized = tester.getRect(_popup(entry.key));
      expect(resized.left, greaterThanOrEqualTo(-0.01));
      expect(resized.right, lessThanOrEqualTo(240.01));
      expect(resized.top, greaterThanOrEqualTo(-0.01));
      expect(resized.bottom, lessThanOrEqualTo(160.01));
      expect(tester.takeException(), isNull);
    });
  }
  for (final CarbonDropdownDirection side in CarbonDropdownDirection.values) {
    testWidgets('explicit dropdown $side remains pinned on collision', (
      tester,
    ) async {
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final bool below = side == CarbonDropdownDirection.bottom;
      await tester.pumpWidget(
        _host(
          CarbonDropdown<int>(
            titleText: 'City',
            selectedItem: 0,
            direction: side,
            items: const <CarbonDropdownItem<int>>[
              CarbonDropdownItem<int>(value: 0, label: 'gypy 0'),
              CarbonDropdownItem<int>(value: 1, label: 'gypy 1'),
            ],
            onChanged: (_) {},
          ),
          TextDirection.ltr,
          below ? Alignment.bottomLeft : Alignment.topLeft,
        ),
      );
      await _open(tester, 'dropdown');
      final Rect field = tester.getRect(find.byType(CompositedTransformTarget));
      final Rect popup = tester.getRect(_popup('dropdown'));
      if (below) {
        expect(popup.top, moreOrLessEquals(field.bottom));
      } else {
        expect(popup.bottom, moreOrLessEquals(field.top));
      }
    });
  }
  test('placement preserves logical start/end and physical pinning', () {
    const Rect target = Rect.fromLTWH(110, 100, 80, 30);
    const Size surface = Size(120, 60);
    const Rect viewport = Rect.fromLTWH(0, 0, 320, 360);
    for (final TextDirection direction in TextDirection.values) {
      for (final CarbonOverlayAlignment alignment
          in CarbonOverlayAlignment.values) {
        final CarbonOverlayGeometry result = carbonOverlayGeometry(
          target: target,
          surface: surface,
          viewport: viewport,
          direction: direction,
          alignment: alignment,
        );
        final double expected = alignment == CarbonOverlayAlignment.center
            ? 90
            : (alignment == CarbonOverlayAlignment.start) ==
                  (direction == TextDirection.ltr)
            ? 110
            : 70;
        expect(result.bounds.left, expected);
        expect(result.bounds.top, target.bottom);
      }
      for (final CarbonOverlaySide side in <CarbonOverlaySide>[
        CarbonOverlaySide.start,
        CarbonOverlaySide.end,
      ]) {
        final CarbonOverlayGeometry result = carbonOverlayGeometry(
          target: target,
          surface: surface,
          viewport: viewport,
          direction: direction,
          side: side,
          automatic: false,
        );
        final bool left =
            (side == CarbonOverlaySide.start) ==
            (direction == TextDirection.ltr);
        expect(
          result.side,
          left ? CarbonOverlaySide.left : CarbonOverlaySide.right,
        );
        expect(
          left ? result.bounds.right : result.bounds.left,
          left ? target.left : target.right,
        );
      }
    }
    // A surface larger than the available room is bounded deterministically.
    final CarbonOverlayGeometry oversized = carbonOverlayGeometry(
      target: target,
      surface: const Size(500, 500),
      viewport: viewport,
      direction: TextDirection.ltr,
    );
    expect(oversized.bounds.topLeft, Offset.zero);
  });
  for (final TextDirection direction in TextDirection.values) {
    testWidgets('submenu flips and stays inside in $direction', (tester) async {
      tester.view.physicalSize = const Size(320, 160);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      await tester.pumpWidget(
        _host(
          CarbonMenu(
            children: <Widget>[
              CarbonMenuItem(
                label: 'More',
                submenu: <Widget>[
                  CarbonMenuItem(label: 'Nested action', onPressed: () {}),
                  CarbonMenuItem(label: 'Another action', onPressed: () {}),
                ],
              ),
            ],
          ),
          direction,
          direction == TextDirection.ltr
              ? Alignment.bottomRight
              : Alignment.bottomLeft,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      final Rect popup = tester.getRect(find.byType(CarbonMenu).last);
      expect(popup.left, greaterThanOrEqualTo(-0.01));
      expect(popup.right, lessThanOrEqualTo(320.01));
      expect(popup.top, greaterThanOrEqualTo(-0.01));
      expect(popup.bottom, lessThanOrEqualTo(160.01));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('a bounded action menu reveals keyboard focus below the fold', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      _host(
        CarbonOverflowMenu(
          items: <Widget>[
            for (int n = 0; n < 20; n++)
              CarbonMenuItem(label: 'Action $n', onPressed: () {}),
          ],
        ),
        TextDirection.ltr,
        Alignment.topLeft,
      ),
    );
    await _open(tester, 'overflow menu');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    final Rect viewport = tester.getRect(find.byType(SingleChildScrollView));
    final Rect row = tester.getRect(find.text('Action 19'));
    expect(row.top, greaterThanOrEqualTo(viewport.top));
    expect(row.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'placement follows retained layers without idle frames or rebuilding the popup',
    (tester) async {
      tester.view.physicalSize = const Size(640, 720);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
      final LayerLink link = LayerLink();
      final OverlayPortalController portal = OverlayPortalController()..show();
      final ScrollController scroll = ScrollController();
      addTearDown(scroll.dispose);
      int placements = 0;
      int builds = 0;
      await tester.pumpWidget(
        _host(
          SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 280),
                CompositedTransformTarget(
                  link: link,
                  child: OverlayPortal(
                    controller: portal,
                    overlayChildBuilder: (_) => CarbonAnchoredOverlay(
                      link: link,
                      onPlacement: (_, _) => placements++,
                      child: Builder(
                        builder: (_) {
                          builds++;
                          return const SizedBox(
                            key: ValueKey<String>('retained-popup'),
                            width: 100,
                            height: 90,
                          );
                        },
                      ),
                    ),
                    child: const SizedBox(
                      key: ValueKey<String>('retained-trigger'),
                      width: 100,
                      height: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
          TextDirection.ltr,
          Alignment.topLeft,
        ),
      );
      await tester.pumpAndSettle();
      final int initialBuilds = builds;
      final int initialPlacements = placements;
      final Stopwatch watch = Stopwatch()..start();
      for (int frame = 1; frame <= 60; frame++) {
        scroll.jumpTo(frame * 3.0);
        await tester.pump();
      }
      watch.stop();
      expect(builds, initialBuilds);
      expect(placements - initialPlacements, 60);
      expect(tester.binding.hasScheduledFrame, isFalse);
      final Rect trigger = tester.getRect(
        find.byKey(const ValueKey<String>('retained-trigger')),
      );
      final Rect popup = tester.getRect(
        find.byKey(const ValueKey<String>('retained-popup')),
      );
      expect(popup.top, moreOrLessEquals(trigger.bottom));
      expect(popup.left, moreOrLessEquals(trigger.left));
      // Observational timing includes the entire test frame, not only placement.
      debugPrint(
        'OVERLAY-MEASURE frames=60 placements=60 rebuilds=0 totalUs=${watch.elapsedMicroseconds}',
      );
    },
  );
  for (final CarbonOverlaySide side in <CarbonOverlaySide>[
    CarbonOverlaySide.top,
    CarbonOverlaySide.bottom,
  ]) {
    final Map<String, Widget> pinned = <String, Widget>{
      'select': CarbonSelect<int>(
        labelText: 'City',
        menuSide: side,
        items: const <CarbonSelectItem<int>>[
          CarbonSelectItem<int>(value: 0, label: 'gypy 0'),
        ],
        value: 0,
        onChanged: (_) {},
      ),
      'combo box': CarbonComboBox<int>(
        titleText: 'City',
        menuSide: side,
        items: const <CarbonComboBoxItem<int>>[
          CarbonComboBoxItem<int>(value: 0, label: 'gypy 0'),
        ],
        onChanged: (_) {},
      ),
      'multi select': CarbonMultiSelect<int>(
        titleText: 'City',
        label: 'Choose a city',
        menuSide: side,
        items: const <CarbonMultiSelectItem<int>>[
          CarbonMultiSelectItem<int>(value: 0, label: 'gypy 0'),
        ],
        onChanged: (_) {},
      ),
      'overflow menu': CarbonOverflowMenu(
        menuSide: side,
        items: <Widget>[CarbonMenuItem(label: 'Edit', onPressed: () {})],
      ),
      'menu button': CarbonMenuButton(
        label: 'Actions',
        menuSide: side,
        items: <Widget>[CarbonMenuItem(label: 'Edit', onPressed: () {})],
      ),
      'combo button': CarbonComboButton(
        label: 'Save',
        menuSide: side,
        onPressed: () {},
        items: <Widget>[CarbonMenuItem(label: 'Edit', onPressed: () {})],
      ),
    };
    for (final MapEntry<String, Widget> entry in pinned.entries) {
      testWidgets('${entry.key} accepts a pinned $side', (tester) async {
        addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
        final bool below = side == CarbonOverlaySide.bottom;
        await tester.pumpWidget(
          _host(
            entry.value,
            TextDirection.rtl,
            below ? Alignment.bottomRight : Alignment.topRight,
            width: entry.key == 'combo button' ? 400 : 180,
          ),
        );
        if (entry.key.endsWith('button')) {
          await tester.tap(find.byType(CarbonButton).last);
          await tester.pumpAndSettle();
        } else {
          await _open(tester, entry.key);
        }
        final Rect target = tester.getRect(
          find.byType(CompositedTransformTarget).first,
        );
        final Rect popup = tester.getRect(
          entry.key.endsWith('button')
              ? find.byType(CarbonMenu)
              : _popup(entry.key),
        );
        expect(
          below ? popup.top : popup.bottom,
          moreOrLessEquals(below ? target.bottom : target.top),
        );
      });
    }
  }
  for (final MapEntry<String, WidgetBuilder> entry in surfaces.entries) {
    testWidgets('${entry.key} bottom-edge viewport goldens', (tester) async {
      await expectThemeGoldens(
        tester,
        name: 'anchored_${entry.key.replaceAll(' ', '_')}_bottom_edge',
        containsText: true,
        size: const Size(320, 360),
        mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => TapRegionSurface(
          child: Overlay(
            initialEntries: <OverlayEntry>[
              managedOverlayEntry(
                builder: (_) => Align(
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: 180,
                    child: Builder(builder: entry.value),
                  ),
                ),
              ),
            ],
          ),
        ),
        afterPump: (tester) => _open(tester, entry.key),
      );
    });
  }
  testWidgets('a transformed trigger preserves its local gap and popup scale', (
    tester,
  ) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    final LayerLink link = LayerLink();
    final OverlayPortalController portal = OverlayPortalController()..show();
    await tester.pumpWidget(
      _host(
        Transform.scale(
          scale: 1.25,
          alignment: Alignment.topLeft,
          child: CompositedTransformTarget(
            link: link,
            child: OverlayPortal(
              controller: portal,
              overlayChildBuilder: (_) => CarbonAnchoredOverlay(
                link: link,
                gap: 8,
                child: const SizedBox(
                  key: ValueKey<String>('scaled-popup'),
                  width: 40,
                  height: 40,
                ),
              ),
              child: const SizedBox(
                key: ValueKey<String>('scaled-trigger'),
                width: 70,
                height: 40,
              ),
            ),
          ),
        ),
        TextDirection.ltr,
        Alignment.topLeft,
      ),
    );
    await tester.pumpAndSettle();
    final Rect trigger = tester.getRect(
      find.byKey(const ValueKey<String>('scaled-trigger')),
    );
    final Rect popup = tester.getRect(
      find.byKey(const ValueKey<String>('scaled-popup')),
    );
    expect(popup.top, moreOrLessEquals(trigger.bottom + 10));
    expect(popup.width, 50);
    expect(popup.height, 50);
    expect(popup.left, moreOrLessEquals(trigger.left));
  });
}
