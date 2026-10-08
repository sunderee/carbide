#!/usr/bin/env python3
"""Generate copied examples from real preview builders, with live state snapshots.

This deliberately handles the gallery's simple declaration/build convention,
not arbitrary Dart. Unknown state types or ambiguous builders fail for review.
"""

import argparse
from pathlib import Path
import re
import subprocess
import tempfile

from public_surface import mask_source
from sdk_floor import read_floor

ROOT = Path(__file__).resolve().parents[1]
PAGES = ROOT / "example/lib/src/pages"


def balanced_end(masked, opening):
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack = [pairs[masked[opening]]]
    for index in range(opening + 1, len(masked)):
        char = masked[index]
        if char in pairs:
            stack.append(pairs[char])
        elif char in ")]}" and (not stack or char != stack.pop()):
            raise ValueError("unbalanced Dart source")
        if not stack:
            return index + 1
    raise ValueError("unterminated Dart source")


def expression_end(masked, start, delimiter=","):
    index = start
    while index < len(masked):
        if masked[index] in "([{":
            index = balanced_end(masked, index)
        elif masked[index] == delimiter:
            return index
        else:
            index += 1
    raise ValueError("unterminated expression")


def declarations(source):
    masked = mask_source(source)
    result = {}
    for match in re.finditer(r"\bclass\s+(_\w+Page(?:State)?)\b[^\{]*\{", masked):
        end = balanced_end(masked, match.end() - 1)
        result[match[1]] = source[match.start():end]
    return result


def snapshot_expression(type_name, name):
    if type_name in {"bool", "int", "int?", "double", "num", "Object?", "String", "String?"}:
        return f"sourceValue({name})"
    if type_name == "DateTime?":
        return f"sourceDate({name})"
    if type_name == "CarbonDateRange?":
        return f"sourceRange({name})"
    if type_name in {"Set<String>", "Set<Object>"}:
        element = type_name[4:-1]
        return f"sourceSet({name}, '{element}')"
    if type_name == "TextEditingController":
        return f"'TextEditingController(text: ${{sourceString({name}.text)}})'"
    if re.fullmatch(r"Carbon\w+", type_name):
        return f"'{type_name}.${{{name}.name}}'"
    raise ValueError(f"unsupported live example field {type_name} {name}")


def preview_only(source):
    masked = mask_source(source)
    scaffolds = list(re.finditer(r"\bDemoScaffold\s*\(", masked))
    if len(scaffolds) != 1:
        raise ValueError("expected one DemoScaffold per page builder")
    scaffold = scaffolds[0]
    end = balanced_end(masked, scaffold.end() - 1)
    preview = re.search(r"\bpreview\s*:\s*", masked[scaffold.end():end])
    if not preview:
        raise ValueError("missing preview")
    start = scaffold.end() + preview.end()
    finish = expression_end(masked, start)
    return source[:scaffold.start()] + source[start:finish].strip() + source[end:]


def template_for(widget, state=None):
    owner = state or widget
    original = owner
    owner = preview_only(owner)
    # A static option list can belong only to removed gallery knobs. Keep
    # constants used by the preview, such as table data and tree nodes.
    masked = mask_source(owner)
    removals = []
    for match in re.finditer(r"^  static const [^\n=]+\s+(_\w+)\s*=", masked, re.M):
        if len(re.findall(rf"\b{match[1]}\b", masked)) == 1:
            end = expression_end(masked, match.end(), ";") + 1
            removals.append((match.start(), end))
    for start, end in reversed(removals):
        owner = owner[:start] + owner[end:]
    snapshots = []
    if state:
        masked = mask_source(owner)
        pattern = r"^  (?:late )?(?:final )?([A-Za-z]\w*(?:<[^;\n=]+>)?\??)\s+(_\w+)\s*(?==|;)"
        replacements = []
        for match in re.finditer(pattern, masked, re.M):
            type_name, name = match[1], match[2]
            finish = expression_end(masked, match.end(), ";")
            # Owned lifecycle resources are created and disposed by the copied
            # State too. Focus, keys and scroll positions are not value knobs.
            if type_name in {"FocusNode", "GlobalKey", "ScrollController"}:
                if not owner[match.end(2):finish].strip().startswith("="):
                    raise ValueError(f"lifecycle resource needs initializer: {name}")
                continue
            snapshots.append((name, snapshot_expression(type_name, name)))
            # Replace the complete initializer, including declarations without one.
            replacements.append((match.end(2), finish, f" = @@{name}@@"))
        for start, finish, value in reversed(replacements):
            owner = owner[:start] + value + owner[finish:]
    body = widget + "\n\n" + owner if state else owner
    widget_name = re.search(r"\bclass\s+(\w+)", widget)[1]
    public_name = widget_name.removeprefix("_").removesuffix("Page") + "Example"
    for before, after in [(widget_name + "State", "_" + public_name + "State"),
                          (widget_name, public_name)]:
        body = re.sub(rf"\b{before}\b", after, body)
    template = (
        "import 'package:carbide/carbide.dart';\n"
        "import 'package:flutter/widgets.dart';\n"
        + ("import 'package:flutter/services.dart';\n" if re.search(r"\b(?:KeyEvent|KeyDownEvent|LogicalKeyboardKey|PhysicalKeyboardKey)\b", body) else "")
        + "\n" + body + "\n"
    )
    if "'''" in template:
        raise ValueError("triple-quoted preview source needs explicit template handling")
    original_name = re.search(r"\bclass\s+(\w+)", original)[1]
    fields = "\n".join(f"      '{name}': {value}," for name, value in snapshots)
    return (
        f"extension {original_name}Source on {original_name} {{\n"
        "  String get exampleSource {\n"
        "    final ExampleConfiguration configuration = ExampleConfiguration(<String, String>{\n"
        + fields + "\n    });\n"
        + "    return configuration.fill(r'''" + template + "''');\n"
        + "  }\n}\n"
    )


def generate(source, file_name):
    classes = declarations(source)
    result = [
        "// Copyright 2026 Bizjak Tech OÜ\n",
        "// GENERATED by tool/generate_gallery_examples.py. Do not edit.\n",
        f"part of '{file_name}';\n\n",
    ]
    for name, widget in classes.items():
        if name.endswith("State") or name == "_ButtonPage":
            continue
        result.append(template_for(widget, classes.get(name + "State")))
    return "\n".join(result)


def format_templates(generated, scratch, language):
    """Format copied Dart itself, not just the string containing it."""
    templates = list(re.finditer(r"r'''([\s\S]*?)'''", generated))
    folder = scratch / "templates"
    folder.mkdir()
    for i, match in enumerate(templates):
        source = re.sub(r"@@(_\w+)@@", r"carbideSnapshot\1", match[1])
        (folder / f"example_{i}.dart").write_text(source)
    subprocess.run(["dart", "format", "--language-version", language, str(folder)],
                   check=True, stdout=subprocess.DEVNULL)
    for i, match in reversed(list(enumerate(templates))):
        source = (folder / f"example_{i}.dart").read_text()
        source = re.sub(r"\bcarbideSnapshot(_\w+)\b", r"@@\1@@", source)
        generated = generated[:match.start(1)] + source + generated[match.end(1):]
    return generated


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    language = read_floor((ROOT / "pubspec.yaml").read_text())["sdk"].rsplit(".", 1)[0]
    for page in sorted(PAGES.glob("tier_*_pages.dart")):
        generated = generate(page.read_text(), page.name)
        target = page.with_suffix(".examples.g.dart")
        with tempfile.TemporaryDirectory(prefix="carbide-example-format-") as directory:
            candidate = Path(directory) / target.name
            generated = format_templates(generated, Path(directory), language)
            candidate.write_text(generated)
            subprocess.run(["dart", "format", "--language-version", language, str(candidate)], check=True,
                           stdout=subprocess.DEVNULL)
            generated = candidate.read_text()
        if args.check:
            if not target.is_file() or target.read_text() != generated:
                raise SystemExit(f"Stale gallery example templates: {target.relative_to(ROOT)}")
        else:
            target.write_text(generated)
        print(f"Checked {target.name}" if args.check else f"Generated {target.name}")


if __name__ == "__main__":
    main()
