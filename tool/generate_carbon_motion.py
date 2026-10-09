#!/usr/bin/env python3
"""Synchronize motion constants with pinned DTCG while retaining the API helpers."""

import json
import math
from pathlib import Path
import re

from generation_check import run_generation, write_generated

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'documentation/carbon/packages/motion/src/dtcg/motion.json'
OUTPUT = ROOT / 'lib/src/foundations/motion.dart'


def parse(source=SOURCE):
    data = json.loads(source.read_text())
    durations, curves = {}, {}
    for family, members in data['duration'].items():
        if family.startswith('$'):
            continue
        for step, token in members.items():
            if step.startswith('$'):
                continue
            value = token['$value']
            if token['$type'] != 'duration' or value['unit'] != 'ms' or type(value['value']) is not int or value['value'] < 0:
                raise ValueError(f'Unsupported duration: {family}/{step}')
            durations[family + step] = value['value']
    for style, members in data['easing'].items():
        if style.startswith('$'):
            continue
        for mode, token in members.items():
            if mode.startswith('$'):
                continue
            value = token['$value']
            if token['$type'] != 'cubicBezier' or len(value) != 4 or any(type(v) not in (int, float) or not math.isfinite(v) for v in value):
                raise ValueError(f'Unsupported easing: {style}/{mode}')
            curves[style + mode.capitalize()] = value
    return durations, curves


def emit(source, durations, curves):
    duration_pattern = r'static const Duration (\w+) = Duration\(milliseconds: (\d+)\);'
    curve_pattern = r'static const Cubic (\w+) = Cubic\(([^)]+)\);'
    if {name for name, _ in re.findall(duration_pattern, source)} != set(durations):
        raise ValueError('Duration family changed; review the public API')
    if {name for name, _ in re.findall(curve_pattern, source)} != set(curves):
        raise ValueError('Easing family changed; review the public API')
    source = re.sub(duration_pattern, lambda m: f'static const Duration {m[1]} = Duration(milliseconds: {durations[m[1]]});', source)
    source = re.sub(curve_pattern, lambda m: f'static const Cubic {m[1]} = Cubic({", ".join(str(v) for v in curves[m[1]])});', source)
    return source


def main():
    durations, curves = parse()
    write_generated(OUTPUT, emit(OUTPUT.read_text(), durations, curves))
    print(f'Prepared {len(durations)} durations and {len(curves)} easing curves')


if __name__ == '__main__':
    run_generation(main)
