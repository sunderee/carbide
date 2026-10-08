// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/legibility.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(textScaler: TextScaler.linear(2)),
    child: DefaultTextStyle(
      style: CarbonTypeStyles.bodyCompact01,
      child: Center(child: child),
    ),
  ),
);

void main() {
  testWidgets('the guard rejects a scale clamp even when the line fits', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.noScaling),
          child: SizedBox(height: 48, child: Text('gypy')),
        ),
      ),
    );
    expect(
      () => expectNoClippedTextAtScale(tester, 2),
      throwsA(isA<TestFailure>()),
    );
  });
  testWidgets('the guard rejects a clipped inherited line box', (tester) async {
    await tester.pumpWidget(
      _host(const SizedBox(height: 30, child: Text('gypy'))),
    );
    expect(tester.takeException(), isNull);
    expect(
      () => expectNoClippedTextAtScale(tester, 2),
      throwsA(isA<TestFailure>()),
    );
  });

  testWidgets('the guard resolves Text semantics wrappers and actual font', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          height: 48,
          child: Text('gypy', semanticsLabel: 'Full name'),
        ),
      ),
    );
    expectNoClippedTextAtScale(tester, 2);
  });

  testWidgets('the guard rejects a clipped editor with no Text widgets', (
    tester,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: 'gypy',
    );
    final FocusNode focus = FocusNode();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      focus.dispose();
    });
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 160,
          height: 30,
          child: EditableText(
            controller: controller,
            focusNode: focus,
            style: CarbonTypeStyles.bodyCompact01,
            cursorColor: CarbonColors.blue60,
            backgroundCursorColor: CarbonColors.gray50,
          ),
        ),
      ),
    );
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      () => expectNoClippedTextAtScale(tester, 2),
      throwsA(isA<TestFailure>()),
    );
  });
}
