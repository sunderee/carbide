// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Align(alignment: Alignment.topCenter, child: child),
    ),
  ),
);

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('layout / spec-lock', () {
    testWidgets('rows take the configured size height', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final CarbonContainedListSize size
                  in CarbonContainedListSize.values)
                CarbonContainedList(
                  size: size,
                  children: <Widget>[
                    CarbonContainedListItem(
                      key: ValueKey<CarbonContainedListSize>(size),
                      child: const Text('Item'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );
      for (final CarbonContainedListSize size
          in CarbonContainedListSize.values) {
        expect(
          tester
              .getSize(find.byKey(ValueKey<CarbonContainedListSize>(size)))
              .height,
          closeTo(size.height, 0.01),
          reason: '$size row should be ${size.height}px',
        );
      }
    });

    testWidgets('content is body-01', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonContainedList(
            children: <Widget>[CarbonContainedListItem(child: Text('Item'))],
          ),
        ),
      );
      final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Item'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(style.style.fontSize, 14);
      expect(style.style.color, CarbonThemeData.white.textPrimary);
    });

    testWidgets('on-page header uses layerBackground; disclosed uses layer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonContainedList(
            label: Text('On page'),
            children: <Widget>[CarbonContainedListItem(child: Text('Item'))],
          ),
        ),
      );
      DecoratedBox header() => tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('On page'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (header().decoration as BoxDecoration).color,
        CarbonThemeData.white.layerBackground01,
      );

      await tester.pumpWidget(
        _host(
          const CarbonContainedList(
            label: Text('Disclosed'),
            kind: CarbonContainedListKind.disclosed,
            children: <Widget>[CarbonContainedListItem(child: Text('Item'))],
          ),
        ),
      );
      final DecoratedBox disclosed = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.text('Disclosed'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (disclosed.decoration as BoxDecoration).color,
        CarbonThemeData.white.layer01,
      );
    });

    testWidgets('renders a leading icon and a trailing action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonContainedList(
            children: <Widget>[
              CarbonContainedListItem(
                icon: CarbonIcons.bookmark,
                action: Text('Action'),
                child: Text('Item'),
              ),
            ],
          ),
        ),
      );
      expect(find.byType(CarbonIcon), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
    });
  });

  group('clickable', () {
    testWidgets('a clickable item calls onPressed', (
      WidgetTester tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        _host(
          CarbonContainedList(
            children: <Widget>[
              CarbonContainedListItem(
                onPressed: () => tapped = true,
                child: const Text('Item'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Item'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('hover fills the contextual layerHover token', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CarbonContainedList(
            children: <Widget>[
              CarbonContainedListItem(
                onPressed: () {},
                child: const Text('Item'),
              ),
            ],
          ),
        ),
      );
      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Item')));
      await tester.pumpAndSettle();

      final AnimatedContainer fill = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.text('Item'),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(
        (fill.decoration! as BoxDecoration).color,
        CarbonThemeData.white.layerHover01,
      );
    });

    testWidgets('disabled is inert and greyed', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _host(
          CarbonContainedList(
            children: <Widget>[
              CarbonContainedListItem(
                onPressed: () => tapped = true,
                disabled: true,
                child: const Text('Item'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Item'));
      await tester.pumpAndSettle();
      expect(tapped, isFalse);
      final DefaultTextStyle style = tester.widget<DefaultTextStyle>(
        find
            .ancestor(
              of: find.text('Item'),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(style.style.color, CarbonThemeData.white.textDisabled);
    });
  });

  group('semantics', () {
    testWidgets('a clickable item is a button', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonContainedList(
            children: <Widget>[
              CarbonContainedListItem(
                onPressed: () {},
                child: const Text('Open'),
              ),
            ],
          ),
        ),
      );
      final SemanticsNode node = tester.getSemantics(find.text('Open'));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });

  group('goldens', () {
    CarbonContainedList sample() => CarbonContainedList(
      label: const Text('Recent files'),
      children: <Widget>[
        const CarbonContainedListItem(
          icon: CarbonIcons.document,
          child: Text('report.pdf'),
        ),
        CarbonContainedListItem(
          icon: CarbonIcons.document,
          onPressed: () {},
          child: const Text('notes.txt'),
        ),
        const CarbonContainedListItem(
          icon: CarbonIcons.document,
          disabled: true,
          child: Text('archive.zip'),
        ),
      ],
    );

    testWidgets('contained list (layer 0)', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'contained_list',
        containsText: true,
        size: const Size(320, 200),
        builder: (BuildContext context) =>
            Align(alignment: Alignment.topCenter, child: sample()),
      );
    });

    testWidgets('contained list (layer 1)', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'contained_list_layer1',
        containsText: true,
        size: const Size(320, 200),
        builder: (BuildContext context) => CarbonLayer(
          child: Align(alignment: Alignment.topCenter, child: sample()),
        ),
      );
    });
  });

  group('accessibility guidelines (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // Clickable rows gate both axes at the default size: list items are
      // `layout.use('size', $default: 'lg')` = 48px (`_contained-list.scss`).
      await tester.pumpWidget(
        _host(
          CarbonContainedList(
            label: const Text('Files'),
            children: <Widget>[
              CarbonContainedListItem(
                onPressed: () {},
                child: const Text('One'),
              ),
              CarbonContainedListItem(
                onPressed: () {},
                child: const Text('Two'),
              ),
            ],
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });
}
