// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/src/components/text_area/text_area_limit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _value(
  String text, {
  TextSelection? selection,
  TextRange? composing,
}) => TextEditingValue(
  text: text,
  selection: selection ?? TextSelection.collapsed(offset: text.length),
  composing: composing ?? TextRange.empty,
);

void main() {
  test('explicit commit recovers the original edit after composing metadata is cleared', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 6,
      words: false,
    );
    final TextEditingValue composing = _value(
      'AB日本語CD',
      selection: const TextSelection.collapsed(offset: 5),
      composing: const TextRange(start: 2, end: 5),
    );
    formatter.formatEditUpdate(
      _value('ABCD', selection: const TextSelection.collapsed(offset: 2)),
      composing,
    );
    final TextEditingValue result = formatter.commit(
      composing.copyWith(composing: TextRange.empty),
    );
    expect(result.text, 'AB日本CD');
    expect(result.selection.extentOffset, 4);
    expect(formatter.commit(result), result);
  });
  test(
    'selection-only changes during composition retain the pre-composition edit',
    () {
      final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
        maxCount: 6,
        words: false,
      );
      final TextEditingValue old = _value(
        'ABCD',
        selection: const TextSelection.collapsed(offset: 2),
      );
      final TextEditingValue composing = _value(
        'AB日本語CD',
        selection: const TextSelection.collapsed(offset: 5),
        composing: const TextRange(start: 2, end: 5),
      );
      formatter.formatEditUpdate(old, composing);
      final TextEditingValue selectionOnly = composing.copyWith(
        selection: const TextSelection.collapsed(offset: 0),
        composing: const TextRange(start: 2, end: 4),
      );
      final TextEditingValue result = formatter.formatEditUpdate(
        selectionOnly,
        selectionOnly.copyWith(composing: TextRange.empty),
      );
      expect(result.text, 'AB日本CD');
      expect(result.selection.extentOffset, 0);
    },
  );
  test('under-limit and unlimited values retain all editing metadata', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 3,
      words: false,
    );
    final TextEditingValue value = _value(
      '🇸🇮e\u0301',
      selection: const TextSelection(
        baseOffset: 6,
        extentOffset: 0,
        affinity: TextAffinity.upstream,
        isDirectional: true,
      ),
    );
    expect(
      formatter.formatEditUpdate(TextEditingValue.empty, value),
      same(value),
    );
    formatter.maxCount = null;
    final TextEditingValue long = _value('abcdefghijk');
    expect(formatter.formatEditUpdate(value, long), same(long));
  });

  test('truncation preserves reverse selection, direction and affinity', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 4,
      words: false,
    );
    final TextEditingValue old = _value(
      'AB',
      selection: const TextSelection.collapsed(offset: 1),
    );
    final TextEditingValue result = formatter.formatEditUpdate(
      old,
      _value(
        'AXYZWB',
        selection: const TextSelection(
          baseOffset: 6,
          extentOffset: 2,
          affinity: TextAffinity.upstream,
          isDirectional: true,
        ),
      ),
    );
    expect(result.text, 'AXYB');
    expect(
      result.selection,
      const TextSelection(
        baseOffset: 4,
        extentOffset: 2,
        affinity: TextAffinity.upstream,
        isDirectional: true,
      ),
    );
  });

  test('an unavailable selection remains unavailable after truncation', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 2,
      words: false,
    );
    final TextEditingValue result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'abcd'),
    );
    expect(result.text, 'ab');
    expect(result.selection, const TextSelection.collapsed(offset: -1));
  });

  test(
    'autocorrect replacing outside the selection retains the unaffected suffix',
    () {
      final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
        maxCount: 6,
        words: false,
      );
      final TextEditingValue result = formatter.formatEditUpdate(
        _value('foxEND'),
        _value(
          'elephantEND',
          selection: const TextSelection.collapsed(offset: 8),
        ),
      );
      expect(result.text, 'eleEND');
      expect(result.selection.extentOffset, 3);
    },
  );

  test('a common surrogate code unit does not become a split grapheme', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 2,
      words: false,
    );
    final TextEditingValue result = formatter.formatEditUpdate(
      _value('😀Z'),
      _value('😁😁Z', selection: const TextSelection.collapsed(offset: 4)),
    );
    expect(result.text, '😁Z');
    expect(result.selection.extentOffset, 2);
  });

  test('a ZWJ insertion keeps the joined grapheme intact', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 2,
      words: false,
    );
    final TextEditingValue result = formatter.formatEditUpdate(
      _value('👩Z', selection: const TextSelection.collapsed(offset: 2)),
      _value('👩‍👩XZ', selection: const TextSelection.collapsed(offset: 6)),
    );
    expect(result.text, '👩‍👩Z');
    expect(result.text.characters.length, 2);
    expect(result.selection.extentOffset, 5);
  });

  test(
    'an edit ending inside an original grapheme retains a complete cluster',
    () {
      final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
        maxCount: 1,
        words: false,
      );
      final TextEditingValue result = formatter.formatEditUpdate(
        _value('e\u0301', selection: const TextSelection.collapsed(offset: 1)),
        _value('eX\u0301', selection: const TextSelection.collapsed(offset: 2)),
      );
      expect(result.text, 'e');
      expect(result.text.characters.length, 1);
    },
  );

  test('thousands of edits preserve each original side and fill grapheme capacity', () {
    const List<String> oldClusters = <String>[
      'A',
      '🇸🇮',
      'e\u0301',
      '👩‍👩‍👧‍👧',
    ];
    const List<String> pasteClusters = <String>[
      '👍🏽',
      'X',
      '😀',
      'Z',
      '👩‍👩‍👧‍👧',
      'e\u0301',
    ];
    int cases = 0;
    for (int oldLength = 0; oldLength <= oldClusters.length; oldLength++) {
      final List<String> clusters = oldClusters.take(oldLength).toList();
      for (int start = 0; start <= oldLength; start++) {
        for (int end = start; end <= oldLength; end++) {
          for (
            int capacity = oldLength;
            capacity <= oldLength + 3;
            capacity++
          ) {
            for (int pasted = 0; pasted <= pasteClusters.length; pasted++) {
              for (final bool backwards in <bool>[false, true]) {
                final String prefix = clusters.take(start).join();
                final String suffix = clusters.skip(end).join();
                final String payload = pasteClusters.take(pasted).join();
                final int selectedEnd = clusters.take(end).join().length;
                final TextEditingValue old = _value(
                  clusters.join(),
                  selection: TextSelection(
                    baseOffset: backwards ? selectedEnd : prefix.length,
                    extentOffset: backwards ? prefix.length : selectedEnd,
                  ),
                );
                final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
                  maxCount: capacity,
                  words: false,
                );
                final TextEditingValue result = formatter.formatEditUpdate(
                  old,
                  _value(
                    prefix + payload + suffix,
                    selection: TextSelection.collapsed(
                      offset: prefix.length + payload.length,
                    ),
                  ),
                );
                final int available = capacity - start - (oldLength - end);
                final String retained = pasteClusters
                    .take(pasted)
                    .take(available)
                    .join();
                expect(
                  result.text,
                  prefix + retained + suffix,
                  reason:
                      'length=$oldLength selection=$start..$end max=$capacity pasted=$pasted backwards=$backwards',
                );
                expect(
                  result.selection.extentOffset,
                  prefix.length + retained.length,
                );
                expect(
                  result.text.characters.length,
                  lessThanOrEqualTo(capacity),
                );
                cases++;
              }
            }
          }
        }
      }
    }
    expect(cases, greaterThan(1000));
  });

  test(
    'composition replaces a selection and uses its original capacity on commit',
    () {
      final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
        maxCount: 4,
        words: false,
      );
      final TextEditingValue old = _value(
        'ABCD',
        selection: const TextSelection(baseOffset: 1, extentOffset: 3),
      );
      final TextEditingValue composing = _value(
        'A日本語D',
        selection: const TextSelection.collapsed(offset: 4),
        composing: const TextRange(start: 1, end: 4),
      );
      expect(formatter.formatEditUpdate(old, composing), same(composing));
      final TextEditingValue result = formatter.formatEditUpdate(
        composing,
        composing.copyWith(composing: TextRange.empty),
      );
      expect(result.text, 'A日本D');
      expect(result.selection.extentOffset, 3);
    },
  );

  test('a second composition does not retain the first snapshot', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 4,
      words: false,
    );
    final TextEditingValue first = _value(
      '日本語文',
      composing: const TextRange(start: 0, end: 4),
    );
    formatter.formatEditUpdate(TextEditingValue.empty, first);
    final TextEditingValue committed = formatter.formatEditUpdate(
      first,
      first.copyWith(composing: TextRange.empty),
    );
    final TextEditingValue selected = committed.copyWith(
      selection: const TextSelection(baseOffset: 1, extentOffset: 3),
    );
    final TextEditingValue second = _value(
      '日ABC文',
      selection: const TextSelection.collapsed(offset: 4),
      composing: const TextRange(start: 1, end: 4),
    );
    formatter.formatEditUpdate(selected, second);
    expect(
      formatter
          .formatEditUpdate(second, second.copyWith(composing: TextRange.empty))
          .text,
      '日AB文',
    );
  });

  test('programmatic replacement invalidates a stale composition snapshot', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 4,
      words: false,
    );
    final TextEditingValue composing = _value(
      '日本語文',
      composing: const TextRange(start: 0, end: 4),
    );
    formatter.formatEditUpdate(TextEditingValue.empty, composing);
    final TextEditingValue replacement = _value(
      'XY',
      selection: const TextSelection.collapsed(offset: 1),
    );
    final TextEditingValue result = formatter.formatEditUpdate(
      replacement,
      _value('XABCY', selection: const TextSelection.collapsed(offset: 4)),
    );
    expect(result.text, 'XABY');
  });

  test('a new limit during composition takes effect only at commit', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: null,
      words: false,
    );
    final TextEditingValue old = _value(
      'AB',
      selection: const TextSelection.collapsed(offset: 1),
    );
    final TextEditingValue composing = _value(
      'A日本語B',
      selection: const TextSelection.collapsed(offset: 4),
      composing: const TextRange(start: 1, end: 4),
    );
    formatter.formatEditUpdate(old, composing);
    formatter.maxCount = 3;
    final TextEditingValue ongoing = composing.copyWith(
      text: 'A日本語文B',
      selection: const TextSelection.collapsed(offset: 5),
      composing: const TextRange(start: 1, end: 5),
    );
    expect(formatter.formatEditUpdate(composing, ongoing), same(ongoing));
    expect(
      formatter
          .formatEditUpdate(
            ongoing,
            ongoing.copyWith(composing: TextRange.empty),
          )
          .text,
      'A日B',
    );
  });

  test('initial composition without a pre-edit snapshot still commits within capacity', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 2,
      words: false,
    );
    final TextEditingValue composing = _value(
      '日本語',
      composing: const TextRange(start: 0, end: 3),
    );
    final TextEditingValue result = formatter.formatEditUpdate(
      composing,
      composing.copyWith(composing: TextRange.empty),
    );
    expect(result.text, '日本');
    expect(result.composing, TextRange.empty);
  });

  test(
    'word boundaries include Unicode whitespace and leave long words intact',
    () {
      final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
        maxCount: 2,
        words: true,
      );
      final TextEditingValue result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _value('e\u0301\u00a0🇸🇮\u2003third'),
      );
      expect(result.text, 'e\u0301\u00a0🇸🇮\u2003');
      expect(countTextAreaText(result.text, words: true), 2);
      final String longWord = 'a' * 100000;
      final TextEditingValue longPaste = formatter.formatEditUpdate(
        TextEditingValue.empty,
        _value('$longWord another excess'),
      );
      expect(longPaste.text, '$longWord another ');
    },
  );

  test('word clipping never leaves an orphaned combining mark', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 1,
      words: true,
    );
    final TextEditingValue result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      _value('A \u0301B'),
    );
    expect(result.text, 'A');
    expect(result.text.characters.toList(), <String>['A']);
  });

  test('word composition stays intact and then enforces capacity around its suffix', () {
    final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
      maxCount: 3,
      words: true,
    );
    final TextEditingValue old = _value(
      'one three',
      selection: const TextSelection.collapsed(offset: 4),
    );
    final TextEditingValue composing = _value(
      'one two extra three',
      selection: const TextSelection.collapsed(offset: 14),
      composing: const TextRange(start: 4, end: 14),
    );
    expect(formatter.formatEditUpdate(old, composing), same(composing));
    expect(
      formatter
          .formatEditUpdate(
            composing,
            composing.copyWith(composing: TextRange.empty),
          )
          .text,
      'one two three',
    );
  });

  test(
    'word edits inside a word retain it and reject excess separated words',
    () {
      final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
        maxCount: 2,
        words: true,
      );
      final TextEditingValue result = formatter.formatEditUpdate(
        _value(
          'one other',
          selection: const TextSelection.collapsed(offset: 1),
        ),
        _value(
          'oXYZ new ne other',
          selection: const TextSelection.collapsed(offset: 9),
        ),
      );
      expect(result.text, 'one other');
      expect(countTextAreaText(result.text, words: true), 2);
      expect(
        formatter
            .formatEditUpdate(
              _value(
                'one other',
                selection: const TextSelection.collapsed(offset: 1),
              ),
              _value(
                'oXYZne other',
                selection: const TextSelection.collapsed(offset: 4),
              ),
            )
            .text,
        'oXYZne other',
      );
    },
  );

  test(
    'deletion from an over-limit programmatic value enforces the whole value',
    () {
      final TextAreaLimitFormatter formatter = TextAreaLimitFormatter(
        maxCount: 2,
        words: false,
      );
      for (final int offset in <int>[0, 1, 2, 3]) {
        final TextEditingValue old = _value(
          'ABCD',
          selection: TextSelection(
            baseOffset: offset,
            extentOffset: offset + 1,
          ),
        );
        final String shortened = old.text.replaceRange(offset, offset + 1, '');
        final TextEditingValue result = formatter.formatEditUpdate(
          old,
          _value(shortened, selection: TextSelection.collapsed(offset: offset)),
        );
        expect(result.text, shortened.substring(0, 2));
      }
    },
  );
}
