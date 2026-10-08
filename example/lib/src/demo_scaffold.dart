// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// Marks the live-preview surface of a [DemoScaffold] so screenshot tooling can
/// capture just the component (see `test/contact_sheet_test.dart`). It also
/// isolates the preview's repaint layer, which is harmless in the app.
const Key kDemoPreviewKey = ValueKey<String>('carbide-demo-preview');

/// The standard layout for a component demo page: a heading, a live preview
/// surface, an optional set of interactive controls, and an optional code
/// snippet.
class DemoScaffold extends StatelessWidget {
  /// Creates a demo page layout.
  const DemoScaffold({
    required this.title,
    required this.preview,
    super.key,
    this.description,
    this.controls = const <Widget>[],
    this.code,
    this.previewAlignment = Alignment.center,
  });

  /// The component name.
  final String title;

  /// A one-line summary shown under the title.
  final String? description;

  /// The live component(s) under test.
  final Widget preview;

  /// Interactive knobs that drive [preview].
  final List<Widget> controls;

  /// A code snippet reflecting the current preview.
  final String? code;

  /// How the preview is aligned within its surface.
  final Alignment previewAlignment;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: CarbonSpacing.spacing09),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            headingLevel: 1,
            child: Text(title, style: CarbonTypeStyles.productiveHeading05),
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: CarbonSpacing.spacing03),
            Text(
              description!,
              style: CarbonTypeStyles.body01.copyWith(
                color: theme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: CarbonSpacing.spacing07),
          RepaintBoundary(
            key: kDemoPreviewKey,
            child: _PreviewSurface(alignment: previewAlignment, child: preview),
          ),
          if (controls.isNotEmpty) ...<Widget>[
            const SizedBox(height: CarbonSpacing.spacing07),
            const _SectionLabel('Controls'),
            const SizedBox(height: CarbonSpacing.spacing05),
            Wrap(
              spacing: CarbonSpacing.spacing07,
              runSpacing: CarbonSpacing.spacing05,
              children: controls,
            ),
          ],
          if (code != null) ...<Widget>[
            const SizedBox(height: CarbonSpacing.spacing07),
            const _SectionLabel('Code'),
            const SizedBox(height: CarbonSpacing.spacing05),
            _CodeBlock(code!),
          ],
        ],
      ),
    );
  }
}

/// A bordered, layer-tinted surface that hosts the live preview.
class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.child, required this.alignment});

  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.layer01,
        border: Border.all(color: theme.borderSubtle01),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        alignment: alignment,
        padding: const EdgeInsets.all(CarbonSpacing.spacing07),
        child: child,
      ),
    );
  }
}

/// A small uppercase section heading.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return Text(
      text,
      style: CarbonTypeStyles.heading01.copyWith(color: theme.textPrimary),
    );
  }
}

/// A monospace code block on a contextual layer surface.
class _CodeBlock extends StatelessWidget {
  const _CodeBlock(this.code);

  final String code;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: theme.layer01),
      child: Padding(
        padding: const EdgeInsets.all(CarbonSpacing.spacing05),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            code,
            style: CarbonTypeStyles.code01.copyWith(color: theme.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// A labelled wrapper for a single knob control, used inside [DemoScaffold].
class DemoControl extends StatelessWidget {
  /// Creates a labelled knob control.
  const DemoControl({
    required this.label,
    required this.child,
    super.key,
    this.width = 220,
  });

  /// The control's caption.
  final String label;

  /// The knob widget itself.
  final Widget child;

  /// The fixed width of the control column.
  final double width;

  @override
  Widget build(BuildContext context) {
    final CarbonThemeData theme = CarbonTheme.of(context);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: CarbonTypeStyles.label01.copyWith(
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: CarbonSpacing.spacing03),
          child,
        ],
      ),
    );
  }
}
