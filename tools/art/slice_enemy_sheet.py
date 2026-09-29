"""Slice the owner's enemy sheets and battle backgrounds into game assets.

Usage:
    python tools/art/slice_enemy_sheet.py            # slice everything
    python tools/art/slice_enemy_sheet.py goblin     # one sheet
    python tools/art/slice_enemy_sheet.py --probe goblin X0 X1 [Y0 Y1]
        prints foreground row bands and column segments (for measuring)

Layout is per-sheet config measured by eye (see CONFIG): each labelled row is
a y-band plus an x-range that excludes the label column and the right-hand
panel. Inside a band, frames are found by a background mask and column-gap
splitting; small pieces (slash/rock/web effects, hurt stars) join a body
frame. Every row must yield exactly its expected frame count or the script
exits non-zero without writing that sheet.
"""
from __future__ import annotations

import json
import sys
from collections import Counter, deque
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art_source"
OUT_ENEMIES = ROOT / "assets" / "enemies"
OUT_BG = ROOT / "assets" / "backgrounds"
CONTACT = ROOT / "build" / "slice_contact"

DETECT = 26        # max channel diff from background that counts as art
COL_GAP = 6        # empty columns that separate two frames
SMALL = 0.22       # a segment below this share of the row's median mass is an effect
PAD = 3            # pixels kept around the detected bbox (outline, blur)
MARGIN = 2         # canvas margin around the largest frame of an animation


def band(y0, y1, x0, x1, count, merge="nearest", gap=COL_GAP, cuts=(), names=()):
    return {"y": (y0, y1), "x": (x0, x1), "count": count, "merge": merge,
            "gap": gap, "cuts": cuts, "names": names}


# Per-sheet layout. Rows: anim -> band(y0, y1, x0, x1, expected, merge).
# Attack effects attach to the nearest body on their left ("left").
CONFIG: dict[str, dict] = {
    "goblin": {
        "biome": "forest", "size_px": 32, "faces": "right",
        "portrait": (1130, 100, 1510, 490),
        "rows": {
            "idle": band(62, 172, 330, 1110, 4),
            "walk": band(220, 332, 330, 1110, 6),
            "run": band(380, 492, 255, 1110, 6),
            "attack": band(538, 648, 225, 1110, 6, "left"),
            "hurt": band(675, 808, 255, 1110, 4),
            "die": band(858, 962, 255, 1110, 5),
        },
    },
    "golem": {
        "biome": "forest", "size_px": 64, "faces": "right",
        "portrait": (1090, 25, 1515, 465),
        "rows": {
            "idle": band(78, 188, 125, 1090, 5),
            "walk": band(192, 308, 125, 1090, 7),
            "run": band(322, 428, 125, 1090, 7),
            # frame 6 is the rock burst alone (the golem is off-frame)
            "attack": band(438, 576, 125, 1090, 6, "left", cuts=(923,)),
            "hurt": band(576, 690, 125, 1090, 4),
            "die": band(698, 794, 118, 1090, 6, cuts=(738,)),
        },
        # dark stone is shadow-coloured: key only the flat background
        "keep_dark": ("variants/dark",),
        "variants": band(836, 1000, 20, 1040, 5,
                         names=("basic", "fire", "ice", "dark", "gold")),
    },
    "slime": {
        "biome": "forest", "size_px": 32, "faces": "right",
        "portrait": (1095, 125, 1515, 415),
        "rows": {
            "idle": band(104, 182, 140, 1090, 5),
            "walk": band(206, 286, 140, 1090, 7),
            "jump": band(294, 412, 140, 1090, 7),
            # frame 4: slime + spit joined by spray; 5-6: the flying blob
            "attack": band(440, 520, 140, 1090, 6),
            "hurt": band(530, 648, 140, 1090, 5),
            "die": band(666, 760, 140, 1090, 6),
        },
        "variants": band(822, 946, 30, 1510, 9, names=(
            "basic", "blue", "red", "yellow", "purple", "ice", "fire", "poison", "gold")),
    },
    "thief": {
        "biome": "forest", "size_px": 32, "faces": "right",
        "portrait": (1145, 100, 1515, 510),
        "rows": {
            "idle": band(115, 234, 140, 1120, 4),
            "walk": band(255, 372, 140, 1120, 8),
            "run": band(400, 510, 140, 1120, 7),
            "attack": band(545, 660, 140, 1120, 6, "left"),
            "hurt": band(680, 815, 140, 1120, 4),
            "die": band(838, 952, 140, 1120, 6),
        },
    },
    "wolf": {
        "biome": "forest", "size_px": 48, "faces": "right",
        "portrait": (1130, 125, 1515, 495),
        "blank": [(30, 562, 140, 588)],       # ATTACK label beside frame 1's tail
        "rows": {
            "idle": band(122, 242, 110, 1125, 4),
            "walk": band(262, 378, 110, 1125, 7),
            "run": band(410, 520, 110, 1125, 7),
            "attack": band(560, 672, 105, 1125, 6, "left"),
            "hurt": band(695, 824, 110, 1125, 4),
            "die": band(845, 964, 110, 1125, 5),
        },
    },
    "kobold": {
        "biome": "cave", "size_px": 32, "faces": "right",
        "portrait": (1080, 85, 1510, 470),
        "rows": {
            "idle": band(86, 192, 136, 1080, 5),
            "walk": band(194, 318, 136, 1080, 8),
            "run": band(334, 440, 136, 1080, 8),
            # frame 3's spear tip hangs over frame 4's tail; 5/6 touch at 891
            "attack": band(450, 566, 136, 1110, 6, "left",
                           cuts=((595, 518, 591), 891)),
            "hurt": band(570, 680, 136, 1080, 4),
            "die": band(686, 772, 136, 1080, 5),
        },
        "variants": band(818, 956, 25, 1210, 6, names=(
            "basic", "scout", "miner", "shaman", "warrior", "archer")),
    },
    "minotaur": {
        "biome": "cave", "size_px": 64, "faces": "right",
        "portrait": (1070, 30, 1515, 485),
        "rows": {
            "idle": band(84, 200, 132, 1060, 5),
            "walk": band(208, 324, 132, 1060, 7),
            "run": band(334, 444, 132, 1060, 7),
            # 4|5: 4px gap at 698; 5|6: slash (above y528) vs frame 6's tail
            "attack": band(446, 570, 132, 1060, 6, "left",
                           cuts=(698, (901, 528, 885))),
            "hurt": band(576, 688, 132, 1060, 4),
            "die": band(696, 796, 132, 1060, 6),
        },
        "variants": band(836, 982, 25, 1240, 5, names=(
            "basic", "dark", "ice", "fire", "elite")),
    },
    "skeleton": {
        "biome": "cave", "size_px": 32, "faces": "right",
        "portrait": (1140, 80, 1505, 460),
        "rows": {
            "idle": band(90, 192, 140, 1110, 5),
            "walk": band(204, 306, 140, 1110, 8),
            "run": band(324, 428, 140, 1110, 8),
            "attack": band(434, 550, 140, 1110, 7, "left"),
            "hurt": band(558, 674, 140, 1110, 5),
            "die": band(684, 780, 140, 1110, 7),
        },
        "variants": band(828, 962, 25, 1140, 6, names=(
            "sword", "shield", "archer", "spear", "mage", "elite")),
    },
    "giant_spider": {
        "biome": "cave", "size_px": 64, "faces": "right",
        "portrait": (1040, 50, 1520, 430),
        "blank": [(30, 480, 135, 502)],       # ATTACK label beside frame 1's legs
        "rows": {
            "idle": band(90, 194, 100, 1060, 5),
            "walk": band(216, 320, 100, 1045, 6),
            "run": band(344, 450, 100, 1045, 6),
            # 1-3 spider; 4 spider + web cone; 5 spider lunging through web
            # streaks; 6 the web splat on its own (like the golem's burst)
            "attack": band(476, 592, 100, 1072, 6, "left", cuts=(782, 969)),
            "hurt": band(604, 722, 100, 1045, 4),
            "die": band(740, 842, 100, 1045, 5),
        },
        # no captions on the sheet: named by colour
        "variants": band(884, 984, 25, 1045, 5, names=(
            "red", "green", "white", "blue", "brown")),
        "effects": dict(band(712, 828, 1055, 1528, 4), prefix="web",
                        min_bright=80),   # drop the dark blend fringe of thin web lines
    },
}


# ---------------------------------------------------------------- masks

def flat(im: Image.Image):
    getter = getattr(im, "get_flattened_data", None) or im.getdata
    return list(getter())


def load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGB")


def background(im: Image.Image) -> tuple[int, int, int]:
    small = im.resize((im.width // 4, im.height // 4), Image.NEAREST)
    return Counter(flat(small)).most_common(1)[0][0]


def diff_image(im: Image.Image, bg) -> Image.Image:
    d = ImageChops.difference(im, Image.new("RGB", im.size, bg))
    r, g, b = d.split()
    return ImageChops.lighter(ImageChops.lighter(r, g), b)


def detect_mask(im: Image.Image, bg) -> Image.Image:
    return diff_image(im, bg).point(lambda v: 255 if v > DETECT else 0)


def runs(values, gap):
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


def profiles(mask: Image.Image, box):
    x0, y0, x1, y1 = box
    sub = mask.crop(box)
    w, h = sub.size
    data = flat(sub)
    cols = [0] * w
    rows = [0] * h
    for i, v in enumerate(data):
        if v:
            cols[i % w] += 1
            rows[i // w] += 1
    return cols, rows


# ---------------------------------------------------------------- alpha

BG_TOL = 8         # flood-fill tolerance for flat background (noise is ~3)
HOLE_TOL = 3       # enclosed pixels this close to the background are holes
SHADOW_ZONE = 0.7  # shadow keying only below this share of the crop height


def is_shadow(c) -> bool:
    """Dark, blue-leaning ground-shadow colour (its core may be near-black)."""
    r, g, b = c
    return (max(c) <= 68 and (max(c) <= NEAR_BLACK
                              or (b >= r and b >= g - 2 and max(c) - min(c) <= 34)))


NEAR_BLACK = 24    # too dark to tell outline from shadow core by colour


def cut_out(im: Image.Image, box, bg, shadow=True, min_bright=0) -> Image.Image:
    """Crop box from im and key the background to transparency."""
    crop = im.crop(box)
    w, h = crop.size
    px = flat(crop)

    def dist(c):
        return max(abs(c[0] - bg[0]), abs(c[1] - bg[1]), abs(c[2] - bg[2]))

    # ground shadows only live under the feet: bottom part of the crop
    # and below everything solid in their column (dark clothing always has
    # an outline or a boot under it).
    floor = int(h * SHADOW_ZONE) if shadow else h
    shade = [is_shadow(c) for c in px]
    lowest_solid = [-1] * w
    for i, c in enumerate(px):
        if dist(c) > BG_TOL and not shade[i]:
            lowest_solid[i % w] = i // w
    passable = [dist(c) <= BG_TOL or (shade[i] and i // w >= floor
                                      and i // w > lowest_solid[i % w])
                for i, c in enumerate(px)]
    clear = [False] * (w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            q.append(y * w + x)
    for y in range(h):
        for x in (0, w - 1):
            q.append(y * w + x)
    while q:
        i = q.popleft()
        if clear[i] or not passable[i]:
            continue
        clear[i] = True
        x, y = i % w, i // w
        if x > 0:
            q.append(i - 1)
        if x < w - 1:
            q.append(i + 1)
        if y > 0:
            q.append(i - w)
        if y < h - 1:
            q.append(i + w)
    keep = [not clear[i] and dist(c) > HOLE_TOL and max(c) >= min_bright
            for i, c in enumerate(px)]
    drop_dark_specks(keep, px, w, h)
    out = Image.new("RGBA", (w, h))
    out.putdata([(*c, 255) if keep[i] else (0, 0, 0, 0) for i, c in enumerate(px)])
    return out


SPECK = 160        # isolated opaque blobs smaller than this ...
SPECK_DARK = 70    # ... and no brighter than this are shadow leftovers
CRUMB = 6          # isolated blobs this small are compression crumbs, any colour


def drop_dark_specks(keep, px, w, h):
    seen = [False] * (w * h)
    for start in range(w * h):
        if not keep[start] or seen[start]:
            continue
        comp = []
        q = deque([start])
        seen[start] = True
        while q:
            i = q.popleft()
            comp.append(i)
            x, y = i % w, i // w
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        j = ny * w + nx
                        if keep[j] and not seen[j]:
                            seen[j] = True
                            q.append(j)
        if len(comp) < CRUMB or (len(comp) < SPECK
                                 and max(max(px[i]) for i in comp) <= SPECK_DARK):
            for i in comp:
                keep[i] = False


# ---------------------------------------------------------------- frames

class SliceError(Exception):
    pass


def find_frames(mask: Image.Image, spec, name: str):
    """Return frames: dicts with x-range, y-range, anchor x (sheet coords)."""
    x0, x1 = spec["x"]
    y0, y1 = spec["y"]
    cols, _ = profiles(mask, (x0, y0, x1, y1))
    spans = runs(cols, spec["gap"])
    # Forced boundaries where two frames touch. An int splits at that column;
    # (x_top, y_mid, x_bot) is a stepped cut: rows above y_mid split at x_top,
    # rows from y_mid down split at x_bot (a spear tip over the next tail).
    cuts = [c if isinstance(c, tuple) else (c, 0, c) for c in spec["cuts"]]
    for _, _, cut in cuts:
        c = cut - x0
        split = []
        for a, b in spans:
            if a < c <= b:
                left = [i for i in range(a, c) if cols[i]]
                right = [i for i in range(c, b + 1) if cols[i]]
                split += [(left[0], left[-1])] if left else []
                split += [(right[0], right[-1])] if right else []
            else:
                split.append((a, b))
        spans = split
    segs = [(x0 + a, x0 + b, sum(cols[a:b + 1])) for a, b in spans]
    if not segs:
        raise SliceError(f"{name}: no art in band {spec}")
    masses = sorted(m for _, _, m in segs)
    median = masses[len(masses) // 2]
    bodies = [s for s in segs if s[2] >= SMALL * median]
    small = [s for s in segs if s[2] < SMALL * median]
    if len(bodies) != spec["count"]:
        desc = " ".join(f"{a}-{b}({m})" for a, b, m in segs)
        raise SliceError(f"{name}: expected {spec['count']} frames, found "
                         f"{len(bodies)} bodies in {spec}: {desc}")
    frames = []
    for a, b, m in bodies:
        # mass-weighted column centre of the body = horizontal anchor
        cx = sum((x0 + i) * cols[i] for i in range(a - x0, b - x0 + 1)) / m
        frames.append({"xa": a, "xb": b, "cx": cx, "clip": []})
    big = 10**6
    for x_top, y_mid, x_bot in cuts:
        if x_top == x_bot:
            continue
        left = max((f for f in frames if f["xb"] < x_bot), key=lambda f: f["xb"])
        right = min((f for f in frames if f["xa"] >= x_bot), key=lambda f: f["xa"])
        left["xb"] = max(left["xb"], x_top - 1)
        right["xa"] = min(right["xa"], x_top)
        # clip boxes in sheet coords: (x0, y0, x1, y1) cleared from the frame
        left["clip"] += [(x_top, -big, big, y_mid), (x_bot, y_mid, big, big)]
        right["clip"] += [(-big, -big, x_top, y_mid), (-big, y_mid, x_bot, big)]
    for a, b, m in small:
        if spec["merge"] == "left":
            left = [f for f in frames if f["xb"] < a]
            pool = left or frames
        else:
            pool = frames
        best = min(pool, key=lambda f: max(f["xa"] - b, a - f["xb"], 0))
        best["xa"] = min(best["xa"], a)
        best["xb"] = max(best["xb"], b)
    for f in frames:
        _, rows = profiles(mask, (f["xa"], y0, f["xb"] + 1, y1))
        ys = [i for i, v in enumerate(rows) if v]
        f["ya"], f["yb"] = y0 + ys[0], y0 + ys[-1]
    return frames


def crop_box(f, prev_xb, next_xa, spec):
    y0, y1 = spec["y"]
    return (max(f["xa"] - PAD, min(prev_xb + 1, f["xa"])), max(f["ya"] - PAD, y0),
            min(f["xb"] + PAD + 1, max(next_xa, f["xb"] + 1)), min(f["yb"] + PAD + 1, y1))


def slice_row(im, mask, bg, spec, name):
    """Cut every frame of a row; return (images, canvas size, baseline)."""
    frames = find_frames(mask, spec, name)
    boxes = []
    for i, f in enumerate(frames):
        prev_xb = frames[i - 1]["xb"] if i else -10**6
        next_xa = frames[i + 1]["xa"] if i + 1 < len(frames) else 10**6
        boxes.append(crop_box(f, prev_xb, next_xa, spec))
    ground = max(b[3] for b in boxes)          # common baseline of the row
    top = min(b[1] for b in boxes)
    half = max(max(f["cx"] - b[0], b[2] - f["cx"]) for f, b in zip(frames, boxes))
    w = int(2 * half + 0.999) + 2 * MARGIN
    h = ground - top + 2 * MARGIN
    images = []
    for f, b in zip(frames, boxes):
        canvas = Image.new("RGBA", (w, h))
        piece = cut_out(im, b, bg, min_bright=spec.get("min_bright", 0))
        for cx0, cy0, cx1, cy1 in f["clip"]:
            box = (max(cx0 - b[0], 0), max(cy0 - b[1], 0),
                   min(cx1 - b[0], piece.width), min(cy1 - b[1], piece.height))
            if box[2] > box[0] and box[3] > box[1]:
                piece.paste((0, 0, 0, 0), box)
        canvas.paste(piece, (round(w / 2 - (f["cx"] - b[0])), b[1] - top + MARGIN))
        images.append(canvas)
    baseline = ground - top + MARGIN - 1 - PAD
    return images, [w, h], baseline


def cut_single(im, mask, bg, box, shadow=True):
    """Tight transparent cut of the art inside box (portrait, variant cell)."""
    x0, y0, x1, y1 = box
    cols, rows = profiles(mask, box)
    xs = [i for i, v in enumerate(cols) if v]
    ys = [i for i, v in enumerate(rows) if v]
    if not xs:
        raise SliceError(f"no art inside {box}")
    b = (max(x0 - PAD, x0 + xs[0] - PAD), max(y0 - PAD, y0 + ys[0] - PAD),
         min(x1 + PAD, x0 + xs[-1] + PAD + 1), min(y1 + PAD, y0 + ys[-1] + PAD + 1))
    return cut_out(im, b, bg, shadow)


# ---------------------------------------------------------------- sheets

def slice_sheet(eid: str, cfg: dict):
    im = load(SRC / "enemies" / cfg["biome"] / f"{eid}_sheet.webp")
    bg = background(im)
    for box in cfg.get("blank", ()):   # label text that shares a frame's columns
        im.paste(bg, box)
    mask = detect_mask(im, bg)
    anims = {}
    for anim, spec in cfg["rows"].items():
        anims[anim] = slice_row(im, mask, bg, spec, f"{eid}.{anim}")
    variants = []
    if "variants" in cfg:
        spec = cfg["variants"]
        if len(spec["names"]) != spec["count"]:
            raise SliceError(f"{eid}.variants: {spec['count']} cells but names {spec['names']}")
        frames = find_frames(mask, spec, f"{eid}.variants")
        for f, cap in zip(frames, spec["names"]):
            box = (f["xa"], f["ya"], f["xb"] + 1, f["yb"] + 1)
            dark = f"variants/{cap}" in cfg.get("keep_dark", ())
            variants.append((cap, cut_single(im, mask, bg, box, not dark)))
    effects = []
    if "effects" in cfg:
        spec = cfg["effects"]
        effects, _, _ = slice_row(im, mask, bg, spec, f"{eid}.effects")
    portrait = cut_single(im, mask, bg, cfg["portrait"])

    # Everything validated: write.
    out = OUT_ENEMIES / eid
    for old in out.rglob("*.png") if out.exists() else []:
        old.unlink()
    out.mkdir(parents=True, exist_ok=True)
    tiles = []
    for anim, (images, _, _) in anims.items():
        for i, img in enumerate(images):
            fn = f"{anim}_{i:02d}.png"
            img.save(out / fn)
            tiles.append((fn, img))
    portrait.save(out / "portrait.png")
    tiles.append(("portrait.png", portrait))
    if variants:
        (out / "variants").mkdir(exist_ok=True)
    for cap, img in variants:
        img.save(out / "variants" / f"{cap}.png")
        tiles.append((f"variants/{cap}.png", img))
    if effects:
        (out / "effects").mkdir(exist_ok=True)
    for i, img in enumerate(effects):
        fn = f"effects/{cfg['effects']['prefix']}_{i:02d}.png"
        img.save(out / fn)
        tiles.append((fn, img))
    contact_sheet(eid, tiles)
    return {
        "animations": {a: len(v[0]) for a, v in anims.items()},
        "canvas": {a: v[1] for a, v in anims.items()},
        "baseline": {a: v[2] for a, v in anims.items()},
        "size_px": cfg["size_px"],
        "faces": cfg["faces"],
        "variants": [c for c, _ in variants],
    }


def checker(w, h, s=8):
    img = Image.new("RGBA", (w, h), (200, 200, 200, 255))
    d = ImageDraw.Draw(img)
    for y in range(0, h, s):
        for x in range(0, w, s):
            if (x // s + y // s) % 2:
                d.rectangle((x, y, x + s - 1, y + s - 1), fill=(150, 150, 150, 255))
    return img


def contact_sheet(eid, tiles, per_row=8):
    cell_w = min(max(t.width for _, t in tiles) * 2 + 8, 330)
    cell_h = min(max(t.height for _, t in tiles) * 2 + 22, 330)
    rows = (len(tiles) + per_row - 1) // per_row
    sheet = Image.new("RGBA", (cell_w * per_row, cell_h * rows), (40, 40, 48, 255))
    d = ImageDraw.Draw(sheet)
    for i, (name, t) in enumerate(tiles):
        s = min(2.0, (cell_w - 8) / t.width, (cell_h - 22) / t.height)
        img = t.resize((max(1, int(t.width * s)), max(1, int(t.height * s))), Image.NEAREST)
        cx, cy = (i % per_row) * cell_w, (i // per_row) * cell_h
        tile = checker(img.width, img.height)
        tile.alpha_composite(img)
        sheet.paste(tile, (cx + 4, cy + 4))
        d.rectangle((cx + 3, cy + 3, cx + 4 + img.width, cy + 4 + img.height),
                    outline=(255, 0, 255, 255))
        d.text((cx + 4, cy + cell_h - 16), name, fill=(255, 255, 255, 255))
    CONTACT.mkdir(parents=True, exist_ok=True)
    sheet.save(CONTACT / f"{eid}.png")


def slice_background(name: str):
    im = load(SRC / "backgrounds" / f"{name}.webp")
    tw, th = 1920, 1080
    s = max(tw / im.width, th / im.height)
    w, h = max(tw, round(im.width * s)), max(th, round(im.height * s))
    big = im.resize((w, h), Image.LANCZOS)
    left, top = (w - tw) // 2, (h - th) // 2
    OUT_BG.mkdir(parents=True, exist_ok=True)
    big.crop((left, top, left + tw, top + th)).save(OUT_BG / f"{name}.png")


# ---------------------------------------------------------------- probe

def probe(sheet: Path, x0: int, x1: int, y0: int = 0, y1: int = 1024):
    im = load(sheet)
    mask = detect_mask(im, background(im))
    _, rows = profiles(mask, (x0, y0, x1, y1))
    for a, b in runs(rows, 4):
        cols, _ = profiles(mask, (x0, y0 + a, x1, y0 + b + 1))
        segs = runs(cols, COL_GAP)
        desc = " ".join(f"{x0+s}-{x0+e}({sum(cols[s:e+1])})" for s, e in segs)
        print(f"y {y0+a}-{y0+b}: {len(segs)} segs: {desc}")


def main(argv):
    if argv and argv[0] == "--probe":
        probe(next(SRC.rglob(f"{argv[1]}_sheet.webp")), *[int(a) for a in argv[2:]])
        return 0
    wanted = argv or list(CONFIG) + ["forest", "cave"]
    manifest_path = OUT_ENEMIES / "manifest.json"
    manifest = json.loads(manifest_path.read_text()) if manifest_path.exists() else {}
    failed = False
    for key in wanted:
        if key in ("forest", "cave"):
            slice_background(key)
            print(f"background {key}: ok")
            continue
        try:
            manifest[key] = slice_sheet(key, CONFIG[key])
            print(f"{key}: {manifest[key]['animations']} variants={manifest[key]['variants']}")
        except SliceError as e:
            print(f"FAIL {e}")
            failed = True
    if failed:
        return 1
    manifest = {k: manifest[k] for k in sorted(manifest)}
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))


