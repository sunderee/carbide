// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 360, child: child)),
  ),
);

double _bodyFactor(WidgetTester tester, String body) => tester
    .widget<Align>(
      find.ancestor(of: find.text(body), matching: find.byType(Align)).first,
    )
    .heightFactor!;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('motion', () {
    testWidgets('spec tokens match _accordion.scss', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(title: 'A', child: Text('Body')),
            ],
          ),
        ),
      );
      // `__arrow`: all $duration-fast-02 motion(standard, productive).
      final AnimatedRotation chevron = tester.widget(
        find.byType(AnimatedRotation),
      );
      expect(chevron.duration, CarbonDuration.fast02);
      expect(chevron.curve, CarbonEasing.standardProductive);
      // `__heading:hover`: background motion(standard, productive)
      // $duration-fast-02.
      final AnimatedContainer header = tester.widget(
        find.byType(AnimatedContainer),
      );
      expect(header.duration, CarbonDuration.fast02);
      expect(header.curve, CarbonEasing.standardProductive);
      // `__wrapper`: all $duration-fast-02 motion(entrance, productive).
      final TweenAnimationBuilder<double> fold = tester.widget(
        find.byType(TweenAnimationBuilder<double>),
      );
      expect(fold.duration, CarbonDuration.fast02);
      expect(fold.curve, CarbonEasing.entranceProductive);
    });

    testWidgets('reduced motion opens instantly', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: CarbonAccordion(
              children: <Widget>[
                CarbonAccordionItem(title: 'A', child: Text('Body')),
              ],
            ),
          ),
        ),
      );
      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).duration,
        Duration.zero,
      );
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>),
            )
            .duration,
        Duration.zero,
      );
      // The body fold is fully open on the next frame.
      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.pump();
      expect(_bodyFactor(tester, 'Body'), 1);
    });
  });

  group('toggle', () {
    testWidgets('tapping the title expands and collapses the body', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(title: 'Section', child: Text('Body')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_bodyFactor(tester, 'Body'), 0);
      await tester.tap(find.text('Section'));
      await tester.pumpAndSettle();
      expect(_bodyFactor(tester, 'Body'), 1);
      await tester.tap(find.text('Section'));
      await tester.pumpAndSettle();
      expect(_bodyFactor(tester, 'Body'), 0);
    });

    testWidgets('initiallyOpen starts expanded', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(
                title: 'Section',
                initiallyOpen: true,
                child: Text('Body'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_bodyFactor(tester, 'Body'), 1);
    });

    testWidgets('Enter toggles via the keyboard', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        _host(
          CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(
                title: 'Section',
                focusNode: node,
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(_bodyFactor(tester, 'Body'), 1);
    });

    testWidgets('items are independent (multiple open)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(title: 'One', child: Text('Body one')),
              CarbonAccordionItem(title: 'Two', child: Text('Body two')),
            ],
          ),
        ),
      );
      await tester.tap(find.text('One'));
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(_bodyFactor(tester, 'Body one'), 1);
      expect(_bodyFactor(tester, 'Body two'), 1);
    });

    testWidgets('disabled item does not toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(
                title: 'Section',
                disabled: true,
                child: Text('Body'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Section'));
      await tester.pumpAndSettle();
      expect(_bodyFactor(tester, 'Body'), 0);
      expect(
        tester.widget<Text>(find.text('Section')).style!.color,
        theme.textDisabled,
      );
    });
  });

  group('controlled', () {
    testWidgets('open + onOpenChanged are honoured', (
      WidgetTester tester,
    ) async {
      bool? changed;
      await tester.pumpWidget(
        _host(
          CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(
                title: 'Section',
                open: false,
                onOpenChanged: (bool v) => changed = v,
                child: const Text('Body'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Section'));
      await tester.pumpAndSettle();
      expect(changed, isTrue);
      // Controlled: stays closed until the parent flips `open`.
      expect(_bodyFactor(tester, 'Body'), 0);
    });
  });

  group('semantics', () {
    testWidgets('header is a button exposing expanded state', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonAccordion(
            children: <Widget>[
              CarbonAccordionItem(
                title: 'Section',
                initiallyOpen: true,
                child: Text('Body'),
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Section')),
        isSemantics(label: 'Section', isButton: true, isExpanded: true),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // The md header is 40px (_accordion.scss layout.use('size',
      // $default: 'md')) — below the 48dp android guideline, so pump the
      // real lg (48px) variant instead.
      await tester.pumpWidget(
        _host(
          const CarbonAccordion(
            size: CarbonFieldSize.lg,
            children: <Widget>[
              CarbonAccordionItem(title: 'Section', child: Text('Body')),
            ],
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('accordion across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'accordion',
        containsText: true,
        size: const Size(360, 260),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 320,
            child: CarbonAccordion(
              children: const <Widget>[
                CarbonAccordionItem(
                  title: 'Getting started',
                  initiallyOpen: true,
                  child: Text('A short description of how to begin.'),
                ),
                CarbonAccordionItem(
                  title: 'Configuration',
                  child: Text('Hidden body.'),
                ),
                CarbonAccordionItem(
                  title: 'Unavailable',
                  disabled: true,
                  child: Text('Hidden body.'),
                ),
              ],
            ),
          ),
        ),
        afterPump: (WidgetTester tester) async {
          await tester.pumpAndSettle();
        },
      );
    });
  });
}
