// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

/// Enforces the line-coverage floor from an lcov trace file.
///
/// Reads `coverage/lcov.info` (produced by `flutter test --coverage`),
/// excludes the generated icon/pictogram registries so the denominator is
/// honest, prints a per-file table of everything under the floor, and exits
/// non-zero when total line coverage drops below the floor.
///
/// When `GITHUB_STEP_SUMMARY` is set, a Markdown summary is appended so the
/// percentage is visible on the workflow run page.
///
/// Usage: `dart run tool/coverage_gate.dart [--floor 90] [--lcov <path>]`
library;

import 'dart:io';

/// Path prefixes excluded from the gate (generated code).
///
/// These are const-only registries that currently emit no `DA:` lines at
/// all, but the exclusion is kept so a future codegen change cannot skew
/// the denominator silently.
const List<String> excludedPrefixes = <String>[
  'lib/src/icons/generated/',
  'lib/src/pictograms/generated/',
];

void main(List<String> args) {
  double floor = 90;
  String lcovPath = 'coverage/lcov.info';
  for (int i = 0; i < args.length - 1; i++) {
    if (args[i] == '--floor') floor = double.parse(args[i + 1]);
    if (args[i] == '--lcov') lcovPath = args[i + 1];
  }

  final File lcov = File(lcovPath);
  if (!lcov.existsSync()) {
    stderr.writeln('coverage_gate: $lcovPath not found — run '
        '`flutter test --coverage` first.');
    exit(2);
  }

  final Map<String, ({int lines, int hit})> files = _parse(lcov);
  int totalLines = 0;
  int totalHit = 0;
  final List<String> tail = <String>[];
  final List<String> sorted = files.keys.toList()..sort();
  for (final String file in sorted) {
    final ({int lines, int hit}) c = files[file]!;
    totalLines += c.lines;
    totalHit += c.hit;
    final double pct = 100 * c.hit / c.lines;
    if (pct < floor) {
      tail.add('${pct.toStringAsFixed(1).padLeft(5)}%  $file '
          '(${c.hit}/${c.lines})');
    }
  }

  final double total = 100 * totalHit / totalLines;
  final String verdict = total >= floor ? 'PASS' : 'FAIL';
  final StringBuffer out = StringBuffer()
    ..writeln('Line coverage: ${total.toStringAsFixed(1)}% '
        '($totalHit/$totalLines lines, ${files.length} files, '
        'generated registries excluded)')
    ..writeln('Floor: ${floor.toStringAsFixed(1)}% — $verdict');
  if (tail.isNotEmpty) {
    out.writeln('\nFiles under the floor (informational):');
    tail.forEach(out.writeln);
  }
  stdout.write(out);

  final String? summaryPath = Platform.environment['GITHUB_STEP_SUMMARY'];
  if (summaryPath != null) {
    File(summaryPath).writeAsStringSync(
      '### Coverage: ${total.toStringAsFixed(1)}% '
      '(floor ${floor.toStringAsFixed(0)}% — $verdict)\n\n'
      '```\n$out```\n',
      mode: FileMode.append,
    );
  }

  if (total < floor) {
    stderr.writeln('coverage_gate: total line coverage '
        '${total.toStringAsFixed(1)}% is below the '
        '${floor.toStringAsFixed(1)}% floor.');
    exit(1);
  }
}

Map<String, ({int lines, int hit})> _parse(File lcov) {
  final Map<String, ({int lines, int hit})> files =
      <String, ({int lines, int hit})>{};
  String? current;
  int lines = 0;
  int hit = 0;
  void flush() {
    final String? file = current;
    if (file != null &&
        lines > 0 &&
        !excludedPrefixes.any(file.startsWith)) {
      files[file] = (lines: lines, hit: hit);
    }
    current = null;
    lines = 0;
    hit = 0;
  }

  for (final String line in lcov.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      flush();
      current = line.substring(3).replaceAll(r'\', '/');
    } else if (line.startsWith('DA:')) {
      lines++;
      if (int.parse(line.substring(3).split(',')[1]) > 0) hit++;
    } else if (line == 'end_of_record') {
      flush();
    }
  }
  flush();
  return files;
}
