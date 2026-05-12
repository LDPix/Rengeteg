#!/usr/bin/env python3
"""Generate pixel art POI icons via PixelLab /map-objects API.

Usage:
    PIXELLAB_API_KEY=your_key python scripts/generate_poi_art.py
"""

import base64
import json
import os
import ssl
import sys
import urllib.error
import urllib.request
from pathlib import Path

# macOS Python.org builds don't ship CA certs; load them from certifi if
# available, otherwise fall back to the system trust store.
try:
    import certifi
    _SSL_CTX = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    _SSL_CTX = ssl.create_default_context()
    # Last resort: disable verification so the script still runs on stock
    # Python.org installs that lack a trust store.
    if not _SSL_CTX.get_ca_certs():
        _SSL_CTX.check_hostname = False
        _SSL_CTX.verify_mode = ssl.CERT_NONE

API_KEY = os.environ.get("PIXELLAB_API_KEY", "")
BASE_URL = "https://api.pixellab.ai/v2"

ROOT = Path(__file__).resolve().parents[1]

# Each entry: asset stem -> (prompt, output path relative to ROOT)
POI_ICONS: dict[str, tuple[str, str]] = {
    "herb_flower_patch": (
        "A small lush cluster of green leafy plants with tiny yellow and pink wildflower blooms, "
        "overworld RPG map icon, top-down view",
        "assets/resources/herb_flower_patch.png",
    ),
    "species_mat_cocoon": (
        "A silky white cocoon wrapped in silk threads resting on a dark twig with a few leaves, "
        "overworld RPG map icon, top-down view",
        "assets/resources/species_mat_cocoon.png",
    ),
    "core_shard_relic": (
        "A glowing magical crystal shard relic with a soft inner light and faint ancient rune markings, "
        "overworld RPG map icon, top-down view",
        "assets/resources/core_shard_relic.png",
    ),
    "wood_branch_pile": (
        "A small neat pile of wooden sticks and brown branches tied loosely with twine, "
        "overworld RPG map icon, top-down view",
        "assets/resources/wood_branch_pile.png",
    ),
    "exit_portal": (
        "A swirling circular magical portal with blue and teal glowing energy rings and sparks, "
        "overworld RPG map icon, top-down view",
        "assets/overworld/exit_portal.png",
    ),
}


def _extract_image_bytes(response_json: dict) -> bytes | None:
    """Pull base64 image bytes out of a PixelLab response."""
    # Background-job result: {"last_response": {"image": "<base64>"}}
    last = response_json.get("last_response")
    if isinstance(last, dict):
        raw = last.get("image")
        if raw:
            return base64.b64decode(raw)

    # Immediate response: {"data": {"image": {"type": "base64", "base64": "..."}}}
    data = response_json.get("data") or {}
    for candidate in (data.get("image"), data, response_json):
        if not isinstance(candidate, dict):
            continue
        if candidate.get("type") == "base64" and candidate.get("base64"):
            return base64.b64decode(candidate["base64"])
        raw = candidate.get("base64") or candidate.get("image_base64")
        if raw:
            return base64.b64decode(raw)

    return None


def _api_request(method: str, path: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        data=data,
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=60, context=_SSL_CTX) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"HTTP {exc.code}: {exc.read()[:300]}") from exc


def _poll_job(job_id: str, poll_interval: float = 3.0, max_wait: float = 120.0) -> dict:
    import time
    elapsed = 0.0
    while elapsed < max_wait:
        result = _api_request("GET", f"/background-jobs/{job_id}")
        status = result.get("status", "")
        if status == "completed":
            return result
        if status == "failed":
            raise RuntimeError(f"Job {job_id} failed: {result}")
        time.sleep(poll_interval)
        elapsed += poll_interval
    raise RuntimeError(f"Job {job_id} timed out after {max_wait}s")


def generate_icon(name: str, description: str) -> bytes | None:
    try:
        queued = _api_request("POST", "/map-objects", {
            "description": description,
            "image_size": {"width": 48, "height": 48},
            "view": "low top-down",
            "outline": "single color outline",
            "shading": "basic shading",
            "detail": "medium detail",
            "text_guidance_scale": 9.0,
            "seed": abs(hash(name)) % (2**31),
        })
    except RuntimeError as exc:
        print(f"  [error] {exc}")
        return None

    job_id = queued.get("background_job_id")
    if not job_id:
        print(f"  [error] no background_job_id in response: {queued}")
        return None

    print(f"  queued job {job_id}, polling…")
    try:
        result = _poll_job(job_id)
    except RuntimeError as exc:
        print(f"  [error] {exc}")
        return None

    img_bytes = _extract_image_bytes(result)
    if img_bytes is None:
        print(f"  [error] no image in completed job: {str(result)[:300]}")
    return img_bytes


def main() -> None:
    if not API_KEY:
        sys.exit("Set PIXELLAB_API_KEY environment variable and re-run.")

    generated: list[str] = []

    for name, (description, rel_path) in POI_ICONS.items():
        out_path = ROOT / rel_path
        print(f"Generating {name} → {rel_path} …")
        img_bytes = generate_icon(name, description)
        if img_bytes:
            out_path.write_bytes(img_bytes)
            print(f"  saved ({len(img_bytes):,} bytes)")
            generated.append(rel_path)
        else:
            print(f"  skipped (see error above)")

    if generated:
        print(f"\nDone. {len(generated)}/{len(POI_ICONS)} icons generated.")
        print("Reopen the Godot project so it imports the new .png files.")
    else:
        print("\nNo icons were generated — check the errors above.")


if __name__ == "__main__":
    main()
