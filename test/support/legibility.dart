// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Assertions that a widget is not just *present* but actually *rendered
// legibly*. `find.text('2')` passing only proves the widget exists in the
// tree; a fixed-height or over-padded ancestor can still squeeze the glyphs
// into an unreadable sliver (and a self-referential golden will happily lock
// that in). These helpers close that gap.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts the [Text] found by [finder] is not vertically clipped: its
/// laid-out height is at least the line height implied by its style.
///
/// A squished badge (e.g. a 24px pill padded to an 8px content box) clamps the
/// glyph box below its line height; this catches that without needing a human
/// to eyeball a low-resolution golden.
void expectTextNotClipped(
  WidgetTester tester,
  Finder finder, {
  double slack = 0.5,
}) {
  final Text text = tester.widget<Text>(finder);
  final Size rendered = tester.getSize(finder);
  final TextStyle? style = text.style;
  final double fontSize = style?.fontSize ?? 14;
  final double lineHeight = fontSize * (style?.height ?? 1.0);
  expect(
    rendered.height,
    greaterThanOrEqualTo(lineHeight - slack),
    reason:
        'Text "${text.data}" is clipped: the glyph box rendered '
        '${rendered.height.toStringAsFixed(2)}px tall but its line box needs '
        '${lineHeight.toStringAsFixed(2)}px. A parent is constraining it below '
        'its line height.',
  );
}

/// Asserts the widget found by [finder] fits inside the widget found by
/// [within] — i.e. it is not overflowing (and therefore being clipped or
/// painting outside) its container.
void expectFitsWithin(
  WidgetTester tester,
  Finder finder, {
  required Finder within,
  double slack = 0.5,
}) {
  final Rect inner = tester.getRect(finder);
  final Rect outer = tester.getRect(within);
  expect(
    inner.height,
    lessThanOrEqualTo(outer.height + slack),
    reason:
        'Widget overflows its container vertically '
        '(${inner.height.toStringAsFixed(2)} > ${outer.height.toStringAsFixed(2)}).',
  );
  expect(
    inner.width,
    lessThanOrEqualTo(outer.width + slack),
    reason:
        'Widget overflows its container horizontally '
        '(${inner.width.toStringAsFixed(2)} > ${outer.width.toStringAsFixed(2)}).',
  );
}

/// Asserts every visible [Text] and [EditableText] renders at least one full line
/// box at [scale] — the text-scaling analogue of [expectTextNotClipped].
///
/// Texts that opt into ellipsis/fade with `maxLines` still keep their first
/// line's height, so they pass; a fixed-height ancestor that squeezes the
/// glyph box below one scaled line is exactly the clipping this catches.
void expectNoClippedTextAtScale(
  WidgetTester tester,
  double scale, {
  double slack = 0.5,
}) {
  for (final Element element in find.byType(Text).evaluate()) {
    final Text text = element.widget as Text;
    final String? data = text.data ?? text.textSpan?.toPlainText();
    if (data == null || data.trim().isEmpty) {
      continue;
    }
    final Size rendered = element.size ?? Size.zero;
    if (rendered == Size.zero) {
      continue;
    }
    // Resolve inherited styles, actual fonts and the effective scaler rather
    // than assuming an unstyled Text has a 14px/1.0 line box. That assumption
    // misses the list-box value inherited from DefaultTextStyle.
    final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byElementPredicate(
              (Element candidate) => candidate == element,
            ),
            matching: find.byType(RichText),
          )
          .first,
    );
    expect(
      paragraph.textScaler.scale(1),
      closeTo(scale, 0.001),
      reason: 'Text "$data" must retain the requested system text scale.',
    );
    final TextPainter painter = TextPainter(
      text: paragraph.text,
      textDirection: paragraph.textDirection,
      textScaler: paragraph.textScaler,
      strutStyle: paragraph.strutStyle,
      textHeightBehavior: paragraph.textHeightBehavior,
      maxLines: 1,
    )..layout();
    final double lineHeight = painter.preferredLineHeight;
    painter.dispose();
    expect(
      rendered.height,
      greaterThanOrEqualTo(lineHeight - slack),
      reason:
          'Text "$data" is clipped at ${scale}x scale: rendered '
          '${rendered.height.toStringAsFixed(2)}px tall but one scaled line '
          'needs ${lineHeight.toStringAsFixed(2)}px.',
    );
  }
  // Editors can retain all their text and scroll internally while a fixed
  // ancestor clips a whole line vertically. Text-only sweeps miss this case.
  for (final Element element in find.byType(EditableText).evaluate()) {
    final EditableTextState state =
        (element as StatefulElement).state as EditableTextState;
    final RenderEditable editable = state.renderEditable;
    if (editable.size == Size.zero) {
      continue;
    }
    expect(
      editable.textScaler.scale(1),
      closeTo(scale, 0.001),
      reason: 'EditableText must retain the requested system text scale.',
    );
    expect(
      editable.size.height,
      greaterThanOrEqualTo(editable.preferredLineHeight - slack),
      reason:
          'EditableText is clipped at ${scale}x scale: rendered '
          '${editable.size.height.toStringAsFixed(2)}px tall but one scaled '
          'line needs ${editable.preferredLineHeight.toStringAsFixed(2)}px.',
    );
  }
}
