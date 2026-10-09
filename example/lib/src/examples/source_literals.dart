// Copyright 2026 Bizjak Tech OÜ

import 'dart:convert';

import 'package:carbide/carbide.dart';

/// An immutable snapshot used to fill a source template from the real preview.
class ExampleConfiguration {
  /// Copies the current field literals, retaining no mutable page state.
  ExampleConfiguration(Map<String, String> values)
    : values = Map<String, String>.unmodifiable(values);

  /// Dart literals for the preview's current field values.
  final Map<String, String> values;

  /// Fills only exact field markers; missing snapshots fail visibly.
  String fill(String template) {
    final String result = template.replaceAllMapped(
      RegExp(r'@@(_\w+)@@'),
      (Match match) =>
          values[match[1]] ??
          (throw StateError('Missing example configuration ${match[1]}')),
    );
    return result;
  }
}

/// A Dart string literal, including quotes and escaped interpolation markers.
String sourceString(String value) => jsonEncode(value).replaceAll(r'$', r'\$');

/// A Dart DateTime expression preserving the current picker value.
String sourceDate(DateTime? value) => value == null
    ? 'null'
    : 'DateTime(${value.year}, ${value.month}, ${value.day})';

/// A literal for scalar gallery settings and string record identities.
String sourceValue(Object? value) => switch (value) {
  null => 'null',
  String value => sourceString(value),
  bool value => '$value',
  num value when value.isFinite => '$value',
  _ => throw ArgumentError.value(value, 'value', 'Unsupported example value'),
};

/// A typed set literal preserving selected/expanded record identities.
String sourceSet(Iterable<Object> values, String type) =>
    '<$type>{${values.map(sourceValue).join(', ')}}';

/// A range expression preserving both committed dates.
String sourceRange(CarbonDateRange? value) => value == null
    ? 'null'
    : 'CarbonDateRange(${sourceDate(value.start)}, ${sourceDate(value.end)})';
