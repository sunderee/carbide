// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0; see LICENSE.

import 'dart:convert';
import 'dart:io';

import '../test/fidelity/support/freshness.dart';

/// Verifies committed capture provenance without cloning Carbon.
void main() {
  final ProcessResult git = Process.runSync('git', <String>[
    'ls-tree',
    'HEAD',
    'documentation/carbon',
  ]);
  if (git.exitCode != 0) throw StateError('Could not read the Carbon gitlink.');
  final List<String> fields = (git.stdout as String).trim().split(
    RegExp(r'\s+'),
  );
  if (fields.length < 3 || fields.first != '160000') {
    throw StateError('Carbon gitlink is missing.');
  }
  final Map<String, dynamic> pin = jsonDecode(
    File('tool/carbon_reference.lock.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, dynamic> manifest = jsonDecode(
    File('test/fidelity/references/manifest.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final Map<String, dynamic> stories = jsonDecode(
    File('tool/fidelity/stories.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  verifyReferenceFreshness(
    pin: pin,
    manifest: manifest,
    gitlink: fields[2],
    components: <String>{
      for (final dynamic story in stories['stories'] as List<dynamic>)
        (story as Map<String, dynamic>)['component'] as String,
    },
  );
  stdout.writeln(
    'Reference freshness passes: every capture is versioned and reviewed against ${pin['carbonReactVersion']} / ${fields[2]}.',
  );
}
