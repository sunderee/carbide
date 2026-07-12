// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   styles/scss/components/file-uploader/_file-uploader.scss
//   react/src/components/FileUploader/{FileUploader,FileUploaderButton,
//     FileUploaderDropContainer,FileUploaderItem,Filename}.tsx
//
// The file uploader family: a button (or dashed drop container) that opens the
// host's file picker, plus a list of selected-file rows showing per-file
// status (uploading / complete / edit-to-remove) and invalid errors. The
// picker and platform drag-and-drop are app-provided via callbacks; the
// widgets are pure presentation. Reuses Button (#43), Loading and the form
// primitives (#66).

import 'dart:ui' show PathMetric;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundations/layout.dart';
import '../../foundations/typography.dart';
import '../../icons/carbon_icon.dart';
import '../../icons/carbon_icons.dart';
import '../../theme/carbon_layer.dart';
import '../../theme/carbon_theme.dart';
import '../../theme/carbon_theme_data.dart';
import '../../utils/focus_ring.dart';
import '../button/carbon_button.dart';
import '../form/carbon_form.dart';
import '../loading/carbon_loading.dart';

/// The upload status of a [CarbonFileUploaderItem].
enum CarbonFileStatus {
  /// The file is uploading; shows a spinner.
  uploading,

  /// The file can be removed; shows a close control.
  edit,

  /// The upload finished; shows a checkmark.
  complete,
}

/// A button that opens the host's file picker.
///
/// The picker itself is app-provided: wire [onPressed] to your platform's
/// file-selection flow and feed the result back as [CarbonFileUploaderItem]s.
class CarbonFileUploaderButton extends StatelessWidget {
  /// Creates a file-uploader button.
  const CarbonFileUploaderButton({
    super.key,
    this.label = 'Add file',
    this.onPressed,
    this.kind = CarbonButtonKind.primary,
    this.size = CarbonButtonSize.md,
  });

  /// The button text.
  final String label;

  /// Opens the file picker; the button is disabled when null.
  final VoidCallback? onPressed;

  /// The button kind.
  final CarbonButtonKind kind;

  /// The button size.
  final CarbonButtonSize size;

  @override
  Widget build(BuildContext context) => CarbonButton(
    label: label,
    onPressed: onPressed,
    kind: kind,
    size: size,
    icon: CarbonIcons.add,
  );
}

/// A dashed drag-and-drop zone that also opens the file picker on click.
///
/// Platform file drag-and-drop is app-provided: set [dragOver] from your drag
/// callbacks to show the highlight, and open the picker from [onPressed].
class CarbonFileUploaderDropContainer extends StatefulWidget {
  /// Creates a drop container.
  const CarbonFileUploaderDropContainer({
    required this.label,
    super.key,
    this.onPressed,
    this.dragOver = false,
    this.disabled = false,
  });

  /// The instructional label, e.g. 'Drag and drop files here or click'.
  final String label;

  /// Opens the file picker; disabled when null or [disabled].
  final VoidCallback? onPressed;

  /// Whether a file is currently dragged over (drives the focus highlight).
  final bool dragOver;

  /// Whether the container is disabled.
  final bool disabled;

  /// The drop-container height (`block-size: 6rem`).
  static const double height = 96;

  @override
  State<CarbonFileUploaderDropContainer> createState() =>
      _CarbonFileUploaderDropContainerState();
}

class _CarbonFileUploaderDropContainerState
    extends State<CarbonFileUploaderDropContainer> {
  bool _focused = false;

  VoidCallback? get _action => widget.disabled ? null : widget.onPressed;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (_action != null &&
        event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _action!();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final Color border = widget.disabled
        ? theme.buttonDisabled
        : theme.borderStrong01;
    final Color text = widget.disabled ? theme.textDisabled : theme.textPrimary;

    return Semantics(
      button: true,
      enabled: _action != null,
      label: widget.label,
      onTap: _action,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: widget.disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _action,
            child: Focus(
              onKeyEvent: _onKey,
              onFocusChange: (bool f) => setState(() => _focused = f),
              // Drag-over and focus both paint the 2px focus outline
              // (`outline: 2px solid $focus; outline-offset: -2px`).
              child: CarbonFocusRing(
                visible: _focused || widget.dragOver,
                inset: true,
                child: CustomPaint(
                  // `border: 1px dashed` — Flutter has no dashed border, so
                  // it is stroked by hand.
                  painter: _DashedBorderPainter(color: border),
                  child: SizedBox(
                    height: CarbonFileUploaderDropContainer.height,
                    child: Padding(
                      padding: const EdgeInsets.all(CarbonSpacing.spacing05),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              widget.label,
                              style: CarbonTypeStyles.bodyCompact01.copyWith(
                                color: text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

/// Strokes a 1px dashed rectangle around the drop container.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const double _dash = 4;
  static const double _gap = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // Inset by half the stroke so the dashes sit inside the bounds.
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1));
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + _dash), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

/// A selected-file row: the filename, a status icon, and (when [invalid]) an
/// error message.
class CarbonFileUploaderItem extends StatefulWidget {
  /// Creates a selected-file row.
  const CarbonFileUploaderItem({
    required this.name,
    super.key,
    this.status = CarbonFileStatus.edit,
    this.size = CarbonFieldSize.md,
    this.invalid = false,
    this.errorSubject,
    this.errorBody,
    this.onDelete,
    this.disabled = false,
  });

  /// The file name.
  final String name;

  /// The upload status.
  final CarbonFileStatus status;

  /// The row height band (sm 32 / md 40 / lg 48).
  final CarbonFieldSize size;

  /// Whether the file failed validation.
  final bool invalid;

  /// The error title shown when [invalid].
  final String? errorSubject;

  /// The error detail shown when [invalid].
  final String? errorBody;

  /// Removes the file (shown for [CarbonFileStatus.edit]).
  final VoidCallback? onDelete;

  /// Whether the row is disabled.
  final bool disabled;

  @override
  State<CarbonFileUploaderItem> createState() => _CarbonFileUploaderItemState();
}

class _CarbonFileUploaderItemState extends State<CarbonFileUploaderItem> {
  bool _deleteFocused = false;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);
    final Color text = widget.disabled ? theme.textDisabled : theme.textPrimary;

    final Widget row = SizedBox(
      // Base min height; the invalid wrapper adds its own padding.
      height: widget.invalid ? null : widget.size.height,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: CarbonSpacing.spacing05,
              ),
              child: Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: CarbonTypeStyles.bodyCompact01.copyWith(color: text),
              ),
            ),
          ),
          _StateContainer(
            status: widget.status,
            invalid: widget.invalid,
            disabled: widget.disabled,
            deleteFocused: _deleteFocused,
            onDelete: widget.onDelete,
            onDeleteFocusChange: (bool f) => setState(() => _deleteFocused = f),
          ),
        ],
      ),
    );

    final Widget content = widget.invalid
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              row,
              if (widget.errorSubject != null || widget.errorBody != null)
                _ErrorRequirement(
                  subject: widget.errorSubject,
                  body: widget.errorBody,
                ),
            ],
          )
        : row;

    final Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: layer.layer,
        // `focus-outline('invalid')` — a 1px support-error outline.
        border: widget.invalid ? Border.all(color: theme.supportError) : null,
      ),
      child: widget.invalid
          ? Padding(
              // `padding: spacing-03 0` for the md invalid row.
              padding: const EdgeInsets.symmetric(
                vertical: CarbonSpacing.spacing03,
              ),
              child: content,
            )
          : content,
    );

    // A container so the row is one group, with explicit children so the
    // filename and the remove control stay separately discoverable.
    return Semantics(container: true, explicitChildNodes: true, child: box);
  }
}

/// The trailing status cell: spinner, checkmark, or remove control, with a
/// leading warning icon when the row is invalid.
class _StateContainer extends StatelessWidget {
  const _StateContainer({
    required this.status,
    required this.invalid,
    required this.disabled,
    required this.deleteFocused,
    required this.onDelete,
    required this.onDeleteFocusChange,
  });

  final CarbonFileStatus status;
  final bool invalid;
  final bool disabled;
  final bool deleteFocused;
  final VoidCallback? onDelete;
  final ValueChanged<bool> onDeleteFocusChange;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);

    return Padding(
      // `padding-inline-end: 12px`; `min-inline-size: 1.5rem`.
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (invalid) ...<Widget>[
              CarbonIcon(CarbonIcons.warningFilled, color: theme.supportError),
              const SizedBox(width: CarbonSpacing.spacing03),
            ],
            switch (status) {
              CarbonFileStatus.uploading => const CarbonLoading(
                small: true,
                description: 'Uploading',
              ),
              CarbonFileStatus.complete => CarbonIcon(
                CarbonIcons.checkmarkFilled,
                size: 16,
                color: theme.interactive,
              ),
              CarbonFileStatus.edit => _DeleteButton(
                disabled: disabled,
                focused: deleteFocused,
                onDelete: onDelete,
                onFocusChange: onDeleteFocusChange,
              ),
            },
          ],
        ),
      ),
    );
  }
}

/// The close (remove) control for an editable item.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.disabled,
    required this.focused,
    required this.onDelete,
    required this.onFocusChange,
  });

  final bool disabled;
  final bool focused;
  final VoidCallback? onDelete;
  final ValueChanged<bool> onFocusChange;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final VoidCallback? action = disabled ? null : onDelete;

    return Semantics(
      button: true,
      enabled: action != null,
      label: 'Remove file',
      onTap: action,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: disabled
              ? SystemMouseCursors.forbidden
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: action,
            child: Focus(
              onKeyEvent: (FocusNode node, KeyEvent event) {
                if (action != null &&
                    event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.space)) {
                  action();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              onFocusChange: onFocusChange,
              child: CarbonFocusRing(
                visible: focused,
                inset: true,
                child: SizedBox.square(
                  dimension: CarbonSpacing.spacing06,
                  child: Center(
                    child: CarbonIcon(
                      CarbonIcons.close,
                      color: disabled ? theme.iconDisabled : theme.iconPrimary,
                    ),
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

/// The invalid-item error block: a top divider then the error subject/body.
class _ErrorRequirement extends StatelessWidget {
  const _ErrorRequirement({required this.subject, required this.body});

  final String? subject;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    final CarbonLayerTokens layer = CarbonLayer.of(context);

    return Container(
      margin: const EdgeInsets.only(top: CarbonSpacing.spacing05),
      padding: const EdgeInsets.symmetric(horizontal: CarbonSpacing.spacing05),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: layer.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: CarbonSpacing.spacing05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (subject != null)
              Text(
                subject!,
                style: CarbonTypeStyles.helperText01.copyWith(
                  color: theme.textError,
                ),
              ),
            if (body != null)
              Text(
                body!,
                style: CarbonTypeStyles.helperText01.copyWith(
                  color: theme.textPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The labelled file-uploader container: an optional title and description, the
/// upload control ([CarbonFileUploaderButton] or
/// [CarbonFileUploaderDropContainer]), and the list of selected files.
class CarbonFileUploader extends StatelessWidget {
  /// Creates a file uploader.
  const CarbonFileUploader({
    super.key,
    this.labelTitle,
    this.labelDescription,
    this.child,
    this.items = const <CarbonFileUploaderItem>[],
    this.disabled = false,
  });

  /// The bold heading above the control.
  final String? labelTitle;

  /// The secondary description below the heading.
  final String? labelDescription;

  /// The upload control.
  final Widget? child;

  /// The selected-file rows.
  final List<CarbonFileUploaderItem> items;

  /// Whether the whole uploader is disabled (affects the labels).
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (labelTitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing03),
            child: Text(
              labelTitle!,
              style: CarbonTypeStyles.headingCompact01.copyWith(
                color: disabled ? theme.textDisabled : theme.textPrimary,
              ),
            ),
          ),
        if (labelDescription != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing05),
            child: Text(
              labelDescription!,
              style: CarbonTypeStyles.bodyCompact01.copyWith(
                color: disabled ? theme.textDisabled : theme.textSecondary,
              ),
            ),
          ),
        ?child,
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: CarbonSpacing.spacing05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < items.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: CarbonSpacing.spacing03),
                  items[i],
                ],
              ],
            ),
          ),
      ],
    );
  }
}
