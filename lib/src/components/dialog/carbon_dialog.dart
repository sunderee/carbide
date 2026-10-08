// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/dialog/_dialog.scss
//   react/src/components/Dialog/Dialog.tsx (preview__Dialog)
//
// Carbon's composable Dialog (the designated successor to ComposedModal;
// still a preview upstream — Carbide ports it under stable names, the same
// posture as the Icon/Shape indicators). A centered 48rem surface on the
// layer with a 1px border-subtle-01 border, entering with the upstream
// opacity + translateY(-24px) transition (moderate-02 × entrance-expressive
// per the `[open]` / `presence-dialog__enter` rules, skipped under reduced
// motion). Modal dialogs add the overlay backdrop and
// a focus trap; non-modal dialogs float without blocking the page (the
// native <dialog> show()/showModal() split). Escape requests close; unlike
// CarbonModal there is no outside-tap dismissal — the native dialog element
// does not close on backdrop clicks.

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../utils/modal_background_lock.dart';
import '../../utils/overlay_semantics_anchor.dart';
import '../../foundations/layout.dart';
import '../../foundations/motion.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';
import '../../utils/native_control_focus.dart';
import '../../utils/overlay_focus_repair.dart';

/// A composable Carbon dialog.
///
/// Modal dialogs contain keyboard traversal and restore focus to the opener
/// on close if it is still attached and focusable. Initial focus follows a
/// descendant's `autofocus` request, otherwise the first available control
/// (normally Close). For a destructive dialog, set `autofocus: true` on the
/// non-destructive action, such as Cancel. Passive and confirmation dialogs
/// normally start at Close. A non-modal dialog leaves existing focus unchanged
/// on opening and closing, and permits traversal to the page behind it.
///
/// The modal backdrop is excluded from semantics and does not dismiss on tap.
/// The named close control and Escape provide keyboard-accessible dismissal;
/// Escape only requests close while focus is inside the dialog.
///
/// Opening plays the upstream entrance transition — opacity +
/// translateY(−24px) at `moderate-02` × `entrance, expressive`. Under
/// reduced motion (`MediaQueryData.disableAnimations`) the dialog and its
/// backdrop appear instantly.
///
/// Compose the slots inside [children]:
///
/// Closing uses the expressive exit curve for the same moderate-02 duration.
/// The surface remains mounted, with focus and semantics intact, until exit
/// completes. Modal focus restores only after removal; reopening cancels exit.
/// Reduced motion removes the surface immediately. Modal mode also blocks page
/// wheel/touch gestures and pointer interaction while present.
///
/// ```dart
/// CarbonDialog(
///   open: _open,
///   onRequestClose: () => setState(() => _open = false),
///   children: <Widget>[
///     CarbonDialogHeader(
///       controls: CarbonDialogControls(
///         children: <Widget>[
///           CarbonDialogCloseButton(
///             onPressed: () => setState(() => _open = false),
///           ),
///         ],
///       ),
///       children: const <Widget>[
///         CarbonDialogSubtitle('Optional label'),
///         CarbonDialogTitle('Dialog title'),
///       ],
///     ),
///     const CarbonDialogBody(child: Text('Body content.')),
///     CarbonDialogFooter(children: <Widget>[...]),
///   ],
/// )
/// ```
class CarbonDialog extends StatefulWidget {
  /// Creates a dialog.
  const CarbonDialog({
    required this.open,
    required this.children,
    super.key,
    this.modal = true,
    this.onRequestClose,
  });

  /// Whether the dialog is shown.
  final bool open;

  /// The slot children (header, body, footer). A [CarbonDialogBody] child
  /// receives the flexible middle row so long content scrolls within the
  /// dialog's max height.
  final List<Widget> children;

  /// Whether the dialog blocks the page behind an overlay backdrop and
  /// traps focus (`showModal()`), or floats without blocking (`show()`).
  final bool modal;

  /// Called when dismissal is requested (Escape or the close button's
  /// default handler — the upstream `onRequestClose`).
  final VoidCallback? onRequestClose;

  @override
  State<CarbonDialog> createState() => _CarbonDialogState();
}

class _CarbonDialogState extends State<CarbonDialog> {
  final OverlayPortalController _overlay = OverlayPortalController();
  final FocusScopeNode _scope = FocusScopeNode(debugLabel: 'CarbonDialog');
  final FocusNode _region = FocusNode(debugLabel: 'CarbonDialog region');
  FocusNode? _restoreFocus;
  bool Function()? _restoreNativeFocus;
  final OverlayFocusRepair _focusRepair = OverlayFocusRepair();
  bool _entered = false;
  Timer? _exitTimer;

  @override
  void initState() {
    super.initState();
    if (widget.open) {
      _restoreFocus = FocusManager.instance.primaryFocus;
      _restoreNativeFocus = widget.modal ? null : captureNativeControlFocus();
      _overlay.show();
      _entered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusOnOpen());
    }
  }

  @override
  void didUpdateWidget(CarbonDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      _sync();
    } else if (widget.open && widget.modal != oldWidget.modal) {
      _focusRepair.cancel();
      if (widget.modal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.open && widget.modal) _focusOnOpen();
        });
      }
    }
  }

  @override
  void dispose() {
    _exitTimer?.cancel();
    _restoreNativeFocus = null;
    _focusRepair.dispose();
    _region.dispose();
    _scope.dispose();
    super.dispose();
  }

  void _sync() {
    void apply() {
      if (!mounted) return;
      if (widget.open) {
        _exitTimer?.cancel();
        _exitTimer = null;
        if (_overlay.isShowing) {
          setState(() => _entered = true);
          return;
        }
        _focusRepair.cancel();
        _restoreFocus = FocusManager.instance.primaryFocus;
        _restoreNativeFocus = widget.modal ? null : captureNativeControlFocus();
        _overlay.show();
        // Mount hidden first so the entrance transition plays.
        setState(() => _entered = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.open) {
            setState(() => _entered = true);
            _focusOnOpen();
          }
        });
      } else if (_overlay.isShowing) {
        setState(() => _entered = false);
        final Duration duration = carbonDuration(
          context,
          CarbonDuration.moderate02,
        );
        if (duration == Duration.zero) {
          _finishClose();
        } else {
          _exitTimer?.cancel();
          _exitTimer = Timer(duration, _finishClose);
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

  void _finishClose() {
    _exitTimer?.cancel();
    _exitTimer = null;
    if (!mounted || widget.open || !_overlay.isShowing) return;

    final FocusNode? pageFocus = FocusManager.instance.primaryFocus;
    final bool preservePage =
        !widget.modal &&
        pageFocus != null &&
        !pageFocus.ancestors.contains(_region);
    final bool Function()? pageNativeFocus = preservePage
        ? captureNativeControlFocus()
        : null;
    _overlay.hide();
    setState(() {});

    final FocusNode? launcher = _restoreFocus;
    _restoreFocus = null;
    _restoreNativeFocus = null;
    if (widget.modal &&
        launcher?.context != null &&
        launcher!.parent != null &&
        launcher.canRequestFocus) {
      launcher.requestFocus();
    } else if (preservePage) {
      _focusRepair.schedule(
        pageFocus,
        pageNativeFocus,
        isCurrent: () => mounted && !widget.open && !widget.modal,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.open &&
        _overlay.isShowing &&
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishClose());
    }
  }

  void _focusOnOpen() {
    if (!widget.modal) {
      _focusRepair.schedule(
        _restoreFocus,
        _restoreNativeFocus,
        isCurrent: () => mounted && widget.open && !widget.modal,
      );
      return;
    }
    // Honor a caller's autofocus choice before selecting the first control.
    scheduleMicrotask(() {
      if (!mounted ||
          !widget.open ||
          !widget.modal ||
          _scope.context == null ||
          (_scope.hasFocus && _scope.focusedChild != null)) {
        return;
      }
      if (_scope.focusedChild != null) {
        _scope.requestFocus();
      } else if (!_scope.nextFocus()) {
        _scope.requestFocus();
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.open &&
        widget.onRequestClose != null &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onRequestClose?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// max-inline-size steps down as the viewport grows: 84% from md, 60%
  /// from lg, 48% from xlg (of the available width), capped at 48rem.
  static double _maxWidth(double available) {
    final double fraction = available >= CarbonBreakpoint.xlg.width
        ? 0.48
        : available >= CarbonBreakpoint.lg.width
        ? 0.60
        : available >= CarbonBreakpoint.md.width
        ? 0.84
        : 1.0;
    final double byViewport = available * fraction;
    return byViewport < 768 ? byViewport : 768;
  }

  Widget _buildOverlay(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final Duration duration = carbonDuration(
      context,
      CarbonDuration.moderate02,
    );

    final Widget surface = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // max-block-size: 90vh from md, 84vh from lg.
        final double maxHeight =
            constraints.maxHeight *
            (constraints.maxWidth >= CarbonBreakpoint.lg.width ? 0.84 : 0.90);
        return Center(
          child: AnimatedSlide(
            duration: duration,
            // `_dialog.scss`: moderate-02, expressive entrance/exit.
            curve: _entered
                ? CarbonEasing.entranceExpressive
                : CarbonEasing.exitExpressive,
            // transform: translateY(-$spacing-06) while hidden.
            offset: _entered ? Offset.zero : const Offset(0, -0.05),
            child: AnimatedOpacity(
              alwaysIncludeSemantics: true,
              duration: duration,
              curve: _entered
                  ? CarbonEasing.entranceExpressive
                  : CarbonEasing.exitExpressive,
              opacity: _entered ? 1 : 0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _maxWidth(constraints.maxWidth),
                  maxHeight: maxHeight,
                ),
                child: Semantics(
                  scopesRoute: widget.modal,
                  explicitChildNodes: true,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: layer.layer,
                      border: Border.all(color: theme.borderSubtle01),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final Widget child in widget.children)
                          if (child is CarbonDialogBody)
                            Flexible(child: child)
                          else
                            child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!widget.modal) {
      return Positioned.fill(
        child: Focus(
          focusNode: _region,
          onKeyEvent: _onKey,
          canRequestFocus: false,
          includeSemantics: false,
          child: Stack(
            children: <Widget>[
              // Non-modal: the page stays interactive; only the dialog
              // surface hit-tests.
              const Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(color: Color(0x00000000)),
                ),
              ),
              surface,
            ],
          ),
        ),
      );
    }

    return Positioned.fill(
      // Escape cancels a modal dialog (the native cancel event); the key
      // handler must sit ABOVE the focus scope to see bubbled keys.
      child: CarbonModalBackgroundLock(
        child: Focus(
          focusNode: _region,
          onKeyEvent: _onKey,
          canRequestFocus: false,
          child: FocusScope(
            node: _scope,
            autofocus: true,
            child: Stack(
              children: <Widget>[
                // ::backdrop — the overlay scrim; no outside-tap dismissal
                // (the native dialog element does not close on backdrop
                // clicks).
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: AnimatedOpacity(
                      alwaysIncludeSemantics: true,
                      duration: carbonDuration(
                        context,
                        CarbonDuration.moderate02,
                      ),
                      curve: _entered
                          ? CarbonEasing.entranceExpressive
                          : CarbonEasing.exitExpressive,
                      opacity: _entered ? 1 : 0,
                      child: ColoredBox(color: theme.overlay),
                    ),
                  ),
                ),
                surface,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlay,
      overlayChildBuilder: _buildOverlay,
      child: _overlay.isShowing
          ? CarbonOverlaySemanticsAnchor(modal: widget.modal)
          : const SizedBox.shrink(),
    );
  }
}

/// The dialog header band: `padding-block-start $spacing-05`,
/// `padding-inline $spacing-05 $spacing-09`, min height `$spacing-09`,
/// 8px bottom margin, with [controls] pinned to the top end.
class CarbonDialogHeader extends StatelessWidget {
  /// Creates a dialog header.
  const CarbonDialogHeader({required this.children, super.key, this.controls});

  /// The header content (typically [CarbonDialogSubtitle] then
  /// [CarbonDialogTitle]).
  final List<Widget> children;

  /// The action cluster pinned to the top end (a [CarbonDialogControls]).
  final Widget? controls;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: CarbonSpacing.spacing05,
            start: CarbonSpacing.spacing05,
            end: CarbonSpacing.spacing09,
            bottom: CarbonSpacing.spacing03,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CarbonSpacing.spacing09 - CarbonSpacing.spacing05,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
        if (controls != null)
          PositionedDirectional(top: 0, end: 0, child: controls!),
      ],
    );
  }
}

/// The header's top-end action cluster (`--dialog__header-controls`).
class CarbonDialogControls extends StatelessWidget {
  /// Creates the header controls.
  const CarbonDialogControls({required this.children, super.key});

  /// The control buttons (typically ending with [CarbonDialogCloseButton]).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: children);
}

/// The 48px dialog close button (`--dialog__close`): transparent at rest,
/// `layer-hover` on hover, a 2px `focus` border when focused.
class CarbonDialogCloseButton extends StatelessWidget {
  /// Creates a dialog close button.
  const CarbonDialogCloseButton({
    super.key,
    this.onPressed,
    this.label = 'Close',
  });

  /// The close action.
  final VoidCallback? onPressed;

  /// The accessible label.
  final String label;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return Semantics(
      button: true,
      label: label,
      child: CarbonInteraction(
        enabled: onPressed != null,
        onPressed: onPressed,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered = states.contains(WidgetState.hovered);
          final bool focused = states.contains(WidgetState.focused);
          // `_dialog.scss`: background-color $duration-fast-02
          // motion(standard, productive); instant under reduced motion.
          return AnimatedContainer(
            duration: carbonDuration(context, CarbonDuration.fast02),
            curve: CarbonEasing.standardProductive,
            width: 48,
            height: 48,
            color: hovered ? layer.layerHover : const Color(0x00000000),
            foregroundDecoration: focused
                ? BoxDecoration(
                    border: Border.all(color: theme.focus, width: 2),
                  )
                : null,
            child: Center(
              child: ExcludeSemantics(
                child: CarbonIcon(
                  CarbonIcons.close,
                  size: 20,
                  color: theme.iconPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The dialog title (`heading-03`), kept clear of the header controls.
class CarbonDialogTitle extends StatelessWidget {
  /// Creates a dialog title.
  const CarbonDialogTitle(this.text, {super.key});

  /// The title text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      // padding-inline-end: calc(20% - $spacing-09), approximated with the
      // fixed spacing so the title never runs under the controls.
      padding: const EdgeInsetsDirectional.only(end: CarbonSpacing.spacing09),
      child: Text(
        text,
        style: CarbonTypeStyles.heading03.copyWith(color: theme.textPrimary),
      ),
    );
  }
}

/// The dialog's overline label (`--dialog-header__label`, `label-01`).
class CarbonDialogSubtitle extends StatelessWidget {
  /// Creates a dialog subtitle.
  const CarbonDialogSubtitle(this.text, {super.key});

  /// The subtitle text.
  final String text;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing02),
      child: Text(
        text,
        style: CarbonTypeStyles.label01.copyWith(color: theme.textSecondary),
      ),
    );
  }
}

/// The scrollable dialog content (`--dialog-content` +
/// `--dialog-scroll-content`): `padding-block $spacing-03 $spacing-09`,
/// `padding-inline $spacing-05`, with the bottom fade that marks scrollable
/// content (the CSS mask-image, approximated with a layer-colored gradient
/// overlay).
class CarbonDialogBody extends StatelessWidget {
  /// Creates the dialog body.
  const CarbonDialogBody({required this.child, super.key});

  /// The body content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(
            CarbonSpacing.spacing05,
            CarbonSpacing.spacing03,
            CarbonSpacing.spacing05,
            CarbonSpacing.spacing09,
          ),
          child: DefaultTextStyle.merge(
            style: CarbonTypeStyles.body01.copyWith(color: theme.textPrimary),
            child: child,
          ),
        ),
        // The scroll fade: content dissolves into the layer over the last
        // $spacing-09..$spacing-11 band.
        PositionedDirectional(
          start: 0,
          end: 0,
          bottom: 0,
          height: CarbonSpacing.spacing09,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: <Color>[
                    layer.layer,
                    layer.layer.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The dialog footer (`--dialog-footer`): a 64px end-aligned button row
/// where each button takes up to half the width.
class CarbonDialogFooter extends StatelessWidget {
  /// Creates the dialog footer.
  const CarbonDialogFooter({required this.children, super.key});

  /// The footer buttons, start to end.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CarbonSpacing.spacing10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final Widget child in children)
            Flexible(
              child: SizedBox(width: double.infinity, child: child),
            ),
        ],
      ),
    );
  }
}
