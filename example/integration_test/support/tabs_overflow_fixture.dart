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
    tabsOverflowHost(
      TabsOverflowFixture(
        vertical: parameters['vertical'] == 'true',
        variant: parameters['contained'] == 'true'
            ? CarbonTabVariant.contained
            : CarbonTabVariant.line,
        activation: parameters['manual'] == 'true'
            ? CarbonTabActivationMode.manual
            : CarbonTabActivationMode.automatic,
        reduced: parameters['reduced'] == 'true',
        width: double.tryParse(parameters['width'] ?? '') ?? 320,
      ),
      theme: theme,
      direction: parameters['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      scale: double.tryParse(parameters['scale'] ?? '') ?? 1,
    ),
  );
}

/// A real app host for tab roles, scrolling and physical keyboard contracts.
Widget tabsOverflowHost(
  Widget child, {
  CarbonThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double scale = 1,
}) {
  final CarbonThemeData data = theme ?? CarbonThemeData.white;
  return WidgetsApp(
    color: data.background,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (BuildContext context, _, _) => Directionality(
        textDirection: direction,
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
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

/// Many tabs in a deliberately narrow host, with an observable change count.
class TabsOverflowFixture extends StatefulWidget {
  /// Creates a horizontal or vertical overflow/activation fixture.
  const TabsOverflowFixture({
    super.key,
    this.vertical = false,
    this.variant = CarbonTabVariant.line,
    this.activation = CarbonTabActivationMode.automatic,
    this.reduced = false,
    this.width = 320,
  });

  /// Whether to render the vertical tab family.
  final bool vertical;

  /// The horizontal appearance.
  final CarbonTabVariant variant;

  /// The navigation/activation policy.
  final CarbonTabActivationMode activation;

  /// Initial programmatic scrolling motion preference.
  final bool reduced;

  /// The fixture width at its normal text scale.
  final double width;

  @override
  State<TabsOverflowFixture> createState() => TabsOverflowFixtureState();
}

/// Observed selection, change count and mutable lifecycle inputs.
class TabsOverflowFixtureState extends State<TabsOverflowFixture> {
  /// Currently controlled selection.
  int selected = 0;

  /// Selection callback count.
  int changes = 0;

  /// The current tab count.
  int count = 18;

  /// Whether to ignore callbacks while keeping the controlled selection.
  bool ignoreChanges = false;

  late bool _reduced = widget.reduced;

  /// Applies a programmatic selection without a user callback.
  void select(int value) => setState(() => selected = value);

  /// Removes later tabs and clamps the fixture's controlled value.
  void shrink() => setState(() {
    count = 4;
    selected = selected.clamp(0, 3);
  });

  /// Enables the runtime reduced-motion preference.
  void reduceMotion() => setState(() => _reduced = true);

  @override
  Widget build(BuildContext context) {
    final List<CarbonTab> tabs = <CarbonTab>[
      for (int i = 0; i < count; i++)
        CarbonTab(
          label: 'Tab ${i.toString().padLeft(2, '0')}',
          disabled: i == 2,
        ),
    ];
    final List<Widget> panels = <Widget>[
      for (int i = 0; i < count; i++) Text('Panel $i'),
    ];
    void change(int value) => setState(() {
      changes++;
      if (!ignoreChanges) selected = value;
    });
    final Widget content = widget.vertical
        ? CarbonTabsVertical(
            tabs: tabs,
            panels: panels,
            selectedIndex: selected,
            onChanged: change,
            activation: widget.activation,
            height: 240,
            tabListLabel: 'Categories',
          )
        : CarbonTabs(
            tabs: tabs,
            panels: panels,
            selectedIndex: selected,
            onChanged: change,
            activation: widget.activation,
            variant: widget.variant,
            tabListLabel: 'Categories',
          );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: _reduced),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(headingLevel: 1, child: const Text('Tab overflow')),
            const SizedBox(height: 16),
            Text('Changes: $changes; selected: $selected'),
            const SizedBox(height: 24),
            SizedBox(width: widget.width, child: content),
            const SizedBox(height: 24),
            CarbonButton(
              label: 'Outside',
              onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ],
        ),
      ),
    );
  }
}
