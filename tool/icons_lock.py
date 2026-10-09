"""Icon lockfile: detect exactly what changed when Carbon updates.

The generator records a lockfile (tool/carbon_icons.lock.json) holding the
Carbon submodule commit, a content hash per icon asset, and the deprecation
list. On a submodule bump, regeneration diffs the old and new lockfiles into
a categorized report — added / modified / removed / deprecation changes — so
icon updates never rely on changelog archaeology, and CI can refuse drift
("submodule bumped but icons not regenerated") by comparing the recorded
commit against the gitlink.

See docs/ICON_UPDATES.md for the workflow.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCKFILE = ROOT / "tool/carbon_icons.lock.json"
SUBMODULE = "documentation/carbon"


def carbon_commit_from_checkout() -> str:
    """The submodule's checked-out commit (generation time)."""
    return subprocess.run(
        ["git", "-C", str(ROOT / SUBMODULE), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()


def carbon_commit_from_gitlink() -> str:
    """The submodule commit pinned in the repository tree.

    Works without the submodule being checked out (CI checks out the
    repository only), because the gitlink lives in the parent tree.
    """
    out = subprocess.run(
        ["git", "-C", str(ROOT), "ls-tree", "HEAD", SUBMODULE],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.split()
    assert len(out) >= 3 and out[0] == "160000", f"no gitlink for {SUBMODULE}"
    return out[2]


def compute_lock(icons: dict[str, dict], deprecated: dict[str, str]) -> dict:
    """Builds the lock structure from the collected asset registry."""
    assets: dict[str, str] = {}
    for name, entry in icons.items():
        for size, path in entry["assets"].items():
            key = f"{name}_{size}"
            assets[key] = hashlib.sha256(path.read_bytes()).hexdigest()
    return {
        "carbonCommit": carbon_commit_from_checkout(),
        "assets": dict(sorted(assets.items())),
        "deprecated": sorted(set(deprecated) & set(icons)),
    }


def diff_locks(old: dict, new: dict) -> dict[str, list[str]]:
    """Categorizes the changes between two locks."""
    old_assets: dict[str, str] = old.get("assets", {})
    new_assets: dict[str, str] = new.get("assets", {})
    old_deprecated = set(old.get("deprecated", []))
    new_deprecated = set(new.get("deprecated", []))
    return {
        "added": sorted(set(new_assets) - set(old_assets)),
        "removed": sorted(set(old_assets) - set(new_assets)),
        "modified": sorted(
            key
            for key in set(old_assets) & set(new_assets)
            if old_assets[key] != new_assets[key]
        ),
        "newlyDeprecated": sorted(new_deprecated - old_deprecated),
        "undeprecated": sorted(old_deprecated - new_deprecated),
    }


def has_changes(diff: dict[str, list[str]]) -> bool:
    return any(diff.values())


def format_report(diff: dict[str, list[str]]) -> str:
    if not has_changes(diff):
        return "icon diff: no changes"
    lines = ["icon diff:"]
    for kind in ("added", "modified", "removed", "newlyDeprecated", "undeprecated"):
        items = diff[kind]
        if items:
            lines.append(f"  {kind} ({len(items)}):")
            lines += [f"    {item}" for item in items]
    lines.append(
        "  -> regenerate references (tool/generate_icon_references.py) and "
        "review the sweep for added/modified assets; remove Dart symbols for "
        "removed assets."
    )
    return "\n".join(lines)


def read_lock(lockfile: Path = LOCKFILE) -> dict | None:
    if lockfile.exists():
        return json.loads(lockfile.read_text())
    return None


def write_lock(lock: dict, lockfile: Path = LOCKFILE, *, writer=None) -> None:
    text = json.dumps(lock, indent=2) + "\n"
    if writer is None:
        lockfile.write_text(text)
    else:
        writer(lockfile, text)
