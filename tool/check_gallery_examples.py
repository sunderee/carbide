#!/usr/bin/env python3
"""Compile the gallery's actual displayed source against the package API."""

import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    # Under example/ so the real independent package configuration resolves
    # Flutter and Carbide. Always remove the scratch output, even on failure.
    with tempfile.TemporaryDirectory(prefix=".compiled-examples-", dir=ROOT / "example") as directory:
        scratch = Path(directory)
        export = scratch / "sources.json"
        subprocess.run([
            "flutter", "test", "test/example_sources_test.dart",
            f"--dart-define=CARBIDE_EXPORT_EXAMPLES={export}",
        ], cwd=ROOT / "example", check=True)
        sources = json.loads(export.read_text())
        if not sources:
            raise ValueError("gallery did not export any examples")
        for i, (slug, source) in enumerate(sources.items()):
            if source.startswith("import "):
                code = source
            else:
                expression = source.strip().removesuffix(";")
                code = (
                    "import 'package:carbide/carbide.dart';\n"
                    "import 'package:flutter/widgets.dart';\n"
                    f"Widget example{i}(BuildContext context) => {expression};\n"
                )
            (scratch / f"example_{i}.dart").write_text(
                "// ignore_for_file: unused_import\n" + f"// {slug}\n" + code,
            )
        # Analyze real API/type correctness independently of stylistic lints on
        # expanded constructor expressions. The gallery itself remains linted.
        (scratch / "analysis_options.yaml").write_text("analyzer:\n  language:\n    strict-casts: true\n    strict-inference: true\n    strict-raw-types: true\n")
        subprocess.run(["dart", "analyze", str(scratch)], cwd=ROOT / "example", check=True)
        print(f"Compiled {len(sources)} displayed/configuration examples.")


if __name__ == "__main__":
    main()
