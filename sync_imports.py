#!/usr/bin/env python3
"""
Detect and purge stale Godot import caches (.ctex) for asset files modified
outside of the Godot editor (e.g. by Python scripts or the AI agent).

When a source PNG changes on disk but Godot's cached .ctex isn't regenerated,
the game renders the old pixel data.  Run this script after any programmatic
asset edits, before launching the game or editor.

Usage:
    python3 sync_imports.py          # dry run (report only)
    python3 sync_imports.py --fix    # delete stale caches so Godot reimports
"""

import sys
import os
import re
import hashlib

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
IMPORTED_DIR = os.path.join(PROJECT_ROOT, ".godot", "imported")


def md5(path: str) -> str:
    h = hashlib.md5()
    with open(path, "rb") as f:
        h.update(f.read())
    return h.hexdigest()


def find_import_files():
    for root, dirs, files in os.walk(PROJECT_ROOT):
        dirs[:] = [d for d in dirs if d != ".godot"]
        for name in files:
            if name.endswith(".import"):
                yield os.path.join(root, name)


def parse_import(path: str):
    with open(path) as f:
        text = f.read()
    m = re.search(r'^path="(res://.+?\.ctex)"', text, re.MULTILINE)
    return m.group(1) if m else None


def ctex_local(res_path: str) -> str:
    return os.path.join(PROJECT_ROOT, res_path.replace("res://", ""))


def read_source_md5(ctex_path: str) -> str | None:
    # e.g. foo.ctex → foo.md5
    md5_path = ctex_path[: -len(".ctex")] + ".md5"
    if not os.path.exists(md5_path):
        return None
    with open(md5_path) as f:
        m = re.search(r'source_md5="([a-f0-9]+)"', f.read())
    return m.group(1) if m else None


def main():
    fix = "--fix" in sys.argv
    stale = []
    missing_ctex = []

    for import_file in find_import_files():
        source = import_file[: -len(".import")]
        if not os.path.exists(source):
            continue

        ctex_res = parse_import(import_file)
        if ctex_res is None:
            continue

        ctex_path = ctex_local(ctex_res)
        rel_source = os.path.relpath(source, PROJECT_ROOT)

        if not os.path.exists(ctex_path):
            missing_ctex.append(rel_source)
            continue

        cached_md5 = read_source_md5(ctex_path)
        if cached_md5 is None:
            continue

        actual_md5 = md5(source)
        if cached_md5 != actual_md5:
            stale.append((rel_source, ctex_path, cached_md5[:8], actual_md5[:8]))

    if not stale and not missing_ctex:
        print("✅  All import caches are up to date.")
        return

    if missing_ctex:
        print("⚠️  Missing .ctex (Godot will reimport on next launch):")
        for s in missing_ctex:
            print(f"   {s}")

    if stale:
        print(f"{'🗑️  Deleting' if fix else '⚠️  Stale'} import caches ({len(stale)} file{'s' if len(stale) != 1 else ''}):")
        for source, ctex_path, old_md5, new_md5 in stale:
            print(f"   {source}  [{old_md5}… → {new_md5}…]")
            if fix:
                os.remove(ctex_path)
                md5_path = ctex_path[: -len(".ctex")] + ".md5"
                if os.path.exists(md5_path):
                    os.remove(md5_path)
        if not fix:
            print()
            print("Run with --fix to delete stale caches so Godot reimports them.")
        else:
            print()
            print("Done. Open the Godot editor or run the game — it will reimport automatically.")


if __name__ == "__main__":
    main()
