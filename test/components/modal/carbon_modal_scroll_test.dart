// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Scroll behavior of the modal body (#232): content taller than the dialog
// scrolls inside the Flexible body region (`_modal.scss` `.cds--modal-content`
// `overflow-y: auto`) while the header and footer stay pinned.
//
// Component gap (upstream `_modal.scss` "Modal overflow"): Carbon fades the
// bottom of scrollable content via the `.cds--modal-scroll-content`
// mask-image overflow indicator; Carbide renders no such indicator yet.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/overlay_entries.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        managedOverlayEntry(builder: (BuildContext context) => child),
      ],
    ),
  ),
);

/// A modal whose body (40 lines) is taller than the 90%-of-viewport dialog.
Widget _tallModal() => _host(
  CarbonModal(
    open: true,
    title: 'Terms',
    primaryButton: const CarbonModalAction(label: 'Accept'),
    secondaryButton: const CarbonModalAction(label: 'Decline'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[for (int i = 0; i < 40; i++) Text('Line $i')],
    ),
  ),
);

void main() {
  group('body scrolling', () {
    testWidgets('a tall body scrolls while the header and footer stay '
        'pinned', (WidgetTester tester) async {
      await tester.pumpWidget(_tallModal());
      await tester.pumpAndSettle();

      // The dialog is capped, so the body region hosts the only scrollable.
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      final Offset title = tester.getTopLeft(find.text('Terms'));
      final Offset accept = tester.getTopLeft(find.text('Accept'));
      final Offset decline = tester.getTopLeft(find.text('Decline'));
      final Offset line0 = tester.getTopLeft(find.text('Line 0'));

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      // Header and footer never moved; the body content did.
      expect(tester.getTopLeft(find.text('Terms')), title);
      expect(tester.getTopLeft(find.text('Accept')), accept);
      expect(tester.getTopLeft(find.text('Decline')), decline);
      expect(tester.getTopLeft(find.text('Line 0')).dy, lessThan(line0.dy));
    });

    testWidgets('content below the fold is clipped until scrolled into '
        'view', (WidgetTester tester) async {
      await tester.pumpWidget(_tallModal());
      await tester.pumpAndSettle();

      // The last line is laid out but clipped below the body viewport.
      expect(find.text('Line 39'), findsOneWidget);
      expect(find.text('Line 39').hitTestable(), findsNothing);

      final Offset accept = tester.getTopLeft(find.text('Accept'));
      await tester.scrollUntilVisible(find.text('Line 39'), 80);
      await tester.pumpAndSettle();

      expect(find.text('Line 39').hitTestable(), findsOneWidget);
      // Scrolling to the end never displaced the pinned footer.
      expect(tester.getTopLeft(find.text('Accept')), accept);
    });

    testWidgets('scrolled-away body content cannot be hit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_tallModal());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Line 39'), 80);
      await tester.pumpAndSettle();

      // The first line scrolled above the body viewport and is clipped out
      // of hit testing (it must not shadow the header controls above it).
      expect(find.text('Line 0'), findsOneWidget);
      expect(find.text('Line 0').hitTestable(), findsNothing);
    });
  });
}
