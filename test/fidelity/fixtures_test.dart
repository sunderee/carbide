// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overlay_entries.dart';
import 'support/fixtures.dart';

Future<void> _story(
  WidgetTester tester,
  String slug,
  void Function() verify, {
  double width = 1280,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 720));
  try {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: Size(width, 720)),
          child: CarbonTheme(
            data: CarbonThemeData.white,
            child: DefaultTextStyle(
              style: CarbonTypeStyles.body02,
              child: TapRegionSurface(
                child: Overlay(
                  initialEntries: <OverlayEntry>[
                    managedOverlayEntry(
                      builder: (_) => slug == 'modal'
                          ? fidelityBuilders[slug]!()
                          : Align(
                              alignment: Alignment.topLeft,
                              child: fidelityBuilders[slug]!(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    verify();
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.binding.setSurfaceSize(null);
  }
}

void main() {
  test(
    'all 33 curated components have one fixture',
    () => expect(fidelityBuilders.length, 33),
  );
  testWidgets('tree fixture includes its visible label', (tester) async {
    await _story(tester, 'tree-view', () {
      expect(find.text('Tree View'), findsOneWidget);
    });
  });
  testWidgets('tile fixture fills its story root width', (tester) async {
    await _story(tester, 'tile', () {
      expect(tester.getSize(find.byType(CarbonTile)).width, 1196);
    });
  });
  testWidgets('overflow fixture uses the 40px default trigger', (tester) async {
    await _story(tester, 'overflow-menu', () {
      final CarbonOverflowMenu menu = tester.widget(
        find.byType(CarbonOverflowMenu),
      );
      expect(menu.buttonSize, CarbonButtonSize.md);
    });
  });
  testWidgets('horizontal progress fixture uses intrinsic content height', (
    tester,
  ) async {
    // Web widget tests use Ahem in place of Plex (#271). Isolate the
    // intrinsic-height contract from the constrained-width gap tracked in #402.
    await _story(tester, 'progress-indicator', () {
      expect(
        tester.getSize(find.byType(CarbonProgressIndicator)).height,
        lessThan(100),
      );
    }, width: 2400);
  });
  testWidgets('notification fixture retains the default dismissal control', (
    tester,
  ) async {
    await _story(tester, 'notification', () {
      final CarbonInlineNotification bar = tester.widget(
        find.byType(CarbonInlineNotification),
      );
      expect(bar.onClose, isNotNull);
      expect(find.text('Notification title'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Close notification',
        ),
        findsOneWidget,
      );
    });
  });
  testWidgets('Modal story uses Modal and its complete default form', (
    tester,
  ) async {
    await _story(tester, 'modal', () {
      expect(find.byType(CarbonModal), findsOneWidget);
      expect(find.byType(CarbonDialog), findsNothing);
      final CarbonModal modal = tester.widget(find.byType(CarbonModal));
      expect(modal.open, isTrue);
      expect(modal.size, CarbonModalSize.lg);
      expect(modal.title, 'Add a custom domain');
      for (final String label in <String>[
        'Domain name',
        'Region',
        'Permissions (Example of Floating UI)',
        'TLS (Example of Floating UI)',
        'Mapping domain',
        'Terms of Agreement',
        'Cancel',
        'Add',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });
  testWidgets('Tooltip story uses the Options icon trigger', (tester) async {
    await _story(tester, 'tooltip', () {
      final CarbonTooltip tooltip = tester.widget(find.byType(CarbonTooltip));
      expect(tooltip.label, 'Options');
      expect(find.text('URL'), findsNothing);
      final CarbonIcon icon = tester.widget(find.byType(CarbonIcon));
      expect(icon.icon, CarbonIcons.overflowMenuVertical);
      expect(icon.size, 16);
      expect(find.byType(FidelityTooltipTrigger), findsOneWidget);
    });
  });
  testWidgets('read-only Tag story preserves all twelve variants', (
    tester,
  ) async {
    await _story(tester, 'tag', () {
      final List<CarbonTag> tags = tester
          .widgetList<CarbonTag>(find.byType(CarbonTag))
          .toList();
      expect(tags.length, 12);
      expect(tags.first.type, CarbonTagType.red);
      expect(tags.first.label, 'Tag content with a long text description');
      expect(tags.last.type, CarbonTagType.outline);
    });
  });
  testWidgets('Checkbox default is a group with two unchecked rows', (
    tester,
  ) async {
    await _story(tester, 'checkbox', () {
      final CarbonCheckboxGroup group = tester.widget(
        find.byType(CarbonCheckboxGroup),
      );
      expect(group.legend, 'Group label');
      expect(group.helperText, 'Helper text goes here');
      final List<CarbonCheckbox> rows = tester
          .widgetList<CarbonCheckbox>(find.byType(CarbonCheckbox))
          .toList();
      expect(rows.length, 2);
      expect(rows.every((row) => !row.value), isTrue);
    });
  });
  testWidgets('Tree default retains nested expansion and disabled Models', (
    tester,
  ) async {
    await _story(tester, 'tree-view', () {
      final CarbonTreeView tree = tester.widget(find.byType(CarbonTreeView));
      expect(tree.label, 'Tree View');
      expect(
        tree.initiallyExpandedIds,
        containsAll(<String>['5', '5-3', '5-5', '7', '8']),
      );
      expect(tree.nodes.last.disabled, isTrue);
      for (final String text in <String>[
        'Cloud computing',
        'Containers',
        'Resources',
        'Models',
        'Audit',
        'Report samples',
        'Sales performance',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
    });
  });
  testWidgets('basic DataTable story retains five columns and seven rows', (
    tester,
  ) async {
    await _story(tester, 'data-table', () {
      final CarbonDataTable table = tester.widget(find.byType(CarbonDataTable));
      expect(table.columns.length, 5);
      expect(table.rows.length, 7);
      expect(find.text('Load Balancer 7'), findsOneWidget);
      expect(find.text('Example'), findsOneWidget);
    });
  });
  testWidgets('Select story starts at the region placeholder', (tester) async {
    await _story(tester, 'select', () {
      final CarbonSelect<String> select = tester.widget(
        find.byType(CarbonSelect<String>),
      );
      expect(select.labelText, 'Deployment region');
      expect(select.value, '');
      expect(select.items.length, 5);
      expect(find.text('Choose a region'), findsOneWidget);
    });
  });
  testWidgets('Radio default is horizontal with the second option selected', (
    tester,
  ) async {
    await _story(tester, 'radio-button', () {
      final CarbonRadioButtonGroup<int> group = tester.widget(
        find.byType(CarbonRadioButtonGroup<int>),
      );
      expect(group.orientation, Axis.horizontal);
      expect(group.value, 1);
      expect(group.legend, 'Radio Button group');
      expect(group.helperText, 'Helper text');
    });
  });
  test('ProgressIndicator fixture retains optional and invalid labels', () {
    final CarbonProgressIndicator progress =
        (fidelityBuilders['progress-indicator']!() as IntrinsicHeight).child
            as CarbonProgressIndicator;
    expect(progress.currentIndex, 1);
    expect(progress.steps[3].invalid, isTrue);
    expect(progress.steps[0].secondaryLabel, 'Optional label');
    expect(progress.steps[1].label, 'Second step with tooltip');
  });
  testWidgets('Tile default includes its second-line link', (tester) async {
    await _story(tester, 'tile', () {
      expect(find.byType(CarbonLink), findsOneWidget);
      expect(find.text('Default tile'), findsOneWidget);
    });
  });
}
