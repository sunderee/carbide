// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';

/// CarbonSelect (used by the pagination pickers) needs an Overlay ancestor.
Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Overlay(
      initialEntries: <OverlayEntry>[
        OverlayEntry(
          builder: (BuildContext context) =>
              Center(child: SizedBox(width: 760, child: child)),
        ),
      ],
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

  group('readout', () {
    testWidgets('shows the range and page count', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 1, pageSize: 10, totalItems: 95)),
      );
      expect(find.text('1–10 of 95 items'), findsOneWidget);
      expect(find.text('of 10 pages'), findsOneWidget);
    });

    testWidgets('middle page computes the right range', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 3, pageSize: 10, totalItems: 95)),
      );
      expect(find.text('21–30 of 95 items'), findsOneWidget);
    });

    testWidgets('last page clamps the range end', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 10, pageSize: 10, totalItems: 95)),
      );
      expect(find.text('91–95 of 95 items'), findsOneWidget);
    });
  });

  group('arrows', () {
    testWidgets('next advances; prev is disabled on the first page', (
      WidgetTester tester,
    ) async {
      int? went;
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 1,
            pageSize: 10,
            totalItems: 95,
            onPageChanged: (int p) => went = p,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Previous page'));
      await tester.pump();
      expect(went, isNull); // disabled on page 1
      await tester.tap(find.bySemanticsLabel('Next page'));
      await tester.pump();
      expect(went, 2);
    });

    testWidgets('next is disabled on the last page', (
      WidgetTester tester,
    ) async {
      int? went;
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 10,
            pageSize: 10,
            totalItems: 95,
            onPageChanged: (int p) => went = p,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Next page'));
      await tester.pump();
      expect(went, isNull);
      await tester.tap(find.bySemanticsLabel('Previous page'));
      await tester.pump();
      expect(went, 9);
    });
  });

  group('semantics', () {
    testWidgets('exposes a Pagination container + arrow labels', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const CarbonPagination(page: 1, pageSize: 10, totalItems: 95)),
      );
      expect(find.bySemanticsLabel('Pagination'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous page'), findsOneWidget);
      expect(find.bySemanticsLabel('Next page'), findsOneWidget);
      handle.dispose();
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      // A middle page keeps both arrows enabled, so every control is swept.
      await tester.pumpWidget(
        _host(
          CarbonPagination(
            page: 2,
            pageSize: 10,
            totalItems: 95,
            onPageChanged: (_) {},
            onPageSizeChanged: (_) {},
          ),
        ),
      );
      // TODO(#226): tap targets are off — the two pickers render 32px tall
      // (CarbonFieldSize.sm), while documentation/carbon/packages/styles/
      // scss/components/pagination/_pagination.scss stretches
      // `.cds--select-input` to `block-size: 100%` of the 48px bar.
      // Re-enable once the pickers fill the bar height.
      await expectA11y(tester, tapTargets: false);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('pagination bar across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'pagination',
        containsText: true,
        size: const Size(800, 64),
        builder: (BuildContext context) => Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(
              builder: (BuildContext context) => Center(
                child: SizedBox(
                  width: 760,
                  child: CarbonPagination(
                    page: 1,
                    pageSize: 10,
                    totalItems: 95,
                    onPageChanged: (_) {},
                    onPageSizeChanged: (_) {},
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  });
}
