// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// Builds the body widget for a gallery page.
typedef GalleryPageBuilder = Widget Function();

/// A single showcase page (one component or a tight family of them).
class GalleryEntry {
  /// Creates a catalog entry.
  const GalleryEntry({
    required this.slug,
    required this.title,
    required this.builder,
  });

  /// The URL-safe identifier; unique across the whole catalog.
  final String slug;

  /// The display name in the side nav and header.
  final String title;

  /// Builds the page body.
  final GalleryPageBuilder builder;

  /// The route path for this entry.
  String get path => '/components/$slug';
}

/// A side-nav group of related [GalleryEntry]s.
class GalleryCategory {
  /// Creates a side-nav category.
  const GalleryCategory({
    required this.title,
    required this.icon,
    required this.entries,
  });

  /// The group heading.
  final String title;

  /// The leading icon in the side nav.
  final CarbonIconData icon;

  /// The pages in this group.
  final List<GalleryEntry> entries;
}

/// Flattened view of every entry across [categories].
List<GalleryEntry> allEntries(List<GalleryCategory> categories) =>
    <GalleryEntry>[for (final GalleryCategory c in categories) ...c.entries];

/// Finds the entry whose [GalleryEntry.slug] matches [slug], or null.
GalleryEntry? entryForSlug(List<GalleryCategory> categories, String slug) {
  for (final GalleryEntry e in allEntries(categories)) {
    if (e.slug == slug) {
      return e;
    }
  }
  return null;
}
