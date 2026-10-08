#!/usr/bin/env python3
"""Regression tests for the Carbon 11.117 source-format migration."""

import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from carbon_svg import extract
from generate_carbon_colors import parse
from generate_carbon_layout import NAMES, parse as parse_fluid_spacing
from generate_carbon_themes import build, component_defaults, constant_color, flatten_tokens, resolve_token
from generate_carbon_type import normalize_styles, style


def token(value, **extensions):
    return {"$extensions": {"carbon.themes": {"white": value}, **extensions}}


class ThemeGenerationTest(unittest.TestCase):
    def test_const_alpha_defaults_keep_exact_palette_channels(self):
        with patch("generate_carbon_themes.parse_colors", return_value=[("gray50", "0xFF8D8D8D")]):
            code = constant_color("_alpha(CarbonColors.gray50, 0.12)")
        self.assertEqual(code, "const Color.from(alpha: 0.12, red: 141 / 255, green: 141 / 255, blue: 141 / 255)")
        self.assertEqual(constant_color("null"), "null")
        with self.assertRaisesRegex(ValueError, "unsupported const color"):
            constant_color("_alpha(_alpha(CarbonColors.gray50, 0.12), 0.5)")

    def test_compatibility_defaults_reject_theme_divergence(self):
        values = {theme: {"statusBlue": "CarbonColors.blue70"} for theme in ("white", "gray10", "gray90", "gray100")}
        self.assertEqual(component_defaults(values, "statusBlue"), ("CarbonColors.blue70", "CarbonColors.blue70"))
        values["gray10"]["statusBlue"] = "CarbonColors.blue50"
        with self.assertRaisesRegex(ValueError, "light compatibility defaults differ"):
            component_defaults(values, "statusBlue")
        values["gray10"]["statusBlue"] = values["white"]["statusBlue"]
        values["gray90"]["statusBlue"] = "CarbonColors.blue50"
        with self.assertRaisesRegex(ValueError, "dark compatibility defaults differ"):
            component_defaults(values, "statusBlue")

    def test_dark_status_outlines_preserve_upstream_absence(self):
        tokens = {"status.orange-outline": token("#000000"), "status.yellow-outline": token("#000000")}
        for path in tokens:
            for theme in ("g90", "g100"):
                with self.subTest(path=path, theme=theme):
                    self.assertEqual(resolve_token(path, theme, tokens, {}), "null")
        with self.assertRaisesRegex(ValueError, "missing g90"):
            resolve_token("status.red", "g90", {"status.red": token("#000000")}, {})

    def test_component_sources_load_status_and_content_switcher(self):
        def themed(hex_value):
            return {"$extensions": {"carbon.themes": {theme: hex_value for theme in ("white", "g10", "g90", "g100")}}}

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            dtcg = root / "dtcg"
            components = dtcg / "components"
            components.mkdir(parents=True)
            (dtcg / "themes.json").write_text("{}")
            for group in ("button", "tag", "notification"):
                (components / (group + ".json")).write_text("{}")
            (components / "status.json").write_text(json.dumps({"status": {"blue": themed("#123456")}}))
            (components / "content-switcher.json").write_text(json.dumps({"content-switcher": {"selected": themed("#654321")}}))
            with patch("generate_carbon_themes.THEME_DIR", root), patch("generate_carbon_themes.PORTED_TOKENS", ["statusBlue", "contentSwitcherSelected"]), patch("generate_carbon_themes.parse_colors", return_value=[]):
                order, brightness, resolved = build()
        self.assertEqual(order, ["statusBlue", "contentSwitcherSelected"])
        self.assertEqual(brightness["gray100"], "dark")
        self.assertEqual(resolved["white"]["statusBlue"], "const Color(0xFF123456)")
        self.assertEqual(resolved["gray100"]["contentSwitcherSelected"], "const Color(0xFF654321)")

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
    def test_fluid_spacing_dimensions_ignore_metadata_and_preserve_percentages(self):
        data = {"fluid-spacing": {"$description": "Viewport spacing", **{name: {"$type": "dimension", "$value": value} for name, value in zip(NAMES, ("0", "2vw", "5vw", "10vw"))}}}
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "layout.json"
            source.write_text(json.dumps(data))
            self.assertEqual(parse_fluid_spacing(source), {"spacing01": 0.0, "spacing02": 2.0, "spacing03": 5.0, "spacing04": 10.0})

    def test_fluid_spacing_rejects_other_units_and_scope_changes(self):
        data = {"fluid-spacing": {name: {"$type": "dimension", "$value": "0"} for name in NAMES}}
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "layout.json"
            for value in ("2px", "2%", "-1vw", "bad", None):
                with self.subTest(value=value):
                    data["fluid-spacing"][NAMES[0]]["$value"] = value
                    source.write_text(json.dumps(data))
                    with self.assertRaisesRegex(ValueError, "unsupported viewport dimension"):
                        parse_fluid_spacing(source)
            data["fluid-spacing"][NAMES[0]]["$value"] = "0"
            data["fluid-spacing"][NAMES[0]]["$type"] = "color"
            source.write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, "expected dimension"):
                parse_fluid_spacing(source)
            del data["fluid-spacing"][NAMES[0]]
            source.write_text(json.dumps(data))
            with self.assertRaisesRegex(ValueError, "fluid spacing family changed"):
                parse_fluid_spacing(source)

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
