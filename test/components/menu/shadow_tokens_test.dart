// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget surface, CarbonThemeData theme, {bool layered = false}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: CarbonTheme(
        data: theme,
        child: Center(
          child: SizedBox(
            width: 240,
            child: layered ? CarbonLayer(child: surface) : surface,
          ),
        ),
      ),
    );

BoxShadow _shadow(WidgetTester tester, Type type) {
  final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
    find.descendant(of: find.byType(type), matching: find.byType(DecoratedBox)),
  );
  final BoxDecoration decoration = boxes
      .map((DecoratedBox box) => box.decoration)
      .whereType<BoxDecoration>()
      .singleWhere(
        (BoxDecoration value) => value.boxShadow?.isNotEmpty ?? false,
      );
  expect(decoration.boxShadow, hasLength(1));
  return decoration.boxShadow!.single;
}

void _expectGeometry(BoxShadow shadow) {
  expect(shadow.offset, const Offset(0, 2));
  expect(shadow.blurRadius, 6);
  expect(shadow.spreadRadius, 0);
  expect(shadow.blurStyle, BlurStyle.normal);
}

void main() {
  for (final (String name, Type type, Widget Function() build)
      in <(String, Type, Widget Function())>[
        (
          'menu',
          CarbonMenu,
          () => CarbonMenu(
            autofocus: false,
            children: <Widget>[CarbonMenuItem(label: 'Copy', onPressed: () {})],
          ),
        ),
        (
          'list box',
          CarbonListBoxMenu,
          () => const CarbonListBoxMenu(
            children: <Widget>[
              CarbonListBoxMenuItem(isFirst: true, child: Text('Apple')),
            ],
          ),
        ),
      ]) {
    for (final CarbonThemeVariant variant in CarbonThemeVariant.values) {
      testWidgets(
        '$name resolves ${variant.label} shadow without moving geometry',
        (WidgetTester tester) async {
          await tester.pumpWidget(_host(build(), variant.theme));
          final BoxShadow shadow = _shadow(tester, type);
          expect(shadow.color, variant.theme.shadow);
          expect(
            shadow.color.a,
            variant.theme.brightness == Brightness.dark ? 0.8 : 0.3,
          );
          _expectGeometry(shadow);
        },
      );
    }
    testWidgets(
      '$name follows live theme and custom shadow changes across layers',
      (WidgetTester tester) async {
        final Widget surface = build();
        const Color custom = Color.from(
          alpha: 0.65,
          red: 0.2,
          green: 0.1,
          blue: 0.9,
        );
        for (final CarbonThemeData theme in <CarbonThemeData>[
          CarbonThemeData.white,
          CarbonThemeData.gray100,
          CarbonThemeData.gray10.copyWith(shadow: custom),
          CarbonThemeData.gray90,
          CarbonThemeData.white,
        ]) {
          await tester.pumpWidget(_host(surface, theme, layered: true));
          final BoxShadow shadow = _shadow(tester, type);
          expect(shadow.color, theme.shadow);
          _expectGeometry(shadow);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
