"""Collect generation output, format in scratch space, then check or write.

Generators read their usual pinned sources. All output operations are deferred;
--check creates no repository files and never deletes an obsolete generated file.
"""

import argparse
import difflib
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
_active = None


class GenerationPlan:
    def __init__(self, root=ROOT):
        self.root = root.resolve()
        self.outputs = {}
        self.removals = set()

    def add(self, path, text):
        path = path.resolve()
        relative = path.relative_to(self.root)
        if relative.parts[0] not in {'lib', 'test', 'tool'}:
            raise ValueError(f'Unexpected generated output: {relative}')
        self.outputs[path] = text
        return len(text)

    def format(self):
        dart = shutil.which('dart')
        if dart is None:
            raise RuntimeError('dart must be on PATH to check formatted generation')
        sdk = re.search(r'sdk:\s*["\']>=([0-9]+\.[0-9]+)', (self.root / 'pubspec.yaml').read_text())
        if sdk is None:
            raise ValueError('Could not read the declared Dart language floor')
        with tempfile.TemporaryDirectory(prefix='carbide-generation-') as temporary:
            scratch = Path(temporary)
            files = []
            for path, text in self.outputs.items():
                if path.suffix != '.dart':
                    continue
                output = scratch / path.relative_to(self.root)
                output.parent.mkdir(parents=True, exist_ok=True)
                output.write_text(text)
                files.append(str(output))
            if files:
                subprocess.run([dart, 'format', '--summary', 'none', '--language-version', sdk.group(1), *files], check=True, capture_output=True, text=True)
                for path in self.outputs:
                    if path.suffix == '.dart':
                        self.outputs[path] = (scratch / path.relative_to(self.root)).read_text()

    def finish(self, check, format_dart=True):
        if format_dart:
            self.format()
        changes = []
        for path, expected in self.outputs.items():
            actual = path.read_text() if path.exists() else ''
            if actual != expected:
                changes.append(path.relative_to(self.root).as_posix())
                if check:
                    # Keep large icon changes reviewable without flooding CI.
                    diff = list(difflib.unified_diff(actual.splitlines(), expected.splitlines(), fromfile=str(path.relative_to(self.root)), tofile='generated', lineterm=''))
                    print('\n'.join(diff[:32]))
        obsolete = sorted(path for path in self.removals if path not in self.outputs and path.exists())
        changes.extend(path.relative_to(self.root).as_posix() for path in obsolete)
        if check:
            if changes:
                raise ValueError('Generated output drift: ' + ', '.join(changes))
            print(f'Generation check passes: {len(self.outputs)} artifacts; repository unchanged.')
            return
        for path in obsolete:
            path.unlink()
        for path, text in self.outputs.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)


def write_generated(path, text):
    if _active is None:
        raise RuntimeError('Generated writes must run inside run_generation')
    return _active.add(path, text)


def remove_generated(path):
    if _active is None:
        raise RuntimeError('Generated removal must run inside run_generation')
    path = path.resolve()
    path.relative_to(_active.root)
    _active.removals.add(path)


def run_generation(main, args=None):
    parser = argparse.ArgumentParser(description=main.__module__)
    parser.add_argument('--check', action='store_true', help='Compare formatted output without changing repository files')
    options = parser.parse_args(args)
    global _active
    if _active is not None:
        raise RuntimeError('Nested generation is unsupported')
    plan = GenerationPlan()
    _active = plan
    try:
        main()
    finally:
        _active = None
    plan.finish(options.check)
