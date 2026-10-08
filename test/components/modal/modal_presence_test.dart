// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';

Widget host(Widget child, {bool reduced = false}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Overlay(
        initialEntries: [managedOverlayEntry(builder: (_) => child)],
      ),
    ),
  ),
);
Widget dialog(bool open, String kind, {FocusNode? focus}) => kind == 'modal'
    ? CarbonModal(
        open: open,
        title: 'Surface title',
        onClose: () {},
        child: CarbonButton(
          label: 'Inside',
          focusNode: focus,
          onPressed: () {},
        ),
      )
    : CarbonDialog(
        open: open,
        modal: kind != 'nonmodal',
        children: [
          const CarbonDialogHeader(
            children: [CarbonDialogTitle('Surface title')],
          ),
          CarbonDialogBody(
            child: CarbonButton(
              label: 'Inside',
              focusNode: focus,
              onPressed: () {},
            ),
          ),
        ],
      );
void check(String name, WidgetTesterCallback body) =>
    testWidgets(name, (tester) async {
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    });

void main() {
  for (final kind in ['modal', 'dialog', 'nonmodal']) {
    testWidgets(
      '$kind remains present during exit and restores modal focus at completion',
      (tester) async {
        final semantics = tester.ensureSemantics(),
            open = ValueNotifier(false),
            launcher = FocusNode(),
            inside = FocusNode();
        addTearDown(open.dispose);
        addTearDown(launcher.dispose);
        addTearDown(inside.dispose);
        try {
          await tester.pumpWidget(
            host(
              ValueListenableBuilder(
                valueListenable: open,
                builder: (c, value, _) => Stack(
                  children: [
                    CarbonButton(
                      label: 'Launch',
                      focusNode: launcher,
                      onPressed: () => open.value = true,
                    ),
                    dialog(value, kind, focus: inside),
                  ],
                ),
              ),
            ),
          );
          launcher.requestFocus();
          await tester.pump();
          open.value = true;
          await tester.pumpAndSettle();
          inside.requestFocus();
          await tester.pump();
          open.value = false;
          await tester.pump();
          await tester.pump();
          expect(find.text('Surface title'), findsOneWidget);
          expect(inside.hasPrimaryFocus, isTrue);
          expect(
            tester
                .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
                .first
                .opacity,
            0,
          );
          expect(
            tester
                .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
                .first
                .curve,
            CarbonEasing.exitExpressive,
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Surface title'), findsOneWidget);
          expect(find.bySemanticsLabel('Inside'), findsOneWidget);
          expect(inside.hasPrimaryFocus, isTrue);
          await tester.pump(CarbonDuration.moderate02);
          await tester.pumpAndSettle();
          expect(find.text('Surface title'), findsNothing);
          if (kind != 'nonmodal') expect(launcher.hasPrimaryFocus, isTrue);
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          semantics.dispose();
        }
      },
    );
    check('$kind reduced motion closes on the next frame', (tester) async {
      final open = ValueNotifier(true);
      addTearDown(open.dispose);
      await tester.pumpWidget(
        host(
          ValueListenableBuilder(
            valueListenable: open,
            builder: (c, v, _) => dialog(v, kind),
          ),
          reduced: true,
        ),
      );
      await tester.pumpAndSettle();
      open.value = false;
      await tester.pump();
      await tester.pump();
      expect(find.text('Surface title'), findsNothing);
    });
    check('$kind reopening cancels an in-flight exit', (tester) async {
      final open = ValueNotifier(true);
      addTearDown(open.dispose);
      await tester.pumpWidget(
        host(
          ValueListenableBuilder(
            valueListenable: open,
            builder: (c, v, _) => dialog(v, kind),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state(
        find.byType(kind == 'modal' ? CarbonModal : CarbonDialog),
      );
      open.value = false;
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      open.value = true;
      await tester.pump();
      await tester.pump(CarbonDuration.moderate02);
      await tester.pumpAndSettle();
      expect(find.text('Surface title'), findsOneWidget);
      expect(
        tester.state(find.byType(kind == 'modal' ? CarbonModal : CarbonDialog)),
        same(state),
      );
      expect(
        tester
            .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .first
            .opacity,
        1,
      );
      open.value = false;
      await tester.pumpAndSettle();
      expect(find.text('Surface title'), findsNothing);
    });
    check('$kind background wheel, touch and clicks respect modal mode', (
      tester,
    ) async {
      final scroll = ScrollController(), open = ValueNotifier(false);
      addTearDown(scroll.dispose);
      addTearDown(open.dispose);
      int clicks = 0;
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            controller: scroll,
            child: Column(
              children: [
                SizedBox(
                  height: 600,
                  child: Overlay(
                    initialEntries: [
                      managedOverlayEntry(
                        builder: (_) => Stack(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: CarbonButton(
                                label: 'Background',
                                onPressed: () => clicks++,
                              ),
                            ),
                            ValueListenableBuilder(
                              valueListenable: open,
                              builder: (c, v, _) => dialog(v, kind),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final background = tester.getCenter(find.bySemanticsLabel('Background'));
      open.value = true;
      await tester.pumpAndSettle();
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(20, 20),
          scrollDelta: Offset(0, 120),
        ),
      );
      await tester.pumpAndSettle();
      if (kind == 'nonmodal')
        expect(scroll.offset, greaterThan(0));
      else
        expect(scroll.offset, 0);
      scroll.jumpTo(0);
      await tester.pump();
      await tester.dragFrom(const Offset(20, 100), const Offset(0, -60));
      await tester.pumpAndSettle();
      if (kind == 'nonmodal')
        expect(scroll.offset, greaterThan(0));
      else
        expect(scroll.offset, 0);
      scroll.jumpTo(0);
      await tester.pump();
      await tester.tapAt(background);
      await tester.pumpAndSettle();
      expect(clicks, kind == 'nonmodal' ? 1 : 0);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
