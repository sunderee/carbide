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
/// and [package] supplies Flutter's dependency font namespace. Built-in Carbon
/// styles supply it automatically. Custom styles should supply both values:
///
/// ```dart
/// const TextStyle(
///   fontFamily: CarbonFontFamily.mono,
///   package: CarbonFontFamily.package,
/// )
/// ```
abstract final class CarbonFontFamily {
  /// The package that declares and bundles the Plex font assets.
  static const String package = 'carbide';

  /// IBM Plex Sans — the family used for all interface text.
  static const String sans = 'IBM Plex Sans';

  /// IBM Plex Mono — the family used for code and other monospaced text.
  static const String mono = 'IBM Plex Mono';

  /// IBM Plex Serif — used by the editorial `quotation` type styles.
  static const String serif = 'IBM Plex Serif';
}
