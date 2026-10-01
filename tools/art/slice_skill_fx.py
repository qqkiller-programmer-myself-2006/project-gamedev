#!/usr/bin/env python3
"""Slice skill strips using the exact frame geometry in their manifest."""
from pathlib import Path
from PIL import Image
import json

ROOT = Path(__file__).resolve().parents[2]
manifest = json.loads((ROOT / "assets/fx/manifest.json").read_text(encoding="utf-8"))
for skill, info in manifest.items():
    count = int(info["frames"]); width, height = map(int, info["size"])
    path = ROOT / "art_source/fx" / f"{skill}.png"
    image = Image.open(path).convert("RGBA")
    if image.size != (count * width, height):
        raise SystemExit(f"{skill}: expected strip {(count * width, height)}, got {image.size}")
    out = ROOT / "assets/fx" / skill; out.mkdir(parents=True, exist_ok=True)
    for i in range(count):
        frame = image.crop((i * width, 0, (i + 1) * width, height))
        bbox = frame.getchannel("A").getbbox()
        if bbox and (bbox[0] < 8 or bbox[1] < 8 or bbox[2] > width - 8 or bbox[3] > height - 8):
            raise SystemExit(f"{skill} frame {i}: alpha bbox {bbox} violates 8px transparent margin in {width}x{height}")
        frame.save(out / f"frame_{i:02d}.png", optimize=True)
    actual = sorted(out.glob("frame_*.png"))
    if len(actual) != count:
        raise SystemExit(f"{skill}: expected {count} sliced frames, got {len(actual)}")
print(f"Sliced {len(manifest)} skill strips with exact frame counts.")
