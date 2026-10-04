// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  final params = Uri.base.queryParameters;
  final theme = switch (params['theme']) {
    'g10' => CarbonThemeData.gray10,
    'g90' => CarbonThemeData.gray90,
    'g100' => CarbonThemeData.gray100,
    _ => CarbonThemeData.white,
  };
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    contextMenuHost(
      ContextMenuFixture(
        editable: params['editor'] == 'true',
        selectionKind: params['kind'],
      ),
      direction: params['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      theme: theme,
    ),
  );
}

Widget contextMenuHost(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  CarbonThemeData? theme,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  onGenerateRoute: (_) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => Directionality(
      textDirection: direction,
      child: CarbonTheme(
        data: theme ?? CarbonThemeData.white,
        child: ColoredBox(
          color: (theme ?? CarbonThemeData.white).background,
          child: Center(child: child),
        ),
      ),
    ),
    transitionDuration: Duration.zero,
  ),
);

class ContextMenuFixture extends StatefulWidget {
  const ContextMenuFixture({
    super.key,
    this.editable = false,
    this.selectionKind,
  });
  final bool editable;
  final String? selectionKind;
  @override
  State<ContextMenuFixture> createState() => ContextMenuFixtureState();
}

class ContextMenuFixtureState extends State<ContextMenuFixture> {
  final target = FocusNode(debugLabel: 'Context target');
  final second = FocusNode(debugLabel: 'Second context target');
  final outside = FocusNode(debugLabel: 'Outside context menu');
  final controller = TextEditingController(text: 'Alpha');
  bool enabled = true;
  bool showRegion = true;
  bool handoff = false;
  bool allDisabled = false;
  int actions = 0;
  int nestedActions = 0;
  bool pinned = false;
  int mode = 1;
  void refresh() => setState(() {});
  @override
  void dispose() {
    target.dispose();
    second.dispose();
    outside.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      switch (event.logicalKey) {
        case LogicalKeyboardKey.f2:
          enabled = !enabled;
        case LogicalKeyboardKey.f3:
          showRegion = !showRegion;
        case LogicalKeyboardKey.f4:
          handoff = !handoff;
        case LogicalKeyboardKey.f6:
          allDisabled = !allDisabled;
        default:
          return KeyEventResult.ignored;
      }
      refresh();
      return KeyEventResult.handled;
    },
    child: SizedBox(
      width: 680,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            container: true,
            child: const Text(
              'Focus a target, then press Shift+F10 or the Context Menu key.',
            ),
          ),
          const SizedBox(height: 24),
          if (showRegion)
            CarbonContextMenu(
              enabled: enabled,
              size: CarbonMenuSize.lg,
              items: <Widget>[
                const CarbonMenuItem(label: 'Unavailable', disabled: true),
                if (widget.selectionKind == 'selectable')
                  CarbonMenuItemSelectable(
                    label: 'Pinned',
                    selected: pinned,
                    onChanged: (value) => setState(() => pinned = value),
                  ),
                if (widget.selectionKind == 'radio')
                  CarbonMenuItemRadioGroup<int>(
                    label: 'Mode',
                    value: mode,
                    options: const <(int, String)>[
                      (1, 'First mode'),
                      (2, 'Second mode'),
                    ],
                    onChanged: (value) => setState(() => mode = value),
                  ),
                CarbonMenuItem(
                  label: 'Cut',
                  disabled: allDisabled,
                  onPressed: () {
                    setState(() => actions++);
                    if (handoff) outside.requestFocus();
                  },
                ),
                CarbonMenuItem(
                  label: 'Copy',
                  disabled: allDisabled,
                  onPressed: () => setState(() => actions++),
                ),
                CarbonMenuItem(
                  label: 'More',
                  disabled: allDisabled,
                  submenu: <Widget>[
                    CarbonMenuItem(
                      label: 'Archive',
                      onPressed: () => setState(() => nestedActions++),
                    ),
                  ],
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (widget.editable)
                      CarbonTextInput(
                        labelText: 'Context editor',
                        controller: controller,
                        focusNode: target,
                      )
                    else
                      CarbonButton(
                        label: 'Context target',
                        focusNode: target,
                        onPressed: () {},
                      ),
                    const SizedBox(height: 16),
                    CarbonButton(
                      label: 'Second target',
                      focusNode: second,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          CarbonButton(
            label: 'Outside region',
            focusNode: outside,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          Semantics(
            container: true,
            child: Text(
              'Actions: $actions; nested: $nestedActions; enabled: $enabled; handoff: $handoff',
            ),
          ),
        ],
      ),
    ),
  );
}
