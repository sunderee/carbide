// Copyright 2026 Bizjak Tech OÜ
// Licensed under the Apache License, Version 2.0; see LICENSE.

/// Checks every capture batch against the reviewed authoritative pin.
///
/// This uses committed metadata and the parent gitlink, without a reference
/// checkout. Older retained animation images keep their actual capture version.
/// A pin change requires a new reference review even within the minor window.
void verifyReferenceFreshness({
  required Map<String, dynamic> pin,
  required Map<String, dynamic> manifest,
  required String gitlink,
  required Set<String> components,
}) {
  final String commit = pin['carbonCommit'] as String;
  if (!RegExp(r'^[a-f0-9]{40}$').hasMatch(commit) || commit != gitlink) {
    throw StateError(
      'Carbon gitlink differs from the authoritative reference pin.',
    );
  }
  final Map<String, dynamic> review =
      manifest['referenceReview'] as Map<String, dynamic>;
  if (review['carbonCommit'] != commit ||
      review['carbonReactVersion'] != pin['carbonReactVersion']) {
    throw StateError(
      'References have not been reviewed against the current Carbon pin.',
    );
  }
  if (review['reviewedAt'] is! String) {
    throw StateError('Reference review date is required.');
  }
  DateTime.parse(review['reviewedAt'] as String);
  _version(manifest['carbonReactVersion']);
  final (int major, int minor, int patch) current = _version(
    pin['carbonReactVersion'],
  );
  final int allowed = pin['maxCaptureMinorLag'] as int;
  if (allowed < 0 || allowed > 1) {
    throw StateError(
      'The supported capture window is zero or one minor release.',
    );
  }
  final Set<String> covered = <String>{};
  final List<dynamic> captures = manifest['captures'] as List<dynamic>;
  if (captures.isEmpty) throw StateError('No capture batches are recorded.');
  for (final dynamic item in captures) {
    final Map<String, dynamic> capture = item as Map<String, dynamic>;
    final (int major, int minor, int patch) captured = _version(
      capture['carbonReactVersion'],
    );
    if (captured.$1 != current.$1 ||
        current.$2 - captured.$2 < 0 ||
        current.$2 - captured.$2 > allowed) {
      throw StateError(
        'Capture ${capture['carbonReactVersion']} is outside the allowed window for ${pin['carbonReactVersion']}.',
      );
    }
    if (capture['capturedAt'] is! String ||
        capture['versionBasis'] is! String ||
        (capture['versionBasis'] as String).isEmpty) {
      throw StateError('Capture date and version provenance are required.');
    }
    DateTime.parse(capture['capturedAt'] as String);
    for (final dynamic name in capture['components'] as List<dynamic>) {
      if (!covered.add(name as String)) {
        throw StateError('Duplicate capture provenance for $name.');
      }
    }
  }
  if (covered.length != components.length || !covered.containsAll(components)) {
    throw StateError('Every curated component needs capture provenance.');
  }
}

(int major, int minor, int patch) _version(Object? value) {
  if (value is! String) throw StateError('Capture/pin version cannot be null.');
  final RegExpMatch? match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(value);
  if (match == null) throw StateError('Unsupported capture version: $value');
  return (int.parse(match[1]!), int.parse(match[2]!), int.parse(match[3]!));
}
