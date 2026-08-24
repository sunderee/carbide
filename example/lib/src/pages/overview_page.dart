// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'dart:async';

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../gallery_controller.dart';

/// The Carbide source repository.
final Uri _repositoryUrl = Uri.parse('https://github.com/sunderee/carbide');

/// Opens the Carbide repository in the platform's browser.
Future<void> _openRepository() async {
  if (await canLaunchUrl(_repositoryUrl)) {
    await launchUrl(_repositoryUrl, mode: LaunchMode.externalApplication);
  }
}

/// The landing page: what Carbide is, the active theme, and quick links.
class OverviewPage extends StatelessWidget {
  /// Creates the overview page.
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final GalleryController controller = GalleryScope.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Carbide', style: CarbonTypeStyles.productiveHeading06),
          const SizedBox(height: CarbonSpacing.spacing03),
          Text(
            'An unofficial Flutter port of the IBM Carbon Design System, built '
            'strictly on Flutter’s base widgets — no Material, no '
            'Cupertino.',
            style: CarbonTypeStyles.body02.copyWith(color: theme.textSecondary),
          ),
          const SizedBox(height: CarbonSpacing.spacing07),
          _InfoTile(heading: 'Active theme', body: controller.theme.label),
          const SizedBox(height: CarbonSpacing.spacing05),
          const _InfoTile(
            heading: 'Browse',
            body:
                'Pick a component from the navigation to see it live, tweak '
                'its props, and copy the code.',
          ),
          const SizedBox(height: CarbonSpacing.spacing07),
          Wrap(
            spacing: CarbonSpacing.spacing05,
            runSpacing: CarbonSpacing.spacing05,
            children: <Widget>[
              CarbonButton(
                label: 'Source on GitHub',
                kind: CarbonButtonKind.tertiary,
                icon: CarbonIcons.logoGithub,
                onPressed: () => unawaited(_openRepository()),
              ),
              CarbonButton(
                label: 'Switch theme',
                kind: CarbonButtonKind.secondary,
                icon: CarbonIcons.colorPalette,
                onPressed: controller.cycleTheme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return CarbonTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(heading, style: CarbonTypeStyles.productiveHeading03),
          const SizedBox(height: CarbonSpacing.spacing03),
          Text(
            body,
            style: CarbonTypeStyles.body01.copyWith(color: theme.textSecondary),
          ),
        ],
      ),
    );
  }
}
