// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Stops modal gestures from reaching an enclosing page scrollable. Descendant
/// scrollables resolve wheel signals and win drag arenas before this boundary,
/// so dialog bodies remain scrollable, including at their scroll limits.
class CarbonModalBackgroundLock extends StatelessWidget {
  /// Creates a boundary retained throughout a modal exit.
  const CarbonModalBackgroundLock({required this.child, super.key});

  /// The backdrop and dialog surface.
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onVerticalDragUpdate: (_) {},
        onHorizontalDragUpdate: (_) {},
        child: child,
      ),
    ),
  );
}
