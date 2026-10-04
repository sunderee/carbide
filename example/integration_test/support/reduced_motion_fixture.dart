// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'dart:convert';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void main() {
  final params = Uri.base.queryParameters;
  WidgetsFlutterBinding.ensureInitialized().ensureSemantics();
  runApp(
    reducedMotionHost(
      ReducedMotionFixture(component: params['component'] ?? 'listBox'),
      direction: params['rtl'] == 'true'
          ? TextDirection.rtl
          : TextDirection.ltr,
      theme: switch (params['theme']) {
        'g10' => CarbonThemeData.gray10,
        'g90' => CarbonThemeData.gray90,
        'g100' => CarbonThemeData.gray100,
        _ => CarbonThemeData.white,
      },
    ),
  );
}

Widget reducedMotionHost(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  CarbonThemeData? theme,
  bool? reduced,
}) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  onGenerateRoute: (_) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => Builder(
      builder: (context) {
        final data = theme ?? CarbonThemeData.white;
        Widget body = Directionality(
          textDirection: direction,
          child: CarbonTheme(
            data: data,
            child: ColoredBox(
              color: data.background,
              child: DefaultTextStyle(
                style: CarbonTypeStyles.body01.copyWith(
                  color: data.textPrimary,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        );
        if (reduced != null) {
          body = MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: body,
          );
        }
        return body;
      },
    ),
    transitionDuration: Duration.zero,
  ),
);

class ReducedMotionFixture extends StatefulWidget {
  const ReducedMotionFixture({super.key, required this.component});
  final String component;
  @override
  State<ReducedMotionFixture> createState() => ReducedMotionFixtureState();
}

class ReducedMotionFixtureState extends State<ReducedMotionFixture> {
  final GlobalKey subject = GlobalKey();
  bool expanded = false;
  String snapshot = '';
  int snapshotSequence = 0;
  int activations = 0;
  num value = 30;
  final controller = TextEditingController();

  List<ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget>> get animations {
    final result = <ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget>>[];
    void visit(Element element) {
      if (element is StatefulElement &&
          element.state
              is ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget>) {
        result.add(
          element.state
              as ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget>,
        );
      }
      element.visitChildren(visit);
    }

    final context = subject.currentContext;
    if (context != null) visit(context as Element);
    return result;
  }

  void capture() {
    setState(() {
      snapshot = jsonEncode(<String, Object>{
        'sequence': ++snapshotSequence,
        'reduced': MediaQuery.disableAnimationsOf(context),
        'durations': <int>[
          for (final state in animations) state.widget.duration.inMilliseconds,
        ],
        'running': animations.any(
          (state) => state.animation.status.isAnimating,
        ),
        'activations': activations,
        if (widget.component == 'tabs') ..._scrollSnapshot(),
      });
    });
  }

  Map<String, double> _scrollSnapshot() {
    final result = <String, double>{};
    void visit(Element element) {
      final widget = element.widget;
      if (widget is SingleChildScrollView &&
          widget.controller?.hasClients == true) {
        result['offset'] = widget.controller!.offset;
        result['max'] = widget.controller!.position.maxScrollExtent;
      }
      element.visitChildren(visit);
    }

    final element = subject.currentContext;
    if (element != null) visit(element as Element);
    return result;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    includeSemantics: false,
    skipTraversal: true,
    onKeyEvent: (_, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f8) {
        capture();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: SizedBox(
      width: 680,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            container: true,
            child: Text(
              'Motion preference: ${MediaQuery.disableAnimationsOf(context) ? 'reduced' : 'normal'}',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            key: subject,
            width: 480,
            child: switch (widget.component) {
              'combo' => CarbonComboBox<String>(
                titleText: 'Combo',
                placeholder: 'Choose a fruit',
                items: const <CarbonComboBoxItem<String>>[
                  CarbonComboBoxItem(value: 'a', label: 'Alpha'),
                ],
                onChanged: (_) => setState(() => activations++),
              ),
              'containedList' => CarbonContainedList(
                label: const Text('Contained list'),
                children: <Widget>[
                  CarbonContainedListItem(
                    onPressed: () => setState(() => activations++),
                    child: const Text('List row'),
                  ),
                ],
              ),
              'link' => CarbonLink(
                label: 'Documentation',
                onPressed: () => setState(() => activations++),
              ),
              'listBox' => CarbonListBox(
                expanded: expanded,
                child: const Text('List box'),
                onTap: () => setState(() {
                  expanded = !expanded;
                  activations++;
                }),
              ),
              'multi' => CarbonMultiSelect<String>(
                titleText: 'Multi',
                label: 'Choose',
                filterable: true,
                items: const <CarbonMultiSelectItem<String>>[
                  CarbonMultiSelectItem(value: 'a', label: 'Alpha'),
                ],
                onChanged: (_) => setState(() => activations++),
              ),
              'search' => CarbonSearch(controller: controller),
              'slider' => CarbonSlider(
                labelText: 'Slider',
                value: value,
                min: 0,
                max: 100,
                hideTextInput: true,
                onChanged: (next) => setState(() => value = next),
              ),
              'tree' => const CarbonTreeView(
                label: 'Files',
                nodes: <CarbonTreeNode>[
                  CarbonTreeNode(
                    id: 'root',
                    label: 'Root',
                    children: <CarbonTreeNode>[
                      CarbonTreeNode(id: 'child', label: 'Child'),
                    ],
                  ),
                ],
              ),
              'tabs' => CarbonTabsVertical(
                height: 256,
                tabs: <CarbonTab>[
                  for (int i = 0; i < 12; i++) CarbonTab(label: 'Tab $i'),
                ],
                panels: <Widget>[for (int i = 0; i < 12; i++) Text('Panel $i')],
              ),
              _ => throw ArgumentError.value(widget.component, 'component'),
            },
          ),
          const SizedBox(height: 32),
          CarbonButton(label: 'Capture motion', onPressed: capture),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: Semantics(
              container: true,
              child: Text(snapshot, key: const Key('motion-snapshot')),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Essential activity signals and decorative skeletons'),
          const SizedBox(height: 12),
          const Row(
            children: <Widget>[
              CarbonLoading(small: true),
              SizedBox(width: 24),
              Expanded(
                child: CarbonProgressBar(label: 'Indeterminate progress'),
              ),
              SizedBox(width: 24),
              CarbonSkeleton(width: 80, height: 24),
            ],
          ),
        ],
      ),
    ),
  );
}
