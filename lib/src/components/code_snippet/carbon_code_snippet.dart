// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/code-snippet/_code-snippet.scss
//   react/src/components/CodeSnippet/CodeSnippet.tsx
//
// CodeSnippet shows monospaced code in three forms: an inline chip, a
// single-line bar, and a multi-line block with show-more/less. Copying reuses
// CarbonCopyButton (single/multi) or an inline copy chip with the same
// feedback. There is no syntax-highlighting token dependency — the snippet is
// plain code-01 mono text on the contextual layer surface.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/control_semantics.dart';
import '../../utils/control_state.dart';
import '../../utils/focus_ring.dart';
import '../copy_button/carbon_copy_button.dart';
import '../popover/carbon_popover.dart';
import '../skeleton/carbon_skeleton_text.dart';

/// The presentation of a [CarbonCodeSnippet].
enum CarbonCodeSnippetType {
  /// A compact chip for code referenced within prose.
  inline,

  /// A single-line bar with horizontal overflow.
  single,

  /// A multi-line block with optional show-more/less.
  multi,
}

/// Displays monospaced code with a copy affordance.
///
/// [type] selects the inline chip, single-line bar, or multi-line block. For
/// [CarbonCodeSnippetType.multi], code taller than [maxCollapsedRows] rows
/// collapses behind a show-more/less toggle; [wrapText] wraps long lines
/// instead of scrolling them.
///
/// Code remains accessible text, with separate copy and expand actions. A
/// copyable inline snippet exposes the code in its button label. Applications
/// can wrap important standalone blocks in a named [Semantics] region with
/// `explicitChildNodes: true` to preserve the content and controls.
///
/// ```dart
/// CarbonCodeSnippet(code: 'flutter pub add carbide')
/// ```
class CarbonCodeSnippet extends StatefulWidget {
  /// Creates a code snippet.
  const CarbonCodeSnippet({
    required this.code,
    super.key,
    this.type = CarbonCodeSnippetType.single,
    this.feedback = 'Copied!',
    this.feedbackTimeout = const Duration(milliseconds: 2000),
    this.hideCopyButton = false,
    this.disabled = false,
    this.wrapText = false,
    this.maxCollapsedRows = 15,
    this.maxExpandedRows = 0,
    this.showMoreText = 'Show more',
    this.showLessText = 'Show less',
    this.copyLabel = 'Copy to clipboard',
    this.onCopy,
  });

  /// The code to display and copy.
  final String code;

  /// The snippet presentation.
  final CarbonCodeSnippetType type;

  /// The message shown after copying.
  final String feedback;

  /// How long the copy feedback stays.
  final Duration feedbackTimeout;

  /// Whether to omit the copy affordance.
  final bool hideCopyButton;

  /// Whether the snippet is disabled (single and multi only).
  final bool disabled;

  /// Whether multi-line code wraps instead of scrolling horizontally.
  final bool wrapText;

  /// Rows shown before a multi-line snippet collapses (16px each).
  final int maxCollapsedRows;

  /// Rows shown when expanded; 0 means unbounded.
  final int maxExpandedRows;

  /// The expand toggle label when collapsed.
  final String showMoreText;

  /// The expand toggle label when expanded.
  final String showLessText;

  /// The accessible label for the copy affordance.
  final String copyLabel;

  /// Called after the code is copied.
  final VoidCallback? onCopy;

  /// The pixel height of one code row (Carbon's `rowHeightInPixels`).
  static const double rowHeight = 16;

  @override
  State<CarbonCodeSnippet> createState() => _CarbonCodeSnippetState();
}

class _CarbonCodeSnippetState extends State<CarbonCodeSnippet> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return switch (widget.type) {
      CarbonCodeSnippetType.inline => _InlineSnippet(
        code: widget.code,
        feedback: widget.feedback,
        feedbackTimeout: widget.feedbackTimeout,
        copyable: !widget.hideCopyButton,
        copyLabel: widget.copyLabel,
        onCopy: widget.onCopy,
      ),
      CarbonCodeSnippetType.single => _buildSingle(context),
      CarbonCodeSnippetType.multi => _buildMulti(context),
    };
  }

  TextStyle _codeStyle(CarbonThemeData theme) =>
      CarbonTypeStyles.code01.copyWith(
        color: widget.disabled ? theme.textDisabled : theme.textPrimary,
      );

  Widget _copyButton(CarbonCopySize size) => CarbonCopyButton(
    value: widget.code,
    size: size,
    enabled: !widget.disabled,
    iconDescription: widget.copyLabel,
    feedback: widget.feedback,
    feedbackTimeout: widget.feedbackTimeout,
    onCopy: widget.onCopy,
  );

  Widget _buildSingle(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return ColoredBox(
      color: layer.layer,
      child: SizedBox(
        height: CarbonSpacing.spacing08,
        child: Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  height: CarbonSpacing.spacing08,
                  alignment: AlignmentDirectional.centerStart,
                  // padding-inline-start spacing-05, pre padding-inline-end
                  // spacing-07.
                  padding: const EdgeInsetsDirectional.only(
                    start: CarbonSpacing.spacing05,
                    end: CarbonSpacing.spacing07,
                  ),
                  child: Text(
                    widget.code,
                    maxLines: 1,
                    softWrap: false,
                    style: _codeStyle(theme),
                  ),
                ),
              ),
            ),
            if (!widget.hideCopyButton) _copyButton(CarbonCopySize.md),
          ],
        ),
      ),
    );
  }

  Widget _buildMulti(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final int lines = '\n'.allMatches(widget.code).length + 1;
    final bool overflows = lines > widget.maxCollapsedRows;
    final double collapsedHeight =
        widget.maxCollapsedRows * CarbonCodeSnippet.rowHeight;
    final double? expandedHeight = widget.maxExpandedRows > 0
        ? widget.maxExpandedRows * CarbonCodeSnippet.rowHeight
        : null;

    Widget code = Text(
      widget.code,
      softWrap: widget.wrapText,
      style: _codeStyle(theme),
    );
    if (!widget.wrapText) {
      code = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: code,
      );
    }
    if (overflows) {
      final double? height = _expanded ? expandedHeight : collapsedHeight;
      if (height != null) {
        code = SizedBox(
          height: height,
          child: SingleChildScrollView(child: code),
        );
      }
    }

    return ColoredBox(
      color: layer.layer,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(CarbonSpacing.spacing05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                code,
                if (overflows)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: CarbonSpacing.spacing03,
                    ),
                    child: _ExpandButton(
                      expanded: _expanded,
                      showMoreText: widget.showMoreText,
                      showLessText: widget.showLessText,
                      onTap: () => setState(() => _expanded = !_expanded),
                    ),
                  ),
              ],
            ),
          ),
          if (!widget.hideCopyButton)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: _copyButton(CarbonCopySize.sm),
            ),
        ],
      ),
    );
  }
}

/// The inline code chip: copies its [code] on tap with the same feedback bubble
/// as [CarbonCopyButton].
class _InlineSnippet extends StatefulWidget {
  const _InlineSnippet({
    required this.code,
    required this.feedback,
    required this.feedbackTimeout,
    required this.copyable,
    required this.copyLabel,
    required this.onCopy,
  });

  final String code;
  final String feedback;
  final Duration feedbackTimeout;
  final bool copyable;
  final String copyLabel;
  final VoidCallback? onCopy;

  @override
  State<_InlineSnippet> createState() => _InlineSnippetState();
}

class _InlineSnippetState extends State<_InlineSnippet> {
  bool _feedback = false;
  bool _hovered = false;
  bool _focused = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _activate() {
    unawaited(Clipboard.setData(ClipboardData(text: widget.code)));
    widget.onCopy?.call();
    _timer?.cancel();
    setState(() => _feedback = true);
    _timer = Timer(widget.feedbackTimeout, () {
      if (mounted) setState(() => _feedback = false);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _activate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    // border-radius 4px; code padding 0 spacing-03; hover layer-hover.
    final Widget chip = DecoratedBox(
      decoration: BoxDecoration(
        color: widget.copyable && _hovered ? layer.layerHover : layer.layer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CarbonSpacing.spacing03,
        ),
        child: Text(
          widget.code,
          style: CarbonTypeStyles.code01.copyWith(color: theme.textPrimary),
        ),
      ),
    );

    if (!widget.copyable) {
      return chip;
    }

    return CarbonPopover(
      open: _feedback,
      highContrast: true,
      onRequestClose: () => setState(() => _feedback = false),
      content: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.all(CarbonSpacing.spacing05),
          child: Text(widget.feedback, style: CarbonTypeStyles.body01),
        ),
      ),
      child: CarbonControlSemantics(
        state: CarbonControlState.interactive,
        button: true,
        label: '${widget.copyLabel}: ${widget.code}',
        readOnlyHint: '',
        onActivate: _activate,
        builder: (FocusNode focus) => ExcludeSemantics(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _activate,
              child: Focus(
                focusNode: focus,
                onKeyEvent: _onKey,
                onFocusChange: (bool value) => setState(() => _focused = value),
                child: CarbonFocusRing(
                  visible: _focused,
                  borderRadius: BorderRadius.circular(4),
                  child: chip,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The multi-line show-more/less toggle.
class _ExpandButton extends StatefulWidget {
  const _ExpandButton({
    required this.expanded,
    required this.showMoreText,
    required this.showLessText,
    required this.onTap,
  });

  final bool expanded;
  final String showMoreText;
  final String showLessText;
  final VoidCallback onTap;

  @override
  State<_ExpandButton> createState() => _ExpandButtonState();
}

class _ExpandButtonState extends State<_ExpandButton> {
  bool _focused = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final String text = widget.expanded
        ? widget.showLessText
        : widget.showMoreText;
    return CarbonControlSemantics(
      state: CarbonControlState.interactive,
      button: true,
      label: text,
      readOnlyHint: '',
      expanded: widget.expanded,
      onActivate: widget.onTap,
      builder: (FocusNode focus) => ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Focus(
              focusNode: focus,
              onKeyEvent: _onKey,
              onFocusChange: (bool value) => setState(() => _focused = value),
              child: CarbonFocusRing(
                visible: _focused,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CarbonSpacing.spacing05,
                    vertical: CarbonSpacing.spacing03,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        text,
                        style: CarbonTypeStyles.bodyCompact01.copyWith(
                          color: theme.linkPrimary,
                        ),
                      ),
                      const SizedBox(width: CarbonSpacing.spacing03),
                      CarbonIcon(
                        widget.expanded
                            ? CarbonIcons.chevronUp
                            : CarbonIcons.chevronDown,
                        color: theme.linkPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A loading placeholder for a [CarbonCodeSnippet].
class CarbonCodeSnippetSkeleton extends StatelessWidget {
  /// Creates a code snippet skeleton.
  const CarbonCodeSnippetSkeleton({
    super.key,
    this.type = CarbonCodeSnippetType.single,
  });

  /// The snippet form to mimic; only single and multi have skeletons.
  final CarbonCodeSnippetType type;

  @override
  Widget build(BuildContext context) {
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    if (type == CarbonCodeSnippetType.multi) {
      return ColoredBox(
        color: layer.layer,
        child: const Padding(
          padding: EdgeInsets.all(CarbonSpacing.spacing05),
          child: CarbonSkeletonText(lineCount: 3),
        ),
      );
    }
    return ColoredBox(
      color: layer.layer,
      child: const SizedBox(
        height: CarbonSpacing.spacing08,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: CarbonSpacing.spacing05,
            vertical: CarbonSpacing.spacing05,
          ),
          child: CarbonSkeletonText(lineCount: 1),
        ),
      ),
    );
  }
}
