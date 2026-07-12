// Copyright 2026 Bizjak Tech OÜ
//
// This file is part of the Carbide gallery and is licensed under the
// Apache License, Version 2.0. See the LICENSE file in the project root.

import 'package:carbide/carbide.dart';
import 'package:flutter/widgets.dart';

import 'demo_scaffold.dart';

/// A labelled dropdown knob for picking one of [options].
Widget choiceKnob<T>({
  required String label,
  required T value,
  required List<T> options,
  required String Function(T) labelOf,
  required ValueChanged<T> onChanged,
}) {
  return DemoControl(
    label: label,
    child: CarbonDropdown<T>(
      titleText: label,
      hideLabel: true,
      selectedItem: value,
      items: <CarbonDropdownItem<T>>[
        for (final T option in options)
          CarbonDropdownItem<T>(value: option, label: labelOf(option)),
      ],
      onChanged: onChanged,
    ),
  );
}

/// A labelled toggle knob for a boolean prop.
Widget boolKnob({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return DemoControl(
    label: label,
    width: 260,
    child: CarbonToggle(
      labelText: label,
      hideLabel: true,
      toggled: value,
      onToggled: onChanged,
    ),
  );
}

/// A labelled slider knob for a numeric prop.
Widget sliderKnob({
  required String label,
  required double value,
  required double min,
  required double max,
  required ValueChanged<double> onChanged,
  double step = 1,
}) {
  return DemoControl(
    label: label,
    width: 360,
    child: CarbonSlider(
      value: value,
      min: min,
      max: max,
      step: step,
      hideTextInput: true,
      onChanged: (num v) => onChanged(v.toDouble()),
    ),
  );
}
