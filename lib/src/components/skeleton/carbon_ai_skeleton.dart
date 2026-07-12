// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/skeleton-styles/_ai-skeleton-styles.scss
//   react/src/components/AISkeleton/*
//
// The AI skeletons: the `ai-skeleton-background` fill with a translating
// highlight band of `ai-skeleton-element-background` (alpha 0 → 0.5 → 0)
// sweeping left-to-right over 1250ms ease-in-out, infinitely. Reduced
// motion renders the static fill.

import 'package:flutter/widgets.dart';

import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';

/// AI skeleton text: the `SkeletonText` geometry on the AI shimmer.
class CarbonAISkeletonText extends StatelessWidget {
  /// Creates AI skeleton text.
  const CarbonAISkeletonText({
    super.key,
    this.heading = false,
    this.paragraph = false,
    this.lineCount = 3,
    this.width,
  });

  /// Renders the taller 24px heading line instead of the 16px body line.
  final bool heading;

  /// Renders [lineCount] lines instead of one.
  final bool paragraph;

  /// Number of lines when [paragraph] is set; defaults to 3 like upstream.
  final int lineCount;

  /// An optional fixed line width; defaults to filling the parent, with
  /// the last paragraph line shortened like the standard skeleton text.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final double line = heading ? 24 : 16;
    if (!paragraph) {
      return _AISkeletonBox(width: width, height: line);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < lineCount; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          FractionallySizedBox(
            widthFactor: width != null ? null : (i == lineCount - 1 ? 0.8 : 1),
            child: _AISkeletonBox(width: width, height: line),
          ),
        ],
      ],
    );
  }
}

/// An AI skeleton icon: a shimmering square, 16px by default.
class CarbonAISkeletonIcon extends StatelessWidget {
  /// Creates an AI skeleton icon.
  const CarbonAISkeletonIcon({super.key, this.size = 16});

  /// The icon edge length (spec default 16).
  final double size;

  @override
  Widget build(BuildContext context) =>
      _AISkeletonBox(width: size, height: size);
}

/// An AI skeleton placeholder: a shimmering rectangle, 100×100 by default.
class CarbonAISkeletonPlaceholder extends StatelessWidget {
  /// Creates an AI skeleton placeholder.
  const CarbonAISkeletonPlaceholder({
    super.key,
    this.width = 100,
    this.height = 100,
  });

  /// The placeholder width (spec default 100).
  final double width;

  /// The placeholder height (spec default 100).
  final double height;

  @override
  Widget build(BuildContext context) =>
      _AISkeletonBox(width: width, height: height);
}

/// The shared AI shimmer surface.
class _AISkeletonBox extends StatefulWidget {
  const _AISkeletonBox({required this.width, required this.height});

  final double? width;
  final double height;

  @override
  State<_AISkeletonBox> createState() => _AISkeletonBoxState();
}

class _AISkeletonBoxState extends State<_AISkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    // 1250ms ease-in-out, infinite (_ai-skeleton-styles.scss keyframes).
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reducedMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }

    final Color element = theme.aiSkeletonElementBackground;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.aiSkeletonBackground),
          child: reducedMotion
              ? const SizedBox.expand()
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (BuildContext context, Widget? child) {
                    // translateX(-100%) → translateX(100%), eased.
                    final double t = Curves.easeInOut.transform(
                      _controller.value,
                    );
                    return FractionalTranslation(
                      translation: Offset(-1 + 2 * t, 0),
                      child: child,
                    );
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          element.withValues(alpha: 0),
                          element.withValues(alpha: 0.5),
                          element.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
        ),
      ),
    );
  }
}
