#!/usr/bin/env python3
"""Inventory Dart barrel exports; reject unreviewed public surface changes.

This is a lexical inventory, not a Dart type checker. Flutter analyze remains
the syntax/type authority. Comments and strings are masked before declarations
are read, so examples, private members and nested classes cannot create APIs.
"""

import argparse
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "tool/public_surface.json"
WIDGET_BASES = {
    "Widget", "StatelessWidget", "StatefulWidget", "InheritedWidget",
    "ImplicitlyAnimatedWidget", "SingleChildRenderObjectWidget",
    "MultiChildRenderObjectWidget", "LeafRenderObjectWidget",
}


def mask_source(source):
    # Preserve offsets/newlines while hiding strings and nested block comments.
    result = list(source)
    i = 0
    while i < len(source):
        start = i
        if source.startswith("//", i):
            end = source.find("\n", i)
            i = len(source) if end < 0 else end
        elif source.startswith("/*", i):
            i += 2
            depth = 1
            while i < len(source) and depth:
                if source.startswith("/*", i):
                    depth += 1
                    i += 2
                elif source.startswith("*/", i):
                    depth -= 1
                    i += 2
                else:
                    i += 1
            if depth:
                raise ValueError("Unterminated block comment")
        elif source[i] in "\"'":
            quote = source[i]
            delimiter = quote * 3 if source.startswith(quote * 3, i) else quote
            raw = i > 0 and source[i - 1] == "r"
            i += len(delimiter)
            while i < len(source) and not source.startswith(delimiter, i):
                i += 2 if source[i] == "\\" and not raw else 1
            if i >= len(source):
                raise ValueError("Unterminated string")
            i += len(delimiter)
        else:
            i += 1
            continue
        for j in range(start, min(i, len(source))):
            if source[j] != "\n":
                result[j] = " "
    return "".join(result)


def declarations(path, root):
    source = path.read_text()
    masked = mask_source(source)
    depths = []
    depth = 0
    for char in masked:
        depths.append(depth)
        depth += char == "{"
        depth -= char == "}"
    found = {}
    patterns = [
        ("type", r"\b(class|enum|mixin|typedef|extension\s+type)\s+(\w+)"),
        ("extension", r"\bextension\s+(\w+)(?:<[^\n]+>)?\s+on\b"),
        ("function", r"(?m)^\w[\w<>?,. ]*?\s+(\w+)\s*(?:<[^\n]+>)?\s*\("),
        ("getter", r"(?m)^\w[\w<>?,. ]*?\s+get\s+(\w+)\b"),
        ("variable", r"(?m)^(?:late\s+)?(?:(?:const|final)\s+)?[\w<>?,.]+\s+(\w+)\s*(?==|;)"),
    ]
    for kind, pattern in patterns:
        for match in re.finditer(pattern, masked):
            if depths[match.start()] != 0:
                continue
            if kind == 'variable' and re.match(r'(?:typedef|class|enum|mixin|part|import|export|library)\b', match.group()):
                continue
            name = match.group(2) if kind == "type" else match.group(1)
            if name.startswith("_"):
                continue
            actual_kind = match.group(1) if kind == "type" else kind
            entry = {"source": path.relative_to(root).as_posix(), "kind": actual_kind}
            if actual_kind == "class":
                header = masked[match.end():].split("{", 1)[0]
                base = re.search(r"\bextends\s+(\w+)", header)
                entry["base"] = base.group(1) if base else ""
            found[name] = entry
    return found


def inventory(root=ROOT):
    root = root.resolve()
    cache = {}

    def library(path, visiting=()):
        path = path.resolve()
        if path in visiting:
            return {}
        if path in cache:
            return cache[path].copy()
        source = path.read_text()
        masked = mask_source(source)
        result = declarations(path, root)
        # Strings are read from the original only where a live directive starts.
        for match in re.finditer(r"\b(export|part)\s+", masked):
            tail = source[match.start():].split(";", 1)[0]
            directive = re.match(r"(export|part)\s+['\"]([^'\"]+)['\"](.*)", tail, re.S)
            if not directive:  # part of is not a part URI
                continue
            kind, uri, combinators = directive.groups()
            if re.search(r'\bif\b', combinators):
                raise ValueError('Conditional barrel export requires review')
            if ":" in uri:
                raise ValueError(f"External barrel URI requires review: {uri}")
            exported = library(path.parent / uri, (*visiting, path))
            if kind == "export":
                for comb in re.finditer(r"\b(show|hide)\s+([\w,\s]+?)(?=\bshow\b|\bhide\b|$)", combinators):
                    names = set(re.findall(r"\w+", comb.group(2)))
                    exported = {name: value for name, value in exported.items()
                                if (name in names) == (comb.group(1) == "show")}
            result.update(exported)
        cache[path] = result
        return result.copy()

    result = library(root / "lib/carbide.dart")
    for name, entry in result.items():
        base = entry.get("base", "")
        seen = {name}
        while base in result and base not in seen:
            seen.add(base)
            base = result[base].get("base", "")
        entry["visual"] = base in WIDGET_BASES
    return dict(sorted(result.items()))


def validate(actual, manifest, specimen_names, open_names=None):
    expected = manifest["exports"]
    if actual != expected:
        added = sorted(actual.keys() - expected.keys())
        removed = sorted(expected.keys() - actual.keys())
        changed = sorted(name for name in actual.keys() & expected.keys()
                         if actual[name] != expected[name])
        raise ValueError(f"Public surface needs classification: added={added}, removed={removed}, changed={changed}")
    for name, policy in manifest["families"].items():
        for specimen in policy.get("specimens", []) + policy.get("open", []):
            if specimen not in specimen_names:
                raise ValueError(f"{name}: missing specimen {specimen}")
        if open_names is not None:
            for specimen in policy.get("open", []):
                if specimen not in open_names:
                    raise ValueError(f"{name}: missing open-state action {specimen}")
        if not policy.get("specimens") and not policy.get("exemption"):
            raise ValueError(f"{name}: no specimen or reasoned exemption")
    for name, entry in actual.items():
        source = Path(entry["source"]).parts
        family = source[3] if source[2] == "components" else source[2]
        if family not in manifest["families"]:
            raise ValueError(f"{name}: unclassified family {family}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Check without modifying files (default)")
    parser.parse_args()
    manifest = json.loads(MANIFEST.read_text())
    specimens = (ROOT / "test/support/specimens.dart").read_text()
    names = set(re.findall(r"^  '([^']+)':", specimens, re.M))
    open_source = specimens.split('carbideOpenSpecimens =', 1)[1]
    open_names = set(re.findall(r"^  '([^']+)':", open_source, re.M))
    validate(inventory(), manifest, names, open_names)
    print(f"Public surface: {len(manifest['exports'])} declarations, {sum(e['visual'] for e in manifest['exports'].values())} widgets; {len(names)} specimens classified.")


if __name__ == "__main__":
    main()
