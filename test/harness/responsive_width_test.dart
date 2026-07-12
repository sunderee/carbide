// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Narrow-width stress goldens (#236): one 320px golden per component with
// responsive behavior, pinning what wrap/collapse/squeeze actually looks
// like at the smallest Carbon breakpoint. Every other golden in the repo
// renders at a comfortable width; without these, responsive breakage is
// invisible by construction.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden.dart';

/// The `sm` breakpoint's full width.
const double _narrow = 320;

void main() {
  testWidgets('grid collapses to the sm column count at 320px', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'narrow_grid',
      containsText: true,
      size: const Size(_narrow, 160),
      builder: (BuildContext context) => CarbonGrid(
        children: <Widget>[
          for (int i = 0; i < 4; i++)
            CarbonColumn(
              span: 4,
              child: ColoredBox(
                color: CarbonTheme.of(context).layerAccent01,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Col ${i + 1}'),
                ),
              ),
            ),
        ],
      ),
    );
  });

  testWidgets('pagination squeezes at 320px', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'narrow_pagination',
      containsText: true,
      size: const Size(_narrow, 96),
      builder: (BuildContext context) => Align(
        alignment: AlignmentDirectional.topStart,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          // 720, not 700: Linux FreeType glyph advances run ~8px wider
          // than CoreText for this label set.
          child: SizedBox(
            width: 720,
            child: CarbonPagination(
              page: 2,
              pageSize: 10,
              totalItems: 103,
              onPageChanged: (int _) {},
              onPageSizeChanged: (int _) {},
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('data table toolbar at 320px', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'narrow_table_toolbar',
      containsText: true,
      size: const Size(_narrow, 120),
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CarbonTableToolbar(
            onSearchChanged: (String _) {},
            actions: <Widget>[CarbonButton(label: 'Add', onPressed: () {})],
          ),
        ],
      ),
    );
  });

  testWidgets('button set stacks at 320px', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'narrow_button_set',
      containsText: true,
      size: const Size(_narrow, 160),
      builder: (BuildContext context) => Align(
        alignment: AlignmentDirectional.topStart,
        child: CarbonButtonSet(
          stacked: true,
          children: <CarbonButton>[
            CarbonButton(
              label: 'Cancel',
              kind: CarbonButtonKind.secondary,
              onPressed: () {},
            ),
            CarbonButton(label: 'Save changes', onPressed: () {}),
          ],
        ),
      ),
    );
  });

  testWidgets('notification wraps its copy at 320px', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'narrow_notification',
      containsText: true,
      size: const Size(_narrow, 130),
      builder: (BuildContext context) => Align(
        alignment: AlignmentDirectional.topStart,
        child: CarbonInlineNotification(
          kind: CarbonNotificationKind.warning,
          title: 'Storage almost full',
          subtitle:
              'Your workspace is using 92% of its quota; older builds '
              'will be pruned automatically.',
          onClose: () {},
        ),
      ),
    );
  });

  testWidgets('page header wraps at 320px', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'narrow_page_header',
      containsText: true,
      size: const Size(_narrow, 170),
      builder: (BuildContext context) => Align(
        alignment: AlignmentDirectional.topStart,
        child: CarbonPageHeader(
          title: 'Quarterly financial report',
          breadcrumbs: <CarbonBreadcrumbItem>[
            CarbonBreadcrumbItem(label: 'Home', onPressed: () {}),
            const CarbonBreadcrumbItem(label: 'Reports', isCurrentPage: true),
          ],
          pageActions: CarbonButton(
            label: 'Edit',
            size: CarbonButtonSize.md,
            onPressed: () {},
          ),
        ),
      ),
    );
  });
}
