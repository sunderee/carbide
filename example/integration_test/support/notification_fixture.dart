// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

void main() {
  final Map<String, String> parameters = Uri.base.queryParameters;
  final CarbonThemeData theme = switch (parameters['theme']) {
    'g10' => CarbonThemeData.gray10,
    'g90' => CarbonThemeData.gray90,
    'g100' => CarbonThemeData.gray100,
    _ => CarbonThemeData.white,
  };
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    notificationHost(
      const NotificationFixture(),
      theme: theme,
      direction: parameters['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      scale: double.tryParse(parameters['scale'] ?? '') ?? 1,
    ),
  );
}

/// Real app semantics and overlay host; an optional viewport pins breakpoints.
Widget notificationHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
  double? viewport,
}) {
  final CarbonThemeData data = theme ?? CarbonThemeData.white;
  return WidgetsApp(
    color: data.background,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext context, _, _) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: viewport == null ? null : Size(viewport, 900),
            textScaler: TextScaler.linear(scale),
          ),
          child: CarbonTheme(
            data: data,
            child: ColoredBox(
              color: data.background,
              child: DefaultTextStyle(
                style: CarbonTypeStyles.body01.copyWith(
                  color: data.textPrimary,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Live updates, optional actions and focus retention observed independently.
class NotificationFixture extends StatefulWidget {
  /// Creates the notification contract fixture.
  const NotificationFixture({super.key});

  @override
  State<NotificationFixture> createState() => NotificationFixtureState();
}

/// Mutable messages and observed actions for permanent contracts.
class NotificationFixtureState extends State<NotificationFixture> {
  /// Caller-owned editor focus used to verify that updates do not steal it.
  final FocusNode editorFocus = FocusNode();

  /// Successfully invoked notification actions.
  int actions = 0;

  /// Successfully invoked close callbacks.
  int closes = 0;

  /// The revision announced by live notifications.
  int revision = 0;

  /// Changes all live messages without requesting focus.
  void update() => setState(() => revision++);

  @override
  void dispose() {
    editorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(headingLevel: 1, child: const Text('Notification policy')),
        const SizedBox(height: 16),
        CarbonTextInput(labelText: 'Keep editing', focusNode: editorFocus),
        const SizedBox(height: 16),
        Text('Actions: $actions; closes: $closes; revision: $revision'),
        const SizedBox(height: 16),
        CarbonInlineNotification(
          kind: CarbonNotificationKind.info,
          title: 'Inline $revision',
          subtitle: 'Additional information.',
        ),
        const SizedBox(height: 16),
        CarbonToastNotification(
          kind: CarbonNotificationKind.error,
          title: 'Toast $revision',
          subtitle: 'The operation failed.',
          caption: 'Just now',
        ),
        const SizedBox(height: 16),
        CarbonActionableNotification(
          kind: CarbonNotificationKind.warning,
          title: 'Actionable $revision',
          subtitle: 'Supporting detail for the optional action.',
          actionLabel: 'Retry operation',
          onAction: () => setState(() => actions++),
          onClose: () => setState(() => closes++),
        ),
        const SizedBox(height: 16),
        CarbonCallout(
          title: 'Static note',
          subtitle: 'Persistent page content.',
          actionLabel: 'Review note',
          onAction: () => setState(() => actions++),
        ),
        const SizedBox(height: 16),
        CarbonButton(label: 'Update messages', onPressed: update),
        const SizedBox(height: 16),
        CarbonButton(
          label: 'Update after editing',
          onPressed: () async {
            await Future<void>.delayed(const Duration(seconds: 1));
            if (mounted) update();
          },
        ),
      ],
    ),
  );
}
