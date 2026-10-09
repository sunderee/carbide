// Copyright 2026 Bizjak Tech OÜ

import 'package:carbide_gallery/src/examples/source_literals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('example snapshots own immutable values and fill once', () {
    final Map<String, String> values = <String, String>{'_label': '"Original"'};
    final ExampleConfiguration config = ExampleConfiguration(values);
    values['_label'] = '"Changed"';
    expect(config.fill('Text(@@_label@@)'), 'Text("Original")');
    expect(() => config.values['_label'] = '"Mutated"', throwsUnsupportedError);
    expect(() => config.fill('Text(@@_missing@@)'), throwsStateError);
    expect(
      ExampleConfiguration(<String, String>{'_label': '"@@_missing@@"'})
          .fill('Text(@@_label@@)'),
      'Text("@@_missing@@")',
    );
  });

  test('text literals escape quotes, controls and interpolation markers', () {
    expect(sourceString('a"b\nc\$d'), r'"a\"b\nc\$d"');
    expect(sourceValue(null), 'null');
    expect(sourceValue(true), 'true');
    expect(sourceValue(3.5), '3.5');
    expect(sourceSet(<Object>{'stable-id'}, 'Object'), '<Object>{"stable-id"}');
    expect(() => sourceValue(double.nan), throwsArgumentError);
    expect(() => sourceValue(Object()), throwsArgumentError);
  });
}
