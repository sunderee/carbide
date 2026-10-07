// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

import 'package:flutter/painting.dart';

/// Carbon's menu/list-box shadow with the active theme's [color].
///
/// Geometry follows `styles/scss/utilities/_box-shadow.scss`: `0 2px 6px`.
BoxShadow carbonMenuShadow(Color color) =>
    BoxShadow(color: color, offset: const Offset(0, 2), blurRadius: 6);
