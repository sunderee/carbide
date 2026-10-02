"""Shared Carbon SVG extraction used by the icon generators.

Parses a Carbon icon/pictogram SVG into normalized shape data:

- resolves ``<style>`` CSS classes and inline/presentation attributes;
- drops invisible elements (``fill: none``, zero opacity) and metadata tags;
- converts ``rect``/``circle``/``ellipse``/``polygon``/``polyline`` to path
  data;
- composes ``transform`` attributes (translate/rotate/scale/matrix) into a
  2D affine matrix per shape;
- maps ``fill-rule: evenodd`` onto the shape.

Validated empirically against rsvg-convert rasterizations of the upstream
sources in the #29 spike (ADR 0001): blurred-coverage mismatch 0.000%.
"""

from __future__ import annotations

import math
import re
import xml.etree.ElementTree as ET
from pathlib import Path

# `switch` is deliberately not dropped: Illustrator exports wrap the real
# artwork in <switch><g> with a <foreignObject> Adobe fallback whose required
# extension never matches, so per SVG switch semantics the <g> renders. We
# recurse into switch and drop the foreignObject.
DROP_TAGS = {"style", "defs", "title", "desc", "foreignObject", "i"}
SHAPE_TAGS = {"path", "rect", "circle", "ellipse", "polygon", "polyline"}

CSS_RULE = re.compile(r"\.([\w-]+)\s*\{([^}]*)\}")
TRANSFORM_CALL = re.compile(r"(\w+)\s*\(([^)]*)\)")

IDENTITY = (1.0, 0.0, 0.0, 1.0, 0.0, 0.0)


def strip_ns(tag: str) -> str:
    return tag.split("}", 1)[1] if "}" in tag else tag


def parse_css(root: ET.Element) -> dict[str, dict[str, str]]:
    classes: dict[str, dict[str, str]] = {}
    for el in root.iter():
        if strip_ns(el.tag) == "style" and el.text:
            for m in CSS_RULE.finditer(el.text):
                props: dict[str, str] = {}
                for decl in m.group(2).split(";"):
                    if ":" in decl:
                        key, value = decl.split(":", 1)
                        props[key.strip()] = value.strip()
                classes.setdefault(m.group(1), {}).update(props)
    return classes


def style_of(el: ET.Element, classes: dict) -> dict[str, str]:
    style: dict[str, str] = {}
    for cls in (el.get("class") or "").split():
        style.update(classes.get(cls, {}))
    inline = el.get("style") or ""
    for decl in inline.split(";"):
        if ":" in decl:
            key, value = decl.split(":", 1)
            style[key.strip()] = value.strip()
    for attr in ("fill", "fill-rule", "opacity", "fill-opacity"):
        if el.get(attr) is not None:
            style[attr] = el.get(attr)
    return style


def invisible(style: dict[str, str]) -> bool:
    if style.get("fill") == "none":
        return True
    for key in ("opacity", "fill-opacity"):
        try:
            if float(style.get(key, "1")) == 0:
                return True
        except ValueError:
            pass
    return False


def mat_mul(a, b):
    return (
        a[0] * b[0] + a[2] * b[1],
        a[1] * b[0] + a[3] * b[1],
        a[0] * b[2] + a[2] * b[3],
        a[1] * b[2] + a[3] * b[3],
        a[0] * b[4] + a[2] * b[5] + a[4],
        a[1] * b[4] + a[3] * b[5] + a[5],
    )


def parse_transform(text: str | None):
    matrix = IDENTITY
    if not text:
        return matrix
    for call in TRANSFORM_CALL.finditer(text):
        name, args_text = call.group(1), call.group(2)
        args = [float(v) for v in re.split(r"[,\s]+", args_text.strip()) if v]
        if name == "translate":
            tx, ty = args[0], args[1] if len(args) > 1 else 0.0
            m = (1, 0, 0, 1, tx, ty)
        elif name == "rotate":
            angle = math.radians(args[0])
            cos, sin = math.cos(angle), math.sin(angle)
            m = (cos, sin, -sin, cos, 0, 0)
            if len(args) == 3:
                cx, cy = args[1], args[2]
                m = mat_mul(
                    mat_mul((1, 0, 0, 1, cx, cy), m), (1, 0, 0, 1, -cx, -cy)
                )
        elif name == "scale":
            sx = args[0]
            sy = args[1] if len(args) > 1 else sx
            m = (sx, 0, 0, sy, 0, 0)
        elif name == "matrix":
            m = tuple(args)
        else:
            raise ValueError(f"unsupported transform: {name}")
        matrix = mat_mul(matrix, m)
    return matrix


def fnum(value: float) -> str:
    return f"{value:.6g}"


def shape_to_path(el: ET.Element, tag: str) -> str:
    g = el.get
    if tag == "path":
        return g("d") or ""
    if tag == "rect":
        x, y = float(g("x") or 0), float(g("y") or 0)
        w, h = float(g("width")), float(g("height"))
        rx = g("rx")
        ry = g("ry")
        rx = float(rx) if rx is not None else (float(ry) if ry else 0.0)
        ry = float(ry) if ry is not None else rx
        if rx == 0 and ry == 0:
            return f"M{fnum(x)},{fnum(y)} h{fnum(w)} v{fnum(h)} h{fnum(-w)} z"
        rx = min(rx, w / 2)
        ry = min(ry, h / 2)
        return (
            f"M{fnum(x + rx)},{fnum(y)} h{fnum(w - 2 * rx)} "
            f"a{fnum(rx)},{fnum(ry)} 0 0 1 {fnum(rx)},{fnum(ry)} "
            f"v{fnum(h - 2 * ry)} "
            f"a{fnum(rx)},{fnum(ry)} 0 0 1 {fnum(-rx)},{fnum(ry)} "
            f"h{fnum(2 * rx - w)} "
            f"a{fnum(rx)},{fnum(ry)} 0 0 1 {fnum(-rx)},{fnum(-ry)} "
            f"v{fnum(2 * ry - h)} "
            f"a{fnum(rx)},{fnum(ry)} 0 0 1 {fnum(rx)},{fnum(-ry)} z"
        )
    if tag in ("circle", "ellipse"):
        cx, cy = float(g("cx") or 0), float(g("cy") or 0)
        rx = float(g("r") or g("rx"))
        ry = float(g("r") or g("ry"))
        return (
            f"M{fnum(cx - rx)},{fnum(cy)} "
            f"a{fnum(rx)},{fnum(ry)} 0 1 0 {fnum(2 * rx)},0 "
            f"a{fnum(rx)},{fnum(ry)} 0 1 0 {fnum(-2 * rx)},0 z"
        )
    if tag in ("polygon", "polyline"):
        nums = [v for v in re.split(r"[,\s]+", (g("points") or "").strip()) if v]
        pairs = [f"{nums[i]},{nums[i + 1]}" for i in range(0, len(nums), 2)]
        close = " z" if tag == "polygon" else ""
        return "M" + " L".join(pairs) + close
    raise ValueError(f"unsupported shape: {tag}")


def extract(svg_file: Path):
    """Returns ``(viewbox_width, viewbox_height, shapes)`` for one SVG.

    Each shape is ``(d, evenodd, matrix6)`` with ``matrix6 == IDENTITY`` when
    no transform applies. Most artwork is square; bespoke glyph assets can be
    rectangular (e.g. caret glyphs are 8×4).
    """
    root = ET.parse(svg_file).getroot()
    view_box = root.get("viewBox")
    if view_box is None:
        width = re.sub(r"px$", "", root.get("width"))
        height = re.sub(r"px$", "", root.get("height") or width)
        view_box = f"0 0 {width} {height}"
    vb = [float(v) for v in view_box.split()]
    assert vb[0] == 0 and vb[1] == 0, f"odd viewBox origin: {vb}"
    classes = parse_css(root)
    shapes = []

    def walk(el: ET.Element, transform):
        tag = strip_ns(el.tag)
        # Adobe exports retain a named artboard rectangle with 0.01 × 0.01
        # opacity. It is metadata, not monochrome artwork (Carbon 11.117).
        if tag == "rect" and el.get("id") == "Transparent_Rectangle":
            return
        if tag in DROP_TAGS:
            return
        matrix = mat_mul(transform, parse_transform(el.get("transform")))
        if tag in SHAPE_TAGS:
            style = style_of(el, classes)
            if invisible(style):
                return
            rule = style.get("fill-rule", "nonzero")
            shapes.append((shape_to_path(el, tag), rule == "evenodd", matrix))
            return
        for child in el:
            walk(child, matrix)

    for child in root:
        walk(child, IDENTITY)
    assert shapes, f"no visible shapes in {svg_file}"
    return vb[2], vb[3], shapes
