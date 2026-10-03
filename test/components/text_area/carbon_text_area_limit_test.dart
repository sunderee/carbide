// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(CarbonTextArea child) => WidgetsApp(
  color: const Color(0xffffffff),
  builder: (BuildContext context, Widget? _) => CarbonTheme(
    data: CarbonThemeData.white,
    child: Center(child: SizedBox(width: 340, child: child)),
  ),
);

TextEditingController _controller(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller;

Future<void> _edit(WidgetTester tester, TextEditingValue value) async {
  tester.testTextInput.updateEditingValue(value);
  await tester.pump();
}

Future<void> _paste(WidgetTester tester, String text) async {
  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async => call.method == 'Clipboard.getData'
        ? <String, String>{'text': text}
        : null,
  );
  try {
    await tester
        .state<EditableTextState>(find.byType(EditableText))
        .pasteText(SelectionChangedCause.keyboard);
    await tester.pump();
  } finally {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  }
}

void main() {
  testWidgets('blur commits a known composition without dropping its suffix', (
    WidgetTester tester,
  ) async {
    final FocusNode focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      _host(
        CarbonTextArea(
          labelText: 'Note',
          initialValue: 'ABCD',
          maxCount: 6,
          focusNode: focus,
          enableCounter: true,
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    _controller(tester).selection = const TextSelection.collapsed(offset: 2);
    await _edit(
      tester,
      const TextEditingValue(
        text: 'AB日本語CD',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 2, end: 5),
      ),
    );
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(_controller(tester).text, 'AB日本CD');
    expect(_controller(tester).value.composing, TextRange.empty);
    expect(find.text('6/6'), findsOneWidget);
  });
  testWidgets(
    'composition survives rebuilds and external-to-internal ownership transfer',
    (WidgetTester tester) async {
      final TextEditingController external = TextEditingController(
        text: 'ABCD',
      );
      addTearDown(external.dispose);
      TextEditingController? controller = external;
      int maxCount = 8;
      late StateSetter update;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xffffffff),
          builder: (BuildContext context, Widget? _) => CarbonTheme(
            data: CarbonThemeData.white,
            child: Center(
              child: SizedBox(
                width: 340,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    update = setState;
                    return CarbonTextArea(
                      labelText: 'Note',
                      controller: controller,
                      maxCount: maxCount,
                      enableCounter: true,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      external.selection = const TextSelection.collapsed(offset: 2);
      const TextEditingValue composing = TextEditingValue(
        text: 'AB日本語CD',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 2, end: 5),
      );
      await _edit(tester, composing);
      update(() {
        controller = null;
        maxCount = 6;
      });
      await tester.pump();
      expect(_controller(tester).value, composing);
      expect(find.text('7/6'), findsOneWidget);
      external.text = 'obsolete';
      await _edit(tester, composing.copyWith(composing: TextRange.empty));
      expect(_controller(tester).text, 'AB日本CD');
      expect(find.text('6/6'), findsOneWidget);
      expect(external.text, 'obsolete');
    },
  );

  testWidgets('switching count modes updates enforcement and semantic units', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _host(const CarbonTextArea(labelText: 'Note', maxCount: 2)),
      );
      await tester.enterText(find.byType(EditableText), 'one two');
      expect(_controller(tester).text, 'on');
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            maxCount: 2,
            counterMode: CarbonCounterMode.word,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'one two three');
      await tester.pump();
      expect(_controller(tester).text, 'one two ');
      SemanticsData field = tester
          .getSemantics(find.bySemanticsLabel('Note'))
          .getSemanticsData();
      expect(field.maxValueLength, isNull);
      expect(field.hint, '2 of 2 words');
      await tester.pumpWidget(
        _host(const CarbonTextArea(labelText: 'Note', maxCount: 3)),
      );
      expect(_controller(tester).text, 'one two ');
      await tester.enterText(find.byType(EditableText), 'one two three');
      await tester.pump();
      expect(_controller(tester).text, 'one');
      field = tester
          .getSemantics(find.bySemanticsLabel('Note'))
          .getSemanticsData();
      expect(field.maxValueLength, 3);
      expect(field.currentValueLength, 3);
      expect(field.hint, isEmpty);
    } finally {
      handle.dispose();
    }
  });
  testWidgets('maxCount limits edits independently of the visible counter', (
    WidgetTester tester,
  ) async {
    final List<String> changes = <String>[];
    await tester.pumpWidget(
      _host(
        CarbonTextArea(labelText: 'Note', maxCount: 5, onChanged: changes.add),
      ),
    );
    await tester.enterText(find.byType(EditableText), '0123456789');
    await tester.pump();
    expect(_controller(tester).text, '01234');
    expect(changes, <String>['01234']);
    expect(find.text('5/5'), findsNothing);
    await _edit(
      tester,
      const TextEditingValue(
        text: '01234x',
        selection: TextSelection.collapsed(offset: 6),
      ),
    );
    expect(_controller(tester).text, '01234');
    expect(changes, <String>['01234']);
  });

  testWidgets('a missing maxCount leaves input unlimited', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CarbonTextArea(labelText: 'Note')));
    await tester.enterText(find.byType(EditableText), '0123456789');
    expect(_controller(tester).text, '0123456789');
  });

  for (final String grapheme in <String>[
    '😀',
    '🇸🇮',
    '👍🏽',
    '👨‍👩‍👧‍👦',
    'e\u0301',
  ]) {
    testWidgets('$grapheme counts as one at and around the limit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            maxCount: 3,
            enableCounter: true,
          ),
        ),
      );
      for (final int length in <int>[2, 3, 4]) {
        await tester.enterText(find.byType(EditableText), grapheme * length);
        await tester.pump();
        final int accepted = length > 3 ? 3 : length;
        expect(_controller(tester).text, grapheme * accepted);
        expect(
          _controller(tester).selection.extentOffset,
          grapheme.length * accepted,
        );
        expect(find.text('$accepted/3'), findsOneWidget);
      }
    });
  }

  testWidgets(
    'clipboard paste fills capacity and preserves the existing suffix',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            initialValue: 'ABCD',
            maxCount: 6,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      _controller(tester).selection = const TextSelection.collapsed(offset: 2);
      await _paste(tester, 'XYZ');
      expect(_controller(tester).text, 'ABXYCD');
      expect(
        _controller(tester).selection,
        const TextSelection.collapsed(offset: 4),
      );
    },
  );

  testWidgets('paste replaces a backwards selection in grapheme units', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonTextArea(
          labelText: 'Note',
          initialValue: 'A😀BCD',
          maxCount: 5,
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    _controller(tester).selection = const TextSelection(
      baseOffset: 4,
      extentOffset: 1,
    );
    await _paste(tester, '🇸🇮XYZ');
    expect(_controller(tester).text, 'A🇸🇮XCD');
    expect(
      _controller(tester).selection,
      const TextSelection.collapsed(offset: 6),
    );
  });

  testWidgets(
    'a combining insertion keeps its base character and existing suffix',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            initialValue: 'eY',
            maxCount: 2,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      _controller(tester).selection = const TextSelection.collapsed(offset: 1);
      await _paste(tester, '\u0301X');
      expect(_controller(tester).text, 'e\u0301Y');
      expect(_controller(tester).selection.extentOffset, 2);
    },
  );

  for (final String existing in <String>['', 'AB']) {
    testWidgets(
      'composition starting in "$existing" stays intact until commit',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _host(
            CarbonTextArea(
              labelText: 'Note',
              initialValue: existing,
              maxCount: 2,
              enableCounter: true,
            ),
          ),
        );
        await tester.showKeyboard(find.byType(EditableText));
        _controller(tester).selection = TextSelection.collapsed(
          offset: existing.length,
        );
        for (final String composing in <String>['日本語', '日本語文']) {
          final TextEditingValue value = TextEditingValue(
            text: '$existing$composing',
            selection: TextSelection.collapsed(
              offset: existing.length + composing.length,
            ),
            composing: TextRange(
              start: existing.length,
              end: existing.length + composing.length,
            ),
          );
          await _edit(tester, value);
          expect(_controller(tester).value, value);
          expect(
            find.text('${value.text.characters.length}/2'),
            findsOneWidget,
          );
        }
        await _edit(
          tester,
          _controller(tester).value.copyWith(composing: TextRange.empty),
        );
        expect(_controller(tester).text, existing.isEmpty ? '日本' : 'AB');
        expect(_controller(tester).value.composing, TextRange.empty);
        expect(find.text('2/2'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'composition inserted in the middle preserves both surrounding sides',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            initialValue: 'ABCD',
            maxCount: 6,
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      _controller(tester).selection = const TextSelection.collapsed(offset: 2);
      const TextEditingValue composing = TextEditingValue(
        text: 'AB日本語CD',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 2, end: 5),
      );
      await _edit(tester, composing);
      expect(_controller(tester).value, composing);
      await _edit(tester, composing.copyWith(composing: TextRange.empty));
      expect(_controller(tester).text, 'AB日本CD');
      expect(_controller(tester).selection.extentOffset, 4);
    },
  );

  testWidgets(
    'character capacity and current grapheme length are on field semantics',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            const CarbonTextArea(
              labelText: 'Note',
              initialValue: '🇸🇮e\u0301',
              maxCount: 5,
              hideLabel: true,
              fluid: true,
            ),
          ),
        );
        final SemanticsNode field = tester.getSemantics(
          find.bySemanticsLabel('Note'),
        );
        expect(field.getSemanticsData().maxValueLength, 5);
        expect(field.getSemanticsData().currentValueLength, 2);
        await tester.enterText(find.byType(EditableText), '😀😀😀😀😀😀');
        await tester.pump();
        expect(field.getSemanticsData().currentValueLength, 5);
        expect(_controller(tester).text.characters.length, 5);
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets(
    'word limits count whitespace-separated words rather than characters',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(
          const CarbonTextArea(
            labelText: 'Note',
            maxCount: 2,
            enableCounter: true,
            counterMode: CarbonCounterMode.word,
          ),
        ),
      );
      await tester.enterText(
        find.byType(EditableText),
        '  first\tsecond\nthird',
      );
      await tester.pump();
      expect(_controller(tester).text, '  first\tsecond\n');
      expect(find.text('2/2'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'a veryLongSecondWord');
      await tester.pump();
      expect(_controller(tester).text, 'a veryLongSecondWord');
      expect(find.text('2/2'), findsOneWidget);
    },
  );

  testWidgets('word paste fills capacity while preserving surrounding words', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CarbonTextArea(
          labelText: 'Note',
          initialValue: 'one three',
          maxCount: 3,
          enableCounter: true,
          counterMode: CarbonCounterMode.word,
        ),
      ),
    );
    await tester.showKeyboard(find.byType(EditableText));
    _controller(tester).selection = const TextSelection.collapsed(offset: 4);
    await _paste(tester, 'two extra ');
    expect(_controller(tester).text, 'one two three');
    expect(find.text('3/3'), findsOneWidget);
  });

  testWidgets(
    'word capacity is announced without pretending it is a character cap',
    (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _host(
            const CarbonTextArea(
              labelText: 'Note',
              initialValue: 'one two',
              maxCount: 3,
              counterMode: CarbonCounterMode.word,
            ),
          ),
        );
        final SemanticsData field = tester
            .getSemantics(find.bySemanticsLabel('Note'))
            .getSemanticsData();
        expect(field.maxValueLength, isNull);
        expect(field.hint, contains('2 of 3 words'));
      } finally {
        handle.dispose();
      }
    },
  );

  testWidgets(
    'programmatic values and a smaller new limit are not rewritten on rebuild',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'abcdef',
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          CarbonTextArea(
            labelText: 'Note',
            controller: controller,
            maxCount: 8,
            enableCounter: true,
          ),
        ),
      );
      await tester.pumpWidget(
        _host(
          CarbonTextArea(
            labelText: 'Note',
            controller: controller,
            maxCount: 3,
            enableCounter: true,
          ),
        ),
      );
      expect(controller.text, 'abcdef');
      expect(find.text('6/3'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'abcdefg');
      await tester.pump();
      expect(controller.text, 'abc');
      expect(find.text('3/3'), findsOneWidget);
      controller.text = 'programmatic';
      await tester.pump();
      expect(controller.text, 'programmatic');
      expect(find.text('12/3'), findsOneWidget);
    },
  );

  testWidgets('zero capacity accepts only active composition', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const CarbonTextArea(labelText: 'Note', maxCount: 0)),
    );
    await tester.enterText(find.byType(EditableText), 'x');
    expect(_controller(tester).text, isEmpty);
    await _edit(
      tester,
      const TextEditingValue(
        text: '日',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      ),
    );
    expect(_controller(tester).text, '日');
    await _edit(
      tester,
      const TextEditingValue(
        text: '日',
        selection: TextSelection.collapsed(offset: 1),
      ),
    );
    expect(_controller(tester).text, isEmpty);
  });

  test('negative maxCount fails with a clear assertion', () {
    expect(
      () => CarbonTextArea(labelText: 'Note', maxCount: -1),
      throwsAssertionError,
    );
  });
}
