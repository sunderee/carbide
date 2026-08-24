// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:carbide_gallery/src/gallery_controller.dart';
import 'package:carbide_gallery/src/pages/overview_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records the URLs a tap asks the platform to open.
class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launched = <String>[];

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

Widget _host(Widget child, GalleryController controller) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: const MediaQueryData(),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: GalleryScope(controller: controller, child: child),
    ),
  ),
);

void main() {
  testWidgets('Source on GitHub opens the repository', (
    WidgetTester tester,
  ) async {
    final _FakeUrlLauncher launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    final GalleryController controller = GalleryController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(const OverviewPage(), controller));
    await tester.tap(find.text('Source on GitHub'));
    await tester.pump();

    expect(launcher.launched, contains('https://github.com/sunderee/carbide'));
  });
}
