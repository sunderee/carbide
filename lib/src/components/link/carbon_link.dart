// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/link/_link.scss
//   react/src/components/Link/Link.tsx

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';
import '../../utils/native_link_semantics.dart';

/// The Carbon link sizes and their type styles.
enum CarbonLinkSize {
  /// 12px (`helper-text-01`).
  sm(CarbonTypeStyles.helperText01, 16),

  /// 14px (`body-compact-01`) — the default.
  md(CarbonTypeStyles.bodyCompact01, 16),

  /// 16px (`body-compact-02`), with 20px icons.
  lg(CarbonTypeStyles.bodyCompact02, 20);

  const CarbonLinkSize(this.style, this.iconSize);

  /// The label type style.
  final TextStyle style;

  /// The trailing icon size.
  final double iconSize;
}

/// A Carbon link.
///
/// ```dart
/// CarbonLink(label: 'Carbon guidelines', onPressed: open);
/// CarbonLink(label: 'visited', visited: true, onPressed: open);
/// ```
///
/// Standalone links underline on hover/focus/active; [inline] links (flowing
/// within text) are always underlined. [visited] renders the `linkVisited`
/// color (Flutter has no history, so visited state is the caller's). A null
/// [onPressed] renders the disabled state. Color transitions at `fast-01` ×
/// standard-productive, per the upstream transition.
class CarbonLink extends StatelessWidget {
  /// Creates a link.
  const CarbonLink({
    super.key,
    required this.label,
    this.onPressed,
    this.size = CarbonLinkSize.md,
    this.inline = false,
    this.visited = false,
    this.icon,
    this.focusNode,
    this.autofocus = false,
    this.maxLines,
    this.overflow,
  });

  /// The link text.
  final String label;

  /// Called on activation; null renders the disabled state.
  final VoidCallback? onPressed;

  /// The size; defaults to md.
  final CarbonLinkSize size;

  /// Whether the link flows inline in text (always underlined).
  final bool inline;

  /// Renders the visited color.
  final bool visited;

  /// Optional trailing icon (16px; 20px for lg) with an 8px gap.
  final CarbonIconData? icon;

  /// An optional focus node to control focus externally.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  /// An optional limit on label lines, such as one for a breadcrumb anchor.
  final int? maxLines;

  /// How a label that exceeds its available space is displayed.
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool enabled = onPressed != null;
    // The inner Text supplies the semantic label; this node adds the link
    // role and enabled state to the merged node.
    return _NativeLinkSemantics(
      enabled: enabled,
      focusNode: focusNode,
      child: Semantics(
        link: true,
        enabled: enabled,
        child: CarbonInteraction(
          enabled: enabled,
          onPressed: onPressed,
          focusNode: focusNode,
          autofocus: autofocus,
          builder: (BuildContext context, Set<WidgetState> states) {
            final bool hovered = states.contains(WidgetState.hovered);
            final bool focused = states.contains(WidgetState.focused);
            final bool pressed = states.contains(WidgetState.pressed);

            // Color resolution per _link.scss: active/focus keep the rest
            // color (even when visited); hover wins over visited.
            final Color color;
            if (!enabled) {
              color = theme.textDisabled;
            } else if (pressed || focused) {
              color = theme.linkPrimary;
            } else if (hovered) {
              color = theme.linkPrimaryHover;
            } else if (visited) {
              color = theme.linkVisited;
            } else {
              color = theme.linkPrimary;
            }

            // Underline: inline always (even disabled); standalone on
            // hover/focus/active only.
            final bool underlined =
                inline || (enabled && (hovered || focused || pressed));

            final TextStyle style = size.style.copyWith(
              color: color,
              decoration: underlined ? TextDecoration.underline : null,
              decorationColor: color,
            );

            final CarbonIconData? trailing = icon;
            Widget content = AnimatedDefaultTextStyle(
              duration: carbonDuration(context, CarbonDuration.fast01),
              curve: CarbonEasing.standardProductive,
              style: style,
              child: trailing == null
                  ? Text(label, maxLines: maxLines, overflow: overflow)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            label,
                            maxLines: maxLines,
                            overflow: overflow,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CarbonIcon(trailing, size: size.iconSize, color: color),
                      ],
                    ),
            );

            // focus-outline('border'): a 1px focus-colored outline on focus
            // and active states.
            if (enabled && (focused || pressed)) {
              content = DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.focus),
                ),
                child: content,
              );
            }
            return content;
          },
        ),
      ),
    );
  }
}

class _NativeLinkSemantics extends StatefulWidget {
  const _NativeLinkSemantics({
    required this.enabled,
    required this.child,
    this.focusNode,
  });
  final bool enabled;
  final Widget child;
  final FocusNode? focusNode;

  @override
  State<_NativeLinkSemantics> createState() => _NativeLinkSemanticsState();
}

class _NativeLinkSemanticsState extends State<_NativeLinkSemantics> {
  static int _nextId = 0;
  final String _identifier = 'carbide-link-${_nextId++}';

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_focusPolicyChanged);
  }

  @override
  void didUpdateWidget(_NativeLinkSemantics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_focusPolicyChanged);
      widget.focusNode?.addListener(_focusPolicyChanged);
    }
  }

  void _focusPolicyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_focusPolicyChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          syncNativeLinkSemantics(
            _identifier,
            enabled: widget.enabled,
            focusable:
                (widget.focusNode?.canRequestFocus ?? true) &&
                !(widget.focusNode?.skipTraversal ?? false),
          );
        }
      });
    }
    return Semantics(identifier: _identifier, child: widget.child);
  }
}
