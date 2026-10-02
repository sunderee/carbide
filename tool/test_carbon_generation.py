#!/usr/bin/env python3
"""Regression tests for the Carbon 11.117 source-format migration."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from carbon_svg import extract
from generate_carbon_colors import parse
from generate_carbon_themes import flatten_tokens, resolve_token
from generate_carbon_type import normalize_styles, style


def token(value, **extensions):
    return {"$extensions": {"carbon.themes": {"white": value}, **extensions}}


class ThemeGenerationTest(unittest.TestCase):
    def test_dual_role_tokens_and_nested_palette_aliases(self):
        root = {"background": {**token("{white.default}"), "hover": token("{gray.50}")}}
        tokens = flatten_tokens(root)
        self.assertEqual(set(tokens), {"background", "background.hover"})
        self.assertEqual(resolve_token("background", "white", tokens, {"white": "FFFFFF"}), "CarbonColors.white")
        self.assertEqual(resolve_token("background.hover", "white", tokens, {"gray50": "8D8D8D"}), "CarbonColors.gray50")

    def test_alias_preserves_alpha_and_zero_is_not_discarded(self):
        tokens = {"base": token({"value": "{white.default}", "alpha": 0}), "alias": token("{base}")}
        self.assertEqual(resolve_token("alias", "white", tokens, {"white": "FFFFFF"}), "_alpha(CarbonColors.white, 0.0)")

    def test_component_alpha_modifiers_and_explicit_color_objects(self):
        tokens = {"disabled": token("{gray.50}", **{"org.carbon": {"alphaModifiers": {"white": 0.3}}}), "caret": token({"colorSpace": "srgb", "hex": "#eaf1ff", "components": [0.917647, 0.945098, 1]})}
        self.assertEqual(resolve_token("disabled", "white", tokens, {"gray50": "8D8D8D"}), "_alpha(CarbonColors.gray50, 0.3)")
        self.assertEqual(resolve_token("caret", "white", tokens, {}), "const Color(0xFFEAF1FF)")

    def test_missing_values_and_cycles_fail_instead_of_silent_generation(self):
        with self.assertRaisesRegex(ValueError, "missing g90"):
            resolve_token("base", "g90", {"base": token("#000000")}, {})
        with self.assertRaisesRegex(ValueError, "cyclic"):
            resolve_token("base", "white", {"base": token("{alias}"), "alias": token("{base}")}, {})
        with self.assertRaisesRegex(ValueError, "unsupported color"):
            resolve_token("base", "white", {"base": token("unknown")}, {})

    def test_dark_notification_fallback_uses_layer_hover(self):
        tokens = {"notification.action-hover": token("#ffffff"), "layer.hover.01": {"$extensions": {"carbon.themes": {"g90": "{gray.80Hover}"}}}}
        self.assertEqual(resolve_token("notification.action-hover", "g90", tokens, {"gray80Hover": "474747"}), "CarbonColors.gray80Hover")


class UpstreamGenerationTest(unittest.TestCase):
    def test_palette_preserves_public_aliases_and_real_values(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "colors.json"
            source.write_text(json.dumps({"black": {"$value": "#000000"}, "white": {"$value": "#ffffff"}, "blue": {"60": {"$value": "#0f62fe"}}}))
            with patch("generate_carbon_colors.SRC", source):
                palette = dict(parse())
        self.assertEqual(len(palette), 5)
        self.assertEqual(palette["black100"], palette["black"])
        self.assertEqual(palette["white0"], palette["white"])
        self.assertEqual(palette["blue60"], "0xFF0F62FE")

    def test_named_type_exports_are_normalized_without_losing_values(self):
        normalized = normalize_styles("{fontFamily: mono, fontSize: /*#__PURE__*/ rem(scale23), fontWeight: semibold, lineHeight: 1.25, letterSpacing: /*#__PURE__*/ px(0.32)}")
        self.assertEqual(style(normalized, [12] * 22 + [156], {"semibold": 600}), {"family": "mono", "size": 156, "weight": 600, "height": "1.25", "spacing": "0.32"})

    def test_transparent_artboard_is_omitted_but_visible_rect_is_retained(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "sample.svg"
            source.write_text('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32.0007 32"><rect id="Transparent_Rectangle" style="opacity:0.01;fill:#FFFFFF;fill-opacity:0.01" width="32" height="32"/><rect width="5" height="7"/></svg>')
            width, height, shapes = extract(source)
        self.assertEqual((width, height), (32.0007, 32))
        self.assertEqual(len(shapes), 1)
        self.assertIn("h5", shapes[0][0])


if __name__ == "__main__":
    unittest.main()
