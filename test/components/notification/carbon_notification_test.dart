// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/a11y.dart';
import '../../support/golden.dart';
import '../../support/legibility.dart';

Widget _host(Widget child, {double width = 480}) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(
      child: SizedBox(width: width, child: child),
    ),
  ),
);

/// The notification surface decoration (the first DecoratedBox in the bar).
BoxDecoration _surface(WidgetTester tester, Type of) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(of),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

/// The status icon widget (rendered at 20px per the spec).
CarbonIcon _statusIcon(WidgetTester tester) => tester.widget<CarbonIcon>(
  find.byWidgetPredicate(
    (Widget w) =>
        w is CarbonIcon && w.size == 20 && !w.icon.name.endsWith('inner-path'),
  ),
);

/// The black inner-path overlay of the warning icons, if rendered.
Finder _innerPath() => find.byWidgetPredicate(
  (Widget w) => w is CarbonIcon && w.icon.name.endsWith('inner-path'),
);

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('kind mapping', () {
    final Map<CarbonNotificationKind, (CarbonIconData, Color, Color, Color)>
    expected = <CarbonNotificationKind, (CarbonIconData, Color, Color, Color)>{
      CarbonNotificationKind.error: (
        CarbonIcons.errorFilled,
        theme.supportErrorInverse,
        theme.supportError,
        theme.notificationBackgroundError,
      ),
      CarbonNotificationKind.success: (
        CarbonIcons.checkmarkFilled,
        theme.supportSuccessInverse,
        theme.supportSuccess,
        theme.notificationBackgroundSuccess,
      ),
      CarbonNotificationKind.info: (
        CarbonIcons.informationFilled,
        theme.supportInfoInverse,
        theme.supportInfo,
        theme.notificationBackgroundInfo,
      ),
      CarbonNotificationKind.infoSquare: (
        CarbonIcons.informationSquareFilled,
        theme.supportInfoInverse,
        theme.supportInfo,
        theme.notificationBackgroundInfo,
      ),
      CarbonNotificationKind.warning: (
        CarbonIcons.warningFilled,
        theme.supportWarningInverse,
        theme.supportWarning,
        theme.notificationBackgroundWarning,
      ),
      CarbonNotificationKind.warningAlt: (
        CarbonIcons.warningAltFilled,
        theme.supportWarningInverse,
        theme.supportWarning,
        theme.notificationBackgroundWarning,
      ),
    };

    for (final MapEntry<
          CarbonNotificationKind,
          (CarbonIconData, Color, Color, Color)
        >
        entry
        in expected.entries) {
      testWidgets('${entry.key.name}: icon, accents, and tint', (
        WidgetTester tester,
      ) async {
        final (CarbonIconData icon, Color inverse, Color plain, Color tint) =
            entry.value;

        await tester.pumpWidget(
          _host(CarbonInlineNotification(kind: entry.key, title: 'Note')),
        );
        expect(_statusIcon(tester).icon, icon);
        expect(_statusIcon(tester).color, inverse);
        final BoxDecoration high = _surface(tester, CarbonInlineNotification);
        expect(high.color, theme.backgroundInverse);
        final BorderDirectional highBorder = high.border! as BorderDirectional;
        expect(highBorder.start.width, 3);
        expect(highBorder.start.color, inverse);
        // High contrast has no surrounding 1px border.
        expect(highBorder.top, BorderSide.none);
        expect(highBorder.end, BorderSide.none);
        expect(highBorder.bottom, BorderSide.none);

        await tester.pumpWidget(
          _host(
            CarbonInlineNotification(
              kind: entry.key,
              title: 'Note',
              lowContrast: true,
            ),
          ),
        );
        expect(_statusIcon(tester).color, plain);
        expect(_surface(tester, CarbonInlineNotification).color, tint);
      });
    }

    testWidgets('low contrast draws the 40%-opacity border overlay', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.error,
            title: 'Note',
            lowContrast: true,
          ),
        ),
      );
      final Iterable<DecoratedBox> boxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(CarbonInlineNotification),
          matching: find.byType(DecoratedBox),
        ),
      );
      final BoxDecoration overlay =
          boxes.elementAt(1).decoration as BoxDecoration;
      final BorderDirectional border = overlay.border! as BorderDirectional;
      final Color faded = theme.supportError.withValues(alpha: 0.4);
      expect(border.top.color.toARGB32(), faded.toARGB32());
      expect(border.end.color.toARGB32(), faded.toARGB32());
      expect(border.bottom.color.toARGB32(), faded.toARGB32());
      expect(border.top.width, 1);
      expect(border.start, BorderSide.none);
    });

    testWidgets('warning kinds paint the inner path black', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.warning,
            title: 'Note',
          ),
        ),
      );
      expect(_innerPath(), findsOneWidget);
      expect(
        tester.widget<CarbonIcon>(_innerPath()).color,
        CarbonColors.black100,
      );

      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.warningAlt,
            title: 'Note',
          ),
        ),
      );
      expect(_innerPath(), findsOneWidget);

      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.info,
            title: 'Note',
          ),
        ),
      );
      expect(_innerPath(), findsNothing);
    });
  });

  group('InlineNotification', () {
    testWidgets('spec geometry: 48px min height, insets, title gap', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.error,
            title: 'Error',
            subtitle: 'Something failed',
          ),
        ),
      );
      final Finder bar = find
          .descendant(
            of: find.byType(CarbonInlineNotification),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(tester.getSize(bar).height, 48);

      // Icon: 16px from the start edge (3px bar + 13px details margin),
      // 14px from the top.
      final Offset barTopLeft = tester.getTopLeft(bar);
      final Offset iconTopLeft = tester.getTopLeft(
        find.byWidgetPredicate((Widget w) => w is CarbonIcon && w.size == 20),
      );
      expect(iconTopLeft.dx - barTopLeft.dx, 16);
      expect(iconTopLeft.dy - barTopLeft.dy, 14);

      // Title: heading-compact-01, 4px gap to the subtitle, 16px after the
      // icon.
      final Text title = tester.widget<Text>(find.text('Error'));
      expect(title.style!.fontSize, CarbonTypeStyles.headingCompact01.fontSize);
      expect(
        title.style!.fontWeight,
        CarbonTypeStyles.headingCompact01.fontWeight,
      );
      expect(
        tester.getTopLeft(find.text('Error')).dx,
        iconTopLeft.dx + 20 + 16,
      );
      expect(
        tester.getTopLeft(find.text('Something failed')).dx -
            tester.getTopRight(find.text('Error')).dx,
        4,
      );
      expectTextNotClipped(tester, find.text('Error'));
      expectTextNotClipped(tester, find.text('Something failed'));
    });

    testWidgets('max width steps 608/736 with the available width', (
      WidgetTester tester,
    ) async {
      final Finder surface = find
          .descendant(
            of: find.byType(CarbonInlineNotification),
            matching: find.byType(DecoratedBox),
          )
          .first;
      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.info,
            title: 'Note',
          ),
          width: 700,
        ),
      );
      expect(tester.getSize(surface).width, 608);

      await tester.binding.setSurfaceSize(const Size(1200, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.info,
            title: 'Note',
          ),
          width: 1100,
        ),
      );
      expect(tester.getSize(surface).width, 736);
    });

    testWidgets('close is a focusable button; Enter activates it', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int closes = 0;
      await tester.pumpWidget(
        _host(
          CarbonInlineNotification(
            kind: CarbonNotificationKind.error,
            title: 'Error',
            onClose: () => closes++,
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Close notification'));
      expect(closes, 1);

      final FocusNode node = Focus.of(
        tester.element(
          find.byWidgetPredicate(
            (Widget w) => w is CarbonIcon && w.icon == CarbonIcons.close,
          ),
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(closes, 2);
      handle.dispose();
    });

    testWidgets('announces as a live region with the icon description', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.warningAlt,
            title: 'Careful',
            subtitle: 'Check this',
          ),
        ),
      );
      final SemanticsNode bar = tester.getSemantics(
        find.bySemanticsLabel('Careful. Check this'),
      );
      expect(bar.flagsCollection.isLiveRegion, isTrue);
      expect(find.bySemanticsLabel('warning-alt icon'), findsOneWidget);
      handle.dispose();
    });
  });

  group('ToastNotification', () {
    testWidgets('288px wide with shadow and stacked spec spacing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonToastNotification(
            kind: CarbonNotificationKind.info,
            title: 'Heads up',
            subtitle: 'A new version is available',
            caption: '00:00:00',
          ),
        ),
      );
      final Finder toast = find
          .descendant(
            of: find.byType(CarbonToastNotification),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(tester.getSize(toast).width, 288);

      final BoxDecoration surface = _surface(tester, CarbonToastNotification);
      expect(surface.boxShadow, isNotNull);
      expect(surface.boxShadow!.single.offset, const Offset(0, 2));
      expect(surface.boxShadow!.single.blurRadius, 6);

      final Offset top = tester.getTopLeft(toast);
      final Offset icon = tester.getTopLeft(
        find.byWidgetPredicate((Widget w) => w is CarbonIcon && w.size == 20),
      );
      // 3px bar + 13px container padding.
      expect(icon.dx - top.dx, 16);
      expect(icon.dy - top.dy, 16);

      // Title 16px from the top; subtitle flush under it; caption 24px
      // below the subtitle (16px subtitle margin + 8px caption padding).
      expect(tester.getTopLeft(find.text('Heads up')).dy - top.dy, 16);
      expect(
        tester.getTopLeft(find.text('A new version is available')).dy,
        tester.getBottomLeft(find.text('Heads up')).dy,
      );
      expect(
        tester.getTopLeft(find.text('00:00:00')).dy -
            tester.getBottomLeft(find.text('A new version is available')).dy,
        24,
      );
      expectTextNotClipped(tester, find.text('Heads up'));
    });
  });

  group('ActionableNotification', () {
    testWidgets('ghost action button fires and hovers', (
      WidgetTester tester,
    ) async {
      int acted = 0;
      await tester.pumpWidget(
        _host(
          CarbonActionableNotification(
            kind: CarbonNotificationKind.warning,
            title: 'Careful',
            actionLabel: 'Undo',
            onAction: () => acted++,
            onClose: () {},
          ),
        ),
      );
      await tester.tap(find.text('Undo'));
      expect(acted, 1);

      // The action is a 32px-tall ghost button in link-inverse text.
      final Finder button = find.ancestor(
        of: find.text('Undo'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(button.first).height, 32);
      expect(
        tester.widget<Text>(find.text('Undo')).style!.color,
        theme.linkInverse,
      );

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Undo')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Container>(button.first).color,
        theme.backgroundInverseHover,
      );
    });
  });

  group('Callout', () {
    testWidgets('defaults to info, has no close, is not a live region', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonCallout(
            title: 'Note',
            subtitle: 'Some supporting detail',
          ),
        ),
      );
      expect(_statusIcon(tester).icon, CarbonIcons.informationFilled);
      expect(find.bySemanticsLabel('Close notification'), findsNothing);
      expect(find.bySemanticsLabel('info icon'), findsOneWidget);

      // Static page content: nothing in the callout is a live region.
      final SemanticsNode root = tester.getSemantics(
        find.byType(CarbonCallout),
      );
      bool liveRegion = root.flagsCollection.isLiveRegion;
      root.visitChildren((SemanticsNode node) {
        liveRegion = liveRegion || node.flagsCollection.isLiveRegion;
        return true;
      });
      expect(liveRegion, isFalse);
      handle.dispose();
    });

    testWidgets('supports only the info and warning kinds', (
      WidgetTester tester,
    ) async {
      expect(
        () => CarbonCallout(kind: CarbonNotificationKind.error),
        throwsAssertionError,
      );
      expect(
        () => CarbonCallout(kind: CarbonNotificationKind.success),
        throwsAssertionError,
      );
      expect(
        () => CarbonCallout(kind: CarbonNotificationKind.warning),
        returnsNormally,
      );
    });

    testWidgets('action button fires; hover uses the action-hover token', (
      WidgetTester tester,
    ) async {
      int acted = 0;
      await tester.pumpWidget(
        _host(
          CarbonCallout(
            kind: CarbonNotificationKind.warning,
            title: 'Careful',
            subtitle: 'Check the configuration',
            lowContrast: true,
            actionLabel: 'Review',
            onAction: () => acted++,
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      expect(acted, 1);

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Review')));
      await tester.pumpAndSettle();
      final Finder button = find.ancestor(
        of: find.text('Review'),
        matching: find.byType(Container),
      );
      expect(
        tester.widget<Container>(button.first).color,
        theme.notificationActionHover,
      );
    });

    testWidgets('title is optional', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(const CarbonCallout(subtitle: 'Just a subtitle')),
      );
      expect(find.text('Just a subtitle'), findsOneWidget);
    });
  });

  group('a11y (#226)', () {
    testWidgets('meets tap-target and label guidelines', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          CarbonActionableNotification(
            kind: CarbonNotificationKind.success,
            title: 'Saved',
            subtitle: 'Draft stored.',
            actionLabel: 'Undo',
            onAction: () {},
            onClose: () {},
          ),
        ),
      );
      // Tap targets are off for the actionable variant: the ghost action
      // button is 32px by upstream default (`block-size:
      // convert.to-rem(32px)` in documentation/carbon/packages/styles/
      // scss/components/notification/_actionable-notification.scss), so
      // 48dp is unattainable. Labels stay gated.
      await expectA11y(tester, tapTargets: false);

      // The inline variant's only tap target is the 48px close control,
      // so it takes the full gate.
      await tester.pumpWidget(
        _host(
          CarbonInlineNotification(
            kind: CarbonNotificationKind.success,
            title: 'Saved',
            subtitle: 'Draft stored.',
            onClose: () {},
          ),
        ),
      );
      await expectA11y(tester);
      handle.dispose();
    });
  });

  group('goldens', () {
    testWidgets('notification kinds across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'notifications',
        containsText: true,
        size: const Size(480, 340),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonInlineNotification(
                  kind: CarbonNotificationKind.error,
                  title: 'Error',
                  subtitle: 'A problem occurred.',
                  onClose: () {},
                ),
                const SizedBox(height: 12),
                CarbonInlineNotification(
                  kind: CarbonNotificationKind.success,
                  title: 'Success',
                  subtitle: 'Saved.',
                  lowContrast: true,
                  onClose: () {},
                ),
                const SizedBox(height: 12),
                CarbonActionableNotification(
                  kind: CarbonNotificationKind.warning,
                  title: 'Warning',
                  subtitle: 'Unsaved changes.',
                  actionLabel: 'Save',
                  onAction: () {},
                  onClose: () {},
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('new kinds and inner paths across themes', (
      WidgetTester tester,
    ) async {
      await expectThemeGoldens(
        tester,
        name: 'notification_kinds',
        containsText: true,
        size: const Size(480, 300),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const CarbonInlineNotification(
                  kind: CarbonNotificationKind.warning,
                  title: 'Warning',
                  subtitle: 'Black inner path.',
                ),
                const SizedBox(height: 12),
                const CarbonInlineNotification(
                  kind: CarbonNotificationKind.warningAlt,
                  title: 'Warning alt',
                  subtitle: 'Triangular icon.',
                  lowContrast: true,
                ),
                const SizedBox(height: 12),
                const CarbonInlineNotification(
                  kind: CarbonNotificationKind.infoSquare,
                  title: 'Info square',
                  subtitle: 'Squared icon.',
                  lowContrast: true,
                ),
              ],
            ),
          ),
        ),
      );
    });

    testWidgets('toast across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'notification_toast',
        containsText: true,
        size: const Size(360, 300),
        builder: (BuildContext context) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CarbonToastNotification(
                kind: CarbonNotificationKind.error,
                title: 'Error',
                subtitle: 'Deployment failed.',
                caption: '12:03:44',
                onClose: () {},
              ),
              const SizedBox(height: 12),
              const CarbonToastNotification(
                kind: CarbonNotificationKind.success,
                title: 'Success',
                subtitle: 'Deployment complete.',
                lowContrast: true,
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('callout across themes', (WidgetTester tester) async {
      await expectThemeGoldens(
        tester,
        name: 'callout',
        containsText: true,
        size: const Size(480, 260),
        builder: (BuildContext context) => Center(
          child: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CarbonCallout(
                  title: 'Note',
                  subtitle: 'This page has unsaved drafts.',
                  actionLabel: 'Review',
                  onAction: () {},
                ),
                const SizedBox(height: 12),
                const CarbonCallout(
                  kind: CarbonNotificationKind.warning,
                  title: 'Warning',
                  subtitle: 'Scheduled maintenance at midnight.',
                  lowContrast: true,
                ),
              ],
            ),
          ),
        ),
      );
    });
  });
}
