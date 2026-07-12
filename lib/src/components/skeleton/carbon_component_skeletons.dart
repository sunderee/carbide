// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of Carbide and is licensed under the Apache License,
// Version 2.0. See the LICENSE file in the project root.
//
// Spec sources (Apache-2.0 Carbon Design System; see NOTICE):
//   react/src/components/*/*.Skeleton.tsx and DataTableSkeleton
//   styles/scss/components/skeleton-styles/_skeleton-styles.scss
//
// Component-specific loading skeletons, composed from CarbonSkeleton. Each
// mimics the footprint of its component (a label + field bar, a selection
// control, or a structural grid of shimmer cells).

import 'package:flutter/widgets.dart';

import '../../theme/carbon_layer.dart';
import '../../foundations/layout.dart';
import 'carbon_skeleton.dart';

// A label placeholder bar (label-01 line) used above form fields.
Widget _label() => const CarbonSkeleton(width: 75, height: 14);

// A field-shaped skeleton: a label bar above a full-width field bar. The
// fluid variant is a single 64px field with the label bar inside (each
// upstream Fluid* component ships a matching `.Skeleton`).
class _FieldSkeleton extends StatelessWidget {
  const _FieldSkeleton({
    this.fieldHeight = 40,
    this.hideLabel = false,
    this.fluid = false,
  });

  final double fieldHeight;
  final bool hideLabel;
  final bool fluid;

  @override
  Widget build(BuildContext context) {
    if (fluid) {
      return SizedBox(
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CarbonLayer.of(context).field,
            border: Border(
              bottom: BorderSide(color: CarbonLayer.of(context).borderSubtle),
            ),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: CarbonSpacing.spacing05,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _label(),
                const SizedBox(height: CarbonSpacing.spacing03),
                const CarbonSkeleton(width: 160, height: 14),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (!hideLabel) ...<Widget>[
          _label(),
          const SizedBox(height: CarbonSpacing.spacing03),
        ],
        CarbonSkeleton(height: fieldHeight),
      ],
    );
  }
}

/// A loading placeholder for a text input.
class CarbonTextInputSkeleton extends StatelessWidget {
  /// Creates a text-input skeleton.
  const CarbonTextInputSkeleton({
    super.key,
    this.hideLabel = false,
    this.fluid = false,
  });

  /// Whether to omit the label bar.
  final bool hideLabel;

  /// The fluid variant: a single 64px field with the label bar inside.
  final bool fluid;

  @override
  Widget build(BuildContext context) =>
      _FieldSkeleton(hideLabel: hideLabel, fluid: fluid);
}

/// A loading placeholder for a text area.
class CarbonTextAreaSkeleton extends StatelessWidget {
  /// Creates a text-area skeleton.
  const CarbonTextAreaSkeleton({super.key, this.hideLabel = false});

  /// Whether to omit the label bar.
  final bool hideLabel;

  @override
  Widget build(BuildContext context) =>
      _FieldSkeleton(fieldHeight: 100, hideLabel: hideLabel);
}

/// A loading placeholder for a number input.
class CarbonNumberInputSkeleton extends StatelessWidget {
  /// Creates a number-input skeleton.
  const CarbonNumberInputSkeleton({super.key, this.hideLabel = false});

  /// Whether to omit the label bar.
  final bool hideLabel;

  @override
  Widget build(BuildContext context) => _FieldSkeleton(hideLabel: hideLabel);
}

/// A loading placeholder for a select.
class CarbonSelectSkeleton extends StatelessWidget {
  /// Creates a select skeleton.
  const CarbonSelectSkeleton({
    super.key,
    this.hideLabel = false,
    this.fluid = false,
  });

  /// Whether to omit the label bar.
  final bool hideLabel;

  /// The fluid variant: a single 64px field with the label bar inside.
  final bool fluid;

  @override
  Widget build(BuildContext context) =>
      _FieldSkeleton(hideLabel: hideLabel, fluid: fluid);
}

/// A loading placeholder for a dropdown.
class CarbonDropdownSkeleton extends StatelessWidget {
  /// Creates a dropdown skeleton.
  const CarbonDropdownSkeleton({
    super.key,
    this.hideLabel = false,
    this.fluid = false,
  });

  /// Whether to omit the label bar.
  final bool hideLabel;

  /// The fluid variant: a single 64px field with the label bar inside.
  final bool fluid;

  @override
  Widget build(BuildContext context) =>
      _FieldSkeleton(hideLabel: hideLabel, fluid: fluid);
}

/// A loading placeholder for a date picker.
class CarbonDatePickerSkeleton extends StatelessWidget {
  /// Creates a date-picker skeleton.
  const CarbonDatePickerSkeleton({super.key, this.hideLabel = false});

  /// Whether to omit the label bar.
  final bool hideLabel;

  @override
  Widget build(BuildContext context) => _FieldSkeleton(hideLabel: hideLabel);
}

/// A loading placeholder for a search field (full-width 40px bar).
class CarbonSearchSkeleton extends StatelessWidget {
  /// Creates a search skeleton.
  const CarbonSearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const CarbonSkeleton(height: 40);
}

// A selection control skeleton: a small shape + a label bar.
class _SelectionSkeleton extends StatelessWidget {
  const _SelectionSkeleton({required this.shape});

  final Widget shape;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        shape,
        const SizedBox(width: CarbonSpacing.spacing03),
        const CarbonSkeleton(width: 100, height: 14),
      ],
    );
  }
}

/// A loading placeholder for a checkbox.
class CarbonCheckboxSkeleton extends StatelessWidget {
  /// Creates a checkbox skeleton.
  const CarbonCheckboxSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const _SelectionSkeleton(shape: CarbonSkeleton(width: 16, height: 16));
}

/// A loading placeholder for a radio button.
class CarbonRadioButtonSkeleton extends StatelessWidget {
  /// Creates a radio-button skeleton.
  const CarbonRadioButtonSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _SelectionSkeleton(
    shape: CarbonSkeleton(
      width: 16,
      height: 16,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

/// A loading placeholder for a toggle.
class CarbonToggleSkeleton extends StatelessWidget {
  /// Creates a toggle skeleton.
  const CarbonToggleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _label(),
        const SizedBox(height: CarbonSpacing.spacing03),
        CarbonSkeleton(
          width: 48,
          height: 24,
          borderRadius: BorderRadius.circular(24),
        ),
      ],
    );
  }
}

/// A loading placeholder for a slider.
class CarbonSliderSkeleton extends StatelessWidget {
  /// Creates a slider skeleton.
  const CarbonSliderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _label(),
        const SizedBox(height: CarbonSpacing.spacing05),
        Row(
          children: <Widget>[
            const Expanded(child: CarbonSkeleton(height: 2)),
            const SizedBox(width: CarbonSpacing.spacing03),
            CarbonSkeleton(
              width: 14,
              height: 14,
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
      ],
    );
  }
}

/// A loading placeholder for a file uploader (label + drop button).
class CarbonFileUploaderSkeleton extends StatelessWidget {
  /// Creates a file-uploader skeleton.
  const CarbonFileUploaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _label(),
        const SizedBox(height: CarbonSpacing.spacing05),
        const CarbonSkeleton(width: 150, height: 40),
      ],
    );
  }
}

/// A loading placeholder for a tabs bar.
class CarbonTabsSkeleton extends StatelessWidget {
  /// Creates a tabs skeleton.
  const CarbonTabsSkeleton({super.key, this.count = 4});

  /// The number of tab placeholders.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: CarbonSpacing.spacing03),
          const CarbonSkeleton(width: 80, height: 40),
        ],
      ],
    );
  }
}

/// A loading placeholder for a breadcrumb trail.
class CarbonBreadcrumbSkeleton extends StatelessWidget {
  /// Creates a breadcrumb skeleton.
  const CarbonBreadcrumbSkeleton({super.key, this.count = 3});

  /// The number of breadcrumb placeholders.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: CarbonSpacing.spacing05),
          const CarbonSkeleton(width: 56, height: 14),
        ],
      ],
    );
  }
}

/// A loading placeholder for the pagination bar.
class CarbonPaginationSkeleton extends StatelessWidget {
  /// Creates a pagination skeleton.
  const CarbonPaginationSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const CarbonSkeleton(height: 40);
}

/// A loading placeholder for a progress indicator.
class CarbonProgressIndicatorSkeleton extends StatelessWidget {
  /// Creates a progress-indicator skeleton.
  const CarbonProgressIndicatorSkeleton({super.key, this.count = 4});

  /// The number of step placeholders.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0)
            const SizedBox(width: 40, child: CarbonSkeleton(height: 1)),
          CarbonSkeleton(
            width: 16,
            height: 16,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ],
    );
  }
}

/// A loading placeholder for an accordion.
class CarbonAccordionSkeleton extends StatelessWidget {
  /// Creates an accordion skeleton.
  const CarbonAccordionSkeleton({super.key, this.count = 4});

  /// The number of accordion-item placeholders.
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: const <Widget>[
                Expanded(child: CarbonSkeleton(height: 14)),
                SizedBox(width: CarbonSpacing.spacing05),
                CarbonSkeleton(width: 16, height: 16),
              ],
            ),
          ),
      ],
    );
  }
}

/// A loading placeholder for a structured list.
class CarbonStructuredListSkeleton extends StatelessWidget {
  /// Creates a structured-list skeleton.
  const CarbonStructuredListSkeleton({
    super.key,
    this.rowCount = 4,
    this.columnCount = 3,
  });

  /// The number of placeholder rows.
  final int rowCount;

  /// The number of placeholder columns.
  final int columnCount;

  @override
  Widget build(BuildContext context) =>
      _SkeletonGrid(rowCount: rowCount, columnCount: columnCount);
}

/// A loading placeholder for a data table.
class CarbonDataTableSkeleton extends StatelessWidget {
  /// Creates a data-table skeleton.
  const CarbonDataTableSkeleton({
    super.key,
    this.rowCount = 5,
    this.columnCount = 4,
  });

  /// The number of body rows.
  final int rowCount;

  /// The number of columns.
  final int columnCount;

  @override
  Widget build(BuildContext context) =>
      _SkeletonGrid(rowCount: rowCount, columnCount: columnCount, header: true);
}

/// A grid of shimmer cells shared by the table and structured-list skeletons.
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid({
    required this.rowCount,
    required this.columnCount,
    this.header = false,
  });

  final int rowCount;
  final int columnCount;
  final bool header;

  Widget _row({required bool isHeader}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      children: <Widget>[
        for (int c = 0; c < columnCount; c++) ...<Widget>[
          if (c > 0) const SizedBox(width: CarbonSpacing.spacing05),
          Expanded(child: CarbonSkeleton(height: isHeader ? 16 : 14)),
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (header) ...<Widget>[
          SizedBox(height: 40, child: Center(child: _row(isHeader: true))),
          const SizedBox(height: CarbonSpacing.spacing03),
        ],
        for (int r = 0; r < rowCount; r++)
          SizedBox(height: 40, child: Center(child: _row(isHeader: false))),
      ],
    );
  }
}
