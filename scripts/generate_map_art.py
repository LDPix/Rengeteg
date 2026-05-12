#!/usr/bin/env python3
"""Generate pixel art map tiles and resource-node sprites via PixelLab API.

Usage:
    PIXELLAB_API_KEY=your_key python3 scripts/generate_map_art.py

Tiles   → /create-image-pixflux  (HTTP 200, immediate)
Objects → /map-objects            (HTTP 200, background job → poll)
"""

import argparse
import base64
import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

API_KEY = os.environ.get("PIXELLAB_API_KEY", "")
BASE_URL = "https://api.pixellab.ai/v2"
ROOT = Path(__file__).resolve().parents[1]

try:
    import certifi
    _SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    _SSL_CTX = ssl.create_default_context()
    if not _SSL_CTX.get_ca_certs():
        _SSL_CTX.check_hostname = False
        _SSL_CTX.verify_mode = ssl.CERT_NONE

# ── Tile definitions ─────────────────────────────────────────────────────────
# Output size 32x32 to match existing tiles. lineless/flat = clean RPG look.
# Tile prompts are wrapped by _tile_prompt() so terrain is generated as a
# repeatable ground texture instead of a prop-like illustration.
TILES: dict[str, tuple[str, str]] = {
    "grass": (
        "Homogeneous lush green short grass material, varied green pixels, tiny blade noise, "
        "no clearing or path",
        "assets/tiles/grass.png",
    ),
    "dirt": (
        "Homogeneous brown earthy soil material, soft dirt grain, tiny scattered pebble noise, "
        "no path shape or border vegetation",
        "assets/tiles/dirt.png",
    ),
    "stone": (
        "Homogeneous grey cobblestone floor material, small irregular paving stones, subtle cracks, "
        "flat walkable ground texture",
        "assets/tiles/stone.png",
    ),
    "cave_wall": (
        "Homogeneous dark grey cave rock material, rough stone surface, small mineral specks, "
        "no individual boulders",
        "assets/tiles/cave_wall.png",
    ),
    "lava": (
        "Homogeneous molten lava material, orange red magma veins mixed with dark crust flecks, "
        "evenly distributed",
        "assets/tiles/lava.png",
    ),
    "flowers": (
        "Homogeneous green grass material with tiny evenly scattered wildflower pixels, "
        "pink yellow and white flecks, no large flowers or clusters",
        "assets/tiles/flowers.png",
    ),
}

USED_MAP_TILE_NAMES: tuple[str, ...] = (
    # Current terrain textures referenced by scenes/overworld/*.tscn.
    "grass",
    "dirt",
    "flowers",
    "stone",
    "cave_wall",
    "lava",
)

# ── Resource node / object definitions ───────────────────────────────────────
# All rendered at 32x32 with transparent background via /map-objects.
OBJECTS: dict[str, tuple[str, str]] = {
    "bush": (
        "A rounded leafy green bush shrub with dense foliage, "
        "overworld RPG map object, low top-down view",
        "assets/resources/bush.png",
    ),
    "core_shard_node": (
        "A glowing amber orange crystal shard standing upright, warm golden inner glow, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/core_shard_node.png",
    ),
    "crystal": (
        "A cluster of blue and teal crystal spikes jutting up from the ground, icy gleam, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/crystal.png",
    ),
    "crystal_lava": (
        "Sharp orange and red fire crystals growing from cracked dark rock, glowing heat, "
        "overworld RPG resource node in lava biome, low top-down view",
        "assets/resources/crystal_lava.png",
    ),
    "crystal_node": (
        "A cluster of blue teal crystal spikes with sparkle highlights and green mossy base, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/crystal_node.png",
    ),
    "crystal_overgrown": (
        "Blue teal crystal cluster wrapped in dark green vines and overgrown moss, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/crystal_overgrown.png",
    ),
    "herb_fungus": (
        "A small cluster of brown and cream mushrooms with spotted caps on mossy ground, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/herb_fungus.png",
    ),
    "herb_node": (
        "A green herb plant with small yellow and white flower blooms on leafy stems, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/herb_node.png",
    ),
    "magical_seal": (
        "A glowing blue and purple magical rune circle on the ground with a star symbol, "
        "arcane seal, overworld RPG object, high top-down view",
        "assets/resources/magical_seal.png",
    ),
    "rock": (
        "A rounded grey stone boulder with subtle cracks, "
        "overworld RPG map object, low top-down view",
        "assets/resources/rock.png",
    ),
    "species_mat_node": (
        "A lumpy orange terracotta colored organic nest or cocoon material on the ground, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/species_mat_node.png",
    ),
    "stone_basalt": (
        "Two dark grey purple basalt rock fragments, angular and volcanic, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/stone_basalt.png",
    ),
    "stone_mossy": (
        "Two grey stones heavily covered in bright green moss, rounded, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/stone_mossy.png",
    ),
    "stone_node": (
        "A cluster of grey green stone rocks with patches of moss, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/stone_node.png",
    ),
    "tree": (
        "A lush green leafy tree with round canopy seen from slightly above, "
        "overworld RPG map object, low top-down view",
        "assets/resources/tree.png",
    ),
    "wood_node": (
        "A short tree trunk log with visible wood grain rings on top, surrounded by grass, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/wood_node.png",
    ),
    "wood_stump": (
        "A cut tree stump with prominent growth rings and a mossy side, "
        "overworld RPG resource node, low top-down view",
        "assets/resources/wood_stump.png",
    ),
}


# ── API helpers ───────────────────────────────────────────────────────────────

def _request(method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        data=data,
        headers={"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"},
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=90, context=_SSL_CTX) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"HTTP {exc.code}: {exc.read()[:400].decode()}") from exc


def _poll_job(job_id: str, interval: float = 3.0, timeout: float = 120.0) -> dict:
    elapsed = 0.0
    while elapsed < timeout:
        result = _request("GET", f"/background-jobs/{job_id}")
        status = result.get("status", "")
        if status == "completed":
            return result
        if status == "failed":
            raise RuntimeError(f"job {job_id} failed: {result}")
        time.sleep(interval)
        elapsed += interval
    raise RuntimeError(f"job {job_id} timed out after {timeout}s")


def _b64_to_bytes(raw: str) -> bytes:
    return base64.b64decode(raw)


# ── Per-endpoint generators ───────────────────────────────────────────────────

def _tile_prompt(description: str) -> str:
    return (
        f"{description}. "
        "Create a flat close-up material texture swatch for a tilemap atlas, not an illustrated scene. "
        "The full 32x32 square must be filled edge-to-edge with the same ground material. "
        "Orthographic top-down view with no horizon, no camera perspective, no composition. "
        "Seamless repeating top-down RPG terrain texture, pixel art. "
        "No standalone props, no central object, no round island, no framed patch, no border decoration, "
        "no corner decoration, no vignette, no shadows around the edge, no paths, no trails, no clearings, "
        "no bushes, no leaves as objects, no rocks as objects, no plants as objects, no icons. "
        "The outer 8 pixels on all four sides must be the same continuous material texture with only tiny noise. "
        "Texture must continue naturally across left/right and top/bottom edges. "
        "Tiny evenly distributed details only, low detail, lineless, flat shading."
    )


def generate_tile(name: str, description: str) -> bytes | None:
    try:
        resp = _request("POST", "/create-image-pixflux", {
            "description": _tile_prompt(description),
            "image_size": {"width": 32, "height": 32},
            "view": "high top-down",
            "outline": "lineless",
            "shading": "flat shading",
            "detail": "low detail",
            "no_background": False,
            "text_guidance_scale": 12.0,
            "seed": abs(hash(name)) % (2 ** 31),
        })
    except RuntimeError as exc:
        print(f"  [error] {exc}")
        return None

    img = resp.get("image", {})
    if img.get("type") == "base64" and img.get("base64"):
        return _b64_to_bytes(img["base64"])

    print(f"  [error] unexpected response shape: {str(resp)[:200]}")
    return None


def generate_object(name: str, description: str) -> bytes | None:
    try:
        queued = _request("POST", "/map-objects", {
            "description": description,
            "image_size": {"width": 32, "height": 32},
            "view": "low top-down",
            "outline": "single color outline",
            "shading": "basic shading",
            "detail": "medium detail",
            "text_guidance_scale": 9.0,
            "seed": abs(hash(name)) % (2 ** 31),
        })
    except RuntimeError as exc:
        print(f"  [error] {exc}")
        return None

    job_id = queued.get("background_job_id")
    if not job_id:
        print(f"  [error] no background_job_id: {queued}")
        return None

    print(f"  queued {job_id}, polling…")
    try:
        result = _poll_job(job_id)
    except RuntimeError as exc:
        print(f"  [error] {exc}")
        return None

    raw = (result.get("last_response") or {}).get("image")
    if raw:
        return _b64_to_bytes(raw)

    print(f"  [error] no image in result: {str(result)[:200]}")
    return None


# ── Main ──────────────────────────────────────────────────────────────────────

def run_batch(
    items: dict[str, tuple[str, str]],
    generator,
    label: str,
) -> int:
    saved = 0
    for name, (description, rel_path) in items.items():
        out = ROOT / rel_path
        print(f"[{label}] {name} → {rel_path}")
        img = generator(name, description)
        if img:
            out.write_bytes(img)
            print(f"  saved ({len(img):,} bytes)")
            saved += 1
        else:
            print("  skipped")
    return saved


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate Rengeteg map art with PixelLab.")
    parser.add_argument(
        "--tiles-only",
        action="store_true",
        help="Generate terrain tiles only. Useful when remaking seamless ground textures.",
    )
    parser.add_argument(
        "--used-map-tiles",
        action="store_true",
        help="Generate only terrain tiles currently referenced by overworld map scenes.",
    )
    parser.add_argument(
        "--objects-only",
        action="store_true",
        help="Generate resource nodes and map objects only.",
    )
    parser.add_argument(
        "--names",
        nargs="+",
        help="Optional asset names to generate, for example: grass dirt lava.",
    )
    return parser.parse_args()


def _filter_items(items: dict[str, tuple[str, str]], names: list[str] | None) -> dict[str, tuple[str, str]]:
    if not names:
        return items
    wanted = set(names)
    return {name: item for name, item in items.items() if name in wanted}


def main() -> None:
    if not API_KEY:
        sys.exit("Set PIXELLAB_API_KEY and re-run.")

    args = _parse_args()
    if args.tiles_only and args.objects_only:
        sys.exit("Choose either --tiles-only or --objects-only, not both.")

    tile_items = _filter_items(TILES, args.names)
    object_items = _filter_items(OBJECTS, args.names)
    if args.used_map_tiles:
        tile_items = _filter_items(tile_items, list(USED_MAP_TILE_NAMES))
        object_items = {}
    if args.tiles_only:
        object_items = {}
    elif args.objects_only:
        tile_items = {}

    total = len(tile_items) + len(object_items)
    if total == 0:
        sys.exit("No matching assets to generate.")

    saved = 0

    if tile_items:
        print(f"=== Tiles ({len(tile_items)}) ===")
        saved += run_batch(tile_items, generate_tile, "tile")

    if object_items:
        print(f"\n=== Resource nodes ({len(object_items)}) ===")
        saved += run_batch(object_items, generate_object, "node")

    print(f"\nDone. {saved}/{total} assets generated.")
    if saved:
        print("Reopen the Godot project to import new PNGs.")


if __name__ == "__main__":
    main()
