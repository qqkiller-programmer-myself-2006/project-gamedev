"""Slice Bram RGBA sheets (3 cols x 2 rows, 6 frames each) -- Bram only.

Source sheets live in art_source/characters/bram/ as full-RGBA PNGs with a
transparent background. Frames are cropped tight, then pasted onto a common
per-animation canvas anchored on the mass-weighted x-centre with a shared
baseline -- the same conventions as tools/art/slice_elder_thornwarden.py
(PAD/MARGIN/baseline), but with Bram's own grid boundaries. This script
knows nothing about Elder Thornwarden or any other character.

Grid: nominal column splits [0, 557, 1115, 1672] and row split [0, 470, 941].
Row 1 of the attack sheet needs a shifted middle boundary at x=645: frame 3's
effect tail crosses the nominal x=557 line (art present at x=557) and only
ends at x=596, while frame 4's own art starts at x=698 (transparent gap
597..697 verified by column profile); the boundary sits mid-gap.

Usage:
    python tools/art/slice_bram_sheet.py

Writes:
    assets/heroes/bram/{idle,attack}_?.png (6 + 6)
    assets/heroes/bram/portrait.png (260x260 head crop of idle_0)
    build/slice_contact/bram_{idle,attack}.png (contact sheets)

Manifest wiring is left to the caller (see assets/heroes/manifest.json key
"bram"); hurt/dead intentionally reuse idle frames via SpriteSet fallback,
no fictional art is made.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art_source" / "characters" / "bram"
OUT = ROOT / "assets" / "heroes" / "bram"
CONTACT = ROOT / "build" / "slice_contact"

COLS, ROWS = 3, 2
NOMINAL_XS = [0, 557, 1115, 1672]
NOMINAL_YS = [0, 470, 941]
# Per-animation, per-row column splits. Only attack row 1 differs (see above).
ROW_XS = {
    "idle": {0: NOMINAL_XS, 1: NOMINAL_XS},
    "attack": {0: NOMINAL_XS, 1: [0, 645, 1115, 1672]},
}
ALPHA = 16   # art pixels are ~250 opaque; background haze is alpha <= 2
PAD = 3      # pixels kept around the detected bbox (pipeline convention)
MARGIN = 2   # canvas margin around the largest frame (pipeline convention)
PORTRAIT_SIZE = 260  # matches archer/guardian/swordsman portraits

SHEETS = {"idle": "Bram_Idle.png", "attack": "Bram_Attack.png"}
EXPECTED_FRAMES = 6


def grid_cells(anim: str, w: int, h: int):
    ys = [round(y * h / 941) for y in NOMINAL_YS]
    for r in range(ROWS):
        xs = [round(x * w / 1672) for x in ROW_XS[anim][r]]
        for c in range(COLS):
            yield (xs[c], ys[r], xs[c + 1], ys[r + 1])


def art_bbox(cell: Image.Image):
    """Tight bbox of art pixels (alpha > ALPHA) in cell-local coords."""
    a = cell.getchannel("A")
    w, h = cell.size
    data = list(a.getdata())
    xs = [x for y in range(h) for x in range(w) if data[y * w + x] > ALPHA]
    if not xs:
        return None
    ys = [y for y in range(h) for x in range(w) if data[y * w + x] > ALPHA]
    return (min(xs), min(ys), max(xs) + 1, max(ys) + 1)


def touches_boundary(cell: Image.Image, bb):
    """True if art reaches the cell edge (would be clipped by the split)."""
    bx0, by0, bx1, by1 = bb
    return bx0 <= 0 or by0 <= 0 or bx1 >= cell.width or by1 >= cell.height


def slice_sheet(path: Path, anim: str):
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    pieces = []  # (crop_box_sheet_coords, cx_sheet)
    for i, (x0, y0, x1, y1) in enumerate(grid_cells(anim, w, h)):
        cell = im.crop((x0, y0, x1, y1))
        bb = art_bbox(cell)
        if bb is None:
            print(f"FAIL {anim} frame {i}: no art in cell {(x0, y0, x1, y1)}")
            sys.exit(1)
        if touches_boundary(cell, bb):
            print(f"FAIL {anim} frame {i}: art touches cell boundary "
                  f"{(x0, y0, x1, y1)} -- grid split is wrong")
            sys.exit(1)
        bx0, by0, bx1, by1 = bb
        # mass-weighted horizontal anchor from art pixels
        a = cell.getchannel("A")
        data = list(a.getdata())
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
        print(f"{anim}_{i}: cell {(x0, y0, x1, y1)} art {(bx0, by0, bx1, by1)} "
              f"mass {mass}")
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


def make_portrait(idle_images: list[Image.Image]) -> Image.Image:
    """260x260 head crop from idle_0: square centred on the art's mass
    centre-x, hanging from the top of the art bbox (head/shoulders bust,
    matching the other heroes' portraits)."""
    img = idle_images[0]
    bb = art_bbox(img)
    if bb is None:
        print("FAIL portrait: no art in idle_0")
        sys.exit(1)
    bx0, by0, bx1, _ = bb
    side = min(bx1 - bx0, img.height - by0)
    if side <= 0:
        print("FAIL portrait: degenerate art bbox")
        sys.exit(1)
    cx = (bx0 + bx1) // 2
    x0 = min(max(cx - side // 2, 0), img.width - side)
    crop = img.crop((x0, by0, x0 + side, by0 + side))
    return crop.resize((PORTRAIT_SIZE, PORTRAIT_SIZE), Image.LANCZOS)


def checker(w: int, h: int, s: int = 8):
    img = Image.new("RGBA", (w, h), (200, 200, 200, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, h, s):
        for x in range(0, w, s):
            if (x // s + y // s) % 2:
                d.rectangle((x, y, x + s - 1, y + s - 1), fill=(150, 150, 150, 255))
    return img


def contact_sheet(anim: str, images: list[Image.Image]):
    tiles = [(f"{anim}_{i}.png", img) for i, img in enumerate(images)]
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
    out = CONTACT / f"bram_{anim}.png"
    sheet.save(out)
    print(f"contact: {out} ({sheet.size})")


def main() -> int:
    anims: dict[str, list[Image.Image]] = {}
    meta = {}
    for anim, fn in SHEETS.items():
        src = SRC / fn
        if not src.exists():
            print(f"FAIL missing source {src}")
            return 1
        images, canvas, baseline = slice_sheet(src, anim)
        if len(images) != EXPECTED_FRAMES:
            print(f"FAIL {anim}: expected {EXPECTED_FRAMES} frames, "
                  f"got {len(images)}")
            return 1
        anims[anim] = images
        meta[anim] = (canvas, baseline)
    portrait = make_portrait(anims["idle"])
    if portrait.size != (PORTRAIT_SIZE, PORTRAIT_SIZE):
        print(f"FAIL portrait: expected "
              f"{(PORTRAIT_SIZE, PORTRAIT_SIZE)}, got {portrait.size}")
        return 1
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.rglob("*.png"):
        old.unlink()
    for anim, images in anims.items():
        for i, img in enumerate(images):
            img.save(OUT / f"{anim}_{i}.png")
        contact_sheet(anim, images)
    portrait.save(OUT / "portrait.png")
    print(json.dumps({a: {"canvas": c, "baseline": b}
                      for a, (c, b) in meta.items()}, indent=2))
    frames = sorted(p.name for p in OUT.glob("*.png"))
    print(f"wrote {len(frames)} files to {OUT}: {frames}")
    return 0 if len(frames) == 2 * EXPECTED_FRAMES + 1 else 1


if __name__ == "__main__":
    sys.exit(main())
