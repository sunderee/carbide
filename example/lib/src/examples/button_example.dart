// Copyright 2026 Bizjak Tech OÜ

import 'package:carbide/carbide.dart';

/// Immutable settings shared by the Button preview and its copied example.
class ButtonExample {
  /// Captures the current gallery controls.
  const ButtonExample({
    required this.kind,
    required this.size,
    required this.withIcon,
    required this.enabled,
    required this.expressive,
  });

  /// The Carbon visual treatment.
  final CarbonButtonKind kind;

  /// The Carbon density.
  final CarbonButtonSize size;

  /// Whether to show the add icon.
  final bool withIcon;

  /// Whether the button can be activated.
  final bool enabled;

  /// Whether to use expressive typography.
  final bool expressive;

  /// Builds the live preview using these settings.
  CarbonButton build() => CarbonButton(
    label: 'Button',
    kind: kind,
    size: size,
    icon: withIcon ? CarbonIcons.add : null,
    isExpressive: expressive,
    onPressed: enabled ? () {} : null,
  );

  /// A complete widget class using the same settings.
  String get code =>
      "import 'package:carbide/carbide.dart';\n"
      "import 'package:flutter/widgets.dart';\n\n"
      'class ButtonExample extends StatelessWidget {\n'
      '  const ButtonExample({super.key});\n\n'
      '  @override\n'
      '  Widget build(BuildContext context) => $_expression;\n'
      '}\n';

  String get _expression =>
      "CarbonButton(\n"
      "  label: 'Button',\n"
      '  kind: CarbonButtonKind.${kind.name},\n'
      '  size: CarbonButtonSize.${size.name},\n'
      '${withIcon ? '  icon: CarbonIcons.add,\n' : ''}'
      '  isExpressive: $expressive,\n'
      '  onPressed: ${enabled ? '() {}' : 'null'},\n'
      ')';
}
