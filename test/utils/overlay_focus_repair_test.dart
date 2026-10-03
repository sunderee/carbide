// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/src/utils/overlay_focus_repair.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final String guard in <String>[
    'current',
    'superseded',
    'disposed',
    'removed',
    'inactive',
    'new focus',
  ]) {
    testWidgets('overlay repair respects $guard focus ownership', (
      WidgetTester tester,
    ) async {
      final FocusNode target = FocusNode();
      final FocusNode other = FocusNode();
      final OverlayFocusRepair repair = OverlayFocusRepair();
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: <Widget>[
                Focus(
                  focusNode: target,
                  child: const SizedBox(width: 40, height: 40),
                ),
                Focus(
                  focusNode: other,
                  child: const SizedBox(width: 40, height: 40),
                ),
              ],
            ),
          ),
        );
        target.requestFocus();
        await tester.pump(const Duration(milliseconds: 1));
        int nativeRequests = 0;
        bool current = true;
        repair.schedule(target, () {
          nativeRequests++;
          return guard != 'inactive';
        }, isCurrent: () => current);
        switch (guard) {
          case 'superseded':
            current = false;
          case 'disposed':
            repair.dispose();
          case 'removed':
            await tester.pumpWidget(const SizedBox.shrink());
          case 'new focus':
            other.requestFocus();
          case 'current' || 'inactive':
            FocusManager.instance.rootScope.requestScopeFocus();
        }
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump(const Duration(milliseconds: 1));
        expect(nativeRequests > 0, guard == 'current' || guard == 'inactive');
        if (guard == 'current') expect(target.hasPrimaryFocus, isTrue);
        if (guard == 'inactive') expect(target.hasPrimaryFocus, isFalse);
        if (guard == 'new focus') expect(other.hasPrimaryFocus, isTrue);
        expect(tester.takeException(), isNull);
      } finally {
        repair.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
        target.dispose();
        other.dispose();
      }
    });
  }

  testWidgets('a newer overlay transition cancels the old native snapshot', (
    WidgetTester tester,
  ) async {
    final FocusNode target = FocusNode();
    final OverlayFocusRepair repair = OverlayFocusRepair();
    try {
      await tester.pumpWidget(
        Focus(focusNode: target, child: const SizedBox()),
      );
      target.requestFocus();
      await tester.pump(const Duration(milliseconds: 1));
      int oldRequests = 0;
      int newRequests = 0;
      repair.schedule(target, () {
        oldRequests++;
        return true;
      }, isCurrent: () => true);
      repair.schedule(target, () {
        newRequests++;
        return true;
      }, isCurrent: () => true);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(oldRequests, 0);
      expect(newRequests, greaterThan(0));
    } finally {
      repair.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      target.dispose();
    }
  });
}
