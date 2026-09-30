"""Slice Elder Thornwarden RGBA sheets (3 cols x 2 rows, 6 frames each).

Source sheets live in art_source/enemies/boss/ as full-RGBA PNGs with a
transparent background (a faint alpha<=2 export haze is keyed out by the
ALPHA threshold). Frames are cropped tight, then pasted onto a common
per-animation canvas anchored on the mass-weighted x-centre with a shared
baseline -- the same conventions as tools/art/slice_enemy_sheet.py
(PAD/MARGIN/baseline), but with a fixed grid instead of label-band
detection, which that script's CONFIG does not cover.

Usage:
    python tools/art/slice_elder_thornwarden.py

Writes:
    assets/enemies/elder_thornwarden/{idle,attack}_??.png (6 + 6)
    build/slice_contact/elder_thornwarden.png (contact sheet)

Manifest/forest.json wiring is left to the caller (see manifest.json and
content/forest.json enemies.elder_thornwarden); hurt/die intentionally
reuse idle frames via manifest filename lists, no fictional art is made.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art_source" / "enemies" / "boss"
OUT = ROOT / "assets" / "enemies" / "elder_thornwarden"
CONTACT = ROOT / "build" / "slice_contact"

COLS, ROWS = 3, 2
# Column splits per grid row. Row 1 of the attack sheet needs a shifted
# middle boundary: frame 3's figure tail crosses the nominal x=557 line and
# only ends ~605, while frame 4's own body starts ~680 (transparent gap
# 610..680 verified by column profile); the boundary sits mid-gap.
ROW_XS = {0: [0, 557, 1115, 1672], 1: [0, 645, 1115, 1672]}
ALPHA = 16   # art pixels are ~250 opaque; background haze is alpha <= 2
PAD = 3      # pixels kept around the detected bbox (pipeline convention)
MARGIN = 2   # canvas margin around the largest frame (pipeline convention)

SHEETS = {"idle": "ElderThorwarden.png", "attack": "ElderThorwarden_Attack.png"}


def grid_cells(w: int, h: int):
    ys = [round(j * h / ROWS) for j in range(ROWS + 1)]
    for r in range(ROWS):
        for c in range(COLS):
            xs = [round(x * w / 1672) for x in ROW_XS[r]]
            yield (xs[c], ys[r], xs[c + 1], ys[r + 1])


def art_bbox(cell: Image.Image):
    """Tight bbox of art pixels (alpha > ALPHA) in cell-local coords."""
    a = cell.getchannel("A")
    w, h = cell.size
    data = list(a.get_flattened_data() if hasattr(a, "get_flattened_data") else a.getdata())
    xs = [x for y in range(h) for x in range(w) if data[y * w + x] > ALPHA]
    if not xs:
        return None
    ys = [y for y in range(h) for x in range(w) if data[y * w + x] > ALPHA]
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1)


def slice_sheet(path: Path, anim: str):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    pieces = []  # (crop_box_sheet_coords, cx_sheet, mass)
    for i, (x0, y0, x1, y1) in enumerate(grid_cells(w, h)):
        cell = im.crop((x0, y0, x1, y1))
        bb = art_bbox(cell)
        if bb is None:
            print(f"FAIL {anim} frame {i}: no art in cell {(x0, y0, x1, y1)}")
            sys.exit(1)
        bx0, by0, bx1, by1 = bb
        # mass-weighted horizontal anchor from art pixels
        a = cell.getchannel("A")
        data = list(a.get_flattened_data() if hasattr(a, "get_flattened_data") else a.getdata())
        mass = 0
        mx = 0
        for yy in range(by0, by1):
            for xx in range(bx0, bx1):
                v = data[yy * cell.width + xx]
                if v > ALPHA:
                    mass += v
                    mx += (x0 + xx) * v
        cx = mx / mass if mass else (x0 + (bx0 + bx1) / 2)
        box = (max(x0 + bx0 - PAD, x0), max(y0 + by0 - PAD, y0),
               min(x0 + bx1 + PAD, x1), min(y0 + by1 + PAD, y1))
        edge = (box[0] == x0 or box[1] == y0 or box[2] == x1 or box[3] == y1)
        print(f"{anim}_{i:02d}: cell {(x0, y0, x1, y1)} art {(bx0, by0, bx1, by1)} "
              f"mass {mass} edge_touch={edge}")
        pieces.append((box, cx))
    # Common canvas: horizontally anchored on the mass-weighted cx, with a
    # shared baseline so every frame's art bottom sits at the same canvas y.
    # (Frames come from different grid rows, so sheet-y cannot be shared --
    # only the per-frame art bottom aligns.)
    half = max(max(cx - b[0], b[2] - cx) for b, cx in pieces)
    cw = int(2 * half + 0.999) + 2 * MARGIN
    ch = max(b[3] - b[1] for b, _ in pieces) + 2 * MARGIN
    images = []
    for (b, cx) in pieces:
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        part = im.crop(b)
        canvas.paste(part, (round(cw / 2 - (cx - b[0])), ch - MARGIN - (b[3] - b[1])),
                     part)
        images.append(canvas)
    baseline = ch - MARGIN - 1 - PAD
    return images, [cw, ch], baseline


def checker(w: int, h: int, s: int = 8):
    img = Image.new("RGBA", (w, h), (200, 200, 200, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, h, s):
        for x in range(0, w, s):
            if (x // s + y // s) % 2:
                d.rectangle((x, y, x + s - 1, y + s - 1), fill=(150, 150, 150, 255))
    return img


def contact_sheet(anims: dict[str, list[Image.Image]]):
    tiles = [(f"{a}_{i:02d}.png", img)
             for a, imgs in anims.items() for i, img in enumerate(imgs)]
    per_row = 6
    cell_w = min(max(t.width for _, t in tiles) * 2 + 8, 330)
    cell_h = min(max(t.height for _, t in tiles) * 2 + 22, 330)
    rows = (len(tiles) + per_row - 1) // per_row
    sheet = Image.new("RGBA", (cell_w * per_row, cell_h * rows), (40, 40, 48, 255))
    d = ImageDraw.Draw(sheet)
    for i, (name, t) in enumerate(tiles):
        s = min(2.0, (cell_w - 8) / t.width, (cell_h - 22) / t.height)
        img = t.resize((max(1, int(t.width * s)), max(1, int(t.height * s))),
                       Image.NEAREST)
        cx, cy = (i % per_row) * cell_w, (i // per_row) * cell_h
        tile = checker(img.width, img.height)
        tile.alpha_composite(img)
        sheet.paste(tile, (cx + 4, cy + 4))
        d.rectangle((cx + 3, cy + 3, cx + 4 + img.width, cy + 4 + img.height),
                    outline=(255, 0, 255, 255))
        d.text((cx + 4, cy + cell_h - 16), name, fill=(255, 255, 255, 255))
    CONTACT.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT / "elder_thornwarden.png")
    print(f"contact: {CONTACT / 'elder_thornwarden.png'} ({sheet.size})")


def main() -> int:
    anims: dict[str, list[Image.Image]] = {}
    meta = {}
    for anim, fn in SHEETS.items():
        src = SRC / fn
        if not src.exists():
            print(f"FAIL missing source {src}")
            return 1
        images, canvas, baseline = slice_sheet(src, anim)
        if len(images) != 6:
            print(f"FAIL {anim}: expected 6 frames, got {len(images)}")
            return 1
        anims[anim] = images
        meta[anim] = (canvas, baseline)
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.rglob("*.png"):
        old.unlink()
    for anim, images in anims.items():
        for i, img in enumerate(images):
            img.save(OUT / f"{anim}_{i:02d}.png")
    contact_sheet(anims)
    print(json.dumps({a: {"canvas": c, "baseline": b}
                      for a, (c, b) in meta.items()}, indent=2))
    count = len(list(OUT.glob("*.png")))
    print(f"wrote {count} frames to {OUT}")
    return 0 if count == 12 else 1


if __name__ == "__main__":
    sys.exit(main())
