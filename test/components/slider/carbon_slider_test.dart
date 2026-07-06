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
    child: Center(child: SizedBox(width: 400, child: child)),
  ),
);

Rect _trackRect(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(CarbonSlider),
        matching: find.byType(GestureDetector),
      )
      .first,
);

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('spec locks (_slider.scss)', () {
    test('track 2px, thumb 14px constants', () {
      expect(CarbonSlider.trackHeight, 2);
      expect(CarbonSlider.thumbSize, 14);
    });

    testWidgets('renders min/max range labels and a 14px thumb', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonSlider(
            labelText: 'Volume',
            value: 50,
            min: 0,
            max: 100,
            hideTextInput: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(tester.getSize(find.byType(AnimatedScale)), const Size(14, 14));
    });
  });

  group('value setting', () {
    // A self-managing host reporting each change through [sink]; a UniqueKey
    // keeps each pump's State fresh.
    Widget controlled(num initial, void Function(num) sink) {
      num value = initial;
      return _host(
        StatefulBuilder(
          key: UniqueKey(),
          builder: (BuildContext context, StateSetter setState) => CarbonSlider(
            value: value,
            min: 0,
            max: 100,
            hideTextInput: true,
            onChanged: (num v) {
              setState(() => value = v);
              sink(v);
            },
          ),
        ),
      );
    }

    testWidgets('clicking the track jumps the value', (
      WidgetTester tester,
    ) async {
      num? reported;
      await tester.pumpWidget(controlled(50, (num v) => reported = v));
      final Rect rect = _trackRect(tester);
      await tester.tapAt(Offset(rect.left + rect.width * 0.25, rect.center.dy));
      await tester.pump();
      expect(reported, closeTo(25, 2));
    });

    testWidgets('dragging moves the value', (WidgetTester tester) async {
      num? reported;
      await tester.pumpWidget(controlled(50, (num v) => reported = v));
      final Rect rect = _trackRect(tester);
      await tester.dragFrom(rect.center, const Offset(-80, 0));
      await tester.pump();
      expect(reported, isNotNull);
      expect(reported, lessThan(50));
    });

    testWidgets('arrow keys, Home and End step/jump the focused thumb', (
      WidgetTester tester,
    ) async {
      num? reported;
      await tester.pumpWidget(controlled(50, (num v) => reported = v));
      final Rect rect = _trackRect(tester);
      // Tap centre to focus the (lower) thumb near 50.
      await tester.tapAt(rect.center);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(reported, closeTo(51, 1.5));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(reported, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(reported, 100);
    });

    testWidgets('disabled ignores input', (WidgetTester tester) async {
      bool changed = false;
      await tester.pumpWidget(
        _host(
          const CarbonSlider(
            value: 50,
            min: 0,
            max: 100,
            hideTextInput: true,
            onChanged: null,
          ),
        ),
      );
      final Rect rect = _trackRect(tester);
      await tester.tapAt(Offset(rect.left + 10, rect.center.dy));
      await tester.pump();
      expect(changed, isFalse);
    });
  });

  group('two-handle', () {
    testWidgets('dragging near the upper thumb moves only it', (
      WidgetTester tester,
    ) async {
      num lower = 20;
      num upper = 80;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                CarbonSlider(
                  value: lower,
                  upperValue: upper,
                  min: 0,
                  max: 100,
                  onChanged: (num v) => setState(() => lower = v),
                  onUpperChanged: (num v) => setState(() => upper = v),
                ),
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNWidgets(2));
      final Rect rect = _trackRect(tester);
      // Tap at ~70% (closer to the upper thumb at 80).
      await tester.tapAt(Offset(rect.left + rect.width * 0.7, rect.center.dy));
      await tester.pump();
      expect(upper, closeTo(70, 3));
      expect(lower, 20);
    });
  });

  group('value input & validation', () {
    testWidgets('typing in the value box updates the slider on submit', (
      WidgetTester tester,
    ) async {
      num value = 50;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) =>
                CarbonSlider(
                  value: value,
                  min: 0,
                  max: 100,
                  onChanged: (num v) => setState(() => value = v),
                ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), '30');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(value, 30);
    });

    testWidgets('invalid shows the message', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          CarbonSlider(
            value: 50,
            min: 0,
            max: 100,
            invalid: true,
            invalidText: 'Out of range',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Out of range'), findsOneWidget);
    });

    testWidgets('thumb exposes slider semantics', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonSlider(
            value: 42,
            min: 0,
            max: 100,
            hideTextInput: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(AnimatedScale)),
        isSemantics(isSlider: true, value: '42'),
      );
      handle.dispose();
    });

    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonSlider(
            labelText: 'Volume',
            value: 50,
            min: 0,
            max: 100,
            onChanged: (_) {},
          ),
        ),
      );
      // Both guidelines pass: the 14px thumb (`_slider.scss` `block-size:
      // convert.to-rem(14px)`) exposes adjustable slider semantics rather
      // than a tap action, so no sub-48dp tap target exists to flag.
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('single + range + disabled across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'slider_states',
        containsText: true,
        size: const Size(420, 220),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CarbonSlider(
                  labelText: 'Single',
                  value: 40,
                  min: 0,
                  max: 100,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 16),
                CarbonSlider(
                  labelText: 'Range',
                  value: 25,
                  upperValue: 70,
                  min: 0,
                  max: 100,
                  onChanged: (_) {},
                  onUpperChanged: (_) {},
                ),
                const SizedBox(height: 16),
                const CarbonSlider(
                  labelText: 'Disabled',
                  value: 60,
                  min: 0,
                  max: 100,
                  hideTextInput: true,
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}
