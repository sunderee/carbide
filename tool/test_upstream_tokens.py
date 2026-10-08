#!/usr/bin/env python3
"""Independent color and unsupported token-source regression checks."""

import json
from pathlib import Path
import tempfile
import unittest
from check_upstream_colors import compare, parse_snapshot
from generate_carbon_layout import dimension, emit_fixed_layout
from generate_carbon_motion import parse as parse_motion, emit as emit_motion

SNAPSHOT = '''exports[`@carbon/colors public API JavaScript exports 1`] = `
[
  "blue60: "#0f62fe"",
  "blue.60: "#0f62fe"",
]
`;'''


class IndependentColorsTest(unittest.TestCase):
    def test_wrong_generated_value_fails_independent_reader(self):
        self.assertEqual(compare(SNAPSHOT, 'static const Color blue60 = Color(0xFF0F62FE);'), 1)
        with self.assertRaisesRegex(ValueError, 'blue60'):
            compare(SNAPSHOT, 'static const Color blue60 = Color(0xFF000000);')
        with self.assertRaisesRegex(ValueError, 'Color API differs'):
            compare(SNAPSHOT, '')

    def test_unknown_snapshot_expression_fails_closed(self):
        with self.assertRaisesRegex(ValueError, 'Unsupported JS snapshot'):
            parse_snapshot(SNAPSHOT.replace('#0f62fe', 'rgb(1, 2, 3)'))


class TokenUnitsTest(unittest.TestCase):
    def test_layout_unit_conversions_and_unknown_units(self):
        self.assertEqual(dimension({'$type': 'dimension', '$value': '1.25rem'}), 20)
        self.assertEqual(dimension({'$type': 'dimension', '$value': 3, '$extensions': {'carbon.layout': {'converter': 'miniUnits'}}}), 24)
        with self.assertRaisesRegex(ValueError, 'Unsupported layout'):
            dimension({'$type': 'dimension', '$value': '2em'})

    def test_unknown_motion_unit_fails(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / 'motion.json'
            path.write_text(json.dumps({'duration': {'fast': {'01': {'$type': 'duration', '$value': {'unit': 's', 'value': 70}}}}, 'easing': {}}))
            with self.assertRaisesRegex(ValueError, 'Unsupported duration'):
                parse_motion(path)

    def test_new_motion_family_requires_public_api_review(self):
        source = 'static const Duration fast01 = Duration(milliseconds: 70);'
        with self.assertRaisesRegex(ValueError, 'Duration family changed'):
            emit_motion(source, {'fast01': 70, 'fast03': 180}, {})

    def test_layout_family_and_grid_expression_changes_fail(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            token = lambda value: {'$type': 'dimension', '$value': value, '$extensions': {'carbon.layout': {'converter': 'rem'}}}
            data = {'spacing': {'spacing-01': token(2)}, 'container': {'container-01': token(24)}, 'size': {'size-xs': token(24)}, 'icon-size': {'icon-size-01': token(16)}}
            path = directory / 'layout.json'
            path.write_text(json.dumps(data))
            source = '\n'.join(f'abstract final class {name} {{\n  static const double {field} = {value};\n}}' for name, field, value in [('CarbonSpacing', 'spacing01', 2), ('CarbonContainer', 'container01', 24), ('CarbonSize', 'xSmall', 24), ('CarbonIconSize', 'iconSize01', 16)])
            changed = json.loads(json.dumps(data))
            changed['spacing']['spacing-14'] = token(160)
            path.write_text(json.dumps(changed))
            with self.assertRaisesRegex(ValueError, 'family changed'):
                emit_fixed_layout(source, path)
            path.write_text(json.dumps(data))
            grid = directory / 'grid.scss'
            grid.write_text('$grid-breakpoints: (\n  sm: (\n    columns: 4,\n    margin: 0,\n    width: calc(20rem + 1px),\n  ),\n) !default;')
            with self.assertRaisesRegex(ValueError, 'Unsupported breakpoint expression'):
                emit_fixed_layout(source, path, grid)


if __name__ == '__main__':
    unittest.main()
