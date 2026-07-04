// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the GNU Affero General
// Public License v3.0 or later. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/chat-button/_chat-button.scss
//   react/src/components/ChatButton/* (unstable__ChatButton)
//
// The AI chat button: a pill-radius button (24/20/16px at lg/md/sm) on the
// standard button tokens, plus the quick-action mode on the chat-button
// token subset — transparent with a 1px `chat-button` border at rest,
// `chat-button-hover/-active` fills, and a `chat-button-selected` state
// that survives disabling. Upstream is `unstable__`; Carbide ships it
// under a stable name and documents that it tracks an unstable upstream
// API (the Icon/Shape-indicator posture). The keyboard focus visual is the
// ghost treatment from the SCSS (a `focus` border + 1px inset ring),
// applied to every kind — the standard button's square double ring does
// not compose with the pill radius.

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';
import '../button/carbon_button.dart';

/// The chat button sizes and their pill radii (`_chat-button.scss`).
enum CarbonChatButtonSize {
  /// 32px, 16px radius.
  sm(32, 16),

  /// 40px, 20px radius.
  md(40, 20),

  /// 48px, 24px radius — the default.
  lg(48, 24);

  const CarbonChatButtonSize(this.height, this.radius);

  /// The fixed button height in logical pixels.
  final double height;

  /// The pill corner radius.
  final double radius;
}

/// A Carbon AI chat button.
///
/// ```dart
/// CarbonChatButton(label: 'Ask a question', onPressed: ask);
/// CarbonChatButton(
///   label: 'Summarize',
///   quickAction: true,
///   isSelected: _summarize,
///   onPressed: toggle,
/// );
/// ```
class CarbonChatButton extends StatelessWidget {
  /// Creates a chat button.
  const CarbonChatButton({
    required this.label,
    super.key,
    this.onPressed,
    this.kind = CarbonButtonKind.primary,
    this.size = CarbonChatButtonSize.lg,
    this.icon,
    this.quickAction = false,
    this.isSelected = false,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         kind == CarbonButtonKind.primary ||
             kind == CarbonButtonKind.secondary ||
             kind == CarbonButtonKind.tertiary ||
             kind == CarbonButtonKind.ghost,
         'Chat buttons support the primary, secondary, tertiary, and ghost '
         'kinds.',
       ),
       assert(
         !isSelected || quickAction,
         'isSelected applies to quick-action chat buttons.',
       );

  /// The button label.
  final String label;

  /// Called on activation; null renders the disabled state.
  final VoidCallback? onPressed;

  /// The visual kind (primary/secondary/tertiary/ghost).
  final CarbonButtonKind kind;

  /// The size; defaults to the 48px chat button.
  final CarbonChatButtonSize size;

  /// An optional trailing 16px icon.
  final CarbonIconData? icon;

  /// The quick-action mode: the outlined `chat-button` treatment with a
  /// selectable state.
  final bool quickAction;

  /// Whether a quick-action button is selected (`--quick-action--selected`;
  /// kept even while disabled, per the SCSS).
  final bool isSelected;

  /// An optional focus node to control focus externally.
  final FocusNode? focusNode;

  /// Whether to request focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final bool enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: quickAction ? isSelected : null,
      child: CarbonInteraction(
        enabled: enabled,
        onPressed: onPressed,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (BuildContext context, Set<WidgetState> states) {
          final _ChatStyle style = _ChatStyle.resolve(
            theme: theme,
            kind: kind,
            quickAction: quickAction,
            isSelected: isSelected,
            states: states,
          );
          final BorderRadius radius = BorderRadius.circular(size.radius);
          return AnimatedContainer(
            duration: CarbonDuration.fast01,
            curve: CarbonEasing.entranceProductive,
            height: size.height,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: EdgeInsetsDirectional.only(
              start: CarbonSpacing.spacing05,
              // padding-inline-end: 15px without an icon.
              end: icon == null ? 15 : CarbonSpacing.spacing05,
            ),
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: radius,
              border: Border.all(color: style.border),
            ),
            // :focus — border-color $focus + inset 0 0 0 1px $focus.
            foregroundDecoration: states.contains(WidgetState.focused)
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: theme.focus, width: 2),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CarbonTypeStyles.bodyCompact01.copyWith(
                      color: style.text,
                    ),
                  ),
                ),
                if (icon != null) ...<Widget>[
                  const SizedBox(width: CarbonSpacing.spacing03),
                  CarbonIcon(icon!, color: style.text),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Resolved colors for one chat-button state.
class _ChatStyle {
  const _ChatStyle(this.background, this.border, this.text);

  final Color background;
  final Color border;
  final Color text;

  static const Color _transparent = Color(0x00000000);

  static _ChatStyle resolve({
    required CarbonThemeData theme,
    required CarbonButtonKind kind,
    required bool quickAction,
    required bool isSelected,
    required Set<WidgetState> states,
  }) {
    final bool disabled = states.contains(WidgetState.disabled);
    final bool pressed = states.contains(WidgetState.pressed);
    final bool hovered = states.contains(WidgetState.hovered);

    if (quickAction) {
      // Selected wins, even while disabled (`--quick-action--selected`).
      if (isSelected) {
        return _ChatStyle(
          theme.chatButtonSelected,
          _transparent,
          theme.chatButtonTextSelected,
        );
      }
      if (disabled) {
        return _ChatStyle(
          _transparent,
          theme.buttonDisabled,
          theme.buttonDisabled,
        );
      }
      if (pressed) {
        return _ChatStyle(
          theme.chatButtonActive,
          _transparent,
          theme.chatButtonTextHover,
        );
      }
      if (hovered) {
        return _ChatStyle(
          theme.chatButtonHover,
          _transparent,
          theme.chatButtonTextHover,
        );
      }
      return _ChatStyle(_transparent, theme.chatButton, theme.chatButton);
    }

    if (disabled) {
      final bool transparentKind =
          kind == CarbonButtonKind.tertiary || kind == CarbonButtonKind.ghost;
      if (transparentKind) {
        return _ChatStyle(
          _transparent,
          kind == CarbonButtonKind.tertiary
              ? theme.buttonDisabled
              : _transparent,
          theme.textDisabled,
        );
      }
      return _ChatStyle(
        theme.buttonDisabled,
        _transparent,
        theme.textOnColorDisabled,
      );
    }

    switch (kind) {
      case CarbonButtonKind.primary:
        return _ChatStyle(
          pressed
              ? theme.buttonPrimaryActive
              : hovered
              ? theme.buttonPrimaryHover
              : theme.buttonPrimary,
          _transparent,
          theme.textOnColor,
        );
      case CarbonButtonKind.secondary:
        return _ChatStyle(
          pressed
              ? theme.buttonSecondaryActive
              : hovered
              ? theme.buttonSecondaryHover
              : theme.buttonSecondary,
          _transparent,
          theme.textOnColor,
        );
      case CarbonButtonKind.tertiary:
        if (pressed) {
          return _ChatStyle(
            theme.buttonTertiaryActive,
            _transparent,
            theme.textInverse,
          );
        }
        if (hovered) {
          return _ChatStyle(
            theme.buttonTertiaryHover,
            theme.buttonTertiary,
            theme.textInverse,
          );
        }
        return _ChatStyle(
          _transparent,
          theme.buttonTertiary,
          theme.buttonTertiary,
        );
      case CarbonButtonKind.ghost:
        return _ChatStyle(
          pressed
              ? theme.backgroundActive
              : hovered
              ? theme.backgroundHover
              : _transparent,
          _transparent,
          pressed || hovered ? theme.linkPrimaryHover : theme.linkPrimary,
        );
      // The assert restricts the remaining kinds.
      case CarbonButtonKind.danger:
      case CarbonButtonKind.dangerTertiary:
      case CarbonButtonKind.dangerGhost:
        throw UnsupportedError('Chat buttons have no danger kinds.');
    }
  }
}
