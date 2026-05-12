#!/usr/bin/env python3
"""Convert player_sprite.png (16×32×32 spritesheet) to player_sprite.aseprite."""
import struct, zlib
from PIL import Image

FRAME_W, FRAME_H = 32, 32
NUM_FRAMES = 16

# idle frames stay for 1 s; walk frames play at ~8 fps
DURATIONS = [1000,125,125,125, 1000,125,125,125, 1000,125,125,125, 1000,125,125,125]

TAGS = [
    ("idle_down",  0,  0),
    ("walk_down",  1,  3),
    ("idle_up",    4,  4),
    ("walk_up",    5,  7),
    ("idle_left",  8,  8),
    ("walk_left",  9, 11),
    ("idle_right", 12, 12),
    ("walk_right", 13, 15),
]

def ase_str(s):
    b = s.encode()
    return struct.pack('<H', len(b)) + b

def make_chunk(tp, data):
    return struct.pack('<IH', 6 + len(data), tp) + data

def layer_chunk():
    d  = struct.pack('<HHHHHH', 0x0003, 0, 0, 0, 0, 0)
    d += struct.pack('<BBB', 255, 0, 0)
    d += ase_str("Background")
    return make_chunk(0x2004, d)

def cel_chunk(pixels, w, h):
    d  = struct.pack('<H', 0)
    d += struct.pack('<hh', 0, 0)
    d += struct.pack('<B', 255)
    d += struct.pack('<H', 2)
    d += struct.pack('<h', 0)
    d += bytes(5)
    d += struct.pack('<HH', w, h)
    d += zlib.compress(pixels, 9)
    return make_chunk(0x2005, d)

def tags_chunk():
    d = struct.pack('<H', len(TAGS)) + bytes(8)
    for name, f, t in TAGS:
        d += struct.pack('<HH', f, t)
        d += struct.pack('<B', 0)
        d += struct.pack('<H', 0)
        d += bytes(6)
        d += bytes(3)
        d += bytes(1)
        d += ase_str(name)
        d += struct.pack('<I', 0xFF000000)
        d += bytes(8)
    return make_chunk(0x2018, d)

def build_frame(chunk_list, duration_ms):
    body = b''.join(chunk_list)
    n = len(chunk_list)
    hdr  = struct.pack('<I', 16 + len(body))
    hdr += struct.pack('<H', 0xF1FA)
    hdr += struct.pack('<H', n if n <= 0xFFFE else 0xFFFF)
    hdr += struct.pack('<H', duration_ms)
    hdr += bytes(2)
    hdr += struct.pack('<I', n)
    return hdr + body

def build_header(file_size):
    h  = struct.pack('<I', file_size)
    h += struct.pack('<H', 0xA5E0)
    h += struct.pack('<H', NUM_FRAMES)
    h += struct.pack('<H', FRAME_W)
    h += struct.pack('<H', FRAME_H)
    h += struct.pack('<H', 32)
    h += struct.pack('<I', 1)
    h += struct.pack('<H', 0)
    h += struct.pack('<II', 0, 0)
    h += struct.pack('<B', 0)
    h += bytes(3)
    h += struct.pack('<H', 0)
    h += struct.pack('<BB', 1, 1)
    h += struct.pack('<hh', 0, 0)
    h += struct.pack('<HH', 0, 0)
    h += bytes(84)
    assert len(h) == 128, f"header is {len(h)} bytes"
    return h

def main():
    src = 'assets/player/player_sprite.png'
    dst = 'assets/player/player_sprite.aseprite'

    img = Image.open(src).convert('RGBA')
    assert img.width == FRAME_W * NUM_FRAMES, f"width mismatch: {img.width}"
    assert img.height == FRAME_H, f"height mismatch: {img.height}"

    frames = []
    for i in range(NUM_FRAMES):
        x0 = i * FRAME_W
        pixels = img.crop((x0, 0, x0 + FRAME_W, FRAME_H)).tobytes()
        chunks = []
        if i == 0:
            chunks.append(layer_chunk())
            chunks.append(tags_chunk())
        chunks.append(cel_chunk(pixels, FRAME_W, FRAME_H))
        frames.append(build_frame(chunks, DURATIONS[i]))

    body = b''.join(frames)
    with open(dst, 'wb') as f:
        f.write(build_header(128 + len(body)) + body)

    print(f"Written {dst}  ({128 + len(body):,} bytes, {NUM_FRAMES} frames, {len(TAGS)} tags)")

if __name__ == "__main__":
    main()
