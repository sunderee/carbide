// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'registry.dart';
import 'pages/foundations_pages.dart';
import 'pages/tier_a_pages.dart';
import 'pages/tier_b_pages.dart';
import 'pages/tier_c_pages.dart';
import 'pages/tier_d_pages.dart';

/// The full set of side-nav categories shown in the gallery.
final List<GalleryCategory> kCatalog = <GalleryCategory>[
  foundationsCategory,
  tierACategory,
  tierBCategory,
  tierCCategory,
  tierDCategory,
];
