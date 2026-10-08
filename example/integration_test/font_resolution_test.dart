// Copyright 2026 Bizjak Tech OÜ

import 'dart:convert';

import 'package:carbide/carbide.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/failure_diagnostics.dart';

void main() {
  retainIntegrationFailureDetails(
    IntegrationTestWidgetsFlutterBinding.ensureInitialized(),
  );
  testWidgets(
    'consumer styles render the bundled Sans, Mono and Serif glyphs',
    (WidgetTester tester) async {
      // No FontLoader or test font aliases: this is an ordinary consuming app.
      final List<dynamic> manifest = jsonDecode(
        await rootBundle.loadString('FontManifest.json'),
      ) as List<dynamic>;
      final Set<String> families = <String>{
        for (final dynamic entry in manifest)
          (entry as Map<String, dynamic>)['family'] as String,
      };
      for (final (TextStyle, String) sample in <(TextStyle, String)>[
        (CarbonTypeStyles.body01, 'IBMPlexSans-Regular.ttf'),
        (CarbonTypeStyles.code01, 'IBMPlexMono-Regular.ttf'),
        (CarbonFluidTypeStyles.quotation01.base, 'IBMPlexSerif-Regular.ttf'),
      ]) {
        final TextStyle style = sample.$1.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1,
        );
        expect(families, contains(style.fontFamily));
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: Text('MW', style: style)),
          ),
        );
        await tester.pumpAndSettle();
        final ByteData font = await rootBundle.load(
          'packages/carbide/fonts/${sample.$2}',
        );
        for (final int code in <int>[77, 87]) {
          final TextPainter painter = TextPainter(
            text: TextSpan(text: String.fromCharCode(code), style: style),
            textDirection: TextDirection.ltr,
          )..layout();
          try {
            expect(
              painter.width,
              closeTo(_advance(font, code) * 20, .05),
              reason:
                  '${sample.$2} glyph ${String.fromCharCode(code)} must use '
                  'the font asset metrics, not a platform fallback',
            );
          } finally {
            painter.dispose();
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

// A focused independent reader for the bundled TTFs' format-4 ASCII cmap and
// horizontal advances. It neither imports the type generator nor guesses the
// expected widths from another Flutter TextPainter.
double _advance(ByteData font, int code) {
  int table(String name) {
    for (int i = 0; i < font.getUint16(4); i++) {
      final int entry = 12 + i * 16;
      final String tag = String.fromCharCodes(<int>[
        for (int j = 0; j < 4; j++) font.getUint8(entry + j),
      ]);
      if (tag == name) return font.getUint32(entry + 8);
    }
    throw StateError('Missing TTF $name table');
  }

  final int cmap = table('cmap');
  int? glyph;
  for (int record = 0; record < font.getUint16(cmap + 2); record++) {
    final int sub = cmap + font.getUint32(cmap + 4 + record * 8 + 4);
    if (font.getUint16(sub) != 4) continue;
    final int count = font.getUint16(sub + 6) ~/ 2;
    final int ends = sub + 14;
    final int starts = ends + count * 2 + 2;
    final int deltas = starts + count * 2;
    final int offsets = deltas + count * 2;
    for (int i = 0; i < count; i++) {
      final int start = font.getUint16(starts + i * 2);
      if (code < start || code > font.getUint16(ends + i * 2)) continue;
      final int delta = font.getInt16(deltas + i * 2);
      final int range = font.getUint16(offsets + i * 2);
      if (range == 0) {
        glyph = (code + delta) & 0xffff;
      } else {
        glyph = font.getUint16(offsets + i * 2 + range + (code - start) * 2);
        if (glyph != 0) glyph = (glyph + delta) & 0xffff;
      }
      break;
    }
    if (glyph != null && glyph != 0) break;
  }
  if (glyph == null || glyph == 0) throw StateError('Missing glyph $code');
  final int metrics = font.getUint16(table('hhea') + 34);
  final int index = glyph < metrics ? glyph : metrics - 1;
  return font.getUint16(table('hmtx') + index * 4) /
      font.getUint16(table('head') + 18);
}
