// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:ui' show Tristate;

import 'package:carbide/carbide.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  double? viewport,
  TextDirection direction = TextDirection.ltr,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(
      size: Size(viewport ?? width, 800),
      textScaler: TextScaler.linear(scale),
    ),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

Widget _variant(String variant, CarbonNotificationKind kind) =>
    switch (variant) {
      'inline' => CarbonInlineNotification(
        kind: kind,
        title: 'Notice',
        subtitle: 'Details',
      ),
      'toast' => CarbonToastNotification(
        kind: kind,
        title: 'Notice',
        subtitle: 'Details',
        caption: 'Just now',
      ),
      _ => CarbonActionableNotification(
        kind: kind,
        title: 'Notice',
        subtitle: 'Details',
        actionLabel: 'Retry',
        onAction: () {},
      ),
    };

void main() {
  for (final String variant in <String>['inline', 'toast', 'actionable']) {
    for (final CarbonNotificationKind kind in CarbonNotificationKind.values) {
      testWidgets('$variant $kind exposes its announcement role', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(_host(_variant(variant, kind)));
          await tester.pumpAndSettle();
          final SemanticsData data = tester
              .getSemantics(
                find.byType(switch (variant) {
                  'inline' => CarbonInlineNotification,
                  'toast' => CarbonToastNotification,
                  _ => CarbonActionableNotification,
                }),
              )
              .getSemanticsData();
          expect(
            data.role,
            !kIsWeb
                ? SemanticsRole.none
                : kind == CarbonNotificationKind.error
                ? SemanticsRole.alert
                : SemanticsRole.status,
          );
          expect(data.flagsCollection.isLiveRegion, !kIsWeb);
          expect(data.label, contains('Notice'));
          expect(data.label, contains('Details'));
          if (variant == 'toast') expect(data.label, contains('Just now'));
          if (variant == 'actionable') expect(data.label, contains('Retry'));
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  for (final CarbonNotificationKind kind in <CarbonNotificationKind>[
    CarbonNotificationKind.info,
    CarbonNotificationKind.warning,
  ]) {
    testWidgets('static callout stays outside live announcements $kind', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(CarbonCallout(kind: kind, title: 'Note', subtitle: 'Details')),
        );
        final SemanticsData data = tester
            .getSemantics(find.byType(CarbonCallout))
            .getSemanticsData();
        expect(data.role, SemanticsRole.none);
        expect(data.flagsCollection.isLiveRegion, isFalse);
      } finally {
        semantics.dispose();
      }
    });
  }

  for (final TextDirection direction in TextDirection.values) {
    for (final double scale in <double>[1, 2]) {
      testWidgets(
        'narrow action sits below the message $direction scale=$scale',
        (WidgetTester tester) async {
          int actions = 0, closes = 0;
          await tester.pumpWidget(
            _host(
              CarbonActionableNotification(
                kind: CarbonNotificationKind.info,
                title: 'A long notification title',
                subtitle: 'Supporting detail that wraps safely.',
                actionLabel: 'Retry operation',
                onAction: () => actions++,
                onClose: () => closes++,
              ),
              direction: direction,
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          final Rect title = tester.getRect(
            find.text('A long notification title'),
          );
          final Rect subtitle = tester.getRect(
            find.text('Supporting detail that wraps safely.'),
          );
          final Rect action = tester.getRect(find.text('Retry operation'));
          expect(action.top, greaterThanOrEqualTo(subtitle.bottom));
          expect(action.top, greaterThan(title.bottom));
          expect(
            tester
                .getSize(
                  find
                      .descendant(
                        of: find.byType(CarbonActionableNotification),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .width,
            lessThanOrEqualTo(288),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Retry operation'));
          await tester.pumpAndSettle();
          expect(actions, 1);
          await tester.tap(find.bySemanticsLabel('Close notification'));
          await tester.pumpAndSettle();
          expect(closes, 1);
        },
      );
    }
  }

  for (final double width in <double>[287, 320, 671, 672, 1056, 1584]) {
    testWidgets('bar width follows shared breakpoint boundaries $width', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width + 64, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          const CarbonInlineNotification(
            kind: CarbonNotificationKind.info,
            title: 'Notice',
          ),
          width: width,
        ),
      );
      final Finder box = find
          .descendant(
            of: find.byType(CarbonInlineNotification),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(
        tester.getSize(box).width,
        closeTo(
          width < 288
              ? width
              : width < CarbonBreakpoint.md.width
              ? 288
              : width < CarbonBreakpoint.lg.width
              ? 608
              : width < CarbonBreakpoint.max.width
              ? 736
              : 832,
          .01,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final double width in <double>[200, 320, 1583, 1584, 1800]) {
    testWidgets('toast respects container and max breakpoint $width', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width + 64, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          const CarbonToastNotification(
            kind: CarbonNotificationKind.info,
            title: 'Notice',
          ),
          width: width,
        ),
      );
      final Finder box = find
          .descendant(
            of: find.byType(CarbonToastNotification),
            matching: find.byType(DecoratedBox),
          )
          .first;
      expect(
        tester.getSize(box).width,
        closeTo(
          width < 288
              ? width
              : width < CarbonBreakpoint.max.width
              ? 288
              : 352,
          .01,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('viewport breakpoints remain independent of the content column', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonToastNotification(
          kind: CarbonNotificationKind.info,
          title: 'Notice',
        ),
        width: 400,
        viewport: CarbonBreakpoint.max.width,
      ),
    );
    expect(tester.getSize(find.byType(DecoratedBox).first).width, 352);
    await tester.pumpWidget(
      _host(
        const CarbonInlineNotification(
          kind: CarbonNotificationKind.info,
          title: 'Notice',
        ),
        width: 400,
        viewport: CarbonBreakpoint.md.width,
      ),
    );
    expect(tester.getSize(find.byType(DecoratedBox).first).width, 400);
  });

  testWidgets('narrow column wraps actions even on a wide viewport', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        CarbonActionableNotification(
          kind: CarbonNotificationKind.info,
          title: 'Notice',
          subtitle: 'Details',
          actionLabel: 'Retry',
          onAction: () {},
        ),
        width: 320,
        viewport: CarbonBreakpoint.max.width,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Retry')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Details')).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'live updates and severity changes preserve caller editor focus',
    (WidgetTester tester) async {
      final FocusNode focus = FocusNode();
      addTearDown(focus.dispose);
      late StateSetter update;
      bool error = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              update = setState;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CarbonTextInput(labelText: 'Editor', focusNode: focus),
                  CarbonActionableNotification(
                    kind: error
                        ? CarbonNotificationKind.error
                        : CarbonNotificationKind.info,
                    title: error ? 'Failed' : 'Ready',
                    actionLabel: 'Retry',
                    onAction: () {},
                  ),
                ],
              );
            },
          ),
        ),
      );
      focus.requestFocus();
      await tester.pumpAndSettle();
      update(() => error = true);
      await tester.pumpAndSettle();
      expect(focus.hasPrimaryFocus, isTrue);
      expect(find.text('Failed'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(() => focus.requestFocus(), returnsNormally);
    },
  );

  testWidgets('missing and blank optional fields do not pollute the message', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          const CarbonToastNotification(
            kind: CarbonNotificationKind.info,
            title: 'Notice',
            subtitle: ' ',
            caption: '',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(CarbonToastNotification)).label,
        'Notice',
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('disabled action remains named and cannot activate', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(
          const CarbonActionableNotification(
            kind: CarbonNotificationKind.info,
            title: 'Notice',
            actionLabel: 'Retry',
          ),
        ),
      );
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Retry'),
      );
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        tester.getSemantics(find.byType(CarbonActionableNotification)).label,
        contains('Retry'),
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('notification narrow action goldens', (
    WidgetTester tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'notification_actionable_narrow',
      containsText: true,
      size: const Size(320, 240),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => Center(
        child: CarbonActionableNotification(
          kind: CarbonNotificationKind.info,
          title: 'A notification',
          subtitle: 'Supporting detail for the optional action.',
          actionLabel: 'Retry',
          onAction: () {},
          onClose: () {},
        ),
      ),
    );
  });
  testWidgets('toast max breakpoint goldens', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'notification_toast_max',
      containsText: true,
      size: const Size(400, 220),
      mediaQuery: MediaQueryData(size: Size(CarbonBreakpoint.max.width, 900)),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => Center(
        child: CarbonToastNotification(
          kind: CarbonNotificationKind.success,
          title: 'Saved',
          subtitle: 'Your changes were saved.',
          caption: 'Just now',
          onClose: () {},
        ),
      ),
    );
  });
}
