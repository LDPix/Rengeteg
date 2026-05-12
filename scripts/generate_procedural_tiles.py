#!/usr/bin/env python3
"""Generate seamless 32x32 procedural pixel-art terrain tiles.

This is intentionally conservative: homogeneous material textures only, no
scene composition and no large objects near tile edges.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "tiles"
SIZE = 32
_NOISE_GRIDS: dict[tuple[int, int], list[list[float]]] = {}


def _lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def _mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(_lerp(a[i], b[i], t) for i in range(3))


def _clamp(v: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, v))


def _smoothstep(t: float) -> float:
    return t * t * (3.0 - 2.0 * t)


def _grid(seed: int, freq: int) -> list[list[float]]:
    key = (seed, freq)
    if key not in _NOISE_GRIDS:
        rng = random.Random(seed * 1009 + freq * 9176)
        _NOISE_GRIDS[key] = [[rng.random() for _x in range(freq)] for _y in range(freq)]
    return _NOISE_GRIDS[key]


def _value_noise(x: int, y: int, seed: int, freq: int) -> float:
    grid = _grid(seed, freq)
    gx = x / SIZE * freq
    gy = y / SIZE * freq
    x0 = int(math.floor(gx)) % freq
    y0 = int(math.floor(gy)) % freq
    x1 = (x0 + 1) % freq
    y1 = (y0 + 1) % freq
    tx = _smoothstep(gx - math.floor(gx))
    ty = _smoothstep(gy - math.floor(gy))

    a = grid[y0][x0] * (1.0 - tx) + grid[y0][x1] * tx
    b = grid[y1][x0] * (1.0 - tx) + grid[y1][x1] * tx
    return a * (1.0 - ty) + b * ty


def _periodic_noise(x: int, y: int, seed: int, octaves: int = 5) -> float:
    total = 0.0
    norm = 0.0
    for octave in range(octaves):
        freq = 2 ** (octave + 1)
        amp = 1.0 / (octave + 1)
        total += _value_noise(x, y, seed + octave * 37, freq) * amp
        norm += amp
    return total / norm


def _speckle(x: int, y: int, seed: int, rate: int) -> bool:
    return random.Random(seed + x * 73856093 + y * 19349663).randrange(rate) == 0


def _save(name: str, pixels: list[list[tuple[int, int, int]]]) -> None:
    img = Image.new("RGBA", (SIZE, SIZE))
    for y in range(SIZE):
        for x in range(SIZE):
            img.putpixel((x, y), (*pixels[y][x], 255))
    img.save(OUT / f"{name}.png")
    print(f"wrote assets/tiles/{name}.png")


def _save_image(name: str, img: Image.Image) -> None:
    img.save(OUT / f"{name}.png")
    print(f"wrote assets/tiles/{name}.png")


def _material(name: str, seed: int, low: tuple[int, int, int], high: tuple[int, int, int], accent: tuple[int, int, int] | None = None) -> None:
    pixels = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            n = _periodic_noise(x, y, seed, 5)
            fine = _periodic_noise(x, y, seed + 997, 3)
            color = _mix(low, high, _clamp(n * 0.75 + fine * 0.25))
            if accent and _speckle(x, y, seed + 11, 34):
                color = _mix(color, accent, 0.45)
            row.append(color)
        pixels.append(row)
    _save(name, pixels)


def _plain_grass(name: str, color: tuple[int, int, int]) -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (*color, 255))
    _save_image(name, img)


def _grass(
    name: str,
    seed: int,
    low: tuple[int, int, int],
    high: tuple[int, int, int],
    shimmer: tuple[int, int, int] | None = None,
    pattern_seed: int | None = None,
) -> None:
    _ = pattern_seed
    rng = random.Random(seed)
    base = _mix(low, high, 0.54)
    img = Image.new("RGBA", (SIZE, SIZE), (*base, 255))
    draw = ImageDraw.Draw(img)
    dark = _mix(low, base, 0.35)
    mid = _mix(low, high, 0.45)
    light = _mix(base, high, 0.45)

    # Broad soft patches first: these read as areas of grass, not pixel noise.
    for _patch in range(4):
        cx = rng.randrange(SIZE)
        cy = rng.randrange(SIZE)
        rx = rng.randrange(5, 10)
        ry = rng.randrange(3, 7)
        color = dark if rng.random() < 0.7 else light
        for ox in (-SIZE, 0, SIZE):
            for oy in (-SIZE, 0, SIZE):
                draw.ellipse(
                    (cx - rx + ox, cy - ry + oy, cx + rx + ox, cy + ry + oy),
                    fill=(*_mix(base, color, 0.28), 255),
                )

    # Blade clumps: short strokes grouped in patches, deliberately not dots.
    for _patch in range(7):
        cx = rng.randrange(SIZE)
        cy = rng.randrange(SIZE)
        radius = rng.randrange(3, 7)
        blade_count = rng.randrange(7, 13)
        for _blade in range(blade_count):
            px = cx + rng.randrange(-radius, radius + 1)
            py = cy + rng.randrange(-radius // 2, radius // 2 + 1)
            length = rng.randrange(3, 7)
            slant = rng.choice([-1, 0, 1])
            color = rng.choice([dark, mid, light])
            for ox in (-SIZE, 0, SIZE):
                for oy in (-SIZE, 0, SIZE):
                    draw.line(
                        (px + ox, py + oy, px + slant + ox, py - length + oy),
                        fill=(*color, 255),
                        width=1,
                    )

    if shimmer:
        for _spark in range(4):
            x = rng.randrange(SIZE)
            y = rng.randrange(SIZE)
            draw.point((x, y), fill=(*_mix(base, shimmer, 0.55), 255))

    _save_image(name, img)


def _flowers() -> None:
    low = (54, 132, 48)
    high = (110, 181, 74)
    flower_colors = [(223, 87, 142), (239, 202, 73), (236, 235, 197), (151, 98, 211)]
    pixels = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            n = _periodic_noise(x, y, 113, 5)
            color = _mix(low, high, n)
            if _speckle(x, y, 211, 21):
                color = flower_colors[(x * 3 + y * 5) % len(flower_colors)]
            row.append(color)
        pixels.append(row)
    _save("flowers", pixels)


def _stone() -> None:
    mortar = (72, 74, 83)
    dark = (103, 106, 119)
    light = (159, 162, 174)
    pixels = []
    for y in range(SIZE):
        row = []
        stagger = 8 if (y // 8) % 2 else 0
        for x in range(SIZE):
            lx = (x + stagger) % 16
            ly = y % 8
            if lx in (0, 15) or ly in (0, 7):
                color = mortar
            else:
                n = _periodic_noise(x, y, 307, 4)
                color = _mix(dark, light, n)
                if _speckle(x, y, 313, 30):
                    color = _mix(color, mortar, 0.38)
            row.append(color)
        pixels.append(row)
    _save("stone", pixels)


def _cave(name: str, seed: int, glow: tuple[int, int, int] | None = None) -> None:
    low = (37, 38, 54)
    high = (91, 89, 112)
    pixels = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            n = _periodic_noise(x, y, seed, 6)
            grain = _periodic_noise(x, y, seed + 29, 3)
            color = _mix(low, high, _clamp(n * 0.85 + grain * 0.15))
            if _speckle(x, y, seed + 5, 28):
                color = _mix(color, (126, 122, 150), 0.3)
            if glow and _speckle(x, y, seed + 43, 45):
                color = _mix(color, glow, 0.55)
            row.append(color)
        pixels.append(row)
    _save(name, pixels)


def _lava(name: str, seed: int, intense: bool = False) -> None:
    crust = (45, 39, 55) if not intense else (38, 39, 54)
    ember = (186, 58, 42)
    hot = (255, 167, 57)
    pixels = []
    for y in range(SIZE):
        row = []
        for x in range(SIZE):
            n = _periodic_noise(x, y, seed, 5)
            vein = abs(math.sin(math.tau * (x / 13.0 + y / 19.0 + 0.15 * math.sin(math.tau * y / SIZE))))
            heat = _clamp(n * 0.55 + (1.0 - vein) * (0.55 if intense else 0.42))
            if heat > 0.62:
                color = _mix(ember, hot, (heat - 0.62) / 0.38)
            else:
                color = _mix(crust, ember, heat * 0.55)
            if _speckle(x, y, seed + 101, 36):
                color = _mix(color, hot, 0.25)
            row.append(color)
        pixels.append(row)
    _save(name, pixels)


def main() -> None:
    _plain_grass("grass", (85, 146, 58))
    _grass("grass_1", 137, (46, 114, 42), (116, 181, 73), pattern_seed=101)
    _grass("grass_2", 173, (43, 113, 43), (120, 183, 75), pattern_seed=101)
    _grass("grass_3", 197, (47, 117, 41), (115, 179, 72), pattern_seed=101)
    _grass("grass_4", 229, (44, 115, 44), (119, 182, 76), pattern_seed=101)
    _material("dirt", 107, (122, 78, 48), (204, 146, 91), (80, 55, 39))
    _flowers()
    _stone()
    _cave("cave_wall", 149)
    _lava("lava", 163)


if __name__ == "__main__":
    main()
