// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Font family names mirror the Carbon type system. The fonts themselves
// (IBM Plex, SIL OFL 1.1) are bundled by this package; see fonts/ and NOTICE.

/// Font families used by Carbon, bundled with this package.
///
/// Carbon uses IBM Plex Sans for interface text and IBM Plex Mono for code.
/// Only the weights Carbon relies on are bundled — Light (300), Regular (400),
/// and SemiBold (600). The names match the families declared in `pubspec.yaml`,
/// so they resolve to the bundled fonts without any additional configuration.
abstract final class CarbonFontFamily {
  /// IBM Plex Sans — the family used for all interface text.
  static const String sans = 'IBM Plex Sans';

  /// IBM Plex Mono — the family used for code and other monospaced text.
  static const String mono = 'IBM Plex Mono';

  /// IBM Plex Serif — used by the editorial `quotation` type styles.
  static const String serif = 'IBM Plex Serif';
}
