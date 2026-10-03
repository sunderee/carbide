// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden.dart';

Widget _host(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 280, child: child)),
  ),
);

// The marker's own SizedBox is the nearest ancestor (the outer test host is
// also a SizedBox, hence `.first`).
double _markerGutter(WidgetTester tester, String marker) => tester
    .widget<SizedBox>(
      find
          .ancestor(of: find.text(marker), matching: find.byType(SizedBox))
          .first,
    )
    .width!;

void main() {
  final CarbonThemeData theme = CarbonThemeData.white;

  group('markers (styles/scss/components/list/_list.scss)', () {
    testWidgets('ordered top-level numbers items; nested uses lower-latin', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonOrderedList(
            children: <CarbonListItem>[
              CarbonListItem(
                child: CarbonOrderedList(
                  children: <CarbonListItem>[
                    CarbonListItem(child: Text('nested one')),
                    CarbonListItem(child: Text('nested two')),
                  ],
                ),
              ),
              CarbonListItem(child: Text('second')),
            ],
          ),
        ),
      );
      // Top-level: 1. then 2.
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      // Nested ordered: a. then b.
      expect(find.text('a.'), findsOneWidget);
      expect(find.text('b.'), findsOneWidget);
    });

    for (final parentOrdered in <bool>[true, false]) {
      testWidgets(
        '53 nested ordered markers continue through z and az, ordered parent=$parentOrdered',
        (tester) async {
          final items = <CarbonListItem>[
            CarbonListItem(
              child: CarbonOrderedList(
                children: <CarbonListItem>[
                  for (int i = 0; i < 53; i++)
                    CarbonListItem(child: Text('Item ${i + 1}')),
                ],
              ),
            ),
          ];
          await tester.pumpWidget(
            _host(
              SingleChildScrollView(
                child: parentOrdered
                    ? CarbonOrderedList(children: items)
                    : CarbonUnorderedList(children: items),
              ),
            ),
          );
          for (final marker in <String>[
            'y.',
            'z.',
            'aa.',
            'ab.',
            'az.',
            'ba.',
          ]) {
            expect(find.text(marker), findsOneWidget);
            expect(_markerGutter(tester, marker), 24);
          }
          expect(
            find.byWidgetPredicate(
              (w) => w is Text && RegExp(r'^[{}|~]\.$').hasMatch(w.data ?? ''),
            ),
            findsNothing,
          );
          expect(find.text(parentOrdered ? '1.' : '–'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets(
      'empty nested list creates no marker and neighboring lists restart at a',
      (tester) async {
        await tester.pumpWidget(
          _host(
            const CarbonOrderedList(
              children: <CarbonListItem>[
                CarbonListItem(
                  child: CarbonOrderedList(children: <CarbonListItem>[]),
                ),
                CarbonListItem(
                  child: CarbonOrderedList(
                    children: <CarbonListItem>[
                      CarbonListItem(child: Text('First')),
                    ],
                  ),
                ),
                CarbonListItem(
                  child: CarbonOrderedList(
                    children: <CarbonListItem>[
                      CarbonListItem(child: Text('Second')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        expect(find.text('a.'), findsNWidgets(2));
        expect(find.text('b.'), findsNothing);
        expect(find.text('1.'), findsOneWidget);
        expect(find.text('2.'), findsOneWidget);
        expect(find.text('3.'), findsOneWidget);
      },
    );
    for (final direction in TextDirection.values) {
      testWidgets(
        'wide expressive markers stay on one line outside the content edge: $direction',
        (tester) async {
          await tester.pumpWidget(
            _host(
              Directionality(
                textDirection: direction,
                child: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: SingleChildScrollView(
                    child: CarbonOrderedList(
                      expressive: true,
                      children: <CarbonListItem>[
                        CarbonListItem(
                          child: CarbonOrderedList(
                            children: <CarbonListItem>[
                              CarbonListItem(
                                child: CarbonOrderedList(
                                  children: <CarbonListItem>[
                                    for (int i = 0; i < 703; i++)
                                      CarbonListItem(
                                        child: Text('Item ${i + 1}'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          for (final entry in <String, int>{
            'zw.': 699,
            'zz.': 702,
            'aaa.': 703,
          }.entries) {
            final marker = tester.getRect(find.text(entry.key));
            final item = tester.getRect(find.text('Item ${entry.value}'));
            expect(marker.height, item.height);
            expect(
              direction == TextDirection.ltr ? marker.right : marker.left,
              closeTo(
                direction == TextDirection.ltr ? item.left - 4 : item.right + 4,
                0.01,
              ),
            );
            expect(_markerGutter(tester, entry.key), 24);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
    testWidgets('unordered top-level is en-dash; nested is a square', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonUnorderedList(
            children: <CarbonListItem>[
              CarbonListItem(
                child: CarbonUnorderedList(
                  children: <CarbonListItem>[
                    CarbonListItem(child: Text('nested')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('–'), findsOneWidget); // –
      expect(find.text('▪'), findsOneWidget); // ▪
    });

    testWidgets('marker gutters: ordered 24, unordered 16, nested square 12', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonOrderedList(
            children: <CarbonListItem>[CarbonListItem(child: Text('x'))],
          ),
        ),
      );
      expect(_markerGutter(tester, '1.'), 24);

      await tester.pumpWidget(
        _host(
          const CarbonUnorderedList(
            children: <CarbonListItem>[
              CarbonListItem(
                child: CarbonUnorderedList(
                  children: <CarbonListItem>[CarbonListItem(child: Text('y'))],
                ),
              ),
            ],
          ),
        ),
      );
      expect(_markerGutter(tester, '–'), 16);
      expect(_markerGutter(tester, '▪'), 12);
    });
  });

  group('typography', () {
    testWidgets('body-01 by default; body-02 when expressive (inherited)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonUnorderedList(
            children: <CarbonListItem>[CarbonListItem(child: Text('item'))],
          ),
        ),
      );
      // The marker Text carries the resolved style (content inherits it via
      // the wrapping DefaultTextStyle).
      expect(
        tester.widget<Text>(find.text('–')).style!.fontSize,
        CarbonTypeStyles.body01.fontSize,
      );
      expect(
        tester.widget<Text>(find.text('–')).style!.color,
        theme.textPrimary,
      );

      await tester.pumpWidget(
        _host(
          const CarbonUnorderedList(
            expressive: true,
            children: <CarbonListItem>[
              CarbonListItem(
                child: CarbonUnorderedList(
                  children: <CarbonListItem>[
                    CarbonListItem(child: Text('deep')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      // Nested list inherits the expressive scale (read off its marker).
      expect(
        tester.widget<Text>(find.text('▪')).style!.fontSize,
        CarbonTypeStyles.body02.fontSize,
      );
    });
  });

  group('semantics', () {
    testWidgets('item content is readable by assistive technology', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const CarbonUnorderedList(
            children: <CarbonListItem>[
              CarbonListItem(child: Text('First')),
              CarbonListItem(child: Text('Second')),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('First'), findsOneWidget);
      expect(find.bySemanticsLabel('Second'), findsOneWidget);
      handle.dispose();
    });
  });

  testWidgets('nested lower-latin boundaries across themes and directions', (
    tester,
  ) async {
    await expectThemeGoldens(
      tester,
      name: 'list_lower_latin_boundary',
      containsText: true,
      size: const Size(360, 260),
      directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
      builder: (_) => Center(
        child: SizedBox(
          width: 320,
          height: 220,
          child: SingleChildScrollView(
            child: CarbonOrderedList(
              children: <CarbonListItem>[
                CarbonListItem(
                  child: CarbonOrderedList(
                    children: <CarbonListItem>[
                      for (int i = 0; i < 30; i++)
                        CarbonListItem(child: Text('Item ${i + 1}')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      afterPump: (tester) async {
        // Show the transition x, y, z, aa … with the real list numbering.
        await tester.ensureVisible(find.text('Item 30'));
        await tester.pumpAndSettle();
      },
    );
  });
  testWidgets(
    'wide lower-latin markers hang in the gutter across themes and directions',
    (tester) async {
      await expectThemeGoldens(
        tester,
        name: 'list_lower_latin_wide',
        containsText: true,
        size: const Size(360, 260),
        directions: const <TextDirection>{TextDirection.ltr, TextDirection.rtl},
        builder: (_) => Center(
          child: SizedBox(
            width: 320,
            height: 220,
            child: SingleChildScrollView(
              child: CarbonOrderedList(
                expressive: true,
                children: <CarbonListItem>[
                  CarbonListItem(
                    child: CarbonOrderedList(
                      children: <CarbonListItem>[
                        for (int i = 0; i < 703; i++)
                          CarbonListItem(child: Text('Item ${i + 1}')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        afterPump: (tester) async {
          await tester.ensureVisible(find.text('Item 703'));
          await tester.pumpAndSettle();
        },
      );
    },
  );
  testWidgets('list variants across themes', (WidgetTester tester) async {
    await expectThemeGoldens(
      tester,
      name: 'list',
      containsText: true,
      size: const Size(320, 320),
      builder: (BuildContext context) => const Center(
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CarbonOrderedList(
                children: <CarbonListItem>[
                  CarbonListItem(child: Text('Ordered one')),
                  CarbonListItem(
                    child: CarbonOrderedList(
                      children: <CarbonListItem>[
                        CarbonListItem(child: Text('Nested a')),
                        CarbonListItem(child: Text('Nested b')),
                      ],
                    ),
                  ),
                  CarbonListItem(child: Text('Ordered three')),
                ],
              ),
              SizedBox(height: 16),
              CarbonUnorderedList(
                children: <CarbonListItem>[
                  CarbonListItem(child: Text('Unordered one')),
                  CarbonListItem(
                    child: CarbonUnorderedList(
                      children: <CarbonListItem>[
                        CarbonListItem(child: Text('Nested square')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  });
}
