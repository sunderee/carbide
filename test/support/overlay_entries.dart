// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.

/// Test-host [OverlayEntry]s with their disposal registered up front.
///
/// Flutter's contract makes the creator of an [OverlayEntry] responsible
/// for disposing it — an `Overlay` does not dispose its `initialEntries`.
/// Every inline host that built a bare entry therefore leaked it under
/// the suite-wide leak tracking (#234); building through this helper ties
/// the entry's lifetime to the enclosing test instead.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates an [OverlayEntry] whose `dispose` runs in the test's teardown.
///
/// Call only from within a running test (any host builder invoked by
/// `pumpWidget` qualifies — `addTearDown` needs the test context).
OverlayEntry managedOverlayEntry({required WidgetBuilder builder}) {
  final OverlayEntry entry = OverlayEntry(builder: builder);
  addTearDown(() {
    // Two teardown paths exist and OverlayEntry exposes no probe to
    // tell them apart: end-of-test deflation leaves the entry attached
    // (remove() required before dispose()), while replacing the host
    // mid-test disposes the old Overlay, which already detached it
    // (remove() would then assert "removed only once").
    try {
      entry.remove();
    } on AssertionError {
      // Already detached by the Overlay's own disposal.
    }
    entry.dispose();
  });
  return entry;
}
