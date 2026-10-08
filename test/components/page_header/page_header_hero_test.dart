// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show ViewFocusEvent, ViewFocusState, ViewFocusDirection;

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';
import '../../support/legibility.dart';
import '../../support/overlay_entries.dart';

final Uint8List _image = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAQAAAACCAIAAADwyuo0AAAAGElEQVR4nGPkT/rHwMAgau/FwMDAxIAEACyuAhGSwbm6AAAAAElFTkSuQmCC',
);
const Key _hero = ValueKey<String>('hero');

Widget _host(
  Widget child, {
  double width = 320,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xffffffff),
  builder: (_, _) => Directionality(
    textDirection: direction,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: Overlay(
          key: UniqueKey(),
          initialEntries: [
            managedOverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: width,
                  maxWidth: width,
                  child: SizedBox(width: width, child: child),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

Widget _imageHero() => Image.memory(
  _image,
  key: _hero,
  fit: BoxFit.cover,
  semanticLabel: 'Report illustration',
);

void main() {
  // Decoded fixture images belong to the test cache, not the hero owner.
  tearDown(() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });
  testWidgets('hero dimensions follow actual md/lg width and optional ratio', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final width in [320.0, 671.0, 672.0, 1055.0, 1056.0, 1100.0]) {
      await tester.pumpWidget(
        _host(
          const CarbonPageHeader(
            title: 'Report',
            hero: ColoredBox(key: _hero, color: Color(0xff0f62fe)),
          ),
          width: width,
        ),
      );
      await tester.pumpAndSettle();
      final size = tester.getSize(find.byKey(_hero));
      expect(size.width, closeTo((width < 672 ? width : width / 2) - 32, .001));
      expect(size.width / size.height, closeTo(width >= 1056 ? 2 : 1.5, .001));
      final title = tester.getRect(find.text('Report')),
          hero = tester.getRect(find.byKey(_hero));
      if (width < 672) {
        expect(hero.top, greaterThan(title.bottom));
      } else {
        expect(hero.top, title.top);
      }
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(
      _host(
        const CarbonPageHeader(
          title: 'Report',
          hero: ColoredBox(key: _hero, color: Color(0xff0f62fe)),
          heroAspectRatio: 1,
        ),
      ),
    );
    final size = tester.getSize(find.byKey(_hero));
    expect(size.width, size.height);
  });
  testWidgets('absent hero retains the content composition', (tester) async {
    await tester.pumpWidget(
      _host(const CarbonPageHeader(title: 'Report', subtitle: 'Finance')),
    );
    expect(find.byType(AspectRatio), findsNothing);
    expect(find.text('Report'), findsOneWidget);
    expect(tester.getRect(find.text('Report')).left, 16);
  });
  for (final ratio in [0.0, -1.0, double.infinity, double.nan]) {
    test('invalid hero ratio rejected: $ratio', () {
      expect(
        () => CarbonPageHeader(title: 'Report', heroAspectRatio: ratio),
        throwsAssertionError,
      );
    });
  }
  test('decorative hero cannot also have an informative label', () {
    expect(
      () => CarbonPageHeader(
        title: 'Report',
        heroDecorative: true,
        heroLabel: 'Image',
      ),
      throwsAssertionError,
    );
  });
  testWidgets(
    'image semantics distinguish decorative, informative and child-owned content',
    (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.binding.setSurfaceSize(const Size(1200, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final (decorative, label) in <(bool, String?)>[
          (false, null),
          (true, null),
          (false, 'Quarterly results'),
        ]) {
          await tester.pumpWidget(
            _host(
              CarbonPageHeader(
                title: 'Report',
                hero: _imageHero(),
                heroDecorative: decorative,
                heroLabel: label,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (decorative) {
            expect(find.bySemanticsLabel('Report illustration'), findsNothing);
          } else {
            expect(
              find.bySemanticsLabel(label ?? 'Report illustration'),
              findsOneWidget,
            );
          }
          expect(
            tester
                .getSemantics(find.text('Report'))
                .getSemanticsData()
                .headingLevel,
            1,
          );
          expect(tester.takeException(), isNull);
        }
      } finally {
        handle.dispose();
      }
    },
  );
  for (final width in [320.0, 1100.0]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.3, 2.0]) {
        testWidgets(
          'scaled hero layout and reading order $width/$direction/$scale',
          (tester) async {
            final handle = tester.ensureSemantics();
            try {
              await tester.binding.setSurfaceSize(const Size(1200, 1000));
              addTearDown(() => tester.binding.setSurfaceSize(null));
              await tester.pumpWidget(
                _host(
                  CarbonPageHeader(
                    title: 'Report',
                    subtitle: 'Finance',
                    body: 'Revenue summary',
                    hero: _imageHero(),
                    tabs: const Text('Tab area'),
                    breadcrumbs: const [
                      CarbonBreadcrumbItem(label: 'Home', isCurrentPage: true),
                    ],
                  ),
                  direction: direction,
                  scale: scale,
                  width: width,
                ),
              );
              await tester.pumpAndSettle();
              expectNoClippedTextAtScale(tester, scale);
              final labels = tester.semantics
                  .simulatedAccessibilityTraversal()
                  .map((node) => node.getSemanticsData().label)
                  .toList();
              int index(String name) =>
                  labels.indexWhere((label) => label.contains(name));
              expect(index('Home'), lessThan(index('Report')));
              expect(index('Report'), lessThan(index('Revenue summary')));
              expect(
                index('Revenue summary'),
                lessThan(index('Report illustration')),
              );
              expect(index('Report illustration'), lessThan(index('Tab area')));
              expect(tester.takeException(), isNull);
            } finally {
              handle.dispose();
            }
          },
        );
      }
    }
  }
  testWidgets(
    'caller custom state and editor survive wide/narrow reparenting',
    (tester) async {
      final key = GlobalKey<_HeroEditorState>();
      final lifecycle = <String>[];
      var width = 1100.0;
      late StateSetter update;
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _host(
          Align(
            alignment: Alignment.topLeft,
            child: StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return SizedBox(
                  width: width,
                  child: CarbonPageHeader(
                    title: 'Report',
                    hero: _HeroEditor(key: key, lifecycle: lifecycle),
                    actions: <CarbonPageHeaderAction>[
                      CarbonPageHeaderAction(
                        id: 'edit',
                        label: 'Edit',
                        onPressed: () {},
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          width: 1200,
        ),
      );
      await tester.pumpAndSettle();
      final original = key.currentState!;
      tester.binding.handleViewFocusChanged(
        ViewFocusEvent(
          viewId: tester.view.viewId,
          state: ViewFocusState.focused,
          direction: ViewFocusDirection.undefined,
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Keep hero draft');
      final FocusNode focus = tester
          .widget<EditableText>(find.byType(EditableText))
          .focusNode;
      expect(focus.hasFocus, isTrue);
      update(() => width = 320);
      await tester.pumpAndSettle();
      expect(key.currentState, same(original));
      expect(original.controller.text, 'Keep hero draft');
      expect(focus.hasFocus, isTrue);
      update(() => width = 1100);
      await tester.pumpAndSettle();
      expect(key.currentState, same(original));
      expect(original.controller.text, 'Keep hero draft');
      expect(focus.hasFocus, isTrue);
      expect(lifecycle, ['created']);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(lifecycle, ['created', 'disposed']);
      expect(tester.takeException(), isNull);
    },
  );
  for (final kind in ['none', 'image', 'custom']) {
    for (final width in [320.0, 1100.0]) {
      testWidgets('golden hero $kind/$width', (tester) async {
        await expectThemeGoldens(
          tester,
          name: 'page_header_hero_${kind}_${width.toInt()}',
          size: Size(width, 700),
          containsText: true,
          directions: TextDirection.values.toSet(),
          mediaQuery: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          builder: (_) => Overlay(
            initialEntries: [
              managedOverlayEntry(
                builder: (context) => Align(
                  alignment: Alignment.topLeft,
                  child: CarbonPageHeader(
                    title: 'Quarterly report',
                    subtitle: 'Finance',
                    body: 'Revenue summary',
                    hero: switch (kind) {
                      'image' => _imageHero(),
                      'custom' => ColoredBox(
                        color: const Color(0xff0f62fe),
                        child: Center(
                          child: Text(
                            'Custom content',
                            style: CarbonTypeStyles.body01.copyWith(
                              color: const Color(0xffffffff),
                            ),
                          ),
                        ),
                      ),
                      _ => null,
                    },
                  ),
                ),
              ),
            ],
          ),
          afterPump: (tester) async {
            if (kind == 'image') {
              await tester.runAsync(
                () => precacheImage(
                  MemoryImage(_image),
                  tester.element(find.byKey(_hero)),
                ),
              );
            }
            await tester.pumpAndSettle();
          },
        );
      });
    }
  }
}

class _HeroEditor extends StatefulWidget {
  const _HeroEditor({required this.lifecycle, super.key});
  final List<String> lifecycle;
  @override
  State<_HeroEditor> createState() => _HeroEditorState();
}

class _HeroEditorState extends State<_HeroEditor> {
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.lifecycle.add('created');
  }

  @override
  void dispose() {
    widget.lifecycle.add('disposed');
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CarbonTheme.of(context).layer01,
    child: Center(
      child: CarbonTextInput(labelText: 'Hero note', controller: controller),
    ),
  );
}
