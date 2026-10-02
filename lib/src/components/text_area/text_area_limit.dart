// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

final RegExp _words = RegExp(r'\S+');
final RegExp _wordChunks = RegExp(r'\s+|\S+\s*');

/// Counts in the same unit used by the text-area counter and input limit.
int countTextAreaText(String text, {required bool words}) =>
    words ? _words.allMatches(text).length : text.characters.length;

/// Limits committed edits while retaining text outside the replacement.
///
/// Keep this formatter for the lifetime of the editor: its snapshot before
/// composition is needed to preserve the suffix when composition commits.
/// Programmatic controller updates never pass through an input formatter.
class TextAreaLimitFormatter extends TextInputFormatter {
  /// Creates an input limit; null leaves committed edits unlimited.
  TextAreaLimitFormatter({
    required this.maxCount,
    required this.words,
    this.resolveComposition,
  });

  /// The current capacity, updated when the widget's properties change.
  int? maxCount;

  /// Whether the capacity counts whitespace-separated words.
  bool words;

  /// An optional native bridge for SDK input paths missing composing ranges.
  final TextEditingValue Function(TextEditingValue)? resolveComposition;

  TextEditingValue? _compositionBase;
  TextEditingValue? _lastComposing;

  /// Commits a known composition even if blur already cleared its metadata.
  TextEditingValue commit(TextEditingValue value) => formatEditUpdate(
    _lastComposing?.text == value.text ? _lastComposing! : value,
    value.copyWith(composing: TextRange.empty),
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    newValue = resolveComposition?.call(newValue) ?? newValue;
    // Selection and composing-range-only updates can bypass formatters. Keep
    // the snapshot when that metadata changes within the same composing text.
    final bool continuing =
        _lastComposing != null &&
        oldValue.text == _lastComposing!.text &&
        oldValue.composing.isValid &&
        !oldValue.composing.isCollapsed;
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      if (!continuing) {
        _compositionBase = oldValue;
      }
      _lastComposing = newValue;
      return newValue;
    }
    final TextEditingValue base = continuing
        ? _compositionBase ?? oldValue
        : oldValue;
    _compositionBase = null;
    _lastComposing = null;
    final int? limit = maxCount;
    if (limit == null ||
        countTextAreaText(newValue.text, words: words) <= limit) {
      return newValue;
    }

    // First locate the replacement using the pre-edit selection. Autocorrect,
    // undo and some IMEs replace a different range: use the common edges then.
    TextRange replacement = _replacement(base, newValue.text);
    String prefix = newValue.text.substring(0, replacement.start);
    String suffix = newValue.text.substring(replacement.end);
    if (countTextAreaText(prefix + suffix, words: words) > limit) {
      // An initial/programmatic over-limit value or a lowered limit may leave
      // no capacity outside the edit. Enforce the next committed edit as a whole.
      replacement = TextRange(start: 0, end: newValue.text.length);
      prefix = '';
      suffix = '';
    }
    final String inserted = newValue.text.substring(
      replacement.start,
      replacement.end,
    );
    final int accepted = words
        ? _wordPrefixLength(prefix, inserted, suffix, limit)
        : inserted.characters
              .take(
                math.max(
                  0,
                  limit - prefix.characters.length - suffix.characters.length,
                ),
              )
              .toString()
              .length;
    final int cutStart = replacement.start + accepted;
    final int cutEnd = replacement.end;
    int mapOffset(int offset) => offset <= cutStart
        ? offset
        : offset < cutEnd
        ? cutStart
        : offset - (cutEnd - cutStart);
    return newValue.copyWith(
      text: newValue.text.replaceRange(cutStart, cutEnd, ''),
      selection: newValue.selection.copyWith(
        baseOffset: mapOffset(newValue.selection.baseOffset),
        extentOffset: mapOffset(newValue.selection.extentOffset),
      ),
      composing: TextRange.empty,
    );
  }

  static TextRange _replacement(TextEditingValue oldValue, String text) {
    final TextSelection selection = oldValue.selection;
    int start;
    int end;
    if (selection.isValid &&
        selection.end <= oldValue.text.length &&
        text.length >=
            oldValue.text.length - (selection.end - selection.start) &&
        text.startsWith(oldValue.text.substring(0, selection.start)) &&
        text.endsWith(oldValue.text.substring(selection.end))) {
      start = selection.start;
      end = text.length - (oldValue.text.length - selection.end);
    } else {
      start = 0;
      final int commonLength = math.min(oldValue.text.length, text.length);
      while (start < commonLength &&
          oldValue.text.codeUnitAt(start) == text.codeUnitAt(start)) {
        start++;
      }
      int suffixLength = 0;
      while (suffixLength < commonLength - start &&
          oldValue.text.codeUnitAt(oldValue.text.length - suffixLength - 1) ==
              text.codeUnitAt(text.length - suffixLength - 1)) {
        suffixLength++;
      }
      end = text.length - suffixLength;
    }

    // The edit can join graphemes across either edge (a combining mark or ZWJ,
    // for example). Include the entire affected cluster before truncating.
    int offset = 0;
    int safeStart = 0;
    int safeEnd = text.length;
    if (end == 0) {
      return const TextRange(start: 0, end: 0);
    }
    for (final String cluster in text.characters) {
      offset += cluster.length;
      if (offset <= start) {
        safeStart = offset;
      }
      if (offset >= end) {
        safeEnd = offset;
        break;
      }
    }
    return TextRange(start: safeStart, end: safeEnd);
  }

  static int _wordPrefixLength(
    String prefix,
    String inserted,
    String suffix,
    int limit,
  ) {
    int count = _words.allMatches(prefix).length;
    bool inWord =
        prefix.isNotEmpty &&
        _words.hasMatch(prefix.substring(prefix.length - 1));
    final int suffixCount = _words.allMatches(suffix).length;
    final bool suffixStartsWord =
        suffix.isNotEmpty && _words.hasMatch(suffix.substring(0, 1));
    int accepted = 0;
    // Include each word's following whitespace. Testing a partial word without
    // that separator would join it to the suffix and falsely create capacity.
    // Scan chunks once so a very long pasted word does not cause quadratic work.
    for (final RegExpMatch chunk in _wordChunks.allMatches(inserted)) {
      final Iterable<RegExpMatch> chunkWords = _words.allMatches(
        chunk.group(0)!,
      );
      final int nextCount =
          count +
          chunkWords.length -
          (inWord && chunkWords.isNotEmpty && chunkWords.first.start == 0
              ? 1
              : 0);
      final bool endsWord =
          chunkWords.isNotEmpty &&
          chunkWords.last.end == chunk.group(0)!.length;
      if (nextCount + suffixCount - (endsWord && suffixStartsWord ? 1 : 0) >
          limit) {
        break;
      }
      count = nextCount;
      inWord = endsWord;
      accepted = chunk.end;
    }
    // Whitespace plus a combining mark can itself be a grapheme. A word
    // boundary must never cut that cluster in half.
    int safeLength = 0;
    for (final String cluster in inserted.characters) {
      if (safeLength + cluster.length > accepted) {
        break;
      }
      safeLength += cluster.length;
    }
    return safeLength;
  }
}
