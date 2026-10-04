// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    Directionality(
      textDirection: direction,
      child: CarbonTheme(
        data: CarbonThemeData.white,
        child: DefaultTextStyle(
          style: CarbonTypeStyles.body01,
          child: Center(child: SizedBox(width: 600, child: child)),
        ),
      ),
    );

Iterable<SemanticsNode> _nodes(WidgetTester tester) {
  Iterable<SemanticsNode> visit(SemanticsNode node) sync* {
    if (node.isMergedIntoParent) return;
    yield node;
    for (final child in node.debugListChildrenInOrder(
      DebugSemanticsDumpOrder.traversalOrder,
    )) {
      yield* visit(child);
    }
  }

  return visit(
    tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!,
  );
}

Iterable<SemanticsNode> _role(WidgetTester tester, SemanticsRole role) =>
    _nodes(tester).where((node) => node.getSemanticsData().role == role);

void _once(WidgetTester tester, String text) {
  final labels = _nodes(tester)
      .map((node) => node.getSemanticsData().label)
      .join('\n');
  expect(text.allMatches(labels), hasLength(1), reason: labels);
}

void _test(String name, WidgetTesterCallback callback) {
  testWidgets(name, (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await callback(tester);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CARBIDE_DUMP_STATIC_SEMANTICS')) {
        debugPrint('Semantics investigation: $name');
        debugPrint(
          tester
              .binding
              .renderViews
              .single
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!
              .toStringDeep(),
        );
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      handle.dispose();
    }
  });
}

void main() {
  for (final disabled in [false, true]) {
    _test('static status tag exposes complete text once, disabled=$disabled', (
      tester,
    ) async {
      const label =
          'Active service with a deliberately long descriptive status';
      await tester.pumpWidget(
        _host(
          CarbonTag(
            label: label,
            disabled: disabled,
            icon: CarbonIcons.checkmark,
          ),
        ),
      );
      _once(tester, label);
      expect(
        _nodes(
          tester,
        ).any((node) => node.getSemanticsData().hasAction(SemanticsAction.tap)),
        isFalse,
      );
    });
  }
  _test(
    'caller can hide decorative tags and replace context without duplication',
    (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              const ExcludeSemantics(child: CarbonTag(label: 'Decorative')),
              Semantics(
                label: 'Service status: Active',
                excludeSemantics: true,
                child: const CarbonTag(label: 'Active'),
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Decorative'), findsNothing);
      _once(tester, 'Service status: Active');
      _once(tester, 'Active');
    },
  );
  for (final direction in TextDirection.values) {
    for (final ordered in [false, true]) {
      _test(
        'nested list roles, direct counts and reading order $direction ordered=$ordered',
        (tester) async {
          final items = [
            const CarbonListItem(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parent'),
                  CarbonOrderedList(
                    children: [
                      CarbonListItem(child: Text('Nested Alpha')),
                      CarbonListItem(child: Text('Nested Beta')),
                    ],
                  ),
                ],
              ),
            ),
            const CarbonListItem(child: Text('Sibling')),
          ];
          await tester.pumpWidget(
            _host(
              ordered
                  ? CarbonOrderedList(children: items)
                  : CarbonUnorderedList(children: items),
              direction: direction,
            ),
          );
          final lists = _role(tester, SemanticsRole.list).toList();
          expect(lists, hasLength(2));
          expect(_role(tester, SemanticsRole.listItem), hasLength(4));
          for (final list in lists) {
            expect(
              list
                  .debugListChildrenInOrder(
                    DebugSemanticsDumpOrder.traversalOrder,
                  )
                  .map((node) => node.getSemanticsData().role),
              [SemanticsRole.listItem, SemanticsRole.listItem],
            );
          }
          for (final text in [
            'Parent',
            'Nested Alpha',
            'Nested Beta',
            'Sibling',
          ]) {
            _once(tester, text);
          }
          final labels = _nodes(tester)
              .map((node) => node.getSemanticsData().label)
              .join('\n');
          expect(
            labels.indexOf('Parent'),
            lessThan(labels.indexOf('Nested Alpha')),
          );
          expect(
            labels.indexOf('Nested Alpha'),
            lessThan(labels.indexOf('Nested Beta')),
          );
          expect(
            labels.indexOf('Nested Beta'),
            lessThan(labels.indexOf('Sibling')),
          );
        },
      );
    }
  }
  _test('empty list has no phantom items', (tester) async {
    await tester.pumpWidget(_host(const CarbonOrderedList(children: [])));
    // Flutter may cull the zero-area container; there are no item nodes.
    expect(_role(tester, SemanticsRole.listItem), isEmpty);
  });
  _test('interactive content remains a separate usable list descendant', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      _host(
        CarbonUnorderedList(
          children: [
            CarbonListItem(
              child: CarbonButton(
                label: 'Open record',
                onPressed: () => presses++,
              ),
            ),
          ],
        ),
      ),
    );
    expect(_role(tester, SemanticsRole.listItem), hasLength(1));
    _once(tester, 'Open record');
    await tester.tap(find.text('Open record'));
    await tester.pumpAndSettle();
    expect(presses, 1);
  });
  for (final type in CarbonCodeSnippetType.values) {
    for (final hideCopy in [false, true]) {
      _test(
        'snippet content once and caller-named region $type hideCopy=$hideCopy',
        (tester) async {
          await tester.pumpWidget(
            _host(
              Semantics(
                role: SemanticsRole.region,
                container: true,
                explicitChildNodes: true,
                label: 'Install command',
                child: CarbonCodeSnippet(
                  code: 'flutter pub add carbide',
                  type: type,
                  hideCopyButton: hideCopy,
                ),
              ),
            ),
          );
          expect(_role(tester, SemanticsRole.region), hasLength(1));
          _once(tester, 'Install command');
          _once(tester, 'flutter pub add carbide');
          final actionable = _nodes(tester).where(
            (node) => node.getSemanticsData().hasAction(SemanticsAction.tap),
          );
          expect(actionable, hasLength(hideCopy ? 0 : 1));
        },
      );
    }
  }
  _test('multi-line collapse keeps code available and toggle separate', (
    tester,
  ) async {
    const code = 'first();\nsecond();\nthird();';
    await tester.pumpWidget(
      _host(
        const CarbonCodeSnippet(
          code: code,
          type: CarbonCodeSnippetType.multi,
          maxCollapsedRows: 1,
          hideCopyButton: true,
        ),
      ),
    );
    _once(tester, code);
    _once(tester, 'Show more');
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    _once(tester, code);
    _once(tester, 'Show less');
  });
}
