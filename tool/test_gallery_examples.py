#!/usr/bin/env python3
"""Regression tests for source-derived gallery templates and live state fields."""

import unittest
from generate_gallery_examples import declarations, preview_only, template_for

WIDGET = """class _DemoPage extends StatefulWidget {
  const _DemoPage();
  @override
  State<_DemoPage> createState() => _DemoPageState();
}"""
STATE = """class _DemoPageState extends State<_DemoPage> {
  bool _enabled = true;
  String _label = 'Original';
  static const List<String> _options = <String>['unused knob'];
  @override
  Widget build(BuildContext context) {
    return DemoScaffold(
      preview: CarbonButton(label: _label, onPressed: _enabled ? () {} : null),
      controls: <Widget>[Text('knob')],
      code: exampleSource,
    );
  }
}"""


class GallerySourceTests(unittest.TestCase):
    def test_preview_source_is_the_only_constructor_definition(self):
        first = template_for(WIDGET, STATE)
        changed = template_for(WIDGET, STATE.replace("label: _label", "label: 'New label'"))
        self.assertNotEqual(first, changed)
        self.assertIn("label: 'New label'", changed)
        self.assertNotIn('DemoScaffold', first)
        self.assertNotIn('controls:', first)
        self.assertNotIn('_options', first)
        self.assertIn('class DemoExample', first)

    def test_mutable_fields_have_live_snapshot_markers(self):
        result = template_for(WIDGET, STATE)
        self.assertIn('bool _enabled = @@_enabled@@', result)
        self.assertIn("'_enabled': sourceValue(_enabled)", result)
        self.assertIn("'_label': sourceValue(_label)", result)

    def test_uninitialized_nullable_fields_are_preserved(self):
        state = STATE.replace("bool _enabled = true;", "int? _index;\n  bool _enabled = true;")
        result = template_for(WIDGET, state)
        self.assertIn('int? _index = @@_index@@;', result)

    def test_unknown_live_field_type_fails_for_review(self):
        state = STATE.replace("bool _enabled", "CustomPolicy _enabled")
        with self.assertRaisesRegex(ValueError, 'unsupported live example field'):
            template_for(WIDGET, state)

    def test_missing_or_ambiguous_preview_fails(self):
        for source in ["class Demo {}", STATE + STATE, STATE.replace('preview:', 'child:')]:
            with self.subTest(source=source), self.assertRaises(ValueError):
                preview_only(source)

    def test_comment_and_string_braces_do_not_change_class_extent(self):
        source = WIDGET + "\n// class _FakePage { }\n" + STATE.replace(
            "'Original'", "'a } bracket { in text'")
        result = declarations(source)
        self.assertEqual(set(result), {'_DemoPage', '_DemoPageState'})
        self.assertEqual(result['_DemoPage'], WIDGET)


if __name__ == '__main__':
    unittest.main()
