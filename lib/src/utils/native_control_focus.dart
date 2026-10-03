// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.

export 'native_control_focus_stub.dart'
    if (dart.library.js_interop) 'native_control_focus_web.dart';
