// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/inline-loading/_inline-loading.scss
//   react/src/components/InlineLoading/InlineLoading.tsx

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import 'carbon_loading.dart';

/// The inline loading states.
enum CarbonInlineLoadingStatus {
  /// Nothing rendered in the animation slot.
  inactive,

  /// The small spinner.
  active,

  /// `checkmark--filled` in `supportSuccess`; fires `onSuccess` after the
  /// success delay.
  finished,

  /// `error--filled` in `supportError`.
  error,
}

/// Loading feedback inline with content (e.g. inside a button or form row).
///
/// A 16px animation slot — small spinner, success checkmark, or error icon —
/// followed by an optional [description] in `label-02`. When [status]
/// becomes [CarbonInlineLoadingStatus.finished], [onSuccess] fires after
/// [successDelay] (upstream default 1500ms). Status changes are announced
/// via a live region.
///
/// Status changes swap icons instantly (no fade), so reduced motion needs
/// no special handling there; the active spinner is essential motion and
/// keeps spinning under `MediaQueryData.disableAnimations` — see
/// [CarbonLoading].
class CarbonInlineLoading extends StatefulWidget {
  /// Creates an inline loading indicator.
  const CarbonInlineLoading({
    super.key,
    this.status = CarbonInlineLoadingStatus.active,
    this.description,
    this.onSuccess,
    this.successDelay = const Duration(milliseconds: 1500),
  });

  /// The current state.
  final CarbonInlineLoadingStatus status;

  /// The text beside the animation slot.
  final String? description;

  /// Called once [successDelay] after the status becomes `finished`.
  final VoidCallback? onSuccess;

  /// The delay before [onSuccess] fires.
  final Duration successDelay;

  /// Minimum row height per spec (2rem).
  static const double minHeight = 32;

  @override
  State<CarbonInlineLoading> createState() => _CarbonInlineLoadingState();
}

class _CarbonInlineLoadingState extends State<CarbonInlineLoading> {
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _scheduleSuccess();
  }

  @override
  void didUpdateWidget(CarbonInlineLoading oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      _successTimer?.cancel();
      _scheduleSuccess();
    }
  }

  void _scheduleSuccess() {
    if (widget.status == CarbonInlineLoadingStatus.finished &&
        widget.onSuccess != null) {
      _successTimer = Timer(widget.successDelay, () => widget.onSuccess!());
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Widget? animation = switch (widget.status) {
      CarbonInlineLoadingStatus.inactive => null,
      CarbonInlineLoadingStatus.active => const CarbonLoading(small: true),
      CarbonInlineLoadingStatus.finished => Semantics(
        liveRegion: true,
        child: CarbonIcon(
          CarbonIcons.checkmarkFilled,
          color: theme.supportSuccess,
          semanticLabel: 'Success',
        ),
      ),
      CarbonInlineLoadingStatus.error => Semantics(
        liveRegion: true,
        child: CarbonIcon(
          CarbonIcons.errorFilled,
          color: theme.supportError,
          semanticLabel: 'Error',
        ),
      ),
    };
    final String? description = widget.description;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: CarbonInlineLoading.minHeight,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (animation != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: CarbonSpacing.spacing03,
              ),
              child: animation,
            ),
          if (description != null)
            Text(
              description,
              style: CarbonTypeStyles.label02.copyWith(
                color: theme.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
