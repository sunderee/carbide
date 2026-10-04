// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the Apache
// License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

/// Native-browser specimen for the contrast policy.
///
/// Matches the public-component scene in `test/support/high_contrast_specimen.dart`.
/// Kept inside this package because Flutter web debug compilation cannot load
/// a relative source outside its application root.
class HighContrastSpecimen extends StatefulWidget {
  const HighContrastSpecimen({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<HighContrastSpecimen> createState() => HighContrastSpecimenState();
}

class HighContrastSpecimenState extends State<HighContrastSpecimen> {
  final buttonFocus = List.generate(3, (_) => FocusNode());

  @override
  void dispose() {
    for (final node in buttonFocus) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarbonTheme.of(context);
    return DefaultTextStyle(
      style: CarbonTypeStyles.body01.copyWith(color: theme.textPrimary),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var level = 0; level < 3; level++) ...[
                  if (level != 0) const SizedBox(width: 16),
                  Expanded(
                    child: CarbonLayer(
                      level: level,
                      child: Builder(
                        builder: (context) => _panel(context, level),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            const CarbonDataTable(
              title: 'Accounts',
              zebra: true,
              columns: [
                CarbonTableColumn(title: 'Name'),
                CarbonTableColumn(title: 'Role'),
              ],
              rows: [
                CarbonTableRow(id: 'ada', cells: [Text('Ada'), Text('Owner')]),
                CarbonTableRow(id: 'lin', cells: [Text('Lin'), Text('Reader')]),
                CarbonTableRow(id: 'sam', cells: [Text('Sam'), Text('Editor')]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, int level) {
    final theme = CarbonTheme.of(context);
    final layer = CarbonLayer.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: layer.layer,
        border: Border.all(color: layer.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Layer ${level + 1}'),
            const SizedBox(height: 16),
            CarbonTextInput(
              labelText: 'Name ${level + 1}',
              placeholder: 'Enter a name',
              helperText: 'Account owner',
            ),
            const SizedBox(height: 16),
            CarbonTextInput(
              labelText: 'Disabled ${level + 1}',
              initialValue: 'Locked',
              disabled: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CarbonButton(
                    label: 'Run ${level + 1}',
                    focusNode: buttonFocus[level],
                    onPressed: widget.onPressed ?? () {},
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: CarbonButton(label: 'Inactive')),
              ],
            ),
            const SizedBox(height: 16),
            CarbonCheckbox(
              label: 'Unavailable ${level + 1}',
              value: true,
              disabled: true,
            ),
            const SizedBox(height: 16),
            const CarbonSelectableTile(
              selected: true,
              child: Text('Chosen tile'),
            ),
            const SizedBox(height: 16),
            CarbonFocusRing(
              visible: true,
              inset: true,
              child: ColoredBox(
                color: layer.field,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Focus stroke',
                    style: CarbonTypeStyles.body01.copyWith(
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
