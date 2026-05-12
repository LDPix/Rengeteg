"""
Build 32x32 Wang transition tilesets from pairs of existing 32x32 tile images.

Produces a 128x128 spritesheet (4x4 grid of 32x32 tiles) covering all 16
corner combinations, plus a matching metadata JSON that overworld_tile_layer.gd
reads via wang_sets.

Corner encoding: tile_id = NW<<3 | NE<<2 | SW<<1 | SE (1=upper, 0=lower)
  id 0  = all lower (pure lower terrain)
  id 15 = all upper (pure upper terrain)

Blending uses bilinear corner weights with an S-curve sharpening so the
transition has a visible edge rather than a muddy gradient.
"""

import json
import math
import os

import numpy as np
from PIL import Image

TILE_SIZE = 32
GRID = 4
SHEET_SIZE = TILE_SIZE * GRID  # 128


def _corner_weight_map():
    """Return (NW, NE, SW, SE) weight arrays, each shape (32,32)."""
    x = np.linspace(0.0, 1.0, TILE_SIZE)
    y = np.linspace(0.0, 1.0, TILE_SIZE)
    xx, yy = np.meshgrid(x, y)  # xx increases right, yy increases down

    w_nw = (1 - xx) * (1 - yy)
    w_ne = xx * (1 - yy)
    w_sw = (1 - xx) * yy
    w_se = xx * yy
    return w_nw, w_ne, w_sw, w_se


def _s_curve(t: np.ndarray, k: float = 4.0) -> np.ndarray:
    """Sharpen a [0,1] blend weight so edges read clearly at 32px."""
    return 1.0 / (1.0 + np.exp(-k * (t - 0.5)))


W_NW, W_NE, W_SW, W_SE = _corner_weight_map()


def build_wang_tile(lower: np.ndarray, upper: np.ndarray, nw: int, ne: int, sw: int, se: int) -> np.ndarray:
    """Blend lower and upper (H,W,4 float32) into one 32x32 RGBA tile."""
    upper_weight = (
        nw * W_NW +
        ne * W_NE +
        sw * W_SW +
        se * W_SE
    )
    upper_weight = _s_curve(np.clip(upper_weight, 0.0, 1.0))
    alpha = upper_weight[..., np.newaxis]
    blended = lower * (1.0 - alpha) + upper * alpha
    return np.clip(blended, 0, 255).astype(np.uint8)


def _edge_noise(x: int, y: int) -> float:
    return math.sin(x * 1.7 + y * 0.9) * 0.5 + math.sin(x * 0.35 - y * 1.3) * 0.5


def build_masked_wang_tile(lower: np.ndarray, upper: np.ndarray, nw: int, ne: int, sw: int, se: int) -> np.ndarray:
    """Blend lower/upper with a crisp, organic pixel mask.

    This works better for dirt-to-grass than a smooth alpha gradient: terrain
    keeps its identity and the border reads like an edge rather than soup.
    """
    upper_weight = (
        nw * W_NW +
        ne * W_NE +
        sw * W_SW +
        se * W_SE
    )
    result = lower.copy()
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            noise = _edge_noise(x, y) * 0.08
            w = float(upper_weight[y, x]) + noise
            if w >= 0.53:
                result[y, x] = upper[y, x]
            elif w >= 0.43:
                # Narrow fringe of grass-tinted dirt keeps the transition alive
                # without washing out the tile.
                t = (w - 0.43) / 0.10
                result[y, x] = lower[y, x] * (1.0 - t * 0.45) + upper[y, x] * (t * 0.45)
    return np.clip(result, 0, 255).astype(np.uint8)


def _edge_mask_value(x: int, y: int, n: int, e: int, s: int, w: int) -> float:
    inset = 5.5
    softness = 1.75
    value = 0.0
    noise = _edge_noise(x, y) * 1.35
    if n:
        value = max(value, (inset - y + noise) / softness)
    if s:
        value = max(value, (inset - (TILE_SIZE - 1 - y) + noise) / softness)
    if w:
        value = max(value, (inset - x + noise) / softness)
    if e:
        value = max(value, (inset - (TILE_SIZE - 1 - x) + noise) / softness)
    return float(np.clip(value, 0.0, 1.0))


def build_edge_tile(lower: np.ndarray, upper: np.ndarray, n: int, e: int, s: int, w: int) -> np.ndarray:
    result = lower.copy()
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            mask = _edge_mask_value(x, y, n, e, s, w)
            if mask >= 0.58:
                result[y, x] = upper[y, x]
            elif mask > 0.0:
                # Keep a narrow transition fringe without shrinking paths into
                # corner triangles.
                result[y, x] = lower[y, x] * (1.0 - mask * 0.45) + upper[y, x] * (mask * 0.45)
    return np.clip(result, 0, 255).astype(np.uint8)


def generate_edge(lower_path: str, upper_path: str, out_png: str, out_json: str,
                  lower_name: str, upper_name: str) -> None:
    lower_img = Image.open(lower_path).convert("RGBA").resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)
    upper_img = Image.open(upper_path).convert("RGBA").resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)

    lower_arr = np.array(lower_img, dtype=np.float32)
    upper_arr = np.array(upper_img, dtype=np.float32)

    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE))
    tiles_meta = []

    for tile_id in range(16):
        n = (tile_id >> 3) & 1
        e = (tile_id >> 2) & 1
        s = (tile_id >> 1) & 1
        w = tile_id & 1

        col = tile_id % GRID
        row = tile_id // GRID
        bx = col * TILE_SIZE
        by = row * TILE_SIZE

        tile_arr = build_edge_tile(lower_arr, upper_arr, n, e, s, w)
        sheet.paste(Image.fromarray(tile_arr, "RGBA"), (bx, by))

        tiles_meta.append({
            "id": str(tile_id),
            "edges": {
                "N": "upper" if n else "lower",
                "E": "upper" if e else "lower",
                "S": "upper" if s else "lower",
                "W": "upper" if w else "lower",
            },
            "bounding_box": {"x": bx, "y": by, "width": TILE_SIZE, "height": TILE_SIZE},
        })

    sheet.save(out_png)

    meta = {
        "tileset_data": {
            "tiles": tiles_meta,
            "tile_size": {"width": TILE_SIZE, "height": TILE_SIZE},
            "total_tiles": 16,
            "terrain_types": ["lower", "upper"],
            "autotile_kind": "edge",
        },
        "metadata": {
            "terrain_prompts": {
                "lower": lower_name,
                "upper": upper_name,
            }
        },
    }
    with open(out_json, "w") as f:
        json.dump(meta, f, indent=2)

    print(f"  {os.path.basename(out_png)}  ({SHEET_SIZE}x{SHEET_SIZE}, 32x32 edge tiles)")


def generate(lower_path: str, upper_path: str, out_png: str, out_json: str,
             lower_name: str, upper_name: str, mode: str = "soft") -> None:
    lower_img = Image.open(lower_path).convert("RGBA").resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)
    upper_img = Image.open(upper_path).convert("RGBA").resize((TILE_SIZE, TILE_SIZE), Image.NEAREST)

    lower_arr = np.array(lower_img, dtype=np.float32)
    upper_arr = np.array(upper_img, dtype=np.float32)

    sheet = Image.new("RGBA", (SHEET_SIZE, SHEET_SIZE))
    tiles_meta = []

    for tile_id in range(16):
        nw = (tile_id >> 3) & 1
        ne = (tile_id >> 2) & 1
        sw = (tile_id >> 1) & 1
        se = tile_id & 1

        col = tile_id % GRID
        row = tile_id // GRID
        bx = col * TILE_SIZE
        by = row * TILE_SIZE

        if mode == "masked":
            tile_arr = build_masked_wang_tile(lower_arr, upper_arr, nw, ne, sw, se)
        else:
            tile_arr = build_wang_tile(lower_arr, upper_arr, nw, ne, sw, se)
        tile_img = Image.fromarray(tile_arr, "RGBA")
        sheet.paste(tile_img, (bx, by))

        tiles_meta.append({
            "id": str(tile_id),
            "corners": {
                "NW": "upper" if nw else "lower",
                "NE": "upper" if ne else "lower",
                "SW": "upper" if sw else "lower",
                "SE": "upper" if se else "lower",
            },
            "bounding_box": {"x": bx, "y": by, "width": TILE_SIZE, "height": TILE_SIZE},
        })

    sheet.save(out_png)

    meta = {
        "tileset_data": {
            "tiles": tiles_meta,
            "tile_size": {"width": TILE_SIZE, "height": TILE_SIZE},
            "total_tiles": 16,
            "terrain_types": ["lower", "upper"],
        },
        "metadata": {
            "terrain_prompts": {
                "lower": lower_name,
                "upper": upper_name,
            }
        },
    }
    with open(out_json, "w") as f:
        json.dump(meta, f, indent=2)

    print(f"  {os.path.basename(out_png)}  ({SHEET_SIZE}x{SHEET_SIZE}, 32x32 tiles)")


TILES = "/Users/nikitafadeev/rengeteg/assets/tiles"
OUT   = "/Users/nikitafadeev/rengeteg/assets/tilesets"

pairs = [
    # (lower_file, upper_file, output_stem, lower_name, upper_name, kind, mode)
    ("dirt.png",                 "grass.png",               "verdant_soil_grass",    "dirt path",       "lush grass", "edge", "soft"),
    ("grass.png",                "flowers.png",              "verdant_grass_flowers", "open grass",      "flower meadow", "wang", "soft"),
]

print("Generating Wang tilesets...")
for lower_f, upper_f, stem, lname, uname, kind, mode in pairs:
    lower_path = os.path.join(TILES, lower_f)
    upper_path = os.path.join(TILES, upper_f)
    out_png = os.path.join(OUT, stem + ".png")
    out_json = os.path.join(OUT, stem + ".json")
    if kind == "edge":
        generate_edge(lower_path, upper_path, out_png, out_json, lname, uname)
    else:
        generate(lower_path, upper_path, out_png, out_json, lname, uname, mode)
print("Done.")
