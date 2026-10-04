// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overlay_entries.dart';

enum _Specimen {
  combo,
  containedList,
  link,
  listBox,
  multi,
  search,
  slider,
  tree,
}

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });
  for (final _Specimen specimen in _Specimen.values) {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('$specimen snaps under reduced motion: $direction', (
        WidgetTester tester,
      ) async {
        await _exercise(tester, specimen, direction, reduced: true);
        expect(_animations(tester), isNotEmpty);
        expect(
          _animations(tester)
              .where((state) => state.animation.status.isAnimating),
          isEmpty,
          reason:
              'Decorative transitions must reach their final state without '
              'waiting for the normal duration.',
        );
      });
    }
    testWidgets('$specimen responds to a live reduced-motion change', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> reduced = ValueNotifier<bool>(false);
      addTearDown(reduced.dispose);
      final Future<void> Function() reverse = await _exercise(
        tester,
        specimen,
        TextDirection.ltr,
        reduced: false,
        policy: reduced,
      );
      expect(
        _animations(tester).any((state) => state.animation.status.isAnimating),
        isTrue,
        reason: 'Normal motion is a positive control for the same interaction.',
      );
      await tester.pumpAndSettle();
      reduced.value = true;
      await tester.pump();
      await reverse();
      await tester.pump();
      await tester.pump();
      expect(
        _animations(tester)
            .where((state) => state.animation.status.isAnimating),
        isEmpty,
      );
      reduced.value = false;
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final bool reduced in <bool>[false, true]) {
    testWidgets('vertical tabs reveal the selected row: reduced=$reduced', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          reduced: reduced,
          direction: TextDirection.ltr,
          child: CarbonTabsVertical(
            height: 256,
            tabs: <CarbonTab>[
              for (int i = 0; i < 12; i++) CarbonTab(label: 'Tab $i'),
            ],
            panels: <Widget>[for (int i = 0; i < 12; i++) Text('Panel $i')],
          ),
        ),
      );
      await tester.tap(find.text('Tab 0'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      final ScrollController controller = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      if (reduced) {
        expect(controller.offset, controller.position.maxScrollExtent);
        expect(controller.position.isScrollingNotifier.value, isFalse);
        expect(find.text('Panel 11'), findsOneWidget);
      } else {
        expect(
          controller.offset,
          lessThan(controller.position.maxScrollExtent),
        );
        await tester.pumpAndSettle();
        expect(controller.offset, controller.position.maxScrollExtent);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

Iterable<ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget>> _animations(
  WidgetTester tester,
) => tester.stateList<ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget>>(
  find.byWidgetPredicate((widget) => widget is ImplicitlyAnimatedWidget),
);

Widget _host({
  required bool reduced,
  required TextDirection direction,
  required Widget child,
}) => Directionality(
  textDirection: direction,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: CarbonTheme(
      data: CarbonThemeData.white,
      child: Center(child: SizedBox(width: 400, child: child)),
    ),
  ),
);

Future<Future<void> Function()> _exercise(
  WidgetTester tester,
  _Specimen specimen,
  TextDirection direction, {
  required bool reduced,
  ValueNotifier<bool>? policy,
}) async {
  final Widget child = _MotionSpecimen(specimen: specimen);
  final OverlayEntry entry = managedOverlayEntry(builder: (_) => child);
  final Widget overlay = Overlay(initialEntries: <OverlayEntry>[entry]);
  await tester.pumpWidget(
    policy == null
        ? _host(reduced: reduced, direction: direction, child: overlay)
        : ValueListenableBuilder<bool>(
            valueListenable: policy,
            child: overlay,
            builder: (_, bool value, Widget? child) =>
                _host(reduced: value, direction: direction, child: child!),
          ),
  );
  await tester.pumpAndSettle();
  late final Future<void> Function() reverse;
  switch (specimen) {
    case _Specimen.combo:
    case _Specimen.containedList:
    case _Specimen.link:
    case _Specimen.multi:
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(const Key('subject'))));
      reverse = () => mouse.moveTo(Offset.zero);
    case _Specimen.listBox:
      await tester.tap(find.text('List box'));
      reverse = () => tester.tap(find.text('List box'));
    case _Specimen.search:
      await tester.enterText(find.byType(EditableText), 'query');
      reverse = () => tester.enterText(find.byType(EditableText), '');
    case _Specimen.slider:
      final FocusNode node = tester
          .widget<Focus>(
            find
                .descendant(
                  of: find.byType(CarbonSlider),
                  matching: find.byType(Focus),
                )
                .first,
          )
          .focusNode!;
      node.requestFocus();
      reverse = () async => node.unfocus();
    case _Specimen.tree:
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is CarbonIcon && widget.icon == CarbonIcons.chevronDown,
        ),
      );
      reverse = () => tester.tap(find.byType(AnimatedRotation));
  }
  await tester.pump();
  await tester.pump();
  return reverse;
}

class _MotionSpecimen extends StatefulWidget {
  const _MotionSpecimen({required this.specimen});
  final _Specimen specimen;
  @override
  State<_MotionSpecimen> createState() => _MotionSpecimenState();
}

class _MotionSpecimenState extends State<_MotionSpecimen> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 360,
      child: switch (widget.specimen) {
        _Specimen.combo => CarbonComboBox<String>(
          key: const Key('subject'),
          titleText: 'Combo',
          items: const <CarbonComboBoxItem<String>>[
            CarbonComboBoxItem<String>(value: 'a', label: 'Alpha'),
          ],
          onChanged: (_) {},
        ),
        _Specimen.containedList => CarbonContainedList(
          children: <Widget>[
            CarbonContainedListItem(
              key: const Key('subject'),
              onPressed: () {},
              child: const Text('Row'),
            ),
          ],
        ),
        _Specimen.link => CarbonLink(
          key: const Key('subject'),
          label: 'Link',
          onPressed: () {},
        ),
        _Specimen.listBox => CarbonListBox(
          expanded: expanded,
          onTap: () => setState(() => expanded = !expanded),
          child: const Text('List box'),
        ),
        _Specimen.multi => CarbonMultiSelect<String>(
          key: const Key('subject'),
          titleText: 'Multi',
          label: 'Choose',
          filterable: true,
          items: const <CarbonMultiSelectItem<String>>[
            CarbonMultiSelectItem<String>(value: 'a', label: 'Alpha'),
          ],
          onChanged: (_) {},
        ),
        _Specimen.search => const CarbonSearch(),
        _Specimen.slider => CarbonSlider(
          value: 30,
          min: 0,
          max: 100,
          onChanged: (_) {},
          hideTextInput: true,
        ),
        _Specimen.tree => const CarbonTreeView(
          label: 'Tree',
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
      },
    ),
  );
}
