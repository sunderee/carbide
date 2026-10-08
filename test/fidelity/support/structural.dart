// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// The actual control bounds, excluding the Storybook background frame.
Size fidelityControlSize(
  WidgetTester tester,
  String component,
  Widget fixture,
) {
  final Finder target = component == 'modal'
      ? find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.scopesRoute == true,
        )
      : component == 'tooltip'
      ? find.byType(FidelityTooltipTrigger)
      : find.byWidget(fixture);
  return tester.getSize(target);
}

/// Locks the measured control dimensions and important semantic token fills.
Future<void> checkFidelityStructure(
  WidgetTester tester,
  String component,
  CarbonThemeData theme,
  Size actualSize,
  ui.Image image,
  Map<String, dynamic> contract,
) async {
  final List<dynamic> expectedSize = contract['size'] as List<dynamic>;
  final double tolerance = (contract['sizeTolerance'] as num).toDouble();
  expect(
    actualSize.width,
    closeTo((expectedSize[0] as num).toDouble(), tolerance),
    reason: '$component structural width',
  );
  expect(
    actualSize.height,
    closeTo((expectedSize[1] as num).toDouble(), tolerance),
    reason: '$component structural height',
  );
  final (Offset, Color)? colour = switch (component) {
    'button' => (const Offset(5, 24), theme.buttonPrimary),
    'notification' => (const Offset(5, 5), theme.backgroundInverse),
    'text-input' ||
    'dropdown' ||
    'multiselect' ||
    'number-input' ||
    'select' ||
    'combo-box' ||
    'date-picker' => (const Offset(5, 40), theme.field01),
    'search' => (const Offset(5, 10), theme.field01),
    'content-switcher' => (const Offset(5, 20), theme.layerSelectedInverse),
    'tile' || 'code-snippet' => (const Offset(5, 5), theme.layer01),
    'tooltip' => (Offset(image.width / 4, image.height / 4), theme.iconPrimary),
    'overflow-menu' => (const Offset(20, 20), theme.iconPrimary),
    'progress-bar' => (const Offset(5, 30), theme.interactive),
    _ => null,
  };
  if (colour != null) {
    final ByteData pixels = (await tester.runAsync<ByteData?>(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final int x = (colour.$1.dx * 2).round(), y = (colour.$1.dy * 2).round();
    final int index = (y * image.width + x) * 4;
    final int rgb =
        (pixels.getUint8(index) << 16) |
        (pixels.getUint8(index + 1) << 8) |
        pixels.getUint8(index + 2);
    expect(
      rgb,
      colour.$2.toARGB32() & 0xffffff,
      reason: '$component structural token colour at ${colour.$1}',
    );
  }
  switch (component) {
    case 'button':
      final CarbonButton button = tester.widget(find.byType(CarbonButton));
      expect(button.kind, CarbonButtonKind.primary);
      expect(button.size, CarbonButtonSize.lg);
      expect(button.onPressed, isNotNull);
    case 'checkbox':
      final List<CarbonCheckbox> rows = tester
          .widgetList<CarbonCheckbox>(find.byType(CarbonCheckbox))
          .toList();
      expect(rows.length, 2);
      expect(rows.every((row) => !row.value), isTrue);
    case 'toggle':
      expect(
        tester.widget<CarbonToggle>(find.byType(CarbonToggle)).toggled,
        isTrue,
      );
    case 'notification':
      final CarbonInlineNotification bar = tester.widget(
        find.byType(CarbonInlineNotification),
      );
      expect(bar.kind, CarbonNotificationKind.error);
      expect(bar.onClose, isNotNull);
    case 'content-switcher':
      final CarbonContentSwitcher control = tester.widget(
        find.byType(CarbonContentSwitcher),
      );
      expect(control.selectedIndex, 0);
      expect(control.switches.length, 3);
      expect(control.switches.every((item) => !item.disabled), isTrue);
    case 'modal':
      final CarbonModal modal = tester.widget(find.byType(CarbonModal));
      expect(modal.open, isTrue);
      expect(modal.danger, isFalse);
      expect(modal.size, CarbonModalSize.lg);
      expect(find.text('Domain name'), findsOneWidget);
      expect(find.text('Terms of Agreement'), findsOneWidget);
    case 'tooltip':
      expect(
        tester.widget<CarbonTooltip>(find.byType(CarbonTooltip)).defaultOpen,
        isFalse,
      );
    case 'progress-indicator':
      final CarbonProgressIndicator steps = tester.widget(
        find.byType(CarbonProgressIndicator),
      );
      expect(steps.currentIndex, 1);
      expect(steps.steps[3].invalid, isTrue);
    case 'tree-view':
      expect(
        tester
            .widget<CarbonTreeView>(find.byType(CarbonTreeView))
            .nodes
            .last
            .disabled,
        isTrue,
      );
    case 'radio-button':
      expect(
        tester
            .widget<CarbonRadioButtonGroup<int>>(
              find.byType(CarbonRadioButtonGroup<int>),
            )
            .value,
        1,
      );
    default:
      break;
  }
}
