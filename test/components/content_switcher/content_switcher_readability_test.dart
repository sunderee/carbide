// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0. See LICENSE.
import 'dart:ui' show ViewFocusEvent, ViewFocusState, ViewFocusDirection;

import 'package:carbide/carbide.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart'
    show SemanticsAction, SemanticsActionEvent;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';

const switches = <CarbonSwitch>[
  CarbonSwitch(text: 'First segment'),
  CarbonSwitch(text: 'Second segment'),
  CarbonSwitch(text: 'Third segment'),
];
Widget host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  onGenerateRoute: (_) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Directionality(
        textDirection: direction,
        child: CarbonTheme(
          data: CarbonThemeData.white,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  ),
);
void main() {
  testWidgets(
    'fitting default preserves equal full-width segments and density',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final h = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            CarbonContentSwitcher(switches: switches, onChanged: (_) {}),
            width: 760,
          ),
        );
        expect(tester.getSize(find.byType(CarbonContentSwitcher)).height, 40);
        for (final s in switches) {
          expect(
            tester.getSize(find.bySemanticsLabel(s.text!)).width,
            closeTo(760 / 3, .01),
          );
        }
      } finally {
        h.dispose();
      }
    },
  );
  for (final width in [160.0, 320.0]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets(
          'label space and keyboard stay usable $width/$direction/$scale',
          (tester) async {
            final h = tester.ensureSemantics();
            try {
              var selected = 0;
              await tester.pumpWidget(
                host(
                  StatefulBuilder(
                    builder: (_, update) => CarbonContentSwitcher(
                      switches: switches,
                      selectedIndex: selected,
                      onChanged: (i) => update(() => selected = i),
                    ),
                  ),
                  width: width,
                  scale: scale,
                  direction: direction,
                ),
              );
              await tester.pumpAndSettle();
              expectNoClippedTextAtScale(tester, scale);
              for (final s in switches) {
                final r = tester.renderObject<RenderParagraph>(
                  find.descendant(
                    of: find.text(s.text!),
                    matching: find.byType(RichText),
                  ),
                );
                final p = TextPainter(
                  text: TextSpan(text: 'M…', style: r.text.style),
                  textScaler: r.textScaler,
                  textDirection: direction,
                )..layout();
                expect(
                  r.size.width,
                  greaterThanOrEqualTo(p.width),
                  reason: 'retain space for a visible glyph and ellipsis',
                );
                p.dispose();
              }
              tester.binding.handleViewFocusChanged(
                ViewFocusEvent(
                  viewId: tester.view.viewId,
                  state: ViewFocusState.focused,
                  direction: ViewFocusDirection.undefined,
                ),
              );
              final last = find.bySemanticsLabel('Third segment');
              final node = tester.getSemantics(last);
              expect(
                node.getSemanticsData().hasAction(SemanticsAction.focus),
                isTrue,
              );
              tester.binding.platformDispatcher.onSemanticsActionEvent!(
                SemanticsActionEvent(
                  type: SemanticsAction.focus,
                  viewId: tester.view.viewId,
                  nodeId: node.id,
                ),
              );
              await tester.pumpAndSettle();
              expect(
                Focus.of(tester.element(find.text('Third segment'))).hasFocus,
                isTrue,
              );
              final rect = tester.getRect(last);
              expect(rect.left, greaterThanOrEqualTo(-.1));
              expect(rect.right, lessThanOrEqualTo(width + .1));
              await tester.sendKeyEvent(LogicalKeyboardKey.home);
              await tester.pumpAndSettle();
              expect(selected, 0);
              await tester.sendKeyEvent(
                direction == TextDirection.ltr
                    ? LogicalKeyboardKey.arrowRight
                    : LogicalKeyboardKey.arrowLeft,
              );
              await tester.pumpAndSettle();
              expect(selected, 1);
              await tester.sendKeyEvent(LogicalKeyboardKey.end);
              await tester.pumpAndSettle();
              expect(selected, 2);
              expect(tester.takeException(), isNull);
            } finally {
              h.dispose();
            }
          },
        );
      }
    }
  }
  testWidgets(
    'focused segment and controlled selection survive width and scale updates',
    (tester) async {
      var width = 320.0, scale = 1.0;
      var selected = 1;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) {
              update = set;
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width,
                    child: CarbonContentSwitcher(
                      switches: switches,
                      selectedIndex: selected,
                      onChanged: (i) => set(() => selected = i),
                    ),
                  ),
                ),
              );
            },
          ),
          width: 320,
        ),
      );
      Focus.of(tester.element(find.text('Second segment'))).requestFocus();
      await tester.pumpAndSettle();
      final focus = Focus.of(tester.element(find.text('Second segment')));
      for (final w in [160.0, 320.0, 160.0]) {
        update(() {
          width = w;
          scale = 2;
        });
        await tester.pumpAndSettle();
        expect(
          Focus.of(tester.element(find.text('Second segment'))),
          same(focus),
        );
        expect(focus.hasFocus, isTrue);
        expect(selected, 1);
        expect(tester.takeException(), isNull);
      }
    },
  );
  for (final width in [160.0, 320.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('golden readable content switcher $width/$scale', (
        tester,
      ) async {
        await expectThemeGoldens(
          tester,
          name:
              'content_switcher_readable_${width.toInt()}_${scale.toString().replaceAll('.', '_')}',
          size: Size(width, 100),
          containsText: true,
          directions: TextDirection.values.toSet(),
          mediaQuery: MediaQueryData(textScaler: TextScaler.linear(scale)),
          builder: (_) => Align(
            alignment: Alignment.topLeft,
            child: CarbonContentSwitcher(
              switches: switches,
              selectedIndex: 1,
              onChanged: (_) {},
            ),
          ),
        );
      });
    }
  }
}
