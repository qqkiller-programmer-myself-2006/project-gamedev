"""Slice the Elder Thornwarden (boss) and Bram (Classless) sheets.

Sources (never edited, RGBA with transparent background, 1672x941):
    art_source/enemies/boss/ElderThorwarden.png         (idle)
    art_source/enemies/boss/ElderThorwarden_Attack.png  (attack)
    art_source/characters/bram/Bram_Idle.png            (idle)
    art_source/characters/bram/Bram_Attack.png          (attack)

Each sheet holds exactly 2 rows x 3 frames. Row bands below were read off
the sheets by looking at them (per-sheet config, not detection). Inside a
band, frames are split by column gaps in the alpha mask; small detached
pieces (leaves, slash arcs, impact glow) join the nearest body frame.
Every band must yield exactly its expected frame count or the script exits
non-zero without writing anything. Never pad, never guess.

Output:
    assets/enemies/elder_thornwarden/idle_00..05.png, attack_00..05.png, portrait.png
    assets/heroes/bram/idle_0..5.png, attack_0..5.png, portrait.png
Contact sheets (checkerboard + file name per frame):
    build/slice_contact/elder_thornwarden_idle.png, elder_thornwarden_attack.png,
    bram_idle.png, bram_attack.png

Frames of one animation share one canvas and one common baseline;
each frame is bottom-centre anchored.

Pillow only. Run:  python tools/art/slice_boss_bram.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
CONTACT = ROOT / "build" / "slice_contact"

ALPHA_T = 24   # alpha above this counts as art
COL_GAP = 6    # empty columns that separate two frames
SMALL = 0.22   # a segment below this share of the row median mass is an effect
PAD = 3        # pixels kept around the detected bbox
MARGIN = 2     # canvas margin around the largest frame of an animation


def band(y0: int, y1: int, x0: int, x1: int, count: int) -> dict:
    return {"y": (y0, y1), "x": (x0, x1), "count": count}


# Row bands read off the sheets. Sheet size is 1672x941 for all four.
CONFIG: dict[str, dict] = {
    "elder_thornwarden_idle": {
        "src": ROOT / "art_source" / "enemies" / "boss" / "ElderThorwarden.png",
        "out": ROOT / "assets" / "enemies" / "elder_thornwarden",
        "prefix": "idle",
        "bands": [band(9, 465, 0, 1672, 3), band(480, 940, 0, 1672, 3)],
    },
    "elder_thornwarden_attack": {
        "src": ROOT / "art_source" / "enemies" / "boss" / "ElderThorwarden_Attack.png",
        "out": ROOT / "assets" / "enemies" / "elder_thornwarden",
        "prefix": "attack",
        "bands": [band(64, 423, 0, 1672, 3), band(504, 872, 0, 1672, 3)],
    },
    "bram_idle": {
        "src": ROOT / "art_source" / "characters" / "bram" / "Bram_Idle.png",
        "out": ROOT / "assets" / "heroes" / "bram",
        "prefix": "idle",
        "bands": [band(17, 456, 0, 1672, 3), band(495, 924, 0, 1672, 3)],
    },
    "bram_attack": {
        "src": ROOT / "art_source" / "characters" / "bram" / "Bram_Attack.png",
        "out": ROOT / "assets" / "heroes" / "bram",
        "prefix": "attack",
        "bands": [band(102, 440, 0, 1672, 3), band(531, 874, 0, 1672, 3)],
    },
}


class SliceError(Exception):
    pass


def runs(values, gap: int):
    """Runs of truthy indices, merging runs separated by < gap empties."""
    out = []
    start = last = None
    for i, v in enumerate(values):
        if v:
            if start is None:
                start = i
            elif i - last > gap:
                out.append((start, last))
                start = i
            last = i
    if start is not None:
        out.append((start, last))
    return out


def alpha_columns(im: Image.Image, box: tuple[int, int, int, int]) -> list[int]:
    x0, y0, x1, y1 = box
    alpha = im.getchannel("A")
    cols = [0] * (x1 - x0)
    for y in range(y0, y1):
        for x in range(x0, x1):
            if alpha.getpixel((x, y)) > ALPHA_T:
                cols[x - x0] += 1
    return cols


def alpha_rows(im: Image.Image, box: tuple[int, int, int, int]) -> list[int]:
    x0, y0, x1, y1 = box
    alpha = im.getchannel("A")
    rows = [0] * (y1 - y0)
    for y in range(y0, y1):
        for x in range(x0, x1):
            if alpha.getpixel((x, y)) > ALPHA_T:
                rows[y - y0] += 1
    return rows


def find_frames(im: Image.Image, spec: dict, name: str) -> list[dict]:
    """Return frame dicts with sheet-coord bbox, anchor cx and mass."""
    x0, x1 = spec["x"]
    y0, y1 = spec["y"]
    cols = alpha_columns(im, (x0, y0, x1, y1))
    spans = runs(cols, COL_GAP)
    segs = [(x0 + a, x0 + b, sum(cols[a:b + 1])) for a, b in spans]
    if not segs:
        raise SliceError(f"{name}: no art in band {spec}")
    masses = sorted(m for _, _, m in segs)
    median = masses[len(masses) // 2]
    bodies = [s for s in segs if s[2] >= SMALL * median]
    small = [s for s in segs if s[2] < SMALL * median]
    if len(bodies) != spec["count"]:
        desc = " ".join(f"{a}-{b}({m})" for a, b, m in segs)
        raise SliceError(
            f"{name}: expected {spec['count']} frames, found "
            f"{len(bodies)} bodies in {spec}: {desc}"
        )
    frames = []
    for a, b, m in bodies:
        cx = sum((x0 + i) * cols[i] for i in range(a - x0, b - x0 + 1)) / m
        frames.append({"xa": a, "xb": b, "cx": cx, "mass": m})
    for a, b, _m in small:
        best = min(frames, key=lambda f: max(f["xa"] - b, a - f["xb"], 0))
        best["xa"] = min(best["xa"], a)
        best["xb"] = max(best["xb"], b)
    for f in frames:
        rows = alpha_rows(im, (f["xa"], y0, f["xb"] + 1, y1))
        ys = [i for i, v in enumerate(rows) if v]
        if not ys:
            raise SliceError(f"{name}: empty frame at x {f['xa']}-{f['xb']}")
        f["ya"], f["yb"] = y0 + ys[0], y0 + ys[-1]
    return frames


def slice_sheet(key: str, cfg: dict) -> tuple[list[Image.Image], list[int], int, Image.Image]:
    """Cut all frames; return (images, canvas size, baseline, portrait)."""
    if not cfg["src"].exists():
        raise SliceError(f"{key}: missing source {cfg['src']}")
    im = Image.open(cfg["src"]).convert("RGBA")
    if im.size != (1672, 941):
        raise SliceError(f"{key}: expected 1672x941, got {im.size}")
    frames: list[dict] = []
    for i, spec in enumerate(cfg["bands"]):
        frames.extend(find_frames(im, spec, f"{key}.row{i}"))
    if len(frames) != 6:
        raise SliceError(f"{key}: expected 6 frames total, found {len(frames)}")
    boxes = []
    for f in frames:
        y0, y1 = cfg["bands"][0]["y"][0], cfg["bands"][-1]["y"][1]
        boxes.append((
            max(f["xa"] - PAD, 0),
            max(f["ya"] - PAD, y0),
            min(f["xb"] + PAD + 1, im.width),
            min(f["yb"] + PAD + 1, y1),
        ))
    heights = [b[3] - b[1] for b in boxes]
    max_h = max(heights)
    half = max(max(f["cx"] - b[0], b[2] - f["cx"]) for f, b in zip(frames, boxes))
    w = int(2 * half + 0.999) + 2 * MARGIN
    h = max_h + 2 * MARGIN
    images = []
    for f, b in zip(frames, boxes):
        canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        piece = im.crop(b)
        # Bottom-centre anchor on the common baseline: every frame's own
        # bottom (feet + PAD) lands at h - MARGIN, whatever its height.
        canvas.paste(piece, (round(w / 2 - (f["cx"] - b[0])), MARGIN + max_h - (b[3] - b[1])), piece)
        images.append(canvas)
    baseline = h - MARGIN - 1 - PAD
    portrait = im.crop(boxes[0])
    return images, [w, h], baseline, portrait


def checker(w: int, h: int, s: int = 8) -> Image.Image:
    img = Image.new("RGBA", (w, h), (200, 200, 200, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, h, s):
        for x in range(0, w, s):
            if (x // s + y // s) % 2:
                d.rectangle((x, y, x + s - 1, y + s - 1), fill=(150, 150, 150, 255))
    return img


def contact_sheet(key: str, tiles: list[tuple[str, Image.Image]], per_row: int = 6) -> Path:
    cell_w = min(max(t.width for _, t in tiles) + 8, 560)
    cell_h = min(max(t.height for _, t in tiles) + 22, 560)
    rows = (len(tiles) + per_row - 1) // per_row
    sheet = Image.new("RGBA", (cell_w * per_row, cell_h * rows), (40, 40, 48, 255))
    d = ImageDraw.Draw(sheet)
    for i, (name, t) in enumerate(tiles):
        s = min(1.0, (cell_w - 8) / t.width, (cell_h - 22) / t.height)
        img = t.resize((max(1, int(t.width * s)), max(1, int(t.height * s))), Image.NEAREST)
        cx, cy = (i % per_row) * cell_w, (i // per_row) * cell_h
        tile = checker(img.width, img.height)
        tile.alpha_composite(img)
        sheet.paste(tile, (cx + 4, cy + 4))
        d.text((cx + 4, cy + cell_h - 16), name, fill=(255, 255, 255, 255))
    CONTACT.mkdir(parents=True, exist_ok=True)
    path = CONTACT / f"{key}.png"
    sheet.save(path)
    return path


def main() -> int:
    results: dict[str, tuple[list[Image.Image], list[int], int, Image.Image]] = {}
    try:
        for key, cfg in CONFIG.items():
            results[key] = slice_sheet(key, cfg)
    except SliceError as err:
        print(f"SLICE FAILED: {err}", file=sys.stderr)
        return 1
    # Everything validated: write.
    for key, cfg in CONFIG.items():
        images, size, baseline, portrait = results[key]
        out = cfg["out"]
        out.mkdir(parents=True, exist_ok=True)
        for old in out.glob(f"{cfg['prefix']}_*.png"):
            old.unlink()
        tiles = []
        width = "02d" if "elder_thornwarden" in key else "d"
        for i, img in enumerate(images):
            fn = f"{cfg['prefix']}_{i:{width}}.png"
            img.save(out / fn)
            tiles.append((fn, img))
        portrait.save(out / "portrait.png")
        path = contact_sheet(key, tiles)
        print(f"{key}: 6 frames canvas={size} baseline={baseline} -> {out} contact={path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
