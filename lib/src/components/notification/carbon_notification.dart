// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/notification/{_inline-notification,
//   _toast-notification,_actionable-notification,_mixins,_tokens}.scss
//   react/src/components/Notification/Notification.tsx
//
// Notifications: Inline, Toast, Actionable, and Callout variants sharing a
// 3px status bar + 20px status icon and title/subtitle. Default (high
// contrast) renders on `backgroundInverse` with no outer border; lowContrast
// renders on the `notificationBackground*` tint with a 1px 40%-opacity border
// overlay on the top/end/bottom edges (the start edge is the status bar;
// toasts have no overlay). The warning icons paint their inner exclamation
// path `black-100` per the `path[opacity='0']` / `path:first-of-type` rules.
// The md+ layout is ported: the <md flex-wrap layout and the 352px
// max-breakpoint toast width are not. Inline/actionable/callout max width
// steps 608/736/832 with the available width; toasts are a fixed 288px.

import 'package:flutter/widgets.dart';

import '../../foundations/colors.dart';
import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icon_data.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/interaction.dart';

/// The status of a notification.
enum CarbonNotificationKind {
  /// An error.
  error('error'),

  /// A success.
  success('success'),

  /// Informational.
  info('info'),

  /// Informational, with the squared icon.
  infoSquare('info-square'),

  /// A warning.
  warning('warning'),

  /// A warning, with the triangular alternative icon.
  warningAlt('warning-alt');

  const CarbonNotificationKind(this.carbonName);

  /// The upstream Carbon kind name (kebab-case, e.g. `info-square`).
  final String carbonName;
}

/// The black inner exclamation of `warning--filled` (20px artwork), painted
/// over the icon per `path[opacity='0'] { fill: $black-100 }`.
const CarbonIconData _warningInnerPath = CarbonIconData(
  name: 'warning--filled--inner-path',
  artwork: <CarbonIconArtwork>[
    CarbonIconArtwork(
      size: 20,
      viewBoxWidth: 20,
      viewBoxHeight: 20,
      shapes: <CarbonIconShape>[
        CarbonIconShape(
          d:
              'M9.2,5h1.5v7H9.2V5z M10,16c-0.6,0-1-0.4-1-1s0.4-1,1-1 '
              's1,0.4,1,1S10.6,16,10,16z',
        ),
      ],
    ),
  ],
);

/// The black inner exclamation of `warning--alt--filled` (32px artwork),
/// painted over the icon per `path:first-of-type { fill: $black-100 }`.
const CarbonIconData _warningAltInnerPath = CarbonIconData(
  name: 'warning--alt--filled--inner-path',
  artwork: <CarbonIconArtwork>[
    CarbonIconArtwork(
      size: 32,
      viewBoxWidth: 32,
      viewBoxHeight: 32,
      shapes: <CarbonIconShape>[
        CarbonIconShape(
          d:
              'M16,26a1.5,1.5,0,1,1,1.5-1.5A1.5,1.5,0,0,1,16,26Z'
              'm-1.125-5h2.25V12h-2.25Z',
        ),
      ],
    ),
  ],
);

/// Resolves per-kind tokens for a notification.
class _KindStyle {
  const _KindStyle(this.icon, this.accent, this.tint, this.innerPath);

  final CarbonIconData icon;
  final Color accent;
  final Color tint;
  final CarbonIconData? innerPath;

  static _KindStyle of(
    CarbonNotificationKind kind,
    CarbonThemeData theme,
    bool lowContrast,
  ) {
    switch (kind) {
      case CarbonNotificationKind.error:
        return _KindStyle(
          CarbonIcons.errorFilled,
          lowContrast ? theme.supportError : theme.supportErrorInverse,
          theme.notificationBackgroundError,
          null,
        );
      case CarbonNotificationKind.success:
        return _KindStyle(
          CarbonIcons.checkmarkFilled,
          lowContrast ? theme.supportSuccess : theme.supportSuccessInverse,
          theme.notificationBackgroundSuccess,
          null,
        );
      case CarbonNotificationKind.info:
        return _KindStyle(
          CarbonIcons.informationFilled,
          lowContrast ? theme.supportInfo : theme.supportInfoInverse,
          theme.notificationBackgroundInfo,
          null,
        );
      case CarbonNotificationKind.infoSquare:
        return _KindStyle(
          CarbonIcons.informationSquareFilled,
          lowContrast ? theme.supportInfo : theme.supportInfoInverse,
          theme.notificationBackgroundInfo,
          null,
        );
      case CarbonNotificationKind.warning:
        return _KindStyle(
          CarbonIcons.warningFilled,
          lowContrast ? theme.supportWarning : theme.supportWarningInverse,
          theme.notificationBackgroundWarning,
          _warningInnerPath,
        );
      case CarbonNotificationKind.warningAlt:
        return _KindStyle(
          CarbonIcons.warningAltFilled,
          lowContrast ? theme.supportWarning : theme.supportWarningInverse,
          theme.notificationBackgroundWarning,
          _warningAltInnerPath,
        );
    }
  }
}

/// An inline notification, shown within page content.
class CarbonInlineNotification extends StatelessWidget {
  /// Creates an inline notification.
  const CarbonInlineNotification({
    required this.kind,
    required this.title,
    super.key,
    this.subtitle,
    this.lowContrast = false,
    this.onClose,
    this.closeLabel = 'Close notification',
    this.statusIconDescription,
  });

  /// The notification status.
  final CarbonNotificationKind kind;

  /// The bold title.
  final String title;

  /// The optional subtitle.
  final String? subtitle;

  /// Whether to use the light low-contrast surface.
  final bool lowContrast;

  /// Called when the close control is activated; null hides it.
  final VoidCallback? onClose;

  /// The accessible label for the close control.
  final String closeLabel;

  /// The accessible description of the status icon; defaults to
  /// `'<kind> icon'` (for example `error icon`), matching upstream.
  final String? statusIconDescription;

  @override
  Widget build(BuildContext context) {
    return _NotificationBar(
      kind: kind,
      title: title,
      subtitle: subtitle,
      lowContrast: lowContrast,
      liveRegion: true,
      onClose: onClose,
      closeLabel: closeLabel,
      statusIconDescription: statusIconDescription,
    );
  }
}

/// A floating toast notification with stacked title/subtitle and optional
/// [caption].
class CarbonToastNotification extends StatelessWidget {
  /// Creates a toast notification.
  const CarbonToastNotification({
    required this.kind,
    required this.title,
    super.key,
    this.subtitle,
    this.caption,
    this.lowContrast = false,
    this.onClose,
    this.closeLabel = 'Close notification',
    this.statusIconDescription,
  });

  /// The notification status.
  final CarbonNotificationKind kind;

  /// The bold title.
  final String title;

  /// The optional subtitle.
  final String? subtitle;

  /// The optional caption (for example a timestamp).
  final String? caption;

  /// Whether to use the light low-contrast surface.
  final bool lowContrast;

  /// Called when the close control is activated; null hides it.
  final VoidCallback? onClose;

  /// The accessible label for the close control.
  final String closeLabel;

  /// The accessible description of the status icon; defaults to
  /// `'<kind> icon'` (for example `error icon`), matching upstream.
  final String? statusIconDescription;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final _KindStyle style = _KindStyle.of(kind, theme, lowContrast);
    final Color textColor = lowContrast ? theme.textPrimary : theme.textInverse;

    final Widget details = Padding(
      // __details: margin-block-end + margin-inline-end $spacing-05.
      padding: const EdgeInsetsDirectional.only(
        end: CarbonSpacing.spacing05,
        bottom: CarbonSpacing.spacing05,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // __title: margin-block-start $spacing-05.
          Padding(
            padding: const EdgeInsets.only(top: CarbonSpacing.spacing05),
            child: Text(
              title,
              style: CarbonTypeStyles.headingCompact01.copyWith(
                color: textColor,
              ),
            ),
          ),
          // __subtitle: margin-block 0 $spacing-05 (flush under the title).
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing05),
              child: Text(
                subtitle!,
                style: CarbonTypeStyles.bodyCompact01.copyWith(
                  color: textColor,
                ),
              ),
            ),
          // __caption: padding-block-start $spacing-03.
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: CarbonSpacing.spacing03),
              child: Text(
                caption!,
                style: CarbonTypeStyles.bodyCompact01.copyWith(
                  color: textColor,
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      container: true,
      liveRegion: true,
      explicitChildNodes: true,
      label: '$title. ${subtitle ?? ''}'.trim(),
      // A toast is a fixed 288px regardless of the parent's width (Align
      // loosens a tight parent constraint; the factors shrink-wrap it in
      // loose ones).
      child: Align(
        alignment: AlignmentDirectional.topStart,
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox(
          width: 288,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: lowContrast ? style.tint : theme.backgroundInverse,
              border: BorderDirectional(
                start: BorderSide(color: style.accent, width: 3),
              ),
              // box-shadow: 0 2px 6px 0 rgba(0, 0, 0, 0.2).
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Padding(
              // 3px status-bar border + padding-inline-start 13px: the border
              // paints inside this box, so the content inset is their sum.
              padding: const EdgeInsetsDirectional.only(start: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    // __icon: margin-block-start + margin-inline-end
                    // $spacing-05.
                    padding: const EdgeInsetsDirectional.only(
                      top: CarbonSpacing.spacing05,
                      end: CarbonSpacing.spacing05,
                    ),
                    child: _StatusIcon(
                      style: style,
                      description:
                          statusIconDescription ?? '${kind.carbonName} icon',
                    ),
                  ),
                  Expanded(child: details),
                  if (onClose != null)
                    _CloseButton(
                      onClose: onClose!,
                      label: closeLabel,
                      lowContrast: lowContrast,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A notification with an inline action button (alertdialog role).
class CarbonActionableNotification extends StatelessWidget {
  /// Creates an actionable notification.
  const CarbonActionableNotification({
    required this.kind,
    required this.title,
    required this.actionLabel,
    super.key,
    this.subtitle,
    this.onAction,
    this.lowContrast = false,
    this.onClose,
    this.closeLabel = 'Close notification',
    this.statusIconDescription,
  });

  /// The notification status.
  final CarbonNotificationKind kind;

  /// The bold title.
  final String title;

  /// The optional subtitle.
  final String? subtitle;

  /// The action button label.
  final String actionLabel;

  /// The action; null disables the action button.
  final VoidCallback? onAction;

  /// Whether to use the light low-contrast surface.
  final bool lowContrast;

  /// Called when the close control is activated; null hides it.
  final VoidCallback? onClose;

  /// The accessible label for the close control.
  final String closeLabel;

  /// The accessible description of the status icon; defaults to
  /// `'<kind> icon'` (for example `error icon`), matching upstream.
  final String? statusIconDescription;

  @override
  Widget build(BuildContext context) {
    return _NotificationBar(
      kind: kind,
      title: title,
      subtitle: subtitle,
      lowContrast: lowContrast,
      liveRegion: true,
      actionLabel: actionLabel,
      onAction: onAction,
      onClose: onClose,
      closeLabel: closeLabel,
      statusIconDescription: statusIconDescription,
    );
  }
}

/// A static, non-dismissible callout that highlights page content.
///
/// Carbon's Callout (formerly `StaticNotification`) reuses the actionable
/// notification chrome with the close button always hidden. It is page
/// content rather than an announcement, so it is not a live region and
/// supports only the [CarbonNotificationKind.info] and
/// [CarbonNotificationKind.warning] kinds.
class CarbonCallout extends StatelessWidget {
  /// Creates a callout.
  const CarbonCallout({
    super.key,
    this.kind = CarbonNotificationKind.info,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.lowContrast = false,
    this.statusIconDescription,
  }) : assert(
         kind == CarbonNotificationKind.info ||
             kind == CarbonNotificationKind.warning,
         'A callout supports only the info and warning kinds.',
       );

  /// The callout status; only [CarbonNotificationKind.info] (the default)
  /// and [CarbonNotificationKind.warning] are supported, matching upstream.
  final CarbonNotificationKind kind;

  /// The optional bold title.
  final String? title;

  /// The optional subtitle.
  final String? subtitle;

  /// The optional action button label; null hides the action.
  final String? actionLabel;

  /// The action; null disables the action button.
  final VoidCallback? onAction;

  /// Whether to use the light low-contrast surface.
  final bool lowContrast;

  /// The accessible description of the status icon; defaults to
  /// `'<kind> icon'` (for example `info icon`), matching upstream.
  final String? statusIconDescription;

  @override
  Widget build(BuildContext context) {
    return _NotificationBar(
      kind: kind,
      title: title,
      subtitle: subtitle,
      lowContrast: lowContrast,
      liveRegion: false,
      actionLabel: actionLabel,
      onAction: onAction,
      statusIconDescription: statusIconDescription,
    );
  }
}

/// The shared md+ bar layout of the inline, actionable, and callout variants.
class _NotificationBar extends StatelessWidget {
  const _NotificationBar({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.lowContrast,
    required this.liveRegion,
    required this.statusIconDescription,
    this.actionLabel,
    this.onAction,
    this.onClose,
    this.closeLabel = '',
  });

  final CarbonNotificationKind kind;
  final String? title;
  final String? subtitle;
  final bool lowContrast;
  final bool liveRegion;
  final String? statusIconDescription;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onClose;
  final String closeLabel;

  /// The max-inline-size steps: 608px from md, 736px from lg, 832px from the
  /// max breakpoint (resolved against the available width).
  static double _maxInlineSize(double available) {
    if (available >= CarbonBreakpoint.max.width) {
      return 832;
    }
    if (available >= CarbonBreakpoint.lg.width) {
      return 736;
    }
    return 608;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final _KindStyle style = _KindStyle.of(kind, theme, lowContrast);
    final Color textColor = lowContrast ? theme.textPrimary : theme.textInverse;

    // __text-wrapper (padding-block 15px) with the title/subtitle laid out
    // inline and wrapping; __title carries margin-inline-end $spacing-02.
    final Widget textWrapper = Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: CarbonSpacing.spacing02,
        children: <Widget>[
          if (title != null)
            Text(
              title!,
              style: CarbonTypeStyles.headingCompact01.copyWith(
                color: textColor,
              ),
            ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: CarbonTypeStyles.bodyCompact01.copyWith(color: textColor),
            ),
        ],
      ),
    );

    final Widget bar = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double available = constraints.maxWidth;
        final double maxWidth = available.isFinite
            ? _maxInlineSize(available)
            : 832.0;
        return Align(
          // max-inline-size caps the bar even when the parent is wider
          // (Align loosens a tight parent constraint, like CSS max-width
          // winning over inline-size: 100%); the factors shrink-wrap it in
          // loose ones.
          alignment: AlignmentDirectional.topStart,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 48,
              minWidth: available.isFinite && available < 288 ? available : 288,
              maxWidth: maxWidth,
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: lowContrast ? style.tint : theme.backgroundInverse,
                      border: BorderDirectional(
                        start: BorderSide(color: style.accent, width: 3),
                      ),
                    ),
                  ),
                ),
                // Low contrast draws a 1px border at 40% opacity over the top,
                // end, and bottom edges (::before, border-width 1px 1px 1px 0).
                // The overlay is anchored to the padding box upstream, so it
                // starts after the 3px status bar.
                if (lowContrast)
                  PositionedDirectional(
                    start: 3,
                    top: 0,
                    end: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            top: BorderSide(
                              color: style.accent.withValues(alpha: 0.4),
                            ),
                            end: BorderSide(
                              color: style.accent.withValues(alpha: 0.4),
                            ),
                            bottom: BorderSide(
                              color: style.accent.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // 3px status-bar border + __details margin-inline-start
                    // 13px (the border paints under this box, so the content
                    // inset is their sum).
                    const SizedBox(width: 16),
                    Padding(
                      // __icon: margin-block-start 14px, margin-inline-end
                      // $spacing-05.
                      padding: const EdgeInsetsDirectional.only(
                        top: 14,
                        end: CarbonSpacing.spacing05,
                      ),
                      child: _StatusIcon(
                        style: style,
                        description:
                            statusIconDescription ?? '${kind.carbonName} icon',
                      ),
                    ),
                    Expanded(child: textWrapper),
                    // __details margin-inline-end: 13px.
                    const SizedBox(width: 13),
                    if (actionLabel != null)
                      Padding(
                        // Ghost action button margin: $spacing-03 0; with the
                        // close button hidden it also gets margin-inline-end
                        // $spacing-03.
                        padding: EdgeInsetsDirectional.only(
                          top: CarbonSpacing.spacing03,
                          bottom: CarbonSpacing.spacing03,
                          end: onClose == null ? CarbonSpacing.spacing03 : 0,
                        ),
                        child: _ActionButton(
                          label: actionLabel!,
                          onPressed: onAction,
                          lowContrast: lowContrast,
                        ),
                      ),
                    if (onClose != null)
                      _CloseButton(
                        onClose: onClose!,
                        label: closeLabel,
                        lowContrast: lowContrast,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      explicitChildNodes: true,
      label: liveRegion ? '$title. ${subtitle ?? ''}'.trim() : null,
      child: bar,
    );
  }
}

/// The 20px status icon; the warning kinds paint their inner exclamation
/// path in `black-100` on top, per the notification SCSS.
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.style, required this.description});

  final _KindStyle style;
  final String description;

  @override
  Widget build(BuildContext context) {
    final Widget icon = CarbonIcon(
      style.icon,
      size: 20,
      color: style.accent,
      semanticLabel: description,
    );
    final CarbonIconData? innerPath = style.innerPath;
    if (innerPath == null) {
      return icon;
    }
    return SizedBox.square(
      dimension: 20,
      child: Stack(
        children: <Widget>[
          icon,
          ExcludeSemantics(
            child: CarbonIcon(
              innerPath,
              size: 20,
              color: CarbonColors.black100,
            ),
          ),
        ],
      ),
    );
  }
}

/// The ghost action button of the actionable and callout variants.
///
/// High contrast recolors the ghost treatment for the inverse surface:
/// `linkInverse` text, `backgroundInverseHover` hover/active fill, and a
/// `focusInverse` outline. Low contrast keeps the ghost link colors with the
/// `notificationActionHover` hover fill and the normal focus outline.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.lowContrast,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool lowContrast;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: CarbonInteraction(
        enabled: onPressed != null,
        onPressed: onPressed,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool hovered =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed);
          final bool focused = states.contains(WidgetState.focused);
          final Color text = lowContrast
              ? (hovered ? theme.linkPrimaryHover : theme.linkPrimary)
              : theme.linkInverse;
          final Color? fill = hovered
              ? (lowContrast
                    ? theme.notificationActionHover
                    : theme.backgroundInverseHover)
              : null;
          final Color focusColor = lowContrast
              ? theme.focus
              : theme.focusInverse;
          return Container(
            height: 32,
            padding: const EdgeInsets.symmetric(
              horizontal: CarbonSpacing.spacing05,
            ),
            color: fill,
            // outline: 2px solid, outline-offset: -2px — painted over the
            // content so focus does not shift layout.
            foregroundDecoration: focused
                ? BoxDecoration(border: Border.all(color: focusColor, width: 2))
                : null,
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: Text(
                label,
                style: CarbonTypeStyles.bodyCompact01.copyWith(color: text),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The 48px square close control shared by the dismissible variants.
class _CloseButton extends StatelessWidget {
  const _CloseButton({
    required this.onClose,
    required this.label,
    required this.lowContrast,
  });

  final VoidCallback onClose;
  final String label;
  final bool lowContrast;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Color iconColor = lowContrast ? theme.iconPrimary : theme.iconInverse;
    final Color focusColor = lowContrast ? theme.focus : theme.focusInverse;
    return Semantics(
      button: true,
      label: label,
      child: CarbonInteraction(
        onPressed: onClose,
        builder: (BuildContext context, Set<WidgetState> states) {
          final bool focused = states.contains(WidgetState.focused);
          return Container(
            width: 48,
            height: 48,
            // outline: 2px solid; outline-offset: -2px — painted over the
            // content so focus does not shift layout.
            foregroundDecoration: focused
                ? BoxDecoration(border: Border.all(color: focusColor, width: 2))
                : null,
            child: Center(
              child: ExcludeSemantics(
                child: CarbonIcon(CarbonIcons.close, color: iconColor),
              ),
            ),
          );
        },
      ),
    );
  }
}
