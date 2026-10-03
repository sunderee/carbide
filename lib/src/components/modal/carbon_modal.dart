// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/modal/_modal.scss
//   react/src/components/{Modal,ComposedModal}
//
// Modal: a centered dialog over a scrim with a focus trap, Escape-to-close and
// a header / scrolling body / footer-button layout.

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../button/carbon_button.dart';

/// The width of a [CarbonModal].
enum CarbonModalSize {
  /// Extra small (400px).
  xs(400),

  /// Small (480px).
  sm(480),

  /// Medium (640px) — the default.
  md(640),

  /// Large (768px).
  lg(768);

  const CarbonModalSize(this.width);

  /// The maximum dialog width in logical pixels.
  final double width;
}

/// A centered modal dialog over a scrim.
///
/// Controlled via [open]; respond to [onClose] (fired by the close button, an
/// outside tap, or Escape). Focus is trapped within the dialog while open and
/// restored to the launcher on close if it is still attached and focusable.
/// Passive and confirmation modals initially focus the first available control
/// (normally Close). Destructive modals focus an enabled secondary action when
/// available, otherwise the first available control; they never automatically
/// focus the destructive primary action.
///
/// The pointer-dismiss scrim is excluded from semantics. Assistive technology
/// uses the named close button or Escape instead of a full-screen dismiss node.
///
/// Opening plays the upstream entrance transition — the modal fades in while
/// the dialog container slides down from −24px (`moderate-02` ×
/// `entrance, expressive`). Under reduced motion
/// (`MediaQueryData.disableAnimations`) the modal appears instantly.
///
/// ```dart
/// CarbonModal(
///   open: _open,
///   title: 'Delete item',
///   onClose: () => setState(() => _open = false),
///   primaryButton: CarbonModalAction(label: 'Delete', onPressed: _delete),
///   secondaryButton: CarbonModalAction(label: 'Cancel', onPressed: _cancel),
///   danger: true,
///   child: const Text('This action cannot be undone.'),
/// )
/// ```
class CarbonModal extends StatefulWidget {
  /// Creates a modal.
  const CarbonModal({
    required this.open,
    required this.title,
    required this.child,
    super.key,
    this.label,
    this.onClose,
    this.primaryButton,
    this.secondaryButton,
    this.size = CarbonModalSize.md,
    this.danger = false,
    this.passiveModal = false,
    this.isFullWidth = false,
    this.preventCloseOnClickOutside = false,
    this.closeLabel = 'Close',
    this.aiLabel,
    this.aiRevert = false,
  });

  /// Whether the modal is shown.
  final bool open;

  /// The header title.
  final String title;

  /// The body content.
  final Widget child;

  /// An optional overline label above the title.
  final String? label;

  /// Called when dismissal is requested (close button, outside tap, Escape).
  final VoidCallback? onClose;

  /// The primary footer action.
  final CarbonModalAction? primaryButton;

  /// The secondary footer action.
  final CarbonModalAction? secondaryButton;

  /// The dialog width.
  final CarbonModalSize size;

  /// Whether the primary action is destructive.
  final bool danger;

  /// Whether to hide the footer buttons.
  final bool passiveModal;

  /// Whether the body content stretches edge to edge, dropping the content
  /// padding — used for data-dense content such as tables.
  ///
  /// Source: `Modal.tsx` `isFullWidth` and `_modal.scss`
  /// `.cds--modal-container--full-width .cds--modal-content`
  /// (`padding: 0; margin: 0`). The header and footer keep their spec
  /// paddings; [isFullWidth] composes with [size].
  final bool isFullWidth;

  /// Whether an outside tap is ignored.
  final bool preventCloseOnClickOutside;

  /// The accessible label for the close button.
  final String closeLabel;

  /// An optional AI presence decorator (a `CarbonAILabel`), rendered in the
  /// header before the close button per upstream's `decorator` prop. When
  /// set (and not [aiRevert]), the scrim uses the `ai-overlay` token and the
  /// dialog surface takes the AI popover treatment: the bottom-up aura over
  /// the layer, the `ai-border-start` border (the upstream border gradient
  /// and inset shadow have no Flutter box-model equivalent — the same
  /// simplifications as the AI Label callout), and the ai drop shadow.
  final Widget? aiLabel;

  /// Suppresses the AI treatment while the label shows its revert control.
  final bool aiRevert;

  @override
  State<CarbonModal> createState() => _CarbonModalState();
}

/// A labelled footer action for a [CarbonModal].
class CarbonModalAction {
  /// Creates a modal action.
  const CarbonModalAction({required this.label, this.onPressed});

  /// The button label.
  final String label;

  /// The action.
  final VoidCallback? onPressed;
}

class _CarbonModalState extends State<CarbonModal> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'CarbonModal');
  FocusNode? _restoreFocus;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    if (widget.open) {
      _restoreFocus = FocusManager.instance.primaryFocus;
      _overlay.show();
      _entered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnOpen());
    }
  }

  @override
  void didUpdateWidget(CarbonModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) _sync();
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _sync() {
    void apply() {
      if (!mounted) return;
      if (widget.open && !_overlay.isShowing) {
        _restoreFocus = FocusManager.instance.primaryFocus;
        _overlay.show();
        // Mount hidden first so the entrance transition plays.
        setState(() => _entered = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.open) {
            setState(() => _entered = true);
            _focusOnOpen();
          }
        });
      } else if (!widget.open && _overlay.isShowing) {
        _overlay.hide();
        _entered = false;
        final FocusNode? launcher = _restoreFocus;
        _restoreFocus = null;
        if (launcher?.context != null && launcher!.canRequestFocus) {
          launcher.requestFocus();
        }
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  void _focusOnOpen() {
    // Let descendant autofocus requests win before choosing a fallback.
    scheduleMicrotask(() {
      if (!mounted ||
          !widget.open ||
          _scope.context == null ||
          (_scope.hasFocus && _scope.focusedChild != null)) {
        return;
      }
      if (_scope.focusedChild != null) {
        _scope.requestFocus();
      } else if (widget.danger) {
        final FocusNode? safe = _scope.traversalDescendants
            .where(
              (FocusNode node) =>
                  node.context
                      ?.findAncestorWidgetOfExactType<CarbonButton>()
                      ?.kind !=
                  CarbonButtonKind.danger,
            )
            .firstOrNull;
        (safe ?? _scope).requestFocus();
      } else if (!_scope.nextFocus()) {
        _scope.requestFocus();
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.open &&
        widget.onClose != null &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onClose?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: _buildOverlay,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    // `_modal.scss` `modal-animations` / `modal-container-animations`: the
    // wrapper fades and the container slides from translate3d(0, -24px, 0),
    // both $duration-moderate-02 × motion(entrance, expressive); under
    // `prefers-reduced-motion` the transition is dropped entirely.
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration duration = reducedMotion
        ? Duration.zero
        : CarbonDuration.moderate02;

    return Positioned.fill(
      child: Focus(
        onKeyEvent: _onKey,
        canRequestFocus: false,
        child: FocusScope(
          node: _scope,
          autofocus: true,
          child: AnimatedOpacity(
            duration: duration,
            curve: CarbonEasing.entranceExpressive,
            opacity: _entered ? 1 : 0,
            child: Stack(
              children: <Widget>[
                // The scrim.
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.preventCloseOnClickOutside
                          ? null
                          : widget.onClose,
                      child: ColoredBox(
                        color: widget.aiLabel != null && !widget.aiRevert
                            ? theme.aiOverlay
                            : theme.overlay,
                      ),
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) =>
                      Center(
                        child: AnimatedSlide(
                          duration: duration,
                          curve: CarbonEasing.entranceExpressive,
                          // transform: translate3d(0, -24px, 0) while hidden,
                          // approximated as a fraction of the dialog height.
                          offset: _entered
                              ? Offset.zero
                              : const Offset(0, -0.05),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: widget.size.width,
                              maxHeight: constraints.maxHeight * 0.9,
                            ),
                            // Swallow taps so they do not reach the scrim.
                            child: GestureDetector(
                              onTap: () {},
                              excludeFromSemantics: true,
                              child: _Dialog(
                                title: widget.title,
                                label: widget.label,
                                danger: widget.danger,
                                passiveModal: widget.passiveModal,
                                isFullWidth: widget.isFullWidth,
                                aiLabel: widget.aiLabel,
                                aiRevert: widget.aiRevert,
                                closeLabel: widget.closeLabel,
                                onClose: widget.onClose,
                                primaryButton: widget.primaryButton,
                                secondaryButton: widget.secondaryButton,
                                child: widget.child,
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  const _Dialog({
    required this.title,
    required this.label,
    required this.danger,
    required this.passiveModal,
    required this.isFullWidth,
    required this.aiLabel,
    required this.aiRevert,
    required this.closeLabel,
    required this.onClose,
    required this.primaryButton,
    required this.secondaryButton,
    required this.child,
  });

  final String title;
  final String? label;
  final bool danger;
  final bool passiveModal;
  final bool isFullWidth;
  final Widget? aiLabel;
  final bool aiRevert;
  final String closeLabel;
  final VoidCallback? onClose;
  final CarbonModalAction? primaryButton;
  final CarbonModalAction? secondaryButton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final bool ai = aiLabel != null && !aiRevert;

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: DecoratedBox(
        decoration: ai
            ? BoxDecoration(
                color: layer.layer,
                // ai-popover-gradient('default', 0, 'layer'): the aura
                // rising from the bottom edge over the layer.
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    theme.aiAuraStart,
                    Color.lerp(theme.aiAuraStart, theme.aiAuraEnd, 0.5)!,
                    theme.aiAuraEnd,
                    theme.aiAuraEnd.withValues(alpha: 0),
                  ],
                  stops: const <double>[0, 0.15, 0.5, 1],
                ),
                border: Border.all(color: theme.aiBorderStart),
                boxShadow: <BoxShadow>[
                  // 0 24px 40px -24px $ai-drop-shadow (the inset shadow has
                  // no Flutter equivalent).
                  BoxShadow(
                    color: theme.aiDropShadow,
                    offset: const Offset(0, 24),
                    blurRadius: 40,
                    spreadRadius: -24,
                  ),
                ],
              )
            : BoxDecoration(color: layer.layer),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                CarbonSpacing.spacing05,
                CarbonSpacing.spacing05,
                CarbonSpacing.spacing03,
                CarbonSpacing.spacing03,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (label != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: CarbonSpacing.spacing02,
                            ),
                            child: Text(
                              label!,
                              style: CarbonTypeStyles.label01.copyWith(
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        ExcludeSemantics(
                          child: Text(
                            title,
                            style: CarbonTypeStyles.heading03.copyWith(
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The AI label sits before the close button
                  // (--modal--decorator header placement).
                  if (aiLabel != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: CarbonSpacing.spacing03,
                      ),
                      child: aiLabel!,
                    ),
                  CarbonButton.iconOnly(
                    icon: CarbonIcons.close,
                    iconDescription: closeLabel,
                    kind: CarbonButtonKind.ghost,
                    size: CarbonButtonSize.lg,
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            // Body. Full width drops the content padding entirely
            // (`--full-width .cds--modal-content`: padding 0, margin 0).
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: isFullWidth
                      ? EdgeInsets.zero
                      : const EdgeInsetsDirectional.fromSTEB(
                          CarbonSpacing.spacing05,
                          CarbonSpacing.spacing03,
                          CarbonSpacing.spacing09,
                          CarbonSpacing.spacing09,
                        ),
                  child: DefaultTextStyle.merge(
                    style: CarbonTypeStyles.body01.copyWith(
                      color: theme.textPrimary,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            // Footer.
            if (!passiveModal &&
                (primaryButton != null || secondaryButton != null))
              SizedBox(
                height: CarbonButtonSize.xl.height,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (secondaryButton != null)
                      Expanded(
                        child: CarbonButton(
                          label: secondaryButton!.label,
                          kind: CarbonButtonKind.secondary,
                          size: CarbonButtonSize.xl,
                          autofocus:
                              danger && secondaryButton!.onPressed != null,
                          onPressed: secondaryButton!.onPressed,
                        ),
                      ),
                    if (primaryButton != null)
                      Expanded(
                        child: CarbonButton(
                          label: primaryButton!.label,
                          kind: danger
                              ? CarbonButtonKind.danger
                              : CarbonButtonKind.primary,
                          size: CarbonButtonSize.xl,
                          onPressed: primaryButton!.onPressed,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
